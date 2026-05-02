---
name: velld-project
description: Velld recipe for open-forge. Self-hosted database backup management tool. Schedule automated backups for PostgreSQL, MySQL, MongoDB, and Redis. S3-compatible storage, backup diff viewer, restore UI, email notifications. Two containers (API + web). Upstream: https://github.com/dendianugerah/velld
---

# Velld

A self-hosted database backup management tool. Schedule automated backups for PostgreSQL, MySQL, MongoDB, and Redis; store them on S3-compatible storage; monitor backup status; compare backups with a diff viewer; and restore from a web UI.

Upstream: <https://github.com/dendianugerah/velld> | Docs: <https://velld.vercel.app>

Two containers: an API backend and a Next.js web frontend.

## Compatible combos

| Infra | Notes |
|---|---|
| Any Linux host with Docker | Two containers (API + web); pre-built images from GHCR |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "API host port?" | Default: `8080` |
| preflight | "Web UI host port?" | Default: `3000` |
| security | "Generate JWT_SECRET and ENCRYPTION_KEY?" | Both must be 64-character hex strings; run `openssl rand -hex 32` for each |
| security | "Admin username and password?" | `ADMIN_USERNAME_CREDENTIAL` / `ADMIN_PASSWORD_CREDENTIAL` |
| config | "Allow user registration?" | `ALLOW_REGISTER=true` for initial setup; set `false` in production |

## Software-layer concerns

### Images

```
ghcr.io/dendianugerah/velld/api:latest
ghcr.io/dendianugerah/velld/web:latest
```

### Pre-flight: generate secrets

```bash
echo "JWT_SECRET=$(openssl rand -hex 32)"
echo "ENCRYPTION_KEY=$(openssl rand -hex 32)"
```

Copy the output into your `.env` file. **Do not use shell substitution directly in `.env` files** — `$(openssl rand -hex 32)` won't execute there; paste the literal values.

> **`ENCRYPTION_KEY` must be exactly 64 hex characters.** Velld uses it to encrypt backup credentials at rest. Loss of this key means stored backup credentials become unrecoverable.

### `.env` file

```bash
NEXT_PUBLIC_API_URL=http://localhost:8080

JWT_SECRET=<64-char hex>
ENCRYPTION_KEY=<64-char hex>

ADMIN_USERNAME_CREDENTIAL=admin
ADMIN_PASSWORD_CREDENTIAL=changeme   # CHANGE THIS

ALLOW_REGISTER=true                  # Set false after initial setup
```

### Compose

```yaml
services:
  api:
    image: ghcr.io/dendianugerah/velld/api:latest
    restart: unless-stopped
    ports:
      - "8080:8080"
    env_file:
      - .env
    volumes:
      - api_data:/app/data
      - backup_data:/app/backups

  web:
    image: ghcr.io/dendianugerah/velld/web:latest
    restart: unless-stopped
    ports:
      - "3000:3000"
    environment:
      NEXT_PUBLIC_API_URL: ${NEXT_PUBLIC_API_URL}
      ALLOW_REGISTER: ${ALLOW_REGISTER}
    depends_on:
      - api

volumes:
  api_data:
  backup_data:
```

> Source: upstream docker-compose.prebuilt.yml — <https://github.com/dendianugerah/velld/blob/main/docker-compose.prebuilt.yml>

### Persistent volumes

| Volume | Container path | Contents |
|---|---|---|
| `api_data` | `/app/data` | App database (connections, schedules, users) |
| `backup_data` | `/app/backups` | Downloaded backup files (before S3 upload) |

### Supported databases

| Database | Notes |
|---|---|
| PostgreSQL | Full backup and restore |
| MySQL | Full backup and restore |
| MongoDB | Full backup and restore |
| Redis | Full backup and restore |

Database credentials are stored encrypted at rest using `ENCRYPTION_KEY`.

### S3-compatible storage

Configure S3 (or any S3-compatible endpoint — MinIO, Backblaze B2, Cloudflare R2, etc.) in the web UI after first login. Velld uploads completed backups to the configured bucket.

### Email notifications

Configure email/SMTP for failed backup notifications from the Settings panel in the web UI.

## First run

1. Start containers: `docker compose up -d`
2. Open `http://localhost:3000`
3. Log in with `ADMIN_USERNAME_CREDENTIAL` / `ADMIN_PASSWORD_CREDENTIAL`
4. Connect your first database under Connections
5. Schedule a backup job
6. (Optional) Configure S3 storage and email notifications in Settings

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

Named volumes persist all data across upgrades.

## Gotchas

- **`ENCRYPTION_KEY` must be exactly 64 hex characters** — any other length causes startup failure or silent corruption. Generate with `openssl rand -hex 32` (outputs exactly 64 hex chars).
- **Do not use shell substitution in `.env`** — `$(openssl rand -hex 32)` is not expanded in `.env` files. Run the command in your shell, then paste the literal output.
- **`ENCRYPTION_KEY` loss = credential loss** — stored database connection credentials are encrypted with this key. If it changes or is lost, existing connections cannot be decrypted. Back it up securely alongside your data.
- **`NEXT_PUBLIC_API_URL` must be reachable from the browser** — this is a client-side variable baked into the Next.js frontend. If accessing Velld from another machine, set it to the host's LAN IP or public hostname, not `localhost`.
- **Set `ALLOW_REGISTER=false` in production** — after creating your admin account, disable open registration.
- **`ADMIN_PASSWORD_CREDENTIAL` should be changed** — the default `changeme` is insecure. Update it in `.env` before first run.
- **S3 configuration is optional** — Velld works without S3 (backups are stored locally in `backup_data`). Add S3 when you want off-host backup storage.

## Links

- Upstream README: <https://github.com/dendianugerah/velld>
- Documentation + Quick Start: <https://velld.vercel.app>
- Installation guide: <https://velld.vercel.app/docs/installation>
