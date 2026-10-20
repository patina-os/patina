# defaults/

Curated defaults as desktop-agnostic data. Nothing here is specific to Plasma; the
renderers under `desktops/` translate it. Users keep their own overrides outside the
repository (planned: `~/.config/patina21/`), so `git pull` never clobbers them.

- `keybindings.yaml`: named actions mapped to key chords. A desktop renderer knows how to
  bind each action (which command to launch, which window-manager function to call).
- `settings.yaml`: the small set of knobs `patina install` applies when the user does not
  choose otherwise: default theme, Flatpak remote, fonts.

Rules: no commands, no filesystem paths, no architecture names. If a default only makes
sense on one desktop, it belongs in that desktop's directory, not here.
