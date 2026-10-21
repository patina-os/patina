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

The only logo is the ASCII wordmark in `branding/logo.txt`: the name, a wave of patina
under it, the tagline. It is plain text so that it looks the same in a README, in
`patina help`, on the live image's console and on the first-boot screen.
`branding/README.md` has the rules for changing it. There is no bitmap logo; the image
build renders the text mark into an SVG for the installer at build time, so there is
still only one copy. When a drawn logo exists it goes next to the text mark in
`branding/` and follows the same rules: our mark only, nothing that borrows from
Debian's or KDE's.

Wording next to the logo: "a polish layer for KDE Plasma on Debian" or "based on
Debian". Never the swirl, never "Debian" in a larger type than our own name.

## Debian's marks

- "Debian" and the swirl belong to Software in the Public Interest, Inc. Debian's policy
  allows true factual statements such as "based on Debian"; we may not imply endorsement
  or use the swirl as ours.
- The image is branded as patina21 through the installer (Calamares branding in
  `iso/live/config/includes.chroot/etc/calamares/branding/patina21/`), the text mark on
  the console (`/etc/issue.d`), and later the Plasma look-and-feel and wallpaper. Stock
  Debian branding packages stay installed and unmodified; package names, repository
  names, the archive and release notes remain Debian's. The GRUB menu of an installed
  system keeps Debian's entry name.
- KDE and Plasma are trademarks of KDE e.V. The same rule applies: describe, do not imply.
