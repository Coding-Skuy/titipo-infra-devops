#!/usr/bin/env bash
set -uo pipefail
D="$(cd "$(dirname "$0")" && pwd)"; B="$D/../backup-db.sh"; C="$D/../check-backup-status.sh"
fails=0
check() { local n="$1" w="$2"; shift 2; "$@" >/dev/null 2>&1; local rc=$?; if [ "$rc" -eq "$w" ]; then echo "LULUS  $n"; else echo "GAGAL  $n (exit $rc, harapan $w)"; fails=$((fails+1)); fi; }
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
mkdir "$T/bin"
# pg_dump palsu: sukses menulis berkas, atau gagal bila FAKE_PGDUMP_FAIL=1
cat > "$T/bin/pg_dump" <<'STUB'
#!/usr/bin/env bash
[ "${FAKE_PGDUMP_FAIL:-0}" = 1 ] && exit 1
for a in "$@"; do case "$a" in --file=*) echo "dump" > "${a#--file=}" ;; esac; done
STUB
chmod +x "$T/bin/pg_dump"
export PATH="$T/bin:$PATH" DATABASE_URL="postgres://x:y@h/titipo" BACKUP_DIR="$T/bk"

BACKUP_DATE=2026-10-20 check "backup sukses -> 0" 0 bash "$B"
[ -s "$T/bk/titipo-2026-10-20.dump" ] && echo "LULUS  berkas dump ada" || { echo "GAGAL  berkas dump tidak ada"; fails=$((fails+1)); }
grep -q "^2026-10-20 OK" "$T/bk/status.log" && echo "LULUS  status OK tercatat" || { echo "GAGAL  status OK tidak tercatat"; fails=$((fails+1)); }

FAKE_PGDUMP_FAIL=1 BACKUP_DATE=2026-10-21 check "pg_dump gagal -> 1" 1 bash "$B"
grep -q "^2026-10-21 FAIL" "$T/bk/status.log" && echo "LULUS  status FAIL tercatat" || { echo "GAGAL  status FAIL tidak tercatat"; fails=$((fails+1)); }
[ ! -e "$T/bk/titipo-2026-10-21.dump.partial" ] && echo "LULUS  berkas parsial dibersihkan" || { echo "GAGAL  parsial tersisa"; fails=$((fails+1)); }

DATABASE_URL="" BACKUP_DATE=2026-10-22 check "tanpa DATABASE_URL -> 1" 1 bash "$B"
DATABASE_URL="postgres://x@h/lumbung" BACKUP_DATE=2026-10-22 check "DB lumbung ditolak -> 1" 1 bash "$B"

# retensi: dump tua (40 hari) dihapus, dump lumbung-* tidak disentuh, dump segar tetap
touch -t 202508010000 "$T/bk/titipo-2025-08-01.dump" "$T/bk/lumbung-2025-08-01.dump"
BACKUP_DATE=2026-10-23 bash "$B" >/dev/null 2>&1
[ ! -e "$T/bk/titipo-2025-08-01.dump" ] && echo "LULUS  dump >30 hari dihapus" || { echo "GAGAL  dump tua tidak dihapus"; fails=$((fails+1)); }
[ -e "$T/bk/lumbung-2025-08-01.dump" ] && echo "LULUS  lumbung-* tidak disentuh" || { echo "GAGAL  lumbung-* terhapus"; fails=$((fails+1)); }
[ -e "$T/bk/titipo-2026-10-20.dump" ] && echo "LULUS  dump segar dipertahankan" || { echo "GAGAL  dump segar terhapus"; fails=$((fails+1)); }

# check-backup-status
export BACKUP_DIR="$T/st"; mkdir "$T/st"
printf '2026-10-18 OK\n2026-10-19 OK\n' > "$T/st/status.log"
check "kemarin & lusa OK -> hijau" 0 bash "$C" 2026-10-20
printf '2026-10-18 FAIL\n2026-10-19 FAIL\n' > "$T/st/status.log"
check "2 hari FAIL -> merah" 1 bash "$C" 2026-10-20
printf '2026-10-18 OK\n2026-10-19 FAIL\n' > "$T/st/status.log"
check "1 hari FAIL -> kuning (0)" 0 bash "$C" 2026-10-20
printf '2026-10-18 OK\n' > "$T/st/status.log"
check "kemarin hilang + lusa OK -> 0" 0 bash "$C" 2026-10-20
printf '2026-10-10 OK\n' > "$T/st/status.log"
check "2 hari tanpa entri -> merah" 1 bash "$C" 2026-10-20
printf '2026-10-19 FAIL\n2026-10-20 FAIL\n' > "$T/st/status.log"
check "hari ini FAIL + kemarin FAIL -> merah" 1 bash "$C" 2026-10-20
printf '2026-10-19 FAIL\n2026-10-20 OK\n' > "$T/st/status.log"
check "hari ini OK -> hijau" 0 bash "$C" 2026-10-20
printf '2026-10-19 FAIL\n2026-10-19 OK\n2026-10-18 FAIL\n' > "$T/st/status.log"
check "entri terakhir hari itu dipakai (OK) -> 0" 0 bash "$C" 2026-10-20
rm -f "$T/st/status.log"
check "tanpa log -> merah" 1 bash "$C" 2026-10-20
check "pergantian tahun 2027-01-02" 1 bash "$C" 2027-01-02

[ "$fails" -eq 0 ] && echo "Semua uji lulus" || { echo "$fails uji gagal"; exit 1; }
