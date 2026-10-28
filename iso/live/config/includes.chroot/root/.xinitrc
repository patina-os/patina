#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# X session of the live image: a bare window manager and Calamares, full screen.
set -euo pipefail

# The installer's stylesheet (etc/calamares/branding/patina/stylesheet.qss) is written
# against Qt's Fusion style.
export QT_STYLE_OVERRIDE=Fusion
# The installer starts in the live system's language (locales= on the kernel command
# line, auto/config), which live-config writes after systemd has read its environment.
if [[ -r /etc/default/locale ]]; then
  set -a
  # written by live-config at boot, so there is nothing to follow at lint time
  # shellcheck source=/dev/null
  source /etc/default/locale
  set +a
fi
openbox &
dbus-run-session -- calamares &
session_pid=$!
until pgrep -x calamares > /dev/null; do
  sleep 1
done
# The boot test watches the serial console for this line (iso/test/boot-test.sh).
echo 'patina installer: ready' > /dev/console || true
wait "$session_pid"
