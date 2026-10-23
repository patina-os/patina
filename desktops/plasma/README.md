# desktops/plasma/

Renderer for KDE Plasma 6 as Debian 13 ships it (Plasma 6.3). `patina theme set <name>`
and `patina install` run `apply.sh <theme-dir>` for the current user, after
`desktops/terminal/`, which renders kitty, the fastfetch greeting and the terminal tools
for every desktop.

## What it produces

Files, from `templates/`, each named after the theme:

- a Plasma colour scheme, `~/.local/share/color-schemes/patina-<theme>.colors`, with
  the theme's `base0E` as the accent and selection colour
- a Konsole colour scheme and profile under `~/.local/share/konsole/`, made the default
  profile in `konsolerc`
- one Plasma wallpaper package per image under `~/.local/share/wallpapers/`; an SVG is
  rendered with `rsvg-convert` at 3840x2160 and only again when the theme's file is newer
- a look-and-feel package, `~/.local/share/plasma/look-and-feel/org.patina.<theme>/`,
  whose `defaults` name the colour scheme, icons, cursors, desktop theme, decoration,
  splash and wallpaper, so a fresh session (the image's first login) starts in the
  theme; its `contents/splash/Splash.qml`, from `templates/splash.qml`, is the Plasma
  splash: the wordmark (`branding/wordmark.svg`) on the theme's background and one
  accent line that grows as Plasma starts, the one piece of code a theme renders
- the login screen: SDDM runs as its own user, so the theme's first wallpaper is written
  to `/usr/local/share/patina/login.png` and the Breeze SDDM theme's
  `theme.conf.user` (from `templates/sddm-theme.conf.user`) next to Plasma's own theme,
  both through the backend's one sudo path (`system.write`), only when they differ.
  Without sudo (no terminal, no cached credentials, not root) the login screen keeps
  what it has and the run goes on with a warning; `patina doctor` reports it.
  `defaults/system/sddm.conf.d/patina.conf` selects Breeze with the layer's font and
  cursor
- the panel layout in that package (`contents/layouts/org.kde.plasma.desktop-layout.js`)
  when `panel.layout` is `centered`: one bar at the bottom with the launcher and the
  icons-only task manager in the middle, the tray and the clock at the right, the apps
  behind `panel.pinned` pinned. Plasma runs it for a session that has no panels yet, so
  the image's first login starts with it; the first `patina install` inside a session
  applies it too (Path A finds Plasma's stock bar there). Afterwards the panels are the
  user's: only `patina theme set <name> --layout` replaces them again
- with the agents bundle: `~/.local/share/applications/patina-agent.desktop`, which
  opens the command `agent` of `defaults/settings.yaml` in the agent's kitty profile;
  removed again when the bundle is not installed
- the cheat sheet's launcher, `~/.local/share/applications/patina-keys.desktop` (from
  `templates/keys.desktop`): kitty showing `patina keys` until a key is pressed, bound
  to the `keys` action (Meta+K). The sheet lists the actions of
  `defaults/keybindings.yaml` and Plasma's own chords worth knowing, kept as words under
  `cheatsheet` in `actions.yaml`

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
  Spectacle, the default web browser from `xdg-settings`, the agent launcher, the cheat
  sheet) or a KWin,
  ksmserver or plasmashell action. A service that is not installed is skipped with a
  warning; Plasma's own chords that collide are unbound (`unbind` in `actions.yaml`)
- GTK 3 and 4 `settings.ini`: Breeze, the icon and cursor theme, the font, dark or light
  after the theme's `variant`; Plasma's own bridge (`kde-config-gtk-style`) syncs the
  colours from there. A Flatpak override lets apps read `kdeglobals`, so Qt apps from
  Flathub follow too

Without `kwriteconfig6` (no Plasma on the machine, the CI container before the tool is
added) only the files are written, with a warning.

The palette, the fonts and the metadata come into the templates through `tpl[]`, filled
by `theme_vars` in `bin/lib.sh` and applied by `render`; `iso/live/assets.sh` fills the
installer's templates from the same array, so the desktop and the installer never
disagree on a colour.

## Reload

Inside a running Plasma session the renderer calls `plasma-apply-lookandfeel`,
`plasma-apply-colorscheme`, `plasma-apply-cursortheme` and `plasma-apply-wallpaperimage`,
so colours, cursor and wallpaper change at once, and asks KWin over D-Bus to reload its
settings. `--layout` adds `--resetLayout`, which replaces the user's panels with the
theme's layout. Shortcuts are read at login; the renderer says so. Outside a session (first boot, a container) everything
applies at the next login through the look-and-feel package.

## The desktop as a picture

`screenshot.sh <out.png>` shows what the renderer produces without a machine to log in
to: a Plasma X11 session on a virtual framebuffer (`Xvfb`, Mesa's software OpenGL, no
GPU and no login), `plasmashell` in it, which runs the layout script as a first login
does, then `patina theme set` once more inside that session (the live reload and the
window rule, which needs a screen), kitty with the fastfetch greeting, and one grab of
the whole screen (`scrot`). It is the X11 session, not Wayland, because KWin's Wayland
backend needs a DRM render node a GPU-less container does not have. Run it as the user
the layer is installed for, on anything with Plasma installed; the `desktop` workflow
runs it in a Debian 13 container after `patina install`, and
`docs/screenshots/desktop-amd64.png` is its picture, copied from the workflow's artifact
unchanged. `PATINA_SHOT_SIZE` sets the screen (1920x1080 by default); the session's
output lands in `<out.png>.log`.

Tools it calls, all from Debian's archive: `kwriteconfig6`, `kreadconfig6`
(`libkf6config-bin`, a dependency of every KDE app), `rsvg-convert` (`librsvg2-bin`, in
the base bundle), `xdg-settings`, `flatpak`, `dbus-send`, and the `plasma-apply-*` tools
and `kscreen-doctor` of `plasma-workspace` when present. Nothing is downloaded.
