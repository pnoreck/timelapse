#!/usr/bin/env bash
set -euo pipefail

# === Konfiguration ===
BASE="/home/sha/timelapse"
OUTDIR="${BASE}/images/$(date +%F)"
mkdir -p "${OUTDIR}"

WIDTH=4056
HEIGHT=3040
QUALITY=95
EXTRA_OPTS=""   # z. B. --awbgains 1.5,1.6 oder leer lassen

# Ziel für "aktuelles Bild"
WEBCAM_FILE="/var/www/html/webcam.jpg"

# --- Pfad für Log ---
LOG="${BASE}/logs/capture.log"
ts() { date '+%Y-%m-%dT%H:%M:%S%z'; }

# === Kamera-Command ermitteln ===
RPICAM_STILL="$(command -v rpicam-still || true)"
LIBCAM_STILL="$(command -v libcamera-still || true)"

if [[ -n "${RPICAM_STILL}" ]]; then
  CMD=("${RPICAM_STILL}" -n --width "${WIDTH}" --height "${HEIGHT}" --quality "${QUALITY}" --timeout 1000 ${EXTRA_OPTS})
elif [[ -n "${LIBCAM_STILL}" ]]; then
  CMD=("${LIBCAM_STILL}" -n --width "${WIDTH}" --height "${HEIGHT}" --quality "${QUALITY}" --timeout 1000)
else
  echo "[$(ts)] Keine rpicam-still oder libcamera-still gefunden (PATH=${PATH})." | tee -a "${LOG}" >&2
  exit 1
fi

STAMP="$(date '+%Y-%m-%d_%H-%M-%S')"
OUTFILE="${OUTDIR}/${STAMP}.jpg"

# === Aufnahme ===
"${CMD[@]}" -o "${OUTFILE}"
echo "[$(ts)] Bild aufgenommen: ${OUTFILE}" >> "${LOG}"

# === Kopie für aktuelle Vorschau ===
if cp -f "${OUTFILE}" "${WEBCAM_FILE}" 2>/dev/null; then
  echo "[$(ts)] webcam.jpg aktualisiert -> ${WEBCAM_FILE}" >> "${LOG}"
else
  echo "[$(ts)] WARNUNG: Konnte ${WEBCAM_FILE} nicht schreiben." >> "${LOG}"
fi

