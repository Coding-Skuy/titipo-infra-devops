#!/usr/bin/env bash
set -uo pipefail
D="$(cd "$(dirname "$0")" && pwd)"; . "$D/helper.sh"; S="$D/../scan-log.sh"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT

printf 'INFO server start\nGET /healthz 200\n' > "$T/bersih.log"
check "log bersih -> 0" 0 bash "$S" "$T/bersih.log"

printf 'INFO auth header Authorization: Bearer %s\n' "$(fake_jwt)" > "$T/jwt.log"
check "JWT di log -> 1" 1 bash "$S" "$T/jwt.log"

printf 'DEBUG X-Titipo-Service-Key: %s\n' "$(fake_skey)" > "$T/skey.log"
check "service key di log -> 1" 1 bash "$S" "$T/skey.log"

printf 'DEBUG TITIPO_SERVICE_KEY=***REDACTED***\n' > "$T/redacted.log"
check "service key tersamar -> 0" 0 bash "$S" "$T/redacted.log"

/usr/bin/head -c $((10*1024*1024 + 1)) /dev/zero | tr '\0' 'a' > "$T/besar.log"
check "log >10 MB -> 1" 1 bash "$S" "$T/besar.log"
/usr/bin/head -c $((10*1024*1024)) /dev/zero | tr '\0' 'a' > "$T/pas.log"
check "log tepat 10 MB -> 0" 0 bash "$S" "$T/pas.log"

check "stdin bocor -> 1" 1 bash -c "printf 'x %s\n' '$(fake_jwt)' | bash '$S' -"
check "tanpa argumen -> 2" 2 bash "$S"

# nilai tidak boleh tercetak
out="$(bash "$S" "$T/jwt.log" 2>&1 || true)"
if echo "$out" | grep -q "eyJ"; then echo "GAGAL  nilai JWT tercetak"; fails=$((fails+1)); else echo "LULUS  keluaran tidak membocorkan nilai"; fi
finish
