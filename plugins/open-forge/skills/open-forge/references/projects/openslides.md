---
name: openslides
description: Recipe for OpenSlides — a free web-based presentation and assembly management system for agenda, motions, and elections. Docker Compose + manage tool.
---

# OpenSlides

Free, web-based presentation and assembly management system. Used by organisations and parliaments for managing and projecting agenda items, motions, amendments, and elections during meetings and assemblies. Microservices architecture deployed via Docker Compose with an official `openslides` manage CLI tool. Upstream: <https://github.com/OpenSlides/OpenSlides>. Website: <https://openslides.com/>.

License: MIT. Platform: Docker Compose, microservices. Stars: ~603. Actively maintained.

## Compatible install methods

| Method | When to use |
|---|---|
| Docker Compose + manage tool | Recommended and only supported method for self-hosting |
| Docker Swarm | For larger/HA deployments (not covered here) |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| domain | "Public domain name or IP for OpenSlides?" | Required for SSL and external access |
| ssl | "Use Caddy automatic HTTPS, self-signed, or bring your own cert?" | Default setup uses self-signed; production should use a real cert |
| admin | "Superadmin credentials?" | Created via `./openslides initial-data` |

## Prerequisites

- Docker 20.10+ and Docker Compose 2.13+
- The `openslides` manage binary from the manage-service releases

## Install steps

```bash
# 1. Download the openslides manage tool
wget https://github.com/OpenSlides/openslides-manage-service/releases/download/latest/openslides
chmod +x openslides

# 2. Set up instance in current directory
./openslides setup .

# 3. Review generated docker-compose.yml (customise if needed)

# 4. Pull images and start
docker compose pull
docker compose up --detach

# 5. Wait for services to be ready
./openslides check-server

# 6. Create initial data (creates superadmin account)
./openslides initial-data

# 7. Open https://localhost:8000
# Default superadmin credentials: superadmin / superadmin
```

## SSL configuration

Three options (configured in `docker-compose.yml`):

| Option | When to use |
|---|---|
| Self-signed (default) | Development/testing only; browsers will warn |
| Caddy auto-HTTPS | Production with public domain — Caddy fetches Let's Encrypt cert automatically |
| External proxy + disable SSL | When using your own nginx/Caddy in front; OpenSlides still needs HTTPS from browser |

> **Note**: OpenSlides browsers clients require HTTPS. Running without any SSL is not supported.

Full SSL docs: [INSTALL.md in the repo](https://github.com/OpenSlides/OpenSlides/blob/main/INSTALL.md)

## Software-layer concerns

| Concern | Detail |
|---|---|
| Architecture | Microservices (multiple containers) — auth, backend, frontend, datastore, media, etc. |
| Default port | `8000` (HTTPS via Caddy proxy) |
| Config | Generated `docker-compose.yml` in instance directory |
| Data | PostgreSQL and Redis services in Compose stack; persist their volumes |
| manage tool | Used for setup, initial-data, check-server, backup, and user management |
| Superadmin | Default login `superadmin` / `superadmin` — change immediately after first login |

## Upgrade procedure

```bash
# Update image tags in docker-compose.yml to new release versions, or:
docker compose pull
docker compose up --detach
```

Check the [CHANGELOG](https://github.com/OpenSlides/OpenSlides/blob/main/CHANGELOG.md) for migration notes before major version upgrades.

## Gotchas

- **HTTPS is mandatory**: The browser client requires a secure context (HTTPS) to function. No HTTP-only deployment is possible.
- **Self-signed cert warning**: The default setup generates self-signed certificates. Browsers will show a security warning. For production, configure Caddy with a real domain and automatic Let's Encrypt.
- **`openslides` manage binary must match server version**: Download the manage tool version that matches your OpenSlides server release. Mismatched versions may cause errors.
- **Multiple services**: OpenSlides is a microservices application with ~10+ containers. It requires more RAM than typical single-container apps (~2–4 GB RAM recommended for a production instance).
- **Not a video conferencing tool**: OpenSlides manages the agenda and voting for assemblies; it does not provide built-in video conferencing. Integrate with Jitsi or BigBlueButton separately if needed.
- **Initial data required**: Without running `./openslides initial-data`, there is no admin account and the application is not usable.

## Upstream links

- Source: <https://github.com/OpenSlides/OpenSlides>
- Website: <https://openslides.com/>
- Install guide: <https://github.com/OpenSlides/OpenSlides/blob/main/INSTALL.md>
- Manage tool: <https://github.com/OpenSlides/openslides-manage-service>
