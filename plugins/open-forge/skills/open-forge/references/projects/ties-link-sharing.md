# Ties

**What it is:** A federated bookmark and link-sharing network. Self-host your own corner of the web to curate, organize, and share favorite pages with friends. Follows others across federated instances, browses trusted users' bookmarks for discovery, and supports public or private lists. Built in Rust on PostgreSQL.

> ⚠️ **Alpha software.** Ties is in an exploratory phase — things change between updates. Single-user instances only for now. Treat all data as potentially public, even in private lists.

**Official URL:** https://github.com/raffomania/ties
**Container:** `ghcr.io/raffomania/ties`
**Demo:** https://demo.ties.pub
**License:** AGPL-3.0
**Stack:** Rust + PostgreSQL

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS / bare metal | Docker Compose | Recommended |
| Any Linux VPS / bare metal | Binary | Single Rust binary; build from source or download release |

---

## Inputs to Collect

### Pre-deployment
- `BASE_URL` — **permanent** — forms the domain part of user handles (e.g. `https://ties.example.com`); **cannot be changed after first run**
- `ADMIN_USERNAME` / `ADMIN_PASSWORD` — initial admin account credentials
- `DATABASE_URL` — PostgreSQL connection string (e.g. `postgres://ties:ties@db/ties`)

---

## Software-Layer Concerns

**Docker Compose:**
```yaml
services:
  ties:
    image: ghcr.io/raffomania/ties
    depends_on:
      - db
    environment:
      - LISTEN=0.0.0.0:3000
      - DATABASE_URL=postgres://ties:ties@db/ties
      - RUST_LOG=info
      - BASE_URL=https://ties.example.com   # Set this permanently before first run!
      - ADMIN_USERNAME=admin
      - ADMIN_PASSWORD=changeme
    ports:
      - "3000:3000"

  db:
    image: postgres:18
    environment:
      - POSTGRES_DB=ties
      - POSTGRES_USER=ties
      - POSTGRES_PASSWORD=ties
    volumes:
      - db:/var/lib/postgresql
    command: |
      -c shared_buffers=16MB
      -c work_mem=1MB
      -c max_connections=10

volumes:
  db:
```

**Default port:** `3000`

**Binary install:** Requires Rust 1.88.0+. Build: `cargo build --release`. Run: `ties start`. Only dependency is PostgreSQL.

**Use a pinned release tag** (e.g. `ghcr.io/raffomania/ties:0.1.0`) rather than `latest` for stability — the `latest` tag tracks `main` and may include breaking changes.

**Upgrade procedure:**
1. `docker compose pull` (or pull specific tag)
2. `docker compose up -d`
3. Check release notes for migration steps

---

## Gotchas

- **`BASE_URL` is permanent** — this becomes the domain of user handles (like `you@ties.example.com`); changing it later will break federation and existing user identities
- **Alpha stage** — data schema and features change frequently; no migration guarantee between versions; back up your PostgreSQL volume before upgrading
- **Single-user only** — multi-user support is not yet implemented
- **Privacy not enforced** — private lists are not fully private yet; treat all data as public
- **AGPL-3.0** — modifications must be open-sourced if deployed publicly

---

## Links
- GitHub: https://github.com/raffomania/ties
- Demo: https://demo.ties.pub
- Vision blog post: https://www.rafa.ee/articles/introducing-linkblocks-federated-bookmark-manager/
- Releases: https://github.com/raffomania/ties/releases
