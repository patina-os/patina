#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Render what the live image shows, from the data: the console mark, the installer's
# marks, artwork and stylesheet, the boot menu's theme and splash and the openbox theme,
# every colour from the default theme's palette (desktops/ renders the same palette for
# the desktop). `assets.sh <build-dir>` where <build-dir>/config is a copy of
# iso/live/config; build.sh calls it before lb, the smoke test runs it on its own. Needs
# yq, rsvg-convert, git and the fonts of defaults/settings.yaml; no root.
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
chroot="$config/includes.chroot"
branding="$chroot/etc/calamares/branding/patina"
grub="$config/bootloaders/grub-pc"
templates="$here/templates"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# The console mark, plain: agetty reads backslashes in /etc/issue as escapes, so they
# are doubled.
install -d -m 0755 "$chroot/etc/issue.d" "$branding" "$grub/live-theme"
sed 's/\\/\\\\/g' "$repo/branding/logo.txt" > "$chroot/etc/issue.d/10-patina.issue"

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

compose() {   # compose <template> <out.png>: fill the template, render it over the pieces
  render "$templates/$1" "$tmp/$(basename "$1")"
  rsvg-convert --width 1920 --height 1080 --output "$2" "$tmp/$(basename "$1")"
}

# Calamares: the marks, the wallpaper behind every page, the slides, the stylesheet, and
# the sidebar colours and the version in branding.desc.
say "rendering the installer's branding"
# The marks as pictures: Calamares draws SVG with Qt, which knows neither Sora nor the
# spacing of the mark's rings, so it gets rsvg renderings. The welcome page shows the
# name in block letters (branding/export), the slides the typeset wordmark.
cp "$tmp/logo.png" "$branding/logo.png"
rsvg-convert --width 1120 --output "$branding/welcome.png" "$repo/branding/export/wordmark-blocks.svg"
cp "$repo/branding/icon-small.svg" "$branding/logo-square.svg"
compose calamares/wallpaper.svg "$branding/wallpaper.png"
compose calamares/slide-1.svg "$branding/slide-1.png"
compose calamares/slide-2.svg "$branding/slide-2.png"
compose calamares/slide-3.svg "$branding/slide-3.png"
# The last slide thanks the people and projects of docs/credits.yaml: each group's
# title, then its names on lines of at most 100 characters.
credits="$repo/docs/credits.yaml" y=320 tpl[CREDITS]=""
for ((i = 0; i < $(yq eval '.groups | length' "$credits"); i++)); do
  tpl[CREDITS]+="<text class=\"group\" x=\"280\" y=\"$y\">$(yq eval ".groups[$i].title | upcase" "$credits")</text>"
  y=$((y + 38)) line=""
  while IFS= read -r name; do
    if [[ -n "$line" && $((${#line} + ${#name} + 3)) -gt 100 ]]; then
      tpl[CREDITS]+="<text class=\"names\" x=\"280\" y=\"$y\">$line</text>"
      y=$((y + 38)) line=""
    fi
    name="${name//&/&amp;}"
    line+="${line:+ · }${name//</&lt;}"
  done < <(yq eval ".groups[$i].entries[].name" "$credits")
  tpl[CREDITS]+="<text class=\"names\" x=\"280\" y=\"$y\">$line</text>"
  y=$((y + 56))
done
compose calamares/slide-4.svg "$branding/slide-4.png"
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
    cloud) tpl[AI_DETAIL]="opencode · $(yq eval '.ai.cloud.providers[0].id + " and " + (.ai.cloud.providers | length - 1 | tostring) + " more"' "$settings")" ;;
    *) tpl[AI_DETAIL]="patina install offers it again" tpl[AI_DEMO]=0.15 ;;
  esac
  render "$templates/calamares/ai.svg" "$tmp/ai-$id.svg"
  rsvg-convert --width 960 --height 540 --output "$branding/ai-$id.png" "$tmp/ai-$id.svg"
done
yq -i "
  .strings.version = \"${tpl[VERSION]}\" |
  .strings.shortVersion = \"${tpl[VERSION]}\" |
  .style.SidebarBackground = \"${tpl[BASE00]}\" |
  .style.SidebarText = \"${tpl[BASE05]}\" |
  .style.SidebarTextCurrent = \"${tpl[BASE00]}\" |
  .style.SidebarBackgroundCurrent = \"${tpl[ACCENT]}\"
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
left="$(grep -lF "\${" "$branding/stylesheet.qss" "$grub/live-theme/theme.txt" "$openbox/themerc" || true)"
[[ -z "$left" ]] || { echo "assets.sh: unfilled placeholders in: $left" >&2; exit 70; }
say "done: ${tpl[THEME]} ${tpl[VERSION]}"
