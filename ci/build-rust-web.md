# CI Build Rust + Web

## Backend Rust (axum 0.8)

```bash
cargo fmt --check
cargo clippy -- -D warnings
cargo test
cargo build --release
```

Migrasi dicek dengan DB sementara `titipo_ci`:

```bash
export DATABASE_URL=postgres://postgres:postgres@localhost:5432/titipo_ci
sqlx migrate run --source ../titipo-backend-service/migrations
```

## Web admin (Bun 1.4.x, Svelte 5, Kit 2, TS 5.9.x)

```bash
bun install --frozen-lockfile
bun run check
bun run build
```

Artefak: image backend + bundle `build/` web admin.
