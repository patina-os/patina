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
  big, a centred or the desktop's own bar, which actions' apps are pinned to it), the
  start menu (its folders, AI and self-hosting, its favourites as desktop entries,
  and the grain on it and the other popups), all as desktop-agnostic words the renderer translates.
- `apps.yaml`: settings `patina install` merges into applications' own configuration
  files (Zed with telemetry and AI off, opencode pointed at Ollama), each with the file
  it owns and the bundle item that must be installed for it to apply.
- `system/`: the system tuning every install gets, copied from what CachyOS ships as
  configuration: sysctl, udev rules, systemd drop-ins, tmpfiles, initramfs and GRUB
  settings, plus the login screen's static settings (`sddm.conf.d/`: the Wayland session
  as the default, the Breeze theme with the layer's cursor and font; the font name is the
  one copy of `fonts.ui` outside `settings.yaml`, because the file under `/etc` is
  static, and the lint workflow checks that the two agree; the wallpaper comes from the
  desktop renderer). Each file is named by its destination under `/etc`
  (`system/sysctl.d/x.conf` lands at `/etc/sysctl.d/x.conf`), and the backend's sudo
  path (`system.write` in `manifest/backends/`) is the only thing that writes them.
  These files keep the names and formats their tools require, so they are the one place
  in the repository that is neither YAML nor bash; `patina doctor` reports any that is
  missing or differs.

Rules: no commands, no architecture names, no filesystem paths except the destinations
the `system/` files are named by and the `file` an app owns in `apps.yaml`. If a default
only makes sense on one desktop, it belongs in that desktop's directory, not here.
