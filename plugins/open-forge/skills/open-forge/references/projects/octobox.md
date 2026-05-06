---
name: octobox
description: Octobox recipe for open-forge. GitHub notification inbox manager — adds archived state, starring, filtering, and enhanced metadata to GitHub notifications. Self-hosted via Docker Compose (Ruby on Rails + PostgreSQL + Redis). Source: https://github.com/octobox/octobox. Docs: https://octobox.io.
---

# Octobox

Triage and manage GitHub notifications efficiently. Adds an "archived" state (notifications stay until you explicitly archive them), starring, label/status/CI-status filtering, and keyboard-driven navigation to your GitHub notification flow. Built on Ruby on Rails. Upstream: <https://github.com/octobox/octobox>. Website: <https://octobox.io>.

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| VPS / bare metal | Docker Compose + PostgreSQL + Redis | Recommended; upstream provides docker-compose.yml |
| VPS / bare metal | Ruby on Rails (native) | Requires Ruby 3.x, PostgreSQL, Redis |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| github | "GitHub OAuth App Client ID?" | Create at https://github.com/settings/applications/new; callback URL = http(s)://your-domain/auth/github/callback |
| github | "GitHub OAuth App Client Secret?" | From the same OAuth App settings page |
| db | "PostgreSQL password?" | For octobox DB user |
| redis | "Redis password?" | Optional but recommended |
| domain | "Public domain for Octobox?" | Used for OAuth callback URL and HTTPS setup |
| secret | "Rails secret key base?" | Generate with: openssl rand -hex 64 |

## Software-layer concerns

- Config: environment variables (GITHUB_CLIENT_ID, GITHUB_CLIENT_SECRET, RAILS_ENV, SECRET_KEY_BASE, DATABASE_URL, REDIS_URL)
- Default port: 3000
- Requires a GitHub OAuth App with callback URL matching your deployment
- Background jobs: Sidekiq (Redis-backed) for syncing notifications
- Data: PostgreSQL (notifications, users, repos metadata)
- RAILS_ENV: set to `production` for production deployments

### Docker Compose

```yaml
version: '3'
services:
  app:
    image: octoboxio/octobox:latest
    ports:
      - "3000:3000"
    depends_on:
      - database
      - redis
    environment:
      - RAILS_ENV=production
      - SECRET_KEY_BASE=<your-64-char-secret>
      - GITHUB_CLIENT_ID=<your-github-oauth-client-id>
      - GITHUB_CLIENT_SECRET=<your-github-oauth-client-secret>
      - OCTOBOX_DATABASE_NAME=octobox
      - OCTOBOX_DATABASE_USERNAME=octobox
      - OCTOBOX_DATABASE_PASSWORD=<db-password>
      - OCTOBOX_DATABASE_HOST=database
      - REDIS_URL=redis://redis:6379
    restart: unless-stopped

  database:
    image: postgres:16
    environment:
      POSTGRES_DB: octobox
      POSTGRES_USER: octobox
      POSTGRES_PASSWORD: <db-password>
    volumes:
      - postgres-data:/var/lib/postgresql/data
    restart: unless-stopped

  redis:
    image: redis:7
    restart: unless-stopped

volumes:
  postgres-data:
```

On first start, run DB migrations: `docker compose exec app bundle exec rails db:migrate`

### GitHub OAuth App setup

1. Go to https://github.com/settings/applications/new
2. Application name: Octobox (your instance name)
3. Homepage URL: https://your-domain
4. Authorization callback URL: https://your-domain/auth/github/callback
5. Copy Client ID and Client Secret into your environment config

## Upgrade procedure

1. `docker compose pull && docker compose up -d`
2. Run migrations after upgrade: `docker compose exec app bundle exec rails db:migrate`
3. Check release notes: https://github.com/octobox/octobox/releases

## Gotchas

- **GitHub OAuth required**: Octobox uses GitHub OAuth for authentication. You must create a GitHub OAuth App and cannot use it without GitHub credentials.
- **SECRET_KEY_BASE in production**: Must be a long random string. Without it, Rails won't start in production mode. Generate with `openssl rand -hex 64`.
- **RAILS_ENV=production**: The docker-compose.yml in the repo defaults to `development`. Set `RAILS_ENV=production` for production deployments (enables caching, asset compilation, etc.).
- **DB migrations**: Always run `rails db:migrate` after pulling a new image version.
- **Notification sync**: Octobox polls GitHub's notification API. The sync frequency depends on your GitHub API rate limit (authenticated = 5000 req/hr).
- **Single-user vs multi-user**: By default Octobox is multi-user (anyone with GitHub can sign in). Restrict access with `RESTRICTED_ACCESS_ENABLED=true` and `GITHUB_ORGANIZATION_ID` env vars.
- **HTTPS for OAuth**: GitHub OAuth requires a valid callback URL. HTTP works for local dev; production needs HTTPS with a real domain.

## Links

- Upstream repo: https://github.com/octobox/octobox
- Website: https://octobox.io
- Docker Hub: https://hub.docker.com/r/octoboxio/octobox
- GitHub OAuth App creation: https://github.com/settings/applications/new
- Release notes: https://github.com/octobox/octobox/releases
