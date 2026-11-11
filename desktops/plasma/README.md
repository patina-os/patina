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
  folder -> folder-blue), only under the names a folder has (`folder…`, `user-…`,
  `inode-directory`), since KDE shortens a name word by word in this icon theme before
  it asks the one inherited, and `network`, a link to a folder, made every network
  icon of the tray the green folder; with the icon theme's own symbolic glyphs of those folders
  beside them (a symbolic name falls back to the coloured folder in the first theme
  that has it, so the bar's show-desktop button was a green block), and a monochrome glyph under the name of every app's icon
  (`mono`: the Icon= of each installed desktop entry a menu shows, mapped to a glyph,
  `other` for the rest; names the icon theme uses for folders or file types are left
  alone; `own`: an app's own glyph from its package, the white file in the dark mode and
  the black one in the light, as Claude Desktop's spark from its tray icon, in place of
  the mapped glyph while the file is there), so the bar, the menu and the title bars are
  one colour, the colour scheme's text colour (white in the dark mode, dark in the light
  one). With
  `start_menu.icons: accent` (the default) the icon theme's symbolic category icons,
  which the start menu's categories show, take the accent: their colour and their
  `ColorScheme-Text` class become the accent; the labels keep the text colour. A
  category whose directory entry names an icon from elsewhere in the icon theme (Help:
  `help-about-symbolic`, an action) gets the category glyph `icons.yaml` names for it
  under `categories` (`system-help-symbolic`), through a copy of the entry under the
  same name in `~/.local/share/desktop-directories/`, its first line a `# patina:`
  comment; the renderer removes such a copy again when no mapping applies. Each glyph, and the start menu's mark, gets a viewBox cut to what it
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
  draws the translucent background, whose 85 % opacity becomes `start_menu.glass` (45
  by default), so the wallpaper glows through the window colour, near black in the
  dark mode. Breeze's darker 1 px rim along their edges becomes the text colour at
  `start_menu.rim` percent (12 by default; 0 keeps Breeze's), a light hairline that
  follows the rounded corners too. It also holds the highlight of Plasma's lists (`widgets/viewitem.svgz`,
  from `templates/viewitem.svg`): the selected row of the start menu, the command
  palette and the tray popups is `start_menu.selection` percent of the accent (10 by
  default; Breeze fills 30) inside a 1 px edge of four times that, a pressed row twice
  both. Apps keep the colour scheme's selection. Plasma's text fields
  (`widgets/lineedit.svgz`, from `templates/lineedit.svg`), the search fields of the
  start menu, the command palette and the tray among them, are a veil of the text
  colour at `start_menu.search` percent (3 by default; 0 keeps Breeze's solid field)
  with no edge but a thin one of the accent, five times that under the pointer and
  ten times while typing. The headings of popups (`widgets/plasmoidheading.svgz`,
  Breeze's with its opacities changed), the start menu's search row and its tabs
  among them, lay a band of the window colour at `start_menu.bands` percent over the
  glass (0 by default; Breeze: 75) and a line against the content in proportion (20 %
  at 75), so 0 leaves one pane of glass. KWin's Blur and Background
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
  theme; its `contents/previews/` hold the pictures System Settings shows for it among
  the global themes, the card (`preview.png`, 600x337) and the full screen
  (`fullscreenpreview.jpg`, 1920x1080, PNG data under the name the package format
  fixes: `rsvg-convert` writes no JPEG and Qt reads an image by its content), both the
  mode's first wallpaper with the bar along the bottom edge in the window colour and the
  mark in its centre (`templates/look-and-feel-preview.svg`); without them Plasma showed
  Breeze's, the package it falls back to; its `contents/splash/Splash.qml`, from `templates/splash.qml`, is the Plasma
  splash: the mark alone (`branding/icon.svg`, its rings without the word beside them)
  on the theme's background and one accent line that grows as Plasma starts, the one
  piece of code a theme renders; it takes the dark palette in either mode, since the
  mark is made for a dark ground
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
  two power buttons without captions (restart and shut down; the rest in a menu);
  every desktop gets the theme's wallpaper, which a first login would not take from the
  package. Plasma runs it for a session that has no panels yet, so the image's first
  login starts with it; the first `patina install` inside a session applies it too
  (Path A finds Plasma's stock bar there). Afterwards the panels are the user's: only
  `patina theme set <name> --layout` replaces them again
- the start menu's folders, from `start_menu` in `defaults/settings.yaml`: one
  directory entry each under `~/.local/share/desktop-directories/patina-<id>.directory`
  and `~/.config/menus/applications-merged/patina-start-menu.menu`, which fills them;
  a folder shows the apps of its list that are installed. The menu cache is rebuilt
  (`kbuildsycoca6`) when they change, from Plasma's menu (`XDG_MENU_PREFIX=plasma-`, as
  `startplasma` sets it, also outside a session). The favourites, the folders' apps and then
  `start_menu.favorites` as far as they are installed, go into `kicker-extra-favoritesrc`
  (`Prepend`, a `;`-list): Kickoff puts them before Plasma's own favourites in a start
  menu whose favourites store is still empty (the image's first login). On a desktop
  that was logged into before patina (Path A) the store already holds Plasma's
  defaults, so with `--layout` inside a session the renderer unlinks those (the browser,
  Kontact, System Settings, Dolphin, Discover) and links patina's through the activity
  manager's D-Bus API (`org.kde.ActivityManager.ResourcesLinking`); favourites the user
  added stay. The layout script also writes their order for the start menu it makes
  (`kactivitymanagerd-statsrc`, `Favorites-…instance-<id>-global`), since a new start
  menu keeps none and would show linked favourites in any order; Kickoff reads it when
  Plasma starts, so the order arrives with the next login. Kickoff always opens centred above its button (libplasma's
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
  them is installed. Where kortex answers for that agent (an AI bundle, kortex
  installed, `agent` is opencode or hermes) it comes from `templates/agent-panel.desktop`
  instead: kortex's `Panel`, the agent's own view of the current conversation in a
  terminal docked at the screen's right edge, full height and a fifth of the width
  (480 to 720 px), above other windows, so the user works on beside it; the kitty
  profile when kortex has no `Panel`
- with an AI bundle and kortex installed: `~/.local/share/applications/patina-ask.desktop`
  (from `templates/ask.desktop`), "Ask kortex" whichever agent kortex talks to,
  first in the start menu's AI folder and behind Meta+A (the `ask` action):
  it opens the command palette on kortex alone (kortex's `Open` through `dbus-send`),
  empty, so what is typed goes to the agent with no `ai` first, or on the conversation
  while a request runs or waits for an answer; a kortex older than that method gets
  KRunner's `querySingleRunner`, always empty. Its icon is kortex's ▲ by path, which the glyphs
  leave alone; removed again without them
- with the same bundles: `~/.config/environment.d/61-patina-askpass.conf` (from
  `templates/askpass.conf`), which sets the session's `SUDO_ASKPASS` to `askpass.sh` at
  the next login; in a running session the renderer also hands it to D-Bus and systemd
  (`dbus-update-activation-environment`), so kortex's agent, which D-Bus starts on
  demand, has it right away. The agents run commands without a terminal, so plain `sudo` cannot
  ask for a password there; they run `sudo -A` (`defaults/agent.md`), and so does
  patina's own backend path when it has no terminal (`run_words` in `bin/lib.sh`).
  `askpass.sh` asks with a notification first (notify-send, critical, so it stays until
  answered), and its "Enter password" opens kdialog, which draws in the theme's colours
  and fonts like any KDE window, with the mark as its window icon: a dialog that opened
  by itself took the keyboard on Wayland, and what the user typed elsewhere landed in its
  field. Cancel, on either, makes sudo give up; a retry after a wrong password opens the
  dialog at once. The same bundles write `/etc/sudoers.d/patina-agents`
  (`defaults/system/`), so one password covers every sudo of the session for sudo's
  timeout, not one command. Removed again with the bundles
- the cheat sheet's launcher, `~/.local/share/applications/patina-keys.desktop` (from
  `templates/keys.desktop`): kitty showing `patina keys` until a key is pressed, bound
  to the `keys` action (Meta+K). The sheet lists the actions of
  `defaults/keybindings.yaml` and Plasma's own chords worth knowing, kept as words under
  `cheatsheet` in `actions.yaml`
- the welcome's start menu entry, `~/.local/share/applications/patina-welcome.desktop`,
  and its autostart entry, `~/.config/autostart/patina-welcome.desktop`, both from
  `templates/welcome.desktop`: `patina welcome --window` and `--login`, kitty split in
  two with the welcome beside btop (`bin/patina-welcome`). Its icon is
  `patina-welcome`, a checklist glyph (`icons.yaml`), so it is not taken for the start
  button's mark in the bar; the entries are written before the glyphs. `--login` opens nothing
  once the welcome's "Don't open at login" wrote `~/.local/state/patina/welcome-off`,
  so the entry stays as it is. KDE's Welcome Center stays
  off: `autoload=false` for its daemon module (`[Module-kded_plasma-welcome]` in
  `kded5rc`, the file KDE 6 still reads), which is what starts it at a first login and
  after a Plasma upgrade
- the apps the start menu leaves out (`start_menu.hidden` in `defaults/settings.yaml`,
  KDE's Welcome Center first): a copy of each one's entry under
  `~/.local/share/applications/`, `NoDisplay=true` added and a first line that says
  so, which the user's data directory puts before the system's; the menu and its search
  skip it, and it still starts when asked. A copy no longer listed goes again

Settings, through `kwriteconfig6`, each written only when it differs from what a session
reads: the renderer puts `~/.config/kdedefaults/` first in `XDG_CONFIG_DIRS`, as
`startplasma` does, because applying the look-and-feel package moves the values it names
there, so a run over SSH or in the screenshot session finds them unchanged as well:

- `kdeglobals`: colour scheme and every colour of it (`plasma-apply-colorscheme` would
  copy them only with a display and never for a scheme whose name is already set, so
  a palette change or a mode switch would not arrive), accent colour, fonts from
  `defaults/settings.yaml`,
  look-and-feel package, widget style, icon theme, and kitty as the terminal Plasma
  opens for others (`TerminalApplication`, when a bundle brought kitty: Dolphin's "Open
  Terminal Here", kortex's "Open in terminal"); `kcminputrc` the cursor theme,
  `plasmarc` the desktop theme, `kscreenlockerrc` the wallpaper for the lock screen,
  `kcm-about-distrorc` the variant About this System shows under Debian's name (patina,
  and `patina credits` for who made it)
- the speed settings of `defaults/settings.yaml`: `AnimationDurationFactor`, KWin's
  `LatencyPolicy`, Baloo's indexing (file names under home only, by default)
- `input.touchpad_scrolling` of `defaults/settings.yaml`: KWin's default for every
  touchpad, `NaturalScroll` under `[Libinput][Defaults][Touchpad]` in `kcminputrc`
  (natural scrolling by default; libinput turns both directions together). A touchpad
  changed in System Settings gets an entry of its own there, which wins. Inside a
  session KWin is told at once (`KGlobalSettings.notifyChange`, the mouse settings).
  Only the Wayland session reads it: on X11 Plasma keeps a setting per touchpad
  (`touchpadxlibinputrc`) and has no default for all of them
- the window defaults of `defaults/settings.yaml`: KWin's placement (`Centered`), and
  for `windows.size` a KWin rule in `kwinrulesrc` that gives every new normal window
  that share of the screen, not maximised, when it first appears (an app that
  remembers a maximised window opens at the size too; the user may maximise it later). The rule needs the screen, so it is written inside a session, from
  `kscreen-doctor` (the output with priority 1); outside one it waits for the next
  `patina theme set` in a session. Two rules ahead of it leave a window's size alone:
  `patina-kdialog` kdialog's windows (the AI agent's sudo password, the welcome's file
  picker), which Wayland counts as normal windows since no window of their app is
  behind them, and opens them above other windows without taking the keyboard;
  `patina-welcome` the welcome's window (class `patina-welcome`) at the size it asks
  kitty for, in characters, so btop has its 80 columns beside the welcome; neither
  needs a screen. Both name a size (`1,1`) their "Do not affect" never applies, since
  KWin reads a size rule without one as unused and deletes a rule left with nothing to
  do. For
  `windows.opacity` below 100 a second rule that
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
  ksmserver or plasmashell action. Plasma's own chord for the action (an app's
  `X-KDE-Shortcuts`, an action's `default`) keeps working beside patina's: Alt+F4
  still closes a window, Alt+Space still opens KRunner, Meta+W the overview. A service
  that is not installed is skipped with a warning; Plasma's own chords that collide
  are unbound (`unbind` in `actions.yaml`)
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

Inside a running Plasma session, after a run that changed something, the renderer
calls `plasma-apply-lookandfeel` and `plasma-apply-cursortheme`, tells the running apps
over D-Bus that the palette changed (`KGlobalSettings.notifyChange`), so colours and
cursor change at once, and asks KWin over D-Bus to reload its settings; a run that
changes nothing leaves the session alone, so what the user changed since stays. The
wallpaper (`plasma-apply-wallpaperimage`) is put on the desktop when the theme or the
mode brings another one than the one patina put there last
(`~/.local/state/patina/wallpaper`), so `patina update` keeps a wallpaper the user
picked. `--layout` adds `--resetLayout`, which replaces the user's panels with the
theme's layout. Shortcuts are read at login; the renderer says so. Outside a session (first boot, a container) everything
applies at the next login through the look-and-feel package.

## The desktop as pictures

`screenshot.sh <dir>` shows what the renderer produces without a machine to log in to:
a Plasma X11 session on a virtual framebuffer (`Xvfb`, Mesa's software OpenGL, no GPU
and no login), `plasmashell` in it, which runs the layout script as a first login
does, then `patina theme set --layout` once more inside that session, as the first
install runs it (the live reload, the window rule, which needs a screen, and patina's
favourites in place of Plasma's), with patina's welcome turned off for it and KDE's
Welcome Center closed should a Plasma open it after all, and the pointer moved
from the middle of the screen, where Xvfb leaves it, to the empty desktop on the right
(`xdotool`), so no tooltip or hover is in the pictures. Then up to four grabs of
the whole screen (`scrot`): `desktop.png`, kitty split in two with the fastfetch
greeting and btop; `welcome.png`, patina's welcome beside btop as a first login opens
it (`patina welcome --login`, turned on for that grab alone); when `PATINA_SHOT_ASK` holds a request and an AI bundle installed
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
