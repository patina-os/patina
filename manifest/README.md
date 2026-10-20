# manifest/

Everything patina21 installs is listed here as data. Scripts read these files; they never
contain package names themselves.

```text
manifest/
  bundles/<bundle>.yaml    what to install, by canonical name, grouped for the installer TUI
  backends/<backend>.yaml  how one package manager installs it (zypper first)
  upstream.yaml            tools that come from their upstream installers (agent CLIs)
```

## Bundles

```yaml
name: dev
description: Shown in the TUI
default: true        # preselected in `patina install`
packages:            # canonical names, resolved through backends/<backend>.yaml
  - git
flatpaks:            # Flathub application IDs; identical on every base
  - org.kde.okular
upstream:            # keys of manifest/upstream.yaml
  - claude-code
```

Canonical names are the openSUSE package names, because openSUSE is the reference base.
A backend file maps them only where its own name differs.

## Backends

A backend is one YAML file: the `ID` values from `/etc/os-release` it serves, the commands
for refresh, install and is-installed, and the name map. Adding a base means adding a file
here (and a container for it in the smoke workflow), not editing scripts.

## Sources, in order of preference

1. the base's own repositories (security updates are the base's job)
2. Flathub, for GUI apps we do not want to track
3. upstream installers, only for tools that have no packaged version worth using

Never: snap, vendor repositories we would have to maintain, binaries we build ourselves.
