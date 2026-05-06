---
name: one-time-secret
description: One-Time Secret recipe for open-forge. Covers self-hosting the self-destructing secret sharing web app. Upstream: https://github.com/onetimesecret/onetimesecret
---

# One-Time Secret

Self-destructing secret sharing service — create a link that can be viewed exactly once and then disappears forever. Keeps passwords and sensitive info out of inboxes and chat logs. Upstream: <https://github.com/onetimesecret/onetimesecret>. Docs: <https://docs.onetimesecret.com/en/self-hosting/>.

**License:** MIT

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose (simple — App + Valkey) | https://github.com/onetimesecret/onetimesecret/blob/main/docker/README.md | ✅ | Default; minimal two-service deployment |
| Docker Compose (full — Caddy TLS + RabbitMQ + workers) | https://github.com/onetimesecret/onetimesecret/blob/main/docker/README.md | ✅ | Production with TLS termination and background workers |
| Bare-metal (Ruby + Redis) | https://docs.onetimesecret.com/en/self-hosting/ | ✅ | Existing Ruby stacks; requires Ruby 3.4+ and Redis/Valkey |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| app | "Public hostname (e.g. secrets.example.com)?" | Hostname | All |
| app | "Port to expose on?" | Number (default: 3000) | Docker |
| secrets | SECRET (persistent app secret key) | `openssl rand -hex 32` | All |
| secrets | SESSION_SECRET (optional override) | `openssl rand -hex 32` | All |
| auth | "Authentication mode?" | `simple` (default) or `full` (PostgreSQL + RabbitMQ) | All |
| email | SMTP settings (optional) | SMTP host/user/pass | All |

## Docker Compose (simple — recommended)

The root `docker-compose.yml` includes the simple profile by default. The simple compose file lives at `docker/compose/docker-compose.simple.yml`:

```yaml
services:
  app:
    image: onetimesecret/onetimesecret:${OTS_IMAGE_TAG:-latest}
    container_name: onetime-app
    depends_on:
      maindb:
        condition: service_healthy
    env_file:
      - ../../.env
    environment:
      - RACK_ENV=${RACK_ENV:-production}
      - VALKEY_URL=redis://maindb:6379/0
      - SECRET=${SECRET:?SECRET must be set}
      - SESSION_SECRET=${SESSION_SECRET:-}
      - AUTHENTICATION_MODE=${AUTHENTICATION_MODE:-simple}
    ports:
      - '3000:3000'
    restart: unless-stopped
    volumes:
      - ../../data:/app/data

  maindb:
    image: valkey/valkey:8.1-bookworm
    container_name: onetime-maindb
    command: >
      valkey-server --appendonly yes --appendfsync everysec
      --dbfilename onetime.rdb --bind 0.0.0.0 --port 6379
    restart: unless-stopped
    volumes:
      - maindb-data:/data
    healthcheck:
      test: ['CMD', 'valkey-cli', 'ping']
      interval: 10s
      timeout: 3s
      retries: 3

volumes:
  maindb-data:
```

## Installation (Docker Compose simple)

```bash
git clone https://github.com/onetimesecret/onetimesecret.git
cd onetimesecret
cp --preserve --no-clobber .env.example .env
# Edit .env: set SECRET, HOST, SSL, SMTP, etc.
docker compose up -d
```

## Software-layer concerns

### Key env vars (.env)

```
SECRET=<openssl rand -hex 32>     # REQUIRED — persistent; back this up!
SESSION_SECRET=<openssl rand -hex 32>
HOST=secrets.example.com          # Public hostname (no scheme)
SSL=true                          # Set true in production
RACK_ENV=production
AUTHENTICATION_MODE=simple        # or "full" for SQL + MFA + WebAuthn
VALKEY_URL=redis://maindb:6379/0

# SMTP (optional)
# SMTP_HOST=smtp.example.com
# SMTP_PORT=587
# SMTP_USERNAME=user
# SMTP_PASSWORD=pass
```

### Config file (optional)

```bash
cp etc/defaults/config.defaults.yaml etc/config.yaml
# Edit etc/config.yaml for advanced settings
```

### Data directories

| Path (container) | Purpose |
|---|---|
| `/app/data` | Persistent app data |
| Valkey `/data` | Encrypted secret payloads (AOF + RDB) |

## Upgrade procedure

```bash
# Pull latest images
OTS_IMAGE_TAG=v0.24.6 docker compose pull
docker compose up -d
```

Check the [upgrade guides](https://docs.onetimesecret.com/en/self-hosting/) before upgrading across major versions — v0.23 and v0.24 have explicit migration steps.

## Gotchas

- **SECRET is write-once in practice.** Changing it after deployment invalidates all existing encrypted secrets. Back it up securely.
- **Upgrade path matters.** v0.23 → v0.24 requires running a migration step. See the [v0.24 Upgrade Guide](https://docs.onetimesecret.com/en/self-hosting/upgrading-v0-24/).
- **SSL=true required in production.** Secrets are transmitted in URLs; without TLS they are trivially intercepted.
- **Simple vs Full mode.** Simple mode stores user data only in Valkey (Redis-compatible). Full mode adds PostgreSQL + RabbitMQ for MFA, WebAuthn, scheduled jobs, and email verification.
- **Valkey, not Redis.** The official stack uses Valkey 8 (open-source Redis fork). The `VALKEY_URL` env var uses the `redis://` scheme, which Valkey understands.
- **Port 6379 exposed by default.** The simple compose exposes Valkey to the host. Remove that port mapping in production or restrict it to localhost.

## Upstream docs

- Self-hosting guide: https://docs.onetimesecret.com/en/self-hosting/
- Docker setup: https://github.com/onetimesecret/onetimesecret/blob/main/docker/README.md
- v0.24 upgrade guide: https://docs.onetimesecret.com/en/self-hosting/upgrading-v0-24/
- GitHub README: https://github.com/onetimesecret/onetimesecret
