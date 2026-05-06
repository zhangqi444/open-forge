---
name: trailbase
description: TrailBase recipe for open-forge. Sub-millisecond single-executable Firebase alternative built on Rust, SQLite, and Wasmtime. REST + realtime APIs, auth, admin UI, and JS/TS runtime in one binary. Self-hosted via binary or Docker. Source: https://github.com/trailbaseio/trailbase. Docs: https://trailbase.io.
---

# TrailBase

Sub-millisecond, single-executable open-source Firebase alternative built on Rust, SQLite, and Wasmtime. Provides type-safe REST and realtime APIs, authentication, an admin UI, and a JavaScript/TypeScript runtime — all in one binary with no external database or runtime dependencies. Alpha status; actively developed. Upstream: <https://github.com/trailbaseio/trailbase>. Docs: <https://trailbase.io>.

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| VPS / bare metal (Linux) | Single binary | Recommended; download from GitHub releases, no dependencies |
| VPS / bare metal | Docker Compose | Official image; mounts traildepot data directory |
| macOS / Windows | Native binary | Pre-built releases for macOS and Windows |
| Local dev | Binary or Docker | Start immediately; SQLite file created on first run |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Binary or Docker?" | Drives install steps |
| port | "Port to listen on?" | Default: 4000 |
| data | "Data directory path?" | Stores SQLite DB + uploads; default ./traildepot |
| admin | "Admin email and password?" | Created on first run |
| domain | "Public domain (for HTTPS)?" | TrailBase supports TLS; configure in admin UI or behind reverse proxy |

## Software-layer concerns

- Single binary: no external DB, no Redis, no message queue — just the binary + a data directory
- Data dir (traildepot/): contains SQLite database(s), uploaded files, JS/TS scripts
- Default port: 4000
- Admin UI: http://localhost:4000/_/admin
- Auth: built-in JWT-based auth; supports OAuth2 providers
- JS/TS runtime: Wasmtime-based; scripts live in traildepot/ and are hot-reloaded
- Multi-DB: supports multiple SQLite databases (attach additional DBs via admin)
- Geospatial: built-in R-Tree spatial indexing on SQLite
- License: OSL-3.0 (Open Software License 3.0) — check compatibility for your use case

### Docker Compose

```yaml
services:
  trail:
    image: docker.io/trailbase/trailbase:latest
    ports:
      - "${PORT:-4000}:4000"
    restart: unless-stopped
    volumes:
      - ${DATA_DIR:-.}/traildepot:/app/traildepot
    environment:
      RUST_BACKTRACE: "1"
```

> Important: Docker Compose auto-creates missing directories as root. TrailBase drops root privileges, so `traildepot/` must be pre-created with appropriate permissions:
> ```bash
> mkdir -p ./traildepot && chmod 755 ./traildepot
> ```

### Binary install (Linux)

```bash
# Download latest release
curl -L https://github.com/trailbaseio/trailbase/releases/latest/download/trail-x86_64-unknown-linux-gnu.tar.gz | tar xz
sudo mv trail /usr/local/bin/

# Run
mkdir -p ./traildepot
trail --data-dir ./traildepot run --address 0.0.0.0:4000
```

## Upgrade procedure

1. Review release notes: https://github.com/trailbaseio/trailbase/releases
2. Backup traildepot/ directory (SQLite + scripts)
3. Download new binary / pull new Docker image
4. Restart service — SQLite schema migrations run automatically

## Gotchas

- **Alpha status**: API and config may change between releases. Pin to a specific version tag in production.
- **OSL-3.0 license**: This is a copyleft license with network use provisions — review carefully for SaaS or embedded use cases.
- **traildepot/ permissions**: When using Docker, pre-create the directory as your user (not root) or you'll get PermissionDenied errors on startup.
- **SQLite concurrency**: SQLite handles concurrent reads well but serialises writes. For extreme write throughput (thousands of writes/sec), consider whether TrailBase's architecture fits your workload.
- **JS/TS scripts**: Run inside Wasmtime (WebAssembly); not all Node.js APIs are available. Check TrailBase's runtime docs for supported APIs.
- **No horizontal scaling (single file DB)**: TrailBase is designed for single-node deployment with SQLite. Multi-node clustering is not supported.
- **Backup**: SQLite backup is straightforward — `cp traildepot/*.db backup/` while idle, or use `sqlite3 .backup` for hot backup.

## Links

- Upstream repo: https://github.com/trailbaseio/trailbase
- Docs: https://trailbase.io
- Demo: https://demo.trailbase.io/_/admin (email: admin@localhost, password: secret)
- Docker Hub: https://hub.docker.com/r/trailbase/trailbase
- Release notes: https://github.com/trailbaseio/trailbase/releases
- Benchmarks: https://trailbase.io/reference/benchmarks/
- FAQ: https://trailbase.io/reference/faq/
