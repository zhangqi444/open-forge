# Gramps Web

**Collaborative genealogy web app** — web frontend and API for Gramps, the open-source genealogy desktop application. Browse and edit family trees from any device; sync bidirectionally with Gramps Desktop. Supports multi-user collaboration with role-based access.

**Official site:** https://www.grampsweb.org  
**Source (API/backend):** https://github.com/gramps-project/gramps-web-api  
**Source (frontend):** https://github.com/gramps-project/gramps-web  
**Demo:** https://demo.grampsweb.org (login: `owner`/`owner`, `editor`/`editor`, etc.)  
**License:** AGPL-3.0

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any | Docker (official image) | Recommended; includes all dependencies |
| Any | Docker Compose (API + frontend) | Standard production setup |

---

## Inputs to Collect

### Provision phase
| Input | Description | Default |
|-------|-------------|---------|
| `HTTP_PORT` | External port | `5000` |
| `SECRET_KEY` | Flask secret key for session signing | — (required) |
| `GRAMPSWEB_TREE` | Name of the Gramps family tree | — |

### Configure phase
| Input | Description | Default |
|-------|-------------|---------|
| `GRAMPSWEB_USER_DB_URI` | SQLite URI for user database | `sqlite:////app/users/users.sqlite` |
| `GRAMPSWEB_MEDIA_BASE_DIR` | Directory for media files | `/app/media` |
| `GRAMPSWEB_SEARCH_INDEX_DB_URI` | Search index URI | `sqlite:////app/indexdir/search_index.db` |
| `GRAMPS_DATABASE_PATH` | Path to Gramps database | `/root/.gramps/grampsdb` |
| `GRAMPSWEB_EMAIL_*` | SMTP config for invitations/notifications | — |

---

## Software-layer Concerns

### Docker Compose (API + pre-built frontend)
```yaml
services:
  grampsweb:
    image: ghcr.io/gramps-project/grampsweb:latest
    ports:
      - "5000:5000"
    environment:
      GRAMPSWEB_TREE: MyFamilyTree
      GRAMPSWEB_SECRET_KEY: "change-me-to-random-string"
      GRAMPSWEB_USER_DB_URI: "sqlite:////app/users/users.sqlite"
      GRAMPSWEB_MEDIA_BASE_DIR: /app/media
      GRAMPSWEB_SEARCH_INDEX_DB_URI: "sqlite:////app/indexdir/search_index.db"
    volumes:
      - gramps_db:/root/.gramps/grampsdb
      - gramps_media:/app/media
      - gramps_users:/app/users
      - gramps_index:/app/indexdir
      - gramps_cache:/app/thumbnail_cache
    restart: unless-stopped

volumes:
  gramps_db:
  gramps_media:
  gramps_users:
  gramps_index:
  gramps_cache:
```

### Data directories (inside container)
| Path | Purpose |
|------|---------|
| `/root/.gramps/grampsdb` | Gramps family tree database |
| `/app/media` | Uploaded photos, documents, etc. |
| `/app/users` | User account SQLite database |
| `/app/indexdir` | Full-text search index |
| `/app/thumbnail_cache` | Generated image thumbnails |
| `/app/cache` | Report and export cache |

All should be persisted with Docker volumes.

### First-run admin setup
After starting the container, create the first admin user:
```bash
docker compose exec grampsweb python3 -m gramps_webapi user add admin --role 4 --fullname "Admin"
```
See docs at https://www.grampsweb.org/install_setup/setup/ for the full first-run procedure.

### Syncing with Gramps Desktop
Export a `.gramps` or `.gpkg` file from Gramps Desktop and import via the web UI, or use the Gramps Web Sync plugin for bidirectional sync.

---

## Upgrade Procedure

```bash
docker compose pull
docker compose up -d
```
Database migrations run automatically on startup.

---

## Gotchas

- **`SECRET_KEY` is required.** Use a long random string. If it changes, all sessions are invalidated.
- **Gramps tree must be created before first use.** Either import an existing `.gramps` export or create a new tree via the UI after login.
- **Media files are not in the Gramps database** — they're stored separately in `GRAMPSWEB_MEDIA_BASE_DIR`. Back up both the database volume and media volume.
- **AI chat feature** requires additional API key configuration (OpenAI or compatible) and is disabled in the demo.
- **Multi-tree support** is available but requires additional configuration — see https://www.grampsweb.org.
- **Role system:** `owner` (4), `admin` (3), `editor` (2), `contributor` (1), `member` (0) — see https://www.grampsweb.org/administration/admin/.

---

## References

- Install/setup docs: https://www.grampsweb.org/install_setup/setup/
- API backend README: https://github.com/gramps-project/gramps-web-api#readme
- Frontend README: https://github.com/gramps-project/gramps-web#readme
- Full documentation: https://www.grampsweb.org
