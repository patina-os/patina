#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# The popups' glass is darker (60 %) with a light rim, and Plasma's lists take a faint
# selection inside a thin edge: render the theme already set here again. Idempotent like
# `patina theme set`.
set -euo pipefail

# shellcheck source=bin/lib.sh
source "$PATINA_PATH/bin/lib.sh"
if theme="$(current_theme)"; then
  "$PATINA_PATH/bin/patina" theme set "$theme"
fi
