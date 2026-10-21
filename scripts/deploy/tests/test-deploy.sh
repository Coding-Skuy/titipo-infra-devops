#!/usr/bin/env bash
set -uo pipefail
D="$(cd "$(dirname "$0")" && pwd)"; S="$D/../deploy.sh"
fails=0
check() { local n="$1" w="$2"; shift 2; "$@" >/dev/null 2>&1; local rc=$?; if [ "$rc" -eq "$w" ]; then echo "LULUS  $n"; else echo "GAGAL  $n (exit $rc, harapan $w)"; fails=$((fails+1)); fi; }
ok() { if [ "$2" = "$3" ]; then echo "LULUS  $1"; else echo "GAGAL  $1 (dapat '$2', harapan '$3')"; fails=$((fails+1)); fi; }
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
export DEPLOY_ROOT="$T/opt" REPLICAS="1 2" HEALTH_TRIES=2 SKIP_BACKUP_GATE=1
mkdir -p "$DEPLOY_ROOT/releases/r1" "$DEPLOY_ROOT/releases/r2" "$DEPLOY_ROOT/releases/r3"
ln -s "$DEPLOY_ROOT/releases/r1" "$DEPLOY_ROOT/current"
# RESTART_CMD/HEALTH_CMD palsu: log urutan; sehat tergantung release di current
export RESTART_CMD="echo restart-{replica} >> $T/calls"
export HEALTH_CMD="[ \"\$(basename \$(readlink $DEPLOY_ROOT/current))\" != bad ]"

check "deploy tanpa id -> 2" 2 bash "$S" deploy
check "perintah tak dikenal -> 2" 2 bash "$S" foo
check "release tak ada -> 1" 1 bash "$S" deploy tidak-ada

check "deploy r2 -> 0" 0 bash "$S" deploy r2
ok "current -> r2" "$(basename "$(readlink "$DEPLOY_ROOT/current")")" r2
ok "previous -> r1" "$(basename "$(readlink "$DEPLOY_ROOT/previous")")" r1
ok "restart berurutan per replika" "$(tr '\n' ' ' < "$T/calls")" "restart-1 restart-2 "

: > "$T/calls"
check "rollback -> 0" 0 bash "$S" rollback
ok "current kembali r1" "$(basename "$(readlink "$DEPLOY_ROOT/current")")" r1

# deploy gagal (health merah) -> rollback otomatis ke release sebelumnya
mkdir -p "$DEPLOY_ROOT/releases/bad"
check "deploy bad -> 1" 1 bash "$S" deploy bad
ok "setelah gagal current kembali r1" "$(basename "$(readlink "$DEPLOY_ROOT/current")")" r1

# rollback tanpa previous
rm -f "$DEPLOY_ROOT/previous"
check "rollback tanpa previous -> 1" 1 bash "$S" rollback

# gerbang backup merah memblokir deploy
export SKIP_BACKUP_GATE=0 BACKUP_DIR="$T/bk"; mkdir "$T/bk"
printf '2026-01-01 FAIL\n' > "$T/bk/status.log"
check "gerbang backup merah -> 1" 1 bash "$S" deploy r3
ok "current tidak berubah saat diblokir" "$(basename "$(readlink "$DEPLOY_ROOT/current")")" r1

[ "$fails" -eq 0 ] && echo "Semua uji lulus" || { echo "$fails uji gagal"; exit 1; }
