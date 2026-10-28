#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# The finished desktop as pictures: a Plasma X11 session on a virtual framebuffer (Xvfb,
# software OpenGL), the theme applied inside it, then the desktop with kitty split in two
# (the greeting and btop), when asked the command palette with the agent's answer on the
# empty desktop, and the start menu in the theme's light mode. No GPU and no login
# needed. The source of the desktop images in docs/screenshots/.
set -euo pipefail

usage() {
  cat << USAGE
usage: screenshot.sh <dir>

Run as the user the layer is installed for (patina install), on a machine or in a
container with Plasma: Xvfb, startplasma-x11, scrot, kitty, fastfetch, fish, btop,
dbus-run-session and dbus-send. No display or login is needed. Writes into <dir>:
  desktop.png          kitty split in two, the greeting beside btop
  command-palette.png  KRunner on the agent's answer to PATINA_SHOT_ASK, through
                       kortex, on the empty desktop; only when PATINA_SHOT_ASK is set
                       and kortex installed
  start-menu.png       the start menu, open as Meta opens it, in the light mode (the
                       mode the desktop had is set again afterwards)
Environment:
  PATINA_SHOT_ASK      a request for the agent, typed after ai in KRunner (default none)
  PATINA_SHOT_SIZE     the virtual screen, WIDTHxHEIGHT (default 1920x1080)
  PATINA_SHOT_SETTLE   seconds for the shell, then the terminal, to be drawn (default 25)
  PATINA_SHOT_WAIT     seconds to wait for plasmashell, then for the agent (default 240)
The session's output lands in <dir>/session.log.
USAGE
}

here="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
PATINA_PATH="${PATINA_PATH:-$(cd "$here/../.." && pwd)}"
export PATINA_PATH
settle="${PATINA_SHOT_SETTLE:-25}"
wait_s="${PATINA_SHOT_WAIT:-240}"
kortex=io.github.patina21.kortex

# Is a name owned on the session bus? plasmashell owns org.kde.plasmashell once it runs.
on_bus() {
  dbus-send --session --print-reply --dest=org.freedesktop.DBus /org/freedesktop/DBus \
    org.freedesktop.DBus.NameHasOwner "string:$1" 2> /dev/null | grep -q 'boolean true'
}

# One grab of the whole screen into <dir>/<name>.png.
grab() {
  scrot --overwrite "$1/$2.png"
  [[ -s "$1/$2.png" ]] || { echo "screenshot: scrot wrote nothing to $1/$2.png" >&2; return 1; }
  echo "screenshot: written to $1/$2.png"
}

# The half that runs under the session bus: it starts the Plasma X11 session on the
# framebuffer DISPLAY already names, applies the theme and takes the pictures. The
# environment is the one a Plasma login sets, so the renderer sees a session
# (XDG_CURRENT_DESKTOP, the bus) and Qt draws on X.
session() {
  local dir="$1" waited=0 theme session_pid split kitty_pid query mode
  export XDG_SESSION_TYPE=x11 XDG_CURRENT_DESKTOP=KDE KDE_FULL_SESSION=true \
    KDE_SESSION_VERSION=6 DESKTOP_SESSION=plasmax11 QT_QPA_PLATFORM=xcb
  startplasma-x11 &
  session_pid=$!
  until on_bus org.kde.plasmashell; do
    if ! kill -0 "$session_pid" 2> /dev/null; then
      echo "screenshot: the Plasma session exited before it came up; see the log" >&2
      return 1
    fi
    if (( waited >= wait_s )); then
      echo "screenshot: plasmashell did not come up within ${wait_s}s" >&2
      return 1
    fi
    sleep 5
    waited=$((waited + 5))
  done
  echo "screenshot: plasmashell up after ${waited}s"
  sleep "$settle"
  # The theme once more, now inside a session: the live reload through the plasma-apply
  # tools, and the window rule that needs a screen (desktops/plasma/README.md).
  # With --layout, as the first install runs it, so the start menu shows patina's
  # favourites in place of the ones Plasma gave the session.
  theme="$("$PATINA_PATH/bin/patina" theme current)"
  "$PATINA_PATH/bin/patina" theme set "$theme" --layout || true
  sleep 5
  # The Welcome Center a first login opens would show through the windows.
  pkill -u "$(id -u)" -x plasma-welcome || true

  # One kitty window split in two: the greeting on the left, btop on the right, its
  # graphs refreshed four times a second so they fill before the grab. The greeting is
  # fish's own (fastfetch, desktops/terminal); it asks kitty for its version and reads
  # the reply itself, so fish waits for kitty to finish its own startup first, or a late
  # reply lands on the shell's prompt line.
  split="$(mktemp)"
  printf '%s\n' 'layout splits' "launch fish -C 'sleep 3'" \
    'launch --location=vsplit --bias=58 btop --update 250' > "$split"
  kitty --session "$split" &
  kitty_pid=$!
  sleep "$settle"
  grab "$dir" desktop
  rm -f "$split"
  kill "$kitty_pid" 2> /dev/null || true
  sleep 2

  if [[ -n "${PATINA_SHOT_ASK:-}" ]]; then
    # The command palette on the empty desktop. What Enter on kortex's "Ask the agent"
    # match does: kortex sends the request to the agent and opens KRunner on the
    # conversation (ai ›), which it keeps current. The match's id is "ask", the unit
    # separator and the request.
    dbus-send --session --print-reply --reply-timeout=60000 --dest="$kortex" /runner \
      org.kde.krunner1.Run "string:ask"$'\x1f'"$PATINA_SHOT_ASK" string: > /dev/null
    # Done once the conversation shows an action that waits for Allow once, Always or
    # Deny, or an answer and no agent still at work; asked as KRunner asks.
    waited=0
    until dbus-send --session --print-reply --reply-timeout=30000 --dest="$kortex" /runner \
      org.kde.krunner1.Match 'string:ai ›' 2> /dev/null | grep -q 'string "Allow '; do
      if (( waited >= wait_s )); then
        echo "screenshot: the agent asked for nothing within ${wait_s}s; the conversation as it stands" >&2
        break
      fi
      sleep 2
      waited=$((waited + 2))
    done
    # Those Match calls told kortex the conversation is on screen as it stands, so it
    # sees no news to show. KRunner asks again only for a query that differs from the
    # one it shows: the list of conversations first, then the conversation.
    for query in ai 'ai ›'; do
      dbus-send --session --type=method_call --dest=org.kde.krunner /App \
        org.kde.krunner.App.querySingleRunner string:kortex "string:$query"
      sleep 2
    done
    sleep 5
    grab "$dir" command-palette
    pkill -u "$(id -u)" -x krunner || true
    sleep 2
  fi

  # The start menu in the light mode, opened as Meta opens it; then the mode the desktop
  # had, so a run on a real desktop leaves it as it was.
  mode="$("$PATINA_PATH/bin/patina" theme mode)"
  "$PATINA_PATH/bin/patina" theme mode light || true
  sleep "$settle"
  dbus-send --session --type=method_call --dest=org.kde.plasmashell /PlasmaShell \
    org.kde.PlasmaShell.activateLauncherMenu
  sleep 5
  grab "$dir" start-menu
  dbus-send --session --type=method_call --dest=org.kde.plasmashell /PlasmaShell \
    org.kde.PlasmaShell.activateLauncherMenu
  "$PATINA_PATH/bin/patina" theme mode "$mode" || true
}

if [[ "${1:-}" == --session ]]; then
  # The session and the terminal end with this half; it ends after the grabs.
  trap 'jobs -p | xargs -r kill 2> /dev/null || true' EXIT
  session "$2"
  exit
fi

[[ $# -eq 1 && "$1" != -* ]] || { usage >&2; exit 64; }
mkdir -p "$1"
dir="$(readlink -f "$1")"
size="${PATINA_SHOT_SIZE:-1920x1080}"
[[ "$size" =~ ^([0-9]+)x([0-9]+)$ ]] || { echo "screenshot: PATINA_SHOT_SIZE is not WIDTHxHEIGHT: $size" >&2; exit 64; }
width="${BASH_REMATCH[1]}"
height="${BASH_REMATCH[2]}"
for tool in Xvfb startplasma-x11 scrot kitty fastfetch fish btop dbus-run-session dbus-send; do
  command -v "$tool" > /dev/null || { echo "screenshot: $tool missing" >&2; exit 69; }
done
if [[ -n "${PATINA_SHOT_ASK:-}" && ! -f "${XDG_DATA_HOME:-$HOME/.local/share}/krunner/dbusplugins/kortex.desktop" ]]; then
  echo "screenshot: PATINA_SHOT_ASK is set but kortex is not installed (an AI bundle)" >&2
  exit 69
fi
# A runtime directory of this user's own; a login gives one, a container does not.
if [[ -z "${XDG_RUNTIME_DIR:-}" || ! -w "${XDG_RUNTIME_DIR:-}" ]]; then
  XDG_RUNTIME_DIR="$(mktemp -d)"
  export XDG_RUNTIME_DIR
fi
# Software OpenGL (Mesa's llvmpipe), so KWin composites without a GPU.
export LIBGL_ALWAYS_SOFTWARE=1 GALLIUM_DRIVER=llvmpipe
rm -f "$dir/start-menu.png" "$dir/desktop.png" "$dir/command-palette.png"
log="$dir/session.log"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

# The framebuffer: Xvfb writes the display number it chose to the descriptor once it is
# ready to accept connections, so there is no need to poll for it or to guess a free one.
Xvfb -displayfd 3 -screen 0 "${width}x${height}x24" +extension GLX +extension RANDR \
  -nolisten tcp 3> "$work/display" > "$log" 2>&1 &
xvfb_pid=$!
trap 'kill "$xvfb_pid" 2> /dev/null || true; rm -rf "$work"' EXIT
display=""
for _ in $(seq 1 100); do
  display="$(cat "$work/display" 2> /dev/null)"
  [[ -n "$display" ]] && break
  if ! kill -0 "$xvfb_pid" 2> /dev/null; then
    echo "screenshot: Xvfb exited before it was ready; the end of $log:" >&2
    tail -n 40 "$log" >&2
    exit 1
  fi
  sleep 1
done
[[ -n "$display" ]] || { echo "screenshot: Xvfb gave no display within 100s; see $log" >&2; exit 1; }
export DISPLAY=":$display"
echo "screenshot: a Plasma X11 session on a ${width}x${height} framebuffer (display $DISPLAY); log in $log"

# A session bus, then the session half above under it; its output joins the log.
status=0
dbus-run-session -- "$here/screenshot.sh" --session "$dir" >> "$log" 2>&1 || status=$?
if (( status == 0 )); then
  ls "$dir"/*.png
else
  echo "screenshot: failed (exit $status); the end of $log:" >&2
  tail -n 60 "$log" >&2
  exit 1
fi
