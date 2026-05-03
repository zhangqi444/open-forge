# DumbKan

> Lightweight, mobile-friendly Kanban board — multiple boards, drag-and-drop tasks between columns, inline editing, light/dark theme with system detection, PIN protection, file-based JSON storage (no database required). Built with vanilla JavaScript and Node.js.

**Official URL:** https://github.com/DumbWareio/DumbKan

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS/VM | Docker | Primary supported method |
| Any Linux VPS/VM | Node.js | Clone and `npm start` |
| Raspberry Pi / ARM | Docker | Lightweight enough for low-power devices |

---

## Inputs to Collect

### Phase: Pre-Deploy
| Input | Description | Default | Required |
|-------|-------------|---------|----------|
| `PORT` | Port to listen on | `3000` | No |
| `DUMBKAN_PIN` | PIN protection (4–10 digits) | none | No |
| `DATA_PATH` | Host path for persistent task data | `./data` | Yes (for persistence) |

---

## Software-Layer Concerns

### Data Directory
| Path (container) | Purpose |
|------------------|---------|
| `/app/data` | `tasks.json` — all boards, columns, and tasks |

> Mount `/app/data` as a volume to persist data across container restarts. Without it, all boards are lost on restart.

### Key Environment Variables
```
PORT=3000
DUMBKAN_PIN=1234    # optional 4-10 digit PIN
```

### Ports
| Container | Purpose |
|-----------|---------|
| `3000` | Web UI (configurable via `PORT`) |

### Storage
- File-based JSON (`/app/data/tasks.json`)
- No database — zero external dependencies
- Data is auto-saved on every change

---

## Docker Compose Example

```yaml
services:
  dumbkan:
    image: dumbwareio/dumbkan:latest
    container_name: dumbkan
    restart: unless-stopped
    ports:
      - "3000:3000"
    volumes:
      - ./data:/app/data
    environment:
      - PORT=3000
      - DUMBKAN_PIN=1234   # remove line to disable PIN
```

---

## Upgrade Procedure

1. Pull latest image: `docker pull dumbwareio/dumbkan:latest`
2. Stop container: `docker compose down`
3. Start with new image: `docker compose up -d`
4. Data persists via the mounted volume

---

## Gotchas

- **Mount `/app/data`** — without a volume, tasks.json lives only in the container layer and is lost on any restart or image update
- **PIN is optional but recommended** for internet-exposed instances — without it, anyone who can reach the URL can read and modify all boards
- **No user accounts or multi-user auth** — PIN protection is a single shared PIN for the entire instance; not suitable for multi-tenant use
- **No built-in HTTPS** — proxy with Nginx/Caddy for remote access
- **Column delete is noted as "fixing" in docs** — verify current state in release notes before relying on this feature in production

---

## Links
- GitHub: https://github.com/DumbWareio/DumbKan
- Docker Hub: https://hub.docker.com/r/dumbwareio/dumbkan
