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

dnf5 remove -y \
nvtop \
htop

echo "::group:: Install Packages"
# flatpak und just sind im base-main vorhanden, aber wir ergänzen deine Tools
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
  usbredir
echo "::endgroup::"

echo "::group:: Installing COSMIC"
copr_install_isolated "ryanabx/cosmic-epoch" \
  cosmic-desktop
echo "::endgroup::"

#firstboot-Marker setzen
mkdir -p /etc/myos
: > /etc/myos/firstboot


echo "::group:: System Configuration"
systemctl enable podman.socket
systemctl enable bluetooth.service
systemctl enable libvirtd.service
systemctl enable virtlogd.service

echo "::endgroup::"

shopt -u nullglob

echo "Custom build complete!"
