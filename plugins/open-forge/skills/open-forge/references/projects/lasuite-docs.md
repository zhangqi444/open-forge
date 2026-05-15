---
name: La Suite Docs (suitenumerique/docs)
description: "Self-hosted open-source collaborative document editor and wiki platform — real-time multi-user editing with live cursors, rich-text + Markdown, subpages, granular access control, document sharing, export to .docx/.pdf/.odt, optional AI writing helpers. Built on Django + React. Requires OIDC provider + S3 storage. Docker Compose or Kubernetes. MIT (core) / GPL (PDF export)."
---

# La Suite Docs

La Suite Docs is an open-source alternative to Notion or Google Docs, built for teams and public organizations. It provides:

- **Real-time collaborative editing** with live cursors, presence indicators, and comments
- **Rich-text + Markdown** with slash commands, block system, and beautiful formatting
- **Subpages + hierarchy** — nested documents, searchable content
- **Granular access control** — share documents with specific users or make public
- **Export** to `.docx`, `.odt`, `.pdf` (PDF requires GPL-licensed XL Blocknote package)
- **Import** from `.docx`, `.md`
- **Optional AI writing helpers** — rewrite, summarize, translate, fix typos (bring your own LLM key)
- **Offline editing** support

Built by the French government's "La Suite Numérique" program. Production-grade and actively maintained.

- Upstream repo: <https://github.com/suitenumerique/docs>
- Latest release: v5.1.0 (check <https://github.com/suitenumerique/docs/releases>)
- Docker images: `lasuite/impress-backend`, `lasuite/impress-frontend`, `lasuite/impress-y-provider`
- Docker Hub: <https://hub.docker.com/u/lasuite>
- Demo: <https://docs.la-suite.eu/docs/9137bbb5-3e8a-4ff7-8a36-fcc4e8bd57f4/>
- License: MIT (core); GPL applies only to PDF export via Blocknote XL packages

## Architecture in one minute

- **backend** — Django (Python) app; handles API, auth, DB, storage
- **frontend** — React (Next.js) SPA served by nginx; connects to backend
- **y-provider** — WebSocket server for real-time CRDT collaboration (Yjs)
- **postgresql** — Primary database (Postgres 16)
- **redis** — Cache + rate limiter
- **S3-compatible storage** — Required for file/media uploads (MinIO works; any S3-compatible service)
- **OIDC provider** — Required for all user authentication (Keycloak works; any OIDC-compliant IdP)

All services run as non-root (uid 1000 for backend/y-provider, uid 101 for frontend).

## Compatible install methods

| Infra | Runtime | Notes |
|---|---|---|
| Single VM / VPS | **Docker Compose** | Community-supported. Upstream provides example compose + env files. |
| Kubernetes | Helm chart | The upstream team's production method. Most advanced support. |
| Bare metal | Python + Node + nginx | Manual; not documented by upstream. |
| YunoHost | YunoHost app | Community-maintained. |
| Nix | NixOS package | Community-maintained; marked unstable. |
| Coop-Cloud | Coop-Cloud recipe | Community-maintained. |

> Upstream uses Kubernetes in production; Docker Compose is community-supported and works well but may lag behind K8s-specific features.

## Prerequisites

You must provision these before deploying Docs:

1. **OIDC / OpenID Connect provider** — e.g. Keycloak, Authentik, Authelia, Pocket ID, or any IdP that speaks OIDC. Upstream provides a [Keycloak example](https://github.com/suitenumerique/docs/blob/main/docs/examples/compose/keycloak/README.md).
2. **S3-compatible object storage** — MinIO works; any S3-compatible service (AWS S3, Cloudflare R2, etc.). Upstream provides a [MinIO example](https://github.com/suitenumerique/docs/blob/main/docs/examples/compose/minio/README.md).
3. **Domain name** with DNS pointing to your server.

## Inputs to collect

| Input | Example | Phase | Notes |
|---|---|---|---|
| Domain | `docs.example.com` | DNS | Where Docs frontend is accessible. |
| OIDC issuer / realm | `https://id.example.com/realms/docs` | OIDC | From your identity provider. |
| OIDC client ID + secret | `docs` / `<secret>` | OIDC | Created in your IdP for this Docs instance. |
| S3 endpoint | `https://storage.example.com` | storage | Your S3-compatible service. |
| S3 bucket name | `docs-media-storage` | storage | Create this bucket first. |
| S3 access key + secret | — | storage | Readwrite credentials for the bucket. |
| PostgreSQL password | `<openssl rand -hex 32>` | database | Set in `env.d/postgresql`. |
| Django secret key | `<openssl rand -hex 50>` | app | `DJANGO_SECRET_KEY` in `env.d/backend`. |
| Y-provider keys | `<openssl rand -hex 32>` x2 | collab | `Y_PROVIDER_API_KEY` + `COLLABORATION_SERVER_SECRET`. |
| SMTP config (opt) | host/port/user/pass | email | For document share invitations. |
| AI config (opt) | LLM base URL + API key + model | AI | OpenAI-compatible endpoint for writing helpers. |

## Install via Docker Compose

```bash
mkdir -p docs/env.d
cd docs

# Download compose file and env templates
curl -o compose.yaml \
  https://raw.githubusercontent.com/suitenumerique/docs/refs/heads/main/docs/examples/compose/compose.yaml
curl -o env.d/common \
  https://raw.githubusercontent.com/suitenumerique/docs/refs/heads/main/env.d/production.dist/common
curl -o env.d/backend \
  https://raw.githubusercontent.com/suitenumerique/docs/refs/heads/main/env.d/production.dist/backend
curl -o env.d/yprovider \
  https://raw.githubusercontent.com/suitenumerique/docs/refs/heads/main/env.d/production.dist/yprovider
curl -o env.d/postgresql \
  https://raw.githubusercontent.com/suitenumerique/docs/refs/heads/main/env.d/production.dist/postgresql
# Optional: nginx reverse proxy config
curl -o default.conf.template \
  https://raw.githubusercontent.com/suitenumerique/docs/refs/heads/main/docker/files/production/etc/nginx/conf.d/default.conf.template
```

### Configure `env.d/common`

```ini
DOCS_HOST=docs.example.com
KEYCLOAK_HOST=id.example.com
S3_HOST=storage.example.com
BUCKET_NAME=docs-media-storage
REALM_NAME=docs
```

### Configure `env.d/postgresql`

```ini
DB_HOST=postgresql
DB_NAME=docs
DB_USER=docs
DB_PASSWORD=<strong password>
POSTGRES_DB=docs
POSTGRES_USER=docs
POSTGRES_PASSWORD=<same strong password>
```

### Configure `env.d/backend`

```ini
DJANGO_SECRET_KEY=<openssl rand -hex 50>
DJANGO_ALLOWED_HOSTS=docs.example.com

# S3 storage
AWS_S3_ACCESS_KEY_ID=<s3 access key>
AWS_S3_SECRET_ACCESS_KEY=<s3 secret key>

# OIDC (update if using a non-Keycloak provider)
OIDC_RP_CLIENT_ID=docs
OIDC_RP_CLIENT_SECRET=<oidc client secret>

# SMTP (optional — for invitations)
DJANGO_EMAIL_HOST=smtp.example.com
DJANGO_EMAIL_PORT=587
DJANGO_EMAIL_HOST_USER=user@example.com
DJANGO_EMAIL_HOST_PASSWORD=<password>
DJANGO_EMAIL_FROM=noreply@example.com

# AI writing helpers (optional)
# AI_FEATURE_ENABLED=true
# AI_BASE_URL=https://api.openai.com/v1
# AI_API_KEY=<key>
# AI_MODEL=gpt-4o
```

### Configure `env.d/yprovider`

```ini
Y_PROVIDER_API_KEY=<openssl rand -hex 32>
COLLABORATION_SERVER_SECRET=<openssl rand -hex 32>
COLLABORATION_SERVER_ORIGIN=https://docs.example.com
```

### Start

```bash
docker compose -f compose.yaml up -d
```

Run database migrations on first start:

```bash
docker compose -f compose.yaml exec backend python manage.py migrate
docker compose -f compose.yaml exec backend python manage.py createsuperuser
```

Visit `https://docs.example.com` — login via your OIDC provider.

## Data layout

| Path | Content |
|---|---|
| `./data/databases/backend/` | PostgreSQL data (pgdata) |
| S3 bucket | Uploaded files, media attachments |
| Redis | Ephemeral cache — no persistent data needed |

## Run database migrations (on upgrade)

```bash
docker compose -f compose.yaml exec backend python manage.py migrate
```

## Upgrade

```bash
docker compose -f compose.yaml pull
docker compose -f compose.yaml up -d
docker compose -f compose.yaml exec backend python manage.py migrate
```

## PDF export note

PDF export uses Blocknote XL packages which are GPL-licensed (not MIT-compatible). To build Docs without these packages (MIT-only):

```bash
PUBLISH_AS_MIT=true
```

Set this build arg if building your own Docker images. The upstream pre-built `lasuite/impress-*` images include the GPL packages and thus fall under GPL for the PDF feature.

## Gotchas

- **OIDC is mandatory.** There is no built-in username/password login. You must provision an OIDC identity provider (Keycloak, Authentik, Authelia, Pocket ID, etc.) before users can log in. This is a hard requirement, not optional.
- **S3 is mandatory.** File and media uploads require S3-compatible object storage. Configure MinIO locally if you don't want a cloud service.
- **Both uid 1000 and uid 101 need write access.** The backend + y-provider run as uid 1000; the nginx frontend runs as uid 101. If you mount volumes, ensure permissions match.
- **Run migrations on every upgrade.** Django migrations are not auto-applied on container start. Always run `python manage.py migrate` after pulling new images.
- **Collaboration WebSocket origin must match.** `COLLABORATION_SERVER_ORIGIN` must exactly match the frontend's public URL. Mismatches cause WebSocket connection failures and break real-time editing.
- **PDF export is GPL.** If your deployment needs to comply with MIT licensing throughout, build images with `PUBLISH_AS_MIT=true` to exclude the GPL Blocknote XL packages.
- **Kubernetes is the production-grade path.** Upstream only uses and formally supports Kubernetes. Docker Compose is community-maintained — file issues if you find gaps, but expect K8s-first answers from maintainers.
- **Nginx template is required for production.** Without `default.conf.template`, the frontend container won't route API calls and collaboration WebSocket correctly.
- **SMTP is optional but needed for invitations.** Without SMTP config, document sharing still works but email notifications/invitations are silently dropped.

## Links

- Repo: <https://github.com/suitenumerique/docs>
- Releases: <https://github.com/suitenumerique/docs/releases>
- Docker Compose install guide: <https://github.com/suitenumerique/docs/blob/main/docs/installation/compose.md>
- Kubernetes install guide: <https://github.com/suitenumerique/docs/blob/main/docs/installation/kubernetes.md>
- Environment variables reference: <https://github.com/suitenumerique/docs/blob/main/docs/env.md>
- Keycloak compose example: <https://github.com/suitenumerique/docs/blob/main/docs/examples/compose/keycloak/README.md>
- MinIO compose example: <https://github.com/suitenumerique/docs/blob/main/docs/examples/compose/minio/README.md>
- Demo: <https://docs.la-suite.eu/docs/9137bbb5-3e8a-4ff7-8a36-fcc4e8bd57f4/>
- Matrix chat: <https://matrix.to/#/#docs-official:matrix.org>
