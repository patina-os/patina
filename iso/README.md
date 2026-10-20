# iso/

The patina21 ISO: openSUSE's own installer and image tooling, driven by our data. The ISO
contains no logic of its own; it automates the stock-openSUSE path (Path A) and nothing
else. If Path A and the ISO ever diverge, Path A wins and the ISO is fixed.

Planned contents (nothing is built yet; see `docs/roadmap.md`, Phase 2):

```text
iso/
  agama/patina21.json    Agama autoinstall profile: btrfs with snapshots, the Plasma
                         pattern, user creation, the base package list. Questions asked
                         at install time: disk, user, theme.
  kiwi/                  KIWI image description, built on the Open Build Service in a
                         project owned by the patina21 account; OBS rebuilds and signs
                         the ISO when openSUSE packages change
  firstboot/             systemd unit that runs the same `patina install` Path A uses
```

Rules:

- Every package comes from openSUSE repositories. The ISO adds only the profile, branding
  within the openSUSE trademark guidelines (`docs/branding.md`) and a copy of this
  repository.
- openSUSE's signed kernel and shim stay untouched so Secure Boot keeps working. No kernel
  patches, no out-of-tree modules.
- Release rule: an ISO is published only after an automated VM install test passes
  (x86_64: QEMU in CI; aarch64: QEMU or a Raspberry Pi 4 by hand). A failing rebuild is
  simply not published; Path A users are never affected.
