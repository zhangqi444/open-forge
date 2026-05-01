---
name: Bracket
description: "Free open-source tournament management system. Docker + PostgreSQL. Python/FastAPI + Next.js. evroon/bracket. Brackets, planning, scheduling, standings, multi-stage, Swiss."
---

# Bracket

**Free open-source tournament management system.** Manage tournaments end-to-end — bracket planning, stage scheduling, match results, live standings, multi-stage formats. Built for sports clubs, esports events, LAN parties, board game nights.

Built + maintained by **evroon** and contributors. Translations via Crowdin.

- Upstream repo: <https://github.com/evroon/bracket>
- Docs: <https://docs.bracketapp.nl>
- Quickstart: <https://docs.bracketapp.nl/docs/running-bracket/quickstart>
- Demo: <https://app.bracketapp.nl> (or runs locally with default creds after `docker compose up`)

## Architecture in one minute

- **Python (FastAPI / uv)** backend + **Next.js** frontend
- **PostgreSQL** database (required)
- Port **8400** (serves both API and frontend via `SERVE_FRONTEND=true`)
- Backend config via `.env` files or environment variables
- Static assets volume for uploaded images/logos
- Resource: **low-to-medium** (Python + Postgres)

## Compatible install methods

| Infra         | Runtime                      | Notes                                          |
| ------------- | ---------------------------- | ---------------------------------------------- |
| **Docker**    | `ghcr.io/evroon/bracket`     | **Primary.** Compose includes Postgres.        |
| **Bare-metal**| `uv` (Python) + `pnpm` (Node)| Dev/manual deploys; see development docs       |

## Inputs to collect

| Input                 | Example                          | Phase   | Notes                                                              |
| --------------------- | -------------------------------- | ------- | ------------------------------------------------------------------ |
| `PG_DSN`              | `postgresql://user:pw@host/db`   | Storage | Postgres connection string                                         |
| `CORS_ORIGINS`        | `https://bracket.example.com`    | Config  | Comma-separated URLs allowed to hit the API                        |
| `ENVIRONMENT`         | `PRODUCTION`                     | Config  | Use `PRODUCTION` in prod (disables dev tooling)                    |
| Domain                | `bracket.example.com`            | URL     | Front with reverse proxy + TLS                                     |
| Admin email + pw      | via UI on first run              | Auth    | Default dev creds: `test@example.org` / `aeGhoe1ahng2Aezai0Dei6Aih6dieHoo` — **change these** |

## Install via Docker Compose

```sh
git clone https://github.com/evroon/bracket.git
cd bracket
docker compose up -d
```

The repo's `docker-compose.yml`:

```yaml
services:
  bracket:
    container_name: bracket
    depends_on:
      - postgres
    environment:
      ENVIRONMENT: DEVELOPMENT
      CORS_ORIGINS: http://localhost:8400
      PG_DSN: postgresql://bracket_dev:bracket_dev@postgres:5432/bracket_dev
      SERVE_FRONTEND: true
      API_PREFIX: '/api'
    image: ghcr.io/evroon/bracket
    ports:
      - 8400:8400
    restart: unless-stopped
    volumes:
      - bracket_static_data:/app/static

  postgres:
    environment:
      POSTGRES_DB: bracket_dev
      POSTGRES_PASSWORD: bracket_dev
      POSTGRES_USER: bracket_dev
    image: postgres
    restart: always
    volumes:
      - bracket_pg_data:/var/lib/postgresql

volumes:
  bracket_pg_data:
  bracket_static_data:
```

For production: set `ENVIRONMENT=PRODUCTION`, update `CORS_ORIGINS` to your real domain, change Postgres creds.

## First boot

1. `docker compose up -d`
2. Visit `http://localhost:8400`
3. Default credentials (dev): `test@example.org` / `aeGhoe1ahng2Aezai0Dei6Aih6dieHoo` — **change before going live**
4. (Optional) insert dev data: `docker exec bracket-backend uv run --no-dev ./cli.py create-dev-db`
5. Create tournament → configure stages → add teams/players → build bracket → run matches
6. Follow the [usage guide](https://docs.bracketapp.nl/docs/usage/guide) for the full workflow
7. Put behind TLS reverse proxy

## Data & config layout

- **Postgres** — all tournament data (tournaments, stages, rounds, matches, teams, results)
- `/app/static/` — uploaded logos, images (bind or named volume)
- `.env` / `prod.env` — backend config (DB creds, CORS, environment)
- Frontend env via Vite `.env` pattern

## Backup

```sh
# Postgres dump
docker exec bracket-postgres pg_dump -U bracket_dev bracket_dev > bracket-$(date +%F).sql
# Static assets
sudo tar czf bracket-static-$(date +%F).tgz /path/to/bracket_static_data
```

## Upgrade

1. Releases: <https://github.com/evroon/bracket/releases>
2. `git pull && docker compose pull && docker compose up -d`
3. Check release notes for DB migration steps (migrations usually run automatically on startup)

## Gotchas

- **Default dev credentials are hardcoded in the compose.** `test@example.org` / `aeGhoe1ahng2Aezai0Dei6Aih6dieHoo` — these are public knowledge. Change admin password on first login or use production config with real credentials from the start.
- **`ENVIRONMENT=PRODUCTION` is not optional for real deploys.** Development mode may enable debug endpoints, verbose logging, and weaker session handling.
- **`CORS_ORIGINS` must match your actual domain exactly.** `http://localhost:8400` works locally; in production set it to `https://bracket.example.com`. Mismatch = browser rejects all API calls with CORS errors.
- **Frontend is served by the backend** (`SERVE_FRONTEND=true`). No separate web server needed — one container, one port. This simplifies deployment but means you can't scale frontend and backend independently.
- **Postgres is required.** No SQLite option. Embedded Postgres in the compose works fine for single-node; for HA use an external managed Postgres.
- **Translations auto-detect from browser.** Language toggle not yet in-UI; browser locale drives it. Contribute translations via Crowdin.
- **Multi-stage tournament formats supported.** Single-elimination, double-elimination, round-robin, Swiss — check docs for stage configuration; not all formats are equally polished.
- **`create-dev-db` inserts dummy data** — useful to explore the UI before real events; run only on a fresh dev instance, never on production data.

## Project health

Active development, CI, docs site, Crowdin translations, demo instance, multiple contributors. Maintained by evroon.

## Tournament-management-family

- **Bracket** — FastAPI + Next.js + Postgres; Docker; multi-stage; self-hosted
- **Challonge** — SaaS, most-used, not self-hosted
- **Toornament** — SaaS, esports focus
- **OpenTournament** — older, unmaintained
- **Tabletop.io / BGA** — board games specific

**Choose Bracket if:** you want a clean self-hosted open-source tournament tool with multi-stage support and an easy Docker setup.

## Links

- Repo: <https://github.com/evroon/bracket>
- Docs: <https://docs.bracketapp.nl>
- Quickstart: <https://docs.bracketapp.nl/docs/running-bracket/quickstart>
- Usage guide: <https://docs.bracketapp.nl/docs/usage/guide>
- Deployment guide: <https://docs.bracketapp.nl/docs/deployment>
