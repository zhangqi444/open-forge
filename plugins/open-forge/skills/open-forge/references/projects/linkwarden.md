---
name: linkwarden
description: Linkwarden recipe for open-forge. Self-hosted, open-source collaborative bookmark manager that preserves webpages as screenshots, PDFs, and single HTML files. Upstream https://docs.linkwarden.app.
---

# Linkwarden

Self-hosted, open-source collaborative bookmark manager. Collects, reads, annotates, and fully preserves webpages (screenshot + PDF + single HTML) to combat link rot. Supports collections, tags, full-text search, SSO, browser extensions, RSS, and a built-in reader/annotation view. Upstream: <https://github.com/linkwarden/linkwarden>. Docs: <https://docs.linkwarden.app>. License: MIT.

Linkwarden is a Next.js application backed by PostgreSQL, Meilisearch (full-text search), and a local file store. It listens on port `3000`. The upstream-documented path is Docker Compose.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose | <https://docs.linkwarden.app/self-hosting/installation> | ✅ | Recommended production path. Ships Postgres + Meilisearch. |
| Build from source | <https://github.com/linkwarden/linkwarden> | ✅ | Development / contribution. |
| Linkwarden Cloud | <https://linkwarden.app/#pricing> | ✅ | Managed SaaS — out of scope for open-forge (paid). |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| preflight | "Which install method?" | Options from table above | Drives method section |
| secrets | "Nextauth secret (random string ≥ 32 chars)?" | Free-text / `openssl rand -hex 32` | All self-hosted |
| secrets | "Postgres password?" | Free-text / generated | Docker Compose |
| domain | "What domain/URL will Linkwarden be accessible at (NEXTAUTH_URL)?" | Full URL e.g. `https://links.example.com` | All public installs |
| storage | "Path for data (screenshots/PDFs) on the host?" | Free-text (default `./data`) | Docker Compose |
| smtp | "Configure SMTP for email (password reset, invites)?" | Yes/No | Optional but recommended |

## Docker Compose

> **Source:** <https://github.com/linkwarden/linkwarden/blob/main/docker-compose.yml>

Upstream `docker-compose.yml` as of HEAD:

```yaml
services:
  postgres:
    image: postgres:16-alpine
    env_file: .env
    restart: always
    volumes:
      - ./pgdata:/var/lib/postgresql/data
  linkwarden:
    env_file: .env
    environment:
      - DATABASE_URL=postgresql://postgres:${POSTGRES_PASSWORD}@postgres:5432/postgres
    restart: always
    image: ghcr.io/linkwarden/linkwarden:latest
    ports:
      - 3000:3000
    volumes:
      - ./data:/data/data
    depends_on:
      - postgres
      - meilisearch
  meilisearch:
    image: getmeili/meilisearch:v1.12.8
    restart: always
    env_file:
      - .env
    volumes:
      - ./meili_data:/meili_data
```

### Minimal `.env` file

```env
# Postgres
POSTGRES_PASSWORD=changeme_strong_password

# NextAuth (required)
NEXTAUTH_SECRET=changeme_random_32_char_string
NEXTAUTH_URL=https://links.example.com

# Meilisearch master key (optional but recommended for security)
MEILI_MASTER_KEY=changeme_meili_key

# Optional: allow new registrations (default: true)
# NEXT_PUBLIC_DISABLE_REGISTRATION=true

# Optional: SMTP for email
# EMAIL_FROM=noreply@example.com
# EMAIL_SERVER=smtp://user:pass@smtp.example.com:587
```

### Deploy

```bash
# 1. Clone or create a directory with docker-compose.yml + .env
mkdir ~/linkwarden && cd ~/linkwarden
# copy docker-compose.yml and .env as above

# 2. Start
docker compose up -d

# 3. Access at http://localhost:3000 (or your domain)
# First registered user becomes admin
```

## Software-layer concerns

### Key env vars

| Variable | Required | Purpose |
|---|---|---|
| `POSTGRES_PASSWORD` | ✅ | PostgreSQL password (used by both postgres service and DATABASE_URL) |
| `DATABASE_URL` | ✅ | Full Postgres connection string (auto-set in compose via `POSTGRES_PASSWORD`) |
| `NEXTAUTH_SECRET` | ✅ | Random secret for NextAuth session signing; min 32 chars |
| `NEXTAUTH_URL` | ✅ | Canonical public URL of the app (e.g. `https://links.example.com`) |
| `MEILI_MASTER_KEY` | Recommended | Meilisearch master key; if set, also add `NEXT_PUBLIC_MEILISEARCH_HOST` pointing to `http://meilisearch:7700` |
| `NEXT_PUBLIC_DISABLE_REGISTRATION` | Optional | Set `true` to prevent new user signups after admin account is created |
| `EMAIL_FROM` / `EMAIL_SERVER` | Optional | SMTP config for password-reset / invite emails |
| `NEXT_PUBLIC_MAX_FILE_SIZE` | Optional | Max upload size in MB (default 30) |

### Data directories

| Path (container) | Host mount | Contents |
|---|---|---|
| `/data/data` | `./data` | Screenshots, PDFs, archived HTML files |
| `/var/lib/postgresql/data` | `./pgdata` | PostgreSQL data |
| `/meili_data` | `./meili_data` | Meilisearch index data |

## Upgrade procedure

```bash
cd ~/linkwarden

# 1. Pull new images
docker compose pull

# 2. Recreate containers
docker compose up -d

# Migrations run automatically on startup via Prisma
```

Always back up `./pgdata` and `./data` before upgrading.

## Gotchas

- **`NEXTAUTH_URL` must match the public URL exactly.** Mismatches cause OAuth callback failures and session errors. Include `https://` and no trailing slash.
- **`POSTGRES_PASSWORD` is also used in `DATABASE_URL`.** The `DATABASE_URL` in the compose file is constructed from `POSTGRES_PASSWORD` — keep them in sync in `.env`.
- **Meilisearch key pairing.** If you set `MEILI_MASTER_KEY`, you must also configure the app to use it via `MEILI_MASTER_KEY` in `.env` and point `NEXT_PUBLIC_MEILISEARCH_HOST=http://meilisearch:7700`. Without the key, Meilisearch runs in no-auth mode (insecure if exposed).
- **First registered user is admin.** Close registration after setup (`NEXT_PUBLIC_DISABLE_REGISTRATION=true`) if running on a public URL.
- **Archival requires Chromium inside the container.** The image bundles a headless browser for screenshots/PDFs; this makes the image large (~1 GB). Normal for the use case.
- **SSO (OIDC/SAML) is only available for Enterprise and self-hosted users** — configure via environment variables per the docs.

## Upstream docs

- Self-hosting installation: <https://docs.linkwarden.app/self-hosting/installation>
- Configuration reference: <https://docs.linkwarden.app/self-hosting/configuration>
- GitHub repo: <https://github.com/linkwarden/linkwarden>
- Browser extension: <https://github.com/linkwarden/browser-extension>
