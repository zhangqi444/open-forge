---
name: Readeck
description: "Self-hosted read-later and bookmark manager that archives full content (text + images) locally. Docker. Go single binary. readeck/readeck (Codeberg). Labels, favorites, highlights, collections, full-text search, EPUB export, OPDS catalog, browser extension, API. AGPL-3.0."
---

# Readeck

**Self-hosted read-later and bookmark manager.** Save web pages and Readeck archives the full readable content — text and images — locally on your instance. No external requests from your browser after saving. Labels, favorites, highlights, collections, full-text search, EPUB export for e-readers, OPDS catalog support, and browser extensions for Firefox and Chrome. Fast Go binary, no heavy database required.

Built + maintained by **readeck** (Codeberg). AGPL-3.0.

- Upstream repo: <https://codeberg.org/readeck/readeck>
- Docker: `codeberg.org/readeck/readeck`
- Website: <https://readeck.org>
- Docs: <https://readeck.org/en/docs/>

## Architecture in one minute

- **Go** single binary — embeds its own web server and SQLite-compatible storage
- Port **8000**
- Single data volume at `/readeck`
- No external database required — embedded storage
- Resource: **very low** — Go binary; minimal RAM and CPU
- Browser extension available for Firefox and Chrome

## Compatible install methods

| Infra      | Runtime                               | Notes                                          |
| ---------- | ------------------------------------- | ---------------------------------------------- |
| **Docker** | `codeberg.org/readeck/readeck:latest` | **Primary** — single container, one volume     |
| Binary     | Single Go binary                      | Download from releases; run `./readeck serve`  |

## Install via Docker

```bash
docker run -d \
  --name readeck \
  --restart unless-stopped \
  -p 8000:8000 \
  -v readeck-data:/readeck \
  codeberg.org/readeck/readeck:latest
```

### Docker Compose

```yaml
services:
  readeck:
    image: codeberg.org/readeck/readeck:latest
    container_name: readeck
    restart: unless-stopped
    ports:
      - "8000:8000"
    volumes:
      - readeck-data:/readeck

volumes:
  readeck-data:
```

```bash
docker compose up -d
```

Visit `http://localhost:8000` → create your account on first run.

## Install via Binary

```bash
mkdir readeck-install && cd readeck-install
# Download from https://codeberg.org/readeck/readeck/releases
chmod +x readeck-*-linux-amd64
./readeck-*-linux-amd64 serve
```

## Features overview

| Feature | Details |
|---------|---------|
| Read later | Save URLs; Readeck fetches and archives full content |
| Full content archival | Text and images stored locally — no external requests from browser |
| Articles, images, videos | Detects content type and adapts archival process |
| Labels | Organise bookmarks with multiple labels |
| Favorites | Mark bookmarks as favourites |
| Archives | Move bookmarks to archive when done |
| Highlights | Highlight important text within saved articles |
| Collections | Save search queries as named collections |
| Full-text search | Find any text across all saved bookmarks |
| EPUB export | Export any article to EPUB for e-readers |
| Collection EPUB | Export a whole collection to a single EPUB book |
| OPDS catalog | Access Readeck from your e-reader's OPDS client |
| Browser extension (Firefox) | Save bookmarks in one click from Firefox |
| Browser extension (Chrome) | Save bookmarks in one click from Chrome |
| API | REST API for integrations |
| Privacy-first | No external requests from browser after saving |
| Fast | Go binary; very low resource usage |
| Single binary | No database server required |

## Browser extensions

- Firefox: <https://addons.mozilla.org/en-US/firefox/addon/readeck/>
- Chrome: <https://chromewebstore.google.com/detail/readeck/jnmcpmfimecibicbojhopfkcbmkafhee>
- Source: <https://codeberg.org/readeck/browser-extension>

## E-reader support (OPDS + EPUB)

Readeck exposes an OPDS catalog at `/opds` — add this to your e-reader (Kobo, Kindle with OPDS support, KOReader, etc.) to browse and download your bookmarks as EPUBs directly on the device.

## Production deployment

For production with systemd + NGINX reverse proxy, see the [deployment guide](https://readeck.org/en/docs/deploy).

## Gotchas

- **Image hosted on Codeberg registry.** The Docker image is at `codeberg.org/readeck/readeck:latest` — not Docker Hub. Make sure to use the full registry URL.
- **Single data volume is everything.** All bookmarks, content, and configuration are stored in `/readeck`. Back up this volume regularly.
- **AGPL-3.0 license.** Network-service usage of modified Readeck requires publishing changes under AGPL-3.0.
- **No multi-user in base install.** Readeck is primarily designed for single-user self-hosting. Check docs for multi-user configuration.
- **Content archival requires network access.** When you save a URL, Readeck fetches it server-side. Your browser never makes external requests after that — but Readeck's server needs internet access.

## Backup

```sh
# Named volume backup
docker run --rm -v readeck-data:/readeck -v $(pwd):/backup alpine \
  tar czf /backup/readeck-$(date +%F).tar.gz /readeck
```

## Upgrade

```sh
docker compose pull && docker compose up -d
```

## Project health

Active Go development, Codeberg-hosted, AGPL-3.0, browser extensions, EPUB/OPDS support.

## Read-later-family comparison

- **Readeck** — Go, full content archival, highlights, EPUB/OPDS, browser extension, AGPL-3.0
- **Wallabag** — PHP/Symfony, read-later + tagging + annotations + reading list, API, AGPL-3.0
- **Omnivore** — Node.js/Postgres, read-later + highlights + newsletters; MIT
- **Shiori** — Go, bookmark manager with content archival; MIT

**Choose Readeck if:** you want a fast, minimal self-hosted read-later app that archives full content (text + images) locally, with highlights, labels, EPUB export for e-readers, and OPDS catalog support — in a single Go binary.

## Links

- Repo: <https://codeberg.org/readeck/readeck>
- Docs: <https://readeck.org/en/docs/>
- Deployment guide: <https://readeck.org/en/docs/deploy>
- Releases: <https://codeberg.org/readeck/readeck/releases>
