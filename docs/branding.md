# Branding and trademarks

Verify this page against Debian's current trademark policy before the first image:
<https://www.debian.org/trademark>

## Our name

- The project is `patina21`, always lowercase, also at the start of a sentence. The
  command is `patina`. The number is never explained; the README FAQ has the only answer.
- Never "Debian patina21", "patina21 Linux" or anything that reads as a distribution or
  as a Debian product. Say "patina21, a polish layer for KDE Plasma on Debian" or "based
  on Debian".

## The logo

The mark is text: a summit drawn as contour rings with the letters of patina, light i
and t at the foot, dense n near the top, the word itself as the summit line and the
survey point ▲ beside it. `logo.txt` holds it as plain text, so that it looks the same
in a README, in `patina help`, on the live image's console, on the first-boot screen,
in the install TUI and in the fastfetch greeting of a new terminal. `wordmark.svg` sets
the same characters in JetBrains Mono beside patina²¹ in Sora ExtraBold; that lockup is
what screens show: the live image's boot menu, the installer, the login screen and the
Plasma splash. `icon.svg` reduces the summit to dots for small squares (the installer's
sidebar, a window icon). `branding/README.md` has the rules for changing them. There is
no bitmap logo: the image build and the desktop renderer copy or rasterise the SVG. The
marks are ours only, nothing that borrows from Debian's or KDE's.

Wording next to the logo: "a polish layer for KDE Plasma on Debian" or "based on
Debian". Never the swirl, never "Debian" in a larger type than our own name.

## Debian's marks

- "Debian" and the swirl belong to Software in the Public Interest, Inc. Debian's policy
  allows true factual statements such as "based on Debian"; we may not imply endorsement
  or use the swirl as ours.
- The image is branded as patina21 through the live image's boot menu (a GRUB theme and
  splash rendered from the theme), the installer (Calamares branding in
  `iso/live/config/includes.chroot/etc/calamares/branding/patina21/`, rendered by
  `iso/live/assets.sh`), the text mark on the console (`/etc/issue.d`), and on the
  installed system the login screen, the Plasma splash, the look-and-feel and the
  wallpaper. Stock Debian branding packages stay installed and unmodified; package
  names, repository names, the archive and release notes remain Debian's. The GRUB menu
  of an installed system keeps Debian's entry name and Debian's look.
- KDE and Plasma are trademarks of KDE e.V. The same rule applies: describe, do not imply.
