---
name: Docmost
description: Open-source collaborative wiki / documentation platform with real-time editing, nested pages, spaces, and whiteboard. Node.js + Postgres + Redis.
---

# Docmost

Docmost is a self-hosted Notion/Confluence-style collaborative wiki. Rich text editor with collaborative editing (Yjs), nested page tree, spaces for access control, Mermaid / drawio diagrams, comments, permissions, SSO (SAML/OIDC).

- Upstream repo: <https://github.com/docmost/docmost>
- Docs: <https://docmost.com/docs/>
- Install docs: <https://docmost.com/docs/installation/>
- Image: `docmost/docmost` on Docker Hub

## Compatible install methods

| Infra              | Runtime               | Notes                                                              |
| ------------------ | --------------------- | ------------------------------------------------------------------ |
| Single VM          | Docker + Compose      | Recommended — upstream ships `docker-compose.yml`                  |
| Kubernetes         | Community Helm charts | No official chart; manifests trivial given the 3-service design    |
| Bare metal (Node)  | `pnpm build && pnpm start` | Possible; requires Postgres + Redis; see docs                |

## Inputs to collect

| Input            | Example                                                    | Phase   | Notes                                                                      |
| ---------------- | ---------------------------------------------------------- | ------- | -------------------------------------------------------------------------- |
| `APP_URL`        | `https://docs.example.com`                                 | Runtime | Full origin incl. scheme; used in invite links + cookies                   |
| `APP_SECRET`     | 32+ random hex bytes (`openssl rand -hex 32`)              | Runtime | **Required.** JWT signing; rotating invalidates all sessions + invites     |
| `DATABASE_URL`   | `postgresql://docmost:<pw>@db:5432/docmost`                | Runtime | Postgres 15+; docker-compose pins `postgres:18`                            |
| `REDIS_URL`      | `redis://redis:6379`                                       | Runtime | Used for sessions + Y.js collab state                                      |
| Storage driver   | `local` (default) or `s3`                                  | Runtime | Local = inside `/app/data/storage` volume; S3 for scale                    |
| Mail driver      | `smtp` or `postmark`                                       | Runtime | Needed for invites, password reset, notifications                          |

## Install via Docker Compose

Upstream's `docker-compose.yml` (at <https://github.com/docmost/docmost/blob/main/docker-compose.yml>) is the canonical deployment. Replace the placeholder secrets:

```yaml
services:
  docmost:
    image: docmost/docmost:0.13.0   # pin a release; avoid :latest in production
    depends_on:
      - db
      - redis
    environment:
      APP_URL: 'https://docs.example.com'
      APP_SECRET: 'REPLACE_WITH_OPENSSL_RAND_HEX_32'
      DATABASE_URL: 'postgresql://docmost:STRONG_DB_PASSWORD@db:5432/docmost'
      REDIS_URL: 'redis://redis:6379'
      # Mail (required for invites / password reset):
      MAIL_DRIVER: smtp
      MAIL_FROM_ADDRESS: 'docs@example.com'
      MAIL_FROM_NAME: 'Docmost'
      SMTP_HOST: smtp.example.com
      SMTP_PORT: 587
      SMTP_USERNAME: 'docs@example.com'
      SMTP_PASSWORD: '__smtp_password__'
    ports:
      - "3000:3000"
    restart: unless-stopped
    volumes:
      - docmost:/app/data/storage

  db:
    image: postgres:18
    environment:
      POSTGRES_DB: docmost
      POSTGRES_USER: docmost
      POSTGRES_PASSWORD: STRONG_DB_PASSWORD
    restart: unless-stopped
    volumes:
      - db_data:/var/lib/postgresql

  redis:
    image: redis:8
    command: ["redis-server", "--appendonly", "yes", "--maxmemory-policy", "noeviction"]
    restart: unless-stopped
    volumes:
      - redis_data:/data

volumes:
  docmost:
  db_data:
  redis_data:
```

Steps:

1. Generate `APP_SECRET`: `openssl rand -hex 32`.
2. Pick a strong Postgres password and set it in **both** `DATABASE_URL` and `POSTGRES_PASSWORD` — they must match.
3. Terminate TLS at a reverse proxy that forwards to `docmost:3000`.
4. `docker compose up -d`.
5. Browse `APP_URL` → register the first workspace admin → later users come in by invite.

Releases: <https://github.com/docmost/docmost/releases>. Pin the image tag per release.

### S3 storage (recommended for scale)

```yaml
    environment:
      STORAGE_DRIVER: s3
      AWS_S3_ACCESS_KEY_ID: ...
      AWS_S3_SECRET_ACCESS_KEY: ...
      AWS_S3_REGION: us-east-1
      AWS_S3_BUCKET: docmost-uploads
      AWS_S3_ENDPOINT: https://s3.amazonaws.com
      # For MinIO / non-AWS:
      AWS_S3_FORCE_PATH_STYLE: "true"
```

## Data & config layout

- Volume `docmost` → `/app/data/storage` — uploaded files, attachments (only used when `STORAGE_DRIVER=local`)
- Volume `db_data` → `/var/lib/postgresql` — Postgres data
- Volume `redis_data` → `/data` — Redis AOF (sessions + collab doc state — rebuildable but losing it kicks everyone out)
- Config: entirely environment-variable driven; full reference at <https://github.com/docmost/docmost/blob/main/.env.example>

## Backup

```sh
# Database
docker compose exec -T db pg_dump -U docmost docmost | gzip > docmost-db-$(date +%F).sql.gz

# Local storage (skip if using S3)
docker run --rm -v docmost_docmost:/data -v "$PWD":/backup alpine \
  tar czf /backup/docmost-storage-$(date +%F).tgz -C /data .
```

**Preserve `APP_SECRET`** — losing it invalidates outstanding invite tokens and anything else JWT-signed.

## Upgrade

1. Check release notes: <https://github.com/docmost/docmost/releases>.
2. Bump the `docmost/docmost` image tag in compose.
3. `docker compose pull && docker compose up -d`.
4. The entrypoint runs migrations on boot; watch `docker compose logs -f docmost`.
5. Back up Postgres first for major version bumps.

## Gotchas

- **`APP_SECRET` is permanent.** Rotating it boots every user and invalidates every pending invite. Treat it like a DB encryption key.
- **Postgres password double-set trap.** `DATABASE_URL` encodes the password; `POSTGRES_PASSWORD` in the db service sets it. Both must match, and `POSTGRES_PASSWORD` is locked in on first volume init (changing it later has no effect without re-init or an in-place ALTER USER).
- **Redis maxmemory-policy must be `noeviction`.** Upstream sets it in the compose command — don't change to `allkeys-lru` or active Y.js docs will corrupt.
- **No built-in TLS.** Put behind Caddy/Traefik/nginx that terminates HTTPS; Docmost listens on HTTP 3000.
- **Real-time collab needs WebSocket passthrough.** If your reverse proxy rewrites or blocks `Upgrade` headers, real-time editing silently falls back to no-sync and users see their edits revert.
- **SMTP required for invites + password reset.** Workspace admin sign-up works without SMTP, but subsequent users need mail.
- **`postgres:18` is very new.** If you need to downgrade to `postgres:16`, restore from a pg_dump (the on-disk format differs across major versions).
- **Telemetry is on by default** (`DISABLE_TELEMETRY=false`). Set to `true` for air-gapped or privacy-sensitive deployments.
- **Gotenberg (PDF export)** and **drawio server** are optional sidecars; set `GOTENBERG_URL` / `DRAWIO_URL` if you run them. Without them the corresponding UI buttons fail silently.
- **File upload size** defaults to 50 MB; bump `FILE_UPLOAD_SIZE_LIMIT` and your reverse-proxy body-size limit for larger attachments.
- **Storage-driver switch is not automatic.** Changing `STORAGE_DRIVER=local → s3` does not migrate existing files — they stay in the local volume until you move them manually.

## Links

- Repo: <https://github.com/docmost/docmost>
- Docs: <https://docmost.com/docs/>
- Installation: <https://docmost.com/docs/installation/>
- Env var reference: <https://github.com/docmost/docmost/blob/main/.env.example>
- Compose file: <https://github.com/docmost/docmost/blob/main/docker-compose.yml>
- Releases: <https://github.com/docmost/docmost/releases>
