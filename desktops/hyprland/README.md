# desktops/hyprland/

Hyprland as an add-on desktop, never the default (docs/roadmap.md, "Later"). Nothing
here yet except this contract; `apply.sh` and `templates/` come only after the Plasma
renderer (Phase 1) is stable, and only from the same theme data: a theme that needs a
change under `themes/` to render on Hyprland is a renderer bug, not a theme bug.

## Why it waits

Debian 13 does not carry Hyprland in its main archive: it is in `trixie-backports`
(0.55) and in Debian 14's archive (0.56, with `hyprpaper`, `hyprlock`, `hypridle` and
`xdg-desktop-portal-hyprland`). The manifest installs from the base's main archive
only, so the add-on waits for Debian 14, or for the manifest to learn about backports
as a source, whichever the roadmap picks first. The rest of the stack is in Debian 13
already: `waybar`, `fuzzel`, `swaybg`, `swaylock`, `swayidle`, `mako-notifier`, `foot`,
`grim`, `slurp`, `wl-clipboard`, `brightnessctl`, `playerctl`, `wlogout`.

## What it will produce from a theme and `defaults/`

- `~/.config/hypr/patina21-theme.conf` with the window border, shadow and group colours
  from the base16 palette, sourced by the user's `hyprland.conf`
- `~/.config/hypr/patina21-binds.conf` with the actions from `defaults/keybindings.yaml`
  translated to `bind` lines; unknown actions are warned about, not fatal
- the wallpaper the theme declares, set through `swaybg` (or `hyprpaper` once Debian
  ships it)
- a Waybar style and a Fuzzel colour block from the same palette
- the terminal colours for `foot`, generated from the palette like the Konsole scheme
- GTK and Qt apps follow through the portal (`xdg-desktop-portal-hyprland`) and the
  same colour scheme files the Plasma renderer writes, so switching desktops keeps
  the theme

Rules that stay: no commands or paths in the theme, output only under the user's XDG
directories, idempotent, and the add-on never touches `desktops/plasma/`.
