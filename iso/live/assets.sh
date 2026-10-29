#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Render what the live image shows, from the data: the console mark, the installer's
# marks, artwork, icons and stylesheet, the boot menu's theme and splash, the openbox
# theme and the standard fonts, every colour from the default theme's palette
# (desktops/ renders the same palette for the desktop). `assets.sh <build-dir>` where
# <build-dir>/config is a copy of iso/live/config; build.sh calls it before lb, the smoke
# test runs it on its own. Needs yq, rsvg-convert, git and the fonts of
# defaults/settings.yaml; no root.
set -euo pipefail

here="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
repo="$(cd "$here/../.." && pwd)"
out="${1:?usage: assets.sh <build-dir>}"
config="$out/config"
[[ -d "$config/includes.chroot" ]] || { echo "assets.sh: $config is not a copy of iso/live/config" >&2; exit 64; }
for tool in yq rsvg-convert git; do
  command -v "$tool" > /dev/null || { echo "assets.sh: $tool missing" >&2; exit 69; }
done

PATINA_PATH="$repo"
# shellcheck source=bin/lib.sh
source "$repo/bin/lib.sh"
say() { printf 'assets: %s\n' "$*"; }

settings="$repo/defaults/settings.yaml"
theme_dir="$repo/themes/$(yq eval '.theme' "$settings")"
theme_vars "$theme_dir/theme.yaml" "$settings"
tpl[VERSION]="$(git -C "$repo" describe --tags --always --dirty 2> /dev/null || echo 0.0.0-unknown)"
# The installer's glass and grain are the start menu's (start_menu in settings.yaml):
# percent opacity as Qt's 0-255 alpha, percent grain as an SVG opacity.
tpl[GLASS]="$(( $(yq eval '.start_menu.glass' "$settings") * 255 / 100 ))"
tpl[GRAIN]="$(yq eval '.start_menu.grain / 100' "$settings")"
chroot="$config/includes.chroot"
branding="$chroot/etc/calamares/branding/patina"
grub="$config/bootloaders/grub-pc"
templates="$here/templates"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# The console mark, plain: agetty reads backslashes in /etc/issue as escapes, so they
# are doubled.
install -d -m 0755 "$chroot/etc/issue.d" "$chroot/etc/fonts" "$branding" "$grub/live-theme"
sed 's/\\/\\\\/g' "$repo/branding/logo.txt" > "$chroot/etc/issue.d/10-patina.issue"

# The standard fonts: Qt's application font, which Calamares' sidebar uses, is
# fontconfig's sans-serif.
render "$templates/fontconfig/local.conf" "$chroot/etc/fonts/local.conf"

# The pieces the compositions are made of, rendered next to them so an SVG may reference
# them: the theme's first two wallpapers at 1920x1080 and the wordmark rasterised.
mapfile -t wallpapers < <(yq eval '.wallpapers[]?' "$theme_dir/theme.yaml")
[[ ${#wallpapers[@]} -gt 0 ]] || { echo "assets.sh: the theme has no wallpaper" >&2; exit 65; }
raster() {   # raster <svg-png-or-jpg> <out.png>: a theme wallpaper at 1920x1080
  case "$1" in
    *.svg) rsvg-convert --width 1920 --height 1080 --output "$2" "$1" ;;
    *.jpg)   # a photograph, through an SVG that holds it
      printf '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="1920" height="1080"><image width="1920" height="1080" preserveAspectRatio="xMidYMid slice" xlink:href="data:image/jpeg;base64,%s"/></svg>\n' \
        "$(base64 -w0 "$1")" > "$tmp/photo.svg"
      rsvg-convert --width 1920 --height 1080 --output "$2" "$tmp/photo.svg"
      ;;
    *) cp "$1" "$2" ;;
  esac
}
say "rendering the wallpapers of ${tpl[THEME]}"
raster "$theme_dir/${wallpapers[0]}" "$tmp/wallpaper.png"
raster "$theme_dir/${wallpapers[1]:-${wallpapers[0]}}" "$tmp/second.png"
rsvg-convert --width 1120 --output "$tmp/logo.png" "$repo/branding/wordmark.svg"

compose() {   # compose <template> <out.png> [width height]: fill the template, render it
  render "$templates/$1" "$tmp/$(basename "$1")"
  rsvg-convert --width "${3:-1920}" --height "${4:-1080}" --output "$2" "$tmp/$(basename "$1")"
}
# Calamares shows the slides at their own size, centred and cut to the room it has (about
# 1070x635 on a 1280x800 screen), so they are rendered small enough to be seen whole.
slide_size=(1024 576)

# Calamares: the marks, the wallpaper behind every page, the slides, the stylesheet, and
# the sidebar colours and the version in branding.desc.
say "rendering the installer's branding"
# The marks as pictures: Calamares draws SVG with Qt, which knows neither Sora nor the
# spacing of the mark's rings, so it gets rsvg renderings. The welcome page shows the
# name in block letters (branding/export), the slides the typeset wordmark.
cp "$tmp/logo.png" "$branding/logo.png"
rsvg-convert --width 1120 --output "$branding/welcome.png" "$repo/branding/export/wordmark-blocks.svg"
# The sidebar's mark: icon-small.svg inset in its box (logo-square.svg), at twice the
# size Calamares shows it; the window icon is the mark itself.
cp "$repo/branding/icon-small.svg" "$branding/icon-small.svg"
cp "$repo/branding/icon-small.svg" "$tmp/icon-small.svg"
render "$templates/calamares/logo-square.svg" "$tmp/logo-square.svg"
rsvg-convert --width 160 --height 160 --output "$branding/logo-square.png" "$tmp/logo-square.svg"
# The icons Calamares shows in the accent instead of its own grey ones: the language
# (welcome.conf), the welcome page's links and About (stylesheet.qss).
for icon in "$templates"/calamares/icons/*.svg; do
  render "$icon" "$tmp/icon.svg"
  rsvg-convert --width 64 --height 64 --output "$branding/$(basename "$icon" .svg).png" "$tmp/icon.svg"
done
compose calamares/wallpaper.svg "$branding/wallpaper.png"
compose calamares/slide-1.svg "$branding/slide-1.png" "${slide_size[@]}"
compose calamares/slide-2.svg "$branding/slide-2.png" "${slide_size[@]}"
compose calamares/slide-3.svg "$branding/slide-3.png" "${slide_size[@]}"
# The last slide thanks the people and projects of docs/credits.yaml: each group's
# title, then its names on lines of at most 100 characters.
credits="$repo/docs/credits.yaml" y=300 tpl[CREDITS]=""
for ((i = 0; i < $(yq eval '.groups | length' "$credits"); i++)); do
  tpl[CREDITS]+="<text class=\"group\" x=\"280\" y=\"$y\">$(yq eval ".groups[$i].title | upcase" "$credits")</text>"
  y=$((y + 34)) line=""
  while IFS= read -r name; do
    if [[ -n "$line" && $((${#line} + ${#name} + 3)) -gt 100 ]]; then
      tpl[CREDITS]+="<text class=\"names\" x=\"280\" y=\"$y\">$line</text>"
      y=$((y + 36)) line=""
    fi
    name="${name//&/&amp;}"
    line+="${line:+ · }${name//</&lt;}"
  done < <(yq eval ".groups[$i].entries[].name" "$credits")
  tpl[CREDITS]+="<text class=\"names\" x=\"280\" y=\"$y\">$line</text>"
  y=$((y + 44))
done
compose calamares/slide-4.svg "$branding/slide-4.png" "${slide_size[@]}"
render "$templates/calamares/stylesheet.qss" "$branding/stylesheet.qss"

# The AI page: its default answer is ai.mode of defaults/settings.yaml, and each answer
# gets a picture with its name and what it sets up.
say "rendering the AI page"
chooser="$chroot/etc/calamares/modules/packagechooser-ai.conf"
yq -i ".default = \"$(yq eval '.ai.mode' "$settings")\"" "$chooser"
for id in $(yq eval '.items[].id' "$chooser"); do
  tpl[AI_NAME]="$(yq eval ".items[] | select(.id == \"$id\") | .name" "$chooser")"
  tpl[AI_DEMO]=1
  case "$id" in
    local) tpl[AI_DETAIL]="opencode · Ollama · $(yq eval '.ai.local.models[0].model' "$settings")" ;;
    cloud) tpl[AI_DETAIL]="opencode · $(yq eval '.ai.cloud.providers[0].name + " and " + (.ai.cloud.providers | length - 1 | tostring) + " more"' "$settings")" ;;
    *) tpl[AI_DETAIL]="patina ai on turns it on later" tpl[AI_DEMO]=0.15 ;;
  esac
  render "$templates/calamares/ai.svg" "$tmp/ai-$id.svg"
  rsvg-convert --width 960 --height 540 --output "$branding/ai-$id.png" "$tmp/ai-$id.svg"
done
yq -i "
  .strings.version = \"${tpl[VERSION]}\" |
  .strings.shortVersion = \"${tpl[VERSION]}\" |
  .style.SidebarBackground = \"#00000000\" |
  .style.SidebarText = \"${tpl[BASE05]}\" |
  .style.SidebarTextCurrent = \"${tpl[ACCENT]}\" |
  .style.SidebarBackgroundCurrent = \"#24${tpl[ACCENT]#\#}\"
" "$branding/branding.desc"

# The boot menu: live-build takes these two files over its stock ones, and its theme.cfg
# turns the theme on as soon as splash.png exists.
say "rendering the boot menu's theme"
render "$templates/grub/theme.txt" "$grub/live-theme/theme.txt"
compose grub/splash.svg "$grub/splash.png"

# Openbox, for the dialogs the installer opens.
openbox="$chroot/usr/share/themes/patina/openbox-3"
install -d -m 0755 "$openbox"
render "$templates/openbox/themerc" "$openbox/themerc"

# Every placeholder must be gone.
left="$(grep -lF "\${" "$branding/stylesheet.qss" "$grub/live-theme/theme.txt" "$openbox/themerc" \
  "$chroot/etc/fonts/local.conf" || true)"
[[ -z "$left" ]] || { echo "assets.sh: unfilled placeholders in: $left" >&2; exit 70; }
say "done: ${tpl[THEME]} ${tpl[VERSION]}"
