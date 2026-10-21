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

## 5. Job terjadwal (4 job)

Sumber jadwal: TitipO-TownHall FSD `30-kontrak.md` bagian Job Bun. Berlaku untuk keempat job:
- ASUMSI: lokasi eksekusi job (skrip Bun di VPS prod, dipicu cron/systemd timer) dan zona waktu (WIB) belum ditetapkan di dokumen; backend Rust bukan "Bun", jadi pemilik job perlu dikonfirmasi ke pemilik backend.
- Perintah menjalankan ulang manual tidak didefinisikan dokumen; di bawah ditulis `<perintah-job>` dan harus diisi pemilik job.
- Insiden data/DB dieskalasi ke pemilik backend, bukan diperbaiki di lapisan infra.

| Job | Jadwal | Kebijakan ulang |
|---|---|---|
| sinkron-lumbung | 04.00 | retry 3 kali, interval 30 detik |
| timeout-konfirmasi | tiap 1 menit | tidak ada (jalan lagi menit berikutnya) |
| cair-fee | 00.00 | ulang 01.00 bila gagal |
| arsip | tanggal 1 jam 02.00 | tidak disebut |

### 5.1 sinkron-lumbung (04.00, retry 3x30 dtk)

Gejala: tidak ada log sukses pukul 04.00-04.02, atau 3 retry habis.
1. Cek log job; pisahkan galat jaringan Lumbung vs 401/403.
2. 401/403: lihat bagian 3 (service key) dan bagian 2 (JWKS). Jangan membuat kunci baru di repo.
3. Jaringan/5xx Lumbung: tunggu, lalu jalankan manual `<perintah-job> sinkron-lumbung` sekali (di luar jam sibuk). Pastikan idempoten sebelum mengulang (kunci ULID klien, FSD) — bila tidak yakin, eskalasi ke pemilik backend.
4. Selesai: konfirmasi baris terakhir sinkron di log; catat insiden.

### 5.2 timeout-konfirmasi (tiap 1 menit)

Gejala: pesanan menunggu konfirmasi tidak kedaluwarsa, job tidak berjalan > 5 menit.
1. Cek timer/cron aktif dan proses tidak macet (`systemctl status <unit-job>`, ASUMSI nama unit).
2. Restart unit job; job berikutnya mengejar pesanan yang tertinggal.
3. Bila pesanan tidak bergerak setelah 3 siklus, eskalasi ke pemilik backend (jangan edit tabel `pesanan` dari infra).

### 5.3 cair-fee (00.00, ulang 01.00)

Gejala: tidak ada log sukses pukul 00.00 dan juga gagal pada ulang 01.00.
1. Cek log kedua percobaan; kumpulkan galat.
2. RISIKO pencairan ganda: JANGAN menjalankan manual sebelum pemilik backend memastikan job idempoten untuk tanggal yang sama.
3. Setelah konfirmasi, jalankan `<perintah-job> cair-fee --tanggal <YYYY-MM-DD>` (ASUMSI bentuk argumen), verifikasi jumlah baris/total dengan pemilik backend.
4. Eskalasi: kegagalan dua kali = insiden keuangan, kabari pemilik backend dan TownHall.

### 5.4 arsip (tanggal 1, 02.00)

Gejala: tidak ada log arsip pukul 02.00 tanggal 1.
1. Pastikan bukan bentrok dengan backup: backup 03.00 berjalan setelah arsip; jangan jalankan arsip manual saat `pg_dump` aktif.
2. Cek log; jalankan ulang manual `<perintah-job> arsip` di luar jam sibuk (aman diulang bila tidak ada data ganda, konfirmasi ke pemilik backend).
3. Bila arsip gagal, backup 03.00 tetap berjalan (tidak bergantung pada arsip).

## 6. Backup DB gagal / status merah

Backup harian 03.00, retensi 30 hari; log status di `$BACKUP_DIR/status.log` (`<tanggal> OK|FAIL`).
1. `scripts/backup/check-backup-status.sh` — HIJAU/KUNING/MERAH. 1 hari gagal = KUNING: perbaiki hari itu.
2. 2 hari berturut gagal (atau tanpa entri) = MERAH: deploy fitur baru diblokir (`deploy.sh` menolak). Hotfix keamanan butuh keputusan manusia pemilik backend; belum ada jalur bypass di skrip.
3. Diagnosa: `DATABASE_URL` menunjuk DB `titipo`, ruang disk `$BACKUP_DIR`, kredensial `pg_dump`. Jalankan ulang manual: `BACKUP_DATE=$(date -u +%F) scripts/backup/backup-db.sh`.
4. Restore hanya dari `titipo-*.dump` (bukan `lumbung-*`): `pg_restore --clean --if-exists -d <DB-titipo> titipo-YYYY-MM-DD.dump` ke DB sementara dahulu, verifikasi, baru ke prod atas persetujuan pemilik backend.

## 7. Deploy gagal / rollback

1. `scripts/deploy/deploy.sh deploy <id>` otomatis rollback bila `/healthz` tidak 200 dalam 15 dtk per replika.
2. Rollback manual: `scripts/deploy/deploy.sh rollback` (kembali ke build hijau sebelumnya).
3. Migrasi DB tidak otomatis mundur. Bila migrasi baru tidak aditif, rollback kode bisa tidak kompatibel: eskalasi ke pemilik backend sebelum rollback.
4. Setelah rollback, catat di CHANGELOG/insiden dan blokir rilis ulang sampai akar masalah jelas.

## 8. Rilis mobile bertahap

Lihat `docs/rilis-mobile.md` (20% ke 100% dalam 3 hari, halt, rollback).
