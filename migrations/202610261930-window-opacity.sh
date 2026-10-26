#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Windows gained a touch of transparency (windows.opacity in defaults/settings.yaml) and
# the bar's glyphs one height: render the theme already set here again, so the KWin
# rule and the evened icons arrive. Idempotent like `patina theme set`.
set -euo pipefail

# shellcheck source=bin/lib.sh
source "$PATINA_PATH/bin/lib.sh"
if theme="$(current_theme)"; then
  "$PATINA_PATH/bin/patina" theme set "$theme"
fi
