---
name: sprout-track
description: Sprout Track recipe for open-forge. Self-hosted baby activity tracker with real-time sync, growth reports, and PWA support. Based on upstream docs at https://github.com/Oak-and-Sprout/sprout-track.
---

# Sprout Track

Self-hosted Next.js application for tracking baby activities, milestones, and development. Supports sleep, feeding, diapers, medicine, growth charts, PDF report cards, push notifications, and multi-caretaker PIN-based access. Upstream: <https://github.com/Oak-and-Sprout/sprout-track>.

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Docker host (VPS, home server, Raspberry Pi) | Docker Compose | Default — single container with SQLite or optional PostgreSQL |
| Any Docker host | Docker Compose (PostgreSQL variant) | Use `docker-compose.postgres.yml` from upstream if available; set `DATABASE_PROVIDER=postgresql` |
| Local dev | `docker run` single command | Quickest trial — SQLite, ephemeral unless volume mounted |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Which database: SQLite (simpler) or PostgreSQL (multi-user production)?" | Default is SQLite; set `DATABASE_PROVIDER=sqlite` or `DATABASE_PROVIDER=postgresql` |
| preflight | "What host port should Sprout Track listen on?" | Default `3000` |
| notifications | "Enable push notifications?" | Requires `ENABLE_NOTIFICATIONS=true` and VAPID keys |
| notifications | "VAPID public key?" | Generate with `npx web-push generate-vapid-keys` |
| notifications | "VAPID private key?" | From same command |
| notifications | "Notification contact email (VAPID subject)?" | e.g. `mailto:you@example.com` |
| network | "Public URL for the app (APP_URL)?" | Required for push notification callbacks; e.g. `https://baby.example.com` |
| network | "Root domain (ROOT_DOMAIN)?" | For cookie scoping; e.g. `example.com` |

## Software-layer concerns

**Config paths / env vars** (from upstream `docker-compose.yml`):

| Variable | Default | Purpose |
|---|---|---|
| `NODE_ENV` | `production` | Runtime mode |
| `DATABASE_PROVIDER` | `sqlite` | `sqlite` or `postgresql` |
| `ENABLE_NOTIFICATIONS` | `true` | Toggle push notifications |
| `NOTIFICATION_CRON_SECRET` | _(empty)_ | Secret for cron endpoint auth |
| `NOTIFICATION_LOG_RETENTION_DAYS` | `30` | Days to keep notification logs |
| `APP_URL` | _(empty)_ | Full public URL; required for push notifications |
| `ROOT_DOMAIN` | _(empty)_ | Cookie root domain |
| `VAPID_PUBLIC_KEY` | _(empty)_ | Push notification VAPID key |
| `VAPID_PRIVATE_KEY` | _(empty)_ | Push notification VAPID private key |
| `VAPID_SUBJECT` | `mailto:notifications@sprouttrack.app` | VAPID contact |

**Data directories / volumes:**

| Volume | Purpose |
|---|---|
| `sprout-track-db` → `/db` | SQLite database file(s) |
| `sprout-track-env` → `/app/env` | App environment config |
| `sprout-track-files` → `/app/Files` | Uploaded file attachments |

**Ports:** `3000` (HTTP, configurable via `PORT` env var).

## Upgrade procedure

1. Pull the new image: `docker pull sprouttrack/sprout-track:latest`
2. Restart: `docker compose down && docker compose up -d`
3. Check logs: `docker logs sprout-track`
4. Built-in backup/restore UI covers SQLite — use it before upgrading major versions.

## Gotchas

- Push notifications require a publicly accessible `APP_URL` with HTTPS; won't work behind `localhost` only.
- VAPID keys must be generated once and persisted — regenerating them invalidates existing push subscriptions.
- Multi-family mode creates separate dashboards; each family uses its own PIN set, not a shared account.
- SQLite is suitable for personal/household use; switch to PostgreSQL if you expect heavy concurrent writes.
- The `NOTIFICATION_CRON_SECRET` must match any external cron caller that hits the notification endpoint.

## Links

- GitHub: <https://github.com/Oak-and-Sprout/sprout-track>
- Live demo: <https://www.sprout-track.com/demo>
- Docker Hub: <https://hub.docker.com/r/sprouttrack/sprout-track>
