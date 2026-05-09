# Stormkit

Self-hostable hosting platform for seamless deployment and management of modern web applications. Positioned as an alternative to Vercel/Netlify. Provides automated CI/CD, custom domains, environment management, and a web interface for deploying static sites and serverless functions. Built with Go microservices and a React frontend; requires PostgreSQL and Redis.

**Official site:** https://www.stormkit.io  
**Source:** https://github.com/stormkit-io/stormkit-io  
**Upstream docs:** https://github.com/stormkit-io/stormkit-io#readme  
**Docker images:**
- `ghcr.io/stormkit-io/workerserver:latest`
- `ghcr.io/stormkit-io/hosting:latest`

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux host | Docker Compose | Recommended self-hosted method |
| Any Linux host | Go binaries | Upstream provides pre-built binaries |

**Prerequisites:** PostgreSQL 14+ and Redis 7+.

---

## Inputs to Collect

### Database
| Variable | Description | Example |
|----------|-------------|---------|
| `POSTGRES_DB` | PostgreSQL database name | `stormkit` |
| `POSTGRES_USER` | PostgreSQL username | `stormkit` |
| `POSTGRES_PASSWORD` | PostgreSQL password | strong random string |

### Application
| Variable | Description | Example |
|----------|-------------|---------|
| Domain | Public hostname for the Stormkit web interface | `deploy.example.com` |

---

## Software-Layer Concerns

### Docker Compose (infrastructure layer)

Upstream provides a `docker-compose.yaml` for the supporting services (database + cache). The Stormkit application services (`workerserver`, `hosting`) connect to these:

```yaml
volumes:
  stormkit:

services:
  db:
    image: postgres:17
    container_name: database
    restart: always
    ports:
      - "5432:5432"
    environment:
      - POSTGRES_DB=${POSTGRES_DB}
      - POSTGRES_USER=${POSTGRES_USER}
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}

  redis:
    container_name: redis
    image: redis:7
    restart: always
    ports:
      - "6379:6379"
```

Application images (`workerserver` and `hosting`) are configured separately. Refer to upstream documentation for the complete multi-container deployment and environment variable reference.

### Local development stack

```bash
git clone https://github.com/stormkit-io/stormkit-io.git
cd stormkit-io
# Install go and node via mise
mise trust && mise install
# Start all services (includes DB setup and migrations)
make dev
```

After starting:
- Landing page: https://localhost:5500
- Application UI: https://localhost:5400
- API: http://api.localhost:8888

### Project structure

- `src/ce/` — Community Edition (AGPL-3.0): API, hosting service, runner, worker
- `src/ee/` — Enterprise Edition (commercial license)
- `src/ui/` — React frontend
- `src/migrations/` — database migrations

---

## Upgrade Procedure

```bash
docker compose pull
docker compose up -d
```

For binary deployments, download the new release artifacts and replace the existing binaries. Check upstream release notes for migration steps.

---

## Gotchas

- Stormkit has two editions: **Community Edition** (AGPL-3.0, `src/ce/`) and **Enterprise Edition** (commercial, `src/ee/`). Self-hosted users use the CE.
- PostgreSQL and Redis are **required** — Stormkit does not run without both.
- The upstream `docker-compose.yaml` only covers the infrastructure (DB + Redis); the Stormkit application images are deployed separately. Consult upstream docs for the full production compose.
- The project is under active development — check release notes before upgrading.

---

**Upstream README:** https://github.com/stormkit-io/stormkit-io#readme  
**Troubleshooting:** https://github.com/stormkit-io/stormkit-io/blob/main/docs/troubleshooting.md
