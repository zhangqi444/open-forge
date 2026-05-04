# Actual Budget

Local-first personal finance and budgeting tool. Actual is a fast, privacy-focused alternative to YNAB. All budget data is stored locally on your device with optional sync via a self-hosted server. The sync server (actual-server) persists changes and makes budget files available across all devices.

**Official site:** https://actualbudget.org  
**Source:** https://github.com/actualbudget/actual  
**Server source:** https://github.com/actualbudget/actual-server (readonly after merge into main repo)  
**Upstream docs:** https://actualbudget.org/docs/install/

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux host | Docker Compose | Primary self-hosted method |
| Any Linux host | Docker (single container) | No compose needed; single image |
| Node.js host | npm / yarn | Run server directly without Docker |

---

## Inputs to Collect

### All phases
| Variable | Description | Example |
|----------|-------------|---------|
| `DATA_DIR` | Host path for budget file storage | `./actual-data` |
| `HOST_PORT` | Port to expose on host | `5006` |

### Optional
| Variable | Description | Default |
|----------|-------------|---------|
| `ACTUAL_PORT` | Internal port inside container | `5006` |
| `ACTUAL_HTTPS_KEY` | Path to TLS private key (enables HTTPS) | unset |
| `ACTUAL_HTTPS_CERT` | Path to TLS certificate | unset |
| `ACTUAL_UPLOAD_FILE_SYNC_SIZE_LIMIT_MB` | Max sync file size | `20` |
| `ACTUAL_UPLOAD_SYNC_ENCRYPTED_FILE_SYNC_SIZE_LIMIT_MB` | Max encrypted sync file | `50` |
| `ACTUAL_UPLOAD_FILE_SIZE_LIMIT_MB` | Max file upload size | `20` |

---

## Software-Layer Concerns

### Docker Compose
```yaml
services:
  actual_server:
    image: docker.io/actualbudget/actual-server:latest
    ports:
      - '5006:5006'
    volumes:
      - ./actual-data:/data
    healthcheck:
      test: ['CMD-SHELL', 'node src/scripts/health-check.js']
      interval: 60s
      timeout: 10s
      retries: 3
      start_period: 20s
    restart: unless-stopped
```

To enable optional config, add an `environment:` block:
```yaml
    environment:
      - ACTUAL_PORT=5006
      - ACTUAL_UPLOAD_FILE_SYNC_SIZE_LIMIT_MB=20
```

### Data directory
- All budget files stored under `/data` in the container (mapped to `./actual-data` on host)
- Back up the `actual-data/` directory; it contains all budget databases

### HTTPS (optional, recommended for remote access)
Place TLS key and cert inside the data directory, then set:
```yaml
    environment:
      - ACTUAL_HTTPS_KEY=/data/selfhost.key
      - ACTUAL_HTTPS_CERT=/data/selfhost.crt
```
Health check for self-signed certs:
```yaml
      test: ['CMD-SHELL', 'NODE_EXTRA_CA_CERTS=/data/selfhost.crt node src/scripts/health-check.js']
```

### Client apps
Once the server is running, connect via:
- **Web app** — open `http://<host>:5006` in a browser
- **Desktop app** — available for Windows, macOS, Linux at https://actualbudget.org/download
- **Mobile** — iOS and Android apps available

On first open, create a budget file and optionally set a server password.

---

## Upgrade Procedure

1. Pull the latest image: `docker compose pull`
2. Recreate: `docker compose up -d`
3. The `/data` volume is preserved automatically
4. Check release notes: https://github.com/actualbudget/actual/releases

---

## Gotchas

- **actual-server repo is now read-only** — the server was merged into the main `actualbudget/actual` monorepo under `packages/sync-server`; the Docker image (`actualbudget/actual-server`) is still published and maintained
- **Local-first means server is optional** — Actual works entirely offline; the server is only needed for multi-device sync
- **No user accounts by default** — access is controlled by a single server password set on first run; multiple budget files are supported but not per-user auth
- **Budget files are not encrypted at rest** — the sync protocol encrypts data in transit; consider disk-level encryption for the data volume if storing sensitive financial data
- **Port 5006 default** — no conflict with common services, but configure your reverse proxy/firewall accordingly

---

## Links
- Upstream README: https://github.com/actualbudget/actual
- Install docs: https://actualbudget.org/docs/install/
- All config options: https://actualbudget.org/docs/config/
- server repo migration notice: https://actualbudget.org/docs/actual-server-repo-move
