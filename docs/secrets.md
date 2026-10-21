# Secrets dan rotasi kunci (TTP-OPS-003)

Sumber: TitipO-TownHall `platform/versions/v1.0.0/FSD/30-kontrak.md` bagian Basis dan Autentikasi; `titipo-backend-service/docs/auth.md` §2-3. Repo ini hanya menjalankan, bukan mendefinisikan, kebijakan.

## 1. Inventaris

| Nama | Fungsi | Di mana disimpan | Catatan |
|---|---|---|---|
| `DATABASE_URL` | koneksi DB `titipo` (bukan `lumbung`) | secret manager / env server | satu DB per service |
| `TITIPO_SERVICE_KEY` | kunci service titipo ke lumbung (header `X-Titipo-Service-Key`) | env backend TitipO + `LUMBUNG_TITIPO_KEYS` di sisi Lumbung | rotasi 90 hari |
| `LUMBUNG_JWKS_URL` | JWKS Lumbung untuk verifikasi JWT (cache 10 mnt, skew 60 dtk) | env | bukan rahasia, tetap dikelola sebagai konfigurasi env |
| `LUMBUNG_ISSUER` | issuer JWT | env | bukan rahasia |
| kunci JWT | lihat Ketidakselarasan 1 | secret manager | ASUMSI |

Aturan: tidak ada secret di repo, artefak CI, atau log. `.env.example` hanya berisi nama + placeholder. Keystore Android/iOS dan kunci toko tidak pernah di repo (lihat `versions/v1.0.0/docs/60-BLAST-RADIUS.md`).

## 2. Rotasi service key: 90 hari, 2 kunci aktif 7 hari

Pemilik: DevOps TitipO melakukan; pemilik backend TitipO dan Lumbung ikut menyetujui. Kunci yang sudah diputar tidak diputar balik.

| Hari | Langkah |
|---|---|
| T-7 | `scripts/secrets/rotation-status.sh <state>` mengeluarkan PERINGATAN (hari ke-83). Jadwalkan jendela. |
| T0 | Buat kunci baru K2 (acak, panjang >= 32 byte) langsung di secret manager; jangan lewat chat/log/repo. |
| T0 | Lumbung: tambahkan K2 ke `LUMBUNG_TITIPO_KEYS` di samping K1 (kini 2 kunci aktif). Catat `OVERLAP_STARTED_AT=<T0>` di berkas state. |
| T0 | TitipO: set `TITIPO_SERVICE_KEY=K2`, deploy ulang backend (restart <30 dtk). Verifikasi panggilan titipo ke lumbung sukses (bukan 401/403). |
| T0..T+7 | Dua kunci aktif. Bila K2 bermasalah, kembalikan HANYA deploy ke K1 selama K1 masih aktif; jangan membuat kunci tambahan. |
| T+7 | Lumbung: cabut K1 dari `LUMBUNG_TITIPO_KEYS`. Set `ROTATED_AT=<T0>`, hapus `OVERLAP_STARTED_AT`. K1 dihancurkan permanen. |

Berkas state hanya berisi tanggal; contoh di `deploy/secrets/rotation-state.example`. Lokasi berkas state nyata (server/secret manager): ASUMSI, belum ditetapkan. Penjadwalan pengecekan `rotation-status.sh` (mis. harian) menunggu keputusan runner, lihat `docs/runbook.md`.

## 3. Log: maks 10 MB, tanpa JWT dan service key

- `scripts/secrets/scan-log.sh <log|->` gagal (exit 1) bila log > 10 MB (10485760 byte) atau memuat JWT / `X-Titipo-Service-Key` / `TITIPO_SERVICE_KEY` bernilai / private key. Keluaran hanya nomor baris + jenis, nilai tidak pernah dicetak.
- CI: `.github/workflows/secret-scan.yml` menjalankan `scripts/secrets/scan-repo.sh` pada tiap PR.
- Penegakan di sisi aplikasi (tidak mencatat header Authorization) adalah tanggung jawab `titipo-backend-service`.

## 4. Bila secret bocor

1. Mulai penghitung: kunci harus diputar dalam 1 jam sejak terdeteksi.
2. Putar kunci yang bocor segera (prosedur §2 dipercepat: K2 dibuat, K1 dicabut dalam jam yang sama bila dampak aktif; ini mengorbankan jendela 7 hari, putusan ada di pemilik backend).
3. Bersihkan log yang memuat kebocoran; jalankan `scan-log.sh` pada log pengganti.
4. Catat audit (templat di bawah) dan eskalasi ke pemilik backend dan TownHall. Retensi audit 2 tahun (`60-BLAST-RADIUS.md`).

```text
Audit insiden kunci
Waktu terdeteksi (UTC):
Waktu kunci diputar (UTC):     (selisih <= 1 jam?)
Jenis kunci:                    (jangan tulis nilainya)
Sumber kebocoran:
Dampak / pihak terdampak:
Tindakan + penanggung jawab:
Eskalasi ke:                    (pemilik backend, TownHall)
```

## Ketidakselarasan dan asumsi (dicatat, tidak diputuskan sepihak)

1. Tiket menyebut "kunci JWT" sebagai secret TitipO, tetapi `auth.md` §1 menyatakan JWT diterbitkan layanan auth Lumbung dan TitipO hanya memverifikasi lewat JWKS. Maka TitipO tidak punya kunci penandatangan JWT sendiri menurut dokumen. Tetap dicantumkan sebagai ASUMSI sampai pemilik backend menjelaskan.
2. Masa berlaku JWT: FSD 30-kontrak.md menulis 24 jam; standar AGENTS/KONTEKS menulis akses 15 menit + refresh 7 hari. Tidak memengaruhi PR ini; dilaporkan.
3. `60-BLAST-RADIUS.md` dan `40-TECHSTACK.md` menyebut "device key" di log; tiket menyebut service key. Pemindai mencakup JWT, service key, private key; device key belum karena formatnya belum didefinisikan.
4. `auth.md` memuat `TITIPO_JWT_AUD` di daftar env; tidak disebut tiket. Dimasukkan ke `.env.example` sebagai konfigurasi non-rahasia.
