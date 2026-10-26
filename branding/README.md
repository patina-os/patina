# branding/

The patina marks as data. Scripts print these files; they never contain the artwork
themselves.

```text
branding/
  logo.txt        the mark, in text: fastfetch, the console, the first-boot screen
  wordmark.txt    the name in block letters: patina help, the install questions
  wordmark.svg    the mark typeset beside patina, the mark of screens and the README
  icon.svg        the mark typeset in a square, for icons of 96 px and up
  icon-small.svg  the mark as dots, for 80 px and below
  export/         wordmark.txt drawn as outlines: SVG and PNG, transparent and dark
```

The mark is the summit; the wordmark is the name. Terminals show the mark where there is
room beside other text (the fastfetch greeting) or no font to trust (the console), and
the wordmark where the name leads (`patina help`, the install questions), outlined from
`export/` where the name leads on a screen (the README's header, the installer's welcome
page). The other screens show the lockup of mark and name. In running text the name stays
`patina`.

## logo.txt, the mark

```text
      iiiiiiiiiii
   iiiittttttttttiii
 iii ttt nnnnnnnntttii
ii  tt nnnaaaaaaannttii
i   t  n  patina▲an t i
ii  tt nnnaaaaaaannttii
 iii ttt nnnnnnnntttii
   iiiittttttttttiii
      iiiiiiiiiii
```

A summit drawn as contour rings, steeper on one side, and shaded with the letters of
its own name: i at the foot, then t, n and a as it gets denser. The word patina is the
summit line; the ▲ beside it is the survey point, the summit of the default theme's
contour map. 23 columns and 9 lines: about as tall as it is wide on screen, since a terminal
cell is twice as tall as it is wide.

- Plain text without colour codes: ASCII letters and spaces, and the ▲ (U+25B2). A
  console font without the ▲ shows a placeholder there; the rest stays intact, on a
  serial line too.
- The rings use only i, t, n and a, and the word keeps its line. Change the mark here
  and in `wordmark.svg` and `icon.svg` together: their characters match these one for
  one.
- Where it appears: the fastfetch greeting of a new terminal, the console of the live
  image and of the installed system (`/etc/issue.d`), the first-boot screen.
- Print it with `print_logo` from `bin/lib.sh` (`auto`: colours only on an interactive
  24-bit terminal; `always`: colours in any case, for the file fastfetch shows). The
  colours are the brand's: deep violet for i, violet for t, lavender for n and a, bold
  white for the word, green for the ▲.

## wordmark.txt, the name

```text
            █▌  ▲
 ▄▄▟▙▖ ▄█▙▖▗█▙▄▗▄▄▗▄▟█▖ ▗▟█▄
 ██▀▜█ ▀▀▜█▝█▛▀▝▜█▐█▛▜█ ▝▀▀█▌
 █▌ ▐█ ▄███ █▌  ▐█▐█ ▐█ ▗▟██▌
 █▙ ▟█▗█▌▐█ ▜▙  ▐█▐█ ▐█ ▟█ █▌
 █▛██▛ ██▛█ ▝██ ▐█▐█ ▐█ ▐██▜▌
 █▌
 ▀▘
⢄⣀⡀   ⢀⣀⡠⠤⠤⠒⠒⠒⠒⠢⠤⢄⣀⣀   ⢀⣀⣀⠤⠤⠒
  ⠈⢉⣉⡩⠥⠔⠒⠒⠒⠒⠤⠤⣀⡀    ⠉⣉⣉⠥⠔⠒⠒⠒⠒
```

patina in heavy block letters traced from the screen wordmark's Sora ExtraBold, the dot
of the i replaced by the survey point, and two contour lines in braille under it. 29
columns and 10 lines.

- Unicode on purpose: quadrant blocks (U+2580–259F), braille (U+2800–28FF) and the ▲.
  Terminal fonts carry them; the Linux console may not, which is why the console shows
  `logo.txt` instead.
- Where it appears: `patina help` and the install questions. Not in the README: the
  fonts a browser uses for code lack the quadrant and braille characters, so the
  letters fall apart there; the README shows `wordmark.svg` instead.
- Print it with `print_wordmark` from `bin/lib.sh` (same `auto` and `always`): the
  letters white, the ▲ green, the upper line violet and the lower one deep violet.

## wordmark.svg, icon.svg and icon-small.svg

`wordmark.svg` is the lockup for screens: the characters of `logo.txt` set in JetBrains
Mono in their colours (deep violet `#6d4fc2`, violet `#9b6bff`, lavender `#c3a2ff` and
`#e4d6ff`, white `#f5f7f9`, the survey point green `#3cff9d`), and beside them the word
`patina` lowercase in Sora ExtraBold, white, so the ▲ is the lockup's one green. The
violet and the green are those of the default theme, aurora, so the desktop and the
marks read as one; they stay fixed when another theme is set. Each run of
characters is its own `<text>` with an explicit x, so the grid survives renderers that
collapse spaces. `icon.svg` sets the same characters in a square for icons of 96 px and
up. Below that the letters blur, so `icon-small.svg` reduces the rings to a 9x5 grid of
dots around the green ▲, for the installer's sidebar and window icons.

The SVG files with `<text>` need JetBrains Mono and Sora where they are rendered: the
image build, the live system and the desktop bundle install `fonts-jetbrains-mono` and
`fonts-sora`. The colours are the brand's and do not follow a theme; they are made for
a dark ground, and a theme places the marks on its own colours. Scripts copy or
rasterise these files (`rsvg-convert`); nothing draws the marks itself.

The marks are GPL-3.0-or-later like the rest of the repository.

## export/, the block-letter name as a picture

`wordmark.txt` drawn as outlines, for places where its characters or fonts are not to
be trusted (a web page, a slide, a sticker): every quadrant block a rectangle, every
braille dot a circle, the ▲ a triangle, on the grid of a terminal cell (twice as tall
as wide), so it looks the same everywhere with no font. The colours are
`print_wordmark`'s: the letters white `#f5f7f9`, the ▲ green `#3cff9d`, the upper
contour line violet `#9b6bff`, the lower one deep violet `#6d4fc2`.

```text
export/
  wordmark-blocks.svg            transparent, for a dark ground
  wordmark-blocks-dark.svg       on aurora's black, for any ground
  wordmark-blocks-512.png        the two, rasterised at 512 and 1024 px wide
  wordmark-blocks-1024.png
  wordmark-blocks-dark-512.png
  wordmark-blocks-dark-1024.png
```

They are derived from `wordmark.txt`, drawn once by a script and kept as the files it
produced (the script is not part of the repository, like the wallpapers'); when
`wordmark.txt` changes they are drawn again, the PNGs with `rsvg-convert --width`.
