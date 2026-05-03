# KaraKeep HomeDash

> Compact home-page dashboard for KaraKeep bookmarks — displays all bookmarks on one page in a masonry layout, organized by lists, with real-time search and drag-and-drop list reordering. Read-only companion to the KaraKeep app; reads KaraKeep's SQLite database directly.

**Official URL:** https://github.com/CodeJawn/karakeep-homedash

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Same host as KaraKeep | Docker Compose | Easiest — shared volume to KaraKeep's db.db |
| Any Linux VPS/VM | Docker | Mount KaraKeep db.db path |
| Any Linux | Python 3.7+ | `python server.py`; no extra dependencies |

**Requires:** A running KaraKeep instance with a `db.db` SQLite file

---

## Inputs to Collect

### Phase: Pre-Deploy
| Input | Description | Example |
|-------|-------------|---------|
| `karakeep_db_path` | Host path to KaraKeep's `db.db` file | `/opt/karakeep/data/db.db` |
| `karakeepUrl` | URL of your KaraKeep instance (for clicking through to manage bookmarks) | `http://karakeep:3000` |

---

## Software-Layer Concerns

### Docker Compose
```yaml
services:
  karakeep-homedash:
    image: ghcr.io/codejawn/karakeep-homedash:latest
    container_name: karakeep-homedash
    ports:
      - "8595:8595"
    volumes:
      # Point to your KaraKeep database (read-only)
      - /path/to/karakeep/db.db:/app/db.db:ro
      # Persist list order preferences
      - ./config:/app/config
    restart: unless-stopped
```

### Configuration
Auto-created at `config/config.json` on first run. Edit to customize:

```json
{
  "karakeepUrl": "http://localhost:3000",
  "bookmarkTarget": "_self",
  "preferences": {
    "columnOrder": []
  }
}
```

| Option | Description | Default |
|--------|-------------|---------|
| `karakeepUrl` | URL to KaraKeep for bookmark management links | `http://localhost:3000` |
| `bookmarkTarget` | `_self` (same tab) or `_blank` (new tab) | `_self` |
| `preferences.columnOrder` | Saved drag-and-drop list order | `[]` |

### Data Directories
| Path (container) | Purpose |
|------------------|---------|
| `/app/db.db` | KaraKeep database — mount **read-only** |
| `/app/config` | Preference JSON — bind-mount to persist list ordering |

### Ports
- Default: `8595`

### How It Works
- Uses SQLite WASM (in-browser) to query the KaraKeep database directly
- No server-side database queries — the browser fetches `db.db` and reads it locally
- All bookmark data stays in your browser; never sent to any external service

---

## Upgrade Procedure

1. Pull latest: `docker pull ghcr.io/codejawn/karakeep-homedash:latest`
2. Stop: `docker compose down`
3. Start: `docker compose up -d`
4. No database migration — KaraKeep owns the schema

---

## Gotchas

- **KaraKeep must be running** — HomeDash is read-only; all bookmark management (add, edit, delete) is done in the KaraKeep app
- **db.db path must be correct** — if the volume mount is wrong, the browser will show "Could not find db.db"; double-check the host path
- **config directory must be writable** — for drag-and-drop list ordering to persist; ensure the `./config` volume mount has write permissions
- **Browser downloads db.db** — the entire KaraKeep database is sent to the browser on each page load; for large bookmark collections this may be slow on first load
- **Schema tied to KaraKeep version** — if KaraKeep changes its database schema, HomeDash may need an update to stay compatible

---

## Links
- GitHub: https://github.com/CodeJawn/karakeep-homedash
- KaraKeep (required): https://github.com/karakeep-app/karakeep
