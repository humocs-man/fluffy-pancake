#!/usr/bin/env bash
set -euo pipefail

LOG="$HOME/.local/state/firstboot-setup.log"
mkdir -p "$(dirname "$LOG")"
exec > >(tee -a "$LOG") 2>&1

# ----------------------------
# Session check
# ----------------------------
if [[ -z "${WAYLAND_DISPLAY:-}" && -z "${DISPLAY:-}" ]]; then
  echo "Keine grafische Session verfügbar – breche ab."
  exit 1
fi

# ----------------------------
# Cleanup trap (nur bei Fehlern)
# ----------------------------
cleanup() {
  local code=$?
  if [[ $code -ne 0 ]]; then
    echo "Wizard abgebrochen oder mit Fehler beendet (Exitcode: $code)."
    rm -f "$HOME/.config/firstboot/run"
    systemctl --user disable firstboot-setup.service || true
  fi
}
trap cleanup EXIT

# ----------------------------
# Abort dialog
# ----------------------------
abort() {
  local code=$?
  echo "Abort ausgelöst (Exitcode: $code)."

  zenity --question \
    --title="Setup abbrechen?" \
    --text="<big><b>Setup abbrechen?</b></big>\n
Der Einrichtungs-Assistent wird dann nicht erneut angezeigt.\n
Alle Anwendungen können jederzeit über den COSMIC-Shop installiert oder entfernt werden.\n
Möchtest du den Setup-Assistenten wirklich abbrechen?" || return 0

  exit 0
}

# ----------------------------
# Helper functions
# ----------------------------
ensure_flathub() {
  flatpak remote-list --columns=name 2>/dev/null | grep -qx flathub || \
    flatpak remote-add --if-not-exists flathub \
      https://dl.flathub.org/repo/flathub.flatpakrepo
}

install_brew_and_setup_path() {
  if ! command -v brew >/dev/null 2>&1; then
    NONINTERACTIVE=1 CI=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi

  local BREW_PREFIX="/home/linuxbrew/.linuxbrew"
  local BREW_BIN="$BREW_PREFIX/bin/brew"
  [[ -x "$BREW_BIN" ]] || BREW_BIN="$(command -v brew)"

  eval "$("$BREW_BIN" shellenv)"

  for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
    [[ -f "$rc" ]] || continue
    grep -q 'brew shellenv' "$rc" || {
      echo "" >> "$rc"
      echo "# Homebrew" >> "$rc"
      echo "eval \"\$($BREW_BIN shellenv)\"" >> "$rc"
    }
  done
}

choose_list() {
  local title="$1"
  local text="$2"
  shift 2

  local result
  result=$(zenity --list \
    --title="$title" \
    --text="$text" \
    --checklist \
    --column="Auswahl" \
    --column="ID" \
    --column="Beschreibung" \
    FALSE "$@" \
    --separator="|" \
  ) || abort

  echo "${result:-}"
}

# ----------------------------
# Welcome
# ----------------------------
zenity --info \
  --title="Willkommen bei COSMIC" \
  --text="<big><b>Willkommen bei COSMIC</b></big>\n
Dieser Assistent hilft dir beim Einstieg in dein System.\n
<b>Hinweise:</b>\n
• Alle Anwendungen können später jederzeit über den COSMIC-Shop installiert oder entfernt werden.\n
• Der Assistent ist optional und erscheint nur einmal.\n
• Die Auswahl deckt gängige Anwendungen ab, aber nicht alles." \
  || abort

# ----------------------------
# Auswahl
# ----------------------------
BROWSERS=$(choose_list \
  "Browser" \
  "<big><b>Browser auswählen</b></big>\nWähle einen oder mehrere Webbrowser aus." \
  firefox "Mozilla Firefox (empfohlen)" \
  chromium "Chromium (Open-Source Basis)" \
  brave "Brave (datenschutzorientiert)" \
)

OFFICE=$(choose_list \
  "Office & Dokumente" \
  "<big><b>Office & Dokumente</b></big>\nWähle Anwendungen für Büroarbeit und PDFs." \
  libreoffice "LibreOffice (Office-Suite)" \
  onlyoffice "OnlyOffice (MS-Office-ähnlich)" \
  collabora "Collabora Office" \
  papers "Papers (PDF-Viewer)" \
  simplescan "Simple Scan" \
)

GRAPHICS=$(choose_list \
  "Grafik & Kreativ" \
  "<big><b>Grafik & Kreativ</b></big>\nWerkzeuge für Bildbearbeitung und Illustration." \
  gimp "GIMP" \
  krita "Krita" \
  inkscape "Inkscape" \
)

MEDIA=$(choose_list \
  "Medien & Unterhaltung" \
  "<big><b>Medien & Unterhaltung</b></big>\nAudio- und Video-Wiedergabe." \
  vlc "VLC Media Player" \
  showtime "Gnome Video Player" \
  spotify "Spotify Client" \
)

AV=$(choose_list \
  "Audio & Video-Bearbeitung" \
  "<big><b>Audio & Video-Bearbeitung</b></big>\nWerkzeuge für kreative Medienproduktion." \
  shotcut "Shotcut" \
  kdenlive "Kdenlive" \
  audacity "Audacity" \
  ardour "Ardour" \
)

GAMES=$(choose_list \
  "Spiele" \
  "<big><b>Spiele-Plattformen</b></big>\nWähle Plattformen für PC-Spiele." \
  steam "Steam" \
  lutris "Lutris" \
)

MAIL=$(choose_list \
  "E-Mail" \
  "<big><b>E-Mail-Programme</b></big>\nWähle einen oder mehrere Mail-Clients." \
  thunderbird "Thunderbird" \
  geary "Geary" \
  evolution "Evolution" \
)

DEV=$(choose_list \
  "Entwicklung" \
  "<big><b>Entwicklung</b></big>\nWerkzeuge für Software-Entwicklung." \
  vscode "Visual Studio Code" \
)

SYSTEM=$(choose_list \
  "System-Werkzeuge" \
  "<big><b>System-Werkzeuge</b></big>\nHilfsprogramme für Konfiguration und Verwaltung." \
  flatseal "Flatseal" \
)

# ----------------------------
# Homebrew
# ----------------------------
zenity --question \
  --title="Homebrew (optional)" \
  --text="<big><b>Homebrew installieren?</b></big>\n
Homebrew ist ein zusätzlicher Paketmanager für Entwickler- und CLI-Werkzeuge.\n
• Installation im Benutzerverzeichnis\n
• Keine Änderung am Basissystem\n
• Komplett optional" 

USE_BREW=$([[ $? -eq 0 ]] && echo yes || echo no)

# ----------------------------
# Auto-Update
# ----------------------------
zenity --question \
  --title="Automatische Systemaktualisierung" \
  --text="<big><b>Automatische Updates aktivieren?</b></big>\n
Wenn aktiviert, prüft das System einmal pro Woche auf neue Aktualisierungen und installiert sie automatisch.\n
<b>Manuelle Aktualisierung:</b>\n
<tt>bootc upgrade</tt>\n
<b>Dienst manuell starten:</b>\n
<tt>systemctl --user start bootc-update.service</tt>"

AUTO_UPDATE=$([[ $? -eq 0 ]] && echo yes || echo no)

# ----------------------------
# Summary
# ----------------------------
SUMMARY="Browser: ${BROWSERS:-keine}
Office: ${OFFICE:-keine}
Grafik: ${GRAPHICS:-keine}
Medien: ${MEDIA:-keine}
Audio/Video: ${AV:-keine}
Spiele: ${GAMES:-keine}
E-Mail: ${MAIL:-keine}
Entwicklung: ${DEV:-keine}
System: ${SYSTEM:-keine}

Homebrew: $USE_BREW
Automatische Updates: $AUTO_UPDATE"

zenity --question \
  --title="Zusammenfassung" \
  --text="<big><b>Bitte bestätige die Installation</b></big>\n\n$SUMMARY" \
  || abort

# ----------------------------
# Installation
# ----------------------------
ensure_flathub

(
  echo "10"; echo "# Installiere Browser..."
  for b in ${BROWSERS//|/ }; do
    [[ -z "$b" ]] && continue
    case "$b" in
      firefox)  flatpak install -y flathub org.mozilla.firefox ;;
      chromium) flatpak install -y flathub org.chromium.Chromium ;;
      brave)    flatpak install -y flathub com.brave.Browser ;;
    esac
  done

  echo "25"; echo "# Installiere Office..."
  for o in ${OFFICE//|/ }; do
    [[ -z "$o" ]] && continue
    case "$o" in
      libreoffice) flatpak install -y flathub org.libreoffice.LibreOffice ;;
      onlyoffice)  flatpak install -y flathub org.onlyoffice.desktopeditors ;;
      collabora)   flatpak install -y flathub com.collabora.CollaboraOffice ;;
      papers)      flatpak install -y flathub org.gnome.Papers ;;
      simplescan)  flatpak install -y flathub org.gnome.SimpleScan ;;
    esac
  done

  echo "40"; echo "# Installiere Grafik-Tools..."
  for g in ${GRAPHICS//|/ }; do
    [[ -z "$g" ]] && continue
    case "$g" in
      gimp)     flatpak install -y flathub org.gimp.GIMP ;;
      krita)    flatpak install -y flathub org.kde.krita ;;
      inkscape) flatpak install -y flathub org.inkscape.Inkscape ;;
    esac
  done

  echo "55"; echo "# Installiere Medien..."
  for m in ${MEDIA//|/ }; do
    [[ -z "$m" ]] && continue
    case "$m" in
      vlc)      flatpak install -y flathub org.videolan.VLC ;;
      spotify)  flatpak install -y flathub com.spotify.Client ;;
      showtime) flatpak install -y flathub org.gnome.Showtime ;;
    esac
  done

  echo "70"; echo "# Installiere Audio/Video-Tools..."
  for a in ${AV//|/ }; do
    [[ -z "$a" ]] && continue
    case "$a" in
      shotcut)  flatpak install -y flathub org.shotcut.Shotcut ;;
      kdenlive) flatpak install -y flathub org.kde.kdenlive ;;
      audacity) flatpak install -y flathub org.audacityteam.Audacity ;;
      ardour)   flatpak install -y flathub org.ardour.Ardour ;;
    esac
  done

  echo "85"; echo "# Installiere Spiele-Plattformen..."
  for g in ${GAMES//|/ }; do
    [[ -z "$g" ]] && continue
    case "$g" in
      steam)  flatpak install -y flathub com.valvesoftware.Steam ;;
      lutris) flatpak install -y flathub net.lutris.Lutris ;;
    esac
  done

  echo "90"; echo "# Installiere E-Mail-Clients..."
  for m in ${MAIL//|/ }; do
    [[ -z "$m" ]] && continue
    case "$m" in
      thunderbird) flatpak install -y flathub org.mozilla.Thunderbird ;;
      geary)       flatpak install -y flathub org.gnome.Geary ;;
      evolution)   flatpak install -y flathub org.gnome.Evolution ;;
    esac
  done

  echo "95"; echo "# Installiere Entwicklung..."
  for d in ${DEV//|/ }; do
    [[ -z "$d" ]] && continue
    case "$d" in
      vscode) flatpak install -y flathub com.visualstudio.code ;;
    esac
  done

  echo "97"; echo "# Installiere System-Werkzeuge..."
  for s in ${SYSTEM//|/ }; do
    [[ -z "$s" ]] && continue
    case "$s" in
      flatseal) flatpak install -y flathub com.github.tchx84.Flatseal ;;
    esac
  done

  echo "98"; echo "# Homebrew..."
  [[ "$USE_BREW" == yes ]] && install_brew_and_setup_path

  echo "100"; echo "# Fertig."
) | zenity --progress \
    --title="Installation läuft" \
    --text="Bitte warten..." \
    --percentage=0 \
    --auto-close

# ----------------------------
# Auto-Update aktivieren
# ----------------------------
if [[ "$AUTO_UPDATE" == yes ]]; then
  systemctl --user enable --now bootc-update.timer
fi

# ----------------------------
# Wizard done (sauberer Abschluss)
# ----------------------------
trap - EXIT
rm -f "$HOME/.config/firstboot/run"
systemctl --user disable firstboot-setup.service || true

zenity --info \
  --title="Fertig" \
  --text="<big><b>Die Einrichtung ist abgeschlossen.</b></big>\n
Weitere Anwendungen kannst du jederzeit über den COSMIC-Shop installieren.\n
<b>Homebrew aktualisieren:</b>\n
<tt>brew update && brew upgrade</tt>\n
Der Setup-Assistent wird nicht erneut gestartet."
