#!/usr/bin/env bash
# Status rotasi service key titipo->lumbung (TTP-OPS-003): siklus 90 hari, 2 kunci aktif 7 hari.
# Pakai: rotation-status.sh <berkas-state> [YYYY-MM-DD hari ini]
# Berkas state HANYA berisi tanggal (bukan kunci):
#   ROTATED_AT=YYYY-MM-DD        tanggal kunci aktif saat ini mulai dipakai
#   OVERLAP_STARTED_AT=YYYY-MM-DD (opsional) tanggal kunci baru ditambahkan di samping yang lama
# Exit: 0 OK / mendekati jatuh tempo (peringatan), 1 JATUH TEMPO atau overlap > 7 hari, 2 salah pakai.
set -uo pipefail
CYCLE=90; WARN_AT=83; OVERLAP=7

state="${1:-}"; [ -f "$state" ] || { echo "pakai: rotation-status.sh <berkas-state> [tanggal]" >&2; exit 2; }
today="${2:-$(date -u +%Y-%m-%d)}"

# hari sejak epoch dari tanggal sipil (algoritma Hinnant), portabel tanpa date -d/-j
days() {
  local y m d
  IFS=- read -r y m d <<<"$1"
  y=$((10#$y)); m=$((10#$m)); d=$((10#$d))
  [ "$m" -le 2 ] && y=$((y - 1))
  local era=$(( (y >= 0 ? y : y - 399) / 400 ))
  local yoe=$((y - era * 400))
  local mp=$(( (m + 9) % 12 ))
  local doy=$(( (153 * mp + 2) / 5 + d - 1 ))
  local doe=$((yoe * 365 + yoe / 4 - yoe / 100 + doy))
  echo $((era * 146097 + doe - 719468))
}
get() { grep -E "^$1=" "$state" | /usr/bin/head -1 | cut -d= -f2- | tr -d '[:space:]'; }
valid() { [[ "$1" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; }

rotated="$(get ROTATED_AT)"; overlap="$(get OVERLAP_STARTED_AT)"
valid "$rotated" || { echo "ROTATED_AT tidak valid/hilang" >&2; exit 2; }
valid "$today" || { echo "tanggal hari ini tidak valid" >&2; exit 2; }
rc=0
age=$(( $(days "$today") - $(days "$rotated") ))
if [ "$age" -ge "$CYCLE" ]; then
  echo "JATUH TEMPO  kunci berumur ${age} hari (batas ${CYCLE}); mulai rotasi sekarang"; rc=1
elif [ "$age" -ge "$WARN_AT" ]; then
  echo "PERINGATAN   kunci berumur ${age} hari; jatuh tempo dalam $((CYCLE - age)) hari"
else
  echo "OK           kunci berumur ${age} hari (batas ${CYCLE})"
fi
if [ -n "$overlap" ]; then
  valid "$overlap" || { echo "OVERLAP_STARTED_AT tidak valid" >&2; exit 2; }
  o=$(( $(days "$today") - $(days "$overlap") ))
  if [ "$o" -gt "$OVERLAP" ]; then
    echo "JATUH TEMPO  dua kunci aktif sudah ${o} hari (maks ${OVERLAP}); cabut kunci lama"; rc=1
  else
    echo "INFO         dua kunci aktif, hari ke-${o} dari ${OVERLAP}"
  fi
fi
exit "$rc"
