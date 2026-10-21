# defaults/

Curated defaults as desktop-agnostic data. Nothing here is specific to Plasma; the
renderers under `desktops/` translate it. Users keep their own overrides outside the
repository (planned: `~/.config/patina21/`), so `git pull` never clobbers them.

- `keybindings.yaml`: named actions mapped to key chords. A desktop renderer knows how to
  bind each action (which command to launch, which window-manager function to call).
- `settings.yaml`: the small set of knobs `patina install` applies when the user does not
  choose otherwise: default theme, Flatpak remote, fonts.
- `system/` (Phase 1, nothing there yet): the system tuning every install gets, copied
  from what CachyOS ships as configuration: sysctl, udev rules, systemd drop-ins,
  tmpfiles, initramfs and GRUB settings. Each file is named by its destination under
  `/etc`, the one place in `defaults/` where a path is allowed, and the apt backend's
  sudo path is the only thing that writes them.

Rules: no commands, no filesystem paths (except the destinations the `system/` files are
named by), no architecture names. If a default only makes sense on one desktop, it
belongs in that desktop's directory, not here.
