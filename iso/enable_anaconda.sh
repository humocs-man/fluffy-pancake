#!/usr/bin/env bash
set -euo pipefail

# ------------------------------------------------------------
# Minimal notwendige Installer-Komponenten
# ------------------------------------------------------------
dnf -y install \
  anaconda \
  pykickstart \
  lorax-templates-generic \
  || true

# ------------------------------------------------------------
# Installer-Launcher (nur Live-System)
# ------------------------------------------------------------
cat >/usr/share/applications/install-to-disk.desktop <<'EOF'
[Desktop Entry]
Name=Install to Disk
Comment=Install this system to your computer
Exec=anaconda --liveinst
Icon=system-installer
Terminal=false
Type=Application
Categories=System;
EOF

# ------------------------------------------------------------
# Nur im Live-System behalten
# ------------------------------------------------------------
if ! grep -q 'boot=live' /proc/cmdline; then
  rm -f /usr/share/applications/install-to-disk.desktop
fi
