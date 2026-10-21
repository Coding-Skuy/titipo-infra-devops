#!/usr/bin/env bash
# Uji untuk verify-kmp-pins.sh. Jalankan: bash scripts/ci/tests/test-verify-kmp-pins.sh
set -uo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
S="$DIR/../verify-kmp-pins.sh"
F="$DIR/fixtures"
fails=0
expect() { # nama harapan_exit berkas
  bash "$S" "$3" >/dev/null 2>&1; rc=$?
  if [ "$rc" -eq "$2" ]; then echo "LULUS  $1"; else echo "GAGAL  $1 (exit $rc, harapan $2)"; fails=$((fails+1)); fi
}
expect "pin sesuai -> exit 0"            0 "$F/libs-ok.toml"
expect "compose meleset -> exit 1"       1 "$F/libs-compose-meleset.toml"
expect "navigation3 hilang -> exit 1"    1 "$F/libs-nav-hilang.toml"
expect "berkas tidak ada -> exit 2"      2 "$F/tidak-ada.toml"
[ "$fails" -eq 0 ] && echo "Semua uji lulus" || { echo "$fails uji gagal"; exit 1; }
