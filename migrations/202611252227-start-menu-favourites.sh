#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# The start menu's favourites without Plasma's own (its browser slot, which could be
# Konqueror, Kontact, System Settings and Discover), with Firefox ESR and Dolphin among
# patina's: in the running Plasma session, through the activity manager that keeps the
# favourites of every start menu. Favourites the user added stay; outside a session it
# waits for the next `patina update` in one.
set -euo pipefail

# shellcheck source=bin/lib.sh
source "$PATINA_PATH/bin/lib.sh"
if ! dbus-send --session --print-reply --dest=org.freedesktop.DBus /org/freedesktop/DBus \
    org.freedesktop.DBus.NameHasOwner string:org.kde.ActivityManager 2> /dev/null | grep -q 'boolean true'; then
  say "start menu: no Plasma session here; the next patina update in one brings patina's favourites"
  exit 75   # not recorded: patina-migrate runs it again (migrations/README.md)
fi
link() {
  dbus-send --session --print-reply --dest=org.kde.ActivityManager \
    /ActivityManager/Resources/Linking "org.kde.ActivityManager.ResourcesLinking.$1" \
    string:org.kde.plasma.favorites.applications "string:$2" "string:$3" > /dev/null
}
for res in preferred://browser applications:org.kde.kontact.desktop \
    applications:systemsettings.desktop applications:org.kde.discover.desktop; do
  link UnlinkResourceFromActivity "$res" :any || true
done
for app in firefox-esr.desktop org.kde.dolphin.desktop; do
  [[ -f "/usr/share/applications/$app" ]] || continue
  link LinkResourceToActivity "applications:$app" :global ||
    warn "start menu: $app is not among the favourites"
done
say "start menu: patina's favourites, with Firefox ESR and Dolphin, without Plasma's own"
