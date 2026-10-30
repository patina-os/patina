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
# them: the theme's first wallpaper at 1920x1080 and the name in block letters
# rasterised.
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
rsvg-convert --width 1160 --output "$tmp/blocks.png" "$repo/branding/export/wordmark-blocks.svg"

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
# spacing of the mark's rings, so it gets rsvg renderings. The welcome page, the slides
# and the boot menu show the name in block letters (branding/export).
cp "$tmp/blocks.png" "$branding/welcome.png"
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
# The slides: a tour of patina on one ground, with the desktop workflow's screenshots
# (docs/screenshots/, refreshed every release), so they show the desktop as it is.
compose calamares/slide-ground.svg "$tmp/ground.png"
cp "$repo/docs/screenshots/desktop-amd64.png" "$tmp/desktop.png"
cp "$repo/docs/screenshots/command-palette-amd64.png" "$tmp/palette.png"
for n in 1 2 3 4 5; do
  compose "calamares/slide-$n.svg" "$branding/slide-$n.png" "${slide_size[@]}"
done
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
compose calamares/slide-6.svg "$branding/slide-6.png" "${slide_size[@]}"
render "$templates/calamares/stylesheet.qss" "$branding/stylesheet.qss"

# The agent and AI pages: their default answers come from ai.agent and ai.mode of
# defaults/settings.yaml (no agent, and a model on this computer, while ai.mode is none),
# and each answer gets a picture with its name, what it sets up and what the agent does
# with a change: opencode asks, Hermes runs one it does not count as dangerous.
say "rendering the agent and AI pages"
mode="$(yq eval '.ai.mode' "$settings")"
chooser="$chroot/etc/calamares/modules/packagechooser-agent.conf"
if [[ "$mode" == none ]]; then
  yq -i '.default = "none"' "$chooser"
else
  yq -i ".default = \"$(yq eval '.ai.agent' "$settings")\"" "$chooser"
fi
tpl[AI_TAG]=agent
for id in $(yq eval '.items[].id' "$chooser"); do
  tpl[AI_NAME]="$(yq eval ".items[] | select(.id == \"$id\") | .name" "$chooser")"
  tpl[AI_DEMO]=1
  case "$id" in
    opencode) tpl[AI_DETAIL]="free · asks before every change" tpl[AI_ASK]="allow? y/n" ;;
    hermes) tpl[AI_DETAIL]="free · remembers · asks before risky commands" tpl[AI_ASK]="done" ;;
    *) tpl[AI_DETAIL]="patina ai on turns one on later" tpl[AI_ASK]="" tpl[AI_DEMO]=0.15 ;;
  esac
  render "$templates/calamares/ai.svg" "$tmp/agent-$id.svg"
  rsvg-convert --width 960 --height 540 --output "$branding/agent-$id.png" "$tmp/agent-$id.svg"
done
chooser="$chroot/etc/calamares/modules/packagechooser-ai.conf"
[[ "$mode" != none ]] || mode=local
yq -i ".default = \"$mode\"" "$chooser"
tpl[AI_TAG]=model tpl[AI_ASK]="" tpl[AI_DEMO]=1
for id in $(yq eval '.items[].id' "$chooser"); do
  tpl[AI_NAME]="$(yq eval ".items[] | select(.id == \"$id\") | .name" "$chooser")"
  case "$id" in
    local) tpl[AI_DETAIL]="Ollama · $(yq eval '.ai.local.models[0].model' "$settings")" ;;
    cloud) tpl[AI_DETAIL]="$(yq eval '.ai.cloud.providers[0].name' "$settings") first · picked at first boot" ;;
  esac
  render "$templates/calamares/ai.svg" "$tmp/ai-$id.svg"
  rsvg-convert --width 960 --height 540 --output "$branding/ai-$id.png" "$tmp/ai-$id.svg"
done

# The apps and more-apps pages: the apps page's default is the bundle marked default,
# and every bundle gets a picture with its name, its line from manifest/bundles/ and
# how much it brings; the more-apps page's empty item (nothing picked) one of its own.
say "rendering the app pages"
for page in apps more; do
  chooser="$chroot/etc/calamares/modules/packagechooser-$page.conf"
  for ((i = 0; i < $(yq eval '.items | length' "$chooser"); i++)); do
    id="$(yq eval ".items[$i].id" "$chooser")"
    tpl[BUNDLE_NAME]="$(yq eval ".items[$i].name" "$chooser")"
    if [[ -z "$id" ]]; then
      tpl[BUNDLE_DETAIL]="Standard or Minimal is enough to begin."
      tpl[BUNDLE_COUNT]="patina install adds the others at any time"
      id=none
    else
      bundle="$repo/manifest/bundles/$id.yaml"
      if [[ "$page" == apps ]] && yq eval -e '.default == true' "$bundle" > /dev/null 2>&1; then
        yq -i ".default = \"$id\"" "$chooser"
      fi
      tpl[BUNDLE_DETAIL]="$(yq eval '.description' "$bundle")"
      tpl[BUNDLE_COUNT]="$(yq eval '(.packages // [] | length) + (.flatpaks // [] | length) + (.upstream // [] | length)' "$bundle") packages, apps and tools"
    fi
    render "$templates/calamares/bundle.svg" "$tmp/bundle-$id.svg"
    rsvg-convert --width 960 --height 540 --output "$branding/bundle-$id.png" "$tmp/bundle-$id.svg"
  done
done

# The theme page: one item per theme of themes/, the default theme preselected, each
# drawn in its own palette over its first wallpaper (a subshell, so the installer's
# colours stay the default theme's).
say "rendering the theme page"
chooser="$chroot/etc/calamares/modules/packagechooser-theme.conf"
yq -i ".default = \"$(yq eval '.theme' "$settings")\" | .items = []" "$chooser"
for dir in "$repo"/themes/[a-z]*/; do
  name="$(basename "$dir")"
  NAME="$name" DISPLAY="$(yq eval '.display_name' "$dir/theme.yaml")" \
    DESCRIPTION="$(yq eval '.description // ""' "$dir/theme.yaml")" yq -i '.items += [{
      "id": strenv(NAME), "name": strenv(DISPLAY), "description": strenv(DESCRIPTION),
      "screenshot": "theme-" + strenv(NAME) + ".png"}]' "$chooser"
  (
    theme_vars "$dir/theme.yaml" "$settings"
    raster "$dir/$(yq eval '.wallpapers[0]' "$dir/theme.yaml")" "$tmp/theme-wallpaper.png"
    render "$templates/calamares/theme.svg" "$tmp/theme-$name.svg"
    rsvg-convert --width 960 --height 540 --output "$branding/theme-$name.png" "$tmp/theme-$name.svg"
  )
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

# The terminal of the Wi-Fi step (root/.xinitrc).
render "$templates/xterm/Xdefaults" "$chroot/root/.Xdefaults"

# Every placeholder must be gone.
left="$(grep -lF "\${" "$branding/stylesheet.qss" "$grub/live-theme/theme.txt" "$openbox/themerc" \
  "$chroot/etc/fonts/local.conf" "$chroot/root/.Xdefaults" || true)"
[[ -z "$left" ]] || { echo "assets.sh: unfilled placeholders in: $left" >&2; exit 70; }
say "done: ${tpl[THEME]} ${tpl[VERSION]}"
