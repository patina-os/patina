# desktops/

One directory per desktop environment. It holds the templates, the action map and the
one thin script that render `themes/` and `defaults/` into that desktop's configuration.

```text
desktops/<desktop>/
  README.md         what the renderer produces and which tools it calls
  apply.sh          `apply.sh <theme-dir>`: render templates, write config, reload
  actions.yaml      how each action of defaults/keybindings.yaml binds on this desktop
  templates/        config files with ${BASE00}-style placeholders the renderer fills
```

Contract:

- Input is only data: a theme directory, `defaults/` and the user's overrides. The
  bundles of the last install arrive as `PATINA_BUNDLES` (space-separated), so a
  renderer can skip what is not installed (the agent shortcut without the agents bundle).
- A desktop never reads or writes another desktop's directory.
- Output lands in the user's XDG config and data directories; the repository checkout
  stays untouched, so `git pull` keeps working. Everything generated carries the theme's
  name, and what belongs to another theme is removed, so switching leaves nothing behind.
- Rendering is idempotent: running it twice yields the same files, and the second run
  ends with `nothing to do`.
- Templates are plain files with `${NAME}` placeholders (the base16 keys as `${BASE00}`
  and as `${BASE00_RGB}` decimals, plus theme and settings fields), filled by the
  renderer in bash. They keep the names of the files they become, so the YAML checks
  skip `templates/`.

`terminal/` is not a desktop: it renders what every desktop shares, kitty, the fastfetch
greeting and the tools in the terminal (btop, neovim, bat, fzf), from the same theme.
`patina theme set` runs it before the desktop's renderer; a desktop may point at its
files, never write them. Its README says what it produces.

`plasma/` is the first and reference desktop. A later `hyprland/` must work from the same
theme data without changes to `themes/`.
