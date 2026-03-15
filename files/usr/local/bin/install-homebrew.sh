#!/usr/bin/env bash
set -euo pipefail

USER="$1"
HOME="/var/home/$USER"
export HOME
export NONINTERACTIVE=1


# Homebrew installieren (als User, aber ohne Interaktion)
sudo -u "$USER" HOME="$HOME" NONINTERACTIVE=1 bash -c \
  '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'

# Optional: Brew in PATH eintragen
if ! grep -q 'linuxbrew' "$HOME/.bashrc"; then
  echo 'eval "$(/var/home/'"$USER"'/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> "$HOME/.bashrc"
fi
