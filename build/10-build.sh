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
  btop

# Hyprland über COPR (isoliert)
copr_install_isolated "ashbuk/Hyprland-Fedora" \
  hyprland \
  xdg-desktop-portal-hyprland

# Quickshell + Desktop-Basis aus Fedora
dnf5 install -y \
  quickshell \
  hyprpaper \
  hypridle \
  hyprlock \
  foot \
  fuzzel \
  wlogout \
  xdg-desktop-portal-gtk \
  network-manager-applet

# Laptop-spezifische Komponenten
dnf5 install -y \
  power-profiles-daemon \
  upower \
  bluez \
  bluez-tools \
  blueman

echo "::endgroup::"

echo "::group:: System Configuration"

systemctl enable podman.socket
systemctl enable bluetooth.service

echo "::endgroup::"

shopt -u nullglob

echo "Custom build complete!"
