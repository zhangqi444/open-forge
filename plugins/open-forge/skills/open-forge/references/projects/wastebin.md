# Wastebin

**Minimal self-hosted pastebin with syntax highlighting, Markdown rendering, encryption, and a tiny footprint — built in Rust with SQLite.**
GitHub: https://github.com/matze/wastebin
Demo: https://bin.bloerg.net (resets daily)

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux | Docker Compose | Recommended |
| Any Linux | Docker run | Single container |
| Any Linux / macOS | Pre-built binary | Statically compiled, no runtime needed |
| NixOS | Nix | Nix flake available |

---

## Inputs to Collect

### All phases
- `WASTEBIN_DATABASE_PATH` — path inside container for SQLite DB (e.g. /data/state.db)
- Data volume — host path to persist the database

---

## Software-Layer Concerns

### Docker Compose
```yaml
services:
  wastebin:
    restart: always
    environment:
      - WASTEBIN_DATABASE_PATH=/data/state.db
    ports:
      - "8088:8088"
    volumes:
      - './data:/data'
    image: 'quxfoo/wastebin:latest'
```
Ensure ./data is writable by uid 10001 (the container user).

### Docker run
```bash
docker run \
  -e WASTEBIN_DATABASE_PATH=/data/state.db \
  -v /path/for/storage:/data \
  -u $(id -u):$(id -g) \
  quxfoo/wastebin:latest
```

### Ports
- `8088` — web UI

### Features
- Syntax highlighting for 170+ languages
- Markdown rendering (GFM tables, task lists, admonitions)
- 8 color themes (light and dark)
- ChaCha20Poly1305 encryption with argon2 hashed passwords
- Paste expiry, burn-after-read, or deletion by anonymous owners
- QR code for mobile sharing
- zstd compression

---

## Upgrade Procedure

1. docker compose pull
2. docker compose up -d

---

## Gotchas

- Image is scratch-based — no shell, no TMPDIR set by default; if SQLite migrations fail with error 6410, set TMPDIR to a writable path
- Ensure ./data directory is owned/writable by uid 10001
- No authentication or rate limiting — not safe to expose to the internet as-is; put behind a reverse proxy with rate limiting
- No user management or file upload support by design

---

## References
- Themes preview: https://matze.github.io/wastebin/
- GitHub: https://github.com/matze/wastebin#readme
