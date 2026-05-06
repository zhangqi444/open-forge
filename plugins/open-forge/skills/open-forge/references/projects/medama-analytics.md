---
name: medama-analytics
description: Recipe for Medama Analytics — a self-hosted, cookie-free, privacy-first website analytics platform. Single binary, no external dependencies, <1KB tracker. Go + SQLite.
---

# Medama Analytics

Self-hosted, privacy-first website analytics. Cookie-free and IP-free — compliant with GDPR, PECR, and other privacy regulations out of the box. Uses a lightweight (<1KB) JavaScript tracker. Single Go binary with embedded SQLite; runs on 256 MB RAM. OpenAPI-based server for easy dashboard integration. Upstream: <https://github.com/medama-io/medama>. Docs: <https://oss.medama.io/>. Demo: <https://demo.medama.io>.

License: Apache-2.0 (core/dashboard), MIT (tracker). Platform: Go, SQLite, Docker. Latest: v0.6.2.

## Compatible install methods

| Method | When to use |
|---|---|
| Docker (single container) | Recommended |
| Binary | Minimal-dependency single-binary install |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| auth | "Admin email and password for first login?" | Set during first run via CLI or environment |
| network | "Host port for the Medama UI/API?" | Default `8080` |
| storage | "Host path for the SQLite database?" | Persists all analytics data |

## Docker (recommended)

```bash
mkdir medama && cd medama
mkdir -p data
```

`docker-compose.yml`:
```yaml
services:
  medama:
    image: ghcr.io/medama-io/medama:latest
    restart: unless-stopped
    ports:
      - "8080:8080"
    volumes:
      - ./data:/app/data
    environment:
      - MEDAMA_APP_HOST=0.0.0.0
      - MEDAMA_APP_PORT=8080
      - MEDAMA_DATABASE_FILE=/app/data/medama.db
```

```bash
docker compose up -d
```

Dashboard at `http://your-host:8080`. On first visit, create an admin account.

## Binary install

```bash
# Download from GitHub Releases
curl -fsSL https://github.com/medama-io/medama/releases/latest/download/medama-linux-amd64 -o medama
chmod +x medama

# Run
MEDAMA_DATABASE_FILE=./medama.db ./medama
```

## Tracker integration

Add to your website's `<head>`:
```html
<script defer src="https://your-medama-host/tracker/me.js"
  data-host="https://your-medama-host"></script>
```

The tracker is <1KB, cookie-free, and does not collect IP addresses or fingerprinting data.

## Environment variables

| Variable | Default | Description |
|---|---|---|
| `MEDAMA_APP_HOST` | `0.0.0.0` | Listen address |
| `MEDAMA_APP_PORT` | `8080` | Listen port |
| `MEDAMA_DATABASE_FILE` | `./medama.db` | SQLite database file path |
| `MEDAMA_APP_DEBUG` | `false` | Enable debug logging |

## Software-layer concerns

| Concern | Detail |
|---|---|
| Database | SQLite (embedded) — single file at `MEDAMA_DATABASE_FILE` |
| Default port | `8080` |
| Tracker script | Served from `/tracker/me.js` |
| API | OpenAPI-based REST API at `/api/` |
| Resource usage | ~256 MB RAM for small sites; single binary |
| No external dependencies | No Redis, PostgreSQL, or other services needed |

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

The SQLite database file is preserved. DB migrations run automatically on startup.

## Gotchas

- **Cookie-free by design**: Medama does not use cookies or session identifiers. This means it cannot track returning vs. new visitors with the same accuracy as cookie-based analytics. This is intentional for privacy compliance.
- **Docker image on GHCR**: The image is at `ghcr.io/medama-io/medama`, not on Docker Hub. Pull may require GitHub Container Registry access (public image, no auth needed).
- **Tracker script must point to your host**: The `data-host` attribute in the tracker script must point to your own Medama instance URL, not any shared endpoint.
- **Reverse proxy for production**: For HTTPS and custom domain, place Medama behind nginx or Caddy. The binary itself only serves HTTP.
- **SQLite is the only database**: There is no PostgreSQL or MySQL option. For very high-traffic sites with many concurrent analytics writes, this may become a bottleneck.

## Upstream links

- Source: <https://github.com/medama-io/medama>
- Docs: <https://oss.medama.io/>
- Demo: <https://demo.medama.io>
- GitHub Container Registry: `ghcr.io/medama-io/medama`
