#!/usr/bin/env bash
set -euxo pipefail

# --------------------------------------------------------------------
# Phase 1: Rootfs vorbereiten – Anaconda erwartet KEIN /home
# --------------------------------------------------------------------
rm -rf /home

# --------------------------------------------------------------------
# Phase 2: Installer installieren
# --------------------------------------------------------------------
dnf install -y \
  anaconda \
  anaconda-gui \
  anaconda-live \
  anaconda-widgets \
  xorg-x11-server-Xwayland \
  polkit

# --------------------------------------------------------------------
# Phase 3: Installer-Launcher systemweit anlegen
# --------------------------------------------------------------------
cat > /usr/share/applications/install-to-disk.desktop <<'EOF'
[Desktop Entry]
Name=Install to Disk
Comment=Install this system to your computer
Exec=Exec=pkexec anaconda
Icon=system-software-install
Terminal=false
Type=Application
Categories=System;
EOF

# --------------------------------------------------------------------
# Phase 4: Finalen Zielzustand herstellen
# --------------------------------------------------------------------
mkdir -p /home
