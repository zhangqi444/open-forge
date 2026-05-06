---
name: sure
description: Sure recipe for open-forge. Covers Docker Compose self-hosted deploy. Sure is a community-maintained fork of the abandoned Maybe Finance personal finance app — tracks accounts, transactions, budgets, and investments with a clean Rails/React UI.
---

# Sure

Open-source personal finance application for tracking accounts, transactions, budgets, and investments. A community-maintained fork of the now-abandoned Maybe Finance project, continuing where the original team left off. Upstream: <https://github.com/we-promise/sure>. Website: <https://sure.am>.

**License:** AGPL-3.0 · **Language:** Ruby on Rails + React · **Default port:** 3000 · **Stars:** ~8,000

> **Fork note:** Sure is a community fork of [Maybe Finance](https://github.com/maybe-finance/maybe) which was archived in 2023 after the company shut down. The original codebase received ~$1M in development. Sure continues active maintenance under the community.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose | <https://github.com/we-promise/sure/blob/main/docs/hosting/docker.md> | ✅ | **Recommended** — official self-hosting path with Postgres, Redis, and optional automated backups. |
| Source (Ruby on Rails) | <https://github.com/we-promise/sure#local-development-setup> | ✅ | Development / contribution. |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| domain | "What URL will Sure be served at? (localhost or public domain)" | Free-text | All methods. |
| db_password | "PostgreSQL password to set? (or leave blank for auto-generated default)" | Free-text (sensitive) | Docker Compose. |
| secret_key | "SECRET_KEY_BASE — generate with `openssl rand -hex 64`?" | Free-text (sensitive) | Docker Compose (recommended for non-local). |
| backups | "Enable automated daily PostgreSQL backups?" | AskUserQuestion: Yes / No | Docker Compose backup profile. |

## Install — Docker Compose

Reference: <https://github.com/we-promise/sure/blob/main/docs/hosting/docker.md>

```bash
mkdir -p ~/sure && cd ~/sure

# Download the official compose file
curl -o compose.yml https://raw.githubusercontent.com/we-promise/sure/main/compose.example.yml

# (Optional but recommended) Create .env for security config
curl -o .env https://raw.githubusercontent.com/we-promise/sure/main/.env.example
```

Edit `.env` (optional — required if exposing to the internet):

```bash
# Generate a strong secret key
SECRET_KEY_BASE=$(openssl rand -hex 64)

# Set your domain
APP_DOMAIN=finance.example.com

# Database credentials
POSTGRES_USER=sure_user
POSTGRES_PASSWORD=<strong-password>
POSTGRES_DB=sure_production
```

Start:

```bash
docker compose up -d
```

Sure is available at `http://localhost:3000` (or your configured domain). Register your account on first visit.

### With automated backups

The compose file includes an optional `backup` profile using `postgres-backup-local`:

```bash
docker compose --profile backup up -d
```

Backups are written to `/opt/sure-data/backups` by default (edit the volume path in `compose.yml`). Retention: 7 days daily, 4 weeks weekly, 6 months monthly.

### Docker Compose services

| Service | Image | Purpose |
|---|---|---|
| `web` | `ghcr.io/we-promise/sure` | Rails app (port 3000) |
| `db` | `postgres:16` | PostgreSQL database |
| `redis` | `redis:latest` | Sidekiq background jobs / caching |
| `worker` | same as web | Sidekiq background worker |
| `backup` | `prodrigestivill/postgres-backup-local` | Optional automated DB backups |

## Software-layer concerns

| Concern | Detail |
|---|---|
| Database | PostgreSQL 16 — financial transaction data, accounts, budgets. Back up regularly. |
| Redis | Required for Sidekiq background jobs (account sync, email delivery, scheduled tasks). |
| SECRET_KEY_BASE | Used to sign Rails sessions and encrypted cookies. Must be set for production — without it, sessions are insecure. Generate once, keep stable. |
| HTTPS | Strongly recommended for a financial app. Put behind nginx/Caddy with TLS. |
| Account sync | Plaid integration available for automatic bank account import (requires Plaid API credentials). Manual import via CSV also supported. |
| Yahoo Finance | Used for investment/stock data. IPv6 issues can occur in some container environments — see compose.yml comments for workaround. |
| Port | Default 3000. Reverse proxy with TLS for production. |
| ARM64 | Multi-arch images available (amd64 + arm64). |
| AGPL-3.0 | If you modify and serve this app to users, source code of modifications must be published. |

## Upgrade procedure

```bash
cd ~/sure
docker compose pull
docker compose up -d
```

Database migrations run automatically on container start. Back up PostgreSQL before major version upgrades:

```bash
docker compose exec db pg_dump -U sure_user sure_production > sure-backup-$(date +%Y%m%d).sql
```

## Gotchas

- **Register first user before opening to internet:** Sure doesn't enforce invite-only registration by default. Create your account before exposing the port publicly.
- **SECRET_KEY_BASE required for production:** Without it, Rails generates a new random key on each restart, invalidating all sessions. Set it explicitly in `.env`.
- **IPv6 / Yahoo Finance:** In some Docker environments, DNS resolves Yahoo Finance to IPv6 which fails inside containers. Add `extra_hosts` to the compose service as described in the compose.example.yml comments.
- **Sidekiq worker must be running:** The `worker` service runs background jobs — account sync, recurring transactions, emails. If it's down, these features silently stop working. Check `docker compose ps`.
- **Fork stability:** Sure is actively maintained by the community but is a newer fork (~early 2024). Expect occasional rough edges; check <https://github.com/we-promise/sure/issues> before reporting bugs.
- **Plaid for bank sync:** Plaid requires an API account and sandbox/development credentials. Production Plaid access requires approval and incurs usage costs.

## Upstream links

- GitHub: <https://github.com/we-promise/sure>
- Self-hosting guide: <https://github.com/we-promise/sure/blob/main/docs/hosting/docker.md>
- Discord: <https://discord.gg/36ZGBsxYEK>
- Website: <https://sure.am>
- Original Maybe Finance (archived): <https://github.com/maybe-finance/maybe>
