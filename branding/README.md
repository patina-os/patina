# branding/

The patina21 marks as data. Scripts print these files; they never contain the artwork
themselves.

```text
branding/
  logo.txt      the ASCII wordmark with the tagline; the canonical text mark
```

## logo.txt

```text
              __   __               ______ ____
.-----.---.-.|  |_|__|.-----.---.-.|__    |_   |
|  _  |  _  ||   _|  ||     |  _  ||    __|_|  |_
|   __|___._||____|__||__|__|___._||______|______|
|__|
~'~.~'~.~'~.~'~.~'~.~'~.~'~.~'~.~'~.~'~.~'~.~'~
     a polish layer for KDE Plasma on Debian
```

The wave under the name is the patina: the layer that forms on the surface and gives the
thing its character. Everything above it stays sharp.

Rules:

- Plain 7-bit ASCII, no colour codes, no box-drawing characters: it must look right on a
  Linux console at first boot, over a serial line and in a GitHub README.
- At most 60 columns and 8 lines, so it fits an 80-column terminal with a margin and a
  TTY with its login prompt.
- The letterforms are fixed. Change the tagline or the wave only here, in one place.
- Where it appears: `patina help`, the README, the console of the live image and of the
  installed system (`/etc/issue.d`), the first-boot screen and the installer, which
  shows an SVG the image build renders from this file. See `docs/branding.md` for the
  trademark rules around Debian's own marks.
- Print it with `cat "$PATINA_PATH/branding/logo.txt"`; never paste a copy into a script.

The mark is GPL-3.0-or-later like the rest of the repository.
