---
name: typebot
description: Typebot recipe for open-forge. Visual conversational form/chatbot builder with 34+ building blocks, embeddable anywhere, and real-time result collection. Self-hosted via Docker Compose. Upstream https://docs.typebot.io/self-hosting/get-started.
---

# Typebot

Visual chatbot / conversational form builder. Create advanced chat flows with 34+ blocks (text bubbles, inputs, logic branching, Stripe payments, webhooks, OpenAI, Google Sheets, etc.), embed anywhere (container, popup, chat bubble), and collect results in real-time with drop-off analytics. Upstream: <https://github.com/baptisteArno/typebot.io>. Docs: <https://docs.typebot.io>. License: AGPL-3.0.

Typebot consists of two Next.js apps — a **builder** (for creating flows) and a **viewer** (for serving chatbots to end users) — plus PostgreSQL and Redis. The upstream-documented self-host path is Docker Compose.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose | <https://docs.typebot.io/self-hosting/guides/docker> | ✅ | Recommended. Ships builder + viewer + Postgres + Redis. |
| app.typebot.io (cloud) | <https://app.typebot.io> | ✅ | Managed SaaS — out of scope for open-forge. |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| preflight | "Which install method?" | Options from table above | Drives method section |
| secrets | "Encryption secret (random 32-char string)?" | Free-text / `openssl rand -hex 16` | Required — encrypts sensitive data |
| domain | "Builder app URL (NEXTAUTH_URL)?" | Full URL e.g. `https://typebot.example.com` | Required |
| domain | "Viewer app URL (NEXT_PUBLIC_VIEWER_URL)?" | Full URL e.g. `https://bot.example.com` | Required — separate subdomain recommended |
| auth | "Admin email address?" | Email | Optional — first user is admin via `ADMIN_EMAIL` |
| smtp | "Configure SMTP for email (magic links, invites)?" | Yes/No | Optional but needed for email login |
| storage | "Configure S3-compatible storage for file uploads?" | Yes/No | Optional (local disk otherwise) |

## Docker Compose

> **Source:** <https://github.com/baptisteArno/typebot.io/blob/main/docker-compose.yml>

Upstream `docker-compose.yml` as of HEAD:

```yaml
x-typebot-common: &typebot-common
  restart: always
  depends_on:
    typebot-redis:
      condition: service_healthy
    typebot-db:
      condition: service_healthy
  networks:
    - typebot-network
  env_file: .env
  environment:
    REDIS_URL: redis://typebot-redis:6379

services:
  typebot-db:
    image: postgres:16
    restart: always
    volumes:
      - db-data:/var/lib/postgresql/data
    environment:
      - POSTGRES_DB=typebot
      - POSTGRES_PASSWORD=typebot
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 5s
      timeout: 5s
      retries: 5
    networks:
      - typebot-network

  typebot-redis:
    image: redis:alpine
    restart: always
    command: --save 60 1 --loglevel warning
    healthcheck:
      test: ["CMD-SHELL", "redis-cli ping | grep PONG"]
      start_period: 20s
      interval: 30s
      retries: 5
      timeout: 3s
    volumes:
      - redis-data:/data
    networks:
      - typebot-network

  typebot-builder:
    <<: *typebot-common
    image: baptistearno/typebot-builder:latest
    ports:
      - "8080:3000"

  typebot-viewer:
    <<: *typebot-common
    image: baptistearno/typebot-viewer:latest
    ports:
      - "8081:3000"

networks:
  typebot-network:
    driver: bridge

volumes:
  db-data:
  redis-data:
```

### Minimal `.env` file

> **Source:** <https://github.com/baptisteArno/typebot.io/blob/main/.env.example>

```env
# Required: unique random string for encrypting sensitive data
ENCRYPTION_SECRET=your_random_32_char_string_here

# Postgres — update password to match docker-compose POSTGRES_PASSWORD
DATABASE_URL=postgresql://postgres:typebot@typebot-db:5432/typebot

# Node options
NODE_OPTIONS=--no-node-snapshot

# Builder URL (where the editor runs)
NEXTAUTH_URL=https://typebot.example.com

# Viewer URL (where chatbots are served to end users)
NEXT_PUBLIC_VIEWER_URL=https://bot.example.com

# Optional: your email becomes admin
ADMIN_EMAIL=you@example.com

# Optional: SMTP for magic-link email login
# EMAIL_FROM=noreply@example.com
# SMTP_HOST=smtp.example.com
# SMTP_PORT=587
# SMTP_USERNAME=user
# SMTP_PASSWORD=pass

# Optional: S3 storage for file uploads
# S3_ACCESS_KEY=
# S3_SECRET_KEY=
# S3_BUCKET=typebot
# S3_ENDPOINT=
```

### Deploy

```bash
mkdir ~/typebot && cd ~/typebot
# Copy docker-compose.yml and .env

# Generate encryption secret
ENCRYPTION_SECRET=$(openssl rand -hex 16)
echo "ENCRYPTION_SECRET=$ENCRYPTION_SECRET"

docker compose up -d
# Builder at http://localhost:8080
# Viewer at http://localhost:8081
```

## Software-layer concerns

### Key env vars

| Variable | Required | Purpose |
|---|---|---|
| `ENCRYPTION_SECRET` | ✅ | 32-char random string for encrypting credentials/tokens in DB. Do not change after data is stored. |
| `DATABASE_URL` | ✅ | PostgreSQL connection string |
| `NEXTAUTH_URL` | ✅ | Public URL of the builder app |
| `NEXT_PUBLIC_VIEWER_URL` | ✅ | Public URL of the viewer app (can be same domain with different path, or separate subdomain) |
| `REDIS_URL` | ✅ (set in compose) | Redis connection for session handling |
| `ADMIN_EMAIL` | Recommended | Email address that becomes the admin account |
| `EMAIL_FROM` + `SMTP_*` | Optional | SMTP config for magic-link/email auth |
| `S3_*` | Optional | S3-compatible storage for file upload blocks |
| `NODE_OPTIONS` | Set in example | `--no-node-snapshot` required for Next.js compatibility |

### Data directories

| Service | Volume | Contents |
|---|---|---|
| `typebot-db` | `db-data` (Docker named volume) | PostgreSQL data |
| `typebot-redis` | `redis-data` (Docker named volume) | Redis persistence (saved every 60s) |

## Upgrade procedure

```bash
cd ~/typebot

# Pull new images
docker compose pull

# Recreate with new images
docker compose up -d

# Database migrations run automatically via Prisma on startup
```

Back up `db-data` volume before upgrading:
```bash
docker compose exec typebot-db pg_dump -U postgres typebot > typebot_backup_$(date +%Y%m%d).sql
```

## Gotchas

- **`ENCRYPTION_SECRET` is write-once.** Changing it after data has been stored corrupts all encrypted credentials (API keys, webhook secrets, etc.) stored in the DB. Treat it as immutable; store it securely.
- **Builder and viewer are separate apps.** They can run on the same domain with different paths (e.g. `/admin` and `/`) or on separate subdomains. `NEXT_PUBLIC_VIEWER_URL` must be publicly reachable by end users' browsers.
- **Postgres password in docker-compose vs DATABASE_URL.** The upstream compose sets `POSTGRES_PASSWORD=typebot` for the DB service, and `DATABASE_URL=postgresql://postgres:typebot@typebot-db:5432/typebot` in `.env`. Change both to match if you use a custom password.
- **License is AGPL-3.0 (Fair Source).** Self-hosting is permitted, but review the license terms at <https://docs.typebot.io/self-hosting#license-requirements> for production deployments and white-labeling.
- **No TLS in the compose.** Put builder and viewer behind a TLS-terminating reverse proxy (Caddy, nginx, Traefik). Update `NEXTAUTH_URL` and `NEXT_PUBLIC_VIEWER_URL` to `https://` after adding TLS.
- **Redis is required.** Sessions and real-time result sync depend on Redis — do not remove it from the compose.

## Upstream docs

- Self-hosting guide: <https://docs.typebot.io/self-hosting/get-started>
- Docker guide: <https://docs.typebot.io/self-hosting/guides/docker>
- Configuration reference: <https://docs.typebot.io/self-hosting/configuration>
- License requirements: <https://docs.typebot.io/self-hosting#license-requirements>
- GitHub repo: <https://github.com/baptisteArno/typebot.io>
