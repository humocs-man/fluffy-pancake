#!/usr/bin/env bash
set -euo pipefail

echo "[firstboot] Ensuring Flathub remote exists"

if ! flatpak remote-list --system | grep -q '^flathub'; then
  flatpak remote-add --system --if-not-exists flathub \
    https://flathub.org/repo/flathub.flatpakrepo
fi

echo "[firstboot] Done"
