# DumbDo

> Stupidly simple self-hosted todo list. No database — todos persist in a single JSON file. Optional PIN protection, PWA support, dark/light mode, and fully responsive. Part of the DumbWare "it just works" ecosystem.

**Official URL:** https://github.com/DumbWareio/DumbDo

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS/VM | Docker | Single container; image on Docker Hub |
| Any Linux VPS/VM | Docker Compose | Recommended for persistent data |
| Any | Node.js (npm) | `npm install && npm start` |

---

## Inputs to Collect

### Phase: Pre-Deploy
| Input | Description | Default |
|-------|-------------|---------|
| `PORT` | HTTP listen port | `3000` |
| `DUMBDO_PIN` | Optional PIN (4–10 digits) for access protection | _(none — unprotected)_ |
| `SINGLE_LIST` | Show only a single list without the list selector | `false` |
| `DUMBDO_SITE_TITLE` | Browser tab/title customization | `DumbDo` |
| `ALLOWED_ORIGINS` | CORS origin restriction (comma-separated URLs) | `*` |

---

## Software-Layer Concerns

### Config & Environment
- No database — todos stored in `data/todos.json` (auto-created on first run)
- All config via environment variables

### Data Directories
| Path (container) | Purpose |
|------------------|---------|
| `/app/data` | `todos.json` — all todo data |

### Docker Compose
```yaml
services:
  dumbdo:
    image: dumbwareio/dumbdo:latest
    container_name: dumbdo
    restart: unless-stopped
    ports:
      - "${DUMBDO_PORT:-3000}:3000"
    volumes:
      - ${DUMBDO_DATA_PATH:-./data}:/app/data
    environment:
      - DUMBDO_PIN=${DUMBDO_PIN:-}
      - DUMBDO_SITE_TITLE=DumbDo
      # - ALLOWED_ORIGINS=https://yourdomain.com
```

### Docker CLI
```bash
docker run -p 3000:3000 -v $(pwd)/data:/app/data dumbwareio/dumbdo:latest
```

### Backup & Restore
- **Backup**: copy `data/todos.json`
- **Restore**: place backup file at `data/todos.json` before starting the container

---

## Upgrade Procedure

1. Pull latest: `docker pull dumbwareio/dumbdo:latest`
2. Stop and remove old container: `docker compose down`
3. Start with new image: `docker compose up -d`
4. No migration needed — JSON file format is stable

---

## Gotchas

- **No user accounts** — PIN is a single shared secret for the whole instance; not per-user
- **PWA install** available on mobile — add to home screen for app-like experience
- **No built-in TLS** — place behind Nginx/Caddy with HTTPS for remote access
- **`ALLOWED_ORIGINS=*` by default** — restrict to your domain in production if PIN is not set
- **`NODE_ENV=development`** disables origin restrictions entirely — only use for local dev

---

## Links
- GitHub: https://github.com/DumbWareio/DumbDo
- Docker Hub: https://hub.docker.com/r/dumbwareio/dumbdo
