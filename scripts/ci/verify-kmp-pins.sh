#!/usr/bin/env bash
# Verifikasi pin versi KMP di gradle/libs.versions.toml (TTP-OPS-002, ci/build-kmp.md).
# Pakai: verify-kmp-pins.sh [path/ke/libs.versions.toml]
# Exit 0 = semua pin cocok; exit 1 = ada pin yang meleset atau hilang.
set -euo pipefail

TOML="${1:-gradle/libs.versions.toml}"
[ -f "$TOML" ] || { echo "GAGAL: berkas tidak ditemukan: $TOML" >&2; exit 2; }

# kunci -> versi terkunci (AGENTS.md repo ini, bagian Tech stack terkunci)
declare -a PINS=(
  "kotlin|2.2.20"
  "compose|1.8.2"
  "navigation3|1.0.0"
  "agp|8.5.2"
)

fail=0
for pin in "${PINS[@]}"; do
  key="${pin%%|*}"
  want="${pin##*|}"
  # cocokkan baris persis: <key> = "<versi>" (spasi bebas, abaikan komentar di akhir)
  if grep -Eq "^[[:space:]]*${key}[[:space:]]*=[[:space:]]*\"${want//./\\.}\"" "$TOML"; then
    echo "OK     ${key} = ${want}"
  else
    got="$(grep -E "^[[:space:]]*${key}[[:space:]]*=" "$TOML" | /usr/bin/head -1 || true)"
    echo "GAGAL  ${key}: diharapkan \"${want}\", ditemukan: ${got:-<tidak ada>}" >&2
    fail=1
  fi
done
exit "$fail"
