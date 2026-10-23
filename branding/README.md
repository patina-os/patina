# branding/

The patina marks as data. Scripts print these files; they never contain the artwork
themselves.

```text
branding/
  logo.txt        the mark, in text: fastfetch, the console, the first-boot screen
  wordmark.txt    the name in block letters: patina help, the install questions, README
  wordmark.svg    the mark typeset beside patina, the mark of screens
  icon.svg        the mark typeset in a square, for icons of 96 px and up
  icon-small.svg  the mark as dots, for 80 px and below
```

The mark is the summit; the wordmark is the name. Terminals show the mark where there is
room beside other text (the fastfetch greeting) or no font to trust (the console), and
the wordmark where the name leads (`patina help`, the install questions, the README).
Screens show the lockup of mark and name. In running text the name stays `patina`.

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
summit line; the ▲ beside it is the survey point, the datum the default theme is named
after. 23 columns and 9 lines: about as tall as it is wide on screen, since a terminal
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
  colours are the brand's: slate for i, ice for t, pale ice for n and a, bold white for
  the word, coral for the ▲.

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
- Where it appears: `patina help`, the install questions, the README header.
- Print it with `print_wordmark` from `bin/lib.sh` (same `auto` and `always`): the
  letters white, the ▲ coral, the upper line ice and the lower one slate.

## wordmark.svg, icon.svg and icon-small.svg

`wordmark.svg` is the lockup for screens: the characters of `logo.txt` set in JetBrains
Mono in their colours (slate `#4f7394`, ice `#6ab8ff`, pale ice `#a9d7ff` and `#d6ecff`,
white `#f5f7f9`, the survey point coral `#ff5f6d`), and beside them the word `patina`
lowercase in Sora ExtraBold, white, so the ▲ is the lockup's one coral. Each run of
characters is its own `<text>` with an explicit x, so the grid survives renderers that
collapse spaces. `icon.svg` sets the same characters in a square for icons of 96 px and
up. Below that the letters blur, so `icon-small.svg` reduces the rings to a 9x5 grid of
dots around the coral ▲, for the installer's sidebar and window icons.

The SVG files with `<text>` need JetBrains Mono and Sora where they are rendered: the
image build, the live system and the desktop bundle install `fonts-jetbrains-mono` and
`fonts-sora`. The colours are the brand's and do not follow a theme; they are made for
a dark ground, and a theme places the marks on its own colours. Scripts copy or
rasterise these files (`rsvg-convert`); nothing draws the marks itself.

The marks are GPL-3.0-or-later like the rest of the repository.
