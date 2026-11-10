# defaults/

Curated defaults as desktop-agnostic data. Nothing here is specific to Plasma; the
renderers under `desktops/` translate it. Users keep their own overrides outside the
repository (planned: `~/.config/patina/`), so `git pull` never clobbers them.

- `keybindings.yaml`: named actions mapped to key chords, and under `names` what each
  does in words. A desktop renderer knows how to bind each action (which command to
  launch, which window-manager function to call); `patina keys` and Meta+K show the
  names as the cheat sheet.
- `settings.yaml`: the small set of knobs `patina install` applies when the user does not
  choose otherwise: default theme, its mode (dark or light; `patina theme mode` keeps
  the user's choice in the state directory) and desktop, Flatpak remote, fonts, the command the
  `agent` action opens, the speed settings (animation factor, compositor latency,
  file indexing), how a touchpad scrolls (natural, as on a phone, or traditional, as a
  mouse wheel), and the window and panel defaults (where a new window opens and how
  big, the bar: the start button alone in its centre or leading the task icons there,
  or the desktop's own, and which actions' apps are pinned to it), where
  the command palette opens (the middle of the screen or the top), the start menu (a
  menu above its button, or moved to the middle of the screen's width for the grouped
  bar, or a full-screen dashboard, its folders, AI and self-hosting,
  its favourites as desktop entries, and the grain, glass, rim, selection, search field
  and bands on it and the
  other popups), all as
  desktop-agnostic words the renderer translates. Under `ai`, the AI agent: the agent and the answer preselected and taken unattended
  (`agent`: opencode or hermes; `mode`: local, cloud or none), the Ollama models offered, in order, each with the
  memory it needs and its name in the question (the first that fits is recommended,
  and taken when unattended) and `small: true` under 14B parameters, which shows
  `small_hint` beside it and has the install and `patina ai` say `small_note`; and the
  cloud providers in the order `patina ai login` offers them, each with opencode's
  `provider/model`, how it logs in (`login`: key, none, or endpoint for your own API),
  the `note` said once it is picked (a US service's), and, for the ones Hermes offers,
  its `hermes` entry: the key's name in Hermes' `.env` and Hermes' `model` entry.
- `apps.yaml`: settings `patina install` merges into applications' own configuration
  files (Zed with telemetry and AI off, opencode pointed at Ollama and asking before
  every change), each with the file it owns and the bundle item that must be installed
  for it to apply.
- `services.yaml`: the services the AI agent can work with as MCP servers, presets off
  until `patina ai connect <name>` turns one on: per service a line for the list, how
  it signs in (`browser`, the agent's own OAuth sign-in, or `token`, asked for on a
  terminal and kept in `~/.config/patina/services/<name>.token`, mode 0600), the
  values the terminal asks for (`ask`), opencode's entry for it (`mcp.<name>`) and
  Hermes' (`mcp_servers.<name>`), written for the agents installed, where
  `${TOKEN_FILE}` and `${<KEY>}` are filled in. opencode's entry names the token file
  (`{file:...}`), Hermes' a line of its own `~/.hermes/.env` (`${PATINA_<NAME>_TOKEN}`),
  so no token is in a configuration; `patina doctor` reports a token file that is
  gone, which would stop opencode from starting. `reads` lists the service's tools
  that only read, as patterns on the tool's name: opencode runs them without asking
  and asks before every other tool of the service (`permission."<name>_*"`, written
  by `patina ai connect` and `patina install` for every server under `mcp`). Hermes
  gets the same through its `pre_tool_call` hook, `patina ai gate`, which reads `reads`
  at each call.
- `agent.md`: the AI agent's standing instruction, in the agent's own language: what
  machine it runs on, how a patina desktop is changed (patina's commands, then
  `kwriteconfig6`, apt and Flathub), and that it explains and asks before a change. The
  AI step of `patina install` names it in opencode's `instructions`, and writes it into
  Hermes' `agent.environment_hint`, so the user's own `SOUL.md` stays theirs; the agent
  reads it, no script does.
- `system/`: the system tuning every install gets, copied from what CachyOS ships as
  configuration: sysctl, udev rules, systemd drop-ins, tmpfiles, initramfs and GRUB
  settings, plus the login screen's static settings (`sddm.conf.d/`: the Wayland session
  as the default, the Breeze theme with the layer's cursor and font; the font name is the
  one copy of `fonts.ui` outside `settings.yaml`, because the file under `/etc` is
  static, and the lint workflow checks that the two agree; the wallpaper comes from the
  desktop renderer), and Firefox's policies (`firefox/policies/policies.json`: no
  telemetry, studies, Pocket or sponsored content; the user may change the rest) and
  Thunderbird's (`thunderbird/policies/policies.json`). Both start with KWin's title
  bar, as every other window has, in place of the tabs in the title bar with buttons
  of their own in GNOME's style; the user may turn it back (Firefox: Customize
  Toolbar, Title Bar; Thunderbird: Settings, General, Hide system window titlebar). Each
  file is named by its destination under `/etc`
  (`system/sysctl.d/x.conf` lands at `/etc/sysctl.d/x.conf`), and the backend's sudo
  path (`system.write` in `manifest/backends/`) is the only thing that writes them.
  The boot splash's setting is among them (`plymouth/plymouthd.conf` picks the patina
  theme, `default/grub.d/patina.cfg` puts `quiet splash` on the kernel's line once, and
  `systemd/system/sddm.service.d/` starts SDDM once the splash has quit), and the boot
  menu's: `default/grub.d/patina.cfg` also picks its theme once it is drawn, with its
  ground behind the kernel's first lines, and names the entry "patina / Debian 13"
  (GRUB adds GNU/Linux) for grub-mkconfig only. grub-install and Debian's grub-efi
  packages read the same file and take the name's first word as the system's folder on
  the EFI partition, so for them it leaves the name as `/etc/default/grub` has it
  (Debian GNU/Linux): Debian's signed GRUB reads its configuration from `EFI/debian`,
  and the updates of GRUB and shim go where that word says. The file tells its readers
  apart by `$0`, the name of the program reading it. It also turns os-prober on, which
  Debian leaves off, so on a disk shared with other systems the menu lists them, and
  keeps the menu five seconds in place of one when os-prober finds any; it runs
  os-prober only when grub-mkconfig writes the menu.
- `boot/`: the boot splash, Plymouth's two-step theme as templates: `frame.svg`, one
  picture of the mark, into which `render_boot_splash` (`bin/lib.sh`) sets the
  characters of `branding/logo.txt` in the brand's colours, each as far faded in as
  the boot has got; `patina.plymouth`, the theme file, with the default theme's dark
  background and the watermark placed past the screen's edge, since Debian's initramfs
  hook puts its own logo into every two-step theme as one; `entry.svg`, `bullet.svg` and `lock.svg`, the disk password prompt
  two-step needs to load at all. The function draws 48 `progress-*.png`, which
  Plymouth picks by the boot's progress over its first 22 % (`ShowAnimationPercent`,
  the first 13 seconds on a machine Plymouth has no timing of yet: the rings arrive,
  the outer ones first), and
  36 `animation-*.png`, played once at the end (the word, then the ▲); the counts stay
  fixed, since Plymouth takes every `progress-*.png` it finds. `patina install` writes
  them to `/usr/share/plymouth/themes/patina` through the same sudo path, only when a
  checksum of what they are drawn from changed, and the image build into the live
  system.
- `boot/grub/`: the boot menu, a GRUB theme, as templates: `theme.txt` (the centred
  menu column, the help line, the timeout's accent line, and GRUB's terminal over the
  whole screen) and `background.svg` (the default theme's first wallpaper under a veil,
  patina in block letters above the menu). `render_boot_menu` (`bin/lib.sh`) fills
  them and draws `background.png`, `ground.png` (the default theme's background, behind
  the lines GRUB prints while an entry boots, instead of Debian's picture) and
  `font.pf2`, `fonts.monospace` converted by grub-mkfont (grub-common): GRUB reads no
  other font format and does not scale fonts, so each menu takes the size of its
  screen, 20 pixels on an installed system at the screen's own resolution and 24 on
  the live image at 1920x1080, which its `theme.cfg` sets in place of live-build's
  800x600. `select.svg` is the selected entry's bar, a faint accent with a fine outline
  and round corners, which the renderer cuts into GRUB's nine pieces
  (`select_*.png`, with clear `item_*.png` of the same sizes for the other entries, so
  all stand alike). `patina install` writes them to
  `/boot/grub/themes/patina` through the same sudo path, only when a checksum of what
  they are drawn from changed and only where GRUB is; `iso/live/assets.sh` draws the
  live image's menu and an installed system's into the image.
  These files keep the names and formats their tools require, so they are, with
  `agent.md`, the only data here that is not YAML; `patina doctor` reports any that is
  missing or differs.

Rules: no commands (`agent.md` names commands for the agent to run, never for a script),
no architecture names, no filesystem paths except the destinations
the `system/` files are named by and the `file` an app owns in `apps.yaml`. If a default
only makes sense on one desktop, it belongs in that desktop's directory, not here.
