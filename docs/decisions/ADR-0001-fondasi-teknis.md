# ADR-0001 — Fondasi teknis titipo-infra-devops

Status: Diterima | Tanggal: 2026-10-14

## Konteks

titipo-infra-devops adalah bagian divisi TitipO (Epic E2 #3, milestone v1.0.0). Spesifikasi v1.0.0 beku sejak 2026-10-07 di [TitipO-TownHall](https://github.com/Coding-Skuy/TitipO-TownHall/blob/main/platform/versions/v1.0.0/FSD/30-kontrak.md). Repo ini memerlukan fondasi teknis yang tetap agar pengembangan oleh AI dan manusia konsisten.

## Keputusan

Keputusan kunci CEO yang berlaku untuk repo ini:

1. **Tiga pipeline CI.** build-kmp, build-rust-web, deploy prod; QA gate memblokir rilis.
2. **Secrets di secret manager.** JWT, service key, DATABASE_URL hanya di env/secret manager; rotasi service key 90 hari dengan 2 kunci aktif 7 hari.
3. **Deploy dan backup.** VPS tunggal prod; backup DB harian 03.00 retensi 30 hari; rollback = deploy ulang artefak hijau sebelumnya, migrasi DB tidak otomatis mundur.
4. **Jalur rilis mobile.** Play Store, APK sideload, dan TestFlight; rilis bertahap 20 persen ke 100 persen dalam 3 hari.

Keputusan lintas repo: satu DB logis per service, JWT beraudien divisi, kunci idempoten ULID klien pada semua POST, uang integer rupiah, waktu timestamptz UTC.

## Konsekuensi

Perubahan CI/deploy butuh ADR baru. Kegagalan backup 2 hari berturut-turut memblokir deploy fitur baru.
ADR ini immutable; perubahan keputusan ditulis sebagai ADR baru yang menggantikan.
