---
name: Zane-Ops
description: "Self-hosted PaaS built on Docker Swarm. Python/Django + Next.js. zane-ops/zane-ops. Deploy apps by URL/archive/Docker image, zero-downtime deploys, metrics, logs, cron jobs, GitHub integration."
---

# Zane-Ops

**Self-hosted PaaS built on Docker Swarm.** Deploy web apps and workers from a git URL, archive, or Docker image with zero-downtime rolling deploys. Web UI + CLI, built-in HTTP proxy (Caddy), automatic TLS, metrics (CPU/memory/network/disk), log aggregation, cron jobs, environment variables, GitHub integration, and resource quotas.

Built + maintained by **zane-ops team (Frédéric Zannetie)**. MIT license.

- Upstream repo: <https://github.com/zane-ops/zane-ops>
- Docs: <https://zaneops.dev/docs>
- Website: <https://zaneops.dev>
- Discord: <https://discord.gg/CUPbHfBQMU>
- Docker Hub: `ghcr.io/zane-ops/app` / `ghcr.io/zane-ops/proxy`

## Architecture in one minute

- **Python / Django** API + **Next.js** web UI
- **Docker Swarm** orchestration (required — not plain Docker Compose)
- **Caddy** HTTP proxy (automatic TLS for deployed apps)
- **Valkey** (Redis fork) for queuing/caching
- **PostgreSQL** database
- **Temporal** workflow engine (for deployment orchestration)
- Port: **8000** API; **80/443** proxy
- Resource: **medium** — multiple services; designed for a dedicated server

## Compatible install methods

| Infra              | Runtime                             | Notes                                                                |
| ------------------ | ----------------------------------- | -------------------------------------------------------------------- |
| **Docker Swarm**   | `docker-compose.prod.yml`           | **Required** — Zane-Ops manages Swarm; use the production compose    |

## Prerequisites

- Linux server with Docker **Swarm mode initialized** (`docker swarm init`)
- Domain DNS pointing to the server
- Ports 80 + 443 open

## Install

```bash
# 1. Initialize Docker Swarm (if not already done)
docker swarm init

# 2. Clone + configure
git clone https://github.com/zane-ops/zane-ops.git
cd zane-ops
cp .env.prod.example .env

# 3. Edit .env:
#   ZANE_APP_DOMAIN=panel.example.com
#   DJANGO_SECRET_KEY=<random>
#   DB_PASSWORD=<random>
#   (and other required vars)

# 4. Deploy
docker stack deploy -c docker-compose.prod.yml zane

# 5. Create admin user
docker exec -it <zane-api-container> python manage.py createsuperuser
```

Visit `https://panel.example.com`.

Full install guide: <https://zaneops.dev/docs/getting-started/installation/>

## First boot

1. Deploy Swarm stack + create superuser.
2. Visit the web UI → log in.
3. Create a **project**.
4. Add a **service**:
   - **Web service**: provide a GitHub URL / archive URL / Docker image
   - **Worker**: background job without HTTP
   - **Cron job**: scheduled task
5. Set environment variables for the service.
6. Configure domain + TLS (handled by Caddy automatically).
7. Deploy → monitor via the built-in metrics + logs dashboards.

## Service types

| Type | Description |
|------|-------------|
| **Web service** | HTTP app; gets a public URL + TLS; zero-downtime rolling deploys |
| **Worker** | Background process; no HTTP; same resource controls |
| **Cron job** | Scheduled via cron expression |

## Features overview

| Feature | Details |
|---------|---------|
| Deploy from GitHub | Connect repo; auto-deploy on push (webhook or manual) |
| Deploy from archive | Upload a tarball of your app |
| Deploy from image | Any Docker image from any registry |
| Zero-downtime | Rolling updates; health check gates |
| Automatic TLS | Caddy provisions Let's Encrypt certs for all services |
| Metrics | CPU, memory, network I/O, disk per service |
| Log aggregation | Stream and search logs per service |
| Env vars | Per-service environment variables with secret masking |
| Resource quotas | CPU + memory limits per service |
| Cron jobs | Schedule recurring tasks |
| Rollback | Roll back to previous deploy |
| CLI | `zane` CLI for all operations |
| GitHub integration | Auto-deploy on push events |
| Multi-project | Organize services into projects |

## Backup

```sh
# PostgreSQL dump
docker exec <postgres-container> pg_dump -U zane zane > zane-$(date +%F).sql
# .env file — commit to a private repo
```

## Upgrade

1. Releases: <https://github.com/zane-ops/zane-ops/releases>
2. `git pull && docker stack deploy -c docker-compose.prod.yml zane`

## Gotchas

- **Docker Swarm is required.** Zane-Ops manages Docker Swarm services — not plain `docker compose up`. Run `docker swarm init` before deploying. Single-node Swarm is fine for a VPS.
- **Multiple services in the stack.** Zane-Ops itself consists of: API (Django), web UI (Next.js), Caddy proxy, PostgreSQL, Valkey, Temporal (workflow engine), + workers. Expect 6–8 containers running just for the platform before you deploy any apps.
- **Resource floor.** A dedicated server with 2+ CPUs and 4+ GB RAM is recommended. Don't try this on a 1 GB VPS.
- **Caddy handles all TLS.** Services deployed via Zane-Ops get automatic HTTPS via Caddy + Let's Encrypt. Ensure ports 80 + 443 are open and your domain resolves to the server.
- **Temporal for orchestration.** Temporal is a durable workflow engine. It makes deployments reliable (retries, rollbacks) but adds operational complexity. If Temporal containers fail, deployment orchestration stops.
- **CLI available.** `npm install -g @zane-ops/cli` (or equivalent) for command-line deployments. Useful for CI/CD pipelines.
- **GitHub integration via webhooks.** Configure GitHub webhook → Zane-Ops URL for push-to-deploy. Requires the server to be publicly reachable.
- **Not a K8s alternative for complex workloads.** Zane-Ops is a Heroku/Railway-style PaaS for simple web apps and workers. For databases, stateful services, or complex networking — manage those outside Zane-Ops.
- **Valkey (not Redis).** Valkey is a Redis fork following the Redis license change; functionally compatible. You don't need a separate Redis install.

## Project health

Active Python/Django + Next.js development, CLI, GitHub integration, metrics, logs, Docker Swarm. Discord community. MIT license. Funded via GitHub Sponsors.

## Self-hosted-PaaS-family comparison

- **Zane-Ops** — Python+Django, Docker Swarm, zero-downtime, metrics+logs, Caddy, Temporal, MIT
- **Coolify** — PHP, Docker/K8s support, broader app support, more mature, larger community
- **Dokku** — Shell/Go, Heroku-like, CLI-first, no web UI (optional Dokku Daemon)
- **CapRover** — Node.js, Docker Swarm, web UI, Let's Encrypt
- **Nixopus** — Go, AI agent, shell installer

**Choose Zane-Ops if:** you want a polished self-hosted PaaS with zero-downtime deploys, built-in metrics, log aggregation, and GitHub integration — running on Docker Swarm with automatic TLS.

## Links

- Repo: <https://github.com/zane-ops/zane-ops>
- Docs: <https://zaneops.dev/docs>
- Installation: <https://zaneops.dev/docs/getting-started/installation/>
- Discord: <https://discord.gg/CUPbHfBQMU>
- Coolify (alt): <https://coolify.io>
