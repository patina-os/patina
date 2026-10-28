# The VM run

The manual run that closes Phase 1 and Phase 2 of the roadmap: Path A on a fresh Debian 13
VM with Plasma, then the theme on that real desktop. CI containers prove the packages and
the rendered files; this run proves what they cannot: the systemd side of the tuning, the
sudo path as a normal user, and the look on a running Plasma session. Tick the boxes in a
copy of this file or in an issue; what fails or looks wrong goes back into the data, and
the roadmap's two open items are ticked once a run passes end to end. Testers of an
alpha report their run with the test report form on GitHub (New issue, "Test report").

Any hypervisor works. The commands below run inside the VM.

## 1. The VM

- [ ] x86_64, UEFI firmware (not BIOS), Secure Boot may stay off for this run
- [ ] 4 virtual CPUs, 8 GB of memory (zram is sized from it), a 40 GB disk: Debian
  with Plasma takes about 10 GB, the desktop bundle's apps 3 GB more, a local AI
  model several GB on top; a 20 GB disk runs out during the install
- [ ] copy and paste between your computer and the VM (SPICE with `spice-vdagent` in
  the VM), or SSH into it (`openssh-server` in the VM and a forwarded port such as
  QEMU's `-nic user,hostfwd=tcp::2222-:22`): the checks below are commands to copy and
  output to paste into the report
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
- [ ] software selection: "KDE Plasma" and "standard system utilities", nothing else.
  Debian's KDE Plasma task brings LibreOffice and a set of KDE apps patina does not
  use; to free their space (optional, about 1 GB):
  `sudo apt purge 'libreoffice*' && sudo apt autoremove`
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
git clone https://github.com/patina-os/patina.git ~/.local/share/patina
mkdir -p ~/.local/bin && ln -s ~/.local/share/patina/bin/patina ~/.local/bin/patina
export PATH="$HOME/.local/bin:$PATH"   # Debian's ~/.profile adds it at the next login
script -q -c 'patina install' ~/run1.log
```

`script` keeps a log without hiding the terminal from the questions.

- [ ] the questions appear: the wordmark, the version line, the theme (aurora offered
  first and preselected), the app bundles (desktop preselected; minimal, extras, agents
  and artcraft not), the AI agent (none preselected; answer local on a VM with 8 GB
  or more and enough disk, the model is a few GB, else cloud or none and note it),
  for local the model (the ones that fit the VM's memory,
  Nemotron 3.5 Bolt E4B first from 16 GB, Ministral 3 3B below), a summary, a yes
- [ ] sudo asks for the password and nothing else does; no command fails
- [ ] it ends with `done: N changes`, and `git -C ~/.local/share/patina status --short` is
  empty (nothing written into the checkout)
- [ ] the system files are root's: `ls -l /etc/sysctl.d/99-patina-memory.conf
  /etc/udev/rules.d/60-patina-ioschedulers.rules` shows `root root` and `-rw-r--r--`
- [ ] the apt source of Euro-Office is in place:
  `/etc/apt/sources.list.d/*.sources` names Nextcloud's repository
- [ ] with the local agent: `ollama list` shows the model the summary named, and
  `opencode run "which Debian release is this?"` answers from it; asked to switch to
  the light theme, opencode asks before it runs `patina theme mode light`. With the
  cloud agent: `opencode auth login` came up for the provider picked
- [ ] with either agent, after logging out and in: `ai hello` in KRunner (Meta+Space)
  offers to ask the agent; Enter reopens KRunner on `ai ›` with the answer growing
  there (note whether it reads well or jumps); `ai switch to the light theme` shows an
  Allow / Always / Deny match before anything changes
- [ ] answered none: `patina ai` says none; `patina ai on cloud` installs opencode and
  kortex and asks for the login, and `patina ai off` takes Meta+A and `ai` in KRunner
  away again (opencode and kortex stay installed)

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

- [ ] kitty, Firefox ESR, Thunderbird, KeePassXC, the Nextcloud client, Element,
  Euro-Office
- [ ] with the extras bundle (`patina install --bundles extras`, over 2 GB): Zed's
  telemetry and AI features are off (Settings, or
  `~/.var/app/dev.zed.Zed/config/zed/settings.json`), Tauon starts
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
- [ ] Meta+A opens opencode in its own kitty profile; without the bundle or an AI
  agent the key does nothing
- [ ] a second `patina install --bundles agents` ends with `nothing to do`

Roll back to "patina-desktop" afterwards.

## 9. The look (Phase 2)

Log out and back in once, then:

- [ ] the splash: the wordmark and one accent line, on the theme's background, not
  KDE's logo; if KDE's shows, `ksplashqml --test --window org.patina.aurora` shows
  patina's in a window and says why it failed
- [ ] the login screen: the contour map wallpaper, the words in Source Sans 3
- [ ] the desktop: the glowing contour map on black, aurora's colour scheme (green
  selections and focus, violet hover), a bar along the bottom edge (it stays there
  when a window is maximised) with the launcher and the pinned files, browser and
  terminal in the middle
- [ ] the start menu: the patina dots as its button; the AI and Self-hosting folders
  among the categories; the favourites are Nextcloud, Element, Euro-Office,
  Thunderbird, KeePassXC, kitty (and the agent and Claude Desktop with the agents
  bundle), and none of Debian's (Discover, Dolphin, System Settings, Konqueror); its
  background is glass, the wallpaper glowing through; its category icons and the
  apps' glyphs are green, the labels white; the user's picture is the patina mark
- [ ] the wallpaper is the DeepMind waves; every icon in the bar, the start menu and
  the title bars is a single-colour glyph; the start menu and the calendar show a
  faint grain
- [ ] no Breeze blue or light grey anywhere: title bars and the bar dark, Dolphin's
  folders and its own icon green, tray and toolbar icons in the palette's colours
  (Papirus)
- [ ] fonts: Source Sans 3 in menus and titles, JetBrains Mono in terminals
- [ ] a new window (Dolphin, Thunderbird, kitty, and Firefox, which remembers a
  maximised window) opens centred at about 70% of the screen; only kitty is
  see-through
- [ ] animations are noticeably shorter than stock Plasma's
- [ ] kitty: the theme's colours, the fastfetch greeting with the mark from
  `branding/logo.txt` in every new window (not in Konsole); btop, nvim, `bat`, `fzf` and `delta` in the same colours
- [ ] Konsole: the patina profile in the same colours
- [ ] a GTK app (Thunderbird) and a Flatpak app (Element) follow the colour scheme
- [ ] every key of `defaults/keybindings.yaml` does what its `names` entry says;
  Meta+K and `patina keys` show the same list

## 10. Switching themes in a running session

```sh
patina theme set datum
patina theme set aurora
patina theme set aurora
patina theme mode light
patina theme mode dark
```

- [ ] the switch to datum applies live: colours, wallpaper, kitty, Konsole, without
  logging out; write down anything that waits for the next login
- [ ] the switch back to aurora leaves nothing of datum:
  `ls ~/.local/share/color-schemes ~/.local/share/konsole ~/.local/share/wallpapers
  ~/.local/share/plasma/look-and-feel` shows only aurora's `patina-aurora*` and
  `org.patina.aurora` entries, and kitty's colours are aurora's again
- [ ] the third command reports no change
- [ ] `patina theme mode light` turns the desktop, kitty and Konsole light and the
  wallpaper to the light contour map, live; the login screen stays dark;
  `patina theme mode dark` brings the black back and removes the light wallpaper
  package

## 11. The first login of a new user

The look-and-feel package hands a session that has never run the theme its whole look,
as the image's first boot will:

```sh
sudo adduser --comment '' patina-test
sudo -iu patina-test bash -c '
  git clone https://github.com/patina-os/patina.git ~/.local/share/patina &&
  ~/.local/share/patina/bin/patina install --unattended'
```

- [ ] the install needs no Plasma session and ends without errors, although
  `patina-test` has no sudo: everything system-wide is already in place from the first
  user's run, so nothing asks for it
- [ ] logging in as `patina-test` for the first time gives the wallpaper, the colour
  scheme and the centred bar at once, without a second login

## 12. After the run

- [ ] a tester: open a test report on GitHub with what passed and what did not, the
  output of `patina version` and `patina doctor`, and the failing part of the logs
- [ ] every failure or wrong look is a fix in the data or the renderer, or an issue
- [ ] `docs/hardware.md`: the "Generic PC or VM (UEFI)" row gets the status the run
  earned and the date
- [ ] `docs/roadmap.md`: Phase 1's and Phase 2's last items are ticked when the run
  passed end to end
