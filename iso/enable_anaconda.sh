#!/usr/bin/env bash
set -euxo pipefail

# --------------------------------------------------------------------
# Phase 1: Rootfs vorbereiten – Anaconda erwartet KEIN /home
# --------------------------------------------------------------------
rm -rf /home

# --------------------------------------------------------------------
# Phase 2: Installer installieren
# --------------------------------------------------------------------
# Phase 2: Web-Installer installieren
# --------------------------------------------------------------------
dnf install -y \
  anaconda \
  anaconda-live \
  anaconda-webui \
  polkit
# --------------------------------------------------------------------
# Phase 3: Installer-Launcher systemweit anlegen
# --------------------------------------------------------------------
cat > /usr/share/applications/install-to-disk.desktop <<'EOF'
[Desktop Entry]
Name=Jetzt installieren
Comment=Installiere das System auf die Festplatte
Exec=xdg-open http://localhost:8080
Icon=system-installer
Terminal=false
Type=Application
Categories=System;

EOF

# --------------------------------------------------------------------
# Phase 4: Finalen Zielzustand herstellen
# --------------------------------------------------------------------
mkdir -p /home
