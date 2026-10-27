#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# The few functions bin/patina-<cmd> scripts share: messages, the state directory, the
# Go yq, this base's backend and its commands, what a bundle names. Sourced, never run.
set -euo pipefail

PATINA_PATH="${PATINA_PATH:?set by bin/patina}"
PATINA_STATE="${XDG_STATE_HOME:-$HOME/.local/state}/patina"
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

# Themes installed with `patina theme install`, outside the checkout.
PATINA_THEMES="${XDG_DATA_HOME:-$HOME/.local/share}/patina/themes"

# The directory of a theme: the repository's themes/ first, then the installed ones.
# Entries starting with _ are templates.
theme_dir() {
  local d
  [[ "$1" =~ ^[a-z0-9][a-z0-9-]*$ ]] || return 1
  for d in "$PATINA_PATH/themes/$1" "$PATINA_THEMES/$1"; do
    if [[ -f "$d/theme.yaml" ]]; then
      echo "$d"
      return
    fi
  done
  return 1
}

# The theme the last `patina theme set` or `patina install` recorded; fails when none.
current_theme() {
  [[ -s "$PATINA_STATE/theme" ]] && cat "$PATINA_STATE/theme"
}

# The mode, dark or light: PATINA_MODE, else what `patina theme mode` recorded, else
# the `mode` of defaults/settings.yaml.
current_mode() {
  local mode="${PATINA_MODE:-}"
  [[ -n "$mode" ]] || mode="$(cat "$PATINA_STATE/mode" 2> /dev/null || true)"
  [[ -n "$mode" ]] || mode="$(yq eval '.mode // "dark"' "$PATINA_PATH/defaults/settings.yaml")"
  [[ "$mode" =~ ^(dark|light)$ ]] || die "the mode is dark or light, not '$mode'"
  echo "$mode"
}

# The AI agent, local, cloud or none: PATINA_AI, else what the last `patina install`
# recorded, else `ai.mode` of defaults/settings.yaml.
current_ai() {
  local ai="${PATINA_AI:-}"
  [[ -n "$ai" ]] || ai="$(cat "$PATINA_STATE/ai" 2> /dev/null || true)"
  [[ -n "$ai" ]] || ai="$(yq eval '.ai.mode // "none"' "$PATINA_PATH/defaults/settings.yaml")"
  [[ "$ai" =~ ^(local|cloud|none)$ ]] || die "the AI agent is local, cloud or none, not '$ai'"
  echo "$ai"
}

# The bundle that answers the AI question with this mode (its `ai` key); fails for none.
ai_bundle() {
  local b
  for b in $(all_bundles); do
    if [[ "$(yq eval '.ai // ""' "$PATINA_PATH/manifest/bundles/$b.yaml")" == "$1" ]]; then
      echo "$b"
      return
    fi
  done
  return 1
}

# Does a theme have this mode: its own variant, or a block named after the other one
# (`light:` in a dark theme) with a palette? theme_has_mode <theme.yaml> <mode>
theme_has_mode() {
  [[ "$2" =~ ^(dark|light)$ ]] || return 1
  [[ "$(yq eval '.variant' "$1")" == "$2" ]] || yq eval -e ".$2.palette" "$1" > /dev/null 2>&1
}

# ---- a theme as template variables ----------------------------------------------------
# Load a theme and defaults/settings.yaml into the global tpl[] array: the metadata, the
# Plasma hints, the fonts, the agent, and every palette colour as hex (BASE00) and as the
# r,g,b decimals KDE's files want (BASE00_RGB). ACCENT and ACCENT_ALT are the palette
# keys the theme names as `accent` and `accent_alt` (base0E and base0F when it names
# none). WALLPAPER_FIRST is the absolute path of the theme's default wallpaper. The
# optional mode picks the theme's other palette: in a dark theme with a `light:` block,
# `light` takes that block's palette (complete on its own) and its wallpapers and
# Plasma hints where it has them; VARIANT says which mode the palette is. Without a
# mode, or for one the theme does not have, the theme's own palette stays. The desktop
# renderer and the image build fill their templates from the same array, so no colour
# is ever copied by hand.
# theme_vars <theme.yaml> <settings.yaml> [dark|light]
theme_vars() {
  local theme_yaml="$1" settings="$2" mode="${3:-}" b pal=.palette key hex first role ref
  declare -gA tpl=()
  tpl[VARIANT]="$(yq eval '.variant' "$theme_yaml")"
  if [[ -n "$mode" && "$mode" != "${tpl[VARIANT]}" ]] && theme_has_mode "$theme_yaml" "$mode"; then
    tpl[VARIANT]="$mode"
    pal=".$mode.palette"   # the other mode's palette is complete on its own
  fi
  b=".${tpl[VARIANT]}"   # the mode's block; absent for the theme's own variant
  tpl[THEME]="$(yq eval '.name' "$theme_yaml")"
  tpl[DISPLAY_NAME]="$(yq eval '.display_name' "$theme_yaml")"
  tpl[AUTHOR]="$(yq eval '.author' "$theme_yaml")"
  tpl[LICENSE]="$(yq eval '.license' "$theme_yaml")"
  tpl[ARTWORK_LICENSE]="$(yq eval '.artwork_license' "$theme_yaml")"
  tpl[ICONS]="$(yq eval "$b.plasma.icons // .plasma.icons // \"breeze\"" "$theme_yaml")"
  tpl[CURSORS]="$(yq eval "$b.plasma.cursors // .plasma.cursors // \"breeze_cursors\"" "$theme_yaml")"
  tpl[DESKTOP_THEME]="$(yq eval "$b.plasma.desktop_theme // .plasma.desktop_theme // \"default\"" "$theme_yaml")"
  tpl[UI_FONT]="$(yq eval '.fonts.ui' "$settings")"
  tpl[MONO_FONT]="$(yq eval '.fonts.monospace' "$settings")"
  tpl[AGENT]="$(yq eval '.agent // "opencode"' "$settings")"
  first="$(yq eval "($b.wallpapers // .wallpapers)[0] // \"\"" "$theme_yaml")"
  tpl[WALLPAPER_FIRST]="${first:+$(cd "$(dirname "$theme_yaml")" && pwd)/$first}"
  for key in 00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F; do
    hex="$(yq eval -e "$pal.base$key" "$theme_yaml")" || die "$pal has no base$key"
    [[ "$hex" =~ ^#[0-9a-fA-F]{6}$ ]] || die "base$key is not a #rrggbb colour: $hex"
    tpl[BASE$key]="$hex"
    tpl[BASE${key}_RGB]="$(printf '%d,%d,%d' "0x${hex:1:2}" "0x${hex:3:2}" "0x${hex:5:2}")"
  done
  for role in accent:base0E accent_alt:base0F; do
    ref="$(yq eval ".${role%%:*} // \"${role#*:}\"" "$theme_yaml")"
    [[ "$ref" =~ ^base0[0-9A-F]$ ]] || die "${role%%:*} must name a palette key (base00..base0F), not '$ref'"
    key="${role%%:*}"
    tpl[${key^^}]="${tpl[BASE${ref:4}]}"
    tpl[${key^^}_RGB]="${tpl[BASE${ref:4}_RGB]}"
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

# The renderers' two ways of writing: install a rendered file only when it differs
# (put <src> <dest>), and remove what another theme left (drop_other_themes <glob>
# <keep-prefix>). Both call the renderer's own say and changed.
put() {
  local src="$1" dest="$2"
  if cmp -s "$src" "$dest"; then
    return
  fi
  say "writing $dest"
  install -D -m 0644 "$src" "$dest"
  changed
}

drop_other_themes() {
  local pattern="$1" keep="$2" f
  for f in $pattern; do
    [[ -e "$f" ]] || continue
    [[ "$f" == "$keep"* ]] && continue
    say "removing $f (another theme)"
    rm -rf "$f"
    changed
  done
}

# Colour for a mark: `auto` only on an interactive 24-bit terminal (NO_COLOR wins),
# `always` in any case (the file fastfetch shows).
logo_colour() {
  [[ "$1" == always ]] || [[ -t 1 && -z "${NO_COLOR:-}" && "${TERM:-dumb}" != "dumb" &&
    ( "${COLORTERM:-}" == "truecolor" || "${COLORTERM:-}" == "24bit" ) ]]
}

# The mark, branding/logo.txt, which stays plain text without colour codes (serial
# console, /etc/issue.d). The colours are added here, at print time, and are the
# brand's, not the theme's, the same as in branding/wordmark.svg: the rings shade from
# deep violet (i) through violet (t) to lavender (n, a), the word patina is bold white,
# the survey point green. `print_logo auto|always`.
print_logo() {
  local logo="$PATINA_PATH/branding/logo.txt"
  [[ -r "$logo" ]] || return 0
  if logo_colour "$1"; then
    local line head word tail part reset=$'\033[0m'
    local -a parts
    while IFS= read -r line; do
      head="$line" word="" tail=""
      if [[ "$line" == *patina* ]]; then
        head="${line%%patina*}" word=patina tail="${line#*patina}"
      fi
      parts=()
      for part in "$head" "$tail"; do
        # The escape codes hold no i, t or n, so each pass leaves the earlier ones alone.
        part="${part//i/$'\033[38;2;109;79;194m'i$reset}"
        part="${part//t/$'\033[38;2;155;107;255m't$reset}"
        part="${part//n/$'\033[38;2;195;162;255m'n$reset}"
        part="${part//a/$'\033[38;2;228;214;255m'a$reset}"
        parts+=("${part//▲/$'\033[38;2;60;255;157m'▲$reset}")
      done
      printf '%s%s%s\n' "${parts[0]}" "${word:+$'\033[1;38;2;245;247;249m'$word$reset}" "${parts[1]}"
    done < "$logo"
  else
    cat "$logo"
  fi
}

# The wordmark, branding/wordmark.txt: patina in block letters over two contour lines,
# for the terminal surfaces that show the name (`patina help`, the install questions).
# The letters print white, the dot of the i (the ▲) green, the lines violet and deep
# violet.
# `print_wordmark auto|always`.
print_wordmark() {
  local file="$PATINA_PATH/branding/wordmark.txt" reset=$'\033[0m' i colour
  [[ -r "$file" ]] || return 0
  if logo_colour "$1"; then
    local -a lines
    mapfile -t lines < "$file"
    for i in "${!lines[@]}"; do
      colour=$'\033[38;2;245;247;249m'
      (( i == ${#lines[@]} - 2 )) && colour=$'\033[38;2;155;107;255m'
      (( i == ${#lines[@]} - 1 )) && colour=$'\033[38;2;109;79;194m'
      printf '%s%s%s\n' "$colour" "${lines[i]//▲/$'\033[38;2;60;255;157m'▲$colour}" "$reset"
    done
  else
    cat "$file"
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
  export GUM_CHOOSE_CURSOR_FOREGROUND="${tpl[ACCENT_ALT]}"
  export GUM_CHOOSE_HEADER_FOREGROUND="${tpl[ACCENT]}"
  export GUM_CHOOSE_SELECTED_FOREGROUND="${tpl[ACCENT_ALT]}"
  export GUM_CHOOSE_ITEM_FOREGROUND="${tpl[BASE05]}"
  export GUM_CONFIRM_PROMPT_FOREGROUND="${tpl[BASE05]}"
  export GUM_CONFIRM_SELECTED_BACKGROUND="${tpl[ACCENT]}"
  export GUM_CONFIRM_SELECTED_FOREGROUND="${tpl[BASE00]}"
  export GUM_CONFIRM_UNSELECTED_BACKGROUND="${tpl[BASE02]}"
  export GUM_CONFIRM_UNSELECTED_FOREGROUND="${tpl[BASE05]}"
}
