---
name: outline-project
description: Outline recipe for open-forge. BSL-1.1-licensed team knowledge base — Notion-like collaborative wiki with rich editing, Postgres-backed, Redis for sessions, S3/local file storage. Self-host via a BYO docker-compose (upstream does NOT ship a ready-to-use production compose — the `docker-compose.yml` in the repo is dev-only for DB/Redis). Requires at least one OAuth/OIDC provider to be functional — Outline has NO built-in username+password signup. This recipe covers building the real compose from `.env.sample`, the OIDC/Google/Slack auth options, S3 vs local storage, the BSL license constraint, and the HTTPS-mandatory deployment shape.
---

# Outline

BSL-1.1-licensed modern team knowledge base. Upstream: <https://github.com/outline/outline>. Docs: <https://docs.getoutline.com/s/hosting/>. Hosted cloud: <https://www.getoutline.com>.

Outline is Notion-shaped — collections, nested documents, rich block editor, search, real-time collaboration, import from Notion/Confluence. Built on React + Node + Postgres + Redis.

**License is BSL-1.1, not OSI-open.** Similar model to Sentry, HashiCorp tools pre-2024, etc. Means:

- ✅ Self-host for your own org / personal use — free.
- ❌ Offer Outline as a hosted service to third parties — NOT allowed under BSL.
- ✅ BSL converts to Apache-2.0 after 4 years.
- Full text: <https://github.com/outline/outline/blob/main/LICENSE>

Non-commercial self-host is fine. Running a "Outline-as-a-service" startup is not.

## Upstream compose is DEV-ONLY

The `docker-compose.yml` in the root of the Outline repo is ONLY a Postgres + Redis setup for local development. It does NOT include the Outline app itself. New self-hosters regularly get tripped up by this — they run `docker compose up` expecting Outline and get confused when nothing happens.

**You MUST write your own `docker-compose.yml` that ties in the `outlinewiki/outline` image** pointing at Postgres + Redis. Template below.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| BYO docker-compose (`outlinewiki/outline`) | Docker Hub image is official; compose is BYO per docs | ✅ | The only upstream-supported self-host path. |
| Source install (`yarn`) | Outline docs | ✅ | Dev / custom build. Requires Node 20+, Yarn, Postgres, Redis. |
| Kubernetes | Community Helm charts | ⚠️ Community | Multiple community charts exist; none upstream-maintained. |
| DigitalOcean 1-Click | <https://marketplace.digitalocean.com/apps/outline> | ⚠️ Community | Not mentioned in Outline docs; verify before relying on it. |

## Architecture

- **outline** (Node.js web server + worker in one process) — port 3000
- **postgres** (14+) — primary DB
- **redis** — sessions + websocket pub/sub + collaboration state
- **s3-compatible storage (optional)** — file uploads, avatars, document attachments; or local filesystem

Minimum production: ~1 GB RAM for Outline itself, plus Postgres/Redis overhead. Memory scales with `WEB_CONCURRENCY` (processes) — upstream rule-of-thumb is "divide server RAM by 512 MB for a rough concurrency estimate."

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Install method?" | `AskUserQuestion`: `docker-compose` / `source` / `k8s` | Drives section. |
| license | "Confirm acceptable use under BSL-1.1 (no resale-as-service)?" | Boolean | Required before install — BSL is restrictive. |
| domain | "Public URL?" | Free-text, e.g. `https://wiki.example.com` | Sets `URL`. HTTPS mandatory for OAuth callbacks. |
| secrets | "Generate `SECRET_KEY`?" | Auto: `openssl rand -hex 32` | **REQUIRED.** 32-byte hex. |
| secrets | "Generate `UTILS_SECRET`?" | Auto: `openssl rand -hex 32` | **REQUIRED.** 32-byte hex. |
| db | "Postgres password + DB name?" | Free-text | Sets `DATABASE_URL`. |
| auth | "Primary auth provider?" | `AskUserQuestion`: `Google` / `Slack` / `Microsoft Entra` / `Discord` / `Generic OIDC` / `GitHub` | **At least one is REQUIRED.** Outline has no built-in username/password login. |
| storage | "File storage?" | `AskUserQuestion`: `Local filesystem` / `S3 (AWS/R2/MinIO/B2)` | `FILE_STORAGE=local` or `s3`. S3 required for multi-node setups. |
| tls | "Reverse proxy?" | `AskUserQuestion` | Outline does not terminate TLS (well — `SSL_KEY`/`SSL_CERT` exists but proxy is recommended). |
| smtp | "Outbound SMTP?" | Free-text | Required for invitations / password-reset-for-service-accounts. |

## Install — BYO Docker Compose

```yaml
# compose.yaml — self-written; NOT from the Outline repo
services:
  postgres:
    image: postgres:16
    restart: unless-stopped
    environment:
      POSTGRES_USER: outline
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: outline
    volumes:
      - pgdata:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD", "pg_isready", "-U", "outline"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    restart: unless-stopped
    volumes:
      - redisdata:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

  outline:
    image: outlinewiki/outline:1.7.1   # pin a version for prod
    restart: unless-stopped
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    env_file: .env
    ports:
      - "127.0.0.1:3000:3000"   # behind reverse proxy
    volumes:
      - outline-data:/var/lib/outline/data   # only needed if FILE_STORAGE=local
    command: sh -c "yarn db:migrate --env=production-ssl-disabled && yarn start --env=production-ssl-disabled"

volumes:
  pgdata:
  redisdata:
  outline-data:
```

### `.env`

Copy the full `.env.sample` from upstream (<https://github.com/outline/outline/blob/main/.env.sample>) and fill. Minimum required for a working install:

```bash
# Core
NODE_ENV=production
URL=https://wiki.example.com
PORT=3000
SECRET_KEY=<openssl rand -hex 32>
UTILS_SECRET=<openssl rand -hex 32>

# DB + Redis
DATABASE_URL=postgres://outline:<password>@postgres:5432/outline
REDIS_URL=redis://redis:6379
PGSSLMODE=disable                          # DB + app on same compose network

# Storage (local)
FILE_STORAGE=local
FILE_STORAGE_LOCAL_ROOT_DIR=/var/lib/outline/data
FILE_STORAGE_UPLOAD_MAX_SIZE=262144000

# SSL / reverse proxy
FORCE_HTTPS=true                           # assumes a reverse proxy is doing TLS

# AT LEAST ONE of these provider groups:
# Google
GOOGLE_CLIENT_ID=<from console.cloud.google.com>
GOOGLE_CLIENT_SECRET=<from console.cloud.google.com>

# …or Slack, Microsoft Entra, Discord, OIDC, GitHub — pick one or more.

# SMTP (invites)
SMTP_HOST=smtp.example.com
SMTP_PORT=587
SMTP_USERNAME=...
SMTP_PASSWORD=...
SMTP_FROM_EMAIL=wiki@example.com
SMTP_REPLY_EMAIL=wiki@example.com
```

### Bring it up

```bash
cat > .env <<EOF
POSTGRES_PASSWORD=$(openssl rand -hex 24)
# ... paste + fill the rest
EOF

docker compose up -d
docker compose logs -f outline

# First boot: Outline runs migrations, then starts HTTP on :3000.
# Visit https://wiki.example.com — you'll be redirected to your OAuth provider.
```

## OAuth setup (pick one)

### Google

1. <https://console.cloud.google.com> → Create project → OAuth consent screen → External.
2. APIs & Services → Credentials → Create OAuth client ID → Web application.
3. Authorized redirect URI: `https://wiki.example.com/auth/google.callback`
4. Copy client ID + secret to `.env` as `GOOGLE_CLIENT_ID` / `GOOGLE_CLIENT_SECRET`.
5. Restrict `GOOGLE_ALLOWED_DOMAINS=example.com` to lock signups to your Workspace.

### Generic OIDC (Keycloak / Authentik / Authelia / Zitadel)

```bash
OIDC_CLIENT_ID=outline
OIDC_CLIENT_SECRET=<from IdP>
OIDC_AUTH_URI=https://auth.example.com/application/o/authorize/
OIDC_TOKEN_URI=https://auth.example.com/application/o/token/
OIDC_USERINFO_URI=https://auth.example.com/application/o/userinfo/
OIDC_USERNAME_CLAIM=preferred_username
OIDC_DISPLAY_NAME=My SSO
OIDC_SCOPES=openid profile email
```

Redirect URI to configure on the IdP: `https://wiki.example.com/auth/oidc.callback`.

## Reverse proxy (Caddy example)

```caddy
wiki.example.com {
    reverse_proxy outline:3000 {
        header_up X-Forwarded-Proto https
    }
}
```

**Websockets** (used for real-time collaboration) just work over `reverse_proxy` in Caddy. For nginx, make sure to set:

```nginx
proxy_http_version 1.1;
proxy_set_header Upgrade $http_upgrade;
proxy_set_header Connection "upgrade";
```

## Data layout

| Path | Content |
|---|---|
| Postgres `outline` DB | All documents (content stored as ProseMirror JSON), collections, users, auth tokens, integration configs. |
| Redis | Sessions, collaboration state, job queue. Safe to drop on restart; users get logged out. |
| `outline-data/` volume OR S3 bucket | Attachments, avatars, uploaded images, document exports. |

### Backup

```bash
# DB
docker compose exec -T postgres pg_dump -U outline outline | gzip > outline-$(date +%F).sql.gz

# Local filesystem attachments
docker run --rm -v outline_outline-data:/data -v "$PWD":/backup alpine \
  tar -czf /backup/outline-files-$(date +%F).tar.gz -C /data .

# S3 — use rclone or aws s3 sync against the bucket
```

## Upgrade procedure

```bash
cd /path/to/outline
docker compose pull outline
docker compose up -d outline
docker compose logs -f outline | grep -iE 'migration|error'
```

Migrations run on startup via the `yarn db:migrate` in the container command. Read release notes at <https://github.com/outline/outline/releases> — major version bumps (v1.x → v2.x) have had required manual steps.

## Gotchas

- **The root `docker-compose.yml` is NOT a production compose** — it's just Postgres + Redis for local dev. New self-hosters frequently run it and wonder why Outline never starts. Write your own compose using `outlinewiki/outline`.
- **No built-in username/password auth.** OAuth/OIDC is mandatory. For homelab users who don't want an external IdP, run Authentik/Authelia locally or use generic OIDC against a self-hosted IdP. There is no "email + password" option in OSS Outline.
- **BSL license forbids offering Outline as a service.** Internal company wiki is fine; "I'll host Outline for small teams for $5/month" is not.
- **`SECRET_KEY` / `UTILS_SECRET` rotation = session invalidation.** Losing them doesn't hard-destroy data (content is in Postgres, not encrypted at rest with these keys), but all JWTs become invalid and users have to re-auth. Back them up.
- **`FORCE_HTTPS=true` + no TLS terminator in front = 100% redirect loop.** Either set this `false` during initial setup, or make sure your reverse proxy is already serving HTTPS before first request.
- **Local file storage doesn't work across multiple Outline replicas.** For horizontally-scaled deploys, you MUST use `FILE_STORAGE=s3` with a shared bucket.
- **`AWS_S3_FORCE_PATH_STYLE=true` needed for MinIO / R2.** Outline defaults to virtual-host-style addressing which breaks non-AWS S3 implementations. Set this for anything except actual AWS S3.
- **No anonymous access / guest share by default.** Public document sharing exists but requires explicit admin enablement + per-document share. If a user says "link doesn't work when I share it publicly" — check *Settings → Security → Share to anyone with a link*.
- **`WEB_CONCURRENCY=1` default is very conservative.** 512 MB per process is the upstream rule of thumb — a 4 GB host can comfortably run `WEB_CONCURRENCY=4`. Under-provisioning concurrency causes slow response times on busy wikis.
- **PostgreSQL ≥ 12 required; 14+ recommended.** The Docker image in the dev compose uses `postgres:latest` which is fine, but pin a major version in production to avoid surprise upgrades.
- **Collaboration websocket requires `REDIS_URL`.** Without Redis, real-time editing silently falls back to polling, which feels broken. Don't try to run Outline without Redis.
- **Upstream explicitly rejects AI-generated PRs.** README has a warning. Irrelevant for self-hosters but worth knowing before opening issues.

## Links

- Upstream repo: <https://github.com/outline/outline>
- Self-host docs: <https://docs.getoutline.com/s/hosting/>
- `.env.sample`: <https://github.com/outline/outline/blob/main/.env.sample>
- OIDC auth guide: <https://docs.getoutline.com/s/hosting/doc/oidc-8CPBm6uC0I>
- File storage: <https://docs.getoutline.com/s/hosting/doc/file-storage-N4M0T6Ypu7>
- Horizontal scaling: <https://docs.getoutline.com/s/hosting/doc/horizontal-scaling-hkfU5Stao7>
- BSL license: <https://github.com/outline/outline/blob/main/LICENSE>
- Releases: <https://github.com/outline/outline/releases>
- Docker image: <https://hub.docker.com/r/outlinewiki/outline>
