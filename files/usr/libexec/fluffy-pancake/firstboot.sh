#!/usr/bin/env bash
set -euo pipefail

echo "[firstboot] Starting first boot initialization"

# -------------------------------------------------------------------
# Initialize Homebrew (no updates, no network dependency)
# -------------------------------------------------------------------
if [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
  echo "[firstboot] Initializing Homebrew environment"

  export HOMEBREW_PREFIX="/home/linuxbrew/.linuxbrew"
  export HOMEBREW_CELLAR="$HOMEBREW_PREFIX/Cellar"
  export HOMEBREW_REPOSITORY="$HOMEBREW_PREFIX/Homebrew"
  export PATH="$HOMEBREW_PREFIX/bin:$HOMEBREW_PREFIX/sbin:$PATH"

  brew config >/dev/null
else
  echo "[firstboot] Homebrew not present, skipping"
fi

# -------------------------------------------------------------------
# Ensure Flathub exists
# -------------------------------------------------------------------
if ! flatpak remote-list --system | grep -q '^flathub'; then
  echo "[firstboot] Adding Flathub remote"
  flatpak remote-add --system --if-not-exists flathub \
    https://flathub.org/repo/flathub.flatpakrepo
fi

# -------------------------------------------------------------------
# Flatpak preinstall
# -------------------------------------------------------------------
echo "[firstboot] Installing Flatpaks"

flatpak install --system --noninteractive flathub \
  org.mozilla.firefox \
  org.gnome.Calculator

echo "[firstboot] First boot initialization complete"
