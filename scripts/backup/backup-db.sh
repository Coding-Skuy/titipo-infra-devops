#!/usr/bin/env bash
# Backup harian DB titipo (TTP-OPS-004): jalankan 03.00 lewat deploy/prod/cron/titipo-backup.cron.
# Env: DATABASE_URL (wajib, DB titipo), BACKUP_DIR (default /var/backups/titipo), RETENTION_DAYS (default 30),
#      BACKUP_DATE (YYYY-MM-DD, default hari ini UTC; untuk uji).
# Hanya menyentuh berkas `titipo-*.dump`; tidak pernah `lumbung-*`. Mencatat OK/FAIL ke $BACKUP_DIR/status.log.
# Exit 0 sukses, 1 gagal. DATABASE_URL tidak pernah dicetak.
set -uo pipefail
: "${BACKUP_DIR:=/var/backups/titipo}"
: "${RETENTION_DAYS:=30}"
day="${BACKUP_DATE:-$(date -u +%Y-%m-%d)}"
mkdir -p "$BACKUP_DIR"
out="$BACKUP_DIR/titipo-${day}.dump"
log() { echo "$day $1" >> "$BACKUP_DIR/status.log"; }

if [ -z "${DATABASE_URL:-}" ]; then echo "GAGAL  DATABASE_URL tidak diset" >&2; log FAIL; exit 1; fi
case "$DATABASE_URL" in *lumbung*) echo "GAGAL  DATABASE_URL menunjuk DB lumbung; menolak" >&2; log FAIL; exit 1 ;; esac

tmp="$out.partial"
if pg_dump --format=custom --file="$tmp" "$DATABASE_URL" 2>/dev/null && [ -s "$tmp" ]; then
  mv "$tmp" "$out"
  log OK
  # retensi: hapus dump titipo-* lebih tua dari RETENTION_DAYS hari
  find "$BACKUP_DIR" -maxdepth 1 -name 'titipo-*.dump' -type f -mtime +"$((RETENTION_DAYS - 1))" -delete
  echo "OK     backup ${out}"
else
  rm -f "$tmp"
  log FAIL
  echo "GAGAL  pg_dump gagal (dicatat FAIL di status.log)" >&2
  exit 1
fi
