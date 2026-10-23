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
raster() {   # raster <svg-or-png> <out.png>: a theme wallpaper at 1920x1080
  case "$1" in
    *.svg) rsvg-convert --width 1920 --height 1080 --output "$2" "$1" ;;
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
cp "$repo/branding/wordmark.svg" "$branding/logo.svg"
cp "$repo/branding/icon-small.svg" "$branding/logo-square.svg"
compose calamares/wallpaper.svg "$branding/wallpaper.png"
compose calamares/slide-1.svg "$branding/slide-1.png"
compose calamares/slide-2.svg "$branding/slide-2.png"
compose calamares/slide-3.svg "$branding/slide-3.png"
render "$templates/calamares/stylesheet.qss" "$branding/stylesheet.qss"
yq -i "
  .strings.version = \"${tpl[VERSION]}\" |
  .strings.shortVersion = \"${tpl[VERSION]}\" |
  .style.SidebarBackground = \"${tpl[BASE00]}\" |
  .style.SidebarText = \"${tpl[BASE05]}\" |
  .style.SidebarTextCurrent = \"${tpl[BASE00]}\" |
  .style.SidebarBackgroundCurrent = \"${tpl[BASE0E]}\"
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
