#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# The few functions bin/patina-<cmd> scripts share: messages, the state directory, the
# Go yq, this base's backend and its commands, what a bundle names. Sourced, never run.
set -euo pipefail

PATINA_PATH="${PATINA_PATH:?set by bin/patina}"
PATINA_STATE="${XDG_STATE_HOME:-$HOME/.local/state}/patina21"
export PATINA_STATE
export PATH="$HOME/.local/bin:$PATH"   # where yq and the upstream tools land

say() { printf 'patina: %s\n' "$*"; }
warn() { printf 'patina: %s\n' "$*" >&2; }
die() { warn "$@"; exit 1; }

# The Go yq (mikefarah) is the only YAML parser the layer uses. Debian's yq package is
# the Python jq wrapper; its --version line does not name mikefarah.
have_go_yq() {
  command -v yq > /dev/null && yq --version 2> /dev/null | grep -q mikefarah
}

need_yq() {
  have_go_yq || die "the Go yq is missing; 'patina install' fetches it (manifest/upstream.yaml)"
}

# The backend file that serves this base: ID= from /etc/os-release against os_ids.
backend_file() {
  local id f
  # shellcheck source=/dev/null
  id="$(. /etc/os-release && echo "${ID:-}")"
  for f in "$PATINA_PATH"/manifest/backends/[a-z]*.yaml; do
    if yq eval -e ".os_ids[] | select(. == \"$id\")" "$f" > /dev/null 2>&1; then
      echo "$f"
      return
    fi
  done
  die "no backend in manifest/backends/ serves ID=$id (see manifest/README.md)"
}

# Run a command given as one string from a data file, plus arguments. The string is
# split on blanks, never eval'ed. A leading sudo is dropped when already root (the CI
# container, the image's first boot), so the data keeps the shape a user needs.
run_words() {
  local -a words
  read -ra words <<< "$1"
  shift
  if [[ "${words[0]}" == sudo && "$EUID" -eq 0 ]]; then
    words=("${words[@]:1}")
  fi
  "${words[@]}" "$@"
}

# Run the backend command under <key> (refresh, install, installed, system.write).
backend_run() {
  local key="$1" cmd
  shift
  cmd="$(yq eval -e ".$key" "$BACKEND" 2> /dev/null)" || die "$(basename "$BACKEND") has no '$key'"
  run_words "$cmd" "$@"
}

package_installed() {
  backend_run installed "$1" > /dev/null 2>&1
}

flatpak_installed() {
  command -v flatpak > /dev/null && flatpak info --user "$1" > /dev/null 2>&1
}

# Is the tool of a manifest/upstream.yaml recipe installed? Each method has its own trace.
upstream_installed() {
  local key="$1" method command package
  method="$(yq eval ".$key.method" "$PATINA_PATH/manifest/upstream.yaml")"
  command="$(yq eval ".$key.command // \"\"" "$PATINA_PATH/manifest/upstream.yaml")"
  package="$(yq eval ".$key.package // \"\"" "$PATINA_PATH/manifest/upstream.yaml")"
  case "$method" in
    binary) [[ -x "$HOME/.local/bin/$command" ]] ;;
    script) command -v "$command" > /dev/null ;;
    npm) [[ -e "$HOME/.local/lib/node_modules/$package" ]] ;;
    uv) command -v uv > /dev/null && uv tool list 2> /dev/null | grep -q "^$package " ;;
    apt-source) package_installed "$package" ;;
    *) die "unknown upstream method '$method' for $key" ;;
  esac
}

all_bundles() {
  local f
  for f in "$PATINA_PATH"/manifest/bundles/[a-z]*.yaml; do
    basename "$f" .yaml
  done
}

default_bundles() {
  local b
  for b in $(all_bundles); do
    if yq eval -e '.required == true or .default == true' \
        "$PATINA_PATH/manifest/bundles/$b.yaml" > /dev/null 2>&1; then
      echo "$b"
    fi
  done
}

# The bundles the last `patina install` recorded, or the defaults before any install.
recorded_bundles() {
  if [[ -s "$PATINA_STATE/bundles" ]]; then
    cat "$PATINA_STATE/bundles"
  else
    default_bundles
  fi
}

# Every entry under <list> (packages, flatpaks, upstream) of the given bundles, once each.
bundle_items() {
  local list="$1" b
  shift
  for b in "$@"; do
    yq eval ".${list}[]?" "$PATINA_PATH/manifest/bundles/$b.yaml"
  done | awk '!seen[$0]++'
}

# Is the system running systemd (a real machine or VM), or is this a container?
booted_with_systemd() {
  [[ -d /run/systemd/system ]]
}

# The directory of a theme under themes/; entries starting with _ are templates.
theme_dir() {
  local d="$PATINA_PATH/themes/$1"
  [[ "$1" == [a-z]* && -f "$d/theme.yaml" ]] || return 1
  echo "$d"
}

# The theme the last `patina theme set` or `patina install` recorded; fails when none.
current_theme() {
  [[ -s "$PATINA_STATE/theme" ]] && cat "$PATINA_STATE/theme"
}
