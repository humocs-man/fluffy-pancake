#!/usr/bin/env bash
set -euxo pipefail

# --------------------------------------------------------------------
# Phase 1: Rootfs vorbereiten – Anaconda erwartet KEIN /home
# --------------------------------------------------------------------
rm -rf /home

# --------------------------------------------------------------------
# Phase 2: Installer + Branding installieren
# --------------------------------------------------------------------
dnf install -y \
  anaconda \
  anaconda-live \
  anaconda-webui \
  anaconda-webui-branding-fedora \
  polkit \
  firefox

# --------------------------------------------------------------------
# Phase 3: WebUI systemd-Servicefile anlegen
# --------------------------------------------------------------------
cat > /usr/lib/systemd/system/anaconda-webui.service <<'EOF'
[Unit]
Description=Anaconda Web UI
After=network.target graphical.target

[Service]
Type=simple
ExecStart=/usr/bin/anaconda-webui
Restart=on-failure

[Install]
WantedBy=graphical.target
EOF

# --------------------------------------------------------------------
# Phase 4: Service aktivieren
# --------------------------------------------------------------------
systemctl enable anaconda-webui.service

# --------------------------------------------------------------------
# Phase 5: Desktop-Launcher für den Installer
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
# Phase 6: Finalen Zielzustand herstellen
# --------------------------------------------------------------------
mkdir -p /home
