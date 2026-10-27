#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Render a theme and defaults/ into KDE Plasma's configuration for this user: colour
# schemes, the Konsole profile, wallpapers, a look-and-feel package, shortcuts and the
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
agent_desktop="$data/applications/patina-agent.desktop"
changes=0

# shellcheck source=bin/lib.sh
source "$PATINA_PATH/bin/lib.sh"
say() { printf 'patina: theme: %s\n' "$*"; }
warn() { printf 'patina: theme: %s\n' "$*" >&2; }
changed() { changes=$((changes + 1)); }

# ---- the theme as template variables ------------------------------------------------
# tpl[NAME] fills ${NAME} in a template (theme_vars and render in bin/lib.sh): colours as
# hex (BASE00) and as the r,g,b decimals KDE's files want (BASE00_RGB), in the palette
# of the mode (`patina theme mode`).
mode="$(current_mode)"
theme_vars "$theme_yaml" "$settings" "$mode"
tpl[CONFIG_HOME]="$config"
tpl[WALLPAPER]=""
tpl[WALLPAPER_PACKAGE]=""
tpl[AGENT_COMMAND]=""
tpl[PANEL_FLOATING]="$(yq eval '.panel.floating // false' "$settings")"
tpl[PINNED_LAUNCHERS]=""
theme="${tpl[THEME]}"
[[ "$theme" == "$(basename "$theme_dir")" ]] ||
  warn "theme.yaml says name: $theme but the directory is $(basename "$theme_dir")"

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

# Set a square icon's drawing at one height, in place: even_glyph <svg>. Its viewBox
# becomes a square around what it draws, the drawing 7/8 of the square high, as wide
# as its shape (at most the whole square), centred. So a circle, a cabinet and a row of
# dots stand equally tall in the bar. The extent is the bounding box cairo writes into
# an EPS (rsvg-convert, at 1600 px: 1200 pt for the whole icon, y counted upwards).
even_glyph() {
  local file="$1" box
  box="$(rsvg-convert --format eps --width 1600 --height 1600 "$file" |
    awk '/^%%BoundingBox:/ { print $2, $3, $4, $5; exit }')"
  [[ -n "$box" ]] || return 0
  LC_ALL=C awk -v box="$box" 'BEGIN { RS = "\001"; split(box, b, " ") }
    {
      s = index($0, "<svg"); e = s + index(substr($0, s), ">") - 1
      tag = substr($0, s, e - s + 1)
      if (match(tag, /viewBox="[^"]*"/)) {
        split(substr(tag, RSTART + 9, RLENGTH - 10), v, /[ ,]+/)
      } else {
        v[1] = v[2] = 0
        match(tag, /width="[0-9.]+/); v[3] = substr(tag, RSTART + 7, RLENGTH - 7)
        match(tag, /height="[0-9.]+/); v[4] = substr(tag, RSTART + 8, RLENGTH - 8)
      }
      x1 = v[1] + v[3] * b[1] / 1200; x2 = v[1] + v[3] * b[3] / 1200
      y1 = v[2] + v[4] * (1200 - b[4]) / 1200; y2 = v[2] + v[4] * (1200 - b[2]) / 1200
      side = (y2 - y1) * 8 / 7
      if (x2 - x1 > side) side = x2 - x1
      gsub(/ viewBox="[^"]*"/, "", tag)
      sub(/^<svg/, sprintf("<svg viewBox=\"%.3f %.3f %.3f %.3f\"", (x1 + x2 - side) / 2,
        (y1 + y2 - side) / 2, side, side), tag)
      printf "%s%s%s", substr($0, 1, s - 1), tag, substr($0, e + 1)
    }' "$file" > "$file.even"
  mv "$file.even" "$file"
}

# The .desktop file an action of defaults/keybindings.yaml launches, through
# actions.yaml; empty (with a warning) when the action has none or it is not installed.
app_dirs=("$data/applications" /usr/share/applications /usr/local/share/applications
  "$data/flatpak/exports/share/applications" /var/lib/flatpak/exports/share/applications)
service_installed() {
  local d
  for d in "${app_dirs[@]}"; do
    [[ -f "$d/$1" ]] && return 0
  done
  return 1
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
  if [[ "$service" == patina-agent.desktop && ! -f "$agent_desktop" ]]; then
    return   # no AI or agents bundle is installed
  fi
  if ! service_installed "$service"; then
    warn "$action: $service is not installed; skipping"
    return
  fi
  echo "$service"
}

# ---- files: colour schemes, Konsole, wallpapers, the look-and-feel package ----------
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

render "$templates/color-scheme.colors" "$tmp/colors"
put "$tmp/colors" "$data/color-schemes/patina-$theme.colors"
drop_other_themes "$data/color-schemes/patina-*.colors" "$data/color-schemes/patina-$theme."

render "$templates/konsole.colorscheme" "$tmp/konsole.colorscheme"
put "$tmp/konsole.colorscheme" "$data/konsole/patina-$theme.colorscheme"
render "$templates/konsole.profile" "$tmp/konsole.profile"
put "$tmp/konsole.profile" "$data/konsole/patina-$theme.profile"
drop_other_themes "$data/konsole/patina-*" "$data/konsole/patina-$theme."

# Wallpapers: one Plasma wallpaper package per image. An SVG is rendered once, at 4K,
# and again only when the theme's file is newer than the rendering (a git pull sets
# the time); a PNG is copied as it is. In a theme's other mode its own wallpapers come
# first, so the first is the desktop's, and the theme's own follow; the theme's own
# first one stays the login screen's, which is made for a dark ground.
wallpaper_dir=""
login_dir=""
login_rel="$(yq eval '.wallpapers[0] // ""' "$theme_yaml")"
wallpaper_pkgs=" "
while IFS= read -r rel; do
  src="$theme_dir/$rel"
  name="$(basename "${rel%.*}")"
  pkg="$data/wallpapers/patina-$theme-$name"
  png="$pkg/contents/images/3840x2160.png"
  wallpaper_pkgs="$wallpaper_pkgs$pkg "
  if [[ ! -f "$src" ]]; then
    warn "wallpaper $rel is not in the theme; skipping it"
    continue
  fi
  case "$src" in
    *.svg | *.jpg)
      if [[ ! -e "$png" || "$src" -nt "$png" ]]; then
        if command -v rsvg-convert > /dev/null; then
          say "rendering $rel"
          mkdir -p "$(dirname "$png")"
          input="$src"
          if [[ "$src" == *.jpg ]]; then
            # A photograph becomes a PNG too, through an SVG that holds it (rsvg reads
            # no file outside the SVG's own directory, so it is embedded).
            printf '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="3840" height="2160"><image width="3840" height="2160" preserveAspectRatio="xMidYMid slice" xlink:href="data:image/jpeg;base64,%s"/></svg>\n' \
              "$(base64 -w0 "$src")" > "$tmp/photo.svg"
            input="$tmp/photo.svg"
          fi
          rsvg-convert --width 3840 --height 2160 --output "$tmp/wallpaper.png" "$input"
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
  [[ "$rel" != "$login_rel" ]] || login_dir="$pkg"
done < <(yq eval "(.${tpl[VARIANT]}.wallpapers // [])[], .wallpapers[]" "$theme_yaml" | awk '!seen[$0]++')
for pkg in "$data"/wallpapers/patina-*; do
  [[ -d "$pkg" ]] || continue
  if [[ "$wallpaper_pkgs" != *" $pkg "* ]]; then
    say "removing $pkg (not in this theme or mode)"
    rm -rf "$pkg"
    changed
  fi
done

# The login screen: SDDM runs as its own user, so the wallpaper has to live outside
# home. The rendering of the theme's own first wallpaper and the Breeze theme's override
# file are written through the backend's one sudo path (CLAUDE.md names this case),
# each only when it differs; without sudo the login screen keeps what it has and the
# run goes on.
login_png=/usr/local/share/patina/login.png
sddm_breeze=/usr/share/sddm/themes/breeze
if [[ -n "$login_dir" && -f "$login_dir/contents/images/3840x2160.png" ]]; then
  render "$templates/sddm-theme.conf.user" "$tmp/theme.conf.user"
  login_todo=()
  cmp -s "$login_dir/contents/images/3840x2160.png" "$login_png" ||
    login_todo+=("$login_dir/contents/images/3840x2160.png:$login_png")
  if [[ -d "$sddm_breeze" ]] && ! cmp -s "$tmp/theme.conf.user" "$sddm_breeze/theme.conf.user"; then
    login_todo+=("$tmp/theme.conf.user:$sddm_breeze/theme.conf.user")
  fi
  if [[ ${#login_todo[@]} -gt 0 ]]; then
    if BACKEND="$(backend_file 2> /dev/null)" && system_writable; then
      for pair in "${login_todo[@]}"; do
        say "login screen: writing ${pair#*:}"
        backend_run system.write "${pair%%:*}" "${pair#*:}"
        changed
      done
    else
      warn "login screen: no sudo here; $login_png keeps the wallpaper it has"
    fi
  fi
fi

# The agent launcher, only with an AI bundle (ai-local, ai-cloud) or the agents bundle
# installed. It and the cheat sheet's
# launcher come before the icons, which give every app's desktop entry its glyph. It opens the agent CLI in
# the kitty profile desktops/terminal/ writes.
if [[ " ${PATINA_BUNDLES:-} " =~ \ (agents|ai-local|ai-cloud)\  ]]; then
  tpl[AGENT_COMMAND]="$(command -v "${tpl[AGENT]}" 2> /dev/null || echo "${tpl[AGENT]}")"
  render "$templates/agent.desktop" "$tmp/agent.desktop"
  put "$tmp/agent.desktop" "$agent_desktop"
elif [[ -e "$agent_desktop" ]]; then
  say "removing $agent_desktop (no AI or agents bundle is installed)"
  rm -f "$agent_desktop"
  changed
fi

# The ArtCraft Launcher's menu entry, only with the artcraft bundle: its AppImage in
# ~/.local/bin brings none of its own.
launcher_desktop="$data/applications/patina-artcraft-launcher.desktop"
if [[ " ${PATINA_BUNDLES:-} " == *" artcraft "* ]]; then
  tpl[LAUNCHER_COMMAND]="$(command -v artcraft-launcher 2> /dev/null || echo "$HOME/.local/bin/artcraft-launcher")"
  render "$templates/artcraft-launcher.desktop" "$tmp/artcraft-launcher.desktop"
  put "$tmp/artcraft-launcher.desktop" "$launcher_desktop"
elif [[ -e "$launcher_desktop" ]]; then
  say "removing $launcher_desktop (the artcraft bundle is not installed)"
  rm -f "$launcher_desktop"
  changed
fi

# The cheat sheet's launcher, which the keys action (Meta+K) starts: kitty showing
# `patina keys` until a key is pressed.
tpl[PATINA_PATH]="$PATINA_PATH"
render "$templates/keys.desktop" "$tmp/keys.desktop"
put "$tmp/keys.desktop" "$data/applications/patina-keys.desktop"

# Icons: an icon theme of desktops/plasma/icons.yaml gets its folders in the accent and
# every app in one colour. The renderer writes a small icon theme, patina-<theme>, that
# inherits it and holds only those icons; the session then uses that one. The icon
# theme's monochrome icons follow the colour scheme already (FollowsColorScheme).
icons_base="${tpl[ICONS]}"
icons_dir="$data/icons/patina-$theme"
variant="$(yq eval ".[\"$icons_base\"].variant // \"\"" "$here/icons.yaml")"
if [[ -n "$variant" && -f "/usr/share/icons/$icons_base/index.theme" ]]; then
  # The variant's colours swapped for shades of the accent: the accent, 80 % and 35 %.
  sed_args=()
  hex="${tpl[ACCENT]}"
  while IFS=$'\t' read -r from role; do
    case "$role" in
      accent) p=100 ;;
      shade) p=80 ;;
      deep) p=35 ;;
      *) warn "icons.yaml: unknown role '$role'"; continue ;;
    esac
    sed_args+=(-e "s/$from/$(printf '#%02x%02x%02x' $((0x${hex:1:2} * p / 100)) \
      $((0x${hex:3:2} * p / 100)) $((0x${hex:5:2} * p / 100)))/gI")
  done < <(yq eval ".[\"$icons_base\"].colors | to_entries | .[] | [.key, .value] | @tsv" "$here/icons.yaml")
  out="$tmp/icons"
  # Every folder icon of the icon theme that ends at the variant, under its own name:
  # folder.svg -> folder-blue.svg, and inode-directory.svg -> folder.svg -> folder-blue.svg.
  for places in /usr/share/icons/"$icons_base"/*/places; do
    declare -A target=()
    while IFS=$'\t' read -r name to; do
      target["$name"]="${to##*/}"
    done < <(find -H "$places" -maxdepth 1 -type l -printf '%f\t%l\n')
    links=()
    for name in "${!target[@]}"; do
      to="${target[$name]}"
      to="${target[$to]:-$to}"
      case "$to" in
        folder-"$variant"*.svg | user-"$variant"*.svg) links+=("$places/$name") ;;
      esac
    done
    unset target
    [[ ${#links[@]} -gt 0 ]] || continue
    size="$(basename "$(dirname "$places")")"
    mkdir -p "$out/$size/places"
    cp -L "${links[@]}" "$out/$size/places/"
    sed -i "${sed_args[@]}" "$out/$size/places"/*.svg
  done
  # Every app in one colour (mono in icons.yaml): the icon each installed desktop entry
  # names becomes a glyph of the icon theme, which takes the colour scheme's text
  # colour. A name the icon theme also uses outside its apps (a folder, a file type) is
  # left alone; an app installed later gets its glyph at the next `patina theme set`.
  other="$(yq eval ".[\"$icons_base\"].mono.other // \"\"" "$here/icons.yaml")"
  if [[ -n "$other" ]]; then
    declare -A glyph=() taken=()
    while IFS=$'\t' read -r icon g; do
      glyph["$icon"]="$g"
    done < <(yq eval ".[\"$icons_base\"].mono.apps | to_entries | .[] | [.key, .value] | @tsv" "$here/icons.yaml")
    while IFS= read -r name; do
      taken["${name%.svg}"]=1
    done < <(find -L /usr/share/icons/"$icons_base"/{16x16,22x22,24x24,32x32,48x48,64x64}/{places,mimetypes,devices,actions,status,emblems} \
      -maxdepth 1 -name '*.svg' -printf '%f\n' 2> /dev/null)
    mkdir -p "$out/32x32/symbolic/apps"
    while IFS= read -r icon; do
      [[ "$icon" =~ ^[A-Za-z0-9._+-]+$ && "$icon" != *.png && "$icon" != *.svg* && "$icon" != *-symbolic &&
        -z "${taken[$icon]:-}" ]] || continue
      g="${glyph[$icon]:-$other}"
      src="$(find -L /usr/share/icons/"$icons_base"/32x32/symbolic -name "$g.svg" -print -quit)"
      if [[ -z "$src" ]]; then
        warn "icons.yaml: $icons_base has no glyph $g"
        continue
      fi
      cp -L "$src" "$out/32x32/symbolic/apps/$icon.svg"
      even_glyph "$out/32x32/symbolic/apps/$icon.svg"
    done < <(for d in "${app_dirs[@]}"; do
        # the icons of the apps a menu shows: Type=Application, neither NoDisplay nor Hidden
        [[ -d "$d" ]] && awk -F= '
          function flush() {
            if (icon != "" && type == "Application" && hide != "true") print icon
            icon = type = hide = ""
          }
          FNR == 1 { flush() }
          /^\[/ { s = $0 }
          s == "[Desktop Entry]" && $1 == "Icon" && icon == "" { icon = $2 }
          s == "[Desktop Entry]" && $1 == "Type" { type = $2 }
          s == "[Desktop Entry]" && ($1 == "NoDisplay" || $1 == "Hidden") && $2 == "true" { hide = "true" }
          END { flush() }' "$d"/*.desktop
      done 2> /dev/null | sort -u)
  fi
  # Its index: the icon theme's own directories, its name, and the icon theme first in
  # line for everything that is not a folder.
  sed -e "s/^Name=.*/Name=patina ${tpl[DISPLAY_NAME]}/" \
    -e "s/^Comment=.*/Comment=$icons_base with folders in the accent of ${tpl[DISPLAY_NAME]}/" \
    -e "s/^Inherits=/Inherits=$icons_base,/" "/usr/share/icons/$icons_base/index.theme" > "$out/index.theme"
  if ! diff -rq "$out" "$icons_dir" > /dev/null 2>&1; then
    say "writing $icons_dir ($icons_base, folders in the accent)"
    rm -rf "$icons_dir"
    mkdir -p "$(dirname "$icons_dir")"
    mv "$out" "$icons_dir"
    changed
  fi
  tpl[ICONS]="patina-$theme"
elif [[ -n "$variant" ]]; then
  warn "icon theme $icons_base is not installed (papirus-icon-theme in the desktop bundle); using breeze-dark"
  tpl[ICONS]="breeze-dark"
  [[ "${tpl[VARIANT]}" == light ]] && tpl[ICONS]="breeze"
fi
drop_other_themes "$data/icons/patina-*" "$icons_dir"

# Grain on the start menu (start_menu.grain): Plasma draws every panel popup from one
# background, so it goes on all of them. A Plasma desktop theme of the theme's own,
# patina-<theme>, holds Breeze's popup backgrounds with a fine noise tile laid into
# their centre tile, which Plasma repeats; every other element comes from Breeze, the
# default theme. Only over the default desktop theme.
grain="$(yq eval '.start_menu.grain // 0' "$settings")"
breeze=/usr/share/plasma/desktoptheme/default
desktoptheme="$data/plasma/desktoptheme/patina-$theme"
if [[ "${tpl[DESKTOP_THEME]}" == default && "$grain" -gt 0 && -d "$breeze" ]] && command -v rsvg-convert > /dev/null; then
  out="$tmp/desktoptheme"
  render "$templates/grain.svg" "$tmp/grain.svg"
  rsvg-convert --width 32 --height 32 --output "$tmp/grain.png" "$tmp/grain.svg"
  printf -v opacity '%d.%02d' $((grain / 100)) $((grain % 100))
  for variant in dialogs translucent/dialogs opaque/dialogs solid/dialogs; do
    [[ -f "$breeze/$variant/background.svgz" ]] || continue
    mkdir -p "$out/$variant"
    # After the centre's background rect (rect4138 in every variant), an image of the
    # noise at the same place and size; the root gets the xlink namespace it needs.
    zcat "$breeze/$variant/background.svgz" | awk -v img="$(base64 -w0 "$tmp/grain.png")" -v op="$opacity" '
      function attr(tag, name,   m) {
        if (match(tag, "[ \t\n]" name "=\"[^\"]*\"")) {
          m = substr(tag, RSTART + 1, RLENGTH - 1)
          sub("^" name "=\"", "", m); sub("\"$", "", m); return m
        }
        return "0"
      }
      BEGIN { RS = "\001" }
      {
        doc = $0
        if (doc !~ /xmlns:xlink=/) sub(/<svg/, "<svg xmlns:xlink=\"http://www.w3.org/1999/xlink\"", doc)
        if (match(doc, /<rect[^>]*id="rect4138"[^>]*\/>/)) {
          at = RSTART + RLENGTH   # attr() matches again, so the place is kept first
          tag = substr(doc, RSTART, RLENGTH)
          image = "<image x=\"" attr(tag, "x") "\" y=\"" attr(tag, "y") "\" width=\"" attr(tag, "width") \
            "\" height=\"" attr(tag, "height") "\" opacity=\"" op "\" preserveAspectRatio=\"none\"" \
            " xlink:href=\"data:image/png;base64," img "\"/>"
          doc = substr(doc, 1, at - 1) image substr(doc, at)
        }
        printf "%s", doc
      }' | gzip -n > "$out/$variant/background.svgz"
  done
  cp "$breeze/plasmarc" "$out/plasmarc"
  render "$templates/desktoptheme-metadata.json" "$out/metadata.json"
  if ! diff -rq "$out" "$desktoptheme" > /dev/null 2>&1; then
    say "writing $desktoptheme (Breeze with grain on the popups)"
    rm -rf "$desktoptheme"
    mkdir -p "$(dirname "$desktoptheme")"
    mv "$out" "$desktoptheme"
    changed
  fi
  tpl[DESKTOP_THEME]="patina-$theme"
fi
drop_other_themes "$data/plasma/desktoptheme/patina-*" "$desktoptheme"

# The look-and-feel package: Plasma's own way to hand a new session its colours,
# icons, cursors and wallpaper at once, so a fresh user gets the theme at first login.
tpl[WALLPAPER_PACKAGE]="${wallpaper_dir:+$wallpaper_dir/}"
lnf="$data/plasma/look-and-feel/org.patina.$theme"
render "$templates/look-and-feel-metadata.json" "$tmp/lnf.json"
put "$tmp/lnf.json" "$lnf/metadata.json"
render "$templates/look-and-feel-defaults" "$tmp/lnf.defaults"
put "$tmp/lnf.defaults" "$lnf/contents/defaults"
# The splash: the wordmark on the theme's background, one accent line (templates/splash.qml).
# Always in the dark palette where the theme has one, like the boot menu and the login
# screen before it: the wordmark is made for a dark ground. A subshell keeps tpl[].
put "$PATINA_PATH/branding/wordmark.svg" "$lnf/contents/splash/images/logo.svg"
( theme_vars "$theme_yaml" "$settings" dark && render "$templates/splash.qml" "$tmp/Splash.qml" )
put "$tmp/Splash.qml" "$lnf/contents/splash/Splash.qml"
drop_other_themes "$data/plasma/look-and-feel/org.patina.*" "$lnf"

# The start menu's folders (start_menu in defaults/settings.yaml): one directory entry
# each and a menu file merged into the applications menu that fills them. Its button is
# the patina mark (branding/icon-small.svg, the size for a bar), as tall as the apps'
# glyphs beside it, in a place that stays when the theme changes.
cp "$PATINA_PATH/branding/icon-small.svg" "$tmp/launcher.svg"
even_glyph "$tmp/launcher.svg"
put "$tmp/launcher.svg" "$data/patina/launcher.svg"
tpl[LAUNCHER_ICON]="$data/patina/launcher.svg"
menu_changes=$changes
folders=""
directories=" "
while IFS=$'\t' read -r id name icon; do
  tpl[FOLDER_NAME]="$name"
  tpl[FOLDER_ICON]="$icon"
  render "$templates/start-menu.directory" "$tmp/folder.directory"
  put "$tmp/folder.directory" "$data/desktop-directories/patina-$id.directory"
  directories="$directories$data/desktop-directories/patina-$id.directory "
  printf -v folders '%s  <Menu>\n    <Name>patina-%s</Name>\n    <Directory>patina-%s.directory</Directory>\n    <Include>\n' \
    "$folders" "$id" "$id"
  while IFS= read -r app; do
    printf -v folders '%s      <Filename>%s</Filename>\n' "$folders" "$app"
  done < <(yq eval ".start_menu.folders[] | select(.id == \"$id\") | .apps[]" "$settings")
  printf -v folders '%s    </Include>\n  </Menu>\n' "$folders"
done < <(yq eval '.start_menu.folders[]? | [.id, .name, .icon] | @tsv' "$settings")
for f in "$data"/desktop-directories/patina-*.directory; do
  [[ -e "$f" && "$directories" != *" $f "* ]] || continue
  say "removing $f (not in start_menu)"
  rm -f "$f"
  changed
done
tpl[MENU_FOLDERS]="${folders%$'\n'}"
render "$templates/start-menu.menu" "$tmp/start-menu.menu"
put "$tmp/start-menu.menu" "$config/menus/applications-merged/patina-start-menu.menu"
# Its favourites: the folders' apps in order, then the extra ones, each only when
# installed. Kicker prepends them, as a ;-list, to the favourites of every new start menu.
favorites=""
while IFS= read -r app; do
  service_installed "$app" || continue
  favorites="$favorites${favorites:+;}$app"
done < <(yq eval '.start_menu.folders[]?.apps[], .start_menu.favorites[]?' "$settings")
# The menu cache follows on its own in a session (kded); a rebuild now makes the
# folders appear at once and costs nothing outside one.
if [[ $changes -gt $menu_changes ]] && command -v kbuildsycoca6 > /dev/null; then
  kbuildsycoca6 > /dev/null 2>&1 || warn "kbuildsycoca6 failed; the menu's folders appear at the next login"
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
  # The Application Dashboard comes with plasma-widgets-addons (the desktop bundle);
  # without it Plasma would show a broken applet in the bar, so Kickoff stands in.
  tpl[LAUNCHER_APPLET]=org.kde.plasma.kickoff
  if [[ "$(yq eval '.start_menu.style // "popup"' "$settings")" == dashboard ]]; then
    if [[ -d /usr/share/plasma/plasmoids/org.kde.plasma.kickerdash ]]; then
      tpl[LAUNCHER_APPLET]=org.kde.plasma.kickerdash
    else
      warn "start menu: the Application Dashboard is not installed (plasma-widgets-addons); using Kickoff"
    fi
  fi
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
kset kdeglobals ColorScheme "patina-$theme" General
# The colours themselves. Plasma, KWin's title bars and every KDE app read them from
# kdeglobals, not from the scheme file. plasma-apply-colorscheme would copy them, but
# it needs a display and does nothing for a scheme whose name is already set, so a
# first install, a palette change and a mode switch never arrived. Every key of the
# rendered scheme is copied here instead, each only when it differs; [General] keeps
# the scheme's own name keys.
colour_keys=0
groups=()
header=""
# What kdeglobals holds now, read once (group line, a tab, key=value), so only the keys
# that differ cost a kreadconfig6.
declare -A have=()
if [[ -f "$config/kdeglobals" ]]; then
  while IFS= read -r line; do
    have["$line"]=1
  done < <(awk '/^\[/ { g = $0; next } /=/ { print g "\t" $0 }' "$config/kdeglobals")
fi
while IFS= read -r line; do
  if [[ "$line" == "["*"]" ]]; then
    header="$line"
    section="${line:1:${#line}-2}"   # Colors:Header][Inactive is two nested groups
    groups=()
    while [[ "$section" == *"]["* ]]; do
      groups+=(--group "${section%%"]["*}")
      section="${section#*"]["}"
    done
    groups+=(--group "$section")
  elif [[ "$line" == *=* && "${groups[1]:-}" != General && -z "${have["$header"$'\t'"$line"]:-}" ]]; then
    key="${line%%=*}"
    value="${line#*=}"
    if [[ "$(kreadconfig6 --file kdeglobals "${groups[@]}" --key "$key")" != "$value" ]]; then
      kwriteconfig6 --file kdeglobals "${groups[@]}" --key "$key" "$value"
      colour_keys=$((colour_keys + 1))
    fi
  fi
done < "$tmp/colors"
if [[ $colour_keys -gt 0 ]]; then
  say "kdeglobals: the colours of patina-$theme ($colour_keys keys)"
  changed
fi
kset kdeglobals AccentColor "${tpl[ACCENT_RGB]}" General
kset kdeglobals accentColorFromWallpaper false General
kset kdeglobals font "$font" General
kset kdeglobals menuFont "$font" General
kset kdeglobals toolBarFont "$font" General
kset kdeglobals smallestReadableFont "${tpl[UI_FONT]},8,-1,5,400,0,0,0,0,0,0,0,0,0,0,1" General
kset kdeglobals fixed "${tpl[MONO_FONT]},10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1" General
kset kdeglobals activeFont "$font" WM
kset kdeglobals LookAndFeelPackage "org.patina.$theme" KDE
kset kdeglobals widgetStyle Breeze KDE
kset kdeglobals Theme "${tpl[ICONS]}" Icons
kset kcminputrc cursorTheme "${tpl[CURSORS]}" Mouse
kset plasmarc name "${tpl[DESKTOP_THEME]}" Theme
kset konsolerc DefaultProfile "patina-$theme.profile" "Desktop Entry"
if [[ -n "$favorites" ]]; then
  kset kicker-extra-favoritesrc Prepend "$favorites" General
else
  kdel kicker-extra-favoritesrc Prepend General
fi
kset ksplashrc Theme "org.patina.$theme" KSplash
kset ksplashrc Engine KSplashQML KSplash
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
# The command palette: KRunner in the middle of the screen (free floating) or at the top.
case "$(yq eval '.command_palette.position' "$settings")" in
  center) kset krunnerrc FreeFloating true General ;;
  top) kset krunnerrc FreeFloating false General ;;
esac
# Drop the KWin rule $rule: drop_rule <key>..., its keys and its name in $rules.
drop_rule() {
  local key
  for key in "$@"; do
    kdel kwinrulesrc "$key" "$rule"
  done
  rules="${rules//$rule/}"
  rules="${rules//,,/,}"
  rules="${rules#,}"
  rules="${rules%,}"
  kset kwinrulesrc rules "$rules" General
}
rule=patina-new-windows
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
    kset kwinrulesrc Description "patina: a new window opens at $percent% of the screen" "$rule"
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
  drop_rule Description types size sizerule
fi

# Windows a little see-through: a KWin rule forcing the opacity of every normal window,
# one share while it is active and one while it is not; 100 for both drops the rule.
rule=patina-window-opacity
active="$(yq eval '.windows.opacity.active // 100' "$settings")"
inactive="$(yq eval '.windows.opacity.inactive // 100' "$settings")"
rules="$(kreadconfig6 --file kwinrulesrc --group General --key rules)"
if [[ "$active" -lt 100 || "$inactive" -lt 100 ]]; then
  kset kwinrulesrc Description "patina: windows at $active% opacity, $inactive% while inactive" "$rule"
  kset kwinrulesrc types 1 "$rule"
  kset kwinrulesrc opacityactive "$active" "$rule"
  kset kwinrulesrc opacityactiverule 2 "$rule"
  kset kwinrulesrc opacityinactive "$inactive" "$rule"
  kset kwinrulesrc opacityinactiverule 2 "$rule"
  if [[ ",$rules," != *",$rule,"* ]]; then
    kset kwinrulesrc rules "${rules:+$rules,}$rule" General
  fi
elif [[ -n "$(kreadconfig6 --file kwinrulesrc --group "$rule" --key opacityactiverule)" ]]; then
  drop_rule Description types opacityactive opacityactiverule opacityinactive opacityinactiverule
fi

# Global shortcuts: each action of defaults/keybindings.yaml through actions.yaml.
while IFS= read -r action; do
  chord="$(yq eval ".actions[\"$action\"]" "$keybindings")"
  component="$(yq eval ".actions[\"$action\"].component // \"\"" "$actions")"
  label="$(yq eval ".actions[\"$action\"].label // \"$action\"" "$actions")"
  if yq eval -e ".actions[\"$action\"].service" "$actions" > /dev/null 2>&1; then
    if [[ "$(yq eval ".actions[\"$action\"].service" "$actions")" == patina-agent.desktop && ! -f "$agent_desktop" ]]; then
      kdel kglobalshortcutsrc _launch services patina-agent.desktop   # no AI or agents bundle is installed
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
      plasma-apply-lookandfeel --apply "org.patina.$theme" --resetLayout > /dev/null ||
        warn "plasma-apply-lookandfeel --resetLayout failed"
    else
      plasma-apply-lookandfeel --apply "org.patina.$theme" > /dev/null || warn "plasma-apply-lookandfeel failed"
    fi
  fi
  if [[ $changes -gt 0 ]] && command -v dbus-send > /dev/null; then
    dbus-send --session --dest=org.kde.KWin /KWin org.kde.KWin.reconfigure 2> /dev/null ||
      warn "KWin did not reload its settings; they apply at the next login"
  fi
  # Running apps repaint when told the palette changed (KGlobalSettings, PaletteChanged).
  if [[ $colour_keys -gt 0 ]] && command -v dbus-send > /dev/null; then
    dbus-send --session --type=signal /KGlobalSettings org.kde.KGlobalSettings.notifyChange \
      int32:0 int32:0 2> /dev/null || warn "the running apps were not told about the new colours"
  fi
  command -v plasma-apply-cursortheme > /dev/null &&
    { plasma-apply-cursortheme "${tpl[CURSORS]}" > /dev/null || warn "plasma-apply-cursortheme failed"; }
  if [[ -n "$wallpaper_dir" ]] && command -v plasma-apply-wallpaperimage > /dev/null; then
    plasma-apply-wallpaperimage "$wallpaper_dir/contents/images/3840x2160.png" > /dev/null ||
      warn "plasma-apply-wallpaperimage failed"
  fi
  [[ $changes -eq 0 ]] || say "shortcuts apply at the next login"
elif [[ "${PATINA_LAYOUT:-}" == 1 ]]; then
  say "no Plasma session here; the panel layout is in place for the first login"
elif [[ $changes -gt 0 ]]; then
  say "no Plasma session here; everything applies at the next login"
fi

finish
