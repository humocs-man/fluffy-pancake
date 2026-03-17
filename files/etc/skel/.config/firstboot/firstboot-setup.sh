#!/usr/bin/env bash
set -euo pipefail

LOG="$HOME/.local/state/firstboot-setup.log"
mkdir -p "$(dirname "$LOG")"
exec > >(tee -a "$LOG") 2>&1

# ------------------------------------------------------------
# WICHTIG: Dynamisches Warten auf Flatpak-Bereitschaft
# ------------------------------------------------------------
echo "=== Initialisiere User-Session und Flatpak ===" >&2

MAX_WAIT=60
WAITED=0

while [[ $WAITED -lt $MAX_WAIT ]]; do
  if systemctl --user is-active >/dev/null 2>&1; then
    if flatpak --version >/dev/null 2>&1; then
      echo "✓ Flatpak ist nach $WAITED Sekunden bereit." >&2
      break
    fi
    
    echo "$(date +%T.%N) - Flatpak nicht verfügbar, starte Dienst..." >&2
    systemctl --user start org.freedesktop.Flatpak.service 2>&1 || true
    sleep 3
  fi
  
  ((WAITED++)) || true
  sleep 1
  
  if [[ $((MAX_WAIT - WAITED)) -le 5 ]]; then
    echo "⚠️  Wartezeit läuft kurz ($WAITED/$MAX_WAIT)..." >&2
  fi
done

if [[ $WAITED -ge $MAX_WAIT ]]; then
  echo "❌ FATAL: Flatpak konnte nicht innerhalb von $MAX_WAIT Sekunden initialisiert werden!" >&2
  exit 1
fi

# ------------------------------------------------------------
# XDG-Umgebung sicherstellen
# ------------------------------------------------------------
export HOME="$HOME"
export USER=$(whoami)
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"

mkdir -p "$XDG_DATA_HOME"
mkdir -p "$(dirname "$LOG")"

echo "✓ XDG-Umgebung konfiguriert: XDG_DATA_HOME=$XDG_DATA_HOME" >&2


# ------------------------------------------------------------
# Helper-Funktionen mit besserer Fehlerbehandlung
# ------------------------------------------------------------
ensure_flathub() {
  if ! flatpak remote-list --columns=name 2>/dev/null | grep -qx flathub; then
    echo "Aktiviere Flathub..." >&2
    flatpak remote-add --if-not-exists flathub \
      https://dl.flathub.org/repo/flathub.flatapkrepo || {
        echo "❌ FATAL: Konnte Flathub nicht aktivieren!" >&2
        exit 1
      }
  fi
  
  # Warte kurz, bis das Repository geladen ist (wichtig!)
  sleep 5
}

flatpak_user_install() {
  local remote="$1"
  local app="$2"

  export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"

  if flatpak info --user "$app" >/dev/null 2>&1; then
    echo "Flatpak (user) bereits installiert: $app"
    return 0
  fi

  echo "Installiere Flatpak (user): $app" >&2
  
  # Füge Fehlerbehandlung hinzu
  if ! flatpak install --user -y "$remote" "$app"; then
    echo "❌ FATAL: Flatpak-Installation fehlgeschlagen: $app" >&2
    
    # Versuche, das Problem zu diagnostizieren
    echo "Diagnose..." >&2
    flatpak search "$app" || true
    exit 1 
  fi
  
  echo "✓ Installation erfolgreich: $app" >&2
}

# ------------------------------------------------------------
# Rest des Skripts (wie zuvor) ...


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

    # WICHTIG: Alle Zeilen zusammenführen → eine einzige Zeile
    echo "$result" | tr -d '\n'
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
      [[ $code -eq 2 ]] && continue
      exit 1
    fi
  done
}

# ------------------------------------------------------------
# Listen
# ------------------------------------------------------------
run_list BROWSERS_LIST \
  "Browser" \
  "<big><b>Browser auswählen</b></big>\nWähle einen oder mehrere Webbrowser aus." \
  firefox  "Ausgewogen, weit verbreitet, guter Datenschutz" \
  chromium "Schlank, schnell, Open‑Source‑Basis vieler Browser" \
  brave    "Starker Fokus auf Datenschutz und Werbeblockierung"

run_list OFFICE_LIST \
  "Office & Dokumente" \
  "<big><b>Office &amp; Dokumente</b></big>\nAnwendungen für Büroarbeit und PDFs." \
  libreoffice "Umfangreiche Office‑Suite für lokale Dokumente" \
  onlyoffice  "Moderne Oberfläche, hohe MS‑Office‑Kompatibilität" \
  collabora   "LibreOffice‑Technologie mit Fokus auf Zusammenarbeit" \
  papers      "Leichter PDF‑Viewer zum Lesen und Kommentieren" \
  simplescan  "Einfaches Scannen von Dokumenten und Bildern"

run_list GRAPHICS_LIST \
  "Grafik & Kreativ" \
  "<big><b>Grafik &amp; Kreativ</b></big>\nWerkzeuge für Bildbearbeitung und Illustration." \
  gimp     "Leistungsstarke Bildbearbeitung für Fotos" \
  krita    "Digitale Malerei und Illustration" \
  inkscape "Vektorgrafiken für Logos und Icons"

run_list MEDIA_LIST \
  "Medien & Unterhaltung" \
  "<big><b>Medien &amp; Unterhaltung</b></big>\nAudio‑ und Video‑Wiedergabe." \
  vlc      "Spielt nahezu alle Audio‑ und Videoformate ab" \
  showtime "Einfacher Videoplayer mit klarer Oberfläche" \
  spotify  "Streaming‑Dienst für Musik und Podcasts"

run_list AV_LIST \
  "Audio & Video‑Bearbeitung" \
  "<big><b>Audio &amp; Video‑Bearbeitung</b></big>\nWerkzeuge für kreative Medienproduktion." \
  shotcut  "Einfacher Videoeditor für schnelle Projekte" \
  kdenlive "Umfangreicher Videoeditor mit vielen Effekten" \
  audacity "Aufnahme und Bearbeitung von Audio" \
  ardour   "Professionelle Audio‑Produktion"

run_list GAMES_LIST \
  "Spiele" \
  "<big><b>Spiele‑Plattformen</b></big>\nPlattformen für PC‑Spiele." \
  steam  "Große Spielebibliothek und Community‑Funktionen" \
  lutris "Zentrale Verwaltung von Spielen aus vielen Quellen" \
  sober "Spiele Roblox auf Linux"

run_list MAIL_LIST \
  "E‑Mail" \
  "<big><b>E‑Mail‑Programme</b></big>\nDesktop‑Clients für E‑Mail und Kalender." \
  thunderbird "Leistungsstarker Mail‑Client mit Erweiterungen" \
  geary       "Schlanker Mail‑Client mit einfacher Bedienung" \
  evolution   "E‑Mail, Kalender und Kontakte in einer Anwendung"

run_list KI_LIST \
  "Anwendungen für lokale KI" \
  "<big><b>KI-Anwenungen</b></big>\nProgramme für lokale KI-Anwendungen" \
  alpaca "All-In-One-Anwendung für lokale Chat- und RAG-Nutzung" \
  gpt4all "All-In-One-Anwendung von NomicAI"

run_list DEV_LIST \
  "Entwicklung" \
  "<big><b>Entwicklung</b></big>\nWerkzeuge für Software‑Entwicklung." \
  vscode "Beliebter Code‑Editor mit vielen Erweiterungen"

run_list SYSTEM_LIST \
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
  systemctl --user enable --now firstboot-brew-install@"$USER".service &
  cosmic-term --bash -c "journalctl -fu firstboot-brew-install@$USER.service" &
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

  BOOTC_TIMER=$(systemctl list-unit-files \
    | awk '/bootc-.*fetch.*apply.*updates.*\.timer/ {print $1; exit}')

  if [ -n "$BOOTC_TIMER" ]; then
      systemctl enable --now "$BOOTC_TIMER"
  else
      echo "Kein bootc Auto-Update Timer gefunden." >> /tmp/firstboot-debug.log
  fi

else
  echo "Automatische Updates bleiben deaktiviert."
fi

# ------------------------------------------------------------
# Installation
# ------------------------------------------------------------
ensure_flathub

(
  echo "10"; echo "# Installiere Anwendungen…"

  for b in ${BROWSERS_LIST//|/ }; do
    case "$b" in
      firefox)  flatpak_user_install flathub org.mozilla.firefox ;;
      chromium) flatpak_user_install flathub org.chromium.Chromium ;;
      brave)    flatpak_user_install flathub com.brave.Browser ;;
    esac
  done

  for o in ${OFFICE_LIST//|/ }; do
    case "$o" in
      libreoffice) flatpak_user_install flathub org.libreoffice.LibreOffice ;;
      onlyoffice)  flatpak_user_install flathub org.onlyoffice.desktopeditors ;;
      collabora)   flatpak_user_install flathub com.collabora.Office ;;
      papers)      flatpak_user_install flathub org.gnome.Papers ;;
      simplescan)  flatpak_user_install flathub org.gnome.SimpleScan ;;
    esac
  done

  for g in ${GRAPHICS_LIST//|/ }; do
    case "$g" in
      gimp)     flatpak_user_install flathub org.gimp.GIMP ;;
      krita)    flatpak_user_install flathub org.kde.krita ;;
      inkscape) flatpak_user_install flathub org.inkscape.Inkscape ;;
    esac
  done

  for m in ${MEDIA_LIST//|/ }; do
    case "$m" in
      vlc)      flatpak_user_install flathub org.videolan.VLC ;;
      showtime) flatpak_user_install flathub org.gnome.Showtime ;;
      spotify)  flatpak_user_install flathub com.spotify.Client ;;
    esac
  done

  for a in ${AV_LIST//|/ }; do
    case "$a" in
      shotcut)  flatpak_user_install flathub org.shotcut.Shotcut ;;
      kdenlive) flatpak_user_install flathub org.kde.kdenlive ;;
      audacity) flatpak_user_install flathub org.audacityteam.Audacity ;;
      ardour)   flatpak_user_install flathub org.ardour.Ardour ;;
    esac
  done

  for g in ${GAMES_LIST//|/ }; do
    case "$g" in
      steam)  flatpak_user_install flathub com.valvesoftware.Steam ;;
      lutris) flatpak_user_install flathub net.lutris.Lutris ;;
      sober)  flatpak_user_install flathub org.vinegarhq.Sober ;;
    esac
  done

  for m in ${MAIL_LIST//|/ }; do
    case "$m" in
      thunderbird) flatpak_user_install flathub org.mozilla.Thunderbird ;;
      geary)       flatpak_user_install flathub org.gnome.Geary ;;
      evolution)   flatpak_user_install flathub org.gnome.Evolution ;;
    esac
  done

  for m in ${KI_LIST//|/ }; do
    case "$m" in
      alpaca)  flatpak_user_install flathub com.jeffser.Alpaca ;;
      gpt4all) flatpak_user_install flathub io.gpt4all.gpt4all ;;
    esac
  done

  for d in ${DEV_LIST//|/ }; do
    [[ "$d" == vscode ]] && flatpak_user_install flathub com.visualstudio.code
  done

  for s in ${SYSTEM_LIST//|/ }; do
    [[ "$s" == flatseal ]] && flatpak_user_install flathub com.github.tchx84.Flatseal
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
