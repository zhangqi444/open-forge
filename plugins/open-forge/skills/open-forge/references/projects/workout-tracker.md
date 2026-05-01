---
name: Workout Tracker
description: "Self-hosted workout and fitness tracking web app. Docker. Go. jovandeginste/workout-tracker. GPX/TCX/FIT import, route segments, heatmap, equipment tracking, stats, API (Fitotrack/Fitbit), Swagger docs. MIT."
---

# Workout Tracker

**Self-hosted web application for tracking workouts and fitness activities.** Upload GPX, TCX, or FIT files from your GPS device or running app; create manual workouts (weightlifting, swimming, etc.); track daily stats (weight, steps); define route segments and see your progress on them; view your activity heatmap; track equipment mileage. REST API for automation (Fitotrack, Fitbit sync).

Built + maintained by **jovandeginste**. MIT license.

- Upstream repo: <https://github.com/jovandeginste/workout-tracker>
- GHCR: `ghcr.io/jovandeginste/workout-tracker`

## Architecture in one minute

- **Go** binary — single executable
- **SQLite** (default) or **PostgreSQL** for storage
- Port **8080** (web UI + API)
- Data directory: `/data` volume
- Swagger API docs available
- Multi-arch Docker images: amd64 + arm64
- Resource: **low** — Go binary; SQLite needs minimal resources

## Compatible install methods

| Infra        | Runtime                                   | Notes                                          |
| ------------ | ----------------------------------------- | ---------------------------------------------- |
| **Docker**   | `ghcr.io/jovandeginste/workout-tracker`   | **Primary** — GHCR; amd64 + arm64              |
| **Binary**   | GitHub Releases                           | Single Go binary                               |

## Install via Docker (SQLite)

```yaml
services:
  workout-tracker:
    image: ghcr.io/jovandeginste/workout-tracker:latest
    container_name: workout-tracker
    restart: unless-stopped
    ports:
      - "8080:8080"
    volumes:
      - ./data:/data
    environment:
      - WT_JWT_ENCRYPTION_KEY=change_this_to_a_random_secret
```

Visit `http://localhost:8080`.

## Install via Docker (PostgreSQL)

Use `docker-compose.postgres.yaml` from the repo, or adapt:

```yaml
services:
  workout-tracker:
    image: ghcr.io/jovandeginste/workout-tracker:latest
    environment:
      - WT_JWT_ENCRYPTION_KEY=change_this_secret
      - WT_DATABASE_DRIVER=postgres
      - WT_DATABASE_DSN=host=db user=wt password=changeme dbname=wt sslmode=disable
    ports:
      - "8080:8080"
    volumes:
      - ./data:/data
    depends_on:
      - db

  db:
    image: postgres:17-alpine
    environment:
      POSTGRES_USER: wt
      POSTGRES_PASSWORD: changeme
      POSTGRES_DB: wt
    volumes:
      - pg_data:/var/lib/postgresql/data

volumes:
  pg_data:
```

## First boot

1. Set `WT_JWT_ENCRYPTION_KEY` before first run (see Gotchas).
2. `docker compose up -d`.
3. Visit `http://localhost:8080` → register your account.
4. Upload your first workout file (GPX, TCX, or FIT).
5. Browse the activity map, stats, and timeline.
6. Create **route segments** to track your times on specific stretches.
7. Add **equipment** (shoes, bike) and assign workouts to track mileage.
8. Set up **daily tracking** for weight/steps.
9. Configure API access for Fitotrack or Fitbit sync.
10. Put behind TLS.

## Supported file formats

| Format | Source |
|--------|--------|
| GPX | Most GPS devices, Garmin, running apps |
| TCX | Garmin Training Center format |
| FIT | Garmin FIT binary format; sports watches |

## Features overview

| Feature | Details |
|---------|---------|
| File upload | GPX, TCX, FIT — manual upload or via API |
| Manual workouts | Log non-GPS activities (weightlifting, swimming, etc.) |
| Route segments | Define segments; auto-detect matches in uploaded workouts; track PRs |
| Heatmap | Visual map of all your activities' GPS traces |
| Daily stats | Weight, step count — manual entry or API sync |
| Equipment | Track mileage per shoe/bike/gear |
| Statistics | Progress charts, summaries, comparisons |
| API | REST API with Swagger docs; used by Fitotrack + Fitbit sync |
| Fitbit sync | Dedicated sync command (`fitbit-sync`) for importing Fitbit data |

## API integrations

- **Fitotrack** — Android GPS tracking app; auto-uploads to Workout Tracker via API
- **Fitbit** — Sync workouts from Fitbit (via `fitbit-sync` tool in the repo)
- Any tool that can POST GPX/FIT files to the API

API docs: `http://localhost:8080/swagger/index.html`

## Gotchas

- **`WT_JWT_ENCRYPTION_KEY` must be set before first run.** If not set, a random key is generated — sessions survive only while the container runs. If the container restarts without the key, all users are logged out. Set a fixed random key (e.g. `openssl rand -hex 32`) and keep it in your compose file.
- **Alternative: `WT_JWT_ENCRYPTION_KEY_FILE`** — mount the key from a Docker secret file instead of exposing it in an env variable: `-e WT_JWT_ENCRYPTION_KEY_FILE=/run/secrets/key` + mount the file.
- **UID for volume permissions.** If running as non-root (`-u 1000:1000`), ensure the `./data` directory is owned by that UID on the host.
- **FIT format parsing.** FIT is a binary Garmin format. CookCLI uses a Go FIT library — parsing is generally good but exotic FIT variants (unusual sports/sensors) may need testing.
- **Route segment detection is automatic.** Once you define a segment by GPS bounding box and path, Workout Tracker scans all future (and existing) uploads for matches. Match detection is approximate — some workouts may not match due to GPS drift.
- **Fitbit sync is a separate binary.** Fitbit integration uses `cmd/fitbit-sync/` — a separate Go binary in the repo. It's not included in the main Docker image. Build separately or run as a cron job.
- **Multi-user.** The app supports multiple user accounts — each user has their own separate workout history. Good for family/friend sharing on a single instance.

## Backup

```sh
docker compose stop workout-tracker
sudo tar czf workout-tracker-$(date +%F).tgz data/
docker compose start workout-tracker
```

For PostgreSQL: `pg_dump -U wt wt > wt-$(date +%F).sql`

## Upgrade

```sh
docker compose pull && docker compose up -d
```

## Project health

Active Go development, GHCR (amd64+arm64), Swagger API, Fitotrack + Fitbit integration, route segments, heatmap. Solo-maintained by jovandeginste. MIT license.

## Self-hosted-fitness-family comparison

- **Workout Tracker** — Go, GPX/TCX/FIT, route segments, heatmap, API, Fitotrack+Fitbit, MIT
- **FitoTrack** — Android GPS app only; uses Workout Tracker as backend
- **Garmin Connect** — SaaS; proprietary; the cloud service for Garmin devices
- **Strava** — SaaS; social fitness; the commercial reference
- **Strava Statistics** (open-source) — reads Strava data; doesn't replace it
- **OpenTracks** — Android tracking only; no web UI

**Choose Workout Tracker if:** you want a self-hosted fitness tracker that accepts GPX/TCX/FIT uploads, shows route heatmaps, tracks progress on defined segments, and integrates with Fitotrack and Fitbit.

## Links

- Repo: <https://github.com/jovandeginste/workout-tracker>
- GHCR: `ghcr.io/jovandeginste/workout-tracker`
- Swagger API: `/swagger/index.html` on your instance
