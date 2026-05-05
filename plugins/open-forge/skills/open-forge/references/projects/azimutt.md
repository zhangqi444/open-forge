# Azimutt

Database schema explorer and entity-relationship diagram (ERD) tool. Connects directly to live databases (PostgreSQL, MySQL, MariaDB, SQLite, MongoDB, Couchbase, and more) or imports schema from SQL files. Supports large, messy real-world schemas with filtering, documentation, data exploration, and team collaboration.

**Official site:** https://azimutt.app

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux host | Docker Compose | Recommended; Elixir/Phoenix + PostgreSQL |
| Any Linux host | Build from source | Elixir/Node.js required |
| VPS / cloud VM | Docker Compose + reverse proxy | Expose via Nginx/Traefik with HTTPS |

---

## Inputs to Collect

### Phase 1 — Planning
- Public-facing hostname (`PHX_HOST`) — required for correct URL generation
- PostgreSQL credentials for the app database
- File storage: local filesystem (default) or S3-compatible
- Email adapter (optional — for user account activation)

### Phase 2 — Deployment
- `SECRET_KEY_BASE` — 64-byte random secret (`mix phx.gen.secret` or `openssl rand -base64 48`)
- `DATABASE_URL` — PostgreSQL connection string
- `PORT` — internal HTTP port (default `4000`)

---

## Software-Layer Concerns

### Docker Compose

```yaml
services:
  database:
    image: postgres:15-alpine
    restart: always
    container_name: azimutt-db
    volumes:
      - pg-data:/var/lib/postgresql/data
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: azimutt_dev

  backend:
    image: ghcr.io/azimuttapp/azimutt:latest
    container_name: azimutt-backend
    restart: always
    depends_on:
      - database
    ports:
      - 4000:4000
    environment:
      PHX_SERVER: "true"
      PHX_HOST: localhost          # set to your domain in production
      PORT: "4000"
      SECRET_KEY_BASE: CHANGE_ME   # generate with: openssl rand -base64 48
      DATABASE_URL: "ecto://postgres:postgres@database/azimutt_dev"
      FILE_STORAGE_ADAPTER: local

volumes:
  pg-data:
```

> **Note:** The upstream `docker-compose.yml` uses a local build. Replace with `image: ghcr.io/azimuttapp/azimutt:latest` for a pre-built image, or use the compose file from the repo to build locally.

### Key Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `PHX_HOST` | Yes | Public hostname (no protocol prefix) |
| `SECRET_KEY_BASE` | Yes | 48+ byte random base64 secret |
| `DATABASE_URL` | Yes | Ecto/PostgreSQL connection string |
| `PORT` | No | HTTP listen port (default `4000`) |
| `FILE_STORAGE_ADAPTER` | No | `local` (default) or `s3` |
| `S3_BUCKET`, `S3_HOST`, `S3_KEY_ID`, `S3_KEY_SECRET` | No | S3 config when using S3 storage |
| `EMAIL_ADAPTER` | No | `mailgun`, `gmail`, `smtp` |
| `AUTH_PASSWORD` | No | `true` to enable email/password login |

### Database Migrations

Migrations run automatically on container startup via the Phoenix application.

---

## Upgrade Procedure

```bash
docker compose pull
docker compose up -d
```

Database migrations are applied automatically. Review [release notes](https://github.com/azimuttapp/azimutt/releases) for breaking changes before upgrading.

---

## Gotchas

- **`PHX_HOST` must match the actual hostname** — Phoenix uses this for URL generation; wrong value breaks asset loading and links.
- **`SECRET_KEY_BASE` length** — must be at least 64 characters; use `openssl rand -base64 48` or `mix phx.gen.secret`.
- **Database connections to external DBs** — Azimutt connects to your target databases at query time; ensure network reachability from the container to your databases.
- **`platform: linux/amd64`** in the upstream compose — the pre-built image may require emulation on ARM hosts; check for ARM64 image availability.
- **License key** — a free tier is available for self-hosting; some enterprise features (e.g., SSO) require a `LICENCE_KEY`.
- **Local file storage** — with `FILE_STORAGE_ADAPTER=local`, uploaded files are stored inside the container. Mount a volume to `/app/priv/static/uploads` to persist them.

---

## References
- GitHub: https://github.com/azimuttapp/azimutt
- Install guide: https://github.com/azimuttapp/azimutt/blob/main/INSTALL.md
- .env.example: https://github.com/azimuttapp/azimutt/blob/main/.env.example
- docker-compose.yml: https://github.com/azimuttapp/azimutt/blob/main/docker-compose.yml
