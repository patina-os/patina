#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Nothing of the user's lives in the checkout any more: themes installed with `patina
# theme install` move from its themes/ to ~/.config/patina/themes, and the renderers'
# own files (the fastfetch mark, the start menu's button) to ~/.local/state/patina. The
# theme is rendered again with its panel layout, since the bar's button points at the
# old place; that also brings the bar along the edge of defaults/settings.yaml.
set -euo pipefail

# shellcheck source=bin/lib.sh
source "$PATINA_PATH/bin/lib.sh"
# Only what git does not track: patina's own themes stay where they are.
while IFS= read -r dir; do
  dir="${dir%/}"
  name="$(basename "$dir")"
  if [[ -f "$PATINA_PATH/$dir/theme.yaml" && ! -e "$PATINA_THEMES/$name" ]]; then
    mkdir -p "$PATINA_THEMES"
    mv "$PATINA_PATH/$dir" "$PATINA_THEMES/$name"
    say "moved the theme $name to $PATINA_THEMES"
  fi
done < <(git -C "$PATINA_PATH" ls-files --others --directory -- themes/)
for f in logo.txt launcher.svg; do
  if [[ -e "$PATINA_PATH/$f" ]] && ! git -C "$PATINA_PATH" ls-files --error-unmatch "$f" > /dev/null 2>&1; then
    rm -f "$PATINA_PATH/$f"
  fi
done
if theme="$(current_theme)"; then
  "$PATINA_PATH/bin/patina" theme set "$theme" --layout
fi
