#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Write the installer's choice pages as JSON for Try patina's setup window: patina-setup.json.
set -euo pipefail
# TryPatina.exe (patina-os/win-emulator) asks on Windows what the installer asks on a
# PC. It reads the pages from this file, a release asset next to the disk image, so it
# shows what patina offers rather than a copy: each page as Calamares has it after
# iso/live/assets.sh filled it in (its default, the themes, the English and German
# words), with each picture inline, and the first boot's key the answer goes to, as
# modules/shellprocess-firstboot.conf writes it (pages with the same key are joined
# with commas, in this order). The window takes its colours and fonts from the default
# theme and the settings, as every screen of patina's does. Run after iso/live/build.sh,
# with its build directory.
usage() { echo "usage: choices.sh <live-build-dir> <patina-setup.json>" >&2; }
[[ $# -eq 2 ]] || { usage; exit 64; }
repo="$(cd "$(dirname "$(readlink -f "$0")")/../.." && pwd)"
calamares="$1/config/includes.chroot/etc/calamares"
json="$2"
settings="$repo/defaults/settings.yaml"
theme="$repo/themes/$(yq eval '.theme' "$settings")/theme.yaml"
command -v yq > /dev/null || { echo "choices.sh: yq missing" >&2; exit 69; }
[[ -d "$calamares/modules" ]] || { echo "choices.sh: no rendered installer in $1" >&2; exit 66; }

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
pages=()
for page in agent:PATINA_AI_AGENT ai:PATINA_AI apps:PATINA_BUNDLES more:PATINA_BUNDLES \
  theme:PATINA_THEME; do
  id="${page%%:*}"
  conf="$calamares/modules/packagechooser-$id.conf"
  ID="$id" KEY="${page#*:}" yq eval -o json '{"id": strenv(ID), "key": strenv(KEY)} * .' \
    "$conf" > "$tmp/$id.json"
  for ((i = 0; i < $(yq eval '.items | length' "$conf"); i++)); do
    picture="$calamares/branding/patina/$(yq eval ".items[$i].screenshot" "$conf")"
    [[ -r "$picture" ]] || { echo "choices.sh: no picture $picture" >&2; exit 66; }
    base64 -w 0 "$picture" > "$tmp/picture"
    yq eval -i -p json -o json ".items[$i].picture = \"data:image/png;base64,\" + load_str(\"$tmp/picture\") |
      del(.items[$i].screenshot)" "$tmp/$id.json"
  done
  pages+=("$tmp/$id.json")
done
# The default theme's own palette (its variant, dark), with the accent and the second
# colour resolved from palette keys to colours, and the three fonts of the settings.
# shellcheck disable=SC2016 # $p is yq's variable, not the shell's
yq eval -o json '.palette as $p | {"theme": .name, "palette": ($p + {"accent": $p[.accent],
  "accent_alt": $p[.accent_alt]})}' "$theme" > "$tmp/look.json"
yq eval -o json '{"fonts": .fonts}' "$settings" > "$tmp/fonts.json"
# shellcheck disable=SC2016 # yq's variable
yq eval-all -p json -o json -I 0 '. as $page ireduce ({"pages": []}; .pages += [$page])' \
  "${pages[@]}" > "$tmp/pages.json"
# shellcheck disable=SC2016 # yq's variable
yq eval-all -p json -o json -I 0 '. as $part ireduce ({}; . * $part)' \
  "$tmp/look.json" "$tmp/fonts.json" "$tmp/pages.json" > "$json"
echo "choices.sh: $(yq eval -p json -o yaml '.pages | length' "$json") pages in $json ($(du -h "$json" | cut -f1))"
