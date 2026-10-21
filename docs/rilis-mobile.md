# Rilis mobile bertahap (TTP-OPS-004)

Sumber: ADR-0001 butir 4 (Play Store, APK sideload, TestFlight; bertahap 20 persen ke 100 persen dalam 3 hari) dan `versions/v1.0.0/docs/60-BLAST-RADIUS.md` (biner mobile rollback via rilis toko sebelumnya). Tanpa rilis Windows MSIX/EXE untuk TitipO.

## Jadwal (3 hari)

| Hari | Play Store (staged rollout) | Syarat lanjut |
|---|---|---|
| 1 | 20% | QA gate hijau (`docs/ci.md`), smoke di perangkat nyata |
| 2 | 50% (ASUMSI: hanya 20% dan 100% yang ditetapkan dokumen) | tidak ada insiden hari 1 |
| 3 | 100% | tidak ada insiden hari 2 |

Kriteria halt (ASUMSI, angka ambang belum ada di dokumen; tetapkan bersama pemilik app-kmp): lonjakan crash/ANR dibanding versi sebelumnya, login/checkout gagal massal, atau galat 401/403 massal.

## Per jalur

- **Play Store**: staged rollout lewat Play Console. Halt = hentikan rollout; rollback = rilis ulang build sebelumnya dengan versionCode lebih tinggi (Play tidak menurunkan versionCode).
- **TestFlight**: ASUMSI hanya kanal beta; persen rollout bertahap berlaku untuk App Store, bukan TestFlight (kelompok penguji dibesarkan bertahap). Cakupan 20% ke 100% untuk iOS perlu klarifikasi.
- **APK sideload**: ASUMSI diedarkan lewat tautan terkontrol; bertahap = membagikan tautan ke kelompok bertahap. Tidak ada mekanisme otomatis.

## Rollback

1. Halt rollout di toko.
2. Rilis ulang biner hijau sebelumnya (Play) / tarik tautan sideload / nonaktifkan build TestFlight.
3. Backend yang dikonsumsi harus kompatibel dengan kedua versi app selama rollout; migrasi DB tidak otomatis mundur.

## Belum diimplementasikan

Pipeline rilis (unggah ke Play/TestFlight) butuh keystore dan kredensial toko di secret manager (tidak boleh di repo); dibuat di tiket lanjutan bersama pemilik app-kmp. Dokumen ini hanya prosedur.
