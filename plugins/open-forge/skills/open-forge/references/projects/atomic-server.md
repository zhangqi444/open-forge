# AtomicServer

Lightweight CMS and graph database built on the Atomic Data specification. AtomicServer provides tables (like Airtable), documents (like Notion), file management, group chat, real-time sync via WebSockets, and a full REST/JSON-AD API — all in an 8MB binary with no runtime dependencies.

**Official site:** https://atomicdata.dev/

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux host | Docker Compose | Recommended; single-container deployment |
| Any Linux host / macOS / Windows | Binary | Self-contained binary, no dependencies |
| Kubernetes | Deployment + PVC | Use `joepmeneer/atomic-server` image |
| Raspberry Pi / ARM | Docker or binary | ARM64 builds available on GitHub Releases |

---

## Inputs to Collect

### Phase 1 — Planning
- Domain name for public URL (AtomicServer has built-in TLS/Let's Encrypt support)
- Whether to use built-in HTTPS or put a reverse proxy in front
- Storage volume path

### Phase 2 — Deployment
- `ATOMIC_SERVER_URL` — public-facing URL (used for identity and resource URLs)
- `ATOMIC_INITIALIZE` — set to `true` on first run to create admin user
- Admin agent secret (auto-generated on first run)

---

## Software-Layer Concerns

### Docker Compose

```yaml
services:
  atomic-server:
    env_file: ".env"
    image: joepmeneer/atomic-server
    container_name: atomic-server
    ports:
      - "80:80"
      - "443:443"   # if using built-in TLS
    volumes:
      - atomic-storage:/atomic-storage

volumes:
  atomic-storage:
    driver: local
```

Generate the `.env` file:
```bash
atomic-server generate-dotenv
# or: docker run --rm joepmeneer/atomic-server generate-dotenv
```

### Key `.env` Variables
| Variable | Purpose |
|----------|---------|
| `ATOMIC_SERVER_URL` | Public URL (e.g. `https://atomic.example.com`) |
| `ATOMIC_INITIALIZE` | `true` to initialize on first run |
| `ATOMIC_PORT` | HTTP port (default `80`) |
| `ATOMIC_PORT_HTTPS` | HTTPS port (default `443`) |
| `ATOMIC_EMAIL` | Email for Let's Encrypt certificate |
| `ATOMIC_DEVELOPMENT` | `true` for dev mode (disables TLS) |

### Binary Install

```bash
# Download from GitHub Releases
wget https://github.com/atomicdata-dev/atomic-server/releases/latest/download/atomic-server-linux-x86_64
chmod +x atomic-server-linux-x86_64
sudo mv atomic-server-linux-x86_64 /usr/local/bin/atomic-server

# Run
atomic-server generate-dotenv > .env
atomic-server run
```

### Data Storage
- Default path: `/atomic-storage` (Docker) or `~/.config/atomic-server/` (binary)
- Single embedded database (sled) — no external DB required

### Cargo Install (Rust)
```bash
cargo install atomic-server
```

---

## Upgrade Procedure

**Docker:** `docker compose pull && docker compose up -d`

**Binary:** Download new release binary from GitHub Releases, replace the old binary, restart.

AtomicServer handles data migrations automatically on startup.

---

## Gotchas

- **Built-in TLS:** AtomicServer can handle Let's Encrypt itself — you don't need a reverse proxy, but you can use one if preferred. Set `ATOMIC_SERVER_URL` to your HTTPS URL.
- **Admin secret is shown once** on first init — save it immediately. It's used to log in to the admin panel.
- **Resource URLs are permanent** — changing `ATOMIC_SERVER_URL` after data has been created breaks all resource identifiers. Set it correctly from the start.
- **Alpha status:** The project labels itself alpha; breaking changes can occur until 1.0.
- **Port 80 required** for Let's Encrypt HTTP challenge — ensure it's accessible during certificate issuance.
- **`joepmeneer/atomic-server`** is the official Docker image (maintained by the lead developer).

---

## References
- GitHub: https://github.com/atomicdata-dev/atomic-server
- Docs: https://docs.atomicdata.dev/atomicserver/installation
- Docker Hub: https://hub.docker.com/r/joepmeneer/atomic-server
- Releases: https://github.com/atomicdata-dev/atomic-server/releases
- Atomic Data spec: https://docs.atomicdata.dev/
