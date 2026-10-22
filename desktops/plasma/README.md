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
  whose `defaults` name the colour scheme, icons, cursors, desktop theme, decoration,
  splash and wallpaper, so a fresh session (the image's first login) starts in the
  theme; its `contents/splash/Splash.qml`, from `templates/splash.qml`, is the Plasma
  splash: the wordmark (`branding/wordmark.svg`) on the theme's background and one
  accent line that grows as Plasma starts, the one piece of code a theme renders
- the login screen: SDDM runs as its own user, so the theme's first wallpaper is written
  to `/usr/local/share/patina21/login.png` and the Breeze SDDM theme's
  `theme.conf.user` (from `templates/sddm-theme.conf.user`) next to Plasma's own theme,
  both through the backend's one sudo path (`system.write`), only when they differ.
  Without sudo (no terminal, no cached credentials, not root) the login screen keeps
  what it has and the run goes on with a warning; `patina doctor` reports it.
  `defaults/system/sddm.conf.d/patina21.conf` selects Breeze with the layer's font and
  cursor
- the fastfetch greeting: `~/.local/share/patina21/logo.txt`, the ASCII mark with its
  gradient (`print_logo always`), and `~/.config/fastfetch/config.jsonc` pointing at it
  with the theme's accent for the labels, rewritten only while its first line is ours
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

The palette, the fonts and the metadata come into the templates through `tpl[]`, filled
by `theme_vars` in `bin/lib.sh` and applied by `render`; `iso/live/assets.sh` fills the
installer's templates from the same array, so the desktop and the installer never
disagree on a colour.

## Reload

Inside a running Plasma session the renderer calls `plasma-apply-lookandfeel`,
`plasma-apply-colorscheme`, `plasma-apply-cursortheme` and `plasma-apply-wallpaperimage`,
so colours, cursor and wallpaper change at once. Shortcuts and KWin settings are read at
login; the renderer says so. Outside a session (first boot, a container) everything
applies at the next login through the look-and-feel package.

Tools it calls, all from Debian's archive: `kwriteconfig6`, `kreadconfig6`
(`libkf6config-bin`, a dependency of every KDE app), `rsvg-convert` (`librsvg2-bin`, in
the base bundle), `xdg-settings`, `flatpak`, and the `plasma-apply-*` tools of
`plasma-workspace` when present. Nothing is downloaded.
