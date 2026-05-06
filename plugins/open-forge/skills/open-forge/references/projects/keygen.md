---
name: keygen
description: Keygen recipe for open-forge. Fair source software licensing and distribution API for validating license keys, managing entitlements, and device activation in desktop/server/on-premise software. Self-host Keygen CE for free. Source: https://github.com/keygen-sh/keygen-api
---

# Keygen

Fair source software licensing and distribution API built for developers. Use Keygen to add license key validation, entitlements, and device activation to desktop apps, server applications, and on-premise software. Comes in two editions: **Keygen CE** (Community Edition — free to self-host) and **Keygen EE** (Enterprise Edition — adds request logs, audit logs, environments, SAML SSO, and OCI registry). Upstream: https://github.com/keygen-sh/keygen-api. Self-hosting docs: https://keygen.sh/docs/self-hosting/.

## Compatible install methods

| Method | Platform | Notes |
|---|---|---|
| Docker Compose | Linux | Recommended for self-hosting |
| Ruby on Rails (source) | Linux | For development or custom deployments |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| install | "PostgreSQL credentials?" | Host, port, user, password, db name |
| install | "Redis URL?" | For background job queuing (Sidekiq) |
| install | "Secret key base?" | Generate: `openssl rand -hex 64` |
| install | "Encryption key?" | Generate: `openssl rand -hex 32` |
| install | "App domain?" | e.g. https://keygen.yourdomain.com |
| install | "SMTP credentials?" | For transactional email (license delivery, etc.) |
| license | "Edition?" | CE (free) or EE (requires license key from keygen.sh) |

## Software-layer concerns

### Self-hosting overview

Keygen CE is a Ruby on Rails application backed by PostgreSQL and Redis (via Sidekiq for background jobs). The official self-hosting guide lives at https://keygen.sh/docs/self-hosting/ — follow it for the canonical, up-to-date Docker Compose setup. The outline below reflects the documented components.

### Docker Compose (recommended)

  # Refer to the official self-hosting docs for the current compose file:
  # https://keygen.sh/docs/self-hosting/

  # Key services in the compose stack:
  # - keygen-api: the Rails application (web + Sidekiq worker)
  # - postgres: PostgreSQL database
  # - redis: job queue backend

### Key environment variables

  # Application
  SECRET_KEY_BASE=<openssl rand -hex 64>
  ENCRYPTION_DETERMINISTIC_KEY=<openssl rand -hex 32>
  ENCRYPTION_PRIMARY_KEY=<openssl rand -hex 32>
  ENCRYPTION_KEY_DERIVATION_SALT=<openssl rand -hex 32>

  # Database
  DATABASE_URL=postgres://keygen:password@postgres:5432/keygen_production

  # Redis
  REDIS_URL=redis://redis:6379/0

  # Application URL
  KEYGEN_HOST=https://keygen.yourdomain.com
  KEYGEN_EDITION=CE     # or EE
  KEYGEN_MODE=singleplayer  # or multiplayer (EE only, multi-account)

  # Email
  SMTP_ADDRESS=smtp.example.com
  SMTP_PORT=587
  SMTP_USERNAME=user@example.com
  SMTP_PASSWORD=password

### Initialize database

  docker compose exec keygen-api bundle exec rails db:create
  docker compose exec keygen-api bundle exec rails db:migrate
  docker compose exec keygen-api bundle exec rails db:seed

### Create initial admin account

  # After first boot, Keygen CE (singleplayer mode) creates a single account.
  # Navigate to https://keygen.yourdomain.com and follow the setup wizard,
  # OR create via API:
  curl -X POST https://keygen.yourdomain.com/v1/accounts \
    -H "Content-Type: application/vnd.api+json" \
    -d '{"data": {"type": "accounts", "attributes": {"name": "My Company", "slug": "my-company"}}}'

### API usage

  # Keygen exposes a RESTful JSON:API at /v1/
  # All resources (licenses, products, policies, machines) are managed via API.

  # Example: validate a license key
  curl -X POST https://keygen.yourdomain.com/v1/accounts/{ACCOUNT_ID}/licenses/actions/validate-key \
    -H "Content-Type: application/vnd.api+json" \
    -d '{"meta": {"key": "YOUR-LICENSE-KEY"}}'

### Ports

  3000   # Default Rails port (proxy behind Nginx/Caddy for HTTPS)

## Upgrade procedure

  # Pull new images and re-run migrations:
  docker compose pull
  docker compose up -d
  docker compose exec keygen-api bundle exec rails db:migrate

  # CE releases are infrequent (~every 6 months). Check releases at:
  # https://github.com/keygen-sh/keygen-api/releases

## Gotchas

- **CE vs EE features**: Keygen CE lacks request logs, audit logs, environments, permissions, SSO/SAML, and OCI registry. These are EE-only. Check https://keygen.sh/docs/self-hosting/ for the current feature matrix.
- **Singleplayer mode**: Keygen CE runs in `singleplayer` mode by default — one account per instance. `multiplayer` mode (multiple accounts on one instance) is an EE feature.
- **Fair source license**: Keygen CE is licensed under the Elastic License 2.0 (or similar fair source terms). It is free to self-host but not open source in the OSI sense. Review the license before redistributing.
- **Release cadence**: CE releases are batched every ~6 months from Keygen Cloud. Cloud gets fixes and features first; CE lags behind intentionally.
- **No community support guarantee**: CE community support is best-effort via Discord. For production guarantees, EE includes dedicated support.
- **Sidekiq required**: background jobs (license expiry, webhooks, email) run via Sidekiq + Redis. Ensure both the web process and Sidekiq worker are running.

## References

- Upstream GitHub: https://github.com/keygen-sh/keygen-api
- Self-hosting documentation: https://keygen.sh/docs/self-hosting/
- API reference: https://keygen.sh/docs/api/
- Releases (CE builds): https://github.com/keygen-sh/keygen-api/releases
- Discord community: https://discord.gg/TRrhSaWSsN
