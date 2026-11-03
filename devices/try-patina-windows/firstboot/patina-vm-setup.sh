#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# First boot of Try patina's disk image: the installer's account, language, keyboard and time zone pages, answered on Windows.
set -euo pipefail

# TryPatina.exe asks on Windows what patina's installer asks on a PC and hands the
# answers over once, as QEMU firmware configuration (fw_cfg) under this name: one
# KEY=value per line, the keys below (README.md in this directory). This step sets up
# the account, the language, the keyboard and the time zone, and writes the apps, theme
# and AI answers to /etc/patina/firstboot.env as the installer does; patina's first boot
# (iso/firstboot/) then runs `patina install` for that account. Runs once.
setup=/sys/firmware/qemu_fw_cfg/by_name/opt/io.github.patina_os/setup/raw
state_dir=/var/lib/patina
done_marker="$state_dir/vm-setup-done"
# The installer's groups for a new account (users.conf), written by iso/disk/build.sh.
groups_file=/usr/local/lib/patina/vm-setup-groups

say() {
  printf 'patina vm setup: %s\n' "$*" | tee /dev/console > /dev/null 2>&1 || true
  # The machine's first serial port, which Try patina keeps as serial.log on Windows and
  # the image's boot test (iso/test/disk-test.sh) watches.
  printf 'patina vm setup: %s\r\n' "$*" > /dev/ttyS0 2> /dev/null || true
  logger -t patina-vm-setup -- "$*" 2> /dev/null || true
}

modprobe qemu_fw_cfg 2> /dev/null || true
if [[ ! -r "$setup" ]]; then
  # patina's first boot then finds no account and says what to do.
  say "no answers from Try patina; set the machine up again from Try patina's menu"
  exit 0
fi

user="" fullname="" password="" hostname="" locale="" layout="" variant="" timezone=""
agent="" ai="" bundles="" theme=""
while IFS= read -r line || [[ -n "$line" ]]; do
  line="${line%$'\r'}"
  value="${line#*=}"
  case "${line%%=*}" in
    PATINA_USER) user="$value" ;;
    PATINA_FULLNAME) fullname="$value" ;;
    PATINA_PASSWORD) password="$value" ;;
    PATINA_HOSTNAME) hostname="$value" ;;
    PATINA_LOCALE) locale="$value" ;;
    PATINA_KEYBOARD_LAYOUT) layout="$value" ;;
    PATINA_KEYBOARD_VARIANT) variant="$value" ;;
    PATINA_TIMEZONE) timezone="$value" ;;
    PATINA_AI_AGENT) agent="$value" ;;
    PATINA_AI) ai="$value" ;;
    PATINA_BUNDLES) bundles="$value" ;;
    PATINA_THEME) theme="$value" ;;
  esac
done < "$setup"

# The account: a name the installer would accept, never root or the live system's user.
if [[ ! "$user" =~ ^[a-z_][a-z0-9_-]{0,31}$ || "$user" == root || "$user" == live || -z "$password" ]]; then
  say "Try patina sent no usable account name or password; set the machine up again"
  exit 0
fi
# Where a value cannot be used, the image's own stays: British English, a US keyboard, UTC.
fullname="$(printf '%s' "$fullname" | tr -d ':,[:cntrl:]')"
[[ "$hostname" =~ ^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$ ]] || hostname="$user-patina"
[[ "$hostname" =~ ^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$ ]] || hostname=patina
grep -qxF "$locale UTF-8" /usr/share/i18n/SUPPORTED 2> /dev/null || locale=en_GB.UTF-8
if [[ ! "$layout" =~ ^[a-z]{2,}$ || ! -r "/usr/share/X11/xkb/symbols/$layout" ]]; then
  layout=us variant=""
fi
if [[ -n "$variant" ]] && { [[ ! "$variant" =~ ^[a-z0-9_]+$ ]] ||
  ! grep -qF "xkb_symbols \"$variant\"" "/usr/share/X11/xkb/symbols/$layout"; }; then
  variant=""
fi
if [[ ! "$timezone" =~ ^[A-Za-z0-9_+-]+(/[A-Za-z0-9_+-]+)*$ || ! -f "/usr/share/zoneinfo/$timezone" ]]; then
  timezone=Etc/UTC
fi

say "setting up $user ($locale, keyboard $layout${variant:+ $variant}, $timezone)"
mapfile -t groups < "$groups_file"
for group in "${groups[@]}"; do
  getent group "$group" > /dev/null || groupadd --system "$group"
done
if ! id "$user" > /dev/null 2>&1; then
  useradd --create-home --shell /bin/bash --comment "$fullname" \
    --groups "$(IFS=,; printf '%s' "${groups[*]}")" "$user"
fi
printf '%s:%s\n' "$user" "$password" | chpasswd
password=""

printf '%s\n' "$hostname" > /etc/hostname
printf '%s' "$hostname" > /proc/sys/kernel/hostname
hosts="$(grep -v '^127\.0\.1\.1[[:space:]]' /etc/hosts || true)"
printf '%s\n127.0.1.1\t%s\n' "$hosts" "$hostname" > /etc/hosts

grep -qxF "$locale UTF-8" /etc/locale.gen || printf '%s UTF-8\n' "$locale" >> /etc/locale.gen
locale-gen > /dev/null
update-locale "LANG=$locale"

# Debian's keyboard file serves the console (setupcon), X (through udev) and
# systemd-localed, which KWin reads in a Wayland session. The console's keymap matters
# at once: patina's first boot asks for the password on tty1.
cat > /etc/default/keyboard <<KEYBOARD
XKBMODEL="pc105"
XKBLAYOUT="$layout"
XKBVARIANT="$variant"
XKBOPTIONS=""
BACKSPACE="guess"
KEYBOARD
setupcon --force --keyboard-only 2> /dev/null || true
udevadm trigger --subsystem-match=input --action=change 2> /dev/null || true

ln -sfn "/usr/share/zoneinfo/$timezone" /etc/localtime
printf '%s\n' "$timezone" > /etc/timezone

# GRUB as the installer installs it, now that it runs on a real disk: the image's build
# could only copy it, with a configuration for its one kernel (iso/disk/build.sh). From
# here on Debian's menu and maintainer scripts keep it, as on an installed system.
target="$(cd /usr/lib/grub 2> /dev/null && ls -d -- *-efi)" || target=""
if [[ -n "$target" ]] && mountpoint -q /boot/efi; then
  grub=(grub-install --target="$target" --efi-directory=/boot/efi --bootloader-id=debian
    --force-extra-removable)
  if { "${grub[@]}" || "${grub[@]}" --no-nvram; } > /dev/null 2>&1 && update-grub > /dev/null 2>&1; then
    say "GRUB installed"
  else
    say "GRUB could not be installed; the disk keeps booting as it came"
  fi
fi

# The answers of the apps, more-apps, AI agent, AI model and theme pages, as the
# installer writes them (iso/live/config/.../shellprocess-firstboot.conf).
mkdir -p /etc/patina "$state_dir"
: > /etc/patina/firstboot.env
for pair in "PATINA_AI_AGENT=$agent" "PATINA_AI=$ai" "PATINA_BUNDLES=$bundles" "PATINA_THEME=$theme"; do
  [[ "${pair#*=}" =~ ^[a-z0-9,-]+$ ]] && printf '%s\n' "$pair" >> /etc/patina/firstboot.env
done
date -u +%FT%TZ > "$done_marker"
# On the disk before the launcher hears of it: it deletes the answers then, and a machine
# cut off with the setup still in memory would come back without either.
sync
say "done"
