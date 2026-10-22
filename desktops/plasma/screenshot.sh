#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# The finished desktop as a picture: a Plasma X11 session on a virtual framebuffer (Xvfb,
# software OpenGL), the theme applied inside it, kitty with the greeting, one grab of the
# whole screen. No GPU and no login needed. The source of the desktop image in
# docs/screenshots/.
set -euo pipefail

usage() {
  cat << USAGE
usage: screenshot.sh <out.png>

Run as the user the layer is installed for (patina install), on a machine or in a
container with Plasma: Xvfb, startplasma-x11, scrot, kitty, fastfetch, fish,
dbus-run-session and dbus-send. No display or login is needed. Environment:
  PATINA_SHOT_SIZE     the virtual screen, WIDTHxHEIGHT (default 1920x1080)
  PATINA_SHOT_SETTLE   seconds for the shell, then the terminal, to be drawn (default 25)
  PATINA_SHOT_WAIT     seconds to wait for plasmashell to come up (default 240)
The session's output lands next to the picture, in <out.png>.log.
USAGE
}

here="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
PATINA_PATH="${PATINA_PATH:-$(cd "$here/../.." && pwd)}"
export PATINA_PATH
settle="${PATINA_SHOT_SETTLE:-25}"
wait_s="${PATINA_SHOT_WAIT:-240}"

# Is a name owned on the session bus? plasmashell owns org.kde.plasmashell once it runs.
on_bus() {
  dbus-send --session --print-reply --dest=org.freedesktop.DBus /org/freedesktop/DBus \
    org.freedesktop.DBus.NameHasOwner "string:$1" 2> /dev/null | grep -q 'boolean true'
}

# The half that runs under the session bus: it starts the Plasma X11 session on the
# framebuffer DISPLAY already names, applies the theme, opens the terminal and grabs the
# screen. The environment is the one a Plasma login sets, so the renderer sees a session
# (XDG_CURRENT_DESKTOP, the bus) and Qt draws on X.
session() {
  local out="$1" waited=0 theme session_pid
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
  theme="$("$PATINA_PATH/bin/patina" theme current)"
  "$PATINA_PATH/bin/patina" theme set "$theme" || true
  sleep 5
  # fastfetch asks kitty for its version and reads the reply itself; give kitty a moment
  # to finish its own startup first, or a late reply lands on the shell's prompt line.
  kitty fish -C 'sleep 3; fastfetch' &
  sleep "$settle"
  scrot --overwrite "$out"
  [[ -s "$out" ]] || { echo "screenshot: scrot wrote nothing to $out" >&2; return 1; }
  echo "screenshot: written to $out"
}

if [[ "${1:-}" == --session ]]; then
  # The session and the terminal end with this half; it ends after the grab.
  trap 'jobs -p | xargs -r kill 2> /dev/null || true' EXIT
  session "$2"
  exit
fi

[[ $# -eq 1 && "$1" != -* ]] || { usage >&2; exit 64; }
out="$(readlink -f "$1")"
size="${PATINA_SHOT_SIZE:-1920x1080}"
[[ "$size" =~ ^([0-9]+)x([0-9]+)$ ]] || { echo "screenshot: PATINA_SHOT_SIZE is not WIDTHxHEIGHT: $size" >&2; exit 64; }
width="${BASH_REMATCH[1]}"
height="${BASH_REMATCH[2]}"
for tool in Xvfb startplasma-x11 scrot kitty fastfetch fish dbus-run-session dbus-send; do
  command -v "$tool" > /dev/null || { echo "screenshot: $tool missing" >&2; exit 69; }
done
# A runtime directory of this user's own; a login gives one, a container does not.
if [[ -z "${XDG_RUNTIME_DIR:-}" || ! -w "${XDG_RUNTIME_DIR:-}" ]]; then
  XDG_RUNTIME_DIR="$(mktemp -d)"
  export XDG_RUNTIME_DIR
fi
# Software OpenGL (Mesa's llvmpipe), so KWin composites without a GPU.
export LIBGL_ALWAYS_SOFTWARE=1 GALLIUM_DRIVER=llvmpipe
rm -f "$out"
log="$out.log"
mkdir -p "$(dirname "$out")"
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
dbus-run-session -- "$here/screenshot.sh" --session "$out" >> "$log" 2>&1 || status=$?
if [[ -s "$out" ]]; then
  echo "screenshot: $out"
else
  echo "screenshot: no picture (exit $status); the end of $log:" >&2
  tail -n 60 "$log" >&2
  exit 1
fi
