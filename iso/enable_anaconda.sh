#!/usr/bin/env bash
set -euo pipefail

# Läuft im ISO-Rootfs während Titanoboa-Build

dnf -y install \
  anaconda \
  anaconda-live \
  anaconda-install-env-deps \
  anaconda-dracut \
  pykickstart \
  lorax-templates-generic \
  || true

# Anaconda als Install-UI im Live-System verfügbar machen
mkdir -p /etc/anaconda/profile.d
cat >/etc/anaconda/profile.d/custom.conf <<'EOF'
[Profile]
profile_id = custom
os_id = custom
efi_dir = fedora
menu_auto_hide = True
EOF
