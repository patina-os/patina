#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# The live image's Wi-Fi step, which root/.xinitrc runs full screen before the installer.
set -euo pipefail

# nmtui until the computer is online, or until the user starts the installer without a
# network (to plug in a cable there, say). nmtui keeps a network with the password it
# was given and does not ask again when joining it fails: a router that also speaks
# WPA3 reports a wrong password as "The Wi-Fi network could not be found". Its list
# cannot forget a network either, so each round forgets the Wi-Fi networks that never
# connected, and picking one again asks for its password.
while true; do
  nmcli -t -f UUID,TYPE,TIMESTAMP connection show 2> /dev/null |
    while IFS=: read -r uuid type stamp; do
      if [[ "$type" == 802-11-wireless && "$stamp" == 0 ]]; then
        nmcli connection delete uuid "$uuid" > /dev/null 2>&1 || true
      fi
    done || true
  nmtui connect || true
  [[ -z "$(ip route show default 2> /dev/null)" ]] || exit 0
  whiptail --title "Not connected" --yes-button "Try again" --no-button "Start installer" \
    --yesno "The installer needs the internet.\n\nTry again to pick a network and type its password again." \
    10 66 || exit 0
done
