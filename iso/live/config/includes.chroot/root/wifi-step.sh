#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# The live image's Wi-Fi step, which root/.xinitrc runs full screen before the installer.
set -euo pipefail

online() {
  [[ -n "$(ip route show default 2> /dev/null)" ]]
}

# nmtui keeps a network with the password it was given and does not ask again when
# joining fails: a router that also speaks WPA3 reports a wrong password as "The Wi-Fi
# network could not be found". Its list cannot forget a network either, so the step
# forgets the Wi-Fi networks that never connected and are not connecting now, and
# picking one again asks for its password.
forget_failed() {
  local uuid type stamp active
  nmcli -t -f UUID,TYPE,TIMESTAMP,ACTIVE connection show 2> /dev/null |
    while IFS=: read -r uuid type stamp active; do
      if [[ "$type" == 802-11-wireless && "$stamp" == 0 && "$active" == no ]]; then
        nmcli connection delete uuid "$uuid" > /dev/null 2>&1 || true
      fi
    done || true
}

# nmtui until the computer is online, which ends the step by itself (nobody has to find
# nmtui's Quit), or until the user starts the installer without a network (to plug in
# a cable there, say). Beside nmtui, once a second, a network that failed is forgotten
# and the step looks for the internet.
while true; do
  forget_failed
  (
    until online; do
      sleep 1
      forget_failed
    done
    pkill -x nmtui || true
  ) &
  watcher=$!
  nmtui connect || true
  kill "$watcher" 2> /dev/null || true
  if online; then
    whiptail --title "Connected" --infobox "The installer starts." 7 40
    sleep 2
    exit 0
  fi
  whiptail --title "Not connected" --yes-button "Try again" --no-button "Start installer" \
    --yesno "The installer needs the internet.\n\nTry again to pick a network and type its password again." \
    10 66 || exit 0
done
