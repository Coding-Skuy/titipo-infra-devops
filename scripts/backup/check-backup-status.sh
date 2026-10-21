#!/usr/bin/env bash
# Gerbang deploy (TTP-OPS-004): backup gagal 2 hari berturut = MERAH, blokir deploy fitur baru.
# Pakai: check-backup-status.sh [YYYY-MM-DD hari ini]    Env: BACKUP_DIR (default /var/backups/titipo)
# Dua hari yang dinilai: (hari ini, kemarin) bila entri hari ini sudah ada, selain itu (kemarin, 2 hari lalu).
# Hari tanpa entri dihitung GAGAL (job tidak jalan). Satu OK dalam dua hari = hijau/kuning.
# Exit 0 hijau, 1 merah.
set -uo pipefail
: "${BACKUP_DIR:=/var/backups/titipo}"
LOG="$BACKUP_DIR/status.log"
today="${1:-$(date -u +%Y-%m-%d)}"

shift_day() { # tanggal selisih-hari (negatif), portabel GNU/BSD
  date -u -d "$1 $2 day" +%Y-%m-%d 2>/dev/null || date -u -j -v"${2}d" -f %Y-%m-%d "$1" +%Y-%m-%d
}
state() { # tanggal -> status terakhir hari itu (OK/FAIL/NONE)
  local s=""
  [ -f "$LOG" ] && s="$(grep -E "^$1 " "$LOG" | tail -n 1 | cut -d' ' -f2)"
  echo "${s:-NONE}"
}
has_today=0; [ "$(state "$today")" != NONE ] && has_today=1
if [ "$has_today" -eq 1 ]; then d1="$today"; else d1="$(shift_day "$today" -1)"; fi
d2="$(shift_day "$d1" -1)"
s1="$(state "$d1")"; s2="$(state "$d2")"
echo "backup ${d1}: ${s1}; ${d2}: ${s2}"
if [ "$s1" != OK ] && [ "$s2" != OK ]; then
  echo "MERAH  backup gagal/hilang 2 hari berturut; deploy fitur baru DIBLOKIR sampai backup pulih" >&2
  exit 1
fi
[ "$s1" = OK ] && echo "HIJAU  backup terakhir OK" || echo "KUNING backup ${d1} ${s1}; perbaiki sebelum besok"
exit 0
