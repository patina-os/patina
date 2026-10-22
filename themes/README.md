# themes/

A theme is a directory of data: a palette, wallpapers and a few metadata fields. No
scripts. The renderers under `desktops/` turn a theme into real configuration.

```text
themes/<name>/
  theme.yaml        metadata and palette (required)
  wallpapers/       images listed in theme.yaml (optional): SVG, rendered when the
                    theme is applied, or PNG, used as it is
  README.md         credits and screenshots (optional)
```

`patina theme list` shows the themes, `patina theme set <name>` renders one for this
user's desktop, `patina theme current` says which one is on. `patina install` applies
the default of `defaults/settings.yaml`, or `PATINA_THEME=<name>`.

`<name>` is lowercase kebab-case and equals the `name` field. `_template/` is the
skeleton to copy; tools skip entries starting with `_`.

## theme.yaml

See `_template/theme.yaml`; every field is commented there. The palette uses base16 keys
(`base00`..`base0F`, with the base24 extras `base10`..`base17` optional), so a scheme from
the [tinted-theming](https://github.com/tinted-theming/home) project can be imported by
copying its `palette` block.

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

Theme data in this repository is contributed under the repository license
(GPL-3.0-or-later). Artwork may carry its own license, declared in `artwork_license`;
CC-BY-SA-4.0 is the recommended choice.
