#!/usr/bin/env bash
set -euo pipefail

DIALOG=dialog
HEIGHT=20
WIDTH=74
LOG="/var/log/firstboot-setup.log"


if [[ -z "${TERM:-}" ]]; then
  exec cosmic-terminal -- /usr/libexec/firstboot-setup.sh
fi


exec > >(tee -a "$LOG") 2>&1

abort() {
  $DIALOG --title "Setup abbrechen?" --yesno \
"Der Einrichtungs‑Assistent wird dann
nicht erneut angezeigt.

Alle Anwendungen können jederzeit
über den COSMIC‑Shop installiert
oder entfernt werden.

Möchtest du den Setup‑Assistenten
wirklich abbrechen?" \
$HEIGHT $WIDTH

  if [[ $? -eq 0 ]]; then
    systemctl start firstboot-cleanup.service
    systemctl --user disable firstboot-setup.service
    clear
    exit 0
  fi

  # User hat sich gegen Abbruch entschieden → zurück
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
$DIALOG --title "Willkommen bei COSMIC" --msgbox \
"Dieser Assistent erleichtert dir den Einstieg,
indem er eine Auswahl gängiger Anwendungen anbietet.

Wichtig:
• Alle hier angebotenen Anwendungen können
  jederzeit auch über den COSMIC‑Shop installiert
  oder entfernt werden.
• Der Wizard ist optional und kann komplett
  übersprungen werden.
• Er deckt nur eine Auswahl verbreiteter
  Anwendungen ab – nicht alles.

Nach Abschluss wird dieser Assistent
nicht erneut angezeigt." \
$HEIGHT $WIDTH || abort

# ----------------------------
# Selections
# ----------------------------
BROWSERS=()
OFFICE=()
GRAPHICS=()
MEDIA=()
AV=()
GAMES=()
MAIL=()
DEV=()
SYSTEM=()

# ----------------------------
# Browser
# ----------------------------
BROWSERS=($($DIALOG --title "Browser" --checklist \
"Webbrowser werden für viele Aufgaben benötigt
(z. B. Dokumentation, Web‑Apps, Login‑Flows)." \
$HEIGHT $WIDTH 5 \
"firefox"  "Mozilla Firefox (empfohlen)" ON \
"chromium" "Chromium (Open‑Source Basis)" OFF \
"brave"    "Brave (datenschutzorientiert)" OFF \
2>&1 >/dev/tty)) || abort

# ----------------------------
# Office
# ----------------------------
OFFICE=($($DIALOG --title "Office & Dokumente" --checklist \
"Anwendungen für Dokumente, PDFs und Büroarbeit:" \
$HEIGHT $WIDTH 7 \
"libreoffice" "LibreOffice (Office‑Suite)" ON \
"onlyoffice"  "OnlyOffice (MS‑Office‑ähnlich)" OFF \
"collabora"   "Collabora Office (LibreOffice‑basiert)" OFF \
"papers"      "Papers (PDF‑Viewer)" ON \
"simplescan"  "Simple Scan (Scanner‑Anwendung)" OFF \
2>&1 >/dev/tty)) || abort

# ----------------------------
# Graphics
# ----------------------------
GRAPHICS=($($DIALOG --title "Grafik & Kreativ" --checklist \
"Bildbearbeitung, Illustration und Vektorgrafik:" \
$HEIGHT $WIDTH 5 \
"gimp"      "GIMP (Bildbearbeitung)" OFF \
"krita"     "Krita (Zeichnen & Illustration)" OFF \
"inkscape"  "Inkscape (Vektorgrafiken & SVG)" OFF \
2>&1 >/dev/tty)) || abort

# ----------------------------
# Media
# ----------------------------
MEDIA=($($DIALOG --title "Medien & Unterhaltung" --checklist \
"Wiedergabe von Audio und Video:" \
$HEIGHT $WIDTH 4 \
"vlc"     "VLC Media Player" ON \
"spotify" "Spotify Client" OFF \
2>&1 >/dev/tty)) || abort

# ----------------------------
# Audio / Video Editing
# ----------------------------
AV=($($DIALOG --title "Audio & Video‑Bearbeitung" --checklist \
"Erstellung und Bearbeitung von Audio‑ und Videoinhalten:" \
$HEIGHT $WIDTH 6 \
"shotcut"  "Shotcut (einfacher Video‑Editor)" OFF \
"kdenlive" "Kdenlive (leistungsfähiger Video‑Editor)" OFF \
"audacity" "Audacity (Audio‑Bearbeitung)" OFF \
"ardour"   "Ardour (professionelle Audio‑Produktion)" OFF \
2>&1 >/dev/tty)) || abort

# ----------------------------
# Games
# ----------------------------
GAMES=($($DIALOG --title "Spiele" --checklist \
"Plattformen für PC‑Spiele.

Hinweis:
• Für Steam und Lutris ist ein Benutzerkonto erforderlich.
• Es werden keine Spiele automatisch installiert." \
$HEIGHT $WIDTH 4 \
"steam"  "Steam (Valve‑Plattform)" OFF \
"lutris" "Lutris (Multi‑Plattform‑Launcher)" OFF \
2>&1 >/dev/tty)) || abort

# ----------------------------
# Mail
# ----------------------------
MAIL=($($DIALOG --title "E‑Mail" --checklist \
"Desktop‑E‑Mail‑Programme für IMAP/POP‑Konten:" \
$HEIGHT $WIDTH 5 \
"thunderbird" "Thunderbird (vollständiger Standard‑Client)" ON \
"geary"       "Geary (einfacher, moderner Mail‑Client)" OFF \
"evolution"   "Evolution (Business‑ & Exchange‑Client)" OFF \
2>&1 >/dev/tty)) || abort

# ----------------------------
# Development
# ----------------------------
DEV=($($DIALOG --title "Entwicklung" --checklist \
"Werkzeuge für Software‑Entwicklung:" \
$HEIGHT $WIDTH 4 \
"vscode" "Visual Studio Code" OFF \
2>&1 >/dev/tty)) || abort

# ----------------------------
# System Tools
# ----------------------------
SYSTEM=($($DIALOG --title "System‑Werkzeuge" --checklist \
"Hilfsprogramme für System‑Konfiguration:" \
$HEIGHT $WIDTH 4 \
"flatseal" "Flatseal (Flatpak‑Rechte verwalten)" OFF \
2>&1 >/dev/tty)) || abort

# ----------------------------
# Homebrew
# ----------------------------
USE_BREW=$($DIALOG --title "Homebrew (optional)" --yesno \
"Homebrew ist ein zusätzlicher Paketmanager
für Entwickler‑ und CLI‑Werkzeuge.

• Installation im Benutzerverzeichnis
• Keine Änderung am Basissystem
• Komplett optional" \
$HEIGHT $WIDTH && echo yes || echo no)

# ----------------------------
# Summary
# ----------------------------
SUMMARY="Browser: ${BROWSERS[*]:-keine}
Office: ${OFFICE[*]:-keine}
Grafik: ${GRAPHICS[*]:-keine}
Medien: ${MEDIA[*]:-keine}
Audio/Video: ${AV[*]:-keine}
Spiele: ${GAMES[*]:-keine}
E‑Mail: ${MAIL[*]:-keine}
Entwicklung: ${DEV[*]:-keine}
System: ${SYSTEM[*]:-keine}

Homebrew: $USE_BREW"

$DIALOG --title "Zusammenfassung" --yesno \
"Bitte bestätige die Installation:\n\n$SUMMARY" \
$HEIGHT $WIDTH || abort

# ----------------------------
# Installation
# ----------------------------
ensure_flathub

(
  echo "10"; echo "# Installiere Browser..."
  for b in "${BROWSERS[@]}"; do
    case "$b" in
      firefox)  flatpak install -y flathub org.mozilla.firefox ;;
      chromium) flatpak install -y flathub org.chromium.Chromium ;;
      brave)    flatpak install -y flathub com.brave.Browser ;;
    esac
  done

  echo "25"; echo "# Installiere Office..."
  [[ " ${OFFICE[*]} " == *" libreoffice "* ]] && flatpak install -y flathub org.libreoffice.LibreOffice
  [[ " ${OFFICE[*]} " == *" onlyoffice "*  ]] && flatpak install -y flathub org.onlyoffice.desktopeditors
  [[ " ${OFFICE[*]} " == *" collabora "*  ]] && flatpak install -y flathub com.collabora.CollaboraOffice
  [[ " ${OFFICE[*]} " == *" papers "*     ]] && flatpak install -y flathub org.gnome.Papers
  [[ " ${OFFICE[*]} " == *" simplescan "* ]] && flatpak install -y flathub org.gnome.SimpleScan

  echo "40"; echo "# Installiere Grafik‑Tools..."
  [[ " ${GRAPHICS[*]} " == *" gimp "*     ]] && flatpak install -y flathub org.gimp.GIMP
  [[ " ${GRAPHICS[*]} " == *" krita "*    ]] && flatpak install -y flathub org.kde.krita
  [[ " ${GRAPHICS[*]} " == *" inkscape "* ]] && flatpak install -y flathub org.inkscape.Inkscape

  echo "55"; echo "# Installiere Medien..."
  [[ " ${MEDIA[*]} " == *" vlc "*     ]] && flatpak install -y flathub org.videolan.VLC
  [[ " ${MEDIA[*]} " == *" spotify "* ]] && flatpak install -y flathub com.spotify.Client

  echo "70"; echo "# Installiere Audio/Video‑Tools..."
  [[ " ${AV[*]} " == *" shotcut "*  ]] && flatpak install -y flathub org.shotcut.Shotcut
  [[ " ${AV[*]} " == *" kdenlive "* ]] && flatpak install -y flathub org.kde.kdenlive
  [[ " ${AV[*]} " == *" audacity "* ]] && flatpak install -y flathub org.audacityteam.Audacity
  [[ " ${AV[*]} " == *" ardour "*   ]] && flatpak install -y flathub org.ardour.Ardour

  echo "85"; echo "# Installiere Spiele‑Plattformen..."
  [[ " ${GAMES[*]} " == *" steam "*  ]] && flatpak install -y flathub com.valvesoftware.Steam
  [[ " ${GAMES[*]} " == *" lutris "* ]] && flatpak install -y flathub net.lutris.Lutris

  echo "90"; echo "# Installiere E‑Mail‑Clients..."
  [[ " ${MAIL[*]} " == *" thunderbird "* ]] && flatpak install -y flathub org.mozilla.Thunderbird
  [[ " ${MAIL[*]} " == *" geary "*       ]] && flatpak install -y flathub org.gnome.Geary
  [[ " ${MAIL[*]} " == *" evolution "*   ]] && flatpak install -y flathub org.gnome.Evolution

  echo "95"; echo "# Installiere Entwicklung..."
  [[ " ${DEV[*]} " == *" vscode "* ]] && flatpak install -y flathub com.visualstudio.code

  echo "97"; echo "# Installiere System‑Tools..."
  [[ " ${SYSTEM[*]} " == *" flatseal "* ]] && flatpak install -y flathub com.github.tchx84.Flatseal

  echo "98"; echo "# Homebrew..."
  [[ "$USE_BREW" == yes ]] && install_brew_and_setup_path

  echo "100"; echo "# Fertig."
) | $DIALOG --title "Installation läuft" --gauge \
"Bitte warten..." \
$HEIGHT $WIDTH 0

# ----------------------------
# Mark wizard as done
# ----------------------------
systemctl start firstboot-cleanup.service
systemctl --user disable firstboot-setup.service

$DIALOG --title "Fertig" --msgbox \
"Die Einrichtung ist abgeschlossen.

Weitere Anwendungen kannst du jederzeit
über den COSMIC‑Shop installieren.

Updates:
• Installierte Anwendungen werden über den COSMIC‑Shop aktualisiert.
• Homebrew‑Pakete können mit folgendem Befehl aktualisiert werden:

  >>>>> brew update && brew upgrade <<<<<

Der Setup‑Wizard wird nicht erneut gestartet." \
$HEIGHT $WIDTH

clear
