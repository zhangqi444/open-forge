---
name: la-suite-docs
description: Recipe for self-hosting La Suite Docs (suitenumerique/docs), an open-source real-time collaborative editor — an alternative to Notion or Google Docs. Based on upstream documentation at https://github.com/suitenumerique/docs.
---

# La Suite Docs

Open-source collaborative editor for teams. Real-time co-editing, rich text + Markdown, subpages, comments, access control, and optional AI writing helpers. Self-hostable alternative to Notion or Google Docs. Built with Django and React. Upstream: <https://github.com/suitenumerique/docs>. Stars: 16k+. License: MIT (with GPL exception for PDF export — see Gotchas).

Originally developed for French public-sector organizations; suitable for any organization wanting data sovereignty.

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux host | Docker Compose | Provided upstream; not used in production by maintainers — community-supported |
| Kubernetes | Helm chart | Maintainer-supported production path |
| YunoHost | YunoHost app | Community-maintained |

## Service architecture

| Service | Image | Port | Role |
|---|---|---|---|
| postgresql | postgres:16 | 5432 (internal) | Primary database |
| redis | redis:8 | 6379 (internal) | Caching |
| backend | lasuite/impress-backend | — | Django API server |
| yprovider | lasuite/impress-y-provider | — | WebSocket collaboration (Yjs) |
| frontend | lasuite/impress-frontend | 80 | React web UI |
| nginx (optional) | nginx | 80/443 | Reverse proxy |

Object storage (S3-compatible) and an OIDC identity provider are **required** external dependencies.

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| required | DJANGO_SECRET_KEY | Secure random string for Django |
| required | DB_PASSWORD | PostgreSQL password |
| required | Y_PROVIDER_API_KEY | Secure random key for Y provider |
| required | COLLABORATION_SERVER_SECRET | Secure random key |
| required | OIDC provider URL + client ID + secret | Keycloak or any OIDC-compatible IdP |
| required | S3 bucket name + credentials | Minio or any S3-compatible store |
| optional | Domain name | For nginx/TLS config |
| optional | SMTP credentials | For invitation emails |

## Docker Compose deployment

```bash
# 1. Create working directory
mkdir -p docs/env.d && cd docs

# 2. Download compose file and env templates
curl -o compose.yaml https://raw.githubusercontent.com/suitenumerique/docs/refs/heads/main/docs/examples/compose/compose.yaml
curl -o env.d/common https://raw.githubusercontent.com/suitenumerique/docs/refs/heads/main/env.d/production.dist/common
curl -o env.d/backend https://raw.githubusercontent.com/suitenumerique/docs/refs/heads/main/env.d/production.dist/backend
curl -o env.d/yprovider https://raw.githubusercontent.com/suitenumerique/docs/refs/heads/main/env.d/production.dist/yprovider
curl -o env.d/postgresql https://raw.githubusercontent.com/suitenumerique/docs/refs/heads/main/env.d/production.dist/postgresql

# Optional: nginx reverse proxy config
curl -o default.conf.template https://raw.githubusercontent.com/suitenumerique/docs/refs/heads/main/docker/files/production/etc/nginx/conf.d/default.conf.template

# 3. Edit all env.d/* files with your values (see Configuration below)

# 4. Start the stack
docker compose up -d
```

## Configuration

### env.d/common (shared settings)

```bash
# Domain for the Docs instance
DOCS_DOMAIN=docs.yourdomain.tld

# OIDC provider (Keycloak example)
OIDC_RP_CLIENT_ID=docs
OIDC_RP_CLIENT_SECRET=<your-client-secret>
REALM_NAME=docs   # Keycloak realm name

# S3 / Object storage
AWS_S3_ACCESS_KEY_ID=<access-key>
AWS_S3_SECRET_ACCESS_KEY=<secret-key>
# Bucket name for media/files
```

### env.d/backend

```bash
DJANGO_SECRET_KEY=<secure-random-string>

# SMTP (for invitation emails)
DJANGO_EMAIL_HOST=<smtp-host>
DJANGO_EMAIL_HOST_USER=<smtp-user>
DJANGO_EMAIL_HOST_PASSWORD=<smtp-password>

# Logging (optional)
LOGGING_LEVEL_HANDLERS_CONSOLE=INFO
LOGGING_LEVEL_LOGGERS_ROOT=INFO
```

### env.d/yprovider

```bash
Y_PROVIDER_API_KEY=<secure-random-key>
COLLABORATION_SERVER_SECRET=<secure-random-key>
```

### env.d/postgresql

```bash
DB_PASSWORD=<secure-password>
```

### MIT-only build (no PDF export)

To build without GPL-licensed XL packages (for MIT-clean deployments):

```bash
PUBLISH_AS_MIT=true docker compose build
```

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

Backend migrations run automatically on startup. Check `docker compose logs backend` after upgrading.

## Gotchas

- **PDF export requires GPL packages.** The `Export as PDF` feature uses Blocknote XL packages licensed under GPL, which are not MIT-compatible. Build with `PUBLISH_AS_MIT=true` to exclude them and get a pure MIT build.
- **OIDC identity provider is required.** Docs has no built-in username/password login — you must configure an external OIDC provider (Keycloak is documented upstream; other providers work with manual env var tuning in `env.d/backend`).
- **S3-compatible object storage is required.** Files and media cannot be stored on local filesystem without additional configuration — Minio is provided as an example in the upstream examples directory.
- The Docker Compose path is community-supported, not used in production by the Docs maintainers. For production, use the Kubernetes Helm chart.
- Default admin credentials: `admin` / `admin` — change immediately after first login.

## Upstream docs

- README: https://github.com/suitenumerique/docs/blob/main/README.md
- Installation overview: https://github.com/suitenumerique/docs/blob/main/docs/installation/README.md
- Docker Compose guide: https://github.com/suitenumerique/docs/blob/main/docs/installation/compose.md
- Environment variables: https://github.com/suitenumerique/docs/blob/main/docs/env.md
- Keycloak example: https://github.com/suitenumerique/docs/blob/main/docs/examples/compose/keycloak/README.md
- Minio example: https://github.com/suitenumerique/docs/blob/main/docs/examples/compose/minio/README.md
