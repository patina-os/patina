# Branding and trademarks

Verify this page against the current openSUSE trademark guidelines before the first ISO:
<https://en.opensuse.org/openSUSE:Trademark_guidelines>

## Our name

- The project is `patina21`, always lowercase, also at the start of a sentence. The
  command is `patina`. The number is never explained; the README FAQ has the only answer.
- Never "openSUSE patina21", "patina21 Linux" or anything that reads as a distribution or
  as an openSUSE product. Say "patina21, a polish layer for KDE Plasma on openSUSE" or
  "based on openSUSE Tumbleweed".

## The logo

The only logo is the ASCII wordmark in `branding/logo.txt`: the name, a wave of patina
under it, the tagline. It is plain text so that it looks the same in a README, in
`patina help`, on the ISO console and on the first-boot screen. `branding/README.md` has
the rules for changing it. There is no bitmap logo yet; when one is drawn it goes next
to the text mark in `branding/` and follows the same rules: our mark only, nothing that
borrows from openSUSE's or KDE's.

Wording next to the logo: "a polish layer for KDE Plasma on openSUSE" or "based on
openSUSE Tumbleweed". Never a geeko, never "openSUSE" in a larger type than our own name.

## openSUSE's marks

- "openSUSE" and the geeko logo belong to the openSUSE project. We may state that patina21
  runs on or is built from openSUSE; we may not imply endorsement or use the logo as ours.
- The ISO is branded as patina21 through the Plasma look-and-feel, the wallpaper, the
  installer strings and the text mark on the console only. Concretely: the Agama product
  definition in `iso/kiwi/root/usr/share/agama/products.d/` names the product "patina21
  (openSUSE Tumbleweed)", and `/etc/issue` on the live system shows `branding/logo.txt`.
  Stock openSUSE branding packages stay installed and unmodified; package names,
  repository names, the installation repositories and release notes remain openSUSE's.
- KDE and Plasma are trademarks of KDE e.V. The same rule applies: describe, do not imply.
