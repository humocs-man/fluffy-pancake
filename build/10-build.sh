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

echo "::group:: Apply Bluefin common system files"
cp -a /ctx/oci/common/. /
echo "::endgroup::"

echo "::group:: Remove Bluefin GNOME branding"
rm -rf /usr/share/backgrounds/bluefin
rm -rf /usr/share/gnome-shell
rm -rf /usr/share/themes/Bluefin*
rm -rf /usr/share/icons/Bluefin*
rm -rf /usr/share/ublue-os/gnome
rm -f /usr/share/glib-2.0/schemas/*bluefin*.gschema.override
echo "::endgroup::"

echo "::group:: Apply Brew integration"
# Bringt Brew-User, PATH, systemd-Units, Brew-Bundle-Mechanik
cp -a /ctx/oci/brew/system_files/. /
echo "::endgroup::"

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

echo "::group:: Remove Firefox Systempackage"
dnf5 remove -y \
  firefox \
  firefox-langpacks\*
echo "::endgroup::"

echo "::group:: Copy Custom Files"
# Brewfiles → werden durch Brew-Bundle.service verarbeitet
mkdir -p /usr/share/ublue-os/homebrew/
cp /ctx/custom/brew/*.Brewfile /usr/share/ublue-os/homebrew/

# Just-Rezepte → werden durch just automatisch gefunden
find /ctx/custom/ujust -iname '*.just' -exec printf "\n\n" \; -exec cat {} \; \
  >> /usr/share/ublue-os/just/60-custom.just

# Flatpak-Preinstall-Skripte → werden durch flatpak-preinstall.service ausgeführt
mkdir -p /etc/flatpak/preinstall.d/
cp /ctx/custom/flatpaks/*.preinstall /etc/flatpak/preinstall.d/
echo "::endgroup::"

echo "::group:: Installing COSMIC"
copr_install_isolated "ryanabx/cosmic-epoch" \
  cosmic-desktop
echo "::endgroup::"

echo "::group:: System Configuration"
systemctl enable podman.socket
systemctl enable bluetooth.service
systemctl enable libvirtd.service
systemctl enable virtlogd.service
echo "::endgroup::"

shopt -u nullglob

echo "Custom build complete!"
