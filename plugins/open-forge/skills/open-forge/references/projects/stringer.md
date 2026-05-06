---
name: stringer
description: Stringer recipe for open-forge. Self-hosted anti-social RSS reader. No social features, no recommendations — just feeds. Ruby on Rails + PostgreSQL. Self-hosted via Docker Compose or VPS. Source: https://github.com/stringer-rss/stringer. Docs: https://github.com/stringer-rss/stringer/tree/main/docs.
---

# Stringer

Self-hosted, anti-social RSS reader. No sharing features, no recommendations, no tracking — just your feeds and keyboard shortcuts. Built on Ruby on Rails with PostgreSQL and GoodJob background processing. Upstream: <https://github.com/stringer-rss/stringer>. Docs: <https://github.com/stringer-rss/stringer/tree/main/docs>.

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| VPS / bare metal | Docker Compose + PostgreSQL | Recommended; upstream docker-compose.yml available |
| VPS / bare metal | Ruby on Rails native (VPS.md) | Requires Ruby 3.x, PostgreSQL, bundler |
| Heroku | Heroku deploy button | Upstream-supported; runs on Eco/Basic plan |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Docker, native VPS, or Heroku?" | Drives install path |
| db | "PostgreSQL password?" | For stringer DB user |
| secrets | "SECRET_KEY_BASE (64-char hex)?" | Generate: openssl rand -hex 64 |
| secrets | "ENCRYPTION_PRIMARY_KEY?" | Generate: openssl rand -hex 64 |
| secrets | "ENCRYPTION_DETERMINISTIC_KEY?" | Generate: openssl rand -hex 64 |
| secrets | "ENCRYPTION_KEY_DERIVATION_SALT?" | Generate: openssl rand -hex 64 |
| port | "Port for Stringer?" | Default: 8080 (Docker); configure behind reverse proxy for HTTPS |

## Software-layer concerns

- Config: environment variables (DATABASE_URL, SECRET_KEY_BASE, encryption keys)
- Default port: 8080 (Docker); 80 (compose with port mapping)
- Feed fetching: background job (GoodJob); configurable cron via FETCH_FEEDS_CRON env var (default: every 5 min)
- Cleanup cron: old read stories pruned per CLEANUP_CRON (default: daily at midnight)
- No multi-user: Stringer is designed for a single user. All feeds are under one account.
- Mobile: responsive UI; works in mobile browsers

### Docker Compose

```yaml
services:
  stringer-postgres:
    image: postgres:16-alpine
    restart: always
    networks:
      - stringer-network
    volumes:
      - stringer-data:/var/lib/postgresql/data
    environment:
      POSTGRES_PASSWORD: <db-password>
      POSTGRES_DB: stringer

  stringer:
    image: stringerrss/stringer:latest
    restart: always
    depends_on:
      - stringer-postgres
    ports:
      - "80:8080"
    networks:
      - stringer-network
    environment:
      PORT: 8080
      DATABASE_URL: postgres://postgres:<db-password>@stringer-postgres/stringer
      SECRET_KEY_BASE: <openssl-rand-hex-64>
      ENCRYPTION_PRIMARY_KEY: <openssl-rand-hex-64>
      ENCRYPTION_DETERMINISTIC_KEY: <openssl-rand-hex-64>
      ENCRYPTION_KEY_DERIVATION_SALT: <openssl-rand-hex-64>
      FETCH_FEEDS_CRON: "*/5 * * * *"
      CLEANUP_CRON: "0 0 * * *"

networks:
  stringer-network:

volumes:
  stringer-data:
```

> The upstream docker-compose.yml uses a setup container and .env file. The above is a simplified standalone version. For the canonical upstream approach, copy docker-compose.yml from the repo and create a `.env` file.

### Generate all secrets at once

```bash
for key in SECRET_KEY_BASE ENCRYPTION_PRIMARY_KEY ENCRYPTION_DETERMINISTIC_KEY ENCRYPTION_KEY_DERIVATION_SALT; do
  echo "${key}=$(openssl rand -hex 64)"
done
```

## Upgrade procedure

1. `docker compose pull && docker compose up -d`
2. DB migrations run automatically on startup
3. Check release notes: https://github.com/stringer-rss/stringer/releases

## Gotchas

- **All four encryption keys are required** in production: missing any of them causes a Rails startup error.
- **Single-user only**: Stringer has one account. There's no registration page or user management. First run creates the account interactively (or via env vars depending on version).
- **Feed fetch frequency**: FETCH_FEEDS_CRON defaults to every 5 minutes. On shared hosting or low-spec VPS, increase the interval to reduce load.
- **HTTPS**: Stringer has no built-in TLS. Put it behind NGINX or Caddy with a certificate. The upstream docker-compose exposes port 80 directly; add a reverse proxy for production.
- **OPML import**: Stringer supports OPML import for bulk adding feeds; use Settings > Import.
- **No search**: Stringer is minimal by design — no full-text search of article contents.

## Links

- Upstream repo: https://github.com/stringer-rss/stringer
- Docker docs: https://github.com/stringer-rss/stringer/blob/main/docs/Docker.md
- VPS install docs: https://github.com/stringer-rss/stringer/blob/main/docs/VPS.md
- Docker Hub: https://hub.docker.com/r/stringerrss/stringer
- Release notes: https://github.com/stringer-rss/stringer/releases
