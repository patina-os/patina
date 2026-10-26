# aurora

The default patina theme, made for OLED panels: true black, neon green as the accent,
violet as the second colour, a Google DeepMind visualisation as the wallpaper and a
contour map that glows green to violet as the second. Dark by default, with a light
mode (`patina theme mode light`).

## Palette

The background, `base00`, is `#000000`: on an OLED panel those pixels stay off. Panels,
title bars and menus (`base01`, `#0b0a10`) sit one step above it, so surfaces keep their
depth and a scrolled view does not smear into the panel next to it.

The accent is `base0B` (`#3cff9d`, green; `accent: base0B` in `theme.yaml`):
selections, focus, the active window, the cursor, the splash line and the terminal
prompt follow it, as Plasma's accent colour. The second colour is `base0E` (`#b77dff`,
violet; `accent_alt: base0E`): hover, glows, the end of gradients (btop's meters, the
installer's progress bar), the agent profile's cursor, and keywords in code. The mark's
rings use the same violet and its survey point the same green. The other base16 slots
keep their usual meaning, tuned to stay apart from the two: a pink-leaning red, a cyan
between the green and the blue, an orchid for `base0F`.

## Icons

Papirus (`papirus-icon-theme` from Debian's archive): Papirus Dark, and Papirus Light
in the light mode. The renderer recolours its folders and the file manager's icon to
the accent, green at the front and darker greens behind and on the pictograms
(`desktops/plasma/icons.yaml`). Every app's icon becomes a monochrome glyph of Papirus
(a terminal for kitty, a cloud for Nextcloud, a key for KeePassXC, a generic one for
apps without a glyph of their own), so the bar, the start menu and the title bars are
one colour, the palette's text colour; Papirus's own monochrome icons in menus,
toolbars and the tray take the same colour from the colour scheme.

The start menu and the other panel popups carry a slight grain (6 %,
`start_menu.grain` in `defaults/settings.yaml`).

## Light mode

The `light:` block holds a second palette with the same roles on lavender white
(`#f7f6fb`): a deeper green (`#087a46`) that carries white text, the violet `#7c3aed`,
Papirus Light with folders in that green, and its own wallpaper. `patina theme mode light` switches to it,
`patina theme mode dark` back; the choice is kept for every later `patina theme set`.
The boot menu, the installer, the Plasma splash and the login screen stay dark in
either mode: the marks are made for a dark ground.

## Wallpapers

`deepmind.jpg`, the default: an abstract visualisation of flowing digital waves in
blue and violet, by Google DeepMind (credited on Pexels also to the artist Domhnall
Malone), [photo 17483910 on Pexels](https://www.pexels.com/photo/17483910/), resized
to 3840x2160. It is the one third-party file of the theme, under the
[Pexels licence](https://www.pexels.com/license/): free to use and to change, with no
attribution required (given here anyway), but not to be sold unaltered or offered on
other stock-photo sites. It is not a free-culture licence; the maintainer chose the
picture in October 2026 knowing that. The renderer turns it into a PNG at apply time.

`contour.svg`, the second: height lines around a summit, every 20 m, every 100 m
brighter with a soft glow and labelled in JetBrains Mono, drawn in one gradient from
green at the summit through cyan to violet at the edges; the survey point ▲ glows green
with its height. The ground is black, so most of the screen stays dark on OLED.
`contour-light.svg` is the same map on lavender white, the light mode's wallpaper. Both
are drawn once from a height field and kept as artwork, rendered at 3840x2160 when the
theme is applied; the script that drew them is not part of the repository. Licensed
CC-BY-SA-4.0. `artwork_license` names both licences; the theme data is
GPL-3.0-or-later like the rest of the repository.

The labels need JetBrains Mono where the SVG is rendered; the desktop bundle and the
image build install `fonts-jetbrains-mono`.

## Origin

aurora replaced datum as the default in October 2026, for a desktop that looks its best
on an OLED screen. datum keeps the contour map in graphite, ice and coral, and stays an
option (`patina theme set datum`), as does amethyst.
