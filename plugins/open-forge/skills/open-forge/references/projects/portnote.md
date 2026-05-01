---
name: PortNote
description: "Self-hosted port documentation and conflict-prevention tool. Docker. Next.js + Go agent + PostgreSQL. crocofied/PortNote. Track port assignments across servers, avoid conflicts, random port generator."
---

# PortNote

**Self-hosted port management and documentation tool.** Stop guessing which service uses which port. Add your servers and VMs; assign and document port usage across your entire infrastructure; detect and prevent conflicts before they happen. Includes a random port generator for picking safe unassigned ports. Built by the author of CoreControl.

Built + maintained by **crocofied**. MIT license.

- Upstream repo: <https://github.com/crocofied/PortNote>
- Docker Hub: `haedlessdev/portnote` / `haedlessdev/portnote-agent`

## Architecture in one minute

- **Next.js + TypeScript** web UI
- **Go** agent (collects port data from servers)
- **PostgreSQL 17** database (Prisma ORM)
- Docker Compose: `web` + `agent` + `db` containers
- Port **3000** (web UI)
- Resource: **low** — Next.js + Go + PostgreSQL

## Compatible install methods

| Infra              | Runtime                      | Notes                         |
| ------------------ | ---------------------------- | ----------------------------- |
| **Docker Compose** | `haedlessdev/portnote`       | **Primary** — includes all three services |

## Inputs to collect

| Input              | Example                                               | Phase  | Notes                                       |
| ------------------ | ----------------------------------------------------- | ------ | ------------------------------------------- |
| `JWT_SECRET`       | random string                                         | Auth   | **Required** — replace with secure random   |
| `USER_SECRET`      | random string                                         | Auth   | **Required** — replace with secure random   |
| `LOGIN_USERNAME`   | your username                                         | Auth   | Admin login username                        |
| `LOGIN_PASSWORD`   | strong password                                       | Auth   | **Change from default**                     |
| `DATABASE_URL`     | `postgresql://postgres:changeme@db:5432/postgres`     | DB     | Postgres connection string                  |

## Install via Docker Compose

```yaml
services:
  web:
    image: haedlessdev/portnote:latest
    ports:
      - "3000:3000"
    environment:
      JWT_SECRET: CHANGE_THIS_TO_RANDOM
      USER_SECRET: CHANGE_THIS_TO_RANDOM
      LOGIN_USERNAME: admin
      LOGIN_PASSWORD: changeme
      DATABASE_URL: "postgresql://postgres:changeme@db:5432/postgres"
    depends_on:
      db:
        condition: service_started

  agent:
    image: haedlessdev/portnote-agent:latest
    environment:
      DATABASE_URL: "postgresql://postgres:changeme@db:5432/postgres"
    depends_on:
      db:
        condition: service_started

  db:
    image: postgres:17
    restart: always
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: changeme
      POSTGRES_DB: postgres
    volumes:
      - postgres_data:/var/lib/postgresql/data

volumes:
  postgres_data:
```

Visit `http://localhost:3000`.

## First boot

1. Set all secrets and credentials before starting.
2. `docker compose up -d`.
3. Visit `http://localhost:3000` → log in with your configured credentials.
4. Add **servers/VMs** to your infrastructure inventory.
5. Add **port assignments** per server (port number, protocol, service name, notes).
6. Use the **random port generator** to find a free port when deploying a new service.
7. Put behind TLS.

## Features overview

| Feature | Details |
|---------|---------|
| Server inventory | Add all servers + VMs with metadata |
| Port assignments | Document which ports are in use on each server |
| Conflict detection | Visual overview to spot port conflicts before they happen |
| Random port generator | Generate a random unassigned port for new services |
| Dashboard | Overview of your entire port landscape |
| Search | Find which server/service uses a given port |

## Gotchas

- **Change all secrets and credentials before first run.** `JWT_SECRET`, `USER_SECRET`, `LOGIN_PASSWORD` — all have placeholder values in the example. Deploying with defaults is a security risk.
- **DATABASE_URL in web and agent must match.** Both the `web` and `agent` services connect to the same PostgreSQL instance — ensure credentials are consistent across all three services.
- **This is documentation, not enforcement.** PortNote tracks port assignments as documentation — it doesn't actually block or detect port conflicts at the network level. It's a knowledge base / planning tool, not a firewall rule manager.
- **Same author as CoreControl.** If you're already using CoreControl (server + uptime management), PortNote is a complementary tool from the same developer. They share the same visual style and tech stack.

## Backup

```sh
docker compose exec db pg_dump -U postgres postgres > portnote-$(date +%F).sql
```

## Upgrade

```sh
docker compose pull && docker compose up -d
```

## Project health

Active Next.js + Go development, Docker Hub. Solo-maintained by crocofied. MIT license.

## Port-tracking-family comparison

- **PortNote** — Next.js+Go+PostgreSQL, port inventory + conflict prevention, random generator, MIT
- **Netbox** — Python+Django, full DCIM/IPAM with port/service tracking; much heavier; enterprise scope
- **phpIPAM** — PHP, IP address management with service tracking; no port-specific focus
- **Spreadsheet** — the zero-cost alternative everyone actually uses; PortNote beats it on searchability

**Choose PortNote if:** you manage multiple servers and want a dedicated web UI for documenting port assignments and preventing conflicts — without the complexity of full DCIM tools.

## Links

- Repo: <https://github.com/crocofied/PortNote>
- Docker Hub: `haedlessdev/portnote`
