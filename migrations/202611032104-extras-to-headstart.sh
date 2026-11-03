#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# The extras bundle became headstart: a machine that recorded extras records headstart,
# so the install `patina update` ends with brings the new apps. Tauon stays installed;
# patina removes nothing (`flatpak uninstall --user com.github.taiko2k.tauonmb` does).
set -euo pipefail

state="$PATINA_STATE/bundles"
if [[ -f "$state" ]] && grep -qx 'extras' "$state"; then
  cp "$state" "$state.bak"
  awk '{ if ($0 == "extras") $0 = "headstart" } NF && !seen[$0]++' "$state.bak" > "$state.new"
  mv "$state.new" "$state"
fi
