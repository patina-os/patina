# The VM run

The manual run that closes Phase 1 and Phase 2 of the roadmap: Path A on a fresh Debian 13
VM with Plasma, then the theme on that real desktop. CI containers prove the packages and
the rendered files; this run proves what they cannot: the systemd side of the tuning, the
sudo path as a normal user, and the look on a running Plasma session. Tick the boxes in a
copy of this file or in an issue; what fails or looks wrong goes back into the data, and
the roadmap's two open items are ticked once a run passes end to end.

Any hypervisor works. The commands below run inside the VM.

## 1. The VM

- [ ] x86_64, UEFI firmware (not BIOS), Secure Boot may stay off for this run
- [ ] 4 virtual CPUs, 8 GB of memory (zram is sized from it), a 40 GB disk
- [ ] the disk on a SATA or NVMe controller, not virtio: the scheduler rules of
  `defaults/system/udev/rules.d/` match `sd*`, `mmcblk*` and `nvme*`, a virtio disk is
  `vda` and would test nothing
- [ ] a display of at least 1920x1080, 3D acceleration if the hypervisor offers it
- [ ] network with internet access (Debian's mirrors, Flathub, GitHub, Nextcloud's apt
  repository)

## 2. Debian 13

- [ ] the current Debian 13 netinst image for amd64
- [ ] leave the root password empty, so the first user gets `sudo`; patina's backend
  commands need it
- [ ] software selection: "KDE Plasma" and "standard system utilities", nothing else
- [ ] after the first login to Plasma: shut down and take a snapshot, "debian-clean". Every
  later run starts from it

## 3. Before patina

Record the stock values, so the changes are visible afterwards:

```sh
{
  cat /proc/swaps; sysctl vm.swappiness vm.page-cluster
  grep . /sys/block/*/queue/scheduler
  cat /sys/kernel/mm/transparent_hugepage/defrag
  systemctl is-active systemd-oomd irqbalance
  grep -h GRUB_TIMEOUT /etc/default/grub /etc/default/grub.d/* 2> /dev/null
  journalctl --disk-usage
} > ~/before.txt 2>&1
```

## 4. The first run (Phase 1)

In Konsole, inside the Plasma session:

```sh
sudo apt install git curl
git clone https://github.com/patina21/patina.git ~/.local/share/patina
mkdir -p ~/.local/bin && ln -s ~/.local/share/patina/bin/patina ~/.local/bin/patina
export PATH="$HOME/.local/bin:$PATH"   # Debian's ~/.profile adds it at the next login
script -q -c 'patina install' ~/run1.log
```

`script` keeps a log without hiding the terminal from the questions.

- [ ] the questions appear: the wordmark, the version line, the theme (datum offered
  first), the app bundles (desktop preselected, agents not), a summary, a yes
- [ ] sudo asks for the password and nothing else does; no command fails
- [ ] it ends with `done: N changes`, and `git -C ~/.local/share/patina status --short` is
  empty (nothing written into the checkout)
- [ ] the system files are root's: `ls -l /etc/sysctl.d/99-patina-memory.conf
  /etc/udev/rules.d/60-patina-ioschedulers.rules` shows `root root` and `-rw-r--r--`
- [ ] the apt source of Euro-Office is in place:
  `/etc/apt/sources.list.d/*.sources` names Nextcloud's repository

## 5. The second run and the doctor

```sh
script -q -c 'patina install' ~/run2.log
patina doctor
```

- [ ] the second run answers the same questions and ends with `nothing to do`: no
  package, flatpak, system file or theme file written
- [ ] `patina doctor` ends with `doctor: clean` and exit status 0; its `note` lines are
  read and explained in the run's notes

## 6. After a reboot: the systemd side

Reboot, log in, then compare with `~/before.txt`:

- [ ] zram: `cat /proc/swaps` lists `/dev/zram0` at priority 100,
  `zramctl` shows `zstd` and a disk size equal to the memory
- [ ] sysctls: `sysctl vm.swappiness vm.page-cluster vm.vfs_cache_pressure` gives
  100, 0, 50
- [ ] schedulers: `grep . /sys/block/*/queue/scheduler` has `[mq-deadline]` for a SATA
  SSD, `[bfq]` for a rotating disk, `[none]` for NVMe
- [ ] THP: `/sys/kernel/mm/transparent_hugepage/defrag` shows `[defer+madvise]`
- [ ] oomd: `systemctl is-active systemd-oomd` is `active`, `oomctl` lists the user
  service (`user@1000.service`) with a 50% memory pressure limit
- [ ] irqbalance: `systemctl is-active irqbalance` is `active`
- [ ] journald: `systemd-analyze cat-config systemd/journald.conf` ends with
  `SystemMaxUse=50M`
- [ ] stop timeouts: `systemctl show --property=DefaultTimeoutStopUSec` gives `15s`
- [ ] GRUB: the menu waits one second at boot; `grep 'timeout=' /boot/grub/grub.cfg`
  shows `set timeout=1`
- [ ] initramfs: `lsinitramfs /boot/initrd.img-$(uname -r) | wc -l` is clearly smaller
  than before the run (`MODULES=dep`), and the VM still boots
- [ ] the login screen offers the Plasma (Wayland) session as the default

## 7. The apps

Open each once from the launcher:

- [ ] kitty, Thunderbird, KeePassXC, the Nextcloud client, Element, Zed, Euro-Office
- [ ] Zed: telemetry and the AI features are off (Settings, or
  `~/.var/app/dev.zed.Zed/config/zed/settings.json`)
- [ ] Euro-Office: whether it still carries ONLYOFFICE's AI plugin (an open question of
  the roadmap); write down what its plugin manager shows
- [ ] in kitty: `fish`, `starship`, `bat`, `eza`, `fzf`, `rg`, `lazygit`, `btop`,
  `zoxide`, `atuin`, `delta`, `nvim` and `fastfetch` start

## 8. The agents bundle (optional, on a snapshot)

Take a snapshot first, "patina-desktop"; the bundle installs proprietary tools.

```sh
patina install --bundles agents
```

- [ ] Claude Code, Codex CLI, opencode, Claude Desktop and Ollama install;
  `systemctl is-active ollama` is `active`
- [ ] `~/.config/opencode/opencode.json` points opencode at `http://localhost:11434`
- [ ] Meta+A opens opencode in its own kitty profile; without the bundle the key does
  nothing
- [ ] a second `patina install --bundles agents` ends with `nothing to do`

Roll back to "patina-desktop" afterwards.

## 9. The look (Phase 2)

Log out and back in once, then:

- [ ] the splash: the wordmark and one accent line, on the theme's background
- [ ] the login screen: the contour map wallpaper, the words in Source Sans 3
- [ ] the desktop: the contour map, datum's colour scheme, a floating bar centred at the
  bottom with the launcher and the pinned files, browser and terminal in the middle
- [ ] fonts: Source Sans 3 in menus and titles, JetBrains Mono in terminals
- [ ] a new window (Dolphin, Thunderbird) opens centred at about 70% of the screen
- [ ] animations are noticeably shorter than stock Plasma's
- [ ] kitty: the theme's colours, the fastfetch greeting with the mark from
  `branding/logo.txt`; btop, nvim, `bat`, `fzf` and `delta` in the same colours
- [ ] Konsole: the patina profile in the same colours
- [ ] a GTK app (Thunderbird) and a Flatpak app (Element) follow the colour scheme
- [ ] every key of `defaults/keybindings.yaml` does what its `names` entry says;
  Meta+K and `patina keys` show the same list

## 10. Switching themes in a running session

```sh
patina theme set amethyst
patina theme set datum
patina theme set datum
```

- [ ] the switch to amethyst applies live: colours, wallpaper, kitty, Konsole, without
  logging out; write down anything that waits for the next login
- [ ] the switch back to datum leaves nothing of amethyst:
  `ls ~/.local/share/color-schemes ~/.local/share/konsole ~/.local/share/wallpapers
  ~/.local/share/plasma/look-and-feel` shows only datum's `patina-datum*` and
  `org.patina.datum` entries, and kitty's colours are datum's again
- [ ] the third command reports no change

## 11. The first login of a new user

The look-and-feel package hands a session that has never run the theme its whole look,
as the image's first boot will:

```sh
sudo adduser --comment '' patina-test
sudo -iu patina-test bash -c '
  git clone https://github.com/patina21/patina.git ~/.local/share/patina &&
  ~/.local/share/patina/bin/patina install --unattended'
```

- [ ] the install needs no Plasma session and ends without errors, although
  `patina-test` has no sudo: everything system-wide is already in place from the first
  user's run, so nothing asks for it
- [ ] logging in as `patina-test` for the first time gives the wallpaper, the colour
  scheme and the centred bar at once, without a second login

## 12. After the run

- [ ] every failure or wrong look is a fix in the data or the renderer, or an issue
- [ ] `docs/hardware.md`: the "Generic PC or VM (UEFI)" row gets the status the run
  earned and the date
- [ ] `docs/roadmap.md`: Phase 1's and Phase 2's last items are ticked when the run
  passed end to end
