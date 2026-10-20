# iso/

The patina21 ISO: openSUSE's own installer (Agama) and image tooling (KIWI on the Open
Build Service), driven by our data. The ISO contains no logic of its own; it automates
the stock-openSUSE path (Path A) and nothing else. If Path A and the ISO ever diverge,
Path A wins and the ISO is fixed.

Status: scaffolded (roadmap, Phase 2). Nothing here has been built or booted yet; the
first OBS build is the step that verifies it. What each file assumes is written next to
it, and the list of things to verify is at the end of this page.

```text
iso/
  agama/patina21.json       the installer preset: product, first-boot files, post script.
                            The live ISO loads it (agama config load), so the installer
                            asks only for disk and user; the theme is asked at first boot
  kiwi/patina21.kiwi        KIWI description of the live installer ISO (x86_64, aarch64)
  kiwi/config.sh            KIWI image script: enable services, offer only our product
  kiwi/root/                overlay for the live system, packed by pack-overlay.sh:
    usr/share/agama/products.d/patina21.yaml   Agama product definition: openSUSE's
                            repositories (oss and update only), the Plasma pattern,
                            the base packages, Tumbleweed's btrfs layout
    etc/systemd/system/patina21-preset.service  loads agama/patina21.json into Agama
    etc/systemd/system/patina21-ui.service      the local installer screen (kiosk browser)
    etc/issue.d/10-patina21.issue               the text mark on the console
  kiwi/pack-overlay.sh      builds the OBS package sources under iso/build/obs/
  firstboot/                the systemd unit and script that run Path A on first boot;
                            the profile fetches them from this repository at install time
  test/install-test.sh      the release gate: unattended install in QEMU, then first boot
  test/answers.json         disk, user and root answers for that test
```

## How an install works

1. Boot the ISO. The live system starts Agama, `patina21-preset.service` loads
   `agama/patina21.json` from this repository's `main` branch, and `patina21-ui.service`
   shows Agama's web UI in a kiosk browser on the local screen.
2. The installer offers one product, "patina21 (openSUSE Tumbleweed)", with Plasma
   preselected. The user answers two questions: disk and user. Everything installed
   comes from openSUSE's oss and update repositories.
3. Agama writes `firstboot/patina21-firstboot.service` and its script into the new
   system (the `files` section) and enables the unit (the `post` script).
4. First boot: the service takes tty1 before the login screen, clones this repository
   into the user's `~/.local/share/patina21`, links `~/.local/bin/patina` and runs
   `patina install`, which asks the third question, the theme. Then it writes
   `/var/lib/patina21/firstboot-done` and never runs again. A failed clone or install
   prints the Path A command to run by hand and still marks the boot done, so a machine
   never loops on first boot.

That is Path A, executed for the user. The ISO carries only the product definition,
the preset loader and the installer screen.

## Open Build Service

The ISO is built in an OBS project owned by the patina21 account (planned name
`home:patina21:iso`, package `patina21-installer`), with openSUSE Tumbleweed's
repositories as the only sources. OBS rebuilds when openSUSE's packages change and
signs the result; Secure Boot works through openSUSE's signed kernel and shim, which the
image does not touch.

To update the package sources:

```sh
iso/kiwi/pack-overlay.sh          # writes iso/build/obs/ (gitignored)
osc checkout home:patina21:iso patina21-installer
cp iso/build/obs/* home:patina21:iso/patina21-installer/
osc -A https://api.opensuse.org addremove && osc commit -m "sync from git <sha>"
```

The OBS package also needs `_service` with `kiwi_metainfo_helper` (buildtime) if the
description ever uses `%VARIABLES%`; it does not today.

## Unattended installs and the install test

`agama/patina21.json` is a partial profile on purpose. For an install that asks
nothing, merge your answers over it and boot the ISO with
`inst.auto=<url of the merged profile>`:

```sh
jq -s '.[0] * .[1]' iso/agama/patina21.json my-answers.json > profile.json
```

`test/answers.json` is such a file (throwaway credentials, largest disk, serial console,
first boot unattended with `PATINA_UNATTENDED=1` and `PATINA_THEME`). Note that `jq`'s
`*` replaces arrays, so an answers file that carries `scripts.post` must repeat the line
that enables the first-boot unit, as `test/answers.json` does.

`test/install-test.sh <iso>` runs the merged profile in QEMU with KVM, waits for Agama to
finish and power off, boots the installed disk and waits for
`patina21 firstboot: done` on the serial console. `.github/workflows/iso-test.yml` runs
it on demand with an ISO URL from OBS.

## Rules

- Every package comes from openSUSE repositories. The ISO adds only the product
  definition, the preset loader, the installer screen and branding within the openSUSE
  trademark guidelines (`docs/branding.md`).
- openSUSE's signed kernel and shim stay untouched so Secure Boot keeps working. No
  kernel patches, no out-of-tree modules.
- Release rule: an ISO is published only after `test/install-test.sh` passes (x86_64:
  QEMU in CI; aarch64: QEMU or a Raspberry Pi 4 by hand). A failing rebuild is simply
  not published; Path A users are never affected.
- The first-boot contract for `patina install` (Phase 1): honour `PATINA_UNATTENDED=1`
  (no prompts, defaults for everything) and `PATINA_THEME=<name>`, and exit non-zero on
  failure so the first-boot script can say so.

## To verify on the first build

- The package list in `kiwi/patina21.kiwi` is modelled on openSUSE's `agama-installer`
  image; compare the two on every Agama release. The names `icewm-lite`, `xsetroot` and
  `google-noto-sans-fonts` are the first to check.
- Agama's live image ships extra units (live password, self-update, free-space check)
  from its own overlay, not from packages. The patina21 ISO has none of them; the
  `live.password=` boot option therefore needs checking before the ISO is announced as
  SSH-reachable.
- `patina21-ui.service` assumes Agama's web server answers plain HTTP on `localhost`;
  if it only serves HTTPS, point Firefox at the HTTPS URL and accept the live
  certificate in `root/.xinitrc`.
- `agama config load` is documented to accept a URL and to change settings without
  starting the install; confirm the preset survives the product being pre-selected.
- The `files` and `scripts.post` sections follow the Agama profile reference for
  openSUSE Tumbleweed; `agama config validate` on a merged profile is the check.
- `test/install-test.sh` takes kernel and initrd from `boot/<arch>/loader/` on the ISO
  and expects `inst.finish=poweroff`; both are KIWI and Agama conventions to confirm.
