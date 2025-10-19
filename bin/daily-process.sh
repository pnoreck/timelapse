#!/usr/bin/env bash
set -euo pipefail

# === Konfiguration ===
BASE="/home/sha/timelapse"
IMG_BASE="${BASE}/images"
VID_BASE="${BASE}/videos"
LOG="${BASE}/logs/daily.log"

# Welche Stunden extrahieren?
HOURS=("09" "12" "17")

# Video-Settings
FPS=24
CRF=20           # Qualität (x264): kleiner = besser/größer
PRESET="veryfast"
SCALE="1920:-2"  # 1080p-ähnlich, Seitenverhältnis wird behalten

# Verarbeitet wird standardmäßig der heutige Tag.
# Falls du nachts vor Mitternacht laufen lässt und "gestern" willst:
# DATE=$(date -d 'yesterday' +%F)
DATE="${1:-$(date +%F)}"

DAY_DIR="${IMG_BASE}/${DATE}"
[ -d "${DAY_DIR}" ] || { echo "Kein Bildordner für ${DATE}" | tee -a "${LOG}"; exit 0; }

echo "$(date --isoseconds) Starte Tagesverarbeitung für ${DATE}" | tee -a "${LOG}"

mkdir -p "${VID_BASE}"

# 1) Tagesvideo aus ALLEN Bildern
if compgen -G "${DAY_DIR}/*.jpg" > /dev/null; then
  OUT_ALL="${VID_BASE}/${DATE}_ALL.mp4"
  ffmpeg -hide_banner -y -framerate ${FPS} -pattern_type glob -i "${DAY_DIR}/*.jpg" \
         -vf "scale=${SCALE},format=yuv420p" \
         -c:v libx264 -preset ${PRESET} -crf ${CRF} \
         "${OUT_ALL}" \
         >> "${LOG}" 2>&1
  echo "Tagesvideo erstellt: ${OUT_ALL}" | tee -a "${LOG}"
else
  echo "Keine Bilder für ${DATE} gefunden." | tee -a "${LOG}"
fi

# 2) Bilder nach Stunde einsortieren & je ein Stunden-Video
for HH in "${HOURS[@]}"; do
  HOUR_DIR="${DAY_DIR}/hour-${HH}"
  mkdir -p "${HOUR_DIR}"
  # Dateien der Stunde verschieben (behalten)
  # Muster passt auf ..._HH-...
  shopt -s nullglob
  files=( "${DAY_DIR}/"*_"${HH}"-*".jpg" )
  if (( ${#files[@]} > 0 )); then
    mv "${files[@]}" "${HOUR_DIR}/"
    OUT_HOUR="${VID_BASE}/${DATE}_H${HH}.mp4"
    if compgen -G "${HOUR_DIR}/*.jpg" > /dev/null; then
      ffmpeg -hide_banner -y -framerate ${FPS} -pattern_type glob -i "${HOUR_DIR}/*.jpg" \
             -vf "scale=${SCALE},format=yuv420p" \
             -c:v libx264 -preset ${PRESET} -crf ${CRF} \
             "${OUT_HOUR}" \
             >> "${LOG}" 2>&1
      echo "Stunden-Video erstellt: ${OUT_HOUR}" | tee -a "${LOG}"
    fi
  else
    echo "Keine Bilder für Stunde ${HH} am ${DATE}." | tee -a "${LOG}"
  fi
done

# 3) Restliche Bilder (die NICHT in den Stundenordnern sind) löschen
#    Dadurch bleiben nur die gewünschten Stundenbilder für Archivierung bestehen.
find "${DAY_DIR}" -maxdepth 1 -type f -name "*.jpg" -print -delete | tee -a "${LOG}"

echo "$(date --isoseconds) Fertig für ${DATE}" | tee -a "${LOG}"


