#!/usr/bin/bash

set -eoux pipefail

###############################################################################
# Main Build Script
###############################################################################

# Source helper functions
# shellcheck source=/dev/null
source /ctx/build/copr-helpers.sh


# Enable nullglob for all glob operations to prevent failures on empty matches
shopt -s nullglob

echo "::group:: Copy Bluefin Config from Common"

mkdir -p /usr/share/ublue-os/just/
cp -r /ctx/oci/common/bluefin/usr/share/ublue-os/just/* /usr/share/ublue-os/just/

echo "::endgroup::"

echo "::group:: Copy Custom Files"

mkdir -p /usr/share/ublue-os/homebrew/
cp /ctx/custom/brew/*.Brewfile /usr/share/ublue-os/homebrew/

find /ctx/custom/ujust -iname '*.just' -exec printf "\n\n" \; -exec cat {} \; \
  >> /usr/share/ublue-os/just/60-custom.just

mkdir -p /etc/flatpak/preinstall.d/
cp /ctx/custom/flatpaks/*.preinstall /etc/flatpak/preinstall.d/

echo "::endgroup::"

echo "::group:: Install Packages"

# Base utilities
dnf5 install -y \
  fastfetch \
  btop \
  libvirt \
  libvirt-daemon \
  libvirt-daemon-driver-qemu \
  libvirt-daemon-config-network \
  libvirt-daemon-kvm \
  libvirt-client \
  qemu-kvm \
  qemu-img \
  virt-manager \
  virt-viewer \
  usbredir \ 
  

copr_install_isolated "ryanabx/cosmic-epoch" \
  cosmic-desktop
  
echo "::endgroup::"

echo "::group:: System Configuration"

systemctl enable podman.socket
systemctl enable bluetooth.service
systemctl enable cosmic-greeter.service
systemctl enable libvirtd.service
systemctl enable virtlogd.service


echo "::endgroup::"

shopt -u nullglob

echo "Custom build complete!"
