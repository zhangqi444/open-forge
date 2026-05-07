---
name: tracim
description: Tracim recipe for open-forge. Collaborative platform combining file sharing, threaded discussions, notes, agenda, task/project management, and knowledge base. Python + React + PostgreSQL. Docker. AGPL-3.0/LGPL-3.0/MIT. Source: https://github.com/tracim/tracim
---

# Tracim

Unified team collaboration platform. Combines file sharing (with versioning), threaded discussions, notes, agenda, task and project management, and knowledge documentation — all organized in "spaces." No more fragmented tools. Python + React + PostgreSQL (or SQLite). Docker. Multilingual (Arabic, English, French, German, Portuguese). AGPL-3.0 / LGPL-3.0 / MIT licensed.

> **Note:** Docker images for the latest Tracim versions are only available to paying customers. The community can run older versions from Docker Hub. Development is under active rework as of early 2026.

Upstream: <https://github.com/tracim/tracim> | Website: <https://www.tracim-teamwork.com> | Demo: <https://demo.tracim.fr>

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any | Docker (SQLite) | Quickstart / evaluation |
| Any | Docker (PostgreSQL) | Production recommended |
| Linux | Manual (Python) | See development docs |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| config | DATABASE_TYPE | `sqlite` (default) or `postgresql` |
| config | TRACIM_WEBSITE__BASE_URL | Public URL, e.g. `http://192.168.1.10:8080` |
| config | Port | Map to container port 80 |
| config (PostgreSQL) | DATABASE_USER, DATABASE_PASSWORD, DATABASE_NAME | |
| config | Admin credentials | Default: `admin@admin.admin` / `admin@admin.admin` — change immediately |

## Software-layer concerns

### Config & data directories

| Host path | Container path | Description |
|---|---|---|
| `~/tracim/etc` | `/etc/tracim` | Configuration files |
| `~/tracim/var` | `/var/tracim` | Data, uploads, SQLite DB |

### Key env vars

| Var | Description |
|---|---|
| DATABASE_TYPE | `sqlite` or `postgresql` |
| TRACIM_WEBSITE__BASE_URL | Public base URL (used in links, emails, CORS) |
| DATABASE_USER | PostgreSQL username (when using postgresql) |
| DATABASE_PASSWORD | PostgreSQL password |
| DATABASE_NAME | PostgreSQL database name |

## Install — Docker (SQLite, quickstart)

```bash
mkdir -p ~/tracim/etc ~/tracim/var

docker run -d \
  --name tracim \
  --restart unless-stopped \
  -e DATABASE_TYPE=sqlite \
  -e TRACIM_WEBSITE__BASE_URL=http://yourserver:8080 \
  -p 8080:80 \
  -v ~/tracim/etc:/etc/tracim \
  -v ~/tracim/var:/var/tracim \
  algoo/tracim:latest

# Login at http://yourserver:8080/ui/login
# Default admin: admin@admin.admin / admin@admin.admin
```

## Install — Docker (PostgreSQL, production)

```yaml
services:
  tracim:
    image: algoo/tracim:latest
    restart: unless-stopped
    ports:
      - 8080:80
    environment:
      DATABASE_TYPE: postgresql
      DATABASE_USER: tracim
      DATABASE_PASSWORD: yourpassword
      DATABASE_NAME: tracim
      TRACIM_WEBSITE__BASE_URL: https://tracim.example.com
    volumes:
      - ./tracim/etc:/etc/tracim
      - ./tracim/var:/var/tracim
    depends_on:
      - db

  db:
    image: postgres:17
    restart: unless-stopped
    environment:
      POSTGRES_USER: tracim
      POSTGRES_PASSWORD: yourpassword
      POSTGRES_DB: tracim
    volumes:
      - db_data:/var/lib/postgresql/data

volumes:
  db_data:
```

```bash
docker compose up -d
```

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
# Tracim runs DB migrations automatically on startup
```

## Gotchas

- **Change admin credentials immediately** — default `admin@admin.admin` / `admin@admin.admin` is public knowledge.
- **Latest Docker images require a paid subscription** — only older community images are freely available on Docker Hub. For production deployments on the latest version, contact https://www.tracim-teamwork.com.
- **TRACIM_WEBSITE__BASE_URL must be set correctly** — this drives all internal links, email notifications, and CORS rules. Set it to the exact public URL users will access.
- **Active development rework (2026)** — the project announced a rework of release and development processes in January 2026. Check upstream before deploying for new features or migration paths.
- The `~/tracim/etc` and `~/tracim/var` directories are created on host before first run — without them, the container may start with root-owned directories that cause permission errors.

## Links

- Source: https://github.com/tracim/tracim
- Website: https://www.tracim-teamwork.com
- Demo: https://demo.tracim.fr
- Docker Hub: https://hub.docker.com/r/algoo/tracim/
- Documentation: https://github.com/tracim/tracim/tree/develop/docs
