#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# kitty gained padding and a slightly see-through background (its patina.conf): render
# the theme already set here again, so they arrive. Idempotent like `patina theme set`.
set -euo pipefail

# shellcheck source=bin/lib.sh
source "$PATINA_PATH/bin/lib.sh"
if theme="$(current_theme)"; then
  "$PATINA_PATH/bin/patina" theme set "$theme"
fi
