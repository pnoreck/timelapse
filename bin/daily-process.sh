#!/usr/bin/env bash
set -euo pipefail

# === Konfiguration ===
BASE="/home/sha/timelapse"
IMG_BASE="${BASE}/images"
VID_BASE="${BASE}/videos"
LOG="${BASE}/logs/daily.log"

# Welche Vollstunden sammeln?
HOURS=("09" "12" "17")

# Video-Settings (Tagesvideo)
FPS=24
CRF=20
PRESET="veryfast"
SCALE="1920:-2"  # Seitenverhältnis bleibt erhalten

# Datum:
# Wir planen den Timer auf 03:00 am Folgetag. Dann ist "gestern" der komplette Aufnahmetag.
DATE="${1:-$(date -d 'yesterday' +%F)}"
DAY_DIR="${IMG_BASE}/${DATE}"

mkdir -p "${VID_BASE}" "${BASE}/logs"
shopt -s nullglob

ts() { date '+%Y-%m-%dT%H:%M:%S%z'; }

if [[ ! -d "${DAY_DIR}" ]]; then
  echo "[$(ts)] Kein Bildordner für ${DATE} (${DAY_DIR})" | tee -a "${LOG}"
  exit 0
fi

echo "[$(ts)] Starte Tagesverarbeitung für ${DATE}" | tee -a "${LOG}"

# 1) Tagesvideo aus ALLEN Bildern (bevor irgendwas verschoben/gelöscht wird)
if compgen -G "${DAY_DIR}/*.jpg" > /dev/null; then
  OUT_ALL="${VID_BASE}/${DATE}_ALL.mp4"
  ffmpeg -hide_banner -y -framerate ${FPS} -pattern_type glob -i "${DAY_DIR}/*.jpg" \
         -vf "scale=${SCALE},format=yuv420p" \
         -c:v libx264 -preset ${PRESET} -crf ${CRF} \
         "${OUT_ALL}" \
         >> "${LOG}" 2>&1
  echo "[$(ts)] Tagesvideo erstellt: ${OUT_ALL}" | tee -a "${LOG}"
else
  echo "[$(ts)] Keine Bilder für ${DATE} gefunden." | tee -a "${LOG}"
fi

# 2) Pro gewünschter Stunde GENAU das Bild von HH:00 in zentrale Ordner verschieben
for HH in "${HOURS[@]}"; do
  CENTRAL_DIR="${IMG_BASE}/hour-${HH}"
  mkdir -p "${CENTRAL_DIR}"

  # Exakt HH:00 – dank Dateinamen: YYYY-MM-DD_HH-MM-SS.jpg
  matches=( "${DAY_DIR}/${DATE}_${HH}-00-"*.jpg )
  if (( ${#matches[@]} == 0 )); then
    echo "[$(ts)] Kein exaktes ${HH}:00-Bild am ${DATE} gefunden." | tee -a "${LOG}"
    continue
  fi

  # Falls wider Erwarten mehrere existieren, nimm das erste (alphabetisch = chronologisch)
  pick="${matches[0]}"
  mv -v -- "${pick}" "${CENTRAL_DIR}/" | tee -a "${LOG}"
done

# 3) Restliche Bilder des Tages löschen (nur top-level Dateien im Tagesordner)
find "${DAY_DIR}" -maxdepth 1 -type f -name "*.jpg" -print -delete | tee -a "${LOG}"

echo "[$(ts)] Fertig für ${DATE}" | tee -a "${LOG}"


