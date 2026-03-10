#!/usr/bin/env bash
set -eoux pipefail

IMAGE_INFO="$(cat /usr/share/ublue-os/image-info.json)"
IMAGE_REF="$(jq -r '."image-ref"' <<<"$IMAGE_INFO")"
IMAGE_TAG="$(jq -r '."image-tag"' <<<"$IMAGE_INFO")"
IMAGE_REF="${IMAGE_REF##*://}"

# --- Live UX -------------------------------------------------------------

tee /usr/share/glib-2.0/schemas/zz-installer.gschema.override <<'EOF'
[org.gnome.shell]
welcome-dialog-last-shown-version='4294967295'
favorite-apps = ['liveinst.desktop', 'org.mozilla.firefox.desktop', 'org.gnome.Nautilus.desktop']
EOF

tee /usr/share/glib-2.0/schemas/zz-installer-power.gschema.override <<'EOF'
[org.gnome.settings-daemon.plugins.power]
sleep-inactive-ac-type='nothing'
sleep-inactive-battery-type='nothing'
sleep-inactive-ac-timeout=0
sleep-inactive-battery-timeout=0

[org.gnome.desktop.session]
idle-delay=uint32 0
EOF

glib-compile-schemas /usr/share/glib-2.0/schemas

rm -f /etc/xdg/autostart/org.gnome.Software.desktop || true

# --- Installer -----------------------------------------------------------

dnf install -y \
  anaconda \
  anaconda-gui \
  anaconda-live \
  libblockdev-btrfs \
  libblockdev-lvm \
  libblockdev-dm \
  firefox

tee /usr/share/applications/liveinst.desktop <<'EOF'
[Desktop Entry]
Name=Install System
Comment=Install this system to disk
Exec=anaconda
Icon=system-installer
Terminal=false
Type=Application
Categories=System;Installer;
EOF

update-desktop-database /usr/share/applications || true

# --- Kickstart -----------------------------------------------------------

tee /usr/share/anaconda/interactive-defaults.ks <<EOF
ostreecontainer --url=${IMAGE_REF}:${IMAGE_TAG} --transport=containers-storage --no-signature-verification
EOF
