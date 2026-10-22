#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Render a theme and defaults/ into KDE Plasma's configuration for this user: colour
# schemes, terminal profiles, wallpapers, a look-and-feel package, shortcuts and the
# curated settings. `apply.sh <theme-dir>`; idempotent, output only under XDG dirs.
set -euo pipefail

here="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
PATINA_PATH="${PATINA_PATH:-$(cd "$here/../.." && pwd)}"
theme_dir="${1:?usage: apply.sh <theme-dir>}"
theme_yaml="$theme_dir/theme.yaml"
[[ -f "$theme_yaml" ]] || { echo "plasma: no theme.yaml in $theme_dir" >&2; exit 1; }
settings="$PATINA_PATH/defaults/settings.yaml"
keybindings="$PATINA_PATH/defaults/keybindings.yaml"
actions="$here/actions.yaml"
templates="$here/templates"

config="${XDG_CONFIG_HOME:-$HOME/.config}"
data="${XDG_DATA_HOME:-$HOME/.local/share}"
agent_desktop="$data/applications/patina21-agent.desktop"
changes=0

say() { printf 'patina: theme: %s\n' "$*"; }
warn() { printf 'patina: theme: %s\n' "$*" >&2; }
changed() { changes=$((changes + 1)); }

# ---- the theme as template variables ------------------------------------------------
# tpl[NAME] fills ${NAME} in a template. Colours come as hex (BASE00) and as the r,g,b
# decimals KDE's files want (BASE00_RGB).
declare -A tpl
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
tpl[CONFIG_HOME]="$config"
tpl[WALLPAPER]=""
tpl[WALLPAPER_PACKAGE]=""
tpl[AGENT_COMMAND]=""
tpl[PANEL_FLOATING]="$(yq eval '.panel.floating // false' "$settings")"
tpl[PINNED_LAUNCHERS]=""
theme="${tpl[THEME]}"
[[ "$theme" == "$(basename "$theme_dir")" ]] ||
  warn "theme.yaml says name: $theme but the directory is $(basename "$theme_dir")"

for key in 00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F; do
  hex="$(yq eval -e ".palette.base$key" "$theme_yaml")" ||
    { warn "palette has no base$key"; exit 1; }
  [[ "$hex" =~ ^#[0-9a-fA-F]{6}$ ]] || { warn "base$key is not a #rrggbb colour: $hex"; exit 1; }
  tpl[BASE$key]="$hex"
  tpl[BASE${key}_RGB]="$(printf '%d,%d,%d' "0x${hex:1:2}" "0x${hex:3:2}" "0x${hex:5:2}")"
done

# Fill ${NAME} placeholders from tpl; plain bash, no eval, no envsubst.
render() {
  local text name
  text="$(< "$1")"
  for name in "${!tpl[@]}"; do
    text="${text//\$\{$name\}/${tpl[$name]}}"
  done
  printf '%s\n' "$text" > "$2"
}

# Install a rendered file only when it differs from what is there.
put() {
  local src="$1" dest="$2"
  if cmp -s "$src" "$dest"; then
    return
  fi
  say "writing $dest"
  install -D -m 0644 "$src" "$dest"
  changed
}

# Write one key with kwriteconfig6 when its value differs: kset <rc> <key> <value> <group>...
# The rc is a name under ~/.config or an absolute path, as the tool takes it.
kset() {
  local file="$1" key="$2" value="$3" g
  shift 3
  local -a groups=()
  for g in "$@"; do
    groups+=(--group "$g")
  done
  if [[ "$(kreadconfig6 --file "$file" "${groups[@]}" --key "$key")" == "$value" ]]; then
    return
  fi
  say "$file: [$*] $key=$value"
  kwriteconfig6 --file "$file" "${groups[@]}" --key "$key" "$value"
  changed
}

# Delete one key when it is set: kdel <rc> <key> <group>...
kdel() {
  local file="$1" key="$2" g
  shift 2
  local -a groups=()
  for g in "$@"; do
    groups+=(--group "$g")
  done
  if [[ -z "$(kreadconfig6 --file "$file" "${groups[@]}" --key "$key")" ]]; then
    return
  fi
  say "$file: [$*] $key removed"
  kwriteconfig6 --file "$file" "${groups[@]}" --key "$key" --delete
  changed
}

# The .desktop file an action of defaults/keybindings.yaml launches, through
# actions.yaml; empty (with a warning) when the action has none or it is not installed.
service_installed() {
  [[ -f "$data/applications/$1" || -f /usr/share/applications/$1 || -f /usr/local/share/applications/$1 ]]
}
service_for_action() {
  local action="$1" service
  service="$(yq eval ".actions[\"$action\"].service // \"\"" "$actions")"
  if [[ "$service" == default-web-browser ]]; then
    service="$(xdg-settings get default-web-browser 2> /dev/null || true)"
    if [[ -z "$service" ]]; then
      warn "$action: no default web browser is set (xdg-settings); skipping"
      return
    fi
  fi
  if [[ -z "$service" ]]; then
    return
  fi
  if [[ "$service" == patina21-agent.desktop && ! -f "$agent_desktop" ]]; then
    return   # the agents bundle is not installed
  fi
  if ! service_installed "$service"; then
    warn "$action: $service is not installed; skipping"
    return
  fi
  echo "$service"
}

# Everything generated carries the theme in its name; what belongs to another theme
# goes, so switching themes leaves nothing behind.
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

# ---- files: colour schemes, terminals, wallpapers, the look-and-feel package --------
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

render "$templates/color-scheme.colors" "$tmp/colors"
put "$tmp/colors" "$data/color-schemes/patina21-$theme.colors"
drop_other_themes "$data/color-schemes/patina21-*.colors" "$data/color-schemes/patina21-$theme."

render "$templates/konsole.colorscheme" "$tmp/konsole.colorscheme"
put "$tmp/konsole.colorscheme" "$data/konsole/patina21-$theme.colorscheme"
render "$templates/konsole.profile" "$tmp/konsole.profile"
put "$tmp/konsole.profile" "$data/konsole/patina21-$theme.profile"
drop_other_themes "$data/konsole/patina21-*" "$data/konsole/patina21-$theme."

render "$templates/kitty.conf" "$tmp/kitty.conf"
put "$tmp/kitty.conf" "$config/kitty/patina21.conf"
if ! grep -qxF 'include patina21.conf' "$config/kitty/kitty.conf" 2> /dev/null; then
  say "kitty.conf: adding the include line"
  mkdir -p "$config/kitty"
  {
    printf '# patina21: the theme and fonts; keep your own settings below this line.\n'
    printf 'include patina21.conf\n'
    if [[ -f "$config/kitty/kitty.conf" ]]; then
      cat "$config/kitty/kitty.conf"
    fi
  } > "$tmp/kitty.conf.new"
  mv "$tmp/kitty.conf.new" "$config/kitty/kitty.conf"
  changed
fi

# Wallpapers: one Plasma wallpaper package per image. An SVG is rendered once, at 4K,
# and again only when the theme's file is newer than the rendering (a git pull sets
# the time); a PNG is copied as it is.
wallpaper_dir=""
wallpaper_pkgs=" "
while IFS= read -r rel; do
  src="$theme_dir/$rel"
  name="$(basename "${rel%.*}")"
  pkg="$data/wallpapers/patina21-$theme-$name"
  png="$pkg/contents/images/3840x2160.png"
  wallpaper_pkgs="$wallpaper_pkgs$pkg "
  if [[ ! -f "$src" ]]; then
    warn "wallpaper $rel is not in the theme; skipping it"
    continue
  fi
  case "$src" in
    *.svg)
      if [[ ! -e "$png" || "$src" -nt "$png" ]]; then
        if command -v rsvg-convert > /dev/null; then
          say "rendering $rel"
          mkdir -p "$(dirname "$png")"
          rsvg-convert --width 3840 --height 2160 --output "$tmp/wallpaper.png" "$src"
          mv "$tmp/wallpaper.png" "$png"
          changed
        else
          warn "rsvg-convert is missing (librsvg2-bin in the base bundle); $rel is not rendered"
          continue
        fi
      fi
      ;;
    *) put "$src" "$png" ;;
  esac
  tpl[WALLPAPER]="$name"
  render "$templates/wallpaper-metadata.json" "$tmp/wallpaper.json"
  put "$tmp/wallpaper.json" "$pkg/metadata.json"
  [[ -n "$wallpaper_dir" ]] || wallpaper_dir="$pkg"   # the first one is the default
done < <(yq eval '.wallpapers[]?' "$theme_yaml")
for pkg in "$data"/wallpapers/patina21-*; do
  [[ -d "$pkg" ]] || continue
  if [[ "$wallpaper_pkgs" != *" $pkg "* ]]; then
    say "removing $pkg (not in this theme)"
    rm -rf "$pkg"
    changed
  fi
done

# The look-and-feel package: Plasma's own way to hand a new session its colours,
# icons, cursors and wallpaper at once, so a fresh user gets the theme at first login.
tpl[WALLPAPER_PACKAGE]="${wallpaper_dir:+$wallpaper_dir/}"
lnf="$data/plasma/look-and-feel/org.patina21.$theme"
render "$templates/look-and-feel-metadata.json" "$tmp/lnf.json"
put "$tmp/lnf.json" "$lnf/metadata.json"
render "$templates/look-and-feel-defaults" "$tmp/lnf.defaults"
put "$tmp/lnf.defaults" "$lnf/contents/defaults"
drop_other_themes "$data/plasma/look-and-feel/org.patina21.*" "$lnf"

# The agent terminal profile and launcher, only with the agents bundle installed.
if [[ " ${PATINA_BUNDLES:-} " == *" agents "* ]]; then
  tpl[AGENT_COMMAND]="$(command -v "${tpl[AGENT]}" 2> /dev/null || echo "${tpl[AGENT]}")"
  render "$templates/kitty-agent.conf" "$tmp/kitty-agent.conf"
  put "$tmp/kitty-agent.conf" "$config/kitty/patina21-agent.conf"
  render "$templates/agent.desktop" "$tmp/agent.desktop"
  put "$tmp/agent.desktop" "$agent_desktop"
else
  for f in "$config/kitty/patina21-agent.conf" "$agent_desktop"; do
    if [[ -e "$f" ]]; then
      say "removing $f (the agents bundle is not installed)"
      rm -f "$f"
      changed
    fi
  done
fi

finish() {
  if [[ $changes -eq 0 ]]; then
    say "nothing to do"
  else
    say "$changes change(s)"
  fi
}

# The panel layout, as the look-and-feel package's layout script: Plasma runs it for a
# session without panels (the first login) and `patina theme set --layout` for an
# existing one. The pinned launchers are the apps behind the actions panel.pinned names.
layout="$lnf/contents/layouts/org.kde.plasma.desktop-layout.js"
if [[ "$(yq eval '.panel.layout' "$settings")" == centered ]]; then
  pinned=""
  while IFS= read -r action; do
    service="$(service_for_action "$action")"
    [[ -n "$service" ]] || continue
    pinned="$pinned${pinned:+, }\"applications:$service\""
  done < <(yq eval '.panel.pinned[]?' "$settings")
  tpl[PINNED_LAUNCHERS]="$pinned"
  render "$templates/layout.js" "$tmp/layout.js"
  put "$tmp/layout.js" "$layout"
elif [[ -e "$layout" ]]; then
  say "removing $layout (panel.layout is not centered)"
  rm -f "$layout"
  changed
fi

# ---- settings: kdeglobals, kwin, baloo, shortcuts, GTK; through kwriteconfig6 --------
if ! command -v kwriteconfig6 > /dev/null || ! command -v kreadconfig6 > /dev/null; then
  warn "kwriteconfig6 is missing (is Plasma installed?); the files are in place, the settings are not"
  finish
  exit 0
fi

font="${tpl[UI_FONT]},10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
kset kdeglobals ColorScheme "patina21-$theme" General
kset kdeglobals AccentColor "${tpl[BASE0E_RGB]}" General
kset kdeglobals accentColorFromWallpaper false General
kset kdeglobals font "$font" General
kset kdeglobals menuFont "$font" General
kset kdeglobals toolBarFont "$font" General
kset kdeglobals smallestReadableFont "${tpl[UI_FONT]},8,-1,5,400,0,0,0,0,0,0,0,0,0,0,1" General
kset kdeglobals fixed "${tpl[MONO_FONT]},10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1" General
kset kdeglobals activeFont "$font" WM
kset kdeglobals LookAndFeelPackage "org.patina21.$theme" KDE
kset kdeglobals widgetStyle Breeze KDE
kset kdeglobals Theme "${tpl[ICONS]}" Icons
kset kcminputrc cursorTheme "${tpl[CURSORS]}" Mouse
kset plasmarc name "${tpl[DESKTOP_THEME]}" Theme
kset konsolerc DefaultProfile "patina21-$theme.profile" "Desktop Entry"
if [[ -n "$wallpaper_dir" ]]; then
  kset kscreenlockerrc Image "$wallpaper_dir/" Greeter Wallpaper org.kde.image General
fi

# The speed settings from defaults/settings.yaml.
kset kdeglobals AnimationDurationFactor "$(yq eval '.speed.animation_speed' "$settings")" KDE
case "$(yq eval '.speed.latency' "$settings")" in
  lowest) latency=LatencyExtremelyLow ;;
  low) latency=LatencyLow ;;
  balanced) latency=LatencyMedium ;;
  smooth) latency=LatencyHigh ;;
  smoothest) latency=LatencyExtremelyHigh ;;
  *) latency="" ;;
esac
[[ -z "$latency" ]] || kset kwinrc LatencyPolicy "$latency" Compositing
case "$(yq eval '.speed.file_indexing' "$settings")" in
  off) kset baloofilerc Indexing-Enabled false "Basic Settings" ;;
  names)
    kset baloofilerc Indexing-Enabled true "Basic Settings"
    kset baloofilerc "only basic indexing" true General
    kset baloofilerc folders "$HOME/" General
    ;;
  content)
    kset baloofilerc Indexing-Enabled true "Basic Settings"
    kset baloofilerc "only basic indexing" false General
    kset baloofilerc folders "$HOME/" General
    ;;
esac

# Windows: where a new one opens, and the size of a new main window as a KWin rule
# applied once at its first appearance. The size is a share of the screen, so the rule
# needs a screen: inside a session it comes from kscreen-doctor (the output with
# priority 1, else the first enabled one); outside, the rule waits for the next
# `patina theme set` in a session.
in_session=0
[[ "${XDG_CURRENT_DESKTOP:-}" == *KDE* && -n "${DBUS_SESSION_BUS_ADDRESS:-}" ]] && in_session=1
case "$(yq eval '.windows.placement' "$settings")" in
  centered) kset kwinrc Placement Centered Windows ;;
  smart) kset kwinrc Placement Smart Windows ;;
esac
rule=patina21-new-windows
percent="$(yq eval '.windows.size // 0' "$settings")"
rules="$(kreadconfig6 --file kwinrulesrc --group General --key rules)"
if [[ "$percent" -gt 0 ]]; then
  screen=""
  if [[ $in_session -eq 1 ]] && command -v kscreen-doctor > /dev/null; then
    screen="$(kscreen-doctor --outputs 2> /dev/null | sed 's/\x1b\[[0-9;]*m//g' |
      awk '/^Output:/ { enabled = 0; first = 0 }
           /^[[:space:]]*enabled/ { enabled = 1 }
           /priority 1$/ { first = 1 }
           /Geometry:/ { if (enabled && first) { print $3; exit }
                         if (enabled && !fallback) fallback = $3 }
           END { if (!first && fallback) print fallback }')"
  fi
  if [[ "$screen" =~ ^([0-9]+)x([0-9]+)$ ]]; then
    kset kwinrulesrc Description "patina21: a new window opens at $percent% of the screen" "$rule"
    kset kwinrulesrc types 1 "$rule"
    kset kwinrulesrc size "$(( BASH_REMATCH[1] * percent / 100 )),$(( BASH_REMATCH[2] * percent / 100 ))" "$rule"
    kset kwinrulesrc sizerule 3 "$rule"
    if [[ ",$rules," != *",$rule,"* ]]; then
      kset kwinrulesrc rules "${rules:+$rules,}$rule" General
    fi
  elif [[ $in_session -eq 1 ]]; then
    warn "kscreen-doctor gave no screen size; the window size rule is not written"
  else
    say "no Plasma session here; the window size rule comes with the next 'patina theme set' inside one"
  fi
elif [[ -n "$(kreadconfig6 --file kwinrulesrc --group "$rule" --key sizerule)" ]]; then
  for key in Description types size sizerule; do
    kdel kwinrulesrc "$key" "$rule"
  done
  rules="${rules//$rule/}"
  rules="${rules//,,/,}"
  rules="${rules#,}"
  rules="${rules%,}"
  kset kwinrulesrc rules "$rules" General
fi

# Global shortcuts: each action of defaults/keybindings.yaml through actions.yaml.
while IFS= read -r action; do
  chord="$(yq eval ".actions[\"$action\"]" "$keybindings")"
  component="$(yq eval ".actions[\"$action\"].component // \"\"" "$actions")"
  label="$(yq eval ".actions[\"$action\"].label // \"$action\"" "$actions")"
  if yq eval -e ".actions[\"$action\"].service" "$actions" > /dev/null 2>&1; then
    if [[ "$(yq eval ".actions[\"$action\"].service" "$actions")" == patina21-agent.desktop && ! -f "$agent_desktop" ]]; then
      kdel kglobalshortcutsrc _launch services patina21-agent.desktop   # the agents bundle is not installed
      continue
    fi
    service="$(service_for_action "$action")"
    [[ -n "$service" ]] || continue
    kset kglobalshortcutsrc _launch "$chord,none,$label" services "$service"
  elif [[ -n "$component" ]]; then
    key="$(yq eval ".actions[\"$action\"].key" "$actions")"
    default="$(yq eval ".actions[\"$action\"].default // \"none\"" "$actions")"
    kset kglobalshortcutsrc "$key" "$chord,$default,$label" "$component"
  else
    warn "$action: no Plasma binding in $actions; skipping"
  fi
done < <(yq eval '.actions | keys | .[]' "$keybindings")
while IFS=$'\t' read -r component key default label; do
  kset kglobalshortcutsrc "$key" "none,$default,$label" "$component"
done < <(yq eval '.unbind[] | [.component, .key, .default, .label] | @tsv' "$actions")

# GTK apps: Plasma's own bridge (kde-config-gtk-style) syncs the colours; the theme,
# icons, cursor and font names are set here so they are right before it runs.
prefer_dark=0
[[ "${tpl[VARIANT]}" == dark ]] && prefer_dark=1
for v in gtk-3.0 gtk-4.0; do
  kset "$config/$v/settings.ini" gtk-theme-name Breeze Settings
  kset "$config/$v/settings.ini" gtk-application-prefer-dark-theme "$prefer_dark" Settings
  kset "$config/$v/settings.ini" gtk-icon-theme-name "${tpl[ICONS]}" Settings
  kset "$config/$v/settings.ini" gtk-cursor-theme-name "${tpl[CURSORS]}" Settings
  kset "$config/$v/settings.ini" gtk-font-name "${tpl[UI_FONT]} 10" Settings
done
# Qt apps from Flathub read the colour scheme when they may see kdeglobals.
if command -v flatpak > /dev/null &&
    ! flatpak override --user --show 2> /dev/null | grep -q 'xdg-config/kdeglobals:ro'; then
  say "flatpak: letting apps read kdeglobals"
  flatpak override --user --filesystem=xdg-config/kdeglobals:ro
  changed
fi

# ---- a running Plasma session picks the theme up now ---------------------------------
if [[ $in_session -eq 1 ]]; then
  if command -v plasma-apply-lookandfeel > /dev/null; then
    if [[ "${PATINA_LAYOUT:-}" == 1 ]]; then
      # Replaces this user's panels with the layout script above.
      say "resetting the panels to the theme's layout"
      plasma-apply-lookandfeel --apply "org.patina21.$theme" --resetLayout > /dev/null ||
        warn "plasma-apply-lookandfeel --resetLayout failed"
    else
      plasma-apply-lookandfeel --apply "org.patina21.$theme" > /dev/null || warn "plasma-apply-lookandfeel failed"
    fi
  fi
  if [[ $changes -gt 0 ]] && command -v dbus-send > /dev/null; then
    dbus-send --session --dest=org.kde.KWin /KWin org.kde.KWin.reconfigure 2> /dev/null ||
      warn "KWin did not reload its settings; they apply at the next login"
  fi
  command -v plasma-apply-colorscheme > /dev/null &&
    { plasma-apply-colorscheme "patina21-$theme" > /dev/null || warn "plasma-apply-colorscheme failed"; }
  command -v plasma-apply-cursortheme > /dev/null &&
    { plasma-apply-cursortheme "${tpl[CURSORS]}" > /dev/null || warn "plasma-apply-cursortheme failed"; }
  if [[ -n "$wallpaper_dir" ]] && command -v plasma-apply-wallpaperimage > /dev/null; then
    plasma-apply-wallpaperimage "$wallpaper_dir/contents/images/3840x2160.png" > /dev/null ||
      warn "plasma-apply-wallpaperimage failed"
  fi
  [[ $changes -eq 0 ]] || say "shortcuts apply at the next login"
elif [[ "${PATINA_LAYOUT:-}" == 1 ]]; then
  warn "--layout needs a running Plasma session; the layout script is in place for the next fresh login"
elif [[ $changes -gt 0 ]]; then
  say "no Plasma session here; everything applies at the next login"
fi

finish
