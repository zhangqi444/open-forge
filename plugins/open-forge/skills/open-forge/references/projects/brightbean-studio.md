---
name: brightbean-studio-project
description: BrightBean Studio recipe for open-forge. Open-source, self-hostable social media management platform. Schedule and publish to 10+ platforms (Facebook, Instagram, LinkedIn, TikTok, YouTube, Bluesky, Mastodon, etc.) with multi-workspace support, approval workflows, unified inbox, and client portal.
---

# BrightBean Studio

Open-source, self-hostable social media management platform for creators, agencies, and SMBs. Replaces Buffer, Sendible, ContentStudio, and SocialPilot with no per-seat, per-channel, or per-workspace limits. Upstream: https://github.com/brightbeanxyz/brightbean-studio. License: AGPL-3.0.

Language: Python 3.12 + Django 5. Database: PostgreSQL. Multi-arch: amd64.

Supports scheduling and publishing to 10+ platforms via first-party official APIs: Facebook, Instagram, LinkedIn (personal + company), TikTok, YouTube, Pinterest, Threads, Bluesky, Google Business Profile, Mastodon. No aggregator middleman.

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux host | Docker Compose | Recommended for self-hosted production |
| Heroku / Render / Railway | One-click deploy buttons | Managed cloud — see deploy buttons in repo README |
| Local | Python + SQLite (no Docker) | Development only |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | Domain / APP_URL | Required for OAuth callbacks to social platforms |
| database | DATABASE_URL | PostgreSQL connection string |
| secrets | SECRET_KEY | Django secret key — generate with: openssl rand -base64 50 |
| secrets | ENCRYPTION_KEY_SALT | Encryption salt — generate with: openssl rand -base64 50 |
| email | SMTP credentials | For invitation emails and password resets |
| storage | STORAGE_BACKEND | local (default) or s3. Use S3 for persistent media on ephemeral hosts |
| optional | Google SSO | GOOGLE_AUTH_CLIENT_ID / GOOGLE_AUTH_CLIENT_SECRET |
| social-apis | Platform API credentials | Set up per-platform via OAuth in the admin UI after first start |

## Software-layer concerns

### Docker Compose (recommended)

Based on upstream docker-compose.yml at https://github.com/brightbeanxyz/brightbean-studio/blob/main/docker-compose.yml.

  git clone https://github.com/brightbeanxyz/brightbean-studio.git
  cd brightbean-studio
  cp .env.example .env
  # Edit .env: set DATABASE_URL to postgres://postgres:postgres@postgres:5432/brightbean
  #            set SECRET_KEY, ENCRYPTION_KEY_SALT, ALLOWED_HOSTS, APP_URL
  docker compose up -d --build
  docker compose exec app python manage.py migrate
  docker compose exec app python manage.py createsuperuser

Then build the Tailwind CSS (required on first start due to bind-mount shadowing):

  docker compose exec app sh -c "cd theme/static_src && npm ci && npm run build"

BrightBean Studio is available at http://localhost:8000.

### Compose service layout

| Service | Role |
|---|---|
| app | Django web application, port 8000 |
| worker | Background task processor (python manage.py process_tasks) |
| postgres | PostgreSQL 16 database |

### Key environment variables

| Variable | Required | Description |
|---|---|---|
| SECRET_KEY | Yes | Django secret key |
| ENCRYPTION_KEY_SALT | Yes | Salt for encrypted credential storage |
| DATABASE_URL | Yes | PostgreSQL connection string |
| ALLOWED_HOSTS | Yes | App domain (e.g. brightbean.example.com) |
| APP_URL | Yes | Full public URL (e.g. https://brightbean.example.com) |
| STORAGE_BACKEND | No | local (default) or s3 |
| S3_ENDPOINT_URL | If s3 | S3-compatible endpoint URL |
| S3_ACCESS_KEY_ID | If s3 | S3 access key |
| S3_SECRET_ACCESS_KEY | If s3 | S3 secret key |
| S3_BUCKET_NAME | If s3 | S3 bucket name |
| EMAIL_HOST | No | SMTP server |
| EMAIL_PORT | No | SMTP port (default: 587) |
| EMAIL_HOST_USER | No | SMTP username |
| EMAIL_HOST_PASSWORD | No | SMTP password |
| GOOGLE_AUTH_CLIENT_ID | No | Google SSO client ID |
| GOOGLE_AUTH_CLIENT_SECRET | No | Google SSO secret |
| DJANGO_SETTINGS_MODULE | Auto-set | config.settings.production |

### Platform credentials

Each social platform uses its own OAuth developer app credentials. After logging into BrightBean Studio, navigate to each platform's settings to connect accounts using your developer credentials (Meta App, Google Cloud Console OAuth client, LinkedIn App, etc.). All tokens are encrypted at rest using ENCRYPTION_KEY_SALT.

### Supported platforms

Facebook, Instagram, LinkedIn (Personal + Company), TikTok, YouTube, Pinterest, Threads, Bluesky, Google Business Profile, Mastodon.

## Upgrade procedure

  docker compose pull
  docker compose up -d --build
  docker compose exec app python manage.py migrate

Check the upstream changelog for breaking changes before upgrading.

## Gotchas

- ALLOWED_HOSTS must match the serving domain exactly — a mismatch causes 400 Bad Request errors on all pages.
- APP_URL must include the full scheme and domain (e.g. https://yourapp.example.com) — it is used in OAuth redirect URIs and email links; wrong values break social platform authentication.
- Tailwind CSS build step on first start — the bind-mount in docker-compose.yml shadows the image's pre-built CSS. Run the npm ci && npm run build step once inside the running container, or the UI will be unstyled.
- S3 storage for non-ephemeral media — Heroku, Render, and Railway have ephemeral filesystems; uploaded media is lost on redeploy without an S3-compatible backend.
- Worker must be running for scheduled posts — the worker container handles task processing. Without it, scheduled posts will queue but never publish.
- Database migration required after upgrade — always run python manage.py migrate after pulling a new image.
- First-time OAuth setup requires a public URL — social platform OAuth callbacks need a reachable public URL; localhost installs cannot complete OAuth flows for most platforms.

## Links

- Upstream README: https://github.com/brightbeanxyz/brightbean-studio
- License: AGPL-3.0
