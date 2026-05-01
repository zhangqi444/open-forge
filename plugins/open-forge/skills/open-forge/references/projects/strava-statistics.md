---
name: Statistics for Strava
description: "Self-hosted open-source dashboard for your Strava data. Docker. PHP/Symfony. robiningelbrecht/statistics-for-strava. Dashboard + activities + gear + Eddington + heatmap + AI assistant."
---

# Statistics for Strava

**Self-hosted, open-source dashboard for your Strava data.** Pulls your activities from the Strava API, stores them in SQLite, and renders a rich dashboard — stats, monthly calendar, gear wear-tracking, Eddington number, segment efforts, heatmaps, milestones, a yearly Rewind, challenges, activity photos, AI workout assistant, shareable user badges, and PWA support.

Built + maintained by **Robin Ingelbrecht**. Sponsored by Blackfire.io. Not affiliated with Strava.

- Upstream repo: <https://github.com/robiningelbrecht/statistics-for-strava>
- Docs: <https://statistics-for-strava-docs.robiningelbrecht.be>
- Docker Hub: <https://hub.docker.com/r/robiningelbrecht/strava-statistics>
- Discord: <https://discord.gg/p4zpZyCHNc>

## Architecture in one minute

- **PHP 8.x / Symfony** app + **SQLite** DB + a long-running **daemon** container for scheduled imports
- Serves on port **8080** (HTTP); upstream example maps `8081:8080`
- Caddy embedded for app runtime (metrics endpoint on `:2019`)
- Strava OAuth → stores tokens + activity data in `./storage/database/strava.db`
- Files (photos, etc.) in `./storage/files/`

## Compatible install methods

| Infra              | Runtime                                         | Notes                                                       |
| ------------------ | ----------------------------------------------- | ----------------------------------------------------------- |
| **Docker**         | `robiningelbrecht/strava-statistics`            | **Primary** — upstream-blessed. See docs site for full env. |

## Inputs to collect

| Input                      | Example                               | Phase    | Notes                                                                                  |
| -------------------------- | ------------------------------------- | -------- | -------------------------------------------------------------------------------------- |
| Domain                     | `strava.example.com`                  | URL      | Front with reverse proxy + TLS                                                         |
| Strava API app             | Client ID + Client Secret             | Auth     | Create at <https://www.strava.com/settings/api> — callback `http://localhost`          |
| Strava athlete ID          | numeric (`12345678`)                  | Auth     | Shown in your Strava profile URL                                                       |
| Strava refresh token       | long string                           | Auth     | Bootstrap via docs; stored in `.env.local`                                             |
| Timezone                   | `Europe/Brussels` / `America/Denver`  | Config   | `TZ=` env — app default is `Europe/Brussels`                                           |
| AI provider (optional)     | OpenAI API key                        | Config   | For the AI workout assistant                                                           |

## Install via Docker

Per docs.statistics-for-strava (getting started / Docker):

1. Clone the repo (the compose file builds two services from local `docker/` dirs — the **app** and the long-running **daemon**):

   ```sh
   git clone https://github.com/robiningelbrecht/statistics-for-strava.git
   cd statistics-for-strava
   ```

2. Copy `.env` → `.env.local` and fill in the Strava OAuth + athlete details per the docs.

3. Build + start:

   ```sh
   docker compose up -d --build app daemon
   ```

   (The `php-cli` service is `profiles: [on-demand]` — only runs when invoked explicitly, e.g. `docker compose run --rm php-cli …` for one-off commands.)

4. First run — import activities:

   ```sh
   docker compose run --rm php-cli bin/console app:strava:import-activities
   docker compose run --rm php-cli bin/console app:strava:build-files
   ```

5. Visit `http://<host>:8081` (host port from compose).

**Production Docker Hub image** (alternative to building from source) — pull `robiningelbrecht/strava-statistics:latest` and mount the same volumes. See Docker Hub page for the exact compose snippet.

## First boot

1. Create a Strava API app at <https://www.strava.com/settings/api>; callback `http://localhost`.
2. Get refresh token (docs walk through the OAuth exchange).
3. Populate `.env.local` with `CLIENT_ID`, `CLIENT_SECRET`, `ATHLETE_ID`, `STRAVA_REFRESH_TOKEN`.
4. Start stack → run the import console command → browse dashboard.
5. Schedule re-imports — the **daemon** container handles this continuously (runs `bin/console app:daemon:run` as entrypoint).
6. Put behind TLS.
7. Back up `./storage/` (DB + files + gear-maintenance state).

## Data & config layout

- `./config/app/` — app config overrides
- `./storage/database/strava.db` — SQLite (all activities, gear, segments)
- `./storage/files/` — activity photos + generated assets
- `./storage/gear-maintenance/` — maintenance tracking state
- `./build/` — generated HTML output

## Backup

```sh
# Stop daemon so DB isn't mid-write
docker compose stop daemon
sudo tar czf strava-stats-$(date +%F).tgz storage/ config/ .env.local
docker compose start daemon
```

Contents: **full Strava activity history + GPS traces + photos** — geo-sensitive; treat as PII.

## Upgrade

1. Releases: <https://github.com/robiningelbrecht/statistics-for-strava/releases>
2. `git pull && docker compose build --pull && docker compose up -d app daemon`

## Gotchas

- **Strava API rate limits** — 100 req/15min, 1000/day per app. First full import of a multi-year athlete can span multiple windows; the daemon handles this with backoff but don't panic if the first sync takes hours.
- **Strava API app callback must be `http://localhost`** during creation — OAuth refresh-token exchange is done one-time via the docs flow; no production callback needed since the app uses refresh tokens forever after.
- **Timezone default is `Europe/Brussels`** — upstream's timezone (Belgian maintainer). Set `TZ=` in `.env.local` and the compose `environment:` block to your own or monthly-view boundaries shift.
- **Two long-running services** — `app` (web UI) and `daemon` (scheduled refreshes). Both must be up for the dashboard to stay current; stopping `daemon` freezes imports but the web UI keeps serving stale data.
- **`php-cli` profile** — `profiles: [on-demand]` means `docker compose up` won't start it; use `docker compose run --rm php-cli …` for console commands (import, build-files, rebuild-indexes).
- **DB healthcheck is file-existence** — the `daemon` healthcheck just checks `strava.db` exists; it'll report healthy even if imports are stalled. Monitor `docker compose logs daemon` for real status.
- **GPS-data-sensitivity** — your ride/run traces reveal home address, workplace, routines. Back up encrypted; if publishing heatmap/badges, strip start/end buffers (upstream has a privacy-zone feature — configure it).
- **AI assistant requires OpenAI key** — optional feature; if enabled, activity titles/descriptions get sent to OpenAI. Off by default.
- **`.env.local` has the refresh token** — full API access to your Strava account. Treat it like a password; rotate by revoking the API app and re-issuing.
- **Monorepo Docker build** — first `docker compose up` builds two images (app + daemon) from `./docker/app/Dockerfile`; expect a ~5-min initial build. Use the Docker Hub prebuilt image if you want to skip.

## Project health

Active development, Docker CI, docs site, Discord, sponsored by Blackfire.io. Solo-maintained by Robin Ingelbrecht.

## Links

- Repo: <https://github.com/robiningelbrecht/statistics-for-strava>
- Docs: <https://statistics-for-strava-docs.robiningelbrecht.be>
- Strava API: <https://developers.strava.com>
- Alt (generic-dashboarding): **Grafana** if you want full control over panels and have the ingestion pipeline to build yourself.
