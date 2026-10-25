#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# The marks moved to aurora's violet and green, and the renderers gained the accent
# roles and the light mode: render the theme already set here again, so the greeting,
# the splash and the accents follow. The user's theme stays; aurora, the new default,
# is one `patina theme set aurora` away. Idempotent like `patina theme set`.
set -euo pipefail

# shellcheck source=bin/lib.sh
source "$PATINA_PATH/bin/lib.sh"
if theme="$(current_theme)"; then
  "$PATINA_PATH/bin/patina" theme set "$theme"
  [[ "$theme" == aurora ]] || say "the new default theme is aurora, made for OLED: patina theme set aurora"
fi
