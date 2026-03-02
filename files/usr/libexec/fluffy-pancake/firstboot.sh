#!/usr/bin/env bash
set -euo pipefail

echo "[fluffy-pancake-firstboot] starting"

if systemctl list-unit-files | grep -q '^brew-setup.service'; then
  systemctl start brew-setup.service || true
fi

if systemctl list-unit-files | grep -q '^flatpak-add-fedora-repos.service'; then
  systemctl start flatpak-add-fedora-repos.service || true
fi

echo "[fluffy-pancake-firstboot] done"
