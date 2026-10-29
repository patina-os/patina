#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# X session of the live image: a bare window manager and Calamares, full screen.
set -euo pipefail

# The installer's stylesheet (etc/calamares/branding/patina/stylesheet.qss) is written
# against Qt's Fusion style.
export QT_STYLE_OVERRIDE=Fusion
# The installer starts in the live system's language (locales= on the kernel command
# line, auto/config), which live-config writes after systemd has read its environment.
if [[ -r /etc/default/locale ]]; then
  set -a
  # written by live-config at boot, so there is nothing to follow at lint time
  # shellcheck source=/dev/null
  source /etc/default/locale
  set +a
fi
openbox &
# The Wi-Fi step: the installer needs the internet and has no page to join a wireless
# network, so a computer without a default route but with a Wi-Fi card first gets
# NetworkManager's own nmtui, full screen in the palette (~/.Xdefaults, rendered by
# assets.sh, maps the slots NEWT_COLORS names: green is the accent). Quitting it starts
# the installer; leaving the installer brings the step back while the computer is
# still offline, as patina-ui.service starts this session again.
if [[ -z "$(ip route show default 2> /dev/null)" ]] &&
    nmcli -t -f TYPE device 2> /dev/null | grep -qx wifi; then
  NEWT_COLORS='root=lightgray,black window=lightgray,black border=green,black
    shadow=black,black title=green,black label=lightgray,black textbox=lightgray,black
    button=lightgray,gray actbutton=black,green compactbutton=lightgray,black
    checkbox=lightgray,black actcheckbox=black,green entry=white,gray disentry=gray,black
    listbox=lightgray,black actlistbox=black,green sellistbox=green,black
    actsellistbox=black,green emptyscale=,gray fullscale=,green helpline=gray,black
    roottext=gray,black' \
    xterm -maximized -title "Connect to Wi-Fi, then Quit to start the installer" \
      -e nmtui connect || true
fi
dbus-run-session -- calamares &
session_pid=$!
until pgrep -x calamares > /dev/null; do
  sleep 1
done
# The boot test watches the serial console for this line (iso/test/boot-test.sh).
echo 'patina installer: ready' > /dev/console || true
wait "$session_pid"
