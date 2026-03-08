#!/usr/bin/env bash
set -euo pipefail

# ------------------------------------------------------------
# Installer-Komponenten für Live-ISO
# ------------------------------------------------------------
dnf -y install \
  anaconda \
  anaconda-webui 
  
# ------------------------------------------------------------
# Desktop-Launcher für Live-User (COSMIC-kompatibel)
# ------------------------------------------------------------
LIVEUSER_HOME="/home/liveuser"
APPDIR="$LIVEUSER_HOME/.local/share/applications"

mkdir -p "$APPDIR"

cat >"$APPDIR/install-to-disk.desktop" <<'EOF'
[Desktop Entry]
Name=Install to Disk
Comment=Install this system to your computer
Exec=anaconda --webui
Icon=system-installer
Terminal=false
Type=Application
Categories=System;
EOF
