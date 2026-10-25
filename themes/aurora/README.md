# aurora

The default patina theme, made for OLED panels: true black, neon green as the accent,
violet as the second colour, and a contour map that glows green at its summit and
turns violet towards the edges. Dark by default, with a light mode
(`patina theme mode light`).

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

## Light mode

The `light:` block holds a second palette with the same roles on lavender white
(`#f7f6fb`): a deeper green (`#087a46`) that carries white text, the violet `#7c3aed`,
Breeze's light icons and its own wallpaper. `patina theme mode light` switches to it,
`patina theme mode dark` back; the choice is kept for every later `patina theme set`.
The boot menu, the installer, the Plasma splash and the login screen stay dark in
either mode: the marks are made for a dark ground.

## Wallpapers

`contour.svg`: height lines around a summit, every 20 m, every 100 m brighter with a
soft glow and labelled in JetBrains Mono, drawn in one gradient from green at the summit
through cyan to violet at the edges; the survey point ▲ glows green with its height. A
faint violet grid carries map references along the edges. The ground is black, so most
of the screen stays dark. `contour-light.svg` is the same map on lavender white for the
light mode. Both are drawn once from a height field and kept as artwork, rendered at
3840x2160 when the theme is applied; the script that drew them is not part of the
repository. Licensed CC-BY-SA-4.0 (`artwork_license`); the theme data is
GPL-3.0-or-later like the rest of the repository.

The labels need JetBrains Mono where the SVG is rendered; the desktop bundle and the
image build install `fonts-jetbrains-mono`.

## Origin

aurora replaced datum as the default in October 2026, for a desktop that looks its best
on an OLED screen. datum keeps the contour map in graphite, ice and coral, and stays an
option (`patina theme set datum`), as does amethyst.
