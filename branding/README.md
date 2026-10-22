# branding/

The patina21 marks as data. Scripts print these files; they never contain the artwork
themselves.

```text
branding/
  logo.txt      the ASCII wordmark: the mark of every terminal surface
  wordmark.svg  the typeset wordmark, patina²¹, for screens
  wave.svg      the patina wave alone, square, where a screen wants a small icon
```

Two marks, one rule: the ASCII mark on terminals (`patina help`, the install TUI, the
fastfetch greeting, the console, the README), the typeset wordmark on screens (the boot
menu of the live image, the installer, the login screen, the Plasma splash), never both
on one surface. In running text the name stays `patina21`; the superscript figures are
the wordmark's typographic form only.

## logo.txt

```text
              __   __               ______ ____
.-----.---.-.|  |_|__|.-----.---.-.|__    |_   |
|  _  |  _  ||   _|  ||     |  _  ||    __|_|  |_
|   __|___._||____|__||__|__|___._||______|______|
|__|
~'~.~'~.~'~.~'~.~'~.~'~.~'~.~'~.~'~.~'~.~'~.~'~
```

The wave under the name is the patina: the layer that forms on the surface and gives the
thing its character. Everything above it stays sharp.

Rules:

- Plain 7-bit ASCII, no colour codes, no box-drawing characters: it must look right on a
  Linux console at first boot, over a serial line and in a GitHub README.
- Colour is never in the file. `patina help` adds a pink-to-purple gradient at print
  time, only for an interactive terminal (24-bit colour, suppressed by `NO_COLOR`), so
  the console, `/etc/issue.d` and the README still get the plain mark.
- At most 60 columns and 8 lines, so it fits an 80-column terminal with a margin and a
  TTY with its login prompt.
- The letterforms are fixed. Change the wave only here, in one place.
- Where it appears: `patina help`, the README, the console of the live image and of the
  installed system (`/etc/issue.d`), the first-boot screen, the install TUI and the
  fastfetch greeting of a new terminal. See `docs/branding.md` for the trademark rules
  around Debian's own marks.
- Print it with `print_logo` from `bin/lib.sh` (`auto`: the gradient only on an
  interactive 24-bit terminal; `always`: the gradient in any case, for the file
  fastfetch shows) or `cat "$PATINA_PATH/branding/logo.txt"`; never paste a copy into a
  script.

## wordmark.svg and wave.svg

The word `patina` lowercase in Inter 600, the `²¹` as the font's own superscript figures
in the pink-to-purple gradient (`#ff5fd0` to `#8b5cf6`, the same gradient `print_logo`
uses), and the wave under it; `wave.svg` is the wave alone in an 80x80 square, for the
installer's sidebar tile and a window icon. Both are plain SVG with `<text>`, so they
need Inter where they are rendered: the image build, the live system and the desktop
bundle all install `fonts-inter`. The colours are the brand's and do not follow a
theme; a theme places the marks on its own colours. Scripts copy or rasterise these
files (`rsvg-convert`); nothing draws the marks itself.

The marks are GPL-3.0-or-later like the rest of the repository.
