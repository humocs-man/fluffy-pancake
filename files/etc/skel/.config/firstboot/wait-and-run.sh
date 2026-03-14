#!/usr/bin/env bash
set -euo pipefail

# 1. Warten, bis der User‑DBus stabil ist
until busctl --user list >/dev/null 2>&1; do
  sleep 1
done

# 2. Warten, bis die COSMIC‑Session wirklich läuft
until pgrep -x cosmic-session >/dev/null; do
  sleep 1
done

# 3. Kurze Beruhigungsphase (Panels, Fokus, Autostarts)
sleep 2

# 4. Wizard starten
exec "$HOME/.config/firstboot/firstboot-setup.sh"
