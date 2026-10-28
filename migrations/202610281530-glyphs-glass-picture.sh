#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# The apps' glyphs take the text colour again (only the start menu's categories keep the
# accent), the glass is stronger with KWin's blur on, and the user's picture is the
# small mark: render the theme already set here again. Idempotent like `patina theme set`.
set -euo pipefail

# shellcheck source=bin/lib.sh
source "$PATINA_PATH/bin/lib.sh"
if theme="$(current_theme)"; then
  "$PATINA_PATH/bin/patina" theme set "$theme"
fi
