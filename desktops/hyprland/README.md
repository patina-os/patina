# desktops/hyprland/

Hyprland as an add-on desktop, never the default (docs/roadmap.md, Phase 7). Nothing
here yet except this contract; `apply.sh` and `templates/` come only after the Plasma
renderer (Phase 2) is stable, and only from the same theme data: a theme that needs a
change under `themes/` to render on Hyprland is a renderer bug, not a theme bug.

## Who it is for

Plasma is the on-ramp for everyone. Hyprland is for the power users patina also wants:
developers who live in a terminal and work with agents, and people who rice their
desktop. Omarchy shows what draws them: a tiled screen of terminal apps (neovim, btop,
nvtop, a package picker, Wi-Fi and Bluetooth TUIs, an agent CLI with a model picker), a
thin bar, gaps and coloured borders, one palette across all of it, and a logo in
fastfetch that makes every screenshot an advertisement.

What patina takes from that:

- One palette everywhere, and most of it is the terminal, which every desktop shares:
  `desktops/terminal/` already renders kitty, fastfetch, btop, neovim, bat and fzf from
  the theme, on Plasma today and on Hyprland unchanged
- Keyboard-first system settings: a `patina menu` (fuzzel, or `gum` in a terminal)
  that opens the tools Debian's archive carries: `nmtui` for networks,
  `bluetoothctl` for Bluetooth, `pulsemixer` for audio, a package search over apt and
  Flathub through `fzf`, `patina theme set` and `patina update`. Omarchy's own TUIs
  (impala, bluetui, wiremix) and its launcher (walker) are not in Debian, and the
  menu is a list of commands as data, not a program
- The agent as a place, not only a shortcut: `Meta+A` toggles a special workspace with
  the agent CLI in its kitty profile (opencode by default, pointed at the local
  Ollama), and `nvtop` (in Debian's archive) shows what the local model costs the GPU

Where patina stays different:

- Plasma and Hyprland side by side, from one theme and one set of chords: start on
  Plasma, pick the Hyprland session at the login screen when ready, keep the colours,
  the wallpaper and `Meta+Return`, `Meta+Space`, `Meta+Q`, `Meta+A`. Omarchy is
  Hyprland only
- Free and EU-sovereign defaults: no proprietary chat, no web apps of US services, the
  free agent CLI first; Debian stable, no package repository of our own, ARM as well
  as x86_64

## Why it waits

Debian 13 does not carry Hyprland in its main archive: it is in `trixie-backports`
(0.55) and in Debian 14's archive (0.56, with `hyprpaper`, `hyprlock`, `hypridle`,
`hyprsunset`, `hyprpicker`, `uwsm` and `xdg-desktop-portal-hyprland`). The manifest
installs from the base's main archive only, so the add-on waits for Debian 14
(Phase 6); the manifest does not learn about backports as a source. The rest of the
stack is in Debian 13 already: `waybar`, `fuzzel`, `swaybg`, `mako-notifier`,
`swayosd`, `grim`, `slurp`, `wl-clipboard`, `brightnessctl`, `playerctl`, `wlogout`,
`nvtop`, `pulsemixer`.

## What it will produce from a theme and `defaults/`

- `~/.config/hypr/patina-theme.conf` with the window border (the accent fading into
  `base0F`), shadow, gap and group colours from the base16 palette, sourced by
  the user's `hyprland.conf`
- `~/.config/hypr/patina-binds.conf` with the actions from `defaults/keybindings.yaml`
  translated to `bind` lines through an `actions.yaml`, the same chords as on Plasma;
  the tiling actions only a tiling desktop has (focus and move by direction,
  workspaces 1 to 9, the agent's special workspace) are added there as data. Unknown
  actions are warned about, not fatal
- the wallpaper the theme declares, set through `hyprpaper`
- a Waybar style (a thin bar at the top: workspaces, clock, tray) and a Fuzzel colour
  block from the same palette; `mako` and `hyprlock` colours likewise
- the terminal from `desktops/terminal/`, unchanged: kitty is the terminal on both
  desktops
- GTK and Qt apps follow through the portal (`xdg-desktop-portal-hyprland`) and the
  same colour scheme files the Plasma renderer writes, so switching desktops keeps
  the theme

Rules that stay: no commands or paths in the theme, output only under the user's XDG
directories, idempotent, and the add-on never touches `desktops/plasma/`.
