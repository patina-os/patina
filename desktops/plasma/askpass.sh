#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# sudo's password dialog for the AI agent, which has no terminal for sudo to ask in.
set -euo pipefail

# `sudo -A` starts this (SUDO_ASKPASS) and reads the password from stdout; sudo's own
# prompt, its argument, only repeats the dialog's field. Cancel prints nothing and
# exits 1, so sudo gives up. kdialog draws in the theme's Plasma colours and fonts,
# with patina's mark as its window icon.
mark="${XDG_STATE_HOME:-$HOME/.local/state}/patina/launcher.svg"
args=()
[[ -f "$mark" ]] && args=(--icon "$mark")
exec kdialog "${args[@]}" --title "patina · administrator password" --password \
  "<b>A command you allowed needs administrator rights.</b><br>Enter your password, or cancel if you did not expect this."
