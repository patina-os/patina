#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# X session of the live image: a bare window manager and Calamares, full screen.
set -euo pipefail

# The installer's stylesheet (etc/calamares/branding/patina21/stylesheet.qss) is written
# against Qt's Fusion style.
export QT_STYLE_OVERRIDE=Fusion
openbox &
dbus-run-session -- calamares &
session_pid=$!
until pgrep -x calamares > /dev/null; do
  sleep 1
done
# The boot test watches the serial console for this line (iso/test/boot-test.sh).
echo 'patina21 installer: ready' > /dev/console || true
wait "$session_pid"
