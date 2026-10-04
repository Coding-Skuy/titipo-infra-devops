# Deploy Prod TitipO

## Topologi

- `titipo-backend-service` — 2 replika, port 8080, `/healthz` untuk probe.
- `titipo-web` (admin) — 1 layanan, di belakang SSO admin.
- DB `titipo` (Postgres 16) — **terpisah** dari DB `lumbung`, backup harian 02:00 WIB, retensi 14 hari.
- Secret: `TITIPO_SERVICE_KEY`, `LUMBUNG_JWKS_URL`, `DATABASE_URL` via secret manager.

## Urutan rilis

1. Migrasi `titipo-backend-service/migrations/0001_init.sql` ke DB `titipo`.
2. Deploy backend, tunggu `/healthz` 200.
3. Deploy web admin.
4. Smoke: `GET /healthz` + `GET /v1/contoh` dengan JWT `aud=titipo`.

## Rollback

- Backend: kembalikan ke image sebelumnya (migrasi 0001 aditif, aman rollback).
- Web: kembalikan bundle sebelumnya.
