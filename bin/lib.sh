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

# ---- a theme as template variables ----------------------------------------------------
# Load a theme and defaults/settings.yaml into the global tpl[] array: the metadata, the
# Plasma hints, the fonts, the agent, and every palette colour as hex (BASE00) and as the
# r,g,b decimals KDE's files want (BASE00_RGB). WALLPAPER_FIRST is the absolute path of
# the theme's default wallpaper. The desktop renderer and the image build fill their
# templates from the same array, so no colour is ever copied by hand.
theme_vars() {
  local theme_yaml="$1" settings="$2" key hex first
  declare -gA tpl=()
  tpl[THEME]="$(yq eval '.name' "$theme_yaml")"
  tpl[DISPLAY_NAME]="$(yq eval '.display_name' "$theme_yaml")"
  tpl[AUTHOR]="$(yq eval '.author' "$theme_yaml")"
  tpl[LICENSE]="$(yq eval '.license' "$theme_yaml")"
  tpl[ARTWORK_LICENSE]="$(yq eval '.artwork_license' "$theme_yaml")"
  tpl[VARIANT]="$(yq eval '.variant' "$theme_yaml")"
  tpl[ICONS]="$(yq eval '.plasma.icons // "breeze"' "$theme_yaml")"
  tpl[CURSORS]="$(yq eval '.plasma.cursors // "breeze_cursors"' "$theme_yaml")"
  tpl[DESKTOP_THEME]="$(yq eval '.plasma.desktop_theme // "default"' "$theme_yaml")"
  tpl[UI_FONT]="$(yq eval '.fonts.ui' "$settings")"
  tpl[MONO_FONT]="$(yq eval '.fonts.monospace' "$settings")"
  tpl[AGENT]="$(yq eval '.agent // "opencode"' "$settings")"
  first="$(yq eval '.wallpapers[0] // ""' "$theme_yaml")"
  tpl[WALLPAPER_FIRST]="${first:+$(cd "$(dirname "$theme_yaml")" && pwd)/$first}"
  for key in 00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F; do
    hex="$(yq eval -e ".palette.base$key" "$theme_yaml")" || die "palette has no base$key"
    [[ "$hex" =~ ^#[0-9a-fA-F]{6}$ ]] || die "base$key is not a #rrggbb colour: $hex"
    tpl[BASE$key]="$hex"
    tpl[BASE${key}_RGB]="$(printf '%d,%d,%d' "0x${hex:1:2}" "0x${hex:3:2}" "0x${hex:5:2}")"
  done
}

# Fill the ${NAME} placeholders of a template from tpl[]: render <template> <out>.
# Plain bash, no eval, no envsubst.
render() {
  local text name
  text="$(< "$1")"
  for name in "${!tpl[@]}"; do
    text="${text//\$\{$name\}/${tpl[$name]}}"
  done
  printf '%s\n' "$text" > "$2"
}

# The ASCII mark, branding/logo.txt, which stays plain 7-bit ASCII (serial console,
# /etc/issue.d, README). The pink-to-purple gradient is added here, at print time:
# `print_logo auto` only for an interactive 24-bit terminal, `print_logo always` in any
# case (the file fastfetch shows). The gradient is the brand's, not the theme's: a green
# theme still prints it pink.
print_logo() {
  local mode="$1" logo="$PATINA_PATH/branding/logo.txt"
  [[ -r "$logo" ]] || return 0
  if [[ "$mode" == always ]] || [[ -t 1 && -z "${NO_COLOR:-}" && "${TERM:-dumb}" != "dumb" &&
        ( "${COLORTERM:-}" == "truecolor" || "${COLORTERM:-}" == "24bit" ) ]]; then
    local -a lines
    mapfile -t lines < "$logo"
    local n=${#lines[@]} i r g b
    for i in "${!lines[@]}"; do
      if (( n > 1 )); then
        r=$(( 255 + (139 - 255) * i / (n - 1) ))
        g=$(( 95 + (92 - 95) * i / (n - 1) ))
        b=$(( 208 + (246 - 208) * i / (n - 1) ))
      else
        r=255 g=95 b=208
      fi
      printf '\033[38;2;%d;%d;%dm%s\033[0m\n' "$r" "$g" "$b" "${lines[i]}"
    done
  else
    cat "$logo"
  fi
}

# Can a file be written through the backend's sudo path right now: root already, sudo
# without a prompt, or a terminal where sudo may ask once?
system_writable() {
  [[ "$EUID" -eq 0 ]] || sudo -n true 2> /dev/null || [[ -t 0 ]]
}

# gum's styles from the palette, for the install TUI; call after theme_vars. Flags
# override these, and gum degrades the hex colours on a 16-colour console.
tui_colors() {
  export GUM_CHOOSE_CURSOR_FOREGROUND="${tpl[BASE0F]}"
  export GUM_CHOOSE_HEADER_FOREGROUND="${tpl[BASE0E]}"
  export GUM_CHOOSE_SELECTED_FOREGROUND="${tpl[BASE0F]}"
  export GUM_CHOOSE_ITEM_FOREGROUND="${tpl[BASE05]}"
  export GUM_CONFIRM_PROMPT_FOREGROUND="${tpl[BASE05]}"
  export GUM_CONFIRM_SELECTED_BACKGROUND="${tpl[BASE0E]}"
  export GUM_CONFIRM_SELECTED_FOREGROUND="${tpl[BASE00]}"
  export GUM_CONFIRM_UNSELECTED_BACKGROUND="${tpl[BASE02]}"
  export GUM_CONFIRM_UNSELECTED_FOREGROUND="${tpl[BASE05]}"
}
