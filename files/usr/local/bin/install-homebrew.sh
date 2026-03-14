#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${1:-}" ]]; then
  echo "Kein Benutzer angegeben – breche ab." >&2
  exit 1
fi

USER="$1"

# Brew bereits vorhanden?
if sudo -u "$USER" command -v brew >/dev/null 2>&1; then
  echo "Homebrew ist bereits installiert – überspringe."
  exit 0
fi

echo "Installiere Homebrew für Benutzer: $USER"

sudo -u "$USER" NONINTERACTIVE=1 \
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
