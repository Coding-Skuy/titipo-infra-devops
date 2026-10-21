#!/usr/bin/env bash
# Pemeriksa repo (TTP-OPS-003): nol secret di berkas yang dilacak git.
# Pakai: scan-repo.sh [direktori-repo]   Exit 0 bersih, 1 temuan.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib-patterns.sh
. "$HERE/lib-patterns.sh"
cd "${1:-.}" || exit 2
rc=0
note() { echo "GAGAL  $1" >&2; rc=1; }

# Berkas berbahaya yang dilacak
while IFS= read -r f; do
  case "$f" in
    *.env.example|*.env.sample) ;;
    .env|*/.env|*.env|*.jks|*.keystore|*.p12|*.pem|*.pfx) note "berkas rahasia dilacak: $f" ;;
  esac
done < <(git ls-files)

# Isi berkas (teks saja); skrip pemindai & uji dikecualikan karena memuat pola
while IFS= read -r f; do
  case "$f" in scripts/secrets/*) continue ;; esac
  [ -f "$f" ] || continue
  grep -Iq . "$f" 2>/dev/null || continue
  if grep -nEq -e "$JWT_RE" "$f"; then note "$f: JWT terdeteksi"; fi
  if grep -nEq -e "$PRIVKEY_RE" "$f"; then note "$f: private key terdeteksi"; fi
  while IFS= read -r line; do
    echo "$line" | grep -Eq "$PLACEHOLDER_RE" && continue
    note "$f: service key bernilai terdeteksi (nilai disembunyikan)"
  done < <(grep -hEi -e "$SKEY_RE" "$f")
done < <(git ls-files)

[ "$rc" -eq 0 ] && echo "OK     tidak ada secret di berkas terlacak"
exit "$rc"
