#!/usr/bin/env bash
set -euo pipefail

# Warten, bis wir wirklich in einer grafischen Session sind
until [ -n "${WAYLAND_DISPLAY:-}" ] || [ -n "${DISPLAY:-}" ]; do
  sleep 1
done

# User‑DBus stabil
until busctl --user list >/dev/null 2>&1; do
  sleep 1
done

sleep 2
exec "$HOME/.config/firstboot/firstboot-setup.sh"
