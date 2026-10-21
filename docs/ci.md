# CI 3 pipeline + QA gate (TTP-OPS-002)

Tiga workflow reusable di `.github/workflows/` dipanggil dari repo TitipO lain. Sumber persyaratan: `SRS/40-acceptance-criteria.md` (QA-001..QA-004) di TitipO-TownHall.

| Pipeline | Berkas | Dipanggil dari | Isi |
|---|---|---|---|
| KMP | `ci-kmp.yml` | `titipo-app-kmp` | verifikasi pin (`scripts/ci/verify-kmp-pins.sh`), `gradle test`, APK debug (artefak 7 hari) |
| Rust | `ci-rust.yml` | `titipo-backend-service` | `fmt`, `clippy -D warnings`, `cargo test` (Postgres 16 service untuk `#[sqlx::test]`), build release, job coverage (tidak memblokir) |
| Web | `ci-web.yml` | `titipo-web` | `bun install --frozen-lockfile`, `bun run check`, `bun test`, `bun run build` |

## Contoh pemanggil (di repo konsumen)

```yaml
name: ci
on: { pull_request: {}, push: { branches: [main] } }
jobs:
  rust:
    uses: Coding-Skuy/titipo-infra-devops/.github/workflows/ci-rust.yml@main
  qa-gate:
    needs: [rust]
    if: always()
    runs-on: ubuntu-latest
    steps:
      - run: '[ "${{ needs.rust.result }}" = "success" ]'
```

## QA gate

- QA-002: `cargo test` tanpa `--skip`/`--ignored`; test merah = job merah. Tidak ada flag skip untuk rilis.
- QA-004: job `coverage` (cargo-llvm-cov) menulis ringkasan ke step summary + artefak 30 hari; target >80% path kritis dilacak per sprint, tidak memblokir.
- Job bernama `qa-gate` di tiap repo adalah kandidat required status check untuk `main`. Mengaktifkannya = pengaturan branch protection (di luar PR ini); usulan dicatat di ADR-0002 (siklus 3).
- Repo ini sendiri: `qa-gate.yml` menjalankan actionlint, yamllint, dan seluruh `scripts/*/tests/test-*.sh`.

## Asumsi (belum ada kontrak tertulis)

1. Repo konsumen memakai Gradle 8.10 tanpa wrapper di CI (`setup-gradle` memasang 8.10); modul `:composeApp` sesuai `ci/build-kmp.md`.
2. `bun run check` = svelte-check dan `tsconfig` memakai `"strict": true` (tidak diverifikasi dari sini).
3. `bun-version` default `latest` (techstack: "Bun 1.4.x latest").
4. Jalur rilis mobile (Play Store, APK sideload, TestFlight) butuh keystore/kredensial toko di secret manager; belum diimplementasikan di PR ini. Rencana bertahap 20% ke 100% ada di tiket TTP-OPS-004.
5. Secret tidak dipakai di tiga pipeline ini; kredensial Postgres CI adalah nilai sementara untuk service container.
