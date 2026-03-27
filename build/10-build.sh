#!/usr/bin/bash
set -eoux pipefail

###############################################################################
# Fedora version (used for RPM Fusion)
###############################################################################

FEDORA_VERSION="$(rpm -E %fedora)"

###############################################################################
# Enable RPM Fusion (free + nonfree)
###############################################################################

dnf5 install -y \
  https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${FEDORA_VERSION}.noarch.rpm \
  https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${FEDORA_VERSION}.noarch.rpm

###############################################################################
# Multimedia stack (Mesa freeworld + codecs)
###############################################################################

# Replace Fedora Mesa with freeworld variants
dnf5 install -y \
  mesa-va-drivers-freeworld \
  mesa-vdpau-drivers-freeworld \
  --allowerasing


# Install full multimedia group (RPM Fusion maintained)
dnf5 group install -y multimedia \
  --with-optional \
  --allowerasing

# Explicit codec safety net
dnf5 install -y \
  ffmpeg \
  ffmpeg-libs \
  libavcodec-freeworld \
  gstreamer1-libav \
  gstreamer1-plugins-bad-freeworld \
  gstreamer1-plugins-ugly \
  --allowerasing

###############################################################################
# Virtualization stack (desktop-focused, minimal)
###############################################################################

dnf5 install -y \
  libvirt-daemon \
  libvirt-daemon-driver-qemu \
  libvirt-daemon-config-network \
  libvirt-client \
  qemu-kvm \
  qemu-img \
  virt-manager \
  virt-viewer

###############################################################################
# Steam (RPM Fusion nonfree)
###############################################################################

dnf5 install -y \
  steam \
  mesa-dri-drivers.i686 \
  mesa-libGL.i686 \
  mesa-libEGL.i686

###############################################################################
# Optional: hardware video acceleration helpers
###############################################################################

dnf5 install -y \
  libva-utils \
  intel-media-driver || true

###############################################################################
# Install Plasma Setup
###############################################################################

dnf5 install -y \
plasma-setup


###############################################################################
# Services
###############################################################################

systemctl enable libvirtd.service
systemctl enable virtlogd.service
systemctl enable podman.socket
systemctl enable bluetooth.service
systemctl enable plasma-setup.service
systemctl enable bootc-fetch-apply-updates.timer


###############################################################################
# Cleanup
###############################################################################

dnf5 clean all

echo "Custom build complete!"
