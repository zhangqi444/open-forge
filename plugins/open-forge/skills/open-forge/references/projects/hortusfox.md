---
name: HortusFox
description: "Self-hosted collaborative plant management system. Docker. PHP + MariaDB. danielbrendel/hortusfox-web. Tasks, inventory, calendar, weather, plant ID, group chat, history log."
---

# HortusFox

**Self-hosted collaborative plant management system.** Track all your plants with details, photos, and custom locations. Dashboard, warning system for plants needing care, task management, inventory, calendar, group chat, history log, weather widget, plant identification (AI), plant info lookup, search, themes, reminders, and admin dashboard. Multi-user collaborative — manage your plants with your household.

Built + maintained by **Daniel Brendel**.

- Upstream repo: <https://github.com/danielbrendel/hortusfox-web>
- Website: <https://www.hortusfox.com>
- FAQ: <https://www.hortusfox.com/faq>
- Discord: <https://discord.gg/kc6xGmjzVS>
- Support: <https://www.hortusfox.com/support>

## Architecture in one minute

- **PHP** web app (Artisan/Laravel-style)
- **MariaDB** database (separate container)
- Docker Compose stack: `app` + `db` + optional `cron`
- Port: **80** inside container (map to your host port)
- Resource: **low** — PHP + MariaDB; typical home-use scale

## Compatible install methods

| Infra              | Runtime                       | Notes                                                              |
| ------------------ | ----------------------------- | ------------------------------------------------------------------ |
| **Docker Compose** | upstream `docker-compose.yml` | **Primary** — clone + set env + `docker compose up -d`            |
| **Installer**      | shell installer script        | For bare-metal PHP hosting                                         |
| **Manual**         | PHP + MariaDB + webserver     | Full manual; see docs                                              |
| **AquaShell**      | AquaShell deploy              | Alternative; see README                                            |

## Inputs to collect

| Input                           | Example                           | Phase    | Notes                                                                         |
| ------------------------------- | --------------------------------- | -------- | ----------------------------------------------------------------------------- |
| Admin email + password          | `admin@example.com` / `password`  | Auth     | `APP_ADMIN_EMAIL` + `APP_ADMIN_PASSWORD` in `docker-compose.yml` environment |
| Timezone                        | `America/New_York`                | Config   | `APP_TIMEZONE` env — default UTC                                              |
| Domain                          | `plants.example.com`              | URL      | Reverse proxy + TLS                                                           |
| MariaDB password                | strong random                     | Storage  | Set in compose env for DB container + app                                     |
| Weather API key (optional)      | OpenWeatherMap key                | Feature  | For the weather widget                                                        |
| Plant ID API key (optional)     | pl@ntnet or similar               | Feature  | For AI plant identification feature                                           |

## Install via Docker

```bash
git clone https://github.com/danielbrendel/hortusfox-web.git
cd hortusfox-web

# Edit docker-compose.yml — set:
#   APP_ADMIN_EMAIL, APP_ADMIN_PASSWORD, APP_TIMEZONE
#   DB_PASSWORD (match in both app + db service)
#   (optional) weather/plant-ID API keys

docker compose up -d
```

Visit `http://<host>:80` (or your mapped port).

Key env vars to set in `docker-compose.yml`:

```yaml
environment:
  APP_ADMIN_EMAIL: "admin@example.com"
  APP_ADMIN_PASSWORD: "your-strong-password"
  APP_TIMEZONE: "America/New_York"
  APP_UPDATEDEPS: "false"    # set true to auto-update composer deps on start
```

## First boot

1. Set admin credentials + timezone in compose env.
2. `docker compose up -d` — wait for DB init (may take 30s).
3. Visit the web UI → log in with your admin email + password.
4. Create **locations** (rooms, garden zones, etc.) in Settings.
5. Add your first **plant** with photo, watering schedule, and location.
6. Configure the **warning system** (which conditions trigger alerts).
7. Add other household users for collaborative management.
8. Set up **reminders** if desired.
9. Optionally configure weather + plant-ID APIs in Settings.
10. Put behind TLS.

## Features overview

| Feature | Details |
|---------|---------|
| Plant management | Add plants with name, species, photos, care notes, watering/light/humidity requirements |
| Locations | Assign plants to custom rooms/zones (kitchen, balcony, garden...) |
| Dashboard | Overview: total plants, warnings, tasks, recent activity |
| Warning system | Flags plants needing care based on schedule/conditions |
| Tasks | To-do list linked to plants or general gardening tasks |
| Inventory | Track pots, soil, fertilizers, and other supplies |
| Calendar | View care events and tasks on a calendar |
| Group chat | Real-time chat for collaborative households |
| History log | Track all actions taken by all users |
| Search | Find plants by name, species, location |
| Weather | Widget showing local weather (requires API key) |
| Plant ID | AI-powered plant identification from photo (requires API key) |
| Plant info | Look up care info for a species |
| Themes | Multiple visual themes |
| Reminders | Time-based notifications for care tasks |
| Admin dashboard | User management, system settings |

## Data & config layout

- MariaDB volume — all plant data, users, tasks, inventory, history
- App uploads volume — plant photos

## Backup

```sh
docker compose exec db mysqldump -u root -p hortusfox > hortusfox-$(date +%F).sql
# Also back up the uploads volume (photos)
sudo tar czf hortusfox-uploads-$(date +%F).tgz <uploads-volume-path>/
```

## Upgrade

1. `git pull && docker compose pull && docker compose up -d --build`
2. Or set `APP_UPDATEDEPS: "true"` to auto-run composer updates on container start.

## Gotchas

- **`APP_ADMIN_EMAIL` / `APP_ADMIN_PASSWORD` set on first run.** These create the admin account during initial DB seeding. Changing them in the compose file after the DB is initialized has no effect — use the web UI to update credentials.
- **`APP_UPDATEDEPS: "true"` slows startup.** It runs `composer update` every time the container starts. Useful for dev; disable in production for faster restarts (`APP_UPDATEDEPS: "false"`).
- **Weather feature requires OpenWeatherMap (or compatible) API key.** Without it, the weather widget shows nothing. Free tier of OpenWeatherMap is sufficient for personal use.
- **Plant ID feature requires an external AI API.** Pl@ntNet or similar — check current docs/settings for the supported provider. This is an optional nice-to-have, not required for core functionality.
- **MariaDB, not MySQL.** The stack uses MariaDB specifically — use the MariaDB Docker image, not the MySQL one, to avoid subtle compatibility issues.
- **Cron container for scheduled tasks.** Some features (reminders, scheduled notifications) require the cron service to be running. Check the compose file for a `cron` service and ensure it's included.
- **Photo uploads need a persistent volume.** Plant photos are stored in the app container's upload dir — map it to a named volume or host path or photos disappear on container recreate.
- **Multi-user is for a household, not the public internet.** User registration may be open by default — configure in admin settings to require admin approval, or close registration after creating household accounts.

## Project health

Active PHP development, Docker support, Discord, website, FAQ, sponsorship (GitHub + Ko-fi). Solo-maintained by Daniel Brendel. MIT license.

## Plant-tracker-family comparison

- **HortusFox** — PHP + MariaDB, Docker, full-featured (tasks/inventory/calendar/chat/history/plant-ID)
- **OpenPlantBook** — API/database project, not an app; data source for plant care info
- **Planta** — SaaS iOS/Android app; polished, not self-hosted
- **Greg** — SaaS plant care reminder app; not self-hosted

**Choose HortusFox if:** you want a self-hosted, multi-user household plant manager with tasks, inventory, calendar, group chat, and optional AI plant identification.

## Links

- Repo: <https://github.com/danielbrendel/hortusfox-web>
- Website: <https://www.hortusfox.com>
- Discord: <https://discord.gg/kc6xGmjzVS>
