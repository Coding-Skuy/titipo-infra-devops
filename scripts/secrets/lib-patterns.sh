# shellcheck shell=bash disable=SC2034
# Pola kebocoran bersama (di-source oleh scan-log.sh dan scan-repo.sh). Bukan skrip mandiri.
# JWT: tiga segmen base64url, dua segmen pertama diawali eyJ (header/payload JSON).
JWT_RE='eyJ[A-Za-z0-9_-]{8,}\.eyJ[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{5,}'
# Service key: header atau env dengan nilai bukan placeholder.
SKEY_RE='(X-Titipo-Service-Key|TITIPO_SERVICE_KEY|LUMBUNG_TITIPO_KEYS)["'"'"']?[[:space:]]*[:=][[:space:]]*["'"'"']?[A-Za-z0-9+/_.-]{12,}'
# Nilai placeholder yang diizinkan.
PLACEHOLDER_RE='isi-di-secret-manager|<[^>]*>|\$\{[^}]*\}|\*{3,}|REDACTED|contoh'
PRIVKEY_RE='-----BEGIN ([A-Z ]+ )?PRIVATE KEY-----'
