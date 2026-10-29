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
yq eval -e '.permission.bash // {} | has("cat *") or has("ls*") or has("git diff*") or has("git log*")' \
  "$file" > /dev/null 2>&1 || exit 0
cp "$file" "$file.bak"
yq eval -i -o=json 'del(.permission.bash["cat *"], .permission.bash["ls*"],
  .permission.bash["git diff*"], .permission.bash["git log*"])' "$file"
say "opencode: the agent asks before cat, ls, git diff and git log now ($file.bak keeps the old file)"
