# Runbook TitipO

DB `titipo` terpisah — jangan campur dengan `lumbung`.

## 1. Backend 5xx / /healthz gagal

1. Cek `GET /healthz` langsung ke pod.
2. Cek log `titipo-backend-service`, filter error sqlx/axum.
3. Cek `DATABASE_URL` menunjuk ke DB `titipo` (bukan `lumbung`).
4. Restart deploy bila perlu; eskalasi bila 2 restart gagal.

## 2. JWT ditolak (401/403 massal)

1. Pastikan `LUMBUNG_JWKS_URL` dapat dijangkau.
2. Pastikan `aud=titipo` (bukan `lumbung`/`titeny`).
3. Cek rotasi kunci Lumbung — refresh cache JWKS.

## 3. Service key titipo→lumbung gagal

1. Cek header `X-Titipo-Service-Key` terkirim.
2. Cocokkan dengan `LUMBUNG_TITIPO_KEYS` di sisi Lumbung.
3. Bila rotasi, aktifkan 2 kunci selama 7 hari.

## 4. DB titipo penuh/lambat

1. Cek indeks `idx_pesanan_jadwal`, `idx_pesanan_vendor`.
2. Vacuum tabel `pesanan` bila bloat.
3. Restore hanya dari backup `titipo-*`, bukan `lumbung-*`.

Kontak: Divisi TitipO via TitipO-TownHall. Kontrak auth: Lumbung-TownHall.
