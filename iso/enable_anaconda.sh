set -euxo pipefail

# 1. /home komplett entfernen
rm -rf /home

# 2. Anaconda installieren
dnf install -y \
  anaconda \
  anaconda-webui

# 3. Desktop-Datei vorbereiten, aber OHNE /home zu benutzen
INSTALLER_DESKTOP="/usr/share/applications/install-to-disk.desktop"

cat >"$INSTALLER_DESKTOP" <<'EOF'
[Desktop Entry]
Name=Install to Disk
Comment=Install this system to your computer
Exec=anaconda --webui
Icon=system-installer
Terminal=false
Type=Application
Categories=System;
EOF

# 4. Erst ganz am Ende /home anlegen
mkdir -p /home/liveuser/.local/share/applications
