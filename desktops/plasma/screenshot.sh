#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# The finished desktop as a picture: a Plasma session on KWin's virtual screen (no GPU,
# no display, no login), the theme applied inside it, kitty with the greeting, one
# screenshot through KWin. The source of the desktop image in docs/screenshots/.
set -euo pipefail

usage() {
  cat << USAGE
usage: screenshot.sh <out.png>

Run as the user the layer is installed for (patina install), on a machine or in a
container with Plasma: kwin_wayland, plasmashell, spectacle, kscreen-doctor, kitty,
fastfetch, fish and dbus-run-session. No display or login is needed. Environment:
  PATINA_SHOT_SIZE     the virtual screen, WIDTHxHEIGHT (default 1920x1080)
  PATINA_SHOT_SETTLE   seconds for the shell, then the terminal, to be drawn (default 20)
  PATINA_SHOT_WAIT     seconds to wait for plasmashell to come up (default 180)
The session's output lands next to the picture, in <out.png>.log.
USAGE
}

here="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
PATINA_PATH="${PATINA_PATH:-$(cd "$here/../.." && pwd)}"
export PATINA_PATH
settle="${PATINA_SHOT_SETTLE:-20}"
wait_s="${PATINA_SHOT_WAIT:-180}"

# Is a name owned on the session bus? The shell owns org.kde.plasmashell once it runs.
on_bus() {
  dbus-send --session --print-reply --dest=org.freedesktop.DBus /org/freedesktop/DBus \
    org.freedesktop.DBus.NameHasOwner "string:$1" 2> /dev/null | grep -q 'boolean true'
}

# The half that runs inside the compositor: KWin starts it with WAYLAND_DISPLAY set and
# exits when it ends. The environment is the one Plasma's own session sets, so the
# renderer sees a session (XDG_CURRENT_DESKTOP, the bus) and Qt draws on Wayland.
session() {
  local out="$1" waited=0 theme shell_pid
  export XDG_SESSION_TYPE=wayland XDG_CURRENT_DESKTOP=KDE KDE_FULL_SESSION=true \
    KDE_SESSION_VERSION=6 DESKTOP_SESSION=plasma QT_QPA_PLATFORM=wayland
  # A session that has no panels yet: plasmashell runs the look-and-feel package's
  # layout script, the way the image's first login does.
  plasmashell --no-respawn &
  shell_pid=$!
  until on_bus org.kde.plasmashell; do
    if ! kill -0 "$shell_pid" 2> /dev/null; then
      echo "screenshot: plasmashell exited before it came up; see the log" >&2
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
  "$PATINA_PATH/bin/patina" theme set "$theme"
  sleep 5
  kitty fish -C fastfetch &
  sleep "$settle"
  spectacle --background --nonotify --fullscreen --output "$out"
  [[ -s "$out" ]] || { echo "screenshot: spectacle wrote nothing to $out" >&2; return 1; }
  echo "screenshot: written to $out"
}

if [[ "${1:-}" == --session ]]; then
  # The shell and the terminal end with this half; KWin ends when this half does.
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
for tool in kwin_wayland plasmashell spectacle kscreen-doctor kitty fastfetch fish \
    dbus-run-session dbus-send; do
  command -v "$tool" > /dev/null || { echo "screenshot: $tool missing" >&2; exit 69; }
done
# Wayland needs a runtime directory of this user's own; a login gives one, a container
# does not.
if [[ -z "${XDG_RUNTIME_DIR:-}" || ! -w "${XDG_RUNTIME_DIR:-}" ]]; then
  XDG_RUNTIME_DIR="$(mktemp -d)"
  export XDG_RUNTIME_DIR
fi
# KWin lets only applications whose desktop file names its screenshot interface take
# one, by looking the caller up in the desktop file cache; this lifts that check, as
# KDE's own CI does, so a cache not built yet cannot block the one picture.
export KWIN_SCREENSHOT_NO_PERMISSION_CHECKS=1
rm -f "$out"
log="$out.log"
mkdir -p "$(dirname "$out")"
echo "screenshot: a Plasma session on a ${width}x${height} virtual screen; log in $log"
# A session bus, then KWin on a virtual screen, which runs the session half above and
# ends with it. The exit code is the session's.
status=0
dbus-run-session -- kwin_wayland --virtual --width "$width" --height "$height" \
  --no-lockscreen --no-global-shortcuts --no-kactivities \
  --exit-with-session="$here/screenshot.sh --session $out" > "$log" 2>&1 || status=$?
if [[ -s "$out" ]]; then
  echo "screenshot: $out"
else
  echo "screenshot: no picture (exit $status); see $log" >&2
  exit 1
fi
