---
name: Traggo
description: "Tag-based time tracking tool. Docker. Go. traggo/server. No tasks — only tagged time spans. Customizable dashboards, calendar view, multi-user, self-hosted."
---

# Traggo

**Tag-based time tracking tool.** In Traggo there are no "tasks" — only tagged time spans. Tags are fully customizable: add a `project` tag, a `type` tag (email/programming/meeting), or anything else. Customizable dashboards with diagrams, list + calendar views, multiple themes, simple user management. Self-hosted only — you own the data.

Built + maintained by **the traggo team**.

- Upstream repo: <https://github.com/traggo/server>
- Website + docs: <https://traggo.net>
- Install guide: <https://traggo.net/install/>
- Config reference: <https://traggo.net/config/>
- Docker Hub: <https://hub.docker.com/r/traggo/server>

## Architecture in one minute

- **Go** backend + web UI
- Port **3030** (default)
- SQLite database (stored in `/opt/traggo/data/`)
- Single binary / single container
- Resource: **tiny** — Go binary, SQLite, minimal RAM

## Compatible install methods

| Infra       | Runtime             | Notes                                              |
| ----------- | ------------------- | -------------------------------------------------- |
| **Docker**  | `traggo/server`     | **Primary** — one-liner or compose                 |

## Inputs to collect

| Input                          | Example                    | Phase    | Notes                                                                          |
| ------------------------------ | -------------------------- | -------- | ------------------------------------------------------------------------------ |
| Admin username                 | `admin`                    | Auth     | `TRAGGO_DEFAULT_USER_NAME` env (created on first start if no DB exists)        |
| Admin password                 | strong password            | Auth     | `TRAGGO_DEFAULT_USER_PASS` env — **change this from the default immediately**  |
| Domain                         | `time.example.com`         | URL      | Reverse proxy + TLS                                                            |
| Port                           | `3030`                     | Network  | Default; override with `TRAGGO_PORT` if needed                                 |

## Install via Docker

```yaml
services:
  traggo:
    image: traggo/server:latest
    container_name: traggo
    ports:
      - "3030:3030"
    volumes:
      - ./traggo-data:/opt/traggo/data
    environment:
      - TRAGGO_DEFAULT_USER_NAME=admin
      - TRAGGO_DEFAULT_USER_PASS=changeme   # CHANGE THIS
    restart: unless-stopped
```

```sh
docker compose up -d
```

Visit `http://<host>:3030`.

## First boot

1. Deploy container with `TRAGGO_DEFAULT_USER_NAME` + `TRAGGO_DEFAULT_USER_PASS` set.
2. Log in → **immediately change the password** in Settings → User.
3. Define your **tags** in Settings → Tags (e.g. `project`, `type`, `client`).
4. Start logging time spans — click + drag in the calendar, or use the list entry form.
5. Create **dashboards** with diagrams (pie, bar, totals) filtered by tags.
6. Add additional users if needed (Admin → Users).
7. Put behind TLS.
8. Back up `./traggo-data/`.

## Configuration

Full config reference: <https://traggo.net/config/>. Key env vars:

| Env var                    | Default   | Effect                                          |
| -------------------------- | --------- | ----------------------------------------------- |
| `TRAGGO_DEFAULT_USER_NAME` | —         | Admin username created on first run             |
| `TRAGGO_DEFAULT_USER_PASS` | —         | Admin password created on first run             |
| `TRAGGO_PORT`              | `3030`    | Listen port                                     |
| `TRAGGO_LOG_LEVEL`         | `info`    | `debug` / `info` / `warn`                       |
| `TRAGGO_DATABASE_TYPE`     | `sqlite3` | DB engine                                       |
| `TRAGGO_DATABASE_CONNECTION` | auto    | Connection string for non-SQLite DB             |

## Data & config layout

- `./traggo-data/` → `/opt/traggo/data/` — SQLite DB + any Traggo state

## Backup

```sh
docker compose stop traggo
sudo cp -a traggo-data/ traggo-data-backup-$(date +%F)/
docker compose start traggo
```

Contents: all time tracking data — time spans, tags, dashboards, users. Minimal PII but potentially sensitive (reveals work patterns, client names, etc.).

## Upgrade

1. Releases: <https://github.com/traggo/server/releases>
2. `docker compose pull && docker compose up -d`

## Gotchas

- **`TRAGGO_DEFAULT_USER_*` only runs once.** These env vars create the admin user on first start when no DB exists. If you change them later, nothing happens — the DB already has the user. To reset, delete the data dir (loses all data) or change the password via the UI.
- **Tags are the core model.** Unlike Toggl/Clockify where you track against projects/clients directly, Traggo gives you blank tags — you define their meaning. Set them up thoughtfully upfront; renaming tag keys later is possible but can be confusing with historical data.
- **No mobile app.** Web UI only (responsive, works on mobile browser, but no native app). For on-the-go time tracking, use the browser.
- **No integrations/webhooks built-in.** Traggo is a self-contained tracker — no Jira sync, no GitHub issue integration, no calendar import. It's deliberately minimal.
- **Multi-user but not multi-tenant.** Users see only their own time spans. No shared project views, no manager-seeing-team-reports. If you need team-level reporting, look at Kimai.
- **SQLite by default.** Fine for personal or small-team use; the config supports other DB engines if needed.
- **Calendar UI looks like Google Calendar.** Drag to create time spans, click to edit. Very intuitive for people familiar with calendar-based time tracking.

## Project health

Active, SemVer versioned, Docker Hub, docs site. Go binary. Maintained by traggo team.

## Time-tracking-family comparison

- **Traggo** — tag-first, no tasks, Docker, Go, calendar UI, self-hosted
- **Kimai** — PHP, multi-user/team reports, invoicing, more complex, actively developed
- **Solidtime** — newer Laravel alternative to Kimai, modern UI
- **Timetagger** — Python, self-hosted, tag-based similar philosophy
- **Toggl / Clockify** — SaaS, polished, integrations; not self-hosted

**Choose Traggo if:** you want tag-based self-hosted time tracking with a calendar UI and minimal complexity, and don't need team-level reporting or invoicing.

## Links

- Repo: <https://github.com/traggo/server>
- Docs: <https://traggo.net>
- Install guide: <https://traggo.net/install/>
- Kimai (team-tracking alt): <https://www.kimai.org>
