# 60-BLAST-RADIUS — titipo-infra-devops

> Versi: v1.0.0 | Status: disetujui | Menggantikan: -
> Acuan: [TitipO-TownHall platform/versions/v1.0.0](https://github.com/Coding-Skuy/TitipO-TownHall/tree/main/platform/versions/v1.0.0) (BRD/PRD/FRD/FSD/SRS beku 2026-10-07).

## Konsumen

- Konsumen langsung: semua repo TitipO (KMP, web, backend, AI, pipeline, desain) memakai CI dan deploy repo ini.
- Hulu: secret manager (JWT, service key, DATABASE_URL) dan signing key toko aplikasi.
- Hilir: VPS prod, backup storage, dan log terpusat.

## Failure

- Runner down: semua CI antre; kode tetap aman di repo; deploy ditahan sampai runner pulih.
- Secret bocor di log: putar kunci dalam 1 jam; blokir perangkat bila device key terlibat; audit 2 tahun.
- Deploy prod gagal: restart service gagal; rollback ke build sebelumnya; migrasi DB tidak otomatis mundur.
- Backup gagal 2 hari berturut: status merah; perbaiki sebelum deploy fitur baru.

## Rollback

- Rollback berarti jalankan ulang job deploy dengan artefak versi sebelumnya yang sudah hijau.
- Biner mobile rollback via rilis toko sebelumnya; backend dan web via restart build sebelumnya.
- Kunci yang sudah diputar tidak diputar balik; rollback tidak menyentuh secret.

## Batasan

- Dampak maksimal CI dan deploy; tidak mengubah aturan bisnis 20.00, 06.00–08.00, fee 12 persen, repeat 40 persen.
- Insiden kunci dan DB dieskalasi ke pemilik backend dan TownHall, bukan simpan kunci baru di repo.

## Boleh disentuh

Pipeline CI, skrip deploy, runbook, jadwal backup, konfigurasi secret manager.

## Dilarang

Keystore/service key di repo, mengubah aturan bisnis, mengedit kode fitur repo lain, akses DB Lumbung.

## Kontrak yang dikonsumsi

Repo TitipO lain (artefak build); secret manager.

## Kontrak yang diproduksi

Artefak rilis (APK/TestFlight, biner Rust, build web), runbook 4 job, backup DB 03.00.

Sumber batas: [townhall-roadmap.md §2](https://github.com/Coding-Skuy/ChefGenie-TownHall/blob/main/townhall-roadmap.md) baris TitipO (pesan <=20.00, serah 06.00-08.00; sinyal `pedaree.stok.v1` anjuran saja; fee vendor 12%) dan [KONTEKS-LINTAS-DIVISI.md](https://github.com/Coding-Skuy/ChefGenie-TownHall/blob/main/KONTEKS-LINTAS-DIVISI.md) §3, §8, §9.
