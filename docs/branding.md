# Branding and trademarks

Verify this page against Debian's current trademark policy before the first image:
<https://www.debian.org/trademark>

## Our name

- The project is `patina`, always lowercase, also at the start of a sentence. The
  command is `patina`.
- Never "Debian patina", "patina Linux" or anything that reads as a distribution or
  as a Debian product. Say "patina, a polish layer for KDE Plasma on Debian" or "based
  on Debian".

## The logo

The mark is text: a summit drawn as contour rings with the letters of patina, i at the
foot, then t, n and a, the word itself as the summit line and the survey point ▲ beside
it. `logo.txt` holds it as plain text for the fastfetch greeting, the live image's and
the installed system's console and the first-boot screen. `wordmark.txt` holds the name
in block letters for `patina help` and the install questions; the README's header
and the installer's welcome page show it outlined (`branding/export/`).
`wordmark.svg` sets the mark's characters in JetBrains Mono beside patina in Sora
ExtraBold; that lockup is what screens show: the live image's boot menu, the installer's
slides, the login screen and the Plasma splash. `icon.svg` is the mark in a square for large
icons, `icon-small.svg` the mark as dots for small ones (the installer's sidebar, a
window icon). `branding/README.md` has the rules for changing them. patina itself uses
no bitmap logo: the image build and the desktop renderer copy or rasterise the SVG.
For other places (a slide, an avatar, a press article), `branding/export/` keeps every
mark as PNG and JPG up to 2048 px, shown with its files in `branding/export/README.md`. The marks are
ours only, nothing that borrows from Debian's or KDE's.

Wording next to the logo: "a polish layer for KDE Plasma on Debian" or "based on
Debian". Never the swirl, never "Debian" in a larger type than our own name.

## Debian's marks

- "Debian" and the swirl belong to Software in the Public Interest, Inc. Debian's policy
  allows true factual statements such as "based on Debian"; we may not imply endorsement
  or use the swirl as ours.
- The image is branded as patina through the live image's boot menu (a GRUB theme and
  splash rendered from the theme), the installer (Calamares branding in
  `iso/live/config/includes.chroot/etc/calamares/branding/patina/`, rendered by
  `iso/live/assets.sh`), the text mark on the console (`/etc/issue.d`), and on the
  installed system the login screen, the Plasma splash, the look-and-feel and the
  wallpaper. Stock Debian branding packages stay installed and unmodified; package
  names, repository names, the archive and release notes remain Debian's. The GRUB menu
  of an installed system keeps Debian's entry name and Debian's look.
- KDE and Plasma are trademarks of KDE e.V. The same rule applies: describe, do not imply.
