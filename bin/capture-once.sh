#!/usr/bin/env bash
set -euo pipefail

# === Konfiguration ===
BASE="/home/sha/timelapse"
OUTDIR="${BASE}/images/$(date +%F)"     # Tagesordner: YYYY-MM-DD
mkdir -p "${OUTDIR}"

# Aufnahme-Intervall wird durch den systemd-Timer gesteuert
# Kameraeinstellungen:
WIDTH=4056       # HQ-Cam max: 4056x3040 (12MP)
HEIGHT=3040
QUALITY=95       # JPEG-Qualität 1..100
EXTRA_OPTS="--awbgains 1.5,1.6"  # Beispiel: manuelles AWB-Tuning; kann leer sein

# === Aufnahme-Command finden (rpicam-still bevorzugt, sonst libcamera-still) ===
CMD=""
if command -v rpicam-still >/dev/null 2>&1; then
  CMD="rpicam-still -n --width ${WIDTH} --height ${HEIGHT} --quality ${QUALITY} --timeout 1 ${EXTRA_OPTS}"
elif command -v libcamera-still >/dev/null 2>&1; then
  CMD="libcamera-still -n --width ${WIDTH} --height ${HEIGHT} --quality ${QUALITY} --timeout 1"
else
  echo "Keine rpicam-still oder libcamera-still gefunden." >&2
  exit 1
fi

# === Aufnahme ===
STAMP="$(date +%Y-%m-%d_%H-%M-%S)"
OUTFILE="${OUTDIR}/${STAMP}.jpg"

# rpicam/libcamera brauchen -o
${CMD} -o "${OUTFILE}"

echo "$(date '+%F %T') -> ${OUTFILE}" >> "${BASE}/logs/capture.log"
