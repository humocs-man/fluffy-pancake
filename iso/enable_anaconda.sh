#!/usr/bin/env bash
set -eoux pipefail

# -------------------------------------------------------------------
# Image metadata
# -------------------------------------------------------------------
IMAGE_INFO="$(cat /usr/share/ublue-os/image-info.json)"
IMAGE_TAG="$(jq -r '."image-tag"' <<<"$IMAGE_INFO")"
IMAGE_REF="$(jq -r '."image-ref"' <<<"$IMAGE_INFO")"
IMAGE_REF="${IMAGE_REF##*://}"

# -------------------------------------------------------------------
# Prevent suspend during installation (Anaconda requirement)
# -------------------------------------------------------------------
tee /usr/share/glib-2.0/schemas/zz3-fluffy-pancake-installer-power.gschema.override <<'EOF'
[org.gnome.settings-daemon.plugins.power]
sleep-inactive-ac-type='nothing'
sleep-inactive-battery-type='nothing'
sleep-inactive-ac-timeout=0
sleep-inactive-battery-timeout=0

[org.gnome.desktop.session]
idle-delay=uint32 0
EOF

glib-compile-schemas /usr/share/glib-2.0/schemas

# -------------------------------------------------------------------
# Install Anaconda (GNOME backend is implicit)
# -------------------------------------------------------------------
dnf install -y \
  anaconda-live \
  libblockdev-btrfs \
  libblockdev-lvm \
  libblockdev-dm \
  firefox

# -------------------------------------------------------------------
# Anaconda profile (Fluffy Pancake)
# -------------------------------------------------------------------
tee /etc/anaconda/profile.d/fluffy-pancake.conf <<'EOF'
[Profile]
profile_id = fluffy-pancake

[Profile Detection]
os_id = fluffy-pancake

[Network]
default_on_boot = FIRST_WIRED_WITH_LINK

[Bootloader]
efi_dir = fedora
menu_auto_hide = True

[Storage]
default_scheme = BTRFS
btrfs_compression = zstd:1

[Localization]
use_geolocation = False
EOF

# -------------------------------------------------------------------
# OS identity (installer + installed system)
# -------------------------------------------------------------------
sed -i 's/^ID=.*/ID=fluffy-pancake/' /usr/lib/os-release
grep -q '^VARIANT_ID=' /usr/lib/os-release || \
  echo 'VARIANT_ID=fluffy-pancake' >> /usr/lib/os-release

. /etc/os-release
echo "Fluffy Pancake release $VERSION_ID ($VERSION_CODENAME)" > /etc/system-release

# -------------------------------------------------------------------
# Minimal Anaconda branding (no GNOME UX tweaks)
# -------------------------------------------------------------------
sed -i -e 's/Fedora/Fluffy Pancake/g' \
       -e 's/CentOS/Fluffy Pancake/g' \
       /usr/share/anaconda/gnome/org.fedoraproject.welcome-screen.desktop || true

# -------------------------------------------------------------------
# Kickstart: install THIS image
# -------------------------------------------------------------------
tee /usr/share/anaconda/interactive-defaults.ks <<EOF
ostreecontainer --url=$IMAGE_REF:$IMAGE_TAG --transport=containers-storage --no-signature-verification
%end
EOF

tee /usr/share/anaconda/post-scripts/install-configure-upgrade.ks <<EOF
%post --erroronfail
bootc switch --mutate-in-place --transport registry $IMAGE_REF:$IMAGE_TAG
%end
EOF
