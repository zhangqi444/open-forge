---
name: statistics-for-strava
description: Statistics for Strava recipe for open-forge. Self-hosted Strava statistics dashboard. Based on upstream docs at https://statistics-for-strava-docs.robiningelbrecht.be
---

# Statistics for Strava

Self-hosted, open-source statistics dashboard for your Strava data. Upstream: <https://github.com/robiningelbrecht/statistics-for-strava>. Docs: <https://statistics-for-strava-docs.robiningelbrecht.be>

> ⚠️ **Requires Strava API access.** This app connects to the Strava API using your personal API key. Strava rate limits apply. The app is not affiliated with Strava.

Features: dashboard, activity list, monthly view, gear stats, maintenance tracking, Eddington number, heatmap, segments, milestones, Strava Rewind, challenges, activity photos, AI workout assistant, PWA support.

Current release: v4.7.8 (April 2026). Active development.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose | <https://statistics-for-strava-docs.robiningelbrecht.be> | ✅ | Recommended path — officially supported |

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| strava | "Strava API Client ID?" | Free-text | Required — from Strava API settings |
| strava | "Strava API Client Secret?" | Free-text (sensitive) | Required |
| strava | "Strava Athlete ID?" | Free-text | Required — your numeric Strava user ID |
| network | "Domain or port for the dashboard?" | Free-text | All |
| timezone | "Your timezone (e.g. Europe/Brussels)?" | Free-text | Sets TZ env var |

### How to get Strava API credentials

1. Go to <https://www.strava.com/settings/api>
2. Create an app — set "Authorization Callback Domain" to `localhost` for local use, or your domain for self-hosted
3. Note the **Client ID** and **Client Secret**
4. Your **Athlete ID** appears in your Strava profile URL: `https://www.strava.com/athletes/<ID>`

## Software-layer concerns

**Services (Docker Compose):**
- `app` — PHP application server (port 8080)
- `daemon` — background sync worker

**Config paths:**
- `.env.local` — app configuration (Strava credentials, TZ, etc.)

**Data dirs:**
- `config/app/` — app config files
- `build/` — compiled assets
- `storage/database/` — SQLite database
- `storage/files/` — cached activity files
- `storage/gear-maintenance/` — gear maintenance data

## Install — Docker Compose

> **Source:** <https://statistics-for-strava-docs.robiningelbrecht.be>

```bash
# 1. Create project directory
mkdir statistics-for-strava && cd statistics-for-strava

# 2. Download docker-compose.yml from upstream
curl -O https://raw.githubusercontent.com/robiningelbrecht/statistics-for-strava/master/docker-compose.yml

# 3. Create .env.local with your Strava credentials
cat > .env.local << EOL
STRAVA_CLIENT_ID=<your_client_id>
STRAVA_CLIENT_SECRET=<your_client_secret>
STRAVA_ATHLETE_ID=<your_athlete_id>
TZ=Europe/Brussels
EOL

# 4. Create required directories
mkdir -p config/app build storage/database storage/files storage/gear-maintenance

# 5. Start the app
docker compose up -d app

# 6. Authorize with Strava (run once)
docker compose run --rm php-cli bin/console app:strava:authenticate
# This outputs an authorization URL — open it in your browser and authorize

# 7. Start the sync daemon
docker compose up -d daemon
```

### Access

Visit `http://<host>:8081` (or whichever port you configured in `docker-compose.yml`).

### Initial data sync

After authorization, trigger the first sync:

```bash
docker compose run --rm php-cli bin/console app:strava:sync-activities
```

This fetches all your historical activities from Strava. Subsequent syncs happen automatically via the daemon.

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

Check the upstream changelog for breaking changes before upgrading: <https://github.com/robiningelbrecht/statistics-for-strava/releases>

## Gotchas

- **Third-party dependency:** This app requires Strava API access — it cannot function offline or without a valid Strava account and API key. Strava's API terms and rate limits apply.
- **Rate limiting:** Strava API has rate limits (100 requests/15min, 1000/day by default). Initial full-history sync may take multiple runs across days for athletes with large activity archives.
- **OAuth callback domain:** When creating the Strava API app, set the callback domain to match your deployment (e.g. `localhost` for local, your domain for remote). Mismatches cause auth failures.
- **`php-cli` profile:** The `php-cli` service is in a Docker Compose profile (`on-demand`) — run with `docker compose run --rm php-cli` for one-off commands like auth and manual sync.
- **Daemon restarts:** The sync daemon connects to Strava periodically. Restart with `docker compose restart daemon` if sync appears stalled.
- **No multi-user:** This is a single-athlete dashboard — designed for personal use with one Strava account.

## Links

- Upstream source: <https://github.com/robiningelbrecht/statistics-for-strava>
- Documentation: <https://statistics-for-strava-docs.robingingelbrecht.be>
- Docker Hub: <https://hub.docker.com/r/robiningelbrecht/strava-statistics>
- Demo: <https://statistics-for-strava.robiningelbrecht.be>
