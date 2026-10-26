# themes/

A theme is a directory of data: a palette, wallpapers and a few metadata fields. No
scripts. The renderers under `desktops/` turn a theme into real configuration.

```text
themes/<name>/
  theme.yaml        metadata and palette (required)
  wallpapers/       images listed in theme.yaml (optional): SVG or JPEG, rendered to
                    PNG when the theme is applied, or PNG, used as it is
  README.md         credits and screenshots (optional)
```

`patina theme list` shows the themes, `patina theme set <name>` renders one for this
user's desktop, `patina theme current` says which one is on. `patina install` applies
the default of `defaults/settings.yaml` (aurora), or `PATINA_THEME=<name>`.
`patina theme mode light` and `patina theme mode dark` switch a theme that has both
modes; the choice is kept for every theme set later (`mode` in
`defaults/settings.yaml` is the default, `PATINA_MODE` overrides).

`<name>` is lowercase kebab-case and equals the `name` field. `_template/` is the
skeleton to copy; tools skip entries starting with `_`.

## theme.yaml

See `_template/theme.yaml`; every field is commented there. The palette uses base16 keys
(`base00`..`base0F`, with the base24 extras `base10`..`base17` optional), so a scheme from
the [tinted-theming](https://github.com/tinted-theming/home) project can be imported by
copying its `palette` block.

The `plasma.icons` hint names an icon theme as Debian ships it. For one listed in
`desktops/plasma/icons.yaml` (Papirus), the renderer recolours its folders to the
theme's accent, so the folders follow every theme without an icon set of its own.

Two optional keys name the palette slots the desktop's colours come from: `accent`
(selections, focus, the active window, the cursor; `base0E` when left out) and
`accent_alt` (hover, glows, the end of gradients; `base0F`). A theme whose accent is
green keeps `base0B` for strings and `base0E` for keywords that way, and the terminal's
sixteen colours keep their meaning.

A theme may carry its other mode as a block named after it: `light:` in a dark theme,
`dark:` in a light one. The block holds a complete `palette` and, optionally,
`wallpapers` and `plasma` hints; whatever it leaves out comes from the top level. The
desktop's wallpaper in that mode is the block's first one, and the theme's own
wallpapers stay available after it. The boot menu, the installer, the Plasma splash and
the login screen always use the dark palette and the theme's own first wallpaper,
because the marks are made for a dark ground.

## Adding a theme

1. `cp -r themes/_template themes/<name>` and fill in `theme.yaml`.
2. Add wallpapers you have the right to redistribute; state their license in
   `artwork_license`. An SVG keeps the pack small and is rendered at 3840x2160 when the
   theme is applied; keep it to gradients, paths and filters (`rsvg-convert` renders it).
3. Keep it desktop-agnostic. Plasma-only hints go under the optional `plasma:` key as
   data, never into renderer code. If a theme seems to need a script, the renderer is
   missing a feature: add it under `desktops/` for all themes.
4. Check with `yq eval '.' themes/<name>/theme.yaml` (CI does the same) and open a pull
   request with a line in `CHANGELOG.md`.

## Sharing a theme from its own repository

A theme can also live in a git repository of its own, by convention named
`patina-<name>-theme`, with `theme.yaml` at its top and the wallpapers under
`wallpapers/`. Anyone installs it with

```sh
patina theme install https://example.org/you/patina-<name>-theme.git
patina theme set <name>
```

`install` clones it into a temporary directory and keeps only data: `theme.yaml`, a
`README.md`, a `LICENSE` and the wallpapers `theme.yaml` lists, its `light:` or
`dark:` block included (SVG, PNG or JPEG, directly under `wallpapers/`). Scripts,
other files and links never leave the clone. The name
must be lowercase kebab-case and may not be one of the themes here; every palette must
be complete and `accent` and `accent_alt` must name palette keys; the names and hints that end up in configuration (`display_name`, `author`,
the licenses, the `plasma:` hints) must be plain words. The theme lands in
`~/.local/share/patina/themes/<name>/`, outside the checkout, with a `.source.yaml`
that records where it came from. `patina theme install` again, or `patina theme
update`, fetches it anew; `patina theme remove <name>` deletes it (never the current
theme, never one of the themes here).

Theme data in this repository is contributed under the repository license
(GPL-3.0-or-later). Artwork may carry its own license, declared in `artwork_license`;
CC-BY-SA-4.0 is the recommended choice.
