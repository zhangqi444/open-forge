# Faved

**Private self-hosted bookmark manager built for large collections, nested tags, and advanced organization.**
Official site: https://faved.dev
GitHub: https://github.com/denho/faved

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux | Docker Compose | PHP + Apache + SQLite bundled in image |
| Any Linux | Bare metal | PHP 8, SQLite, Apache required |

---

## Inputs to Collect

### All phases
- `DOMAIN` — public hostname (e.g. `bookmarks.example.com`)
- `PORT` — HTTP port (default `8080`)
- `SSL_PORT` — HTTPS port (default `8443`)
- `DATA_DIR` — host path for bookmark storage (mapped to `/var/www/html/storage/`)

---

## Software-Layer Concerns

### Config
- No external config file required; settings managed via web UI
- Certbot config can be mounted for TLS termination inside the container

### Data
- SQLite database stored in `/var/www/html/storage/` — no external DB required
- All data is local; no cloud sync

### Ports
- `8080` (HTTP) and `8443` (HTTPS) by default; configurable via `PORT` and `SSL_PORT` env vars

### Docker Compose
```yaml
name: faved
services:
  apache-php:
    container_name: faved-web-app
    image: denho/faved
    restart: unless-stopped
    working_dir: /var/www/html
    volumes:
      - temp-data:/tmp/
      - storage:/var/www/html/storage/
      - apache-conf:/etc/apache2/sites-enabled/
      - certbot-conf:/etc/letsencrypt/
    ports:
      - "${PORT:-8080}:80"
      - "${SSL_PORT:-8443}:443"

volumes:
  temp-data:
  storage:
  apache-conf:
  certbot-conf:
```

---

## Upgrade Procedure

1. `docker compose pull`
2. `docker compose up -d`
3. Check logs: `docker compose logs -f apache-php`

---

## Gotchas

- No external database needed — SQLite keeps things simple and portable
- Supports nested tags for hierarchical organization (e.g. `Programming → Backend → Go`)
- Browser bookmarklet available for saving without extensions
- Apple Shortcuts integration for iOS/macOS share sheet
- Import from Chrome, Safari, Firefox, Edge, Raindrop.io, Pocket with folder/tag structure preserved
- PWA installable for near-native mobile experience

---

## References
- [Installation Docs](https://faved.dev/docs/getting-started/installation)
- [Updating Docs](https://faved.dev/docs/getting-started/updating)
- [GitHub README](https://github.com/denho/faved#readme)
