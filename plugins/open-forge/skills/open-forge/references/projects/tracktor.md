---
name: Tracktor
description: "Self-hosted vehicle management web app. Docker. SvelteKit + SQLite. javedh-dev/tracktor. Track fuel consumption, maintenance logs, insurance, regulatory documents, and set reminders for all your vehicles. ⚠️ Under active development — not yet stable for production. MIT."
---

# Tracktor

**Self-hosted vehicle management app.** Track fuel refills and consumption, maintenance history, insurance and regulatory documents, and set reminders — all for multiple vehicles in one place. Dashboard with key metrics, analytics, and upcoming renewal alerts. Built with SvelteKit and SQLite.

> ⚠️ **Under active development.** Tracktor may have frequent breaking changes and is **not yet stable for production use**. Keep regular backups.

Built + maintained by **javedh-dev** (Javed Hasan). MIT.

- Upstream repo: <https://github.com/javedh-dev/tracktor>
- GHCR: `ghcr.io/javedh-dev/tracktor`
- Live demo: <https://tracktor.bytedge.in>

## Architecture in one minute

- **SvelteKit** (Svelte 5 + Tailwind CSS) — frontend + server routes
- **SQLite** with Drizzle ORM — built-in file-based database; no external DB needed
- Port **3000** (internal), mapped to **3333** by default
- Data persisted in `/data` volume
- Resource: **very low** — lightweight Node.js app with SQLite

## Compatible install methods

| Infra      | Runtime                          | Notes                                         |
| ---------- | -------------------------------- | --------------------------------------------- |
| **Docker** | `ghcr.io/javedh-dev/tracktor`    | **Primary** — single container, SQLite built-in |

## Install via Docker Compose

```yaml
services:
  app:
    image: ghcr.io/javedh-dev/tracktor:latest
    container_name: tracktor-app
    restart: always
    ports:
      - '3333:3000'
    volumes:
      - tracktor-data:/data    # Database and uploads stored here
    environment:
      - TRACKTOR_DEMO_MODE=false
      - FORCE_DATA_SEED=false
      - CORS_ORIGINS="http://localhost:3000"   # Adjust to your public URL

volumes:
  tracktor-data:
    name: tracktor-data
```

```bash
docker compose up -d
```

Visit `http://your-server:3333`.

## Environment variables

| Variable | Default | Notes |
|----------|---------|-------|
| `TRACKTOR_DEMO_MODE` | `false` | Enable demo mode (pre-populated data, no auth) |
| `FORCE_DATA_SEED` | `false` | Force seed database with demo data on startup |
| `CORS_ORIGINS` | — | Allowed CORS origins (e.g. your app's public URL) |

See [environment docs](https://github.com/javedh-dev/tracktor/blob/main/docs/environment.md) for full variable list.

## Features overview

| Feature | Details |
|---------|---------|
| Multiple vehicles | Add and manage any number of vehicles with different fuel types |
| Fuel tracking | Log refills, monitor fuel efficiency over time |
| Maintenance log | Record and view service/maintenance history per vehicle |
| Document tracking | Track insurance + pollution certificates with renewal dates |
| Reminders | Set alerts for maintenance, renewals, and other events |
| Dashboard | Metrics, analytics, and upcoming renewals at a glance |
| User authentication | Username/password with session management |
| Feature toggles | Enable/disable specific features via config |

## Gotchas

- **⚠️ Not stable for production.** Tracktor is under active development with potential breaking changes. Use a specific version tag (e.g. `ghcr.io/javedh-dev/tracktor:v0.x.x`) rather than `latest` if you need stability, and keep backups.
- **CORS_ORIGINS.** Set this to the URL you use to access Tracktor, otherwise browser requests from other origins will be blocked.
- **SQLite.** All data is stored in the `/data` volume. Back it up before upgrading.
- **MIT license.** Free for commercial and personal use.

## Backup

```sh
# All data is in the tracktor-data volume
docker run --rm -v tracktor-data:/data -v $(pwd):/backup alpine \
  tar czf /backup/tracktor-data-$(date +%F).tar.gz /data
```

## Upgrade

```sh
docker compose down
docker compose pull
docker compose up -d --force-recreate
```

## Project health

Active SvelteKit development, MIT license, pre-1.0 / under heavy development.

## Vehicle-tracking-family comparison

- **Tracktor** — SvelteKit/SQLite, fuel + maintenance + documents + reminders, MIT
- **Lubelogger** — PHP/SQLite, vehicle maintenance log, web UI; MIT
- **Car Maintenance Tracker** — Various open-source options; check GitHub

**Choose Tracktor if:** you want a modern self-hosted vehicle dashboard for tracking fuel, maintenance, insurance documents, and reminders — and you're comfortable with pre-production software.

## Links

- Repo: <https://github.com/javedh-dev/tracktor>
- GHCR: <https://github.com/javedh-dev/tracktor/pkgs/container/tracktor>
- Install guide: <https://github.com/javedh-dev/tracktor/blob/main/docs/installation.md>
- Live demo: <https://tracktor.bytedge.in>
