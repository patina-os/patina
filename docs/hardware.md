# Tested hardware

The layer has no architecture; the base provides the hardware support. This list records
what has been tested with patina, how far it got, and where the device glue lives. An
"ARM version" is this list plus `devices/`, never a separate release.

Status values: untested, boots, works-with-caveats, supported.

| Device | Arch | Status | Base image | Glue | Notes |
|---|---|---|---|---|---|
| Generic PC or VM (UEFI) | x86_64 | untested | Debian 13 netinst or live | none | reference target for Phases 1 to 3; the live image's boot test runs in QEMU in CI |
| Generic UEFI machine or VM | aarch64 | untested | Debian 13 netinst or live | none | the arm64 live image is built and boot-tested in QEMU in CI (Phase 3) |
| Try patina for Windows (QEMU on Windows) | x86_64 | untested | the released `patina-amd64.hybrid.iso`, installed by TryPatina.exe | [`devices/try-patina-windows/`](../devices/try-patina-windows/) (data and an SDDM file) | the launcher lives in [patina-os/win-emulator](https://github.com/patina-os/win-emulator); stock QEMU on the Windows Hypervisor Platform, software rendering; the Plasma X11 session first, for copy and paste with Windows through spice-vdagent |
| Raspberry Pi 4 | aarch64 | untested | Debian's official Raspberry Pi image | [`devices/raspberry-pi-4/`](../devices/raspberry-pi-4/) (data only) | Phase 4; the validation procedure is in that directory's README: USB SSD, clean reimage per run |
| Snapdragon X Elite laptops | aarch64 | untested | Debian 13 by hand (debootstrap, systemd-boot, kernel and firmware from trixie-backports) | [`devices/snapdragon-x-elite/`](../devices/snapdragon-x-elite/) (data only) | Phase 4; the validation procedure is in that directory's README; works with caveats upstream. Debian 13's firmware package covers the ThinkPad T14s Gen 6 and the Yoga Slim 7x; other models need firmware from their Windows partition, a helper for that waits for the first run |
| Snapdragon X2 Elite laptops | aarch64 | untested | n/a | none | Phase 4, waiting: device trees land in Linux 7.4, GPU and NPU drivers are still upstreaming, Debian 13's kernel is 6.12. Qualcomm announced Debian support for late 2026; no device directory until one boots Debian's kernel |
| Nvidia RTX Spark laptops (N1X) | aarch64 | untested | n/a | none | Phase 4, waiting: on sale since October 2026 (ASUS, Dell, HP, Lenovo, Microsoft, MSI), Windows only; Nvidia has not committed to Linux. Community bring-ups (Arch Linux ARM, Omarchy) run on patched 7.x kernels with the 615 open driver; the platform patches (embedded controller, USB4, audio, pin control, power) are not upstream, Debian 13's kernel is 6.12. No device directory until one boots Debian's kernel |
| Apple Silicon Mac, in a virtual machine | aarch64 | untested | Debian 13 for arm64 in UTM | none | Path A, like any aarch64 VM; the arm64 image once it is handed out |
| Apple Silicon Mac, natively | aarch64 | untested | n/a | none | waiting: Debian's kernel lacks the Asahi patches (Debian's Bananas team carries the rest of the stack in trixie, the kernel and installer not); M1 and M2 run on Asahi's own kernel, M3 is preliminary, M4 and M5 are in bring-up. No device directory until one boots Debian's kernel |

Add a row when you test a device, even when it fails, and link the `devices/<slug>/`
directory when one exists.
