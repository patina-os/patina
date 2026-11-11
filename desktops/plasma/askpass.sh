#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# sudo's password dialog for the AI agent, which has no terminal for sudo to ask in.
set -euo pipefail

# `sudo -A` starts this (SUDO_ASKPASS) and reads the password from stdout; sudo's own
# prompt, its argument, only repeats the dialog's field. Cancel prints nothing and
# exits 1, so sudo gives up.
#
# A notification asks first, and the dialog opens from its button: a window that opens
# by itself takes the keyboard on Wayland (KWin gives every new window the focus, and a
# window rule cannot keep it), so what the user typed elsewhere went into the password
# field, and the dialog covered their work. The notification is critical, so it stays
# until answered, in Do Not Disturb too. sudo asks again right after a wrong password,
# and then the dialog opens at once, since the user is at it; without notify-send or a
# notification server it opens at once too. kdialog draws in the theme's Plasma colours
# and fonts, with patina's mark as its window icon.
mark="${XDG_STATE_HOME:-$HOME/.local/state}/patina/launcher.svg"
last="${XDG_RUNTIME_DIR:-}/patina-askpass"
icon=()
[[ -f "$mark" ]] && icon=(--icon "$mark")
if [[ -n "${XDG_RUNTIME_DIR:-}" && -f "$last" && $(($(date +%s) - $(stat -c %Y "$last"))) -lt 10 ]]; then
  :   # sudo asks again after a wrong password
elif command -v notify-send > /dev/null &&
  picked="$(notify-send --app-name=patina "${icon[@]}" --urgency=critical --expire-time=0 \
    --action=default="Enter password" --action=enter="Enter password" --action=cancel=Cancel \
    "Administrator password" "A command you allowed needs administrator rights.")"; then
  [[ "$picked" == default || "$picked" == enter ]] || exit 1   # Cancel, or closed
  kill -0 "$PPID" 2> /dev/null || exit 1   # the command was stopped meanwhile
fi
kdialog "${icon[@]}" --title "patina · administrator password" --password \
  "<b>A command you allowed needs administrator rights.</b><br>Enter your password, or cancel if you did not expect this."
[[ -z "${XDG_RUNTIME_DIR:-}" ]] || touch "$last"
