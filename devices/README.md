# devices/

The only place where architecture- or device-specific files may live. Everything else in
the repository is architecture-free; the base (Debian) carries the hardware support.

An "ARM version" of patina is never a separate release or branch. It is the tested
hardware list in `docs/hardware.md` plus, where a device needs it, a directory here.

```text
devices/<slug>/
  device.yaml       what the device is and what it needs (required); laptops that differ
                    only in their device tree share one directory and are listed under `models`
  README.md         how to get Debian onto it, known caveats (recommended)
  system/           system files, installed under /etc at the same path (as
                    defaults/system/ is) when `patina` detects the device (optional);
                    one that is executable stays so (a script under /etc/grub.d)
  firstboot/        what a disk image made for the device carries for its first boot,
                    before `patina install` (Try patina's, iso/disk/; optional)
  *.sh              glue scripts, only when data cannot express it (firmware extraction)
```

`patina install` detects a device by the `detect` map of its `device.yaml`: fields of
`/sys/class/dmi/id` and the value each must equal, all of them. A machine that boots
with a device tree is detected by `detect_compatible` instead, one of the strings its
tree calls itself compatible with (`/sys/firmware/devicetree/base/compatible`): the
SoC's, where one directory serves a platform. A detected device adds its
`extra_packages` to the install and its `system/` files to the system tuning, and
`patina doctor` checks both. A device with neither key is never detected; its README
says what to do by hand.

A machine whose firmware gives Linux no hardware description boots only when the boot
loader hands the kernel its device tree, so the image must know it before Linux
starts. A model with `menu` under `models` gets an entry of that name in the image's
boot menu ("Install on …"), which loads the model's `dtb` from the live kernel and
adds the device's `kernel_params`; where the product name the firmware reports
matches the model's `smbios`, a regular expression, the entry leads the menu, and all
of a device's entries stand in a submenu named by its own `menu`. The installer then
writes the device's `system/` files and the tree's name (`/etc/kernel/devicetree`) to
the disk, before the first boot, which could not happen without them: the one step of
the image that Path A does not run first (`iso/README.md`). Only for a model whose
firmware Debian's archive carries.

Rules:

- A device directory is added only once the device boots Debian's kernel, even if only
  with caveats or from backports; wishes go to the roadmap and `docs/hardware.md`.
- Glue scripts follow the `bin/` conventions and run only when `patina` detects that device.
- Detect a device by what only it reports (a product name, not a vendor that covers a
  whole family), so no other machine is matched.
- No kernel patches, no out-of-tree modules, no firmware blobs committed to the repository.
  A firmware helper may copy files from a vendor partition on the user's own machine.

`_template/` is the skeleton to copy; tools skip entries starting with `_`.
