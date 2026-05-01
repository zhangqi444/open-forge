---
name: CoreControl
description: "Self-hosted server and homelab infrastructure dashboard. Docker. Next.js + Go agent + PostgreSQL. crocofied/CoreControl. Server inventory, uptime monitoring, app quick-links, network flowcharts, notifications."
---

# CoreControl

**Self-hosted infrastructure dashboard for homelabs and self-hosted setups.** Track all your servers in one place: hardware info, quick-links to management panels, uptime monitoring for self-hosted applications, network flowchart visualisation, and notifications. Clean web UI with a Go-based monitoring agent.

Built + maintained by **crocofied**. MIT license.

- Upstream repo: <https://github.com/crocofied/CoreControl>
- Docker Hub: `haedlessdev/corecontrol` / `haedlessdev/corecontrol-agent`
- Discord: <https://discord.gg/gMSgHZDHyy>

## Architecture in one minute

- **Next.js + TypeScript** web UI
- **Go** agent (collects server hardware metrics)
- **PostgreSQL 17** database
- **Prisma ORM** (DB migrations)
- Docker Compose: `web` + `agent` + `db` containers
- Port **3000** (web UI)
- Resource: **low** — Next.js + Go + PostgreSQL

## Compatible install methods

| Infra          | Runtime                        | Notes                              |
| -------------- | ------------------------------ | ---------------------------------- |
| **Docker Compose** | `haedlessdev/corecontrol`  | **Primary** — includes web + agent + DB |

## Inputs to collect

| Input           | Example                                                       | Phase  | Notes                                        |
| --------------- | ------------------------------------------------------------- | ------ | -------------------------------------------- |
| `JWT_SECRET`    | random string                                                 | Auth   | **Required** — replace with secure random    |
| `DATABASE_URL`  | `postgresql://postgres:postgres@db:5432/postgres`             | DB     | Postgres connection string                   |
| DB password     | strong random                                                 | DB     | Set in Postgres env + DATABASE_URL           |

## Install via Docker Compose

```yaml
services:
  web:
    image: haedlessdev/corecontrol:latest
    ports:
      - "3000:3000"
    environment:
      JWT_SECRET: CHANGE_THIS_TO_RANDOM
      DATABASE_URL: "postgresql://postgres:changeme@db:5432/postgres"

  agent:
    image: haedlessdev/corecontrol-agent:latest
    environment:
      DATABASE_URL: "postgresql://postgres:changeme@db:5432/postgres"
    depends_on:
      db:
        condition: service_healthy

  db:
    image: postgres:17
    restart: always
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: changeme
      POSTGRES_DB: postgres
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 2s
      timeout: 2s
      retries: 10

volumes:
  postgres_data:
```

Default login: `admin@example.com` / `admin` — **change immediately after first login.**

## First boot

1. Set `JWT_SECRET` and `DATABASE_URL` (with your chosen password) before starting.
2. `docker compose up -d`.
3. Visit `http://localhost:3000` → log in with default credentials → **change password**.
4. Add **Servers**: name, IP/hostname, hardware info, quick-links (e.g. Proxmox, iDRAC).
5. Add **Applications**: URL + name for uptime monitoring.
6. View **Uptime** history for monitored apps.
7. Build **Networks**: visual flowchart of your network topology.
8. Configure **Notifications** for downtime alerts.
9. Put behind TLS.

## Features overview

| Feature | Details |
|---------|---------|
| Servers | Add servers with hardware info (CPU, RAM, storage) + management panel quick-links |
| Applications | Add self-hosted apps with URL; CoreControl pings them for uptime |
| Uptime | Real-time + historical uptime tracking per app |
| Network | Visual network flowchart builder (React Flow) |
| Dashboard | Overview of server + app status |
| Notifications | Alerts for app downtime (configurable) |
| App icons | selfh.st/icons integration for service logos |

## Go agent

The `corecontrol-agent` container runs alongside the web app and collects real server hardware metrics (powered by Glances under the hood). It writes metrics directly to the shared PostgreSQL database. For multi-server monitoring, you can deploy the agent on remote servers too — see the repo docs.

## Gotchas

- **Change default credentials immediately.** Default login is `admin@example.com` / `admin` — trivially guessable. Change on first login.
- **`JWT_SECRET` is required.** If left as the placeholder, session signing is insecure. Generate a long random string (`openssl rand -hex 32`).
- **DATABASE_URL consistency.** The `DATABASE_URL` in `web`, `agent`, and `db` services must all use the same credentials. A mismatch is the most common setup error.
- **PostgreSQL 17.** CoreControl targets Postgres 17 (per upstream compose). Older versions may work but aren't tested.
- **Uptime monitoring is HTTP ping.** CoreControl polls your app URLs for HTTP 2xx responses. It's not deep health checking (no DB connectivity, no API validation) — it's availability monitoring.
- **Network flowchart is manual.** The network diagram is drawn by you — CoreControl doesn't auto-discover topology. It's a visual documentation tool, not auto-mapped.
- **Agent on remote servers.** For hardware metrics from multiple servers, deploy the agent container on each server pointing to the central PostgreSQL. See repo for multi-server setup.

## Backup

```sh
docker compose exec db pg_dump -U postgres postgres > corecontrol-$(date +%F).sql
```

## Upgrade

```sh
docker compose pull && docker compose up -d
```

## Project health

Active Next.js + Go development, Docker Hub, Glances integration, React Flow network diagrams, selfh.st icons. Solo-maintained by crocofied. MIT license.

## Homelab-dashboard-family comparison

- **CoreControl** — Next.js + Go + PostgreSQL, server inventory + app uptime + network flowchart, MIT
- **Homepage** — static config-driven dashboard, app widgets, status indicators; no server inventory
- **Dasherr / Dashy** — bookmark/app launcher dashboards; no uptime monitoring
- **Uptime Kuma** — dedicated uptime monitoring; no server inventory or network diagrams
- **Netdata** — deep per-server metrics; not a homelab inventory tool

**Choose CoreControl if:** you want one self-hosted dashboard for server inventory, app uptime monitoring, network topology diagrams, and management panel quick-links.

## Links

- Repo: <https://github.com/crocofied/CoreControl>
- Docker Hub: `haedlessdev/corecontrol`
- Discord: <https://discord.gg/gMSgHZDHyy>
