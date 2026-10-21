# Tested hardware

The layer has no architecture; the base provides the hardware support. This list records
what has been tested with patina21, how far it got, and where the device glue lives. An
"ARM version" is this list plus `devices/`, never a separate release.

Status values: untested, boots, works-with-caveats, supported.

| Device | Arch | Status | Base image | Glue | Notes |
|---|---|---|---|---|---|
| Generic PC or VM (UEFI) | x86_64 | untested | Debian 13 netinst or live | none | reference target for Phase 1 and 2; the live image's boot test runs in QEMU in CI |
| Generic UEFI machine or VM | aarch64 | untested | Debian 13 netinst or live | none | the arm64 live image is built and boot-tested in QEMU in CI (Phase 3) |
| Raspberry Pi 4 | aarch64 | untested | Debian's official Raspberry Pi image | [`devices/raspberry-pi-4/`](../devices/raspberry-pi-4/) (data only) | Phase 3; the validation procedure is in that directory's README: USB SSD, clean reimage per run |
| Snapdragon X Elite laptops | aarch64 | untested | n/a | planned (firmware helper) | works with caveats upstream; Phase 4 |
| Snapdragon X2 Elite laptops | aarch64 | untested | n/a | none | upstreaming in progress |
| Nvidia RTX Spark / N1X laptops | aarch64 | untested | n/a | none | no public Linux image yet |
| Apple Silicon | aarch64 | out of scope | n/a | none | Fedora Asahi, not Debian |

Add a row when you test a device, even when it fails, and link the `devices/<slug>/`
directory when one exists.
