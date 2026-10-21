# Deploy Prod TitipO

Sumber: ADR-0001, `AGENTS.md`, TitipO-TownHall FSD `30-kontrak.md` bagian Job Bun. Skrip + uji di `scripts/deploy/` dan `scripts/backup/`; runbook di `docs/runbook.md`.

## Topologi

- `titipo-backend-service` — 2 replika, port 8080 (replika 2: 8081, ASUMSI), `/healthz` untuk probe. VPS tunggal prod.
- `titipo-web` (admin) — 1 layanan, di belakang SSO admin.
- DB `titipo` (Postgres 16) — **terpisah** dari DB `lumbung`; backup harian **03.00**, retensi **30 hari** (`scripts/backup/backup-db.sh`, jadwal `deploy/prod/cron/titipo-backup.cron`).
- Secret: `TITIPO_SERVICE_KEY`, `LUMBUNG_JWKS_URL`, `DATABASE_URL` via secret manager (lihat `docs/secrets.md`).

## Urutan rilis

1. Gerbang backup: `scripts/backup/check-backup-status.sh` harus bukan MERAH (backup gagal 2 hari berturut memblokir deploy fitur baru). `deploy.sh` menjalankannya otomatis.
2. Migrasi `titipo-backend-service/migrations/*` ke DB `titipo` (manual, terpisah; tidak otomatis mundur).
3. `scripts/deploy/deploy.sh deploy <release-id>`: rolling restart replika satu per satu, tunggu `/healthz` 200; gagal = rollback otomatis ke release sebelumnya.
4. Deploy web admin.
5. Smoke: `GET /healthz` + `GET /v1/contoh` dengan JWT `aud=titipo`.

Target downtime restart < 30 detik: dengan rolling 2 replika, tidak ada saat semua replika mati. `deploy.sh` melaporkan durasi total (bukan downtime terukur).

## Rollback

- Backend: `scripts/deploy/deploy.sh rollback` (kembali ke `previous`, yakni build hijau sebelumnya). Migrasi DB tidak otomatis mundur; migrasi 0001 aditif sehingga aman.
- Web: kembalikan bundle sebelumnya.
- Mobile: lihat `docs/rilis-mobile.md`.

## Perubahan dari versi sebelumnya README ini

Backup semula tertulis 02:00 WIB / retensi 14 hari. Diselaraskan ke 03.00 / 30 hari sesuai ADR-0001 dan tiket TTP-OPS-004 (ADR menang atas README). 02.00 kini ditempati job arsip tanggal 1.
