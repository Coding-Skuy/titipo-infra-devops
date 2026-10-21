#!/usr/bin/env bash
set -uo pipefail
D="$(cd "$(dirname "$0")" && pwd)"; . "$D/helper.sh"; S="$D/../rotation-status.sh"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
st() { printf '%s\n' "$@" > "$T/s"; }

st ROTATED_AT=2026-10-01
check "hari 0 -> 0"                 0 bash "$S" "$T/s" 2026-10-01
check "hari 82 -> 0 (OK)"           0 bash "$S" "$T/s" 2026-12-22
out="$(bash "$S" "$T/s" 2026-12-24)"; echo "$out" | grep -q PERINGATAN && echo "LULUS  hari 84 -> peringatan" || { echo "GAGAL  hari 84 tanpa peringatan"; fails=$((fails+1)); }
check "hari 89 -> 0 (peringatan)"   0 bash "$S" "$T/s" 2026-12-29
check "hari 90 -> 1 (jatuh tempo)"  1 bash "$S" "$T/s" 2026-12-30
check "lintas tahun kabisat"        1 bash "$S" "$T/s" 2027-03-01

st ROTATED_AT=2026-12-23 OVERLAP_STARTED_AT=2026-12-23
check "overlap hari 7 (kunci baru) -> 0" 0 bash "$S" "$T/s" 2026-12-30
check "overlap hari 8 -> 1"         1 bash "$S" "$T/s" 2026-12-31

st ROTATED_AT=bukan-tanggal
check "tanggal tak valid -> 2"      2 bash "$S" "$T/s" 2026-10-01
check "berkas tidak ada -> 2"       2 bash "$S" "$T/tidak-ada"
finish
