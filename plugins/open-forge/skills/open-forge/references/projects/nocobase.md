---
name: NocoBase
description: Open-source, self-hostable no-code / low-code platform for building business applications on top of Postgres/MySQL/SQLite. Plugin-based, data-model-first.
---

# NocoBase

NocoBase is a Node.js+React no-code platform. You define data collections (tables), relationships, and UI pages through a browser admin; the platform persists to a relational DB of your choice. Extensibility is via plugins (JS/TS) — unlike most no-code tools, the core and the plugins are open source.

- Upstream repo: <https://github.com/nocobase/nocobase>
- Image: `nocobase/nocobase` on Docker Hub
- Docs: <https://docs.nocobase.com/>

## Compatible install methods

| Infra            | Runtime                                | Notes                                                             |
| ---------------- | -------------------------------------- | ----------------------------------------------------------------- |
| Single VM        | Docker + Compose (Postgres recommended) | Recommended path; upstream ships variants for Postgres/MySQL/MariaDB/SQLite |
| Kubernetes       | Manual manifests                       | No official chart                                                  |
| Bare metal (Node)| Source install (Yarn + Node 20)        | Supported; see docs                                                |

## Inputs to collect

| Input                    | Example                           | Phase   | Notes                                                                        |
| ------------------------ | --------------------------------- | ------- | ---------------------------------------------------------------------------- |
| `APP_KEY`                | 32+ random chars                  | Runtime | **Required & permanent.** Signs JWTs; rotating invalidates all sessions      |
| `ENCRYPTION_FIELD_KEY`   | 32+ random chars                  | Runtime | **Required & permanent.** Encrypts at-rest field values; losing it = data loss |
| DB dialect               | `postgres` / `mysql` / `mariadb` / `sqlite` | Runtime | Pick **before** first install; migrating dialects is not supported            |
| DB credentials           | host / user / password / database | Runtime | Must match your DB container's env                                             |
| External port            | `13000`                           | Runtime | Maps to container port 80                                                     |
| Storage dir              | `./storage`                       | Runtime | Holds uploads + SQLite DB (if using SQLite)                                   |

## Install via Docker Compose (Postgres, recommended)

Upstream's recommended compose is **`docker/app-postgres/docker-compose.yml`**, not the repo-root `docker-compose.yml` (which is a dev setup with multiple DB engines). Use:

<https://github.com/nocobase/nocobase/blob/main/docker/app-postgres/docker-compose.yml>

Copy and customize:

```yaml
services:
  app:
    image: nocobase/nocobase:1.5.0   # pin; track https://github.com/nocobase/nocobase/releases
    restart: unless-stopped
    networks:
      - nocobase
    environment:
      - APP_KEY=REPLACE_WITH_LONG_RANDOM_STRING
      - ENCRYPTION_FIELD_KEY=REPLACE_WITH_DIFFERENT_LONG_RANDOM_STRING
      - DB_DIALECT=postgres
      - DB_HOST=postgres
      - DB_DATABASE=nocobase
      - DB_USER=nocobase
      - DB_PASSWORD=change_me_strong
    volumes:
      - ./storage:/app/nocobase/storage
    ports:
      - "13000:80"
    depends_on:
      - postgres
    init: true

  postgres:
    image: postgres:16    # upstream sample uses postgres:10 — bump it
    restart: unless-stopped
    command: postgres -c wal_level=logical
    environment:
      POSTGRES_USER: nocobase
      POSTGRES_DB: nocobase
      POSTGRES_PASSWORD: change_me_strong
    volumes:
      - ./storage/db/postgres:/var/lib/postgresql/data
    networks:
      - nocobase

networks:
  nocobase:
    driver: bridge
```

Generate keys:

```sh
openssl rand -hex 32   # for APP_KEY
openssl rand -hex 32   # for ENCRYPTION_FIELD_KEY (different value!)
```

Then:

```sh
docker compose up -d
```

Browse `http://<host>:13000` → create the admin account on first load.

### MySQL / MariaDB / SQLite variants

Swap the compose file for the matching directory under <https://github.com/nocobase/nocobase/tree/main/docker>:

- `app-mysql/docker-compose.yml`
- `app-mariadb/docker-compose.yml`
- `app-sqlite/docker-compose.yml` (single-container, DB file lives in `./storage`)

SQLite is fine for evaluation but upstream recommends Postgres for production (plugin DB features assume pg where possible).

## Data & config layout

- `./storage/` → `/app/nocobase/storage` — uploads, plugin data, SQLite file if applicable
- `./storage/db/postgres/` — Postgres data dir (bound out so you can back it up)
- Config is env-var only; nothing on disk to edit inside the container

## Backup

```sh
# Postgres
docker compose exec -T postgres pg_dump -U nocobase nocobase | gzip > nocobase-db-$(date +%F).sql.gz

# Uploads + metadata
tar czf nocobase-storage-$(date +%F).tgz -C ./storage --exclude=db .
```

Store `APP_KEY` and `ENCRYPTION_FIELD_KEY` out-of-band. **`ENCRYPTION_FIELD_KEY` is not recoverable** — losing it renders all encrypted-field columns unreadable.

## Upgrade

1. Read release notes for breaking schema/plugin changes: <https://github.com/nocobase/nocobase/releases>.
2. Bump the `nocobase/nocobase` image tag.
3. `docker compose pull && docker compose up -d`.
4. The container runs migrations on boot; watch `docker compose logs -f app`. Major-version jumps (e.g. 0.x → 1.x) often require a database backup + explicit upgrade command:

   ```sh
   docker compose exec app yarn nocobase upgrade
   ```

## Gotchas

- **Repo-root `docker-compose.yml` is for contributor development**, not production. It pulls down a Verdaccio npm registry, a Kingbase image, adminer, and expects a full source checkout. Ignore it unless you're hacking on NocoBase itself.
- **Upstream sample pins `postgres:10`** which is past EOL. Bump to a supported Postgres 15/16 line at install time; once you have data, upgrading Postgres major versions requires a dump/restore.
- **`APP_KEY` + `ENCRYPTION_FIELD_KEY` must be distinct and long.** Identical or short keys make JWT + field encryption trivially brute-forceable.
- **Losing `ENCRYPTION_FIELD_KEY` is data loss.** Any field marked "encrypted" in the schema uses it; there's no recovery.
- **Dialect is sticky.** You cannot switch from SQLite → Postgres via a NocoBase command; you'd have to re-create the schema + re-ingest data.
- **Plugin market / pro plugins** require an online account on <https://portal.nocobase.com> — the core app runs offline, but some marketplace plugins need auth.
- **`depends_on` without healthcheck** — the app may start before Postgres is ready and crash-loop once; the restart policy handles it but check logs on first boot.
- **HTTPS not built in.** Put Caddy/Traefik in front; NocoBase assumes it's behind a proxy.
- **Backward-incompatible minor releases** have happened in the 0.x → 1.x transition; always take a backup before upgrading.

## Links

- Repo: <https://github.com/nocobase/nocobase>
- Docs: <https://docs.nocobase.com/>
- Install docs (Docker): <https://docs.nocobase.com/welcome/getting-started/installation/docker-compose>
- Compose variants directory: <https://github.com/nocobase/nocobase/tree/main/docker>
- Releases: <https://github.com/nocobase/nocobase/releases>
- Docker Hub: <https://hub.docker.com/r/nocobase/nocobase>
