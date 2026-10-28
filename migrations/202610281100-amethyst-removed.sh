#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# amethyst, the first theme, was removed: a machine still on it moves to the default of
# defaults/settings.yaml, which also removes amethyst's rendered files.
set -euo pipefail

# shellcheck source=bin/lib.sh
source "$PATINA_PATH/bin/lib.sh"
if [[ "$(current_theme || true)" == amethyst ]]; then
  "$PATINA_PATH/bin/patina" theme set "$(yq eval '.theme' "$PATINA_PATH/defaults/settings.yaml")"
fi
