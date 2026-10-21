#!/usr/bin/env bash
set -uo pipefail
D="$(cd "$(dirname "$0")" && pwd)"; . "$D/helper.sh"; S="$D/../scan-repo.sh"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
mk() { rm -rf "$T/r"; mkdir "$T/r"; (cd "$T/r" && git init -q && git config user.email t@t && git config user.name t); }

mk; echo 'TITIPO_SERVICE_KEY=isi-di-secret-manager' > "$T/r/.env.example"; (cd "$T/r" && git add -A)
check "placeholder + .env.example -> 0" 0 bash "$S" "$T/r"

mk; echo "TITIPO_SERVICE_KEY=$(fake_skey)" > "$T/r/app.conf"; (cd "$T/r" && git add -A)
check "service key bernilai -> 1" 1 bash "$S" "$T/r"

mk; echo "token $(fake_jwt)" > "$T/r/notes.md"; (cd "$T/r" && git add -A)
check "JWT di dokumen -> 1" 1 bash "$S" "$T/r"

mk; echo x > "$T/r/.env"; (cd "$T/r" && git add -f .env)
check ".env dilacak -> 1" 1 bash "$S" "$T/r"

mk; echo x > "$T/r/release.jks"; (cd "$T/r" && git add -A)
check "keystore dilacak -> 1" 1 bash "$S" "$T/r"

mk; printf -- '-----BEGIN %s KEY-----\nabc\n' "RSA PRIVATE" > "$T/r/k.txt"; (cd "$T/r" && git add -A)
check "private key -> 1" 1 bash "$S" "$T/r"

mk; echo x > "$T/r/.env"   # tidak dilacak
check ".env tidak dilacak -> 0" 0 bash "$S" "$T/r"

# repo ini sendiri harus bersih
check "repo ini bersih -> 0" 0 bash "$S" "$D/../../.."
finish
