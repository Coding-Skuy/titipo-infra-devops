#!/usr/bin/env bash
# Deploy prod + rollback (TTP-OPS-004). Rolling restart replika satu per satu agar downtime <30 dtk.
# Pakai:  deploy.sh deploy <release-id>   |   deploy.sh rollback
# Tata letak (ASUMSI, belum ada kontrak infra tertulis): $DEPLOY_ROOT/releases/<id>/ berisi artefak,
#   $DEPLOY_ROOT/current -> symlink ke release aktif, $DEPLOY_ROOT/previous -> release hijau sebelumnya.
# Env:
#   DEPLOY_ROOT   default /opt/titipo
#   REPLICAS      default "1 2"            (README prod: 2 replika)
#   RESTART_CMD   default 'systemctl restart titipo-backend@{replica}'   ({replica} diganti)
#   HEALTH_CMD    default 'curl -fsS http://127.0.0.1:{port}/healthz'    ({replica},{port}); port=PORT_BASE+replica-1
#   PORT_BASE     default 8080
#   HEALTH_TRIES  default 15 (jeda 1 dtk)  -> batas tunggu /healthz per replika
#   SKIP_BACKUP_GATE=1 hanya untuk uji; produksi WAJIB lewat gerbang backup.
# Migrasi DB TIDAK dijalankan dan TIDAK dimundurkan di sini (dijalankan manual/terpisah sebelum deploy).
# Exit 0 sukses, 1 gagal (deploy gagal otomatis rollback ke previous bila ada), 2 salah pakai.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
: "${DEPLOY_ROOT:=/opt/titipo}" "${REPLICAS:=1 2}" "${PORT_BASE:=8080}" "${HEALTH_TRIES:=15}"
: "${RESTART_CMD:=systemctl restart titipo-backend@{replica}}"
: "${HEALTH_CMD:=curl -fsS http://127.0.0.1:{port}/healthz}"

expand() { local s="$1"; s="${s//\{replica\}/$2}"; s="${s//\{port\}/$3}"; echo "$s"; }

restart_all() {
  local r port i
  for r in $REPLICAS; do
    port=$((PORT_BASE + r - 1))
    bash -c "$(expand "$RESTART_CMD" "$r" "$port")" >/dev/null 2>&1 || { echo "GAGAL  restart replika $r" >&2; return 1; }
    for ((i = 1; i <= HEALTH_TRIES; i++)); do
      bash -c "$(expand "$HEALTH_CMD" "$r" "$port")" >/dev/null 2>&1 && break
      sleep 1
    done
    [ "$i" -le "$HEALTH_TRIES" ] || { echo "GAGAL  /healthz replika $r tidak 200 dalam ${HEALTH_TRIES} dtk" >&2; return 1; }
    echo "OK     replika $r sehat"
  done
}

switch_to() { ln -sfn "$DEPLOY_ROOT/releases/$1" "$DEPLOY_ROOT/current.tmp" && mv -T "$DEPLOY_ROOT/current.tmp" "$DEPLOY_ROOT/current" 2>/dev/null || { ln -sfn "$DEPLOY_ROOT/releases/$1" "$DEPLOY_ROOT/current"; rm -f "$DEPLOY_ROOT/current.tmp"; }; }
rel_of() { [ -L "$1" ] && basename "$(readlink "$1")"; }

do_rollback() {
  local prev; prev="$(rel_of "$DEPLOY_ROOT/previous")"
  [ -n "$prev" ] && [ -d "$DEPLOY_ROOT/releases/$prev" ] || { echo "GAGAL  tidak ada release previous untuk rollback" >&2; return 1; }
  switch_to "$prev"
  restart_all || return 1
  echo "OK     rollback ke ${prev} (migrasi DB TIDAK dimundurkan otomatis)"
}

cmd="${1:-}"
case "$cmd" in
  deploy)
    id="${2:-}"; [ -n "$id" ] || { echo "pakai: deploy.sh deploy <release-id>" >&2; exit 2; }
    [ -d "$DEPLOY_ROOT/releases/$id" ] || { echo "GAGAL  release tidak ada: $DEPLOY_ROOT/releases/$id" >&2; exit 1; }
    if [ "${SKIP_BACKUP_GATE:-0}" != 1 ]; then
      bash "$HERE/../backup/check-backup-status.sh" || { echo "GAGAL  gerbang backup merah; deploy dibatalkan" >&2; exit 1; }
    fi
    cur="$(rel_of "$DEPLOY_ROOT/current" || true)"
    start=$SECONDS
    switch_to "$id"
    if restart_all; then
      [ -n "$cur" ] && [ "$cur" != "$id" ] && ln -sfn "$DEPLOY_ROOT/releases/$cur" "$DEPLOY_ROOT/previous"
      echo "OK     deploy ${id} selesai dalam $((SECONDS - start)) dtk (total, bukan downtime; rolling per replika)"
    else
      echo "GAGAL  deploy ${id}; mencoba rollback otomatis" >&2
      if [ -n "$cur" ]; then
        ln -sfn "$DEPLOY_ROOT/releases/$cur" "$DEPLOY_ROOT/previous"; do_rollback
      fi
      exit 1
    fi ;;
  rollback) do_rollback || exit 1 ;;
  *) echo "pakai: deploy.sh deploy <release-id> | rollback" >&2; exit 2 ;;
esac
