---
name: Maybe
description: "Self-hosted personal finance app — track accounts, net worth, budgets, and transactions with bank sync and AI-powered insights. Ruby on Rails + PostgreSQL + Redis. AGPLv3. ⚠️ No longer actively maintained upstream (final release v0.6.0); fork-friendly under AGPLv3."
---

# Maybe

**What it is:** Open-source personal finance application for tracking net worth, budgets, accounts, and transactions. Features AI-powered financial chat (via OpenAI), transaction categorization, and multi-account dashboards. Upstream is finalized but fully functional and self-hostable.

**Official site:** https://github.com/maybe-finance/maybe
**Docs:** https://github.com/maybe-finance/maybe/blob/main/docs/hosting/docker.md
**License:** AGPLv3

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Docker Compose | Any Linux host | Recommended method |
| Bare metal | Ruby 3.x + PostgreSQL + Redis | Dev/advanced only |

---

## Inputs to Collect

### Pre-deploy
- `SECRET_KEY_BASE` — 128-char hex string; generate with `openssl rand -hex 64`
- `POSTGRES_PASSWORD` — database password

### Optional
- `OPENAI_ACCESS_TOKEN` — OpenAI API key for AI chat features (incurs costs)
- `POSTGRES_USER` — default: `maybe_user`
- `POSTGRES_DB` — default: `maybe_production`
- `RAILS_FORCE_SSL` / `RAILS_ASSUME_SSL` — set `true` when behind TLS-terminating reverse proxy

---

## Software-Layer Concerns

### Services
| Service | Image | Exposed port |
|---------|-------|------|
| web | `ghcr.io/maybe-finance/maybe:latest` | 3000 |
| db | `postgres:16` | internal |
| redis | `redis` | internal |

### Key env vars
```
SECRET_KEY_BASE=<128-char hex>
POSTGRES_PASSWORD=<password>
POSTGRES_USER=maybe_user
POSTGRES_DB=maybe_production
DB_HOST=db
DB_PORT=5432
REDIS_URL=redis://redis:6379/1
SELF_HOSTED=true
RAILS_FORCE_SSL=false
RAILS_ASSUME_SSL=false
OPENAI_ACCESS_TOKEN=   # leave blank to disable AI
```

### Data volumes
- `app-storage` — Rails ActiveStorage file uploads
- `db-data` — PostgreSQL data

---

## Deployment Steps

```bash
mkdir -p ~/docker-apps/maybe && cd ~/docker-apps/maybe

# Download sample compose file
curl -o compose.yml https://raw.githubusercontent.com/maybe-finance/maybe/main/compose.example.yml

# Generate secret key
SECRET=$(openssl rand -hex 64)

# Create .env
cat > .env << EOF
SECRET_KEY_BASE=$SECRET
POSTGRES_PASSWORD=changeme
EOF

docker compose up -d
# App at http://localhost:3000
# Seed login: user@maybe.local / password  ← change immediately
```

---

## Upgrade Procedure

```bash
cd ~/docker-apps/maybe
docker compose pull
docker compose up -d   # migrations run automatically on startup
docker compose logs -f web
```

> Since upstream is no longer maintained, `:latest` won't receive new releases. Pin to a version tag for stability.

---

## Gotchas

- **Archived upstream** — Final release is v0.6.0. No security patches from upstream. Fork freely under AGPLv3.
- **AI costs money** — `OPENAI_ACCESS_TOKEN` triggers paid API calls. Set spend limits before enabling.
- **Secret key must persist** — Changing `SECRET_KEY_BASE` invalidates all sessions.
- **Trademark restriction** — "Maybe" trademark is held by Maybe Finance Inc.; forks must not use the name or logo.
- **Default seed credentials** — Change the seeded password immediately after first login.
- **Bank sync** — Live sync (Plaid/Synth) requires additional API keys not included in base setup.
- **Reverse proxy** — For public deployments, use Nginx/Caddy + set `RAILS_FORCE_SSL=true` and `RAILS_ASSUME_SSL=true`.

---

## Links
- Upstream README: https://github.com/maybe-finance/maybe
- Docker hosting guide: https://github.com/maybe-finance/maybe/blob/main/docs/hosting/docker.md
- Example compose: https://raw.githubusercontent.com/maybe-finance/maybe/main/compose.example.yml
- Final release: https://github.com/maybe-finance/maybe/releases/tag/v0.6.0
