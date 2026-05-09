---
name: html2rss
description: "Self-hosted RSS/JSON feed generator for any website. Ruby + Roda backend + Preact frontend. Scrapes web pages and converts them to RSS feeds. Supports Browserless for JS-heavy sites. MIT."
---

# html2rss-web

html2rss-web is a **self-hosted web service** that generates RSS and JSON feeds from any website — including sites that don't provide native RSS. It uses the [html2rss](https://github.com/html2rss/html2rss) gem for scraping + extraction, a Ruby/Roda backend for the API, and a Preact frontend for the feed directory UI.

Use it to follow news sites, forums, job boards, or any regularly-updated page that lacks an RSS feed.

- Upstream repo: <https://github.com/html2rss/html2rss-web>
- Public docs + feed directory: <https://html2rss.github.io>
- Docker Hub: <https://hub.docker.com/r/html2rss/web>
- OpenAPI spec: available at `/openapi.yaml` on your instance
- Discussions: <https://github.com/orgs/html2rss/discussions>

## Architecture in one minute

- **Backend**: Ruby + Roda (`app.rb`) — handles feed scraping, API, and serving
- **Frontend**: Preact + Vite (built assets from `frontend/dist`) — optional feed directory UI
- **Feed extraction**: `html2rss` gem — CSS-selector-based scraping
- **Optional dependency**: [Browserless](https://www.browserless.io/) — for scraping JavaScript-heavy websites (requires `BROWSERLESS_IO_API_TOKEN`)
- **Port**: `4000` — web UI and API

## Compatible install methods

| Method | Notes |
|---|---|
| **Docker Compose** (recommended) | Upstream-primary; `docker-compose.yml` in repo |
| **Docker standalone** | Single container with env vars |
| **From source** | Ruby dev environment; see `docs/README.md` |
| **Dev Container** | VS Code devcontainer for local development |

## Inputs to collect

| Input | Required | Notes |
|---|---|---|
| `HTML2RSS_SECRET_KEY` | Yes | `openssl rand -hex 32` — stops startup if missing |
| `HEALTH_CHECK_TOKEN` | Yes | Strong random token for `/api/v1/health` auth |
| `BROWSERLESS_IO_API_TOKEN` | Optional | Required to scrape JS-heavy sites (Browserless service or self-hosted) |
| `BUILD_TAG` | Yes (prod) | Build identifier; e.g. a date string or version |
| `GIT_SHA` | Yes (prod) | Git commit SHA; use `git rev-parse --short HEAD` |
| `AUTO_SOURCE_ENABLED` | Optional | `true` to allow creating feeds via API; defaults to `false` in production |

## Install via Docker Compose

The repo's `docker-compose.yml` is the upstream-primary method. Required env vars must be set before starting.

```bash
# Generate secrets
export HTML2RSS_SECRET_KEY="$(openssl rand -hex 32)"
export HEALTH_CHECK_TOKEN="$(openssl rand -hex 24)"

# Set build metadata
export BUILD_TAG="$(date +%F)"
export GIT_SHA="local"

# Optional: Browserless token for JS-heavy sites
export BROWSERLESS_IO_API_TOKEN="your-browserless-token-or-trial"

# Optional: allow feed creation via API
export AUTO_SOURCE_ENABLED=true

docker compose up -d
```

Then open:
- `http://localhost:4000/` — UI / feed directory
- `http://localhost:4000/api/v1` — API metadata
- `http://localhost:4000/openapi.yaml` — OpenAPI spec

## Feed configuration

Feeds are defined using YAML config files with CSS selectors. Example:
```yaml
channel:
  url: https://example.com/news
  title: Example News
  language: en

selectors:
  items:
    selector: "article.news-item"
  title:
    selector: "h2.title"
  link:
    selector: "a"
    extractor: href
  description:
    selector: "p.summary"
```

See the full selector reference at <https://html2rss.github.io>.

## API usage

```bash
# Create a feed (requires AUTO_SOURCE_ENABLED=true + bearer token)
curl -X POST http://localhost:4000/api/v1/feeds \
  -H "Authorization: Bearer $HEALTH_CHECK_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"url": "https://example.com/news", ...}'

# Health check
curl http://localhost:4000/api/v1/health
```

## First boot checklist

1. Set all required env vars (especially `HTML2RSS_SECRET_KEY` — app won't start without it)
2. Start with `docker compose up -d`
3. Verify at `http://localhost:4000/`
4. Review `/openapi.yaml` for full API documentation
5. Create feed configs or use the API to add sources
6. Put behind a reverse proxy (Nginx/Caddy) for public access

## Data & config layout

- Feed YAML configs: mounted into the container (see `docker-compose.yml` for volume details)
- No external database — feed definitions are file-based
- Built assets served from the container

## Backup

```bash
# Backup feed config files
tar czf html2rss-configs-$(date +%F).tgz ./feeds/

# Store HTML2RSS_SECRET_KEY and HEALTH_CHECK_TOKEN securely
```

## Upgrade

```bash
docker compose pull && docker compose up -d
```

Check releases at <https://github.com/html2rss/html2rss-web/releases> for breaking changes in config format.

## Gotchas

- **`HTML2RSS_SECRET_KEY` is mandatory in production** — missing it causes startup failure
- **Browserless is required for JS-heavy sites** — many modern sites require JavaScript execution to render content. Without Browserless, html2rss can only scrape static HTML
- **`AUTO_SOURCE_ENABLED` defaults to `false` in production** — must explicitly set `true` to allow API-based feed creation
- **Feed configs are CSS-selector-based** — requires some knowledge of the target site's HTML structure; use browser DevTools to inspect
- **Rate limiting**: Be respectful when scraping; add appropriate caching and request intervals
- **MIT license** — fully permissive

## Alternatives

| Tool | Notes |
|---|---|
| **FreshRSS** | Full RSS aggregator/reader (self-hosted) |
| **Miniflux** | Minimalist RSS reader |
| **RSS-Bridge** | PHP-based; pre-built bridges for many popular sites |
| **RSSHub** | Node.js; 1000+ pre-built adapters for popular sites |

## Links

- Repo: <https://github.com/html2rss/html2rss-web>
- html2rss core: <https://github.com/html2rss/html2rss>
- Docker Hub: <https://hub.docker.com/r/html2rss/web>
- Public docs: <https://html2rss.github.io>
- OpenAPI: `/openapi.yaml` on your instance
- Discussions: <https://github.com/orgs/html2rss/discussions>
