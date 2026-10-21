#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# KIWI image script for the patina21 live ISO: runs once inside the image root at build
# time. Enables the installer services and makes patina21 the only product offered.
set -euo pipefail

# KIWI's helper functions and image variables (kiwi_iname, kiwi_profiles, ...).
# shellcheck disable=SC1091  # written by KIWI into the image root; absent elsewhere
[[ -f /.kconfig ]] && source /.kconfig
# shellcheck disable=SC1091  # same
[[ -f /.profile ]] && source /.profile

echo "configure image: ${kiwi_iname:-patina21-installer}"

# openSUSE's /etc/products.d/baseproduct link, as every openSUSE image sets it.
if declare -F suseSetupProduct >/dev/null; then
  suseSetupProduct
fi

# The installer offers only patina21. openSUSE's own product files stay in the
# agama-products-opensuse package; they are removed from this image only, not altered.
find /usr/share/agama/products.d -maxdepth 1 -name '*.yaml' ! -name 'patina21.yaml' -delete

# Services. Every unit is checked first: Agama's set changes between releases, and a
# missing unit must not fail the build.
enable_if_present() {
  local unit
  for unit in "$@"; do
    if [[ -f "/usr/lib/systemd/system/$unit" || -f "/etc/systemd/system/$unit" ]]; then
      systemctl enable "$unit"
    else
      echo "config.sh: unit $unit not present, skipped"
    fi
  done
}
enable_if_present \
  NetworkManager.service sshd.service avahi-daemon.service zramswap.service \
  agama.service agama-web-server.service agama-dbus-monitor.service \
  agama-autoinstall.service agama-hostname.service agama-proxy-setup.service \
  agama-certificate-issue.path agama-certificate-wait.service \
  agama-cmdline-process.service agama-welcome-issue.service agama-url-issue.service \
  agama-ssh-issue.service agama-avahi-issue.service checkmedia.service \
  qemu-guest-agent.service spice-vdagentd.service \
  patina21-preset.service patina21-ui.service
systemctl set-default graphical.target

# Snapshots make no sense on a live medium.
systemctl disable snapper-cleanup.timer snapper-timeline.timer 2>/dev/null || true

# The live initrd needs the live modules; Agama's cmdline module reads inst.* options.
echo 'add_dracutmodules+=" dracut-menu agama-cmdline "' > /etc/dracut.conf.d/10-patina21-live.conf

# Agama reads JSON profiles from URLs; shorter timeouts keep a wrong URL from hanging.
mkdir -p /etc/zypp/zypp.conf.d
cat > /etc/zypp/zypp.conf.d/90-patina21.conf <<'CONF'
[main]
download.connect_timeout = 20
CONF

# Marker the install test and `patina doctor` can read.
mkdir -p /etc/patina21
echo "patina21-installer ${kiwi_iversion:-unknown}" > /etc/patina21/live-image
