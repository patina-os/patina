#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# The agent's allow-list loses "cat *", "ls*", "git diff*" and "git log*": opencode
# matches the whole command, so they let a redirect or --output overwrite a file without
# asking. Merging settings never removes a key, so they leave opencode.json here, with a
# backup next to it; the install `patina update` runs afterwards merges the rest (web
# fetches ask, and so does any command with a redirect). A fresh install never writes
# them.
set -euo pipefail

# shellcheck source=bin/lib.sh
source "$PATINA_PATH/bin/lib.sh"
file="$HOME/.config/opencode/opencode.json"
[[ -f "$file" ]] || exit 0
yq eval '.' "$file" > /dev/null 2>&1 || {
  warn "cannot parse $file (comments?); remove the allow rules \"cat *\", \"ls*\", \"git diff*\" and \"git log*\" by hand"
  exit 0
}
# The keys matched literally: yq reads * in a path or after == as a wildcard, which would
# also take lsblk* or a rule of the user's such as "lsof *".
old='^(cat \\*|ls\\*|git diff\\*|git log\\*)$'
yq eval -e ".permission.bash // {} | to_entries | any_c(.key | test(\"$old\"))" "$file" > /dev/null 2>&1 ||
  exit 0
cp "$file" "$file.bak"
yq eval -i -o=json ".permission.bash |= with_entries(select(.key | test(\"$old\") | not))" "$file"
say "opencode: the agent asks before cat, ls, git diff and git log now ($file.bak keeps the old file)"
