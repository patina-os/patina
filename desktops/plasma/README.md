# desktops/plasma/

Renderer for KDE Plasma 6 as Debian 13 ships it (Plasma 6.3). `patina theme set <name>`
and `patina install` run `apply.sh <theme-dir>` for the current user, after
`desktops/terminal/`, which renders kitty, the fastfetch greeting and the terminal tools
for every desktop. Both render the palette of the mode in use, dark or light
(`patina theme mode`, `current_mode` in `bin/lib.sh`), for a theme that has both.

## What it produces

Files, from `templates/`, each named after the theme:

- a Plasma colour scheme, `~/.local/share/color-schemes/patina-<theme>.colors`, with
  the theme's accent (`accent`, `base0E` by default) as the accent, selection and
  focus colour and its second colour (`accent_alt`) for hover. Its colours are also
  copied key by key into `kdeglobals` (below), where Plasma, KWin's title bars and
  every KDE app read them
- for an icon theme named in `icons.yaml` (Papirus, aurora's), an icon theme of its
  own, `~/.local/share/icons/patina-<theme>/`: it inherits that icon theme and holds
  only its folder icons, recoloured to the accent (the accent, 80 % and 35 % of it in
  place of the icon theme's blues, following link chains such as inode-directory ->
  folder -> folder-blue), and a monochrome glyph under the name of every app's icon
  (`mono`: the Icon= of each installed desktop entry a menu shows, mapped to a glyph,
  `other` for the rest; names the icon theme uses for folders or file types are left
  alone), so the bar, the menu and the title bars are one colour, the colour scheme's
  text colour (white in the dark mode, dark in the light one). With
  `start_menu.icons: accent` (the default) the icon theme's symbolic category icons,
  which the start menu's categories show, take the accent: their colour and their
  `ColorScheme-Text` class become the accent; the labels keep the text colour. Each glyph, and the start menu's mark, gets a viewBox cut to what it
  draws, 7/8 of the icon high and centred (the extent from the bounding box of an EPS
  `rsvg-convert` writes), so they stand equally tall in the bar. An app installed later gets its glyph at the next `patina theme set`.
  The session uses this icon theme. Without the icon theme installed the renderer
  falls back to Breeze and says so
- over the default desktop theme, a Plasma desktop theme of the theme's own,
  `~/.local/share/plasma/desktoptheme/patina-<theme>/`, with Breeze's `plasmarc`; every
  element it does not hold comes from Breeze. It holds Breeze's four popup backgrounds
  (`dialogs/background.svgz` and its translucent, opaque and solid forms), with
  `start_menu.grain` above 0 a 32 px noise tile in the text colour
  (`templates/grain.svg`, rendered to PNG and embedded) laid at that opacity into their
  centre tile, which Plasma repeats. Plasma draws all panel popups and the command
  palette from that background, so the start menu, KRunner, the calendar and the tray
  share the grain. Where KWin's Background Contrast effect blurs behind a popup, Plasma
  draws the translucent background, whose 85 % opacity becomes `start_menu.glass` (60
  by default), so the wallpaper glows through the window colour, near black in the
  dark mode. Breeze's darker 1 px rim along their edges becomes the text colour at
  `start_menu.rim` percent (12 by default; 0 keeps Breeze's), a light hairline that
  follows the rounded corners too. It also holds the highlight of Plasma's lists (`widgets/viewitem.svgz`,
  from `templates/viewitem.svg`): the selected row of the start menu, the command
  palette and the tray popups is `start_menu.selection` percent of the accent (10 by
  default; Breeze fills 30) inside a 1 px edge of four times that, a pressed row twice
  both. Apps keep the colour scheme's selection. KWin's Blur and Background
  Contrast effects (`kwinrc`, `[Plugins]`) are turned on, Plasma's defaults, for a
  desktop where they were off
- a Konsole colour scheme and profile under `~/.local/share/konsole/`, made the default
  profile in `konsolerc`
- one Plasma wallpaper package per image under `~/.local/share/wallpapers/`; an SVG or a
  JPEG is rendered to PNG with `rsvg-convert` at 3840x2160 (a JPEG through an SVG that
  embeds it) and only again when the theme's file is newer;
  in the theme's other mode that mode's wallpapers come first and the theme's own follow
- a look-and-feel package, `~/.local/share/plasma/look-and-feel/org.patina.<theme>/`,
  whose `defaults` name the colour scheme, icons, cursors, desktop theme, decoration,
  splash and wallpaper, so a fresh session (the image's first login) starts in the
  theme; its `contents/splash/Splash.qml`, from `templates/splash.qml`, is the Plasma
  splash: the wordmark (`branding/wordmark.svg`) on the theme's background and one
  accent line that grows as Plasma starts, the one piece of code a theme renders; it
  takes the dark palette in either mode, since the wordmark is made for a dark ground
- the login screen: SDDM runs as its own user, so the theme's first wallpaper is written
  to `/usr/local/share/patina/login.png` and the Breeze SDDM theme's
  `theme.conf.user` (from `templates/sddm-theme.conf.user`) next to Plasma's own theme,
  both through the backend's one sudo path (`system.write`), only when they differ.
  Without sudo (no terminal, no cached credentials, not root) the login screen keeps
  what it has and the run goes on with a warning; `patina doctor` reports it.
  `defaults/system/sddm.conf.d/patina.conf` selects Breeze with the layer's font and
  cursor
- the panel layout in that package (`contents/layouts/org.kde.plasma.desktop-layout.js`)
  when `panel.layout` is `centered` or `grouped`: one bar at the bottom with the start
  button alone in the middle, the icons-only task manager at the left end (`grouped`:
  the start button and the task manager together in the middle, as on Windows 11), the
  tray and the clock at the right, the apps behind `panel.pinned` pinned. The start
  menu (Kickoff, a menu above its button; the
  Application Dashboard, full screen and centred, for `start_menu.style: dashboard`
  when `plasma-widgets-addons` is installed)
  gets the patina mark as its button (`branding/icon-small.svg`, copied to
  `~/.local/state/patina/launcher.svg` so it stays when the theme changes), and in
  Kickoff its favourites as a grid, the apps by their names alone, compact lists and
  one power button without a caption (shut down; the rest in its menu);
  every desktop gets the theme's wallpaper, which a first login would not take from the
  package. Plasma runs it for a session that has no panels yet, so the image's first
  login starts with it; the first `patina install` inside a session applies it too
  (Path A finds Plasma's stock bar there). Afterwards the panels are the user's: only
  `patina theme set <name> --layout` replaces them again
- the start menu's folders, from `start_menu` in `defaults/settings.yaml`: one
  directory entry each under `~/.local/share/desktop-directories/patina-<id>.directory`
  and `~/.config/menus/applications-merged/patina-start-menu.menu`, which fills them;
  a folder shows the apps of its list that are installed. The menu cache is rebuilt
  (`kbuildsycoca6`) when they change. The favourites, the folders' apps and then
  `start_menu.favorites` as far as they are installed, go into `kicker-extra-favoritesrc`
  (`Prepend`, a `;`-list): Kickoff puts them before Plasma's own favourites in a start
  menu whose favourites store is still empty (the image's first login). On a desktop
  that was logged into before patina (Path A) the store already holds Plasma's
  defaults, so with `--layout` inside a session the renderer unlinks those (the browser,
  Kontact, System Settings, Dolphin, Discover) and links patina's through the activity
  manager's D-Bus API (`org.kde.ActivityManager.ResourcesLinking`); favourites the user
  added stay. Kickoff always opens centred above its button (libplasma's
  `PopupPlasmaWindow` anchors every panel popup to its applet), and Plasma centres on
  the screen whatever sits between a bar's two expanding spacers (`panelspacer`'s
  `optimalSize`), so `centered` puts the button alone between them and the menu opens
  in the middle of the screen's width, on X11 and Wayland alike. With `grouped` it sits
  left of the centre by half the width of the icons beside the button, 26 px more for
  every app that opens. No KWin rule can move it: its window has no title and the
  same class and type (`_KDE_NET_WM_WINDOW_TYPE_APPLET_POPUP`) as the calendar's and
  the tray's, as the desktop workflow's session showed
- with `panel.layout: grouped` and `start_menu.position: center`, a KWin script of
  patina's own, `~/.local/share/kwin/scripts/patina-start-menu/` (from
  `templates/start-menu.js` and `templates/kwin-script-metadata.json`), turned on in
  `kwinrc` (`[Plugins] patina-start-menuEnabled`): it moves the start menu to the
  middle of the screen's width once Plasma has placed it over its button, and again
  when Plasma places it anew (a resize). Name and class cannot tell the start menu from
  the bar's other popups, so it takes the panel popup that opens in the left three
  quarters of the screen; the tray's and the clock's open at its right end. Any other
  value, or the centered bar, which centres the button itself, removes it and turns it
  off. KWin loads and unloads it when it reloads its settings; a new version of it runs
  from the next login
- with an AI bundle (`ai-local`, `ai-cloud`, `hermes-local`, `hermes-cloud`) or the
  agents bundle:
  `~/.local/share/applications/patina-agent.desktop`, which opens the command `agent`
  of `defaults/settings.yaml` in the agent's kitty profile; removed again when none of
  them is installed
- with the same bundles: `~/.config/environment.d/61-patina-askpass.conf` (from
  `templates/askpass.conf`), which sets the session's `SUDO_ASKPASS` to `askpass.sh` at
  the next login; in a running session the renderer also hands it to D-Bus and systemd
  (`dbus-update-activation-environment`), so kortex's agent, which D-Bus starts on
  demand, has it right away. The agents run commands without a terminal, so plain `sudo` cannot
  ask for a password there; they run `sudo -A` (`defaults/agent.md`), and so does
  patina's own backend path when it has no terminal (`run_words` in `bin/lib.sh`).
  `askpass.sh` asks with kdialog, which draws in the theme's colours and fonts like any
  KDE window, with the mark as its window icon; Cancel makes sudo give up. Removed again
  with the bundles
- the cheat sheet's launcher, `~/.local/share/applications/patina-keys.desktop` (from
  `templates/keys.desktop`): kitty showing `patina keys` until a key is pressed, bound
  to the `keys` action (Meta+K). The sheet lists the actions of
  `defaults/keybindings.yaml` and Plasma's own chords worth knowing, kept as words under
  `cheatsheet` in `actions.yaml`

Settings, through `kwriteconfig6`, each written only when it differs:

- `kdeglobals`: colour scheme and every colour of it (`plasma-apply-colorscheme` would
  copy them only with a display and never for a scheme whose name is already set, so
  a palette change or a mode switch would not arrive), accent colour, fonts from
  `defaults/settings.yaml`,
  look-and-feel package, widget style, icon theme; `kcminputrc` the cursor theme,
  `plasmarc` the desktop theme, `kscreenlockerrc` the wallpaper for the lock screen,
  `kcm-about-distrorc` the variant About this System shows under Debian's name (patina,
  and `patina credits` for who made it)
- the speed settings of `defaults/settings.yaml`: `AnimationDurationFactor`, KWin's
  `LatencyPolicy`, Baloo's indexing (file names under home only, by default)
- the window defaults of `defaults/settings.yaml`: KWin's placement (`Centered`), and
  for `windows.size` a KWin rule in `kwinrulesrc` that gives every new normal window
  that share of the screen, not maximised, when it first appears (an app that
  remembers a maximised window opens at the size too; the user may maximise it later). The rule needs the screen, so it is written inside a session, from
  `kscreen-doctor` (the output with priority 1); outside one it waits for the next
  `patina theme set` in a session; for `windows.opacity` below 100 a second rule that
  forces every normal window to that opacity, one share while active and one while not
  (100 by default: only kitty is see-through, by its own background)
- `ksplashrc` the theme's splash, written again after `plasma-apply-lookandfeel`, which
  reverts the user's splash key and so left KDE's splash after login
- the user's picture, only while it is Debian's (`/etc/skel/.face`), none, or the one
  patina set before (the system's copy equals ours): `branding/icon-small.svg`, the
  dots that still read at the menu's size, inset on the theme's background, rendered
  to `~/.local/state/patina/avatar.png` and set through AccountsService's
  `SetIconFile`, as System Settings does, so the start menu and the login screen both
  show it
- the command palette's position of `defaults/settings.yaml`: KRunner's `FreeFloating`
  in `krunnerrc`, true for `center` (the middle of the screen), false for `top`
- global shortcuts in `kglobalshortcutsrc` from `defaults/keybindings.yaml`, each action
  through `actions.yaml`: a `.desktop` file's `_launch` (kitty, KRunner, Dolphin,
  Spectacle, the default web browser from `xdg-settings`, the agent launcher, the cheat
  sheet) or a KWin,
  ksmserver or plasmashell action. A service that is not installed is skipped with a
  warning; Plasma's own chords that collide are unbound (`unbind` in `actions.yaml`)
- GTK 3 and 4 `settings.ini`: Breeze, the icon and cursor theme, the font, dark or light
  after the mode in use (`patina theme mode`); Plasma's own bridge (`kde-config-gtk-style`) syncs the
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
`plasma-apply-cursortheme` and `plasma-apply-wallpaperimage`, tells the running apps
over D-Bus that the palette changed (`KGlobalSettings.notifyChange`), so colours,
cursor and wallpaper change at once, and asks KWin over D-Bus to reload its settings. `--layout` adds `--resetLayout`, which replaces the user's panels with the
theme's layout. Shortcuts are read at login; the renderer says so. Outside a session (first boot, a container) everything
applies at the next login through the look-and-feel package.

## The desktop as pictures

`screenshot.sh <dir>` shows what the renderer produces without a machine to log in to:
a Plasma X11 session on a virtual framebuffer (`Xvfb`, Mesa's software OpenGL, no GPU
and no login), `plasmashell` in it, which runs the layout script as a first login
does, then `patina theme set --layout` once more inside that session, as the first
install runs it (the live reload, the window rule, which needs a screen, and patina's
favourites in place of Plasma's) and the Welcome Center closed. Then three grabs of
the whole screen (`scrot`): `desktop.png`, kitty split in two with the fastfetch
greeting and btop; when `PATINA_SHOT_ASK` holds a request and an AI bundle installed
kortex, `command-palette.png` on the empty desktop: what Enter on kortex's "Ask the
agent" does (its `Run` over D-Bus), KRunner opened by kortex on the conversation,
grabbed once the agent asks for an action (Allow once, Always, Deny); and
`start-menu.png`, the start menu opened as Meta opens it (`activateLauncherMenu` over
D-Bus) after `patina theme mode light`, the mode the desktop had set again afterwards.
It is the X11 session, not Wayland, because KWin's Wayland backend needs a DRM render
node a GPU-less container does not have. Run it as the user the layer is installed
for, on anything with Plasma installed; the `desktop` workflow runs it in a Debian 13
container after `patina install` with the cloud agent, opencode pointed at kortex's
scripted demo model and `PATINA_SHOT_ASK` set to `install photocraft`, and
`docs/screenshots/` keeps its pictures, copied from the workflow's artifact unchanged
(`desktop-amd64.png`, `start-menu-amd64.png`, `command-palette-amd64.png`).
`PATINA_SHOT_SIZE` sets the screen (1920x1080 by default); the session's output lands
in `<dir>/session.log`.

Tools it calls, all from Debian's archive: `kwriteconfig6`, `kreadconfig6`
(`libkf6config-bin`, a dependency of every KDE app), `rsvg-convert` (`librsvg2-bin`, in
the base bundle), `xdg-settings`, `flatpak`, `dbus-send`, and the `plasma-apply-*` tools
and `kscreen-doctor` of `plasma-workspace` when present. Nothing is downloaded.
