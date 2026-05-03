# BookHeaven Server

> Self-hosted ebook library server — organize books by author, series, and tags; edit and persist metadata (including cover) back into ebook files; fetch covers and metadata from the internet; track reading progress (start/finish dates, percentage, elapsed time); manage fonts for download by reader devices; multi-profile support; OPDS v1 feed; KOReader sync. Companion client apps available.

**Official URL:** https://github.com/BookHeaven/BookHeaven.Server  
**Docs:** https://bookheaven.ggarrido.dev/getting-started  
**API reference:** https://bookheaven.ggarrido.dev/api-reference

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS/VM | Docker | Primary supported method |
| Any Linux VPS/VM | Docker Compose | Recommended for production |
| Any Linux VPS/VM | Podman | Supported; use `--userns=keep-id` |

---

## Inputs to Collect

### Phase: Pre-Deploy
| Input | Description | Example |
|-------|-------------|---------|
| `DATA_PATH` | Host path for books, covers, fonts, DB | `./data` |
| `IMPORT_PATH` | Optional: folder to drop books for import | `./import` |
| `SERVER_URL` | Public URL of your instance (for auto-discovery) | `https://bookheaven.yourdomain.tld` |
| `TZ` | Timezone | `America/New_York` |
| `PUID` | User ID to run as | `1000` |
| `PGID` | Group ID to run as | `1000` |

---

## Software-Layer Concerns

### Data Directory
| Path (container) | Purpose |
|------------------|---------|
| `/app/data` | All persistent data: books, covers, fonts, SQLite DB — **bind-mount required** |
| `/app/import` | Optional drop folder; files placed here get imported automatically |

> ⚠️ **Do NOT map `/app/data` to a network share (NFS, SMB, etc.)** — BookHeaven uses SQLite, which is known to corrupt on network filesystems.

### Ports
| Container | Purpose |
|-----------|---------|
| `8080` | Web UI + API |
| `27007/udp` | Auto-discovery (for client apps; hardcoded port — do not change) |

### OPDS
- OPDS v1 feed available at: `<SERVER_URL>/opds/v1`
- Add to any OPDS-compatible reader

### KOReader Sync
- Set your BookHeaven server URL as a custom KOReader sync server
- Use your profile name as the username; password can be anything

---

## Docker Compose Example

```yaml
services:
  bookheaven:
    image: ghcr.io/bookheaven/bookheaven-server:latest
    container_name: bookheaven
    restart: unless-stopped
    user: "1000:1000"
    ports:
      - "8080:8080"
      - "27007:27007/udp"
    volumes:
      - ./data:/app/data
      - ./import:/app/import
    environment:
      - SERVER_URL=https://bookheaven.yourdomain.tld
      - TZ=America/New_York
```

Alternative image (Docker Hub): `docker.io/heasheartfire/bookheaven-server:latest`

---

## Upgrade Procedure

1. Pull latest image: `docker pull ghcr.io/bookheaven/bookheaven-server:latest`
2. Stop container: `docker compose down`
3. Start with new image: `docker compose up -d`
4. Any DB migrations run automatically on startup
5. Check logs: `docker compose logs -f`

---

## Gotchas

- **Do not use network shares for `/app/data`** — SQLite + NFS/SMB = data corruption risk
- **Auto-discovery port 27007/udp is hardcoded** — client apps expect exactly this port; it cannot be changed
- **`SERVER_URL` must be set** for auto-discovery to work; include the protocol (`http://` or `https://`)
- **Metadata edits are written back to ebook files** — changes are persistent and modify the source files, not just the database
- **No built-in auth** — currently profiles are not password-protected; plan accordingly for public exposure
- **Roadmap is active** — check the [roadmap discussion](https://github.com/orgs/BookHeaven/discussions/2) for upcoming features before deploying

---

## Links
- GitHub: https://github.com/BookHeaven/BookHeaven.Server
- Getting started guide: https://bookheaven.ggarrido.dev/getting-started
- API reference: https://bookheaven.ggarrido.dev/api-reference
- Roadmap: https://github.com/orgs/BookHeaven/discussions/2
