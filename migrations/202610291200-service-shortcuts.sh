#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# The shortcuts that launch an app (Meta+Return, Meta+B, Meta+A, Meta+K, Print) are
# written in Plasma 6's form, the chord alone, Meta+Space reaches KRunner, and the
# splash shows a rendering of the wordmark: render the theme already set here again.
# Idempotent like `patina theme set`.
set -euo pipefail

# shellcheck source=bin/lib.sh
source "$PATINA_PATH/bin/lib.sh"
if theme="$(current_theme)"; then
  "$PATINA_PATH/bin/patina" theme set "$theme"
fi
