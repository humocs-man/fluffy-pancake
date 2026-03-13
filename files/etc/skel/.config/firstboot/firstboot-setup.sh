#!/usr/bin/env bash
set -euo pipefail

LOG="$HOME/.local/state/firstboot-setup.log"

exec > >(tee -a "$LOG") 2>&1

abort() {
  zenity --question \
    --title="Setup abbrechen?" \
    --text="Der Einrichtungs‑Assistent wird dann nicht erneut angezeigt.

Alle Anwendungen können jederzeit über den COSMIC‑Shop installiert oder entfernt werden.

Möchtest du den Setup‑Assistenten wirklich abbrechen?"

  if [[ $? -eq 0 ]]; then
    rm -f "$HOME/.config/firstboot/run"
    systemctl --user disable firstboot-setup.service
    exit 0
  fi

  return 0
}

ensure_flathub() {
  flatpak remote-list --columns=name 2>/dev/null | grep -qx flathub || \
    flatpak remote-add --if-not-exists flathub \
      https://dl.flathub.org/repo/flathub.flatpakrepo
}

install_brew_and_setup_path() {
  if ! command -v brew >/dev/null 2>&1; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
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

# ----------------------------
# Welcome
# ----------------------------
zenity --info \
  --title="Willkommen bei COSMIC" \
  --text="Dieser Assistent erleichtert dir den Einstieg, indem er eine Auswahl gängiger Anwendungen anbietet.

Wichtig:
• Alle hier angebotenen Anwendungen können jederzeit auch über den COSMIC‑Shop installiert oder entfernt werden.
• Der Wizard ist optional und kann komplett übersprungen werden.
• Er deckt nur eine Auswahl verbreiteter Anwendungen ab – nicht alles.

Nach Abschluss wird dieser Assistent nicht erneut angezeigt." \
  || abort

# ----------------------------
# Auswahlfunktionen
# ----------------------------

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

  echo "$result"
}

# ----------------------------
# Browser
# ----------------------------
BROWSERS=$(choose_list \
  "Browser" \
  "Webbrowser werden für viele Aufgaben benötigt." \
  firefox "Mozilla Firefox (empfohlen)" \
  chromium "Chromium (Open‑Source Basis)" \
  brave "Brave (datenschutzorientiert)" \
)

# ----------------------------
# Office
# ----------------------------
OFFICE=$(choose_list \
  "Office & Dokumente" \
  "Anwendungen für Dokumente, PDFs und Büroarbeit:" \
  libreoffice "LibreOffice (Office‑Suite)" \
  onlyoffice "OnlyOffice (MS‑Office‑ähnlich)" \
  collabora "Collabora Office" \
  papers "Papers (PDF‑Viewer)" \
  simplescan "Simple Scan" \
)

# ----------------------------
# Graphics
# ----------------------------
GRAPHICS=$(choose_list \
  "Grafik & Kreativ" \
  "Bildbearbeitung, Illustration und Vektorgrafik:" \
  gimp "GIMP" \
  krita "Krita" \
  inkscape "Inkscape" \
)

# ----------------------------
# Media
# ----------------------------
MEDIA=$(choose_list \
  "Medien & Unterhaltung" \
  "Wiedergabe von Audio und Video:" \
  vlc "VLC Media Player" \
  spotify "Spotify Client" \
)

# ----------------------------
# Audio/Video Editing
# ----------------------------
AV=$(choose_list \
  "Audio & Video‑Bearbeitung" \
  "Erstellung und Bearbeitung von Audio‑ und Videoinhalten:" \
  shotcut "Shotcut" \
  kdenlive "Kdenlive" \
  audacity "Audacity" \
  ardour "Ardour" \
)

# ----------------------------
# Games
# ----------------------------
GAMES=$(choose_list \
  "Spiele" \
  "Plattformen für PC‑Spiele:" \
  steam "Steam" \
  lutris "Lutris" \
)

# ----------------------------
# Mail
# ----------------------------
MAIL=$(choose_list \
  "E‑Mail" \
  "Desktop‑E‑Mail‑Programme:" \
  thunderbird "Thunderbird" \
  geary "Geary" \
  evolution "Evolution" \
)

# ----------------------------
# Development
# ----------------------------
DEV=$(choose_list \
  "Entwicklung" \
  "Werkzeuge für Software‑Entwicklung:" \
  vscode "Visual Studio Code" \
)

# ----------------------------
# System Tools
# ----------------------------
SYSTEM=$(choose_list \
  "System‑Werkzeuge" \
  "Hilfsprogramme für System‑Konfiguration:" \
  flatseal "Flatseal" \
)

# ----------------------------
# Homebrew
# ----------------------------
zenity --question \
  --title="Homebrew (optional)" \
  --text="Homebrew ist ein zusätzlicher Paketmanager für Entwickler‑ und CLI‑Werkzeuge.

• Installation im Benutzerverzeichnis
• Keine Änderung am Basissystem
• Komplett optional"

USE_BREW=$([[ $? -eq 0 ]] && echo yes || echo no)

# ----------------------------
# Summary
# ----------------------------
SUMMARY="Browser: ${BROWSERS:-keine}
Office: ${OFFICE:-keine}
Grafik: ${GRAPHICS:-keine}
Medien: ${MEDIA:-keine}
Audio/Video: ${AV:-keine}
Spiele: ${GAMES:-keine}
E‑Mail: ${MAIL:-keine}
Entwicklung: ${DEV:-keine}
System: ${SYSTEM:-keine}

Homebrew: $USE_BREW"

zenity --question \
  --title="Zusammenfassung" \
  --text="Bitte bestätige die Installation:\n\n$SUMMARY" \
  || abort

# ----------------------------
# Installation
# ----------------------------
ensure_flathub

(
  echo "10"; echo "# Installiere Browser..."
  for b in ${BROWSERS//|/ }; do
    case "$b" in
      firefox)  flatpak install -y flathub org.mozilla.firefox ;;
      chromium) flatpak install -y flathub org.chromium.Chromium ;;
      brave)    flatpak install -y flathub com.brave.Browser ;;
    esac
  done

  echo "25"; echo "# Installiere Office..."
  [[ "$OFFICE" == *libreoffice* ]] && flatpak install -y flathub org.libreoffice.LibreOffice
  [[ "$OFFICE" == *onlyoffice* ]]  && flatpak install -y flathub org.onlyoffice.desktopeditors
  [[ "$OFFICE" == *collabora* ]]   && flatpak install -y flathub com.collabora.CollaboraOffice
  [[ "$OFFICE" == *papers* ]]      && flatpak install -y flathub org.gnome.Papers
  [[ "$OFFICE" == *simplescan* ]]  && flatpak install -y flathub org.gnome.SimpleScan

  echo "40"; echo "# Installiere Grafik‑Tools..."
  [[ "$GRAPHICS" == *gimp* ]]     && flatpak install -y flathub org.gimp.GIMP
  [[ "$GRAPHICS" == *krita* ]]    && flatpak install -y flathub org.kde.krita
  [[ "$GRAPHICS" == *inkscape* ]] && flatpak install -y flathub org.inkscape.Inkscape

  echo "55"; echo "# Installiere Medien..."
  [[ "$MEDIA" == *vlc* ]]     && flatpak install -y flathub org.videolan.VLC
  [[ "$MEDIA" == *spotify* ]] && flatpak install -y flathub com.spotify.Client

  echo "70"; echo "# Installiere Audio/Video‑Tools..."
  [[ "$AV" == *shotcut* ]]  && flatpak install -y flathub org.shotcut.Shotcut
  [[ "$AV" == *kdenlive* ]] && flatpak install -y flathub org.kde.kdenlive
  [[ "$AV" == *audacity* ]] && flatpak install -y flathub org.audacityteam.Audacity
  [[ "$AV" == *ardour* ]]   && flatpak install -y flathub org.ardour.Ardour

  echo "85"; echo "# Installiere Spiele‑Plattformen..."
  [[ "$GAMES" == *steam* ]]  && flatpak install -y flathub com.valvesoftware.Steam
  [[ "$GAMES" == *lutris* ]] && flatpak install -y flathub net.lutris.Lutris

  echo "90"; echo "# Installiere E‑Mail‑Clients..."
  [[ "$MAIL" == *thunderbird* ]] && flatpak install -y flathub org.mozilla.Thunderbird
  [[ "$MAIL" == *geary* ]]       && flatpak install -y flathub org.gnome.Geary
  [[ "$MAIL" == *evolution* ]]   && flatpak install -y flathub org.gnome.Evolution

  echo "95"; echo "# Installiere Entwicklung..."
  [[ "$DEV" == *vscode* ]] && flatpak install -y flathub com.visualstudio.code

  echo "97"; echo "# Installiere System‑Tools..."
  [[ "$SYSTEM" == *flatseal* ]] && flatpak install -y flathub com.github.tchx84.Flatseal

  echo "98"; echo "# Homebrew..."
  [[ "$USE_BREW" == yes ]] && install_brew_and_setup_path

  echo "100"; echo "# Fertig."
) | zenity --progress \
    --title="Installation läuft" \
    --text="Bitte warten..." \
    --percentage=0 \
    --auto-close

# ----------------------------
# Mark wizard as done
# ----------------------------
rm -f "$HOME/.config/firstboot/run"
systemctl --user disable firstboot-setup.service

zenity --info \
  --title="Fertig" \
  --text="Die Einrichtung ist abgeschlossen.

Weitere Anwendungen kannst du jederzeit über den COSMIC‑Shop installieren.

Updates:
• Installierte Anwendungen werden über den COSMIC‑Shop aktualisiert.
• Homebrew‑Pakete können mit folgendem Befehl aktualisiert werden:

  brew update && brew upgrade

Der Setup‑Wizard wird nicht erneut gestartet."
