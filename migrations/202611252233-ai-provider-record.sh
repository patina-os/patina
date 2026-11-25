#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# The cloud agent's provider as the user picked it: from 0.1.0-alpha.12 to .15 a second
# `patina install` emptied the record before it read it and wrote Mistral, the first
# provider, in its place, and the next install, often an update's, pointed the agent at
# Mistral, which the user never logged in to. Where the record names a provider the agent
# has no key for, it takes the one the agent's own file names if that one has its key or
# address, else the first provider that has (your own API, say); never Big Pickle, which
# needs none. The install that follows `patina update` points the agent at it again.
set -euo pipefail

# shellcheck source=bin/lib.sh
source "$PATINA_PATH/bin/lib.sh"
[[ "$(cat "$PATINA_STATE/ai" 2> /dev/null || true)" == cloud ]] || exit 0
agent="$(cat "$PATINA_STATE/ai-agent" 2> /dev/null || echo opencode)"
now="$(cat "$PATINA_STATE/ai-provider" 2> /dev/null || true)"
settings="$PATINA_PATH/defaults/settings.yaml"
[[ -z "$now" ]] || ! ai_logged_in "$agent" "$now" || exit 0
named=""
if [[ "$agent" == opencode ]]; then
  model="$(yq eval -r '.model // ""' "${XDG_CONFIG_HOME:-$HOME/.config}/opencode/opencode.json" 2> /dev/null || true)"
  named="${model%%/*}"
fi
found=""
for p in "$named" $(yq eval "$(offered_providers "$agent") | .id" "$settings"); do
  [[ -n "$p" && "$p" != "$now" && "$(provider_login "$p")" != none ]] || continue
  P="$p" yq eval -e "[$(offered_providers "$agent") | select(.id == strenv(P))] | length > 0" "$settings" \
    > /dev/null 2>&1 || continue
  if ai_logged_in "$agent" "$p"; then
    found="$p"
    break
  fi
done
if [[ -z "$found" ]]; then
  say "ai: ${now:-no provider} has no key yet; patina ai login picks the provider and logs in"
  exit 0
fi
cp "$PATINA_STATE/ai-provider" "$PATINA_STATE/ai-provider.bak" 2> /dev/null || true
echo "$found" > "$PATINA_STATE/ai-provider"
say "ai: the agent's provider is $(P="$found" yq eval '.ai.cloud.providers[] | select(.id == strenv(P)) | .name' "$settings") again (the record said ${now:-nothing}, which has no key)"
