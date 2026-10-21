#!/usr/bin/env bash
# Pemeriksa log (TTP-OPS-003): ukuran maks 10 MB dan tanpa JWT / service key.
# Pakai: scan-log.sh <berkas-log|->   (- = stdin).  Exit 0 bersih, 1 bocor/terlalu besar, 2 salah pakai.
# Keluaran TIDAK pernah mencetak nilai yang cocok, hanya nomor baris dan jenisnya.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib-patterns.sh
. "$HERE/lib-patterns.sh"
MAX_BYTES=$((10 * 1024 * 1024))

src="${1:-}"
[ -n "$src" ] || { echo "pakai: scan-log.sh <berkas|->" >&2; exit 2; }
tmp="$(mktemp)"; trap 'rm -f "$tmp"' EXIT
if [ "$src" = "-" ]; then cat > "$tmp"; else [ -f "$src" ] || { echo "berkas tidak ada: $src" >&2; exit 2; }; cp "$src" "$tmp"; fi

rc=0
size="$(wc -c < "$tmp" | tr -d ' ')"
if [ "$size" -gt "$MAX_BYTES" ]; then
  echo "GAGAL  log ${size} byte melebihi batas 10 MB (${MAX_BYTES})" >&2; rc=1
fi

report() { # jenis regex
  local n
  while IFS= read -r n; do
    # buang baris yang hanya berisi placeholder
    if sed -n "${n}p" "$tmp" | grep -Eq "$PLACEHOLDER_RE" && [ "$1" = "service-key" ]; then continue; fi
    echo "GAGAL  baris ${n}: ${1} terdeteksi (nilai disembunyikan)" >&2; rc=1
  done < <(grep -nEi -e "$2" "$tmp" | cut -d: -f1)
}
report "jwt" "$JWT_RE"
report "service-key" "$SKEY_RE"
report "private-key" "$PRIVKEY_RE"

[ "$rc" -eq 0 ] && echo "OK     log bersih (${size} byte)"
exit "$rc"
