---
name: Shiori
description: Self-hosted bookmark manager (Pocket/Pinboard alternative). Web UI + CLI, full-text search across saved page content, archive mode (stores a local copy), tags, import from Pocket/HTML, browser extension. Go + SQLite/Postgres/MySQL. MIT.
---

# Shiori

Shiori is a simple, fast, single-binary bookmark manager that's the OSS answer to Pocket (shutdown in 2024/2025) and Pinboard. Save URLs with a browser extension, bookmarklet, CLI, or web UI; Shiori fetches + archives the page content locally so it's readable even if the source dies.

- **Full-text search** across saved page bodies (not just titles)
- **Archive mode** — stores a clean readable copy of each page (like Pocket's reader mode)
- **Tags** + **folders-less flat organization**
- **Import** from Pocket (export HTML), Netscape HTML bookmarks, Shaarli
- **Export** to HTML
- **Browser extension** (<https://github.com/go-shiori/shiori-web-ext>)
- **CLI** for scripting (`shiori add`, `shiori search`)
- **REST API** + web UI
- **Multi-user** with account management
- **Read-later workflow** — mark as unread/read, per-user

- Upstream repo: <https://github.com/go-shiori/shiori>
- Docker Hub: <https://hub.docker.com/r/ghcr.io/go-shiori/shiori>
- GHCR: <https://github.com/go-shiori/shiori/pkgs/container/shiori>
- Docs: <https://shiori.readthedocs.io/en/latest/>
- Browser extension: <https://github.com/go-shiori/shiori-web-ext>

## Architecture in one minute

- **Single Go binary** + web UI (embedded)
- **Database**: SQLite (default, bundled in `$SHIORI_DIR`), PostgreSQL, or MySQL via `SHIORI_DATABASE_URL`
- **Storage**: `$SHIORI_DIR` for SQLite + thumbnails + archived page content
- **Port 8080** by default

## Compatible install methods

| Infra       | Runtime                                            | Notes                                                              |
| ----------- | -------------------------------------------------- | ------------------------------------------------------------------ |
| Single VM   | Docker (`ghcr.io/go-shiori/shiori:<VERSION>`)       | **Simplest** — one container, SQLite in volume                       |
| Single VM   | Docker Compose (Postgres/MySQL + app)                | For multi-user prod                                                   |
| Single VM   | Native Go binary (`go install github.com/go-shiori/shiori@latest`) | From source                                |
| Kubernetes  | Community Helm charts                                 | Stateless app + volume                                               |
| Linux/macOS/Windows | Native binary from releases                     | Cross-platform                                                        |

## Inputs to collect

| Input                   | Example                                | Phase     | Notes                                                   |
| ----------------------- | -------------------------------------- | --------- | ------------------------------------------------------- |
| `SHIORI_DIR`            | `/srv/shiori`                           | Storage   | Data dir: SQLite DB, thumbnails, archives                 |
| `SHIORI_DATABASE_URL`   | `postgres://shiori:pw@db/shiori?sslmode=disable` | DB | Optional (SQLite default)                                 |
| `SHIORI_HTTP_ROOT_PATH` | `/shiori/`                              | Reverse proxy | If hosting under a subpath                                  |
| `SHIORI_HTTP_PORT`      | `8080`                                  | Network   | Listen port                                               |
| Admin user              | first-user-is-admin                     | Bootstrap | Create via web UI on first visit                          |
| Default login           | `shiori` / `gopher`                      | Bootstrap | **Change immediately** — well-known default              |

## Install via Docker (SQLite, simplest)

```sh
docker run -d --name shiori \
  -p 8080:8080 \
  -v shiori-data:/srv/shiori \
  -e SHIORI_DIR=/srv/shiori \
  --restart unless-stopped \
  ghcr.io/go-shiori/shiori:v1.8.0
```

Log in at `http://<host>:8080` with **`shiori` / `gopher`** (the well-known default credentials). **Change the password immediately** via Settings → Users.

## Install via Docker Compose (with Postgres)

```yaml
services:
  shiori:
    image: ghcr.io/go-shiori/shiori:v1.8.0
    container_name: shiori
    restart: unless-stopped
    ports:
      - "8080:8080"
    environment:
      SHIORI_DIR: /srv/shiori
      SHIORI_DATABASE_URL: postgres://shiori:<strong>@postgres/shiori?sslmode=disable
    volumes:
      - shiori-data:/srv/shiori
    depends_on:
      postgres: { condition: service_healthy }

  postgres:
    image: postgres:17-alpine
    container_name: shiori-db
    restart: unless-stopped
    environment:
      POSTGRES_USER: shiori
      POSTGRES_PASSWORD: <strong>
      POSTGRES_DB: shiori
    volumes:
      - shiori-db:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U shiori"]
      interval: 10s
      retries: 5

volumes:
  shiori-data:
  shiori-db:
```

## Native install

```sh
# Requires Go 1.21+
go install github.com/go-shiori/shiori@latest
export SHIORI_DIR=/var/lib/shiori
shiori serve
# Listens on :8080
```

Run under systemd for persistence (stock systemd unit pattern).

## Browser extension

Install <https://github.com/go-shiori/shiori-web-ext> (Chrome/Firefox). Configure with your Shiori URL + username/password. Click-to-bookmark from any page.

Alternative: bookmarklet (drag to bookmarks bar, click to save current page).

## First boot

1. Browse `http://<host>:8080`
2. Log in with **default `shiori` / `gopher`**
3. **Change password immediately**
4. Settings → Users → add additional users if multi-user
5. Install browser extension; configure with URL + creds
6. Start bookmarking

## Data & config layout

Inside `SHIORI_DIR` (default `/srv/shiori`):

- `shiori.db` — SQLite DB (if not using external)
- `thumb/<id>` — page thumbnails
- `archive/<id>` — archived HTML (readable offline copy)
- `ebook/<id>` — optional EPUB export of archived pages

If `SHIORI_DATABASE_URL` points to Postgres/MySQL, the DB lives there but archives/thumbnails stay in `SHIORI_DIR`.

## Backup

```sh
# Whole data dir (covers SQLite + archives + thumbnails)
docker run --rm -v shiori-data:/src -v "$PWD":/backup alpine \
  tar czf /backup/shiori-$(date +%F).tgz -C /src .

# External DB case
docker compose exec -T postgres pg_dump -U shiori shiori | gzip > shiori-db-$(date +%F).sql.gz
```

Both DB + `SHIORI_DIR` needed for full restore (archives/thumbnails not in DB).

## Upgrade

1. Releases: <https://github.com/go-shiori/shiori/releases>. Occasional.
2. `docker compose pull && docker compose up -d`. SQLite migrations run automatically.
3. **Back up before major version bumps** — schema changes are forward-only.
4. v1.5 → v1.6 → v1.7 → v1.8 in recent history; all backward-compatible.

## Gotchas

- **Default credentials are `shiori` / `gopher`** — well-known, CHANGE IMMEDIATELY. Expose after setting a strong admin password.
- **Session secret**: Shiori auto-generates a session secret on first run (stored in `SHIORI_DIR`). Losing the data dir = all users logged out.
- **Archive format** — stores a static HTML snapshot, not a headless-browser screenshot. JS-heavy pages may archive as blank; use a tool like [reader-view](https://addons.mozilla.org/firefox/addon/reader-view/) first or accept imperfect archiving.
- **No built-in OCR / PDF text extraction** — PDFs saved as attachments, not indexed. Use Wallabag or Hoarder if you need that.
- **Multi-user**: accounts are independent; each user has their own bookmarks. No per-bookmark sharing; "view as another user" isn't supported.
- **Import from Pocket**: export Pocket HTML (Pocket still supports export) → upload via Settings → Import.
- **Export to HTML** = Netscape format; restorable to most bookmark managers.
- **CLI `shiori add <URL>`** from the same host works directly against the data dir (avoids HTTP). Useful for batch import scripts.
- **Full-text search** uses SQLite FTS5 by default (good for ≤100k bookmarks) or equivalent in Postgres/MySQL.
- **Reverse proxy subpath** supported via `SHIORI_HTTP_ROOT_PATH=/shiori/` (trailing slash matters).
- **Thumbnail generation** requires the container to be able to fetch URLs + HTML parse — network access required.
- **Rate-limiting outbound** — when bulk-importing, Shiori will hammer sources fetching thumbnails + archives. If you're importing 10k Pocket URLs, expect hours.
- **No native mobile app** from upstream, but PWA works fine.
- **Dev vs prod compose**: upstream `docker-compose.yaml` has `build: .` (dev setup); for prod use the GHCR image directly.
- **MIT license** — permissive.
- **Alternatives worth knowing:**
  - **Wallabag** — more feature-rich (EPUB, RSS-per-tag, mobile apps); separate recipe
  - **Hoarder / Karakeep** — newer, more polished UX, AI tag suggestions
  - **LinkWarden** — Next.js, modern stack, collections + sharing
  - **LinkDing** — similar philosophy, Django
  - **Readeck** — clean reader-first bookmark tool
  - **Pinboard** — commercial SaaS ($11/year, archive extra)
  - **Pocket** — discontinued 2024/2025
  - **Raindrop.io / Omnivore / Memos** — varies on philosophy
  - **Bookstack / Archivebox** — different goals (wiki / full-webpage snapshot)

## Links

- Repo: <https://github.com/go-shiori/shiori>
- Docs: <https://shiori.readthedocs.io/en/latest/>
- GHCR image: <https://github.com/go-shiori/shiori/pkgs/container/shiori>
- Releases: <https://github.com/go-shiori/shiori/releases>
- Browser extension: <https://github.com/go-shiori/shiori-web-ext>
- Android (third-party client): <https://github.com/tachiyomiorg/... (search "shiori" in F-Droid)>
- Discord: <https://discord.gg/zpVZeudesF>
