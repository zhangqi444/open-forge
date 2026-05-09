---
name: scraperr
description: Scraperr recipe for open-forge. Self-hosted, no-code web scraping platform with XPath-based extraction, job queue management, domain spidering, and media downloads. Stack: Next.js + FastAPI + MongoDB. Upstream: https://github.com/jaypyles/Scraperr
---

# Scraperr

A self-hosted, no-code web scraping platform. Submit URLs, define XPath selectors via the UI, manage a scraping job queue, spider entire domains, download media, and export results to CSV or Markdown — no programming required. Upstream: <https://github.com/jaypyles/Scraperr>. License: MIT.

Scraperr is a two-service Docker stack: a Next.js frontend and a FastAPI backend. MongoDB is used as the job/results store (mounted as a local volume).

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux host | Docker Compose | Recommended — two-container stack from upstream. |
| Any Linux host | Docker Compose (dev mode) | `make build up-dev` for live-reload development. |
| Kubernetes | Helm | Upstream documents Helm deployment in their docs. |

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| preflight | "Which port should the Scraperr web UI be accessible on?" | Integer | Default `80` (maps to container port `3000`). |
| preflight | "Which port should the Scraperr API be accessible on?" | Integer | Default `8000`. Only needed if exposing the API separately. |
| preflight (optional) | "OpenAI API key for AI-assisted scraping features?" | Secret string | Optional — maps to `OPENAI_KEY`. Leave blank to skip. |
| preflight | "Directory for scraped data and media storage?" | Directory path | Mapped as `./data` and `./media` by default. |

## Software-layer concerns

### Environment variables

| Variable | Service | Purpose |
|---|---|---|
| `NEXT_PUBLIC_API_URL` | Frontend | URL the browser uses to reach the API (e.g. `http://<host>:8000`) |
| `SERVER_URL` | Frontend | URL the Next.js SSR server uses to reach the API container (Docker internal: `http://scraperr_api:8000`) |
| `OPENAI_KEY` | API | Optional OpenAI API key for AI-assisted extraction |
| `LOG_LEVEL` | API | Logging verbosity (`INFO`, `DEBUG`, etc.) |

### docker-compose.yml (from upstream)

```yaml
services:
  scraperr:
    image: jpyles0524/scraperr:latest
    container_name: scraperr
    command: ["npm", "run", "start"]
    environment:
      - NEXT_PUBLIC_API_URL=http://scraperr_api:8000  # browser-facing API URL
      - SERVER_URL=http://scraperr_api:8000           # internal container URL
    ports:
      - 80:3000
    networks:
      - web
  scraperr_api:
    init: true
    image: jpyles0524/scraperr_api:latest
    environment:
      - LOG_LEVEL=INFO
      - OPENAI_KEY=${OPENAI_KEY}
    container_name: scraperr_api
    ports:
      - 8000:8000
    volumes:
      - "$PWD/data:/project/app/data"
      - "$PWD/media:/project/app/media"
    networks:
      - web

networks:
  web:
```

Source: <https://github.com/jaypyles/Scraperr/blob/master/docker-compose.yml>

> **Important:** `NEXT_PUBLIC_API_URL` is the URL the **browser** uses to reach the API — it must be externally reachable. `SERVER_URL` is the URL the Next.js server-side renderer uses — it points to the internal Docker service name `scraperr_api`.

### Quick start

```bash
git clone https://github.com/jaypyles/Scraperr.git
cd Scraperr
make up          # starts with docker compose up -d
```

For development (live reload):

```bash
make build up-dev
```

### Data persistence

Scraped results and downloaded media are stored in the bind-mounted `./data` and `./media` directories. These are relative to where you run `docker compose up`. Set absolute paths in production to avoid accidental deletion.

## Upgrade procedure

```bash
docker compose pull
docker compose up -d --force-recreate
```

Data in `./data` and `./media` persists across upgrades. Check the upstream changelog for any breaking API or schema changes before upgrading.

## Gotchas

- **`NEXT_PUBLIC_API_URL` vs `SERVER_URL`** — The two API URL variables serve different purposes. `NEXT_PUBLIC_API_URL` is embedded in the browser-side JS bundle and must be an externally reachable address. `SERVER_URL` is used only in server-side rendering and should point to the internal Docker hostname `scraperr_api`. Setting them both to the internal address breaks browser-side API calls.
- **No authentication by default** — Scraperr's upstream `docker-compose.yml` does not include any authentication layer. Exposing it on a public IP without a reverse proxy + auth (Basic Auth, OAuth2-Proxy, Authelia) gives anyone on the internet access to your scraping queue.
- **robots.txt and ToS compliance** — Scraperr is intended for sites that explicitly permit scraping. Respect `robots.txt` and each site's Terms of Service. The maintainer accepts no responsibility for misuse.
- **OpenAI key is optional** — if `OPENAI_KEY` is left blank, AI-assisted extraction features are disabled; the base scraping functionality works without it.
- **Media storage can grow large** — the `./media` volume accumulates all downloaded images, videos, and files. Monitor disk usage and prune periodically.
- **MongoDB is embedded** — Scraperr uses an in-container MongoDB instance; there is no separate MongoDB service in the default Compose file. Data lives in the `./data` volume bind mount.

## Upstream docs

- GitHub: <https://github.com/jaypyles/Scraperr>
- Documentation site: <https://scraperr-docs.pages.dev>
- Helm deployment guide: <https://scraperr-docs.pages.dev/guides/helm-deployment>
- Discord: <https://discord.gg/89q7scsGEK>
