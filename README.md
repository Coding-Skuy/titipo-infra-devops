# TitipO Infra DevOps — Divisi TitipO (Community Commerce)

> CI, build, deploy, dan runbook TitipO. DB `titipo` terpisah dari `lumbung`.
> TownHall: [TitipO-TownHall](https://github.com/Coding-Skuy/TitipO-TownHall).
> Kontrak auth: [Lumbung-TownHall](https://github.com/Coding-Skuy/Lumbung-TownHall), detail `titipo-backend-service/docs/auth.md`.

## Isi

```text
ci/build-kmp.md        # build KMP (APK/AAB + iOS)
ci/build-rust-web.md   # build Rust backend + web admin
deploy/prod/README.md  # topologi prod + DB terpisah
docs/runbook.md        # runbook operasional
```

## Prinsip

- DB `titipo` dan `lumbung` instance/skema terpisah, backup terpisah.
- Secret JWT + service key via secret manager, bukan di repo.
- Setiap repo wajib CI hijau sebelum merge ke `main`.

## Tautan

- App: https://github.com/Coding-Skuy/titipo-app-kmp
- Web: https://github.com/Coding-Skuy/titipo-web
- Backend: https://github.com/Coding-Skuy/titipo-backend-service
