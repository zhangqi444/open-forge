---
name: Timeful
description: "Open-source group scheduling and availability polling platform. Docker Compose + Caddy. Go + Vue.js + MongoDB. schej-it/timeful.app. Calendar integrations, time zones, group overlap view."
---

# Timeful

**Open-source scheduling platform to find the best time for a group to meet.** Availability polls, calendar integrations (Google, Outlook, Apple), time zone support, overlap view, email reminders, and a plugin API for browser automation. Free hosted at [timeful.app](https://timeful.app). Self-hostable via Docker Compose.

Built + maintained by the **schej / Timeful team**.

- Upstream repo: <https://github.com/schej-it/timeful.app>
- Hosted: <https://timeful.app>
- Discord: <https://discord.gg/v6raNqYxx3>
- Reddit: <https://www.reddit.com/r/schej/>

## Architecture in one minute

- **Go** backend server (port `3002`, bound to `127.0.0.1` — reverse-proxied)
- **Vue 2** frontend (built to a shared Docker volume; served by the Go backend or static server)
- **MongoDB 7** database
- Three-service Docker Compose: `mongo` + `frontend` (build) + `server` (Go API)
- **Caddy** reverse proxy on the host (recommended; handles HTTPS + headers + compression)
- Resource: **low** — Go binary + MongoDB

## Compatible install methods

| Infra              | Runtime                             | Notes                                                               |
| ------------------ | ----------------------------------- | ------------------------------------------------------------------- |
| **Docker Compose** | upstream `docker-compose.yml`       | **Primary** — Go + Vue + MongoDB; Caddy on host for TLS             |
| **Hosted**         | <https://timeful.app>               | Free, no setup; managed by the team                                 |

## Inputs to collect

| Input                            | Example                            | Phase    | Notes                                                                                      |
| -------------------------------- | ---------------------------------- | -------- | ------------------------------------------------------------------------------------------ |
| Domain                           | `meet.example.com`                 | URL      | DNS A-record → server; Caddy auto-provisions TLS                                           |
| MongoDB connection string        | `mongodb://mongo:27017/schej-it`   | Storage  | Internal Docker network; `mongo` service default                                           |
| Google Calendar OAuth (optional) | Client ID + Secret                 | Auth     | For Google Calendar integration; Google Cloud Console OAuth app                             |
| Outlook/Apple Calendar (optional)| OAuth or CalDAV                    | Auth     | See upstream docs/env template for provider-specific vars                                  |
| Admin/JWT secret                 | random string                      | Auth     | `JWT_SECRET` in `server/.env` — **required; set before first start**                       |
| Email (optional)                 | SMTP creds                         | Notify   | For email notification + reminder features                                                 |

## Deploy via Docker Compose + Caddy

```bash
# 1. Clone
git clone https://github.com/schej-it/timeful.app
cd timeful.app

# 2. Configure server env
cp server/.env.template server/.env
# Edit server/.env:
#   JWT_SECRET=<random-long-string>
#   MONGODB_URI=mongodb://mongo:27017/schej-it
#   (+ calendar OAuth creds if desired)

# 3. Build + start services
docker compose up -d --build

# 4. Set up Caddy on the host (for HTTPS)
sudo apt install caddy
sudo cp Caddyfile.example /etc/caddy/Caddyfile
# Edit /etc/caddy/Caddyfile — set your domain
sudo systemctl reload caddy
```

The Go server listens on `127.0.0.1:3002`. Caddy proxies all traffic to it, handles TLS automatically.

## Services in compose

| Service    | Role                                         | Port            |
| ---------- | -------------------------------------------- | --------------- |
| `mongo`    | MongoDB 7 database                           | Internal only   |
| `frontend` | Vue.js build step (outputs to shared volume) | N/A (build-only)|
| `server`   | Go API + serves static frontend              | `127.0.0.1:3002`|

> Note: `frontend` is a one-shot build container — it exits after building assets into the `frontend_dist` shared volume. Only `mongo` and `server` run permanently.

## First boot

1. Set `JWT_SECRET` + MongoDB URI in `server/.env` before starting.
2. `docker compose up -d --build`
3. Configure Caddy with your domain.
4. Visit `https://your-domain.com` → create your first poll.
5. Share the poll link with participants — no account required for availability entry.
6. Optionally connect calendar integrations (Google/Outlook/Apple) in Settings.
7. Test email reminders if SMTP is configured.

## Data & config layout

- `mongo_data` Docker volume — all poll data, user accounts, availability entries
- `frontend_dist` Docker volume — built Vue.js static assets
- `server_logs` Docker volume — Go server logs
- `server/.env` — secrets + config (JWT, MongoDB URI, OAuth creds)

## Backup

```bash
# Backup MongoDB
docker compose exec mongo mongodump \
  --db=schej-it --archive=/data/db/backup.archive
docker compose cp mongo:/data/db/backup.archive \
  ./timeful-backup-$(date +%F).archive

# Restore
docker compose cp ./timeful-backup.archive mongo:/data/db/backup.archive
docker compose exec mongo mongorestore \
  --drop --db=schej-it --archive=/data/db/backup.archive
```

Contents: all polls, availability responses, user calendar tokens. Calendar OAuth tokens = access to users' calendars — treat as high-sensitivity secrets.

## Upgrade

1. Releases: <https://github.com/schej-it/timeful.app/releases>
2. `git pull && docker compose up -d --build`

## Gotchas

- **`JWT_SECRET` must be set before first start.** It's used to sign session tokens. If you start without it (or with the default placeholder), all sessions will be invalid. It can't easily be rotated later without logging everyone out.
- **`frontend` service exits on purpose.** It's a build step, not a long-running service. `docker compose ps` showing it as "exited" is expected behavior — not a crash.
- **Caddy on the host, not in Docker.** Upstream DEPLOYMENT.md uses Caddy installed directly on the host machine, not a Docker container. If you prefer nginx or a proxy container, adapt the Caddyfile to your setup — but ensure HTTP → HTTPS redirect and correct proxy headers (`X-Forwarded-For`, etc.).
- **Google Calendar OAuth requires a Google Cloud project.** Create an OAuth 2.0 app at [console.cloud.google.com](https://console.cloud.google.com), set redirect URI to `https://your-domain.com/auth/callback`. Without this, Google Calendar integration is unavailable.
- **Calendar tokens are stored in MongoDB.** Users who connect their Google/Outlook calendars grant Timeful OAuth access. These tokens are sensitive — MongoDB backup = calendar access tokens. Restrict MongoDB access accordingly.
- **Vue 2 frontend.** Vue 2 is end-of-life (December 2023). The app still works, but this is a tech debt flag — migration to Vue 3 may be in the roadmap.
- **Availability groups** — a real-time feature showing live calendar availability of a saved group of people. Requires participants to connect their calendars and share; more powerful than one-off polls.
- **Plugin API** — browser extensions can get/set availability on Timeful events programmatically. See `PLUGIN_API_README.md`. Useful for building automation (e.g., auto-fill availability from a custom calendar source).
- **`docker compose down -v` deletes all data.** The DEPLOYMENT.md explicitly warns about this. Never run `-v` in production unless you intend to wipe everything.

## Project health

Active Go + Vue development, hosted product at timeful.app, Discord, Reddit community. Multi-contributor team. AGPL license.

## Group-scheduling-family comparison

- **Timeful** — self-hostable, calendar integrations, time zones, plugin API, AGPL
- **When2meet** — minimalist SaaS, no calendar integration, very fast; widely used
- **Lettucemeet** — SaaS, slightly nicer UI than When2meet, no self-host
- **Doodle** — SaaS, date/option polling (not time-grid), free tier has ads
- **Cal.com** — full scheduling platform (1:1 booking + team scheduling), much heavier

**Choose Timeful if:** you want a self-hosted When2meet equivalent with proper calendar integrations (Google/Outlook/Apple), time-zone support, and an automation plugin API.

## Links

- Repo: <https://github.com/schej-it/timeful.app>
- Hosted version: <https://timeful.app>
- Deployment guide: <https://github.com/schej-it/timeful.app/blob/main/DEPLOYMENT.md>
- Plugin API: <https://github.com/schej-it/timeful.app/blob/main/PLUGIN_API_README.md>
- Cal.com (full scheduling alt): <https://cal.com>
