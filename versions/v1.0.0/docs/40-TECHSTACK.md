# 40-TECHSTACK — titipo-infra-devops

STATUS: defined pending (target dikunci, implementasi menunggu).

Mengacu: TitipO-TownHall v1.0.0

## 1. Target stack

| Lapisan | Teknologi + versi | Keterangan |
|---|---|---|
| CI KMP | Gradle 8.10 + AGP 8.5.2 + JDK 17 | Verifikasi pin Kotlin 2.2.20 Compose 1.8.2 Navigation3 1.0.0 |
| CI Rust | Cargo + axum 0.8.4 + sqlx + uuid v7 | Build dan migrasi backend |
| CI Web | Bun 1.4.x latest + Svelte 5 + Kit 2 + TS 5.9.x | Build dan cek tipe admin |
| Runner | VPS tunggal prod + backup harian 03.00 | Downtime target di bawah 30 detik |
| Secret | Env dan secret manager | Tanpa keystore dan service key di repo |

Pemeriksaan CI wajib: grep pin KMP di libs.versions.toml, bun build web, cargo build backend, tanpa secret di log.

## 2. Konfigurasi kunci

- Pipeline: build-kmp, build-rust-web, deploy prod; rilis mobile bertahap 20 persen ke 100 persen 3 hari.
- Backup DB titipo harian retensi 30 hari; log maksimal 10 MB tanpa JWT dan device key.
- Rotasi JWT dan service key titipo ke lumbung 90 hari didukung 2 kunci 7 hari.

## Batasan

- Hanya CI, runner, dan deploy; bukan pemilik kode fitur, fee, atau model.
- Dilarang menyimpan keystore, JWT rahasia, dan service key di repo atau artefak baca publik.
