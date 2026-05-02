---
name: luna-project
description: Luna recipe for open-forge. Covers Docker Compose (build-from-source or community images) and bare-metal deployment of this self-hosted calendar frontend and CalDAV/iCal/Google Calendar aggregator. Based on upstream README and documentation/deployment.md at https://github.com/Opisek/luna.
---

# Luna

Self-hosted calendar frontend and aggregator. Aggregates CalDAV, iCal, and Google Calendar sources into a single customizable web UI. Includes user management and theming. Upstream: <https://github.com/Opisek/luna>. Deployment guide: <https://github.com/Opisek/luna/blob/main/documentation/deployment.md>.

> ⚠️ **Pre-release software**: Luna is approaching 1.0.0 but is not yet officially released. Expect potential breaking changes between updates until 1.0.0. Back up your database before every upgrade and be prepared to recreate it.

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux host / VPS | Docker Compose (build from source) | Official method; clone repo and run `make` |
| Any Linux host / VPS | Docker Compose (community images) | Community images: `tiritibambix/lunafrontend` + `tiritibambix/lunabackend` — no upstream warranty |
| Linux bare metal | Bun + Go | Requires `make`, `bun` ≥1.2.5, `go` ≥1.23, Postgres 16+ |

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| deploy | "Public URL for your Luna instance?" | URL | Sets `PUBLIC_URL` in both frontend and backend (e.g. `https://cal.example.com`) |
| database | "Postgres password for the `luna` user?" | Free-text (sensitive) | Sets `DB_PASSWORD` / `POSTGRES_PASSWORD` |
| database | "Postgres host (if external)?" | Hostname | Default: `luna-postgres` (compose internal) |
| reverse-proxy | "Will Luna be behind a reverse proxy with TLS?" | Yes / No | Required for production — Luna does not handle TLS |

## Software-layer concerns

### Environment variables

**Frontend:**

| Variable | Description |
|---|---|
| `PORT` | Port frontend listens on (default `8080`) |
| `PUBLIC_URL` | Full public URL (e.g. `https://cal.example.com`) |
| `API_URL` | Internal URL of backend (e.g. `http://luna-backend:3000`) |

**Backend:**

| Variable | Description |
|---|---|
| `PUBLIC_URL` | Full public URL — must match frontend |
| `DB_HOST` | Postgres host |
| `DB_PORT` | Postgres port (default `5432`) |
| `DB_USERNAME` | Postgres user (default `luna`) |
| `DB_PASSWORD` | Postgres password |
| `DB_DATABASE` | Postgres database name (default `luna`) |

### Docker Compose (from upstream documentation)

```yaml
name: luna
services:
  luna-frontend:
    container_name: luna-frontend
    ports:
      - "8080:8080"
    volumes:
      - /etc/timezone:/etc/timezone:ro
      - /etc/localtime:/etc/localtime:ro
    environment:
      PORT: 8080
      PUBLIC_URL: https://cal.example.com
      API_URL: http://luna-backend:3000
    build:
      context: frontend
      dockerfile: Dockerfile

  luna-backend:
    container_name: luna-backend
    volumes:
      - /srv/luna/data:/data
      - /etc/timezone:/etc/timezone:ro
      - /etc/localtime:/etc/localtime:ro
    environment:
      PUBLIC_URL: https://cal.example.com
      DB_HOST: luna-postgres
      DB_PORT: 5432
      DB_USERNAME: luna
      DB_PASSWORD: luna
      DB_DATABASE: luna
    depends_on:
      - luna-postgres
    build:
      context: backend
      dockerfile: Dockerfile

  luna-postgres:
    image: postgres:16-alpine
    container_name: luna-postgres
    volumes:
      - /srv/luna/postgres:/var/lib/postgresql/data
      - /etc/timezone:/etc/timezone:ro
      - /etc/localtime:/etc/localtime:ro
    environment:
      POSTGRES_USER: luna
      POSTGRES_PASSWORD: luna
      POSTGRES_DB: luna
```

### Volumes / data paths

| Path | Purpose |
|---|---|
| `/srv/luna/data` | Backend runtime data |
| `/srv/luna/postgres` | Postgres data directory |

### Bare-metal deployment

1. Backend: create `.env` in `backend/src/` from `.env.example`; run `make` (dev) or `make build` (prod binary `luna-backend` in `backend/src/`)
2. Frontend: create `.env` in `frontend/` from `.env.example`; run `make` (dev) or `make build` + `bun run ./build/index.js` (prod)

Requirements: `make`, `bun` ≥1.2.5, `go` ≥1.23, Postgres 16+

## Upgrade procedure

> ⚠️ Until 1.0.0, assume a database wipe may be necessary. Take a Postgres dump before upgrading.

```bash
git pull
# If using build-from-source Docker Compose:
docker compose build
docker compose up -d
```

For community Docker images: pull new tags from Docker Hub and recreate containers.

## Gotchas

- **Pre-release**: no stability guarantees on database schema until 1.0.0. Plan for potential `pg_dumpall` + fresh-init cycles.
- No official pre-built Docker images yet — the upstream compose builds from source. Community images exist but are not maintained by the Luna author.
- `PUBLIC_URL` must be set identically in both frontend and backend — mismatch causes calendar sync and auth failures.
- Luna **requires a reverse proxy with TLS** for any internet-facing deployment; it does not serve HTTPS natively.
- Timezone mounts (`/etc/timezone`, `/etc/localtime`) are required for correct calendar event times — do not omit them.
- Google Calendar requires an iCal export URL (not OAuth) — Luna uses the iCal protocol to read Google Calendar.

## Links

- Upstream repo: <https://github.com/Opisek/luna>
- Deployment guide: <https://github.com/Opisek/luna/blob/main/documentation/deployment.md>
- Security & privacy: <https://github.com/Opisek/luna/blob/main/documentation/security.md>
- Development roadmap: <https://todo.opisek.net/share/dvEazOyRLEYThqxohVosnqKskYLyoZ4nS8rQ63G1/auth?view=280>
- Community Docker images (unofficial): [tiritibambix/lunafrontend](https://hub.docker.com/r/tiritibambix/lunafrontend) · [tiritibambix/lunabackend](https://hub.docker.com/r/tiritibambix/lunabackend)
