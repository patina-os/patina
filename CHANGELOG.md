# Changelog

All notable changes to patina are documented here. The format follows
[Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/), and the project uses
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- The command palette, the start menu and the other popups are a darker glass: 60 %
  of the window colour (near black in the dark mode, lavender white in the light one)
  instead of 40 %, so the wallpaper glows through less. The installer's sidebar
  follows, as its glass is the start menu's.
- The popups' edge is a light hairline of the text colour (`start_menu.rim`, 12 %)
  that follows the rounded corners, instead of Breeze's darker line along the sides.
- The selected row of the command palette, the start menu and the tray popups is a
  faint tint of the accent inside a thin edge (`start_menu.selection`, 10 %) instead
  of Breeze's solid-looking green; apps keep their selection colour.
- kortex 0.1.1: its icon in the command palette is a solid green summit, the survey
  point of the mark, instead of a tile with an outline and a prompt line. `patina
  update` installs it where kortex is installed.

## [0.1.0-alpha.2] - 2026-10-28

The second alpha, for testers, and still Path A only. It carries what the first run on
a Debian 13 VM found: the AI agent is opt-in, Zed and Tauon moved to an opt-in extras
bundle, the bar no longer floats, only kitty is see-through, and the start menu and the
installer are glass. The live image passed its first manual install in a VM; the images
stay in CI until the first release past the alphas.

### Added

- Credits: `patina credits` names and thanks the people and projects patina is made
  of: Debian, KDE and the apps, opencode, Ollama and Anthropic, the artists of
  aurora's wallpapers and the type designers, the platforms, and CachyOS and Omarchy,
  which inspired it. The list is data
  (`docs/credits.yaml`); the installer's last slide shows its names, Plasma's About
  this System shows patina as the variant with a pointer to the command, and the
  README has a Credits section.
- The everyday apps in the default desktop bundle: Firefox ESR as the browser, with
  telemetry, studies, Pocket and sponsored content off by policy; Tauon for music
  (Flathub), Haruna for video, Gwenview for images and Okular for PDFs, each with its
  monochrome glyph in the start menu.
- An opt-in `artcraft` bundle: the launcher of the ArtCraft suite (PhotoCraft,
  WordCraft and 11 more free, alpha counterparts of Adobe's and Microsoft's apps). You
  pick the apps in the launcher, which installs and updates them; it gets a menu
  entry. Upstream `binary` recipes may now be an AppImage.
- An AI agent as part of the install. `patina install` asks after the bundles, and
  the image's installer has a page of its own for it: opencode with a model on this
  machine (Ollama with a model you pick from those that fit the memory,
  Nemotron 3.5 Bolt E4B recommended from 16 GB and Ministral 3 3B below, Ministral 3
  8B and 14B and Qwen 3.5 offered too), with a cloud provider you pick (Mistral and
  other European providers first; the key stays in opencode's login), or none.
  `PATINA_AI`, `PATINA_AI_MODEL` and `PATINA_AI_PROVIDER` answer it for unattended
  runs, the answer is kept for the next run, and `patina doctor` shows it.
  It reads freely and asks before it changes a file, runs a command or reaches a
  server, and `defaults/agent.md` tells it how a patina desktop is changed. Meta+A
  opens it without the agents bundle now.
- The agent in the command palette: with either AI answer, `patina install` installs
  [kortex](https://github.com/patina-os/kortex) 0.1.0, so `ai` and a request in KRunner
  (Meta+Space) asks the agent, shows the answer there and every action it wants to take
  with Allow once, Always and Deny. Upstream recipes gain a `git` method for it: a
  tagged release installed by its own install script.
- `patina ai` turns the AI agent on or off after the install: `patina ai on local`
  or `on cloud` installs it (through `patina install --bundles ai-local` or
  `ai-cloud`), `patina ai off` takes Meta+A, its launcher and `ai` in the command
  palette away again and says how to remove Ollama, `patina ai` alone says which one
  this machine has.
- A `minimal` bundle, the small alternative to desktop: kitty and Firefox ESR only.
- An `extras` bundle, opt-in: the Zed editor and Tauon from Flathub.
- kitty greets every new window with fastfetch and the mark, through two lines added
  once at the end of `~/.bashrc` and a file in fish's `conf.d`.

### Changed

- The project lives at github.com/patina-os: patina, kortex and the landing page moved
  with the account's new name. Clone from `https://github.com/patina-os/patina.git`.
- With the artcraft bundle, the ArtCraft Launcher is among the start menu's
  favourites, after kitty and Zed.
- kitty keeps its text 10 points off the window's edges and its background a little
  more see-through (98% on top of the windows' own opacity); the text stays opaque.
- The command palette (KRunner, and kortex's `ai` in it) opens in the middle of the
  screen instead of at the top. `command_palette.position` in
  `defaults/settings.yaml` sets it back to `top`.
- `start_menu.style: dashboard` in `defaults/settings.yaml` opens the start menu as
  Plasma's Application Dashboard, full screen and centred, instead of the menu above
  its button (`popup`, the default). The dashboard comes with `plasma-widgets-addons`,
  now in the desktop bundle; without it the renderer keeps Kickoff. It arrives with
  `patina theme set <name> --layout`, which lays out the panel again.
- aurora's light mode has its own DeepMind wallpaper from Pexels, a white and violet
  picture of the same series as the dark one (`deepmind-light.jpg`); the light contour
  map is its second.
- The AI agent knows patina's app bundles: asked for PhotoCraft, it offers
  `patina install --bundles artcraft`, which brings the ArtCraft Launcher
  (`defaults/agent.md`).
- The AI agent is opt-in: the install's question and the installer's AI page offer no
  agent first (`ai.mode: none` in `defaults/settings.yaml`); a local model meant
  several GB of downloads nobody had asked for yet.
- Zed and Tauon left the desktop bundle for the opt-in extras bundle: their Flathub
  runtimes (the Freedesktop SDK and GNOME's platform) took over 2 GB, which filled a
  20 GB VM. The desktop bundle's one Flathub app is Element.
- The look is part of the base bundle: the fonts, the Papirus icons and the start
  menu's dashboard come with every install, whichever app bundles it takes.
- The bar sits along the bottom edge and stays there (`panel.floating: false`): a
  floating bar jumped when a window was maximised. A migration lays out the panel
  again.
- Only kitty is see-through, by its own background (95%); the KWin rule that made
  every window a little transparent is off (`windows.opacity` 100), so Firefox and
  the other apps stay opaque.
- A new window opens at the size of `windows.size` even when the app remembers being
  maximised (Firefox on a small screen); maximising it afterwards still works.
  kitty no longer remembers its own size, so it opens at that size too.
- `~/.local/bin` is on the PATH of the whole session
  (`~/.config/environment.d/60-patina.conf`), so `patina` and the tools it fetches are
  found in every terminal right after the install.
- Bundle descriptions are short enough for an 80-column terminal; lint checks it.
- The start menu is glass: where KWin blurs behind it, its background is 40% opaque
  instead of Breeze's 85% (`start_menu.glass`), and KWin's Blur and Background
  Contrast effects are turned on where they were off, so the wallpaper's colour glows
  through. Its category icons take the accent, the labels and the apps' icons the text
  colour (`start_menu.icons: accent`, or `text`). It shows the apps by their names
  alone, in compact lists, with one power button whose menu holds sleep, restart and
  log out.
- The user's picture is the small patina mark while it is Debian's swirl, set through
  AccountsService so the login screen shows it too; a picture patina set before is
  replaced.
- The installer looks like the desktop: its sidebar and the bar of Back, Next and
  Cancel are glass over the wallpaper, blurred under the sidebar, with the start
  menu's grain over the background. The mark in the sidebar has room around it, and
  the steps below it are spaced and inset. The current step is a faint green with
  green text instead of a solid green block, and the icons of the language list, the
  welcome page's links and About are green.
- The installer starts in British English; its first page still offers every other
  language.
- The README's screenshots show the new look, taken by CI: the installer's glass
  sidebar in British English, kitty as the one see-through window, and the glass start
  menu with its green category icons and the mark as the user's picture.

### Fixed

- Themes installed with `patina theme install` lived in `~/.local/share/patina/themes`,
  which is the checkout's own `themes/`: every theme was listed twice as installed,
  the install's theme question preselected amethyst instead of the default, and
  `patina theme remove` could delete one of patina's own themes. They now live in
  `~/.config/patina/themes`; the fastfetch mark and the start menu's button moved from
  the checkout to `~/.local/state/patina`. A migration moves what an earlier install
  put there.
- On a desktop that was logged into before patina, the start menu kept Plasma's
  favourites (Discover, Dolphin, System Settings, the browser): patina's only seeded
  an empty store. `--layout` (the first install, the migration) now replaces Plasma's
  defaults with patina's through the activity manager; your own stay.
- KDE's splash showed after login: applying the look-and-feel package reverted the
  splash setting. It is set again afterwards.
- One Flathub app that fails to install (no disk space, Flathub unreachable) no longer
  stops the install: the others follow, and the end says which are missing.
- The installer's sidebar was set in Qt's fallback font instead of Source Sans 3: the
  live system's fontconfig now makes the layer's fonts the standard ones.

### Removed

- amethyst, the first theme. A machine still on it moves to aurora with the next
  `patina update`.

## [0.1.0-alpha.1] - 2026-10-26

The first alpha, for testers. It covers Path A only: Debian 13 with Plasma, `git clone`
and `patina install`; the live image is built and boot-tested in CI but not handed out.
patina has run in CI containers and a headless Plasma session, not yet on a real
desktop: that run, `docs/vm-run.md`, is what testers do. "Testing the alpha" in the
README says how, and the test report form on GitHub takes the results.

### Added

- A test report form for the alpha's testers (`.github/ISSUE_TEMPLATE/`), following
  the steps of `docs/vm-run.md`.
- The aurora theme, the new default, made for OLED screens: true black, so those pixels
  stay off, with panels one step above it; neon green as the accent (selections,
  focus, the active window, the cursor, the splash line) and violet as the second
  colour (hover, glows, the end of gradients); a contour map that glows green at its
  summit and turns violet towards the edges, drawn once and kept as SVG artwork
  (CC-BY-SA-4.0). datum and amethyst stay as options.
- A light mode. `patina theme mode light` switches the current theme to its light
  palette, `patina theme mode dark` back, and the choice holds for every theme set
  later (`mode: dark` in `defaults/settings.yaml` is the default, `PATINA_MODE`
  overrides). A theme carries its other mode as data, a `light:` block with its own
  palette, wallpapers and Plasma hints; aurora has one. The boot menu, the installer,
  the splash and the login screen stay dark in either mode. `patina theme list` shows
  which themes have both.
- Themes name their accent: `accent` and `accent_alt` in `theme.yaml` point at palette
  keys (`base0E` and `base0F` when left out), so a green accent keeps green strings and
  violet keywords in the terminal and in code. A migration renders the theme already
  set once more.

- The terminal tools follow the theme. A new renderer, `desktops/terminal/`, runs for
  every desktop before the desktop's own: kitty and the fastfetch greeting move there
  from the Plasma renderer, btop gets a theme file from the palette, neovim a colour
  scheme that turns on when your configuration chose none, and bat, git-delta and fzf
  draw with the terminal's colours, which kitty takes from the theme (eza, starship,
  lazygit and atuin already did). A btop theme or neovim colour scheme you picked
  stays. `patina doctor` checks the terminal colours.
- The Hyprland add-on's contract records what Omarchy shows power users and where
  patina differs: the same theme and the same chords as on Plasma, an agent
  workspace, a `patina menu` over the system's terminal tools from Debian's archive.
  It still waits for Debian 14 (roadmap, Phase 7).

- A cheat sheet: `patina keys` lists patina's keys from `defaults/keybindings.yaml`
  (now with a `names` map in words) and Plasma's own essentials (`cheatsheet` in
  `desktops/plasma/actions.yaml`). The new `keys` action, Meta+K, opens it in kitty.
- Themes from git: `patina theme install <git-url>` fetches a theme kept in a repository
  of its own (`patina-<name>-theme`) into `~/.local/share/patina/themes/`, keeping
  only data and checking the name, the palette and every value that reaches
  configuration; `patina theme update` fetches installed themes anew, `patina theme
  remove <name>` deletes one. `patina theme list` and the install questions show them.
- The datum theme, the new default: graphite, the ice blue of contour lines and one
  coral accent (`base0E`), with a contour map around a survey point as its wallpaper,
  drawn once and kept as SVG artwork (CC-BY-SA-4.0). amethyst stays as an option.
- `docs/design/futures.html`: the eight directions of the October 2026 redesign
  (Perigee, Sodium, Phosphor, Nacre, Sirocco, Canopy, Cascade, Datum) with mockups,
  palettes, type and what each would cost to ship, kept as candidates for more themes.
- A migration for installed machines: `patina update` runs `patina install` once more,
  which installs the new fonts and renders the theme already set again.
- The image's boot test takes a screenshot of the installer screen through QEMU's
  monitor and the `iso` workflow uploads it with the serial log. The README shows the
  amd64 one from `docs/screenshots/`.
- The `desktop` workflow takes a screenshot of the finished desktop: `patina install`
  as a user in a Debian 13 container with Plasma, then `desktops/plasma/screenshot.sh`
  runs a Plasma X11 session on a virtual framebuffer (Xvfb, software OpenGL), applies
  the theme inside it, opens kitty with the fastfetch greeting and grabs the screen.
  It runs on pull requests that change the look and by hand; the README shows its amd64
  picture from `docs/screenshots/`.

- A start menu of patina's own: the patina mark as its button, AI and self-hosting
  first. Two folders, AI (the agent, Claude Desktop) and Self-hosting (Nextcloud,
  Element, Euro-Office, Thunderbird, KeePassXC), and the same apps, then kitty and Zed,
  ahead of Plasma's favourites in a grid (`start_menu` in `defaults/settings.yaml`).
  An existing bar gets the new button with `patina theme set <name> --layout`.

- One colour for every app: aurora's icon theme puts a monochrome Papirus glyph in the
  text colour in place of each app's icon (a terminal, a cloud, a key; a generic one
  for apps without a glyph of their own), in the bar, the start menu and the title
  bars (`mono` in `desktops/plasma/icons.yaml`).
- A slight grain on the start menu and the other panel popups (`start_menu.grain`, 6 %
  by default), from a small Plasma desktop theme over Breeze that replaces only the
  popup backgrounds.
- Wallpapers may be JPEG; the renderer and the image build turn them into PNG.
- The block-letter name as a picture: `branding/export/` holds `wordmark.txt` drawn as
  outlines, as SVG and PNG (512 and 1024 px), transparent and on aurora's black, so
  it looks the same where its characters or fonts are missing.

- Windows are a touch see-through: 97 % opaque while active, 92 % while not, as a
  KWin rule the renderer writes (`windows.opacity` in `defaults/settings.yaml`; 100 for
  both turns it off). A migration renders the theme again.

### Fixed

- A first login shows the theme's wallpaper: the panel layout sets it, since Plasma
  does not take it from the look-and-feel package then.
- The desktop takes the theme's colours. The renderer set the colour scheme's name but
  left copying its colours to `plasma-apply-colorscheme`, which does nothing for a name
  already set and nothing at all without a display, so title bars, the bar and KDE's
  apps stayed in Breeze's blue and light grey. The colours now go into `kdeglobals`
  key by key, and a palette change or a mode switch arrives too.
- The installer's welcome page shows the wordmark in Sora with its mark intact: it gets
  a rendering of `wordmark.svg` instead of the SVG, which Calamares drew without its
  fonts.
- The README's header shows the typeset wordmark; the block letters fell apart in the
  fonts browsers use for code.

### Changed

- The bar's icons stand equally tall: the renderer crops each app's glyph and the
  start menu's mark to what they draw and sets them at one height, so a circle, a
  cabinet and a row of dots no longer differ in size.
- The desktop screenshot shows kitty split in two, the fastfetch greeting beside btop.
- The installer's welcome page and the README's header show the name in block letters
  (`branding/export/`); the boot menu, the slides and the splash keep the typeset
  wordmark.
- aurora's wallpaper is a Google DeepMind visualisation from Pexels (`deepmind.jpg`,
  under the Pexels licence, credited in the theme's README), the one third-party
  wallpaper; the glowing contour map is the second.
- aurora's icons are Papirus (Papirus Light in the light mode), with its folders and
  the file manager's icon recoloured to the theme's accent by the renderer
  (`desktops/plasma/icons.yaml`); its monochrome icons follow the colour scheme. A
  migration installs `papirus-icon-theme` and renders the theme again.
- The README's screenshots show aurora: the installer's welcome page and the desktop,
  taken by CI, now with the DeepMind wallpaper, the one-colour icons and the
  installer's wordmark in Sora. Its header centres the wordmark and shows the status
  of the smoke and lint workflows, the licence and the Debian base as badges.
- The marks take aurora's colours: the rings deep violet, violet and lavender, the
  word white, the survey point ▲ green, in `wordmark.svg`, the icons, the terminal
  greeting and `patina help`.
- The cursor and the active tab in kitty, focus and hover in Plasma's colour scheme
  follow the theme's accent and second colour in every theme.
- The name is patina, without the 21. Everything follows: the clone at
  `~/.local/share/patina`, state in `~/.local/state/patina`, the system files, units
  and generated files named `patina-*`, the installer's branding, and the screen
  wordmark, where the coral survey point ▲ is now the one accent. Theme repositories
  are named `patina-<name>-theme`. No migration moves an existing install: reinstall,
  and remove the files still named `patina21` by hand.
- The brand is redesigned, as a mark and a name. The mark is text: a summit drawn as
  contour rings shaded with the letters of patina (i, t, n, a), the word as the summit
  line and the survey point ▲ in coral (`branding/logo.txt`, 23x9, ASCII plus that one
  character). fastfetch, the console and the first-boot screen show it, in the brand's
  colours where the terminal has them. The name is `branding/wordmark.txt`: patina in
  block letters traced from Sora with the ▲ as the dot of the i and two contour lines in
  braille, shown by `patina help`, the install questions and the README.
  `branding/wordmark.svg` sets the mark beside patina in Sora ExtraBold for screens;
  `icon.svg` is the mark as a large icon and `icon-small.svg` as dots, which replaces
  `wave.svg` as the square mark.
- The interface font is Source Sans 3 instead of Inter (`fonts-adobe-sourcesans3`), in
  Plasma, GTK, the login screen, the installer and its window manager; the wordmark
  needs Sora (`fonts-sora`). Both join the desktop bundle, the live image and the
  packages the installer adds. The bar floats by default (`panel.floating: true`).
- The smoke test finds the default theme's wallpaper by name instead of expecting
  amethyst's, and the lint check for copies of the mark leaves `docs/design/` alone.
- The roadmap is renumbered into seven phases in the order they are finished: core
  commands, theming, the branded install (TUI, first boot, image), ARM hardware, the 0.1
  release, Debian 14, the Hyprland add-on. Two open decisions are settled: the TUI helper
  is `gum`, the office suite is Euro-Office, from Nextcloud's signed apt repository until
  Flathub carries it. Every file that cites a phase number follows.
- The desktop bundle grows by kitty (Ghostty once Debian carries it), the developer
  tools fish, starship, bat, eza, fzf, ripgrep, lazygit, btop, zoxide, atuin, git-delta,
  neovim and fastfetch from Debian's archive, and Zed from Flathub. The roadmap settles
  the first theme as purple with generated artwork, and the agent tools' desktop
  integration as a shortcut, a terminal profile and Ollama as the local backend.
- The system tuning CachyOS ships as configuration (zram, I/O schedulers, memory
  sysctls, journald and systemd limits, a lean boot) is adopted as data for every
  install, and the Plasma-side speed settings become curated defaults (roadmap, Phases 1
  and 2). The base bundle names `systemd-zram-generator` and `irqbalance`.
- The logo wordmark is redrawn in a bold block letterform; the patina wave is kept and the
  tagline is dropped. Still plain 7-bit ASCII within 60 columns, so it renders on a
  serial console and in a GitHub README. `branding/logo.txt` stays the only copy; the
  README headers follow it. `patina help` prints the mark with a pink-to-purple
  gradient on an interactive terminal (24-bit colour, honouring `NO_COLOR`); the file
  itself stays colourless so `/etc/issue.d`, serial consoles and the README are clean.
- The base is Debian stable (Debian 13 today) instead of openSUSE Tumbleweed, decided
  before anything shipped: third-party installers, vendor packages and manuals assume
  apt, and Debian serves the project's top priorities at least as well. Canonical
  package names are now Debian's; `manifest/backends/apt.yaml` is the reference
  backend, `zypper.yaml` stays as untested data. README, CLAUDE.md, roadmap, branding
  and hardware notes, the logo tagline and every README follow.
- The image is a small live image built with Debian's live-build, installed by
  Calamares with patina branding; Plasma and the base bundle are fetched from Debian's
  mirrors during the install. It replaces the KIWI description, Agama profile and Open
  Build Service plan under `iso/`. Built and boot-tested by the new `iso` workflow,
  attached to a tag's GitHub release only when the boot test passed.
- CI runs the smoke test in Debian 13 containers and resolves every package the
  manifest and the image name against Debian's archive with an apt dry run.
- The Nvidia N1X row in `docs/hardware.md` and the roadmap now carries the retail name,
  RTX Spark: the laptops are on sale since October 2026, Windows only, and wait for the
  platform patches to reach Debian's kernel.

### Added

- One look from the boot menu to the desktop (roadmap, Phase 3). Every surface before
  the desktop takes its colours from the default theme's palette, rendered at build or
  apply time, never typed by hand: the live image's GRUB menu (a theme and a splash
  live-build takes over its stock files), the Calamares installer (a Qt stylesheet for
  every page down to the partition editor, the wordmark on the welcome page, the wave in
  the sidebar, the theme's wallpaper veiled behind every page, three still slides while
  it installs, an openbox theme for its dialogs), the SDDM login screen (the theme's
  first wallpaper, written to `/usr/local/share/patina/login.png` with the Breeze
  theme's override through the backend's one sudo path; Breeze with Inter and the
  theme's cursor from `defaults/system/sddm.conf.d/`), the Plasma splash (the wordmark
  and one accent line, `templates/splash.qml` in the look-and-feel package) and the
  fastfetch greeting of a new terminal (the ASCII mark in its gradient). The templates
  live under `iso/live/templates/` and `desktops/plasma/templates/`, filled by the
  theme loader and template filler now shared in `bin/lib.sh`; `iso/live/assets.sh`
  renders the image's files, and the smoke test runs it and checks them.
- The typeset wordmark, patina in Inter with the wave under it (`branding/wordmark.svg`,
  and `wave.svg` for a square icon), the mark of every screen; the ASCII mark in
  `branding/logo.txt` stays the mark of every terminal surface. Inter and JetBrains Mono
  become the layer's fonts (`defaults/settings.yaml`), from Debian's archive through the
  desktop bundle, the installer's package list and the live image.
- The `patina install` questions (roadmap, Phase 3): on a terminal, without `--bundles`
  or `--all`, the install asks the theme and the app bundles with `gum` (in the base
  bundle), shows a summary and waits for a yes, then prints a section line before each
  part while apt's and flatpak's own output stays visible. `--unattended`, the
  first-boot contract and CI take the same path as before.
- Theming (roadmap, Phase 2). `desktops/plasma/apply.sh` renders a theme and
  `defaults/` into Plasma's configuration for the user: a colour scheme with the
  theme's accent, Konsole and kitty profiles, wallpapers as Plasma wallpaper packages
  (SVG rendered at 3840x2160 with `rsvg-convert`, hence `librsvg2-bin` in the base
  bundle), a look-and-feel package so a fresh login starts in the theme, GTK and
  Flatpak consistency, the global shortcuts from `defaults/keybindings.yaml` through
  `desktops/plasma/actions.yaml`, the speed settings and fonts from
  `defaults/settings.yaml`; inside a session it applies live. `patina theme
  list|set|current` switches themes and back without leftovers; `patina install`
  applies the default theme or `PATINA_THEME=<name>`; `patina doctor` reports it.
- `themes/amethyst`: the first theme. A purple palette on a deep aubergine background
  that continues the logo's pink-to-purple gradient, and two abstract wallpapers drawn as
  SVG (`drift`, `bloom`), CC-BY-SA-4.0.
- The curated defaults: Meta plus one key for terminal, search, browser, files, close,
  overview and lock, Print for screenshots, Meta+A for the agent CLI in its own kitty
  profile (opencode by default, only with the agents bundle); half-length animations,
  KWin's lowest-latency policy, Baloo on file names under home only, and the Wayland
  session as the login screen's default (`defaults/system/sddm.conf.d/`).
- The desktop's shape as data (`defaults/settings.yaml`, `windows` and `panel`): a
  centred bar with the launcher and the task icons in the middle as on Windows 11, the
  files, browser and terminal pinned, written as the look-and-feel package's layout
  script so a fresh login starts with it; the first `patina install` inside a session
  applies it, and `patina theme set <name> --layout` brings it back later. New windows open centred, and a KWin rule gives
  every new main window 70% of the screen at its first appearance.
- The smoke test checks the rendered theme, that setting it again changes nothing, and
  that a copy of the theme pack renders and switches back cleanly.
- The core commands (roadmap, Phase 1). `patina install` installs the chosen bundles
  (`--bundles`, `--all`, `--list`; `--unattended` or `PATINA_UNATTENDED=1` for the
  first-boot contract): Debian packages through the apt backend, flatpaks per user from
  Flathub, the upstream recipes (the Go `yq` binary, npm and uv tools, install scripts,
  signed upstream apt repositories in deb822 form), the system tuning files from
  `defaults/system/` and the app settings from `defaults/apps.yaml`. It fetches `yq`
  itself, drops `sudo` when already root, runs twice without changes and records the
  install under `~/.local/state/patina/`. `patina doctor` reports the base, the tools,
  missing packages, flatpaks and upstream tools, the tuning files and pending migrations;
  `patina migrate` runs pending migrations, `patina update` pulls and then migrates.
- Euro-Office joins the desktop bundle, from Nextcloud's signed apt repository (the
  signed builds are published as Nextcloud Office, amd64 and arm64). Claude Desktop's
  recipe is verified against Anthropic's repository. Every upstream recipe names the
  command or package it leaves behind.
- `defaults/system/`: the tuning after CachyOS's configuration, as the files `patina
  install` writes under `/etc`: zram with zstd, I/O schedulers per device type, the
  memory sysctls, a journald cap, shorter stop timeouts, systemd-oomd, background THP
  defragmentation, a one-second GRUB menu, a `MODULES=dep` initramfs. The base bundle
  names `systemd-oomd`, which Debian packages apart from systemd.
- `defaults/apps.yaml`: Zed with telemetry and AI off, opencode pointed at Ollama on
  this machine.
- The smoke workflow runs `patina install` unattended, twice, then `patina doctor`, in
  the Debian 13 containers on both architectures.
- `devices/snapdragon-x-elite/`: the first ARM laptop entry (roadmap, Phase 4), data
  only and untested: the models with their device trees, the firmware packages from
  Debian's archive, and the manual validation procedure after the Debian wiki. The
  Snapdragon X2 Elite and Nvidia N1X rows in `docs/hardware.md` record why they wait.
  The smoke test now resolves the packages devices name against Debian's archive too.
- `manifest/backends/dnf.yaml` and `pacman.yaml`: Fedora and Arch backends as untested
  data next to the openSUSE one, with the name maps for today's bundles (roadmap,
  "Later").
- `desktops/hyprland/README.md`: the contract for the Hyprland add-on, and why it waits
  for Debian 14 (Debian 13 carries Hyprland only in backports).
- The roadmap's "Later" section says what a Debian 14 move touches.
- The first images: the amd64 and arm64 live images build with live-build and
  Calamares 3.3 as Debian 13 ships them and boot to the installer screen in QEMU
  (roadmap, Phase 2 and 3). The `iso` workflow builds both natively, on GitHub's x86_64
  and aarch64 runners, boot-tests both and runs on every pull request that touches the
  image. The boot test falls back to CPU emulation where a runner has no KVM.
- `devices/raspberry-pi-4/`: the first device entry (status untested, data only) with
  the manual validation procedure for Path A on a Raspberry Pi 4.
- `manifest/bundles/agents.yaml`: the agent tools as an opt-in bundle (Claude Code,
  Codex CLI, opencode, Claude Desktop, Ollama). Claude Desktop comes from Anthropic's
  own signed apt repository, the only form it ships for Linux.
- Upstream recipes for the Go `yq` (Debian packages the Python one) and `uv`.

### Removed

- The openSUSE ISO scaffold (`iso/agama/`, `iso/kiwi/`, the OBS-based `iso-test`
  workflow and the Agama install test).

- The patina logo: an ASCII wordmark in `branding/logo.txt`, shown by `patina help`,
  in the README, on the ISO console and at first boot.
- Image scaffold under `iso/` (roadmap, Phase 2): first-boot unit and script that run
  Path A, and the live image configuration. Nothing is built yet.
- Repository skeleton: `bin/`, `themes/`, `defaults/`, `desktops/`, `manifest/`,
  `migrations/`, `devices/`, `iso/`, `docs/`, each with a README that fixes its purpose
  and file format.
- `patina` entry point with `help` and `version`; every other command reports that it is
  planned.
- Project documentation: README, CLAUDE.md, roadmap, branding and hardware notes.
- CI: shellcheck and yamllint; smoke run in containers of the base on x86_64 and
  aarch64.

[Unreleased]: https://github.com/patina-os/patina/compare/v0.1.0-alpha.2...main
[0.1.0-alpha.2]: https://github.com/patina-os/patina/releases/tag/v0.1.0-alpha.2
[0.1.0-alpha.1]: https://github.com/patina-os/patina/releases/tag/v0.1.0-alpha.1
