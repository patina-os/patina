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
# The installer at the screen's size. Qt 6 scales Calamares by X's Xft.dpi, and xterm
# sizes the Wi-Fi step's font by it, but nothing sets it on this bare session, so it is
# set here from the physical size the screen reports (xrandr, from its EDID): its dots
# per inch over 96, rounded down to a quarter, as Windows picks 150 % for a 13.3" Full
# HD panel, and never so large that the pages get less than 1280x720, the size they
# were checked at. A screen that reports no size (a virtual machine's) stays at 100 %.
# Once the display has resources, xterm no longer reads ~/.Xdefaults itself, so they go
# along. xinit keeps its connection open, so X keeps them until the session ends.
quarters=4
while read -r line; do
  if [[ "$line" =~ \ connected\ (primary\ )?([0-9]+)x([0-9]+)\+.*\ ([1-9][0-9]*)mm\ x\ [0-9]+mm$ ]]; then
    width="${BASH_REMATCH[2]}" height="${BASH_REMATCH[3]}" mm="${BASH_REMATCH[4]}"
    quarters=$(( width * 1016 / (mm * 960) ))
    (( quarters <= width * 4 / 1280 )) || quarters=$(( width * 4 / 1280 ))
    (( quarters <= height * 4 / 720 )) || quarters=$(( height * 4 / 720 ))
    (( quarters >= 4 )) || quarters=4
    break
  fi
done < <(xrandr --query 2> /dev/null)
if (( quarters > 4 )); then
  { cat /root/.Xdefaults; echo "Xft.dpi: $(( quarters * 24 ))"; } | xrdb -nocpp -merge
fi
openbox &
# The Wi-Fi step: the installer needs the internet and has no page to join a wireless
# network, so a computer without a default route but with a Wi-Fi card first gets
# NetworkManager's own nmtui, full screen in the palette (~/.Xdefaults, rendered by
# assets.sh, maps the slots NEWT_COLORS names: green is the accent; newt paints a focused
# compact button, nmtui's kind, with the button slot; whiptail is newt too). Once the
# computer is online the installer starts by itself (wifi-step.sh); leaving the
# installer brings the step back while the computer is still offline, as
# patina-ui.service starts this session again.
if [[ -z "$(ip route show default 2> /dev/null)" ]] &&
    nmcli -t -f TYPE device 2> /dev/null | grep -qx wifi; then
  NEWT_COLORS='root=lightgray,black window=lightgray,black border=green,black
    shadow=black,black title=green,black label=lightgray,black textbox=lightgray,black
    button=black,green actbutton=black,green compactbutton=lightgray,black
    checkbox=lightgray,black actcheckbox=black,green entry=white,gray disentry=gray,black
    listbox=lightgray,black actlistbox=black,green sellistbox=green,black
    actsellistbox=black,green emptyscale=,gray fullscale=,green helpline=gray,black
    roottext=gray,black' \
    xterm -maximized -title "Connect to Wi-Fi to start the installer" \
      -e /root/wifi-step.sh || true
fi
# Calamares' mount step turns the new system's swap on for the live system, which has
# none of its own, and nothing turns it off: after a failed install the next try found
# the disk in use and offered no "Erase disk". A fresh start of the installer finds
# every swap off.
swapoff -a 2> /dev/null || true
dbus-run-session -- calamares &
session_pid=$!
until pgrep -x calamares > /dev/null; do
  sleep 1
done
# The boot test watches the serial console for this line (iso/test/boot-test.sh).
echo 'patina installer: ready' > /dev/console || true
wait "$session_pid"
