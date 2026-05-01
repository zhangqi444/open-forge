---
name: FitTrackee
description: "Simple self-hosted workout and activity tracker. Docker. Python/Flask + Vue 3 + PostgreSQL/PostGIS. SamR1/FitTrackee. GPX/FIT/TCX upload, maps (OSM), statistics, equipment tracking, FitoTrack/OpenTracks integration, multi-user, REST API."
---

# FitTrackee

**Simple self-hosted workout and activity tracker.** Upload GPS files (GPX, FIT, TCX) from your device or running app; visualize routes on OpenStreetMap; track statistics over time; manage equipment; multi-user with public/private workouts. REST API for integrations. Supported by FitoTrack, OpenTracks, Gadgetbridge (via export), Amazfish, Runner Up.

Built + maintained by **SamR1**. See repo license.

- Upstream repo: <https://github.com/SamR1/FitTrackee>
- Docs: <https://docs.fittrackee.org>
- Docker Hub: <https://hub.docker.com/r/fittrackee/fittrackee>
- Matrix: <https://matrix.to/#/#fittrackee:matrix.org>
- Mastodon: <https://fosstodon.org/@FitTrackee>

## Architecture in one minute

- **Python / Flask** backend + REST API
- **Vue 3 + TypeScript** frontend
- **PostgreSQL** (14–18) + **PostGIS** (3.4–3.6) database (geospatial queries)
- Optional **Redis** for API rate limiting, data export, and email sending
- Optional **worker** containers for background jobs (multi-user setups)
- Docker Compose: `fittrackee-db` + `fittrackee` + optional `fittrackee-workers` + `fittrackee-redis`
- Resource: **low-medium** — Python + PostgreSQL/PostGIS

## Compatible install methods

| Infra              | Runtime                       | Notes                                                   |
| ------------------ | ----------------------------- | ------------------------------------------------------- |
| **Docker Compose** | `fittrackee/fittrackee`       | **Primary** — Docker Hub; pin to a version tag          |
| **pip**            | `pip install fittrackee`      | PyPI package; bare metal                                |

## Inputs to collect

| Input                   | Example                       | Phase   | Notes                                                           |
| ----------------------- | ----------------------------- | ------- | --------------------------------------------------------------- |
| `SECRET_KEY`            | random string                 | Security| Flask app secret                                               |
| PostgreSQL credentials  | user, password, DB name       | DB      | Must match in `.env` for both app + db services                |
| `EMAIL_URL` (optional)  | `smtp://user:pass@host:port`  | Email   | For email sending (registration, password reset); enables workers |
| Upload dir              | `./data/uploads`              | Storage | Where workout files land                                        |
| Static map cache        | `./data/staticmap_cache`      | Storage | OSM static map tiles cache                                      |

## Install via Docker Compose

Download the compose file + `.env` template:

```bash
curl -O https://raw.githubusercontent.com/SamR1/FitTrackee/main/docker-compose.yml
curl -o .env https://raw.githubusercontent.com/SamR1/FitTrackee/main/.env.example  # check repo for actual filename
```

Key `.env` settings:

```env
SECRET_KEY=change_this_random_secret
POSTGRES_USER=fittrackee
POSTGRES_PASSWORD=changeme
POSTGRES_DB=fittrackee
DATABASE_URL=postgresql://fittrackee:changeme@fittrackee-db:5432/fittrackee
# EMAIL_URL=smtp://user:pass@host:465?ssl=true   # uncomment to enable email
```

```bash
docker compose up -d
```

Visit `http://localhost:5000` (check compose for mapped port).

> **Note:** The compose file pins to a specific version tag (e.g. `fittrackee/fittrackee:v1.2.2`). Update the tag deliberately and back up before DB migrations.

## First boot

1. Set `SECRET_KEY`, DB credentials, and paths in `.env`.
2. `docker compose up -d`.
3. Visit the web UI → register the first account (becomes admin).
4. Upload a workout file (GPX, FIT, or TCX).
5. View your route on the OSM map + workout statistics.
6. Add equipment (shoes, bike) and assign workouts.
7. Configure sport types and settings.
8. Put behind TLS.

## Minimal vs. full setup

| Setup | Services | Use case |
|-------|----------|---------|
| **Minimal** | `fittrackee-db` + `fittrackee` | Single user; no email |
| **Full** | + `fittrackee-workers` + `fittrackee-redis` | Multi-user; user data export; email |

Enable workers + Redis by uncommenting them in the compose file. Set `EMAIL_URL` for email features.

## Supported file formats

| Format | Source |
|--------|--------|
| GPX | FitoTrack, OpenTracks, Garmin, most GPS devices |
| FIT | Garmin, sports watches, Amazfish |
| TCX | Garmin Training Center |

Also supports: adding a workout **without a file** (manual entry with route drawn on map).

## Compatible mobile apps / devices

| App / Device | Notes |
|---|---|
| FitoTrack (Android) | Direct HTTP upload to FitTrackee API |
| OpenTracks (Android) | Export + upload to FitTrackee |
| Amazfish (Sailfish) | Integration from v2.9.0 |
| Gadgetbridge (Android) | Export workouts as FIT/GPX; manual upload |
| Runner Up (Android) | GPX export |

## Features overview

| Feature | Details |
|---------|---------|
| Activity upload | GPX, FIT, TCX; or manual entry |
| Route map | OpenStreetMap-based map per workout |
| Statistics | Distance, duration, speed, elevation; charts over time |
| Equipment | Track shoes/bikes; mileage per equipment |
| Public/private | Per-workout visibility |
| Multi-user | Separate accounts; admin manages users |
| User data export | Export all workouts as a ZIP (requires workers + Redis) |
| Archive upload | Bulk import from a ZIP of workout files |
| REST API | Full API; documented in docs |
| Rate limiting | Optional Redis-backed API rate limiting |
| Workouts without GPS | Manual workouts for gym sessions etc. |
| Sports | Configure sport types per workout |

## Gotchas

- **PostGIS is required.** FitTrackee uses geospatial queries for route storage and map bounding boxes. The compose file uses `postgis/postgis:17-3.5-alpine` — not standard `postgres`. Don't replace with a plain Postgres image.
- **⚠️ No official PostGIS ARM image.** The README notes: "there is no official image for PostGIS on ARM platforms yet." Raspberry Pi / ARM64 users need to build PostGIS locally or use an unofficial arm64 image. Check the GitHub issue for the workaround.
- **Back up before every upgrade with DB migrations.** The compose file's comment explicitly warns this. Check the release notes — versions with schema migrations need a backup first.
- **Workers + Redis for email and export.** The minimal setup (no workers/Redis) works for single users but lacks email sending, password reset emails, and user data export. Uncomment workers + Redis in compose and set `EMAIL_URL` to enable these.
- **Version pin in compose.** The compose pins to `fittrackee/fittrackee:v1.2.2` — update deliberately. Check the changelog at docs.fittrackee.org before upgrading.
- **Static map cache.** OSM tiles for static map previews are cached in `./data/staticmap_cache`. This can grow significantly for large workout histories. Monitor disk usage.
- **FitoTrack direct upload.** FitoTrack on Android can be configured to auto-upload workouts to FitTrackee directly via the REST API. Configure in FitoTrack settings with your server URL + API key.

## Backup

```sh
docker compose stop fittrackee
docker compose exec fittrackee-db pg_dump -U fittrackee fittrackee > fittrackee-$(date +%F).sql
sudo tar czf fittrackee-uploads-$(date +%F).tgz data/uploads/ data/staticmap_cache/
docker compose start fittrackee
```

## Upgrade

1. Read the changelog: <https://docs.fittrackee.org/en/changelog.html>
2. If migration: back up DB first.
3. Update version tag in compose.
4. `docker compose pull && docker compose up -d`.

## Project health

Active Python/Flask + Vue 3 development, Docker Hub, pip package, PostGIS geospatial, FitoTrack + Amazfish integration, REST API, docs site, Matrix + Mastodon community. Solo-maintained by SamR1.

## Fitness-tracker-family comparison

- **FitTrackee** — Python+Flask+Vue, PostGIS, GPX/FIT/TCX, OSM maps, equipment, REST API, FitoTrack
- **Workout Tracker** — Go, similar scope, Fitotrack + Fitbit, segments, heatmap; no PostGIS
- **Stravarr** — reads from Strava; doesn't replace it
- **Garmin Connect** — SaaS; the cloud service for Garmin devices
- **Strava** — SaaS; the commercial reference

**Choose FitTrackee if:** you want a self-hosted workout tracker with PostGIS-backed OSM route maps, GPX/FIT/TCX support, equipment tracking, FitoTrack/Amazfish integration, and a REST API for automation.

## Links

- Repo: <https://github.com/SamR1/FitTrackee>
- Docs: <https://docs.fittrackee.org>
- Docker Hub: <https://hub.docker.com/r/fittrackee/fittrackee>
- Matrix: <https://matrix.to/#/#fittrackee:matrix.org>
