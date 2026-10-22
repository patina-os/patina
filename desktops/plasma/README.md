# desktops/plasma/

Renderer for KDE Plasma 6 as Debian 13 ships it (Plasma 6.3). `patina theme set <name>`
and `patina install` run `apply.sh <theme-dir>` for the current user.

## What it produces

Files, from `templates/`, each named after the theme:

- a Plasma colour scheme, `~/.local/share/color-schemes/patina21-<theme>.colors`, with
  the theme's `base0E` as the accent and selection colour
- a Konsole colour scheme and profile under `~/.local/share/konsole/`, made the default
  profile in `konsolerc`
- kitty: `~/.config/kitty/patina21.conf` (colours and fonts), included from `kitty.conf`;
  the include line is added once, above whatever the user keeps there
- one Plasma wallpaper package per image under `~/.local/share/wallpapers/`; an SVG is
  rendered with `rsvg-convert` at 3840x2160 and only again when the theme's file is newer
- a look-and-feel package, `~/.local/share/plasma/look-and-feel/org.patina21.<theme>/`,
  whose `defaults` name the colour scheme, icons, cursors, desktop theme, decoration and
  wallpaper, so a fresh session (the image's first login) starts in the theme
- the panel layout in that package (`contents/layouts/org.kde.plasma.desktop-layout.js`)
  when `panel.layout` is `centered`: one bar at the bottom with the launcher and the
  icons-only task manager in the middle, the tray and the clock at the right, the apps
  behind `panel.pinned` pinned. Plasma runs it for a session that has no panels yet, so
  the image's first login starts with it; the first `patina install` inside a session
  applies it too (Path A finds Plasma's stock bar there). Afterwards the panels are the
  user's: only `patina theme set <name> --layout` replaces them again
- with the agents bundle: `~/.config/kitty/patina21-agent.conf`, a quieter kitty profile
  from the same palette, and `~/.local/share/applications/patina21-agent.desktop`, which
  opens the command `agent` of `defaults/settings.yaml` in it; both are removed again
  when the bundle is not installed

Settings, through `kwriteconfig6`, each written only when it differs:

- `kdeglobals`: colour scheme, accent colour, fonts from `defaults/settings.yaml`,
  look-and-feel package, widget style, icon theme; `kcminputrc` the cursor theme,
  `plasmarc` the desktop theme, `kscreenlockerrc` the wallpaper for the lock screen
- the speed settings of `defaults/settings.yaml`: `AnimationDurationFactor`, KWin's
  `LatencyPolicy`, Baloo's indexing (file names under home only, by default)
- the window defaults of `defaults/settings.yaml`: KWin's placement (`Centered`), and
  for `windows.size` a KWin rule in `kwinrulesrc` that gives every new normal window
  that share of the screen when it first appears (apps that remember their size keep
  it afterwards). The rule needs the screen, so it is written inside a session, from
  `kscreen-doctor` (the output with priority 1); outside one it waits for the next
  `patina theme set` in a session
- global shortcuts in `kglobalshortcutsrc` from `defaults/keybindings.yaml`, each action
  through `actions.yaml`: a `.desktop` file's `_launch` (kitty, KRunner, Dolphin,
  Spectacle, the default web browser from `xdg-settings`, the agent launcher) or a KWin,
  ksmserver or plasmashell action. A service that is not installed is skipped with a
  warning; Plasma's own chords that collide are unbound (`unbind` in `actions.yaml`)
- GTK 3 and 4 `settings.ini`: Breeze, the icon and cursor theme, the font, dark or light
  after the theme's `variant`; Plasma's own bridge (`kde-config-gtk-style`) syncs the
  colours from there. A Flatpak override lets apps read `kdeglobals`, so Qt apps from
  Flathub follow too

Without `kwriteconfig6` (no Plasma on the machine, the CI container before the tool is
added) only the files are written, with a warning.

## Reload

Inside a running Plasma session the renderer calls `plasma-apply-lookandfeel`,
`plasma-apply-colorscheme`, `plasma-apply-cursortheme` and `plasma-apply-wallpaperimage`,
so colours, cursor and wallpaper change at once, and asks KWin over D-Bus to reload its
settings. `--layout` adds `--resetLayout`, which replaces the user's panels with the
theme's layout. Shortcuts are read at login; the renderer says so. Outside a session (first boot, a container) everything
applies at the next login through the look-and-feel package.

Tools it calls, all from Debian's archive: `kwriteconfig6`, `kreadconfig6`
(`libkf6config-bin`, a dependency of every KDE app), `rsvg-convert` (`librsvg2-bin`, in
the base bundle), `xdg-settings`, `flatpak`, `dbus-send`, and the `plasma-apply-*` tools
and `kscreen-doctor` of `plasma-workspace` when present. Nothing is downloaded.
