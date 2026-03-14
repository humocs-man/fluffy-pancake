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
# Abbruchdialog
#   Ja   -> Wizard beenden
#   Nein -> zurück zur aktuellen Liste (return 2)
# ------------------------------------------------------------
abort() {
  if zenity --question \
    --title="Setup abbrechen?" \
    --text="<big><b>Setup abbrechen?</b></big>\n
Der Einrichtungs‑Assistent wird dann nicht erneut angezeigt.\n
Alle Anwendungen können jederzeit über den COSMIC‑Shop installiert oder entfernt werden.\n
Möchtest du den Setup‑Assistenten wirklich abbrechen?"
  then
    rm -f "$HOME/.config/firstboot/run"
    systemctl --user disable firstboot-setup.service >/dev/null 2>&1 || true
    exit 1
  else
    return 2
  fi
}

# ------------------------------------------------------------
# Helper
# ------------------------------------------------------------
ensure_flathub() {
  flatpak remote-list --columns=name 2>/dev/null | grep -qx flathub || \
    flatpak remote-add --if-not-exists flathub \
      https://dl.flathub.org/repo/flathub.flatpakrepo
}

# ------------------------------------------------------------
# Zenity‑Checkliste
#   OK     -> stdout = Auswahl, return 0
#   Cancel -> abort(); Nein => return 2
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

  local result
  if result=$(zenity --list \
      --title="$title" \
      --text="$text" \
      --width=800 \
      --height=600 \
      --checklist \
      --column="Auswahl" \
      --column="Anwendung" \
      --column="Beschreibung" \
      --separator="|" \
      "${rows[@]}"); then
    printf '%s\n' "$result"
    return 0
  else
    abort
    return 2
  fi
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
# Auswahl-Runner
#   return 0 -> weiter
#   return 2 -> gleiche Liste erneut
# ------------------------------------------------------------
run_list() {
  local varname="$1"
  shift

  while true; do
    local result
    if result=$(choose_list "$@"); then
      printf -v "$varname" "%s" "$result"
      break
    else
      local code=$?
      if [[ $code -eq 2 ]]; then
        continue
      fi
      exit 1
    fi
  done
}

# ------------------------------------------------------------
# Listen
# ------------------------------------------------------------
run_list BROWSERS \
  "Browser" \
  "<big><b>Browser auswählen</b></big>\nWähle einen oder mehrere Webbrowser aus." \
  firefox  "Ausgewogen, weit verbreitet, guter Datenschutz" \
  chromium "Schlank, schnell, Open‑Source‑Basis vieler Browser" \
  brave    "Starker Fokus auf Datenschutz und Werbeblockierung"

run_list OFFICE \
  "Office & Dokumente" \
  "<big><b>Office &amp; Dokumente</b></big>\nAnwendungen für Büroarbeit und PDFs." \
  libreoffice "Umfangreiche Office‑Suite für lokale Dokumente" \
  onlyoffice  "Moderne Oberfläche, hohe MS‑Office‑Kompatibilität" \
  collabora   "LibreOffice‑Technologie mit Fokus auf Zusammenarbeit" \
  papers      "Leichter PDF‑Viewer zum Lesen und Kommentieren" \
  simplescan  "Einfaches Scannen von Dokumenten und Bildern"

run_list GRAPHICS \
  "Grafik & Kreativ" \
  "<big><b>Grafik &amp; Kreativ</b></big>\nWerkzeuge für Bildbearbeitung und Illustration." \
  gimp     "Leistungsstarke Bildbearbeitung für Fotos" \
  krita    "Digitale Malerei und Illustration" \
  inkscape "Vektorgrafiken für Logos und Icons"

run_list MEDIA \
  "Medien & Unterhaltung" \
  "<big><b>Medien &amp; Unterhaltung</b></big>\nAudio‑ und Video‑Wiedergabe." \
  vlc      "Spielt nahezu alle Audio‑ und Videoformate ab" \
  showtime "Einfacher Videoplayer mit klarer Oberfläche" \
  spotify  "Streaming‑Dienst für Musik und Podcasts"

run_list AV \
  "Audio & Video‑Bearbeitung" \
  "<big><b>Audio &amp; Video‑Bearbeitung</b></big>\nWerkzeuge für kreative Medienproduktion." \
  shotcut  "Einfacher Videoeditor für schnelle Projekte" \
  kdenlive "Umfangreicher Videoeditor mit vielen Effekten" \
  audacity "Aufnahme und Bearbeitung von Audio" \
  ardour   "Professionelle Audio‑Produktion"

run_list GAMES \
  "Spiele" \
  "<big><b>Spiele‑Plattformen</b></big>\nPlattformen für PC‑Spiele." \
  steam  "Große Spielebibliothek und Community‑Funktionen" \
  lutris "Zentrale Verwaltung von Spielen aus vielen Quellen" \
  sober "Spiele Roblox auf Linux"

run_list MAIL \
  "E‑Mail" \
  "<big><b>E‑Mail‑Programme</b></big>\nDesktop‑Clients für E‑Mail und Kalender." \
  thunderbird "Leistungsstarker Mail‑Client mit Erweiterungen" \
  geary       "Schlanker Mail‑Client mit einfacher Bedienung" \
  evolution   "E‑Mail, Kalender und Kontakte in einer Anwendung"

run_list KI \
  "Anwendungen für lokale KI" \
  "<big><b>KI-Anwenungen</b></big>\nProgramme für lokale KI-Anwendungen" \
  alpaca "All-In-One-Anwendung für lokale Chat- und RAG-Nutzung" \
  gpt4all "All-In-One-Anwendung von NomicAI"

run_list DEV \
  "Entwicklung" \
  "<big><b>Entwicklung</b></big>\nWerkzeuge für Software‑Entwicklung." \
  vscode "Beliebter Code‑Editor mit vielen Erweiterungen"

run_list SYSTEM \
  "System‑Werkzeuge" \
  "<big><b>System‑Werkzeuge</b></big>\nHilfsprogramme für Konfiguration und Verwaltung." \
  flatseal "Verwaltung von Flatpak‑Berechtigungen"


if zenity --question \
  --title="Homebrew installieren?" \
  --width=500 \
  --text="<big><b>Homebrew installieren?</b></big>\n
Homebrew ist ein Paketmanager für Kommandozeilen‑Werkzeuge.\n
Er eignet sich besonders für Entwickler und fortgeschrittene Nutzer.\n
\n
Möchtest du Homebrew installieren?"
then
  echo "Installiere Homebrew (non‑interactive)…"
  NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  echo "Homebrew wird nicht installiert."
fi

if zenity --question \
  --title="Automatische Updates aktivieren?" \
  --width=500 \
  --text="<big><b>Automatische System‑Updates</b></big>\n
Das System kann regelmäßig image‑basierte Updates automatisch installieren.\n
\n
Empfohlen für die meisten Nutzer.\n
\n
Möchtest du automatische Updates aktivieren?"
then
  echo "Aktiviere automatische Updates…"
  systemctl enable --now bootc-update.timer
else
  echo "Automatische Updates bleiben deaktiviert."
fi

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
      sober) flatpak install -y flathub org.vinegarhq.Sober ;;
    esac
  done

  for m in ${MAIL//|/ }; do
    case "$m" in
      thunderbird) flatpak install -y flathub org.mozilla.Thunderbird ;;
      geary)       flatpak install -y flathub org.gnome.Geary ;;
      evolution)   flatpak install -y flathub org.gnome.Evolution ;;
    esac
  done

  for m in ${KI//|/ }; do
    case "$m" in
      alpaca) flatpak install -y flathub com.jeffser.Alpaca ;;
      gpt4all) flatpak install -y flathub io.gpt4all.gpt4all ;;
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
rm -f "$HOME/.config/firstboot/run"
systemctl --user disable firstboot-setup.service >/dev/null 2>&1 || true

zenity --info \
  --title="Fertig" \
  --text="<big><b>Die Einrichtung ist abgeschlossen.</b></big>\n
Weitere Anwendungen kannst du jederzeit über den COSMIC‑Shop installieren.\n
Der Setup‑Assistent wird nicht erneut gestartet."
