#!/usr/bin/env bash
set -euo pipefail

LOG="$HOME/.local/state/firstboot-setup.log"
mkdir -p "$(dirname "$LOG")"
exec > >(tee -a "$LOG") 2>&1

# ------------------------------------------------------------
# Session check
# ------------------------------------------------------------
if [[ -z "${WAYLAND_DISPLAY:-}" && -z "${DISPLAY:-}" ]]; then
  echo "Keine grafische Session verfügbar – breche ab."
  exit 1
fi

# ------------------------------------------------------------
# Globaler Abbruch – beendet den Wizard vollständig
# ------------------------------------------------------------
abort() {
  echo "Abbruch durch Benutzer."

  zenity --question \
    --title="Setup abbrechen?" \
    --text="<big><b>Setup abbrechen?</b></big>\n
Der Einrichtungs‑Assistent wird dann nicht erneut angezeigt.\n
Alle Anwendungen können jederzeit über den COSMIC‑Shop installiert oder entfernt werden.\n
Möchtest du den Setup‑Assistenten wirklich abbrechen?" \
    >/dev/null 2>&1 || true

  rm -f "$HOME/.config/firstboot/run"
  systemctl --user disable firstboot-setup.service >/dev/null 2>&1 || true
  exit 1
}

# ------------------------------------------------------------
# Cleanup bei Fehlern
# ------------------------------------------------------------
cleanup() {
  local code=$?
  if [[ $code -ne 0 ]]; then
    rm -f "$HOME/.config/firstboot/run"
    systemctl --user disable firstboot-setup.service >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

# ------------------------------------------------------------
# Helper
# ------------------------------------------------------------
ensure_flathub() {
  flatpak remote-list --columns=name 2>/dev/null | grep -qx flathub || \
    flatpak remote-add --if-not-exists flathub \
      https://dl.flathub.org/repo/flathub.flatpakrepo
}

install_brew_and_setup_path() {
  if ! command -v brew >/dev/null 2>&1; then
    NONINTERACTIVE=1 CI=1 /bin/bash -c \
      "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
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

# ------------------------------------------------------------
# Zenity‑Checkliste
# Erwartet Paare: id "beschreibung"
# ------------------------------------------------------------
choose_list() {
  local title="$1"
  local text="$2"
  shift 2

  if (( $# % 2 != 0 )); then
    echo "choose_list: Ungerade Anzahl Argumente." >&2
    exit 1
  fi

  local -a rows=()
  while (( $# )); do
    rows+=(FALSE "$1" "$2")
    shift 2
  done

  zenity --list \
    --title="$title" \
    --text="$text" \
    --checklist \
    --column="Auswahl" \
    --column="Anwendung" \
    --column="Beschreibung" \
    --separator="|" \
    "${rows[@]}" \
  || abort
}

# ------------------------------------------------------------
# Welcome
# ------------------------------------------------------------
zenity --info \
  --title="Willkommen bei COSMIC" \
  --text="<big><b>Willkommen bei COSMIC</b></big>\n
Dieser Assistent hilft dir beim Einstieg in dein System.\n
<b>Hinweise:</b>\n
• Alle Anwendungen können später jederzeit über den COSMIC‑Shop installiert oder entfernt werden.\n
• Der Assistent ist optional und erscheint nur einmal.\n
• Die Auswahl deckt gängige Anwendungen ab, aber nicht alles." \
  || abort

# ------------------------------------------------------------
# Auswahl
# ------------------------------------------------------------
BROWSERS=$(choose_list \
  "Browser" \
  "<big><b>Browser auswählen</b></big>\nWähle einen oder mehrere Webbrowser aus." \
  firefox  "Ausgewogen, weit verbreitet, guter Datenschutz" \
  chromium "Schlank, schnell, Open‑Source‑Basis vieler Browser" \
  brave    "Starker Fokus auf Datenschutz und Werbeblockierung" \
)

OFFICE=$(choose_list \
  "Office & Dokumente" \
  "<big><b>Office &amp; Dokumente</b></big>\nAnwendungen für Büroarbeit und PDFs." \
  libreoffice "Umfangreiche Office‑Suite für lokale Dokumente" \
  onlyoffice  "Moderne Oberfläche, hohe MS‑Office‑Kompatibilität" \
  collabora   "LibreOffice‑Technologie mit Fokus auf Zusammenarbeit" \
  papers      "Leichter PDF‑Viewer zum Lesen und Kommentieren" \
  simplescan  "Einfaches Scannen von Dokumenten und Bildern" \
)

GRAPHICS=$(choose_list \
  "Grafik & Kreativ" \
  "<big><b>Grafik &amp; Kreativ</b></big>\nWerkzeuge für Bildbearbeitung und Illustration." \
  gimp     "Leistungsstarke Bildbearbeitung für Fotos" \
  krita    "Digitale Malerei und Illustration" \
  inkscape "Vektorgrafiken für Logos und Icons" \
)

MEDIA=$(choose_list \
  "Medien & Unterhaltung" \
  "<big><b>Medien &amp; Unterhaltung</b></big>\nAudio‑ und Video‑Wiedergabe." \
  vlc      "Spielt nahezu alle Audio‑ und Videoformate ab" \
  showtime "Einfacher Videoplayer mit klarer Oberfläche" \
  spotify  "Streaming‑Dienst für Musik und Podcasts" \
)

AV=$(choose_list \
  "Audio & Video‑Bearbeitung" \
  "<big><b>Audio &amp; Video‑Bearbeitung</b></big>\nWerkzeuge für kreative Medienproduktion." \
  shotcut  "Einfacher Videoeditor für schnelle Projekte" \
  kdenlive "Umfangreicher Videoeditor mit vielen Effekten" \
  audacity "Aufnahme und Bearbeitung von Audio" \
  ardour   "Professionelle Audio‑Produktion" \
)

GAMES=$(choose_list \
  "Spiele" \
  "<big><b>Spiele‑Plattformen</b></big>\nPlattformen für PC‑Spiele." \
  steam  "Große Spielebibliothek und Community‑Funktionen" \
  lutris "Zentrale Verwaltung von Spielen aus vielen Quellen" \
)

MAIL=$(choose_list \
  "E‑Mail" \
  "<big><b>E‑Mail‑Programme</b></big>\nDesktop‑Clients für E‑Mail und Kalender." \
  thunderbird "Leistungsstarker Mail‑Client mit Erweiterungen" \
  geary       "Schlanker Mail‑Client mit einfacher Bedienung" \
  evolution   "E‑Mail, Kalender und Kontakte in einer Anwendung" \
)

DEV=$(choose_list \
  "Entwicklung" \
  "<big><b>Entwicklung</b></big>\nWerkzeuge für Software‑Entwicklung." \
  vscode "Beliebter Code‑Editor mit vielen Erweiterungen" \
)

SYSTEM=$(choose_list \
  "System‑Werkzeuge" \
  "<big><b>System‑Werkzeuge</b></big>\nHilfsprogramme für Konfiguration und Verwaltung." \
  flatseal "Verwaltung von Flatpak‑Berechtigungen" \
)

# ------------------------------------------------------------
# Installation
# ------------------------------------------------------------
ensure_flathub

(
  echo "10"; echo "# Installiere Anwendungen…"

  for b in ${BROWSERS//|/ }; do
    case "$b" in
      firefox)  flatpak install -y flathub org.mozilla.firefox ;;
      chromium) flatpak install -y flathub org.chromium.Chromium ;;
      brave)    flatpak install -y flathub com.brave.Browser ;;
    esac
  done

  for o in ${OFFICE//|/ }; do
    case "$o" in
      libreoffice) flatpak install -y flathub org.libreoffice.LibreOffice ;;
      onlyoffice)  flatpak install -y flathub org.onlyoffice.desktopeditors ;;
      collabora)   flatpak install -y flathub com.collabora.CollaboraOffice ;;
      papers)      flatpak install -y flathub org.gnome.Papers ;;
      simplescan)  flatpak install -y flathub org.gnome.SimpleScan ;;
    esac
  done

  for g in ${GRAPHICS//|/ }; do
    case "$g" in
      gimp)     flatpak install -y flathub org.gimp.GIMP ;;
      krita)    flatpak install -y flathub org.kde.krita ;;
      inkscape) flatpak install -y flathub org.inkscape.Inkscape ;;
    esac
  done

  for m in ${MEDIA//|/ }; do
    case "$m" in
      vlc)      flatpak install -y flathub org.videolan.VLC ;;
      showtime) flatpak install -y flathub org.gnome.Showtime ;;
      spotify)  flatpak install -y flathub com.spotify.Client ;;
    esac
  done

  for a in ${AV//|/ }; do
    case "$a" in
      shotcut)  flatpak install -y flathub org.shotcut.Shotcut ;;
      kdenlive) flatpak install -y flathub org.kde.kdenlive ;;
      audacity) flatpak install -y flathub org.audacityteam.Audacity ;;
      ardour)   flatpak install -y flathub org.ardour.Ardour ;;
    esac
  done

  for g in ${GAMES//|/ }; do
    case "$g" in
      steam)  flatpak install -y flathub com.valvesoftware.Steam ;;
      lutris) flatpak install -y flathub net.lutris.Lutris ;;
    esac
  done

  for m in ${MAIL//|/ }; do
    case "$m" in
      thunderbird) flatpak install -y flathub org.mozilla.Thunderbird ;;
      geary)       flatpak install -y flathub org.gnome.Geary ;;
      evolution)   flatpak install -y flathub org.gnome.Evolution ;;
    esac
  done

  for d in ${DEV//|/ }; do
    [[ "$d" == vscode ]] && flatpak install -y flathub com.visualstudio.code
  done

  for s in ${SYSTEM//|/ }; do
    [[ "$s" == flatseal ]] && flatpak install -y flathub com.github.tchx84.Flatseal
  done

  echo "100"; echo "# Fertig."
) | zenity --progress \
    --title="Installation läuft" \
    --text="Bitte warten…" \
    --percentage=0 \
    --auto-close

# ------------------------------------------------------------
# Wizard done
# ------------------------------------------------------------
trap - EXIT
rm -f "$HOME/.config/firstboot/run"
systemctl --user disable firstboot-setup.service >/dev/null 2>&1 || true

zenity --info \
  --title="Fertig" \
  --text="<big><b>Die Einrichtung ist abgeschlossen.</b></big>\n
Weitere Anwendungen kannst du jederzeit über den COSMIC‑Shop installieren.\n
Der Setup‑Assistent wird nicht erneut gestartet."
