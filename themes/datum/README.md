# datum

A contour map around a survey point. Graphite surfaces, ice-blue lines and one coral
accent; the brand's colours until the marks moved to aurora's violet and green. Dark
variant. `patina theme set datum` picks it.

## Palette

The accent is `base0E` (`#ff5f6d`, coral): selections, focus, toggles, the active task
and the terminal prompt follow it, as Plasma's accent colour. The ice of the contour
lines and of the mark's rings is `base0D` (`#6ab8ff`). The error red, `base08`, is
pushed towards orange (`#ff7b54`) so an error never reads as the accent. The other
base16 slots keep their usual meaning.

## Wallpaper

`contour.svg`: height lines around a summit, every 50 m drawn brighter and labelled in
JetBrains Mono, the 450 m line and a survey route in coral, and the survey point
itself, the datum the theme is named after, with its height. A faint grid carries map
references along the edges. It is drawn once from a height field and kept as artwork,
rendered at 3840x2160 when the theme is applied; the script that drew it is not part
of the repository. Licensed CC-BY-SA-4.0 (`artwork_license`); the theme data is
GPL-3.0-or-later like the rest of the repository.

The labels need JetBrains Mono where the SVG is rendered; the desktop bundle and the
image build install `fonts-jetbrains-mono`.

## Origin

Datum was chosen in the redesign of October 2026 from eight directions;
`docs/design/futures.html` keeps all of them, and the others may become themes of their
own. aurora, the OLED theme in green and violet, replaced it as the default later that
month.
