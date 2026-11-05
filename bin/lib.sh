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
# container, the image's first boot), so the data keeps the shape a user needs; without
# a terminal to ask in (the AI agent runs patina so) it asks through SUDO_ASKPASS.
run_words() {
  local -a words
  read -ra words <<< "$1"
  shift
  if [[ "${words[0]}" == sudo && "$EUID" -eq 0 ]]; then
    words=("${words[@]:1}")
  elif [[ "${words[0]}" == sudo && ! -t 0 && -n "${SUDO_ASKPASS:-}" ]]; then
    words=(sudo -A "${words[@]:1}")
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

# Is the tool of a manifest/upstream.yaml recipe installed? Each method has its own trace;
# a git recipe's is the ref patina install recorded, so a new ref counts as missing.
upstream_installed() {
  local key="$1" method command package ref file
  method="$(yq eval ".$key.method" "$PATINA_PATH/manifest/upstream.yaml")"
  command="$(yq eval ".$key.command // \"\"" "$PATINA_PATH/manifest/upstream.yaml")"
  package="$(yq eval ".$key.package // \"\"" "$PATINA_PATH/manifest/upstream.yaml")"
  case "$method" in
    binary) [[ -x "$HOME/.local/bin/$command" ]] ;;
    script) command -v "$command" > /dev/null ;;
    npm) [[ -e "$HOME/.local/lib/node_modules/$package" ]] ;;
    uv) command -v uv > /dev/null && uv tool list 2> /dev/null | grep -q "^$package " ;;
    apt-source) package_installed "$package" ;;
    git)
      # The ref recorded at install time, and the files the install left, which the
      # repository's own uninstall script may have removed since.
      ref="$(yq eval ".$key.ref" "$PATINA_PATH/manifest/upstream.yaml")"
      [[ "$(cat "$PATINA_STATE/upstream/$key" 2> /dev/null)" == "$ref" ]] || return 1
      while IFS= read -r file; do
        [[ -e "${XDG_DATA_HOME:-$HOME/.local/share}/$file" ]] || return 1
      done < <(yq eval ".$key.data_files // [] | .[]" "$PATINA_PATH/manifest/upstream.yaml")
      ;;
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

# The devices of devices/ this machine is: those with a detect map whose fields of
# /sys/class/dmi/id (PATINA_DMI overrides the directory) all equal the firmware's. A
# device without detect is never detected; its README says what to do by hand.
detected_devices() {
  local dmi="${PATINA_DMI:-/sys/class/dmi/id}" f key value match
  for f in "$PATINA_PATH"/devices/[a-z]*/device.yaml; do
    yq eval -e '.detect | length > 0' "$f" > /dev/null 2>&1 || continue
    match=1
    while IFS=$'\t' read -r key value; do
      if [[ ! "$key" =~ ^[a-z_]+$ || "$(cat "$dmi/$key" 2> /dev/null)" != "$value" ]]; then
        match=0
      fi
    done < <(yq eval '.detect | to_entries | .[] | .key + "\t" + .value' "$f")
    [[ $match -eq 0 ]] || basename "$(dirname "$f")"
  done
}

# Is the system running systemd (a real machine or VM), or is this a container?
booted_with_systemd() {
  [[ -d /run/systemd/system ]]
}

# Themes installed with `patina theme install`, outside the checkout: the checkout is
# ~/.local/share/patina, so nothing of the user's goes under that name.
PATINA_THEMES="${XDG_CONFIG_HOME:-$HOME/.config}/patina/themes"

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
  # PATINA_AI_AGENT=none, the installer's agent page, is no agent whatever PATINA_AI says.
  [[ "${PATINA_AI_AGENT:-}" != none ]] || ai=none
  [[ -n "$ai" ]] || ai="$(cat "$PATINA_STATE/ai" 2> /dev/null || true)"
  [[ -n "$ai" ]] || ai="$(yq eval '.ai.mode // "none"' "$PATINA_PATH/defaults/settings.yaml")"
  [[ "$ai" =~ ^(local|cloud|none)$ ]] || die "the AI agent is local, cloud or none, not '$ai'"
  echo "$ai"
}

# The AI agent: PATINA_AI_AGENT, else the one the last install recorded, else ai.agent of
# defaults/settings.yaml.
current_agent() {
  local agent="${PATINA_AI_AGENT:-}"
  [[ "$agent" != none ]] || agent=""
  [[ -n "$agent" ]] || agent="$(cat "$PATINA_STATE/ai-agent" 2> /dev/null || true)"
  [[ -n "$agent" ]] || agent="$(yq eval '.ai.agent // "opencode"' "$PATINA_PATH/defaults/settings.yaml")"
  [[ "$agent" =~ ^(opencode|hermes)$ ]] || die "the AI agent is opencode or hermes, not '$agent'"
  echo "$agent"
}

# The AI agents the questions offer (`patina install`, `patina ai on`), one line each:
# the agent, then what it is.
agent_lines() {
  printf '%-9s %s\n' opencode "opencode · free · asks before every change" \
    hermes "Hermes Agent · free · remembers · asks before risky commands only"
}

# The bundle that answers the AI question with this mode and agent (its `ai` and `agent`
# keys; no `agent` is opencode): ai_bundle <mode> [<agent>]; fails for none.
ai_bundle() {
  local b
  for b in $(all_bundles); do
    if [[ "$(yq eval '(.ai // "") + " " + (.agent // "opencode")' "$PATINA_PATH/manifest/bundles/$b.yaml")" == \
        "$1 ${2:-opencode}" ]]; then
      echo "$b"
      return
    fi
  done
  return 1
}

# The cloud providers an agent offers, as a yq expression on defaults/settings.yaml:
# offered_providers <agent>. Hermes has the ones with a `hermes` entry.
offered_providers() {
  if [[ "$1" == hermes ]]; then
    echo '.ai.cloud.providers[] | select(.hermes)'
  else
    echo '.ai.cloud.providers[]'
  fi
}

# The cloud provider: cloud_provider <agent>. PATINA_AI_PROVIDER, else the one the last
# install recorded if the agent offers it, else the first the agent offers.
cloud_provider() {
  local p="${PATINA_AI_PROVIDER:-}" settings="$PATINA_PATH/defaults/settings.yaml"
  if [[ -n "$p" ]]; then
    P="$p" yq eval -e "[$(offered_providers "$1") | select(.id == strenv(P))] | length > 0" "$settings" > /dev/null 2>&1 ||
      die "$1 offers no cloud provider '$p' (ai.cloud.providers in defaults/settings.yaml)"
  else
    p="$(cat "$PATINA_STATE/ai-provider" 2> /dev/null || true)"
    P="$p" yq eval -e "[$(offered_providers "$1") | select(.id == strenv(P))] | length > 0" "$settings" > /dev/null 2>&1 ||
      p="$(yq eval "[$(offered_providers "$1")][0].id" "$settings")"
  fi
  echo "$p"
}

# How the agent gets into a cloud provider (`login` of ai.cloud.providers): key, none or
# endpoint. provider_login <provider>
provider_login() {
  P="$1" yq eval '.ai.cloud.providers[] | select(.id == strenv(P)) | .login // "key"' \
    "$PATINA_PATH/defaults/settings.yaml"
}

# Can the agent use the provider now: its key in opencode's own login or Hermes' .env,
# nothing to log in to, or your own API's address (`patina ai login`)? ai_logged_in
# <agent> <provider>
ai_logged_in() {
  local key
  case "$(provider_login "$2")" in
    none) return 0 ;;
    endpoint) [[ -s "$PATINA_STATE/ai-endpoint.yaml" ]] ;;
    *)
      if [[ "$1" == hermes ]]; then
        key="$(P="$2" yq eval '.ai.cloud.providers[] | select(.id == strenv(P)) | .hermes.key // ""' \
          "$PATINA_PATH/defaults/settings.yaml")"
        [[ -n "$key" ]] && grep -q "^$key=." "${HERMES_HOME:-$HOME/.hermes}/.env" 2> /dev/null
      else
        P="$2" yq eval -e '.[strenv(P)]' "${XDG_DATA_HOME:-$HOME/.local/share}/opencode/auth.json" > /dev/null 2>&1
      fi
      ;;
  esac
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
  tpl[DISPLAY_FONT]="$(yq eval '.fonts.display' "$settings")"
  tpl[AGENT]="$(yq eval '.agent // "opencode"' "$settings")"
  # The agent CLI the `agent` action opens: Hermes while it is this machine's agent and
  # one of its bundles is installed. The record keeps every bundle installed so far, so a
  # machine that went back to opencode (`patina ai on opencode`) still lists Hermes'.
  if [[ " ${PATINA_BUNDLES:-} " =~ \ hermes-(local|cloud)\  && "$(current_agent)" == hermes ]]; then
    tpl[AGENT]=hermes
  fi
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
# Plain bash, no eval, no envsubst. The value is quoted: bash 5.2 (patsub_replacement)
# reads an unquoted & in it as the placeholder itself, so "A & B" came out "A ${NAME} B".
render() {
  local text name
  text="$(< "$1")"
  for name in "${!tpl[@]}"; do
    text="${text//\$\{$name\}/"${tpl[$name]}"}"
  done
  printf '%s\n' "$text" > "$2"
}

# The renderers' two ways of writing: install a rendered file only when it differs
# (put <src> <dest>), and remove what another theme left (drop_other_themes <glob>
# <keep>: the path to keep, or a prefix ending in "." for one theme's files, so the
# files of aurora-x never pass for aurora's). Both call the renderer's own say and
# changed.
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
    [[ "$f" == "$keep" || ( "$keep" == *. && "$f" == "$keep"* ) ]] && continue
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

# The ground the marks print on, dark or light: the variant the current theme shows in
# the mode in use (theme_vars' VARIANT). Dark when that cannot be told yet (no Go yq,
# no theme).
mark_ground() {
  local d mode
  if have_go_yq &&
      d="$(theme_dir "$(current_theme || yq eval '.theme' "$PATINA_PATH/defaults/settings.yaml")")" &&
      mode="$(current_mode)"; then
    if theme_has_mode "$d/theme.yaml" "$mode"; then echo "$mode"; else yq eval '.variant' "$d/theme.yaml"; fi
  else
    echo dark
  fi
}

# The mark, branding/logo.txt, which stays plain text without colour codes (serial
# console, /etc/issue.d). The colours are added here, at print time, and are the
# brand's, not the theme's, the same as in branding/wordmark.svg: the rings shade from
# deep violet (i) through violet (t) to lavender (n, a), the word patina is bold white,
# the survey point green. On a light ground the word is black, the ▲ aurora light's
# deeper green, and the rings shade from the same deep violet through darker violets,
# so the palest (a) still reads at 3:1. `print_logo auto|always [dark|light]`, the
# ground from mark_ground when not given.
print_logo() {
  local logo="$PATINA_PATH/branding/logo.txt"
  [[ -r "$logo" ]] || return 0
  if logo_colour "$1"; then
    local line head word tail part reset=$'\033[0m' ink=$'\033[1;38;2;245;247;249m'
    local point=$'\033[38;2;60;255;157m' ring_i=$'\033[38;2;109;79;194m'
    local ring_t=$'\033[38;2;155;107;255m' ring_n=$'\033[38;2;195;162;255m'
    local ring_a=$'\033[38;2;228;214;255m'
    local -a parts
    if [[ "${2:-$(mark_ground)}" == light ]]; then
      ink=$'\033[1;38;2;0;0;0m' point=$'\033[38;2;7;113;65m'
      # #8348ff, #965dff and #a374ff: 4.5, 3.7 and 3 to 1 on aurora light's #f7f6fb
      ring_t=$'\033[38;2;131;72;255m' ring_n=$'\033[38;2;150;93;255m'
      ring_a=$'\033[38;2;163;116;255m'
    fi
    while IFS= read -r line; do
      head="$line" word="" tail=""
      if [[ "$line" == *patina* ]]; then
        head="${line%%patina*}" word=patina tail="${line#*patina}"
      fi
      parts=()
      for part in "$head" "$tail"; do
        # The escape codes hold no i, t or n, so each pass leaves the earlier ones alone.
        part="${part//i/${ring_i}i$reset}"
        part="${part//t/${ring_t}t$reset}"
        part="${part//n/${ring_n}n$reset}"
        part="${part//a/${ring_a}a$reset}"
        parts+=("${part//▲/$point▲$reset}")
      done
      printf '%s%s%s\n' "${parts[0]}" "${word:+$ink$word$reset}" "${parts[1]}"
    done < "$logo"
  else
    cat "$logo"
  fi
}

# The wordmark, branding/wordmark.txt: patina in block letters over two contour lines,
# for the terminal surfaces that show the name (`patina help`, the install questions).
# The letters print white, the dot of the i (the ▲) green, the lines violet and deep
# violet; on a light ground the letters black and the ▲ aurora light's deeper green.
# `print_wordmark auto|always [dark|light]`, the ground from mark_ground when not given.
print_wordmark() {
  local file="$PATINA_PATH/branding/wordmark.txt" reset=$'\033[0m' i colour
  [[ -r "$file" ]] || return 0
  if logo_colour "$1"; then
    local ink=$'\033[38;2;245;247;249m' point=$'\033[38;2;60;255;157m'
    local -a lines
    if [[ "${2:-$(mark_ground)}" == light ]]; then
      ink=$'\033[38;2;0;0;0m' point=$'\033[38;2;7;113;65m'
    fi
    mapfile -t lines < "$file"
    for i in "${!lines[@]}"; do
      colour="$ink"
      (( i == ${#lines[@]} - 2 )) && colour=$'\033[38;2;155;107;255m'
      (( i == ${#lines[@]} - 1 )) && colour=$'\033[38;2;109;79;194m'
      printf '%s%s%s\n' "$colour" "${lines[i]//▲/$point▲$colour}" "$reset"
    done
  else
    cat "$file"
  fi
}

# The boot splash, Plymouth's two-step theme, drawn into <dir> from branding/logo.txt with
# the templates of defaults/boot/: progress-0001.png to progress-0048.png, which Plymouth
# picks by how far the boot has got, show the mark's rings arriving character by
# character, the outer rings first and each character at a time of its own, like a
# cloud condensing into contour lines; animation-0001.png to animation-0036.png, played
# once at the end, type the word in and light the ▲. Then the lock, field and bullet of
# the disk's password prompt, which two-step needs to load at all, and the theme file.
# The mark keeps the brand's colours (frame.svg); the ground and the prompt take the
# default theme's dark palette, as the boot menu does. The frame counts stay fixed:
# Plymouth loads every progress-*.png it finds, so fewer would need a migration that
# removes the rest. It loads the default theme into tpl, so callers run it in a subshell
# and keep their own: `( render_boot_splash <dir> )`. Needs yq, rsvg-convert and
# JetBrains Mono.
render_boot_splash() {
  local out="$1" boot="$PATINA_PATH/defaults/boot" settings="$PATINA_PATH/defaults/settings.yaml"
  local -a lines rows cols chars classes arrive
  local line r c ch cls k f n glyphs alpha x y width=0 word ring
  local -A rings=([i]=0 [t]=1 [n]=2 [a]=3)
  # Characters, not bytes, whatever the caller's locale: the ▲ is one.
  local LC_ALL=C.UTF-8
  theme_vars "$PATINA_PATH/themes/$(yq eval '.theme' "$settings")/theme.yaml" "$settings" dark
  mkdir -p "$out"
  mapfile -t lines < "$PATINA_PATH/branding/logo.txt"
  # Every character but the blanks: its place, its colour class and, for a ring, when
  # it arrives in thousandths of the progress pictures: its ring's start (the outermost
  # first) plus a share of its own from its place, the same on every run.
  for r in "${!lines[@]}"; do
    line="${lines[r]}"
    if (( ${#line} > width )); then width=${#line}; fi
    word=-1
    if [[ "$line" == *patina* ]]; then
      word="${line%%patina*}"
      word=${#word}
    fi
    for ((c = 0; c < ${#line}; c++)); do
      ch="${line:c:1}"
      [[ "$ch" != " " ]] || continue
      rows+=("$r") cols+=("$c") chars+=("$ch")
      if (( word >= 0 && c >= word && c < word + 6 )); then
        classes+=(w) arrive+=("$(( c - word ))")   # the word: its letters in order
      elif [[ "$ch" == "▲" ]]; then
        classes+=(p) arrive+=(0)
      else
        ring="${rings[$ch]}"
        classes+=("$ch")
        arrive+=("$(( ring * 170 + ((r * 7919 + c * 104729 + 3) * 2654435761 % 1000) * 280 / 1000 ))")
      fi
    done
  done
  # 30 px characters 18 px apart and 36 px lines apart, as the console sets them, with
  # room round them for the ▲'s glow.
  tpl[BOOT_WIDTH]=$(( width * 18 + 72 ))
  tpl[BOOT_HEIGHT]=$(( ${#lines[@]} * 36 + 72 ))
  tpl[BOOT_GROUND]="0x${tpl[BASE00]#\#}"
  # frame <name> <progress> <letters> <point>: the rings as far as <progress> (in
  # thousandths), the first <letters> of the word, the ▲ at <point> thousandths.
  frame() {
    glyphs=""
    for k in "${!chars[@]}"; do
      cls="${classes[k]}"
      case "$cls" in
        w) alpha=0; if (( arrive[k] < $3 )); then alpha=1000; fi ;;
        p) alpha="$4" ;;
        *) alpha=$(( ($2 - arrive[k]) * 1000 / 60 )); if (( alpha > 1000 )); then alpha=1000; fi ;;
      esac
      (( alpha > 0 )) || continue
      x=$(( 36 + cols[k] * 18 )) y=$(( 36 + rows[k] * 36 + 27 ))
      alpha="$(printf '%d.%03d' $(( alpha / 1000 )) $(( alpha % 1000 )))"
      if [[ "$cls" == p ]]; then
        glyphs+="  <text x=\"$x\" y=\"$y\" class=\"p\" filter=\"url(#glow)\" opacity=\"$alpha\">${chars[k]}</text>"$'\n'
      fi
      glyphs+="  <text x=\"$x\" y=\"$y\" class=\"$cls\" opacity=\"$alpha\">${chars[k]}</text>"$'\n'
    done
    tpl[BOOT_GLYPHS]="${glyphs%$'\n'}"
    render "$boot/frame.svg" "$out/$1.svg"
    rsvg-convert --output "$out/$1.png" "$out/$1.svg"
    rm "$out/$1.svg"
  }
  for ((f = 1; f <= 48; f++)); do
    frame "$(printf 'progress-%04d' "$f")" $(( f * 900 / 48 )) 0 0
  done
  # The end: a letter of the word every three pictures (a tenth of a second each at
  # Plymouth's 30 a second), then the ▲ fading in over twelve, then held.
  for ((f = 1; f <= 36; f++)); do
    n=$(( (f + 2) / 3 > 6 ? 6 : (f + 2) / 3 ))
    k=$(( f <= 18 ? 0 : (f >= 30 ? 1000 : (f - 18) * 1000 / 12) ))
    frame "$(printf 'animation-%04d' "$f")" 2000 "$n" "$k"
  done
  for f in entry bullet lock; do
    render "$boot/$f.svg" "$out/$f.svg"
    rsvg-convert --output "$out/$f.png" "$out/$f.svg"
    rm "$out/$f.svg"
  done
  render "$boot/patina.plymouth" "$out/patina.plymouth"
}

# A theme's wallpaper as a 1920x1080 PNG, cut to fill: raster_wallpaper <svg-jpg-or-png>
# <out.png>. A photograph goes through an SVG that holds it, written beside <out.png>.
raster_wallpaper() {
  case "$1" in
    *.svg) rsvg-convert --width 1920 --height 1080 --output "$2" "$1" ;;
    *.jpg)
      printf '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="1920" height="1080"><image width="1920" height="1080" preserveAspectRatio="xMidYMid slice" xlink:href="data:image/jpeg;base64,%s"/></svg>\n' \
        "$(base64 -w0 "$1")" > "$2.svg"
      rsvg-convert --width 1920 --height 1080 --output "$2" "$2.svg"
      rm "$2.svg"
      ;;
    *) cp "$1" "$2" ;;
  esac
}

# The boot menu, a GRUB theme, drawn into <dir> from the templates of defaults/boot/grub/:
# theme.txt; background.png, the default theme's first wallpaper under a veil with
# patina in block letters above the menu; font.pf2, fonts.monospace at <size> pixels,
# converted by grub-mkfont, since GRUB reads no other font format; and ground.png, the
# default theme's background, which GRUB's terminal shows once an entry boots, behind
# Debian's "Loading Linux" lines, instead of Debian's picture. <columns> is how many
# characters the menu's column holds on a 1920-pixel-wide screen: GRUB cannot centre
# the entries, and cuts off what is wider than the column. An installed system's menu,
# at the screen's own size, takes 20 pixels and 80 characters, so the recovery entries
# of its submenu ("patina / Debian 13 GNU/Linux, with Linux 6.12.115+deb13.1-amd64
# (recovery mode)") read whole; the live image's, at live-build's 800x600, 16 and 40
# ("Live system (amd64 fail-safe mode)" has 34). It loads the default theme into tpl,
# so callers run it in a subshell: `( render_boot_menu <dir> [<size> <columns>] )`.
# Needs yq, rsvg-convert, fc-match and grub-mkfont.
render_boot_menu() {
  local out="$1" size="${2:-20}" columns="${3:-80}" settings="$PATINA_PATH/defaults/settings.yaml"
  local tmp wide narrow share
  theme_vars "$PATINA_PATH/themes/$(yq eval '.theme' "$settings")/theme.yaml" "$settings" dark
  # JetBrains Mono's characters are three fifths of their size wide, rounded to whole
  # pixels as grub-mkfont draws them; the column has two pixels of padding each side.
  # GRUB sizes a column as a share of the screen plus pixels: <columns> characters
  # wide on a 1920-pixel screen, at most an 800-pixel one less 30 pixels each side (a
  # virtual machine's firmware gives GRUB 800x600), and in a line between and beyond.
  wide=$(( columns * ((size * 6 + 5) / 10) + 4 ))
  narrow=$(( wide < 740 ? wide : 740 ))
  share=$(( (wide - narrow) * 100 / 1120 ))
  share=$(( share - share % 2 ))   # percent, even, so half of it is whole
  tpl[MENU_SIZE]="$size"
  tpl[MENU_FONT]="${tpl[MONO_FONT]} Regular $size"
  tpl[MENU_WIDTH]="${share}%+$(( narrow - share * 8 ))"
  tpl[MENU_LEFT]="$(( 50 - share / 2 ))%-$(( (narrow - share * 8) / 2 ))"
  tpl[MENU_ITEM]=$(( size + 4 ))
  tpl[MENU_SPACING]=$(( size * 3 / 8 ))
  tpl[MENU_LABEL]=$(( size * 25 / 8 ))
  tpl[MENU_BOTTOM]=$(( size * 5 ))
  mkdir -p "$out"
  tmp="$(mktemp -d)"
  raster_wallpaper "${tpl[WALLPAPER_FIRST]}" "$tmp/wallpaper.png"
  rsvg-convert --width 1160 --output "$tmp/blocks.png" "$PATINA_PATH/branding/export/wordmark-blocks.svg"
  render "$PATINA_PATH/defaults/boot/grub/background.svg" "$tmp/background.svg"
  rsvg-convert --width 1920 --height 1080 --output "$out/background.png" "$tmp/background.svg"
  printf '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16"><rect width="16" height="16" fill="%s"/></svg>\n' \
    "${tpl[BASE00]}" > "$tmp/ground.svg"
  rsvg-convert --output "$out/ground.png" "$tmp/ground.svg"
  # Named as the theme names it, whichever file fontconfig finds; grub-mkfont warns about
  # every OpenType feature it leaves out.
  grub-mkfont --name "${tpl[MONO_FONT]}" --size "$size" --output "$out/font.pf2" \
    "$(fc-match --format '%{file}' "${tpl[MONO_FONT]}:style=Regular")" 2> /dev/null
  render "$PATINA_PATH/defaults/boot/grub/theme.txt" "$out/theme.txt"
  rm -rf "$tmp"
}

# Can a file be written through the backend's sudo path right now: root already, sudo
# without a prompt, a terminal where sudo may ask once, or a password dialog?
system_writable() {
  [[ "$EUID" -eq 0 ]] || sudo -n true 2> /dev/null || [[ -t 0 ]] || [[ -n "${SUDO_ASKPASS:-}" ]]
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
