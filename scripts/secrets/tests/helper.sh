# Pembantu uji; di-source. Nilai "rahasia" dirakit saat runtime agar tidak tersimpan di repo.
fails=0
check() { # nama harapan_exit perintah...
  local name="$1" want="$2"; shift 2
  "$@" >/dev/null 2>&1; local rc=$?
  if [ "$rc" -eq "$want" ]; then echo "LULUS  $name"; else echo "GAGAL  $name (exit $rc, harapan $want)"; fails=$((fails+1)); fi
}
fake_jwt() { printf '%s.%s.%s' "eyJhbGciOiJSUzI1NiJ9" "eyJzdWIiOiJ1c2VyMSIsImF1ZCI6InRpdGlwbyJ9" "c2lnbmF0dXJlMTIzNDU"; }
fake_skey() { printf 'abcd%s' "EFGH1234567890xyz"; }
finish() { [ "$fails" -eq 0 ] && echo "Semua uji lulus" || { echo "$fails uji gagal"; exit 1; }; }
