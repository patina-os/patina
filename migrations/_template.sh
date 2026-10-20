#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Migration template: copy to migrations/YYYYMMDDHHMM-<slug>.sh and replace this line
# with what the migration changes. Must be idempotent; see migrations/README.md.
set -euo pipefail

# Example: move a state file to its new location, only if the old one still exists.
# old="$HOME/.local/state/patina21/theme"
# new="$HOME/.local/state/patina21/current-theme"
# if [[ -f "$old" && ! -e "$new" ]]; then
#   mv "$old" "$new"
# fi
