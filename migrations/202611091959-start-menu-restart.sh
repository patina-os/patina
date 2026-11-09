#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# The start menu's restart button, beside shut down, as the layout script now sets it
# up: written into the start menus of the running Plasma session that still have the one
# power button patina gave them (shut down), so a menu the user changed stays theirs;
# outside a session, `patina theme set <theme> --layout` brings it with the whole bar.
set -euo pipefail

# shellcheck source=bin/lib.sh
source "$PATINA_PATH/bin/lib.sh"
if ! dbus-send --session --print-reply --dest=org.freedesktop.DBus /org/freedesktop/DBus \
    org.freedesktop.DBus.NameHasOwner string:org.kde.plasmashell 2> /dev/null | grep -q 'boolean true'; then
  say "start menu: no Plasma session here; patina theme set <theme> --layout brings the restart button"
  exit 0
fi
script='panels().forEach(function (p) {
  p.widgets("org.kde.plasma.kickoff").forEach(function (w) {
    w.currentConfigGroup = ["General"];
    if (String(w.readConfig("systemFavorites")) === "shutdown") {
      w.writeConfig("systemFavorites", ["reboot", "shutdown"]);
    }
  });
});'
dbus-send --session --print-reply --dest=org.kde.plasmashell /PlasmaShell \
  org.kde.PlasmaShell.evaluateScript "string:$script" > /dev/null
say "start menu: restart beside shut down (from the next login if not at once)"
