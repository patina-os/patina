#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Render a theme into the terminal and the tools that run in it, for every desktop:
# kitty, the fastfetch greeting, btop, neovim, bat and fzf. `apply.sh <theme-dir>`.
set -euo pipefail

here="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
PATINA_PATH="${PATINA_PATH:-$(cd "$here/../.." && pwd)}"
theme_dir="${1:?usage: apply.sh <theme-dir>}"
theme_yaml="$theme_dir/theme.yaml"
[[ -f "$theme_yaml" ]] || { echo "terminal: no theme.yaml in $theme_dir" >&2; exit 1; }
templates="$here/templates"

config="${XDG_CONFIG_HOME:-$HOME/.config}"
data="${XDG_DATA_HOME:-$HOME/.local/share}"
changes=0

# shellcheck source=bin/lib.sh
source "$PATINA_PATH/bin/lib.sh"
say() { printf 'patina: terminal: %s\n' "$*"; }
warn() { printf 'patina: terminal: %s\n' "$*" >&2; }
changed() { changes=$((changes + 1)); }

mode="$(current_mode)"
theme_vars "$theme_yaml" "$PATINA_PATH/defaults/settings.yaml" "$mode"
tpl[DATA_HOME]="$data"
tpl[ACCENT_SGR]="38;2;${tpl[ACCENT_RGB]//,/;}"   # the accent as an ANSI colour, for fastfetch
theme="${tpl[THEME]}"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# Write a user's configuration file only while its first line is ours, so a user who
# removes that line keeps their own: ours <template> <dest>.
ours() {
  if [[ ! -e "$2" || "$(head -n 1 "$2")" == *"patina:"* ]]; then
    render "$1" "$tmp/ours"
    put "$tmp/ours" "$2"
  fi
}

# kitty: the palette as its sixteen colours plus the base16 extras (16 to 21), so every
# tool that draws with the terminal's colours follows the theme. The include line is
# added once, above whatever the user keeps in kitty.conf.
render "$templates/kitty.conf" "$tmp/kitty.conf"
put "$tmp/kitty.conf" "$config/kitty/patina.conf"
if ! grep -qxF 'include patina.conf' "$config/kitty/kitty.conf" 2> /dev/null; then
  say "kitty.conf: adding the include line"
  mkdir -p "$config/kitty"
  {
    printf '# patina: the theme and fonts; keep your own settings below this line.\n'
    printf 'include patina.conf\n'
    if [[ -f "$config/kitty/kitty.conf" ]]; then
      cat "$config/kitty/kitty.conf"
    fi
  } > "$tmp/kitty.conf.new"
  mv "$tmp/kitty.conf.new" "$config/kitty/kitty.conf"
  changed
fi

# The agent's quieter kitty profile, only with an AI bundle (ai-local, ai-cloud) or the
# agents bundle installed; the desktop binds the `agent` action to it.
if [[ " ${PATINA_BUNDLES:-} " =~ \ (agents|ai-local|ai-cloud)\  ]]; then
  render "$templates/kitty-agent.conf" "$tmp/kitty-agent.conf"
  put "$tmp/kitty-agent.conf" "$config/kitty/patina-agent.conf"
elif [[ -e "$config/kitty/patina-agent.conf" ]]; then
  say "removing $config/kitty/patina-agent.conf (no AI or agents bundle is installed)"
  rm -f "$config/kitty/patina-agent.conf"
  changed
fi

# fastfetch greets a new terminal with the mark: a coloured copy of branding/logo.txt
# (the file itself stays plain) and a configuration that points at it.
print_logo always > "$tmp/logo.txt"
put "$tmp/logo.txt" "$data/patina/logo.txt"
ours "$templates/fastfetch.jsonc" "$config/fastfetch/config.jsonc"

# btop: a theme file from the palette, made btop's colour theme unless the user picked
# another one. btop rewrites btop.conf itself and keeps the key; a btop.conf that does
# not exist yet gets just this key, and btop adds its defaults on the first exit.
btop_theme="$config/btop/themes/patina-$theme.theme"
render "$templates/btop.theme" "$tmp/btop.theme"
put "$tmp/btop.theme" "$btop_theme"
drop_other_themes "$config/btop/themes/patina-*.theme" "$btop_theme"
btop_conf="$config/btop/btop.conf"
btop_now="$(sed -n 's/^color_theme *= *"\(.*\)"$/\1/p' "$btop_conf" 2> /dev/null || true)"
case "$btop_now" in
  "$btop_theme") ;;
  "" | Default | */btop/themes/patina-*.theme)
    if grep -q '^color_theme *=' "$btop_conf" 2> /dev/null; then
      sed "s|^color_theme *=.*|color_theme = \"$btop_theme\"|" "$btop_conf" > "$tmp/btop.conf"
    else
      { cat "$btop_conf" 2> /dev/null || true; printf 'color_theme = "%s"\n' "$btop_theme"; } > "$tmp/btop.conf"
    fi
    put "$tmp/btop.conf" "$btop_conf"
    ;;
  *) say "btop: keeping your colour theme ($btop_now)" ;;
esac

# neovim: a colour scheme from the palette, and a plugin file that turns it on when the
# user's own configuration chose none.
render "$templates/nvim-colors.lua" "$tmp/nvim-colors.lua"
put "$tmp/nvim-colors.lua" "$config/nvim/colors/patina-$theme.lua"
drop_other_themes "$config/nvim/colors/patina-*.lua" "$config/nvim/colors/patina-$theme."
ours "$templates/nvim-plugin.lua" "$config/nvim/plugin/patina.lua"

# bat, git-delta and fzf draw with the terminal's colours, so they follow every theme
# without a file per theme: bat through its own configuration, delta (which reads
# BAT_THEME) and fzf through the session's environment, read by systemd at login.
ours "$templates/bat-config" "$config/bat/config"
ours "$templates/environment.conf" "$config/environment.d/60-patina.conf"

if [[ $changes -eq 0 ]]; then
  say "nothing to do"
else
  say "$changes change(s); a running btop or neovim picks the theme up at its next start"
fi
