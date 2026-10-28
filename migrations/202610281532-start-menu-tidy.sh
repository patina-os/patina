#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# The start menu as the layout script now sets it up: the apps by their names alone,
# compact lists, one power button without a caption. Written into the start menus of the
# running Plasma session through its scripting API, so the rest of the panels stays the
# user's; outside a session, `patina theme set <theme> --layout` brings it.
set -euo pipefail

# shellcheck source=bin/lib.sh
source "$PATINA_PATH/bin/lib.sh"
if ! dbus-send --session --print-reply --dest=org.freedesktop.DBus /org/freedesktop/DBus \
    org.freedesktop.DBus.NameHasOwner string:org.kde.plasmashell 2> /dev/null | grep -q 'boolean true'; then
  say "start menu: no Plasma session here; patina theme set <theme> --layout tidies it"
  exit 0
fi
script='panels().forEach(function (p) {
  p.widgets("org.kde.plasma.kickoff").forEach(function (w) {
    w.currentConfigGroup = ["General"];
    w.writeConfig("appNameFormat", 0);
    w.writeConfig("compactMode", true);
    w.writeConfig("primaryActions", 2);
    w.writeConfig("systemFavorites", ["shutdown"]);
    w.writeConfig("showActionButtonCaptions", false);
  });
});'
dbus-send --session --print-reply --dest=org.kde.plasmashell /PlasmaShell \
  org.kde.PlasmaShell.evaluateScript "string:$script" > /dev/null
say "start menu: names only, compact lists, one power button"
