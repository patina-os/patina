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
  file indexing), and the window and panel defaults (where a new window opens and how
  big, the bar: the start button alone in its centre or leading the task icons there,
  or the desktop's own, and which actions' apps are pinned to it), where
  the command palette opens (the middle of the screen or the top), the start menu (a
  menu above its button or a full-screen dashboard, its folders, AI and self-hosting,
  its favourites as desktop entries, and the grain, glass, rim and selection on it and the
  other popups), all as
  desktop-agnostic words the renderer translates. Under `ai`, the AI agent: the agent and the answer preselected and taken unattended
  (`agent`: opencode or hermes; `mode`: local, cloud or none), the Ollama models offered, in order, each with the
  memory it needs and its name in the question (the first that fits is recommended,
  and taken when unattended) and the cloud providers in the order they are offered, each with
  opencode's `provider/model` where patina picks one, and, for the ones Hermes offers,
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
  gone, which would stop opencode from starting.
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
  telemetry, studies, Pocket or sponsored content; the user may change the rest). Each
  file is named by its destination under `/etc`
  (`system/sysctl.d/x.conf` lands at `/etc/sysctl.d/x.conf`), and the backend's sudo
  path (`system.write` in `manifest/backends/`) is the only thing that writes them.
  These files keep the names and formats their tools require, so they are, with
  `agent.md`, the only data here that is not YAML; `patina doctor` reports any that is
  missing or differs.

Rules: no commands (`agent.md` names commands for the agent to run, never for a script),
no architecture names, no filesystem paths except the destinations
the `system/` files are named by and the `file` an app owns in `apps.yaml`. If a default
only makes sense on one desktop, it belongs in that desktop's directory, not here.
