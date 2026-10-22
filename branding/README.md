# branding/

The patina21 marks as data. Scripts print these files; they never contain the artwork
themselves.

```text
branding/
  logo.txt      the text mark: the mark of every terminal surface
  wordmark.svg  the text mark typeset beside patina²¹, the mark of screens
  icon.svg      the summit as dots, square, where a screen wants a small icon
```

One mark in three forms: the text on terminals (`patina help`, the install TUI, the
fastfetch greeting, the console, the README), the typeset lockup on screens (the boot
menu of the live image, the installer, the login screen, the Plasma splash), the square
where only a small icon fits. In running text the name stays `patina21`; the
superscript figures are the wordmark's typographic form only.

## logo.txt

```text
     iiiiiiiiiiiii
 iiiiittttttttttttiiii
ii  ttt nnnnnnnnnntt ii
i   t  nn patina▲nntt i
ii  ttt nnnnnnnnnntt ii
 iiiiittttttttttttiiii
     iiiiiiiiiiiii
```

A summit drawn as contour rings, steeper on one side, and shaded with the letters of
its own name: light i and t at the foot, dense n near the top. The word patina is the
summit line; the ▲ beside it is the survey point, the datum the default theme is named
after.

Rules:

- Plain UTF-8 text, no colour codes, no box-drawing characters. The only character
  outside 7-bit ASCII is the ▲ (U+25B2). A console font without it shows a placeholder
  there; the rest of the mark stays intact, on a serial line too.
- Colour is never in the file. `patina help` adds the brand's colours at print time,
  only for an interactive terminal (24-bit colour, suppressed by `NO_COLOR`): slate for
  i, ice for t, pale ice for n, bold white for the word, coral for the ▲. The console,
  `/etc/issue.d` and the README get the plain mark.
- 23 columns and 7 lines, so it fits an 80-column terminal beside fastfetch's facts and
  a TTY with its login prompt.
- The letterforms are fixed: the rings use only i, t and n, and the word stays on its
  own line. Change the mark here and in `wordmark.svg` together; the characters of the
  two files match one for one.
- Where it appears: `patina help`, the README, the console of the live image and of the
  installed system (`/etc/issue.d`), the first-boot screen, the install TUI and the
  fastfetch greeting of a new terminal. See `docs/branding.md` for the trademark rules
  around Debian's own marks.
- Print it with `print_logo` from `bin/lib.sh` (`auto`: colours only on an interactive
  24-bit terminal; `always`: colours in any case, for the file fastfetch shows) or `cat
  "$PATINA_PATH/branding/logo.txt"`; never paste a copy into a script.

## wordmark.svg and icon.svg

`wordmark.svg` is the lockup: the characters of `logo.txt` set in JetBrains Mono in
their colours (slate `#4f7394`, ice `#6ab8ff`, pale ice `#a9d7ff`, white `#f5f7f9`, the
survey point coral `#ff5f6d`), and beside them the word `patina` lowercase in Sora
ExtraBold with the `21` small and raised in coral. Each run of characters is its own
`<text>` with an explicit x, so the grid survives renderers that collapse spaces.
`icon.svg` is the summit reduced to a 9x5 grid of dots with the coral ▲, in an 80x80
square, for the installer's sidebar tile and a window icon.

Both are plain SVG, `wordmark.svg` with `<text>`, so it needs JetBrains Mono and Sora
where it is rendered: the image build, the live system and the desktop bundle install
`fonts-jetbrains-mono` and `fonts-sora`. The colours are the brand's and do not follow
a theme; they are made for a dark ground, and a theme places the marks on its own
colours. Scripts copy or rasterise these files (`rsvg-convert`); nothing draws the
marks itself.

The marks are GPL-3.0-or-later like the rest of the repository.
