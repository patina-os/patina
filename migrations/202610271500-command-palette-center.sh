#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# The command palette opens in the middle of the screen (command_palette.position in
# defaults/settings.yaml): render the theme already set here again, so KRunner's
# position arrives. Idempotent like `patina theme set`.
set -euo pipefail

# shellcheck source=bin/lib.sh
source "$PATINA_PATH/bin/lib.sh"
if theme="$(current_theme)"; then
  "$PATINA_PATH/bin/patina" theme set "$theme"
fi
