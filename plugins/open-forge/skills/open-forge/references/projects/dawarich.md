---
name: Dawarich
description: "Self-hostable location history tracker — Google Timeline / Location History replacement. Map view, trips, stats, family sharing, Immich/Photoprism integration. Ingests from Google Takeout, OwnTracks, GPX, GeoJSON, iOS/Android companion apps. Rails + Postgres + Redis. AGPL-3.0."
---

# Dawarich

Dawarich is a self-hosted **Google Timeline / Location History replacement**. When Google killed cloud-hosted Timeline (2024), "where have I been?" became a self-hosting problem. Dawarich fills that gap with an interactive map, trip analysis, family sharing, rich statistics, and ingestion from every common source (Google Takeout, OwnTracks, Overland, GPSLogger, PhoneTrack, Home Assistant, GPX, GeoJSON, iOS/Android Dawarich apps).

What you get:

- **Interactive map** — heatmap + trails of everywhere you've been
- **Trips** — auto-detect or manually create; annotate, share
- **Insights** — countries visited, cities, total distance, time-by-place
- **Family sharing** — see each other's live location (opt-in)
- **Photo integration** — pulls from Immich / Photoprism, geotags on the map
- **Ingestion** — Google Maps Timeline (Takeout), OwnTracks, Overland, GPSLogger, PhoneTrack, GPX, GeoJSON, Home Assistant device_tracker
- **Mobile apps** — official iOS + Android Dawarich apps; plus `sunstep/dawarich-android` community fork
- **API** for automations
- **Dawarich Cloud** — managed option if you don't want to self-host

**⚠️ Upstream warnings** (from README, paraphrased):

- **DO NOT UPDATE AUTOMATICALLY** — read release notes first; automatic pulls break setups
- **Under active development** — expect bugs + breaking changes
- **Do NOT delete your original data after import** — keep backups
- **Back up before every update**

Take these seriously. Dawarich is pre-1.0 and breaking changes happen.

- Upstream repo: <https://github.com/Freika/dawarich>
- Hosted/managed: <https://dawarich.app>
- Docs: <https://dawarich.app/docs>
- Discord: <https://discord.gg/pHsBjpt5J8>
- Patreon: <https://www.patreon.com/freika>

## Architecture in one minute

- **Rails 7+** (Ruby 3.x)
- **Postgres 13+** (the primary DB; holds location points, trips, stats)
- **Redis** (jobs + caching)
- **Sidekiq** — background jobs (trip detection, statistics computation, import processing)
- **Photon** — geocoding service (optional; for reverse-geocoding point → city/country). Heavy (8+ GB for Europe, 80+ GB worldwide). Many self-hosters skip it or use Nominatim.
- **LightingMaps / OSM tiles** — map rendering (client-side via Leaflet + OSM or self-hosted tile server)

## Compatible install methods

| Infra       | Runtime                                                   | Notes                                                           |
| ----------- | --------------------------------------------------------- | --------------------------------------------------------------- |
| Single VM   | **Docker Compose** (upstream-provided)                       | **The way**                                                         |
| Single VM   | Helm / Kubernetes (community)                                   | Exists but less tested                                                      |
| Managed     | Dawarich Cloud                                                     | Cheapest/easiest if you don't want ops                                              |

## Inputs to collect

| Input             | Example                        | Phase     | Notes                                                           |
| ----------------- | ------------------------------ | --------- | --------------------------------------------------------------- |
| Domain            | `dawarich.example.com`           | URL       | **MUST** match `APPLICATION_HOST(S)` env                            |
| DB creds          | Postgres user/password             | DB        | Used by Rails                                                           |
| Redis             | Included in compose                  | Queue     | No config needed unless external                                                 |
| Admin email       | set via env/install                   | Bootstrap | First account created                                                                    |
| API key           | auto-generated per-user                 | API       | Mobile apps + OwnTracks need it                                                                    |
| Mapbox key (opt)  | for premium tiles                         | Map       | Default uses OSM                                                                                  |
| Photon instance (opt) | self-hosted or public             | Geocoding | Optional but enables city/country enrichment                                                                    |
| TLS               | Mandatory for mobile location POSTs           | Security  | OwnTracks / Overland will refuse plain HTTP                                                                    |

## Install via Docker Compose

Upstream provides `docker-compose.yml`. Clone the repo or copy the canonical compose:

```sh
git clone https://github.com/Freika/dawarich.git
cd dawarich
cp .env.example .env
# Edit .env: set APPLICATION_HOST, SECRET_KEY_BASE, database creds, email settings
docker compose up -d
```

Minimal compose skeleton:

```yaml
services:
  dawarich_app:
    image: freikin/dawarich:1.7.4          # pin specific version; check releases
    container_name: dawarich_app
    restart: unless-stopped
    depends_on:
      - dawarich_db
      - dawarich_redis
    ports:
      - "3000:3000"
    env_file: .env
    environment:
      RAILS_ENV: production
      DATABASE_URL: postgres://postgres:<strong>@dawarich_db/dawarich_production
      REDIS_URL: redis://dawarich_redis:6379/0
      APPLICATION_HOST: dawarich.example.com
      APPLICATION_HOSTS: dawarich.example.com
      TIME_ZONE: America/Los_Angeles
      SECRET_KEY_BASE: <64-char-random>
      # PHOTON_API_HOST: photon.example.com   # optional
    volumes:
      - dawarich_public:/var/app/public
      - dawarich_imports:/var/app/tmp/imports/watched

  dawarich_db:
    image: postgres:14-alpine
    container_name: dawarich_db
    restart: unless-stopped
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: <strong>
      POSTGRES_DB: dawarich_production
    volumes:
      - dawarich_db:/var/lib/postgresql/data

  dawarich_redis:
    image: redis:7-alpine
    container_name: dawarich_redis
    restart: unless-stopped
    volumes:
      - dawarich_redis:/data

volumes:
  dawarich_db:
  dawarich_redis:
  dawarich_public:
  dawarich_imports:
```

Front with Caddy/nginx + TLS. Browse `https://dawarich.example.com` → register admin.

## First boot

1. Register admin account (first user is admin)
2. Settings → generate API key (per-user)
3. Install iOS/Android Dawarich app (or OwnTracks/Overland), configure endpoint + API key
4. Let app run a day → points start flowing in
5. **Import historical data**:
   - Google Takeout → Location History → download ZIP → upload in Settings → Imports
   - OwnTracks archive → Settings → Imports → OwnTracks
   - GPX / GeoJSON → same
6. Trips auto-detect after 24-48h of data + Sidekiq completing processing

## Photon (optional but useful)

Geocoding enriches points with "which city / which country." Without Photon, the UI still works but country/city stats are empty.

Self-host Photon OR use a public instance (respect rate limits):

```yaml
  photon:
    image: rtuszik/photon-docker:latest
    container_name: photon
    restart: unless-stopped
    ports:
      - "2322:2322"
    volumes:
      - ./photon-data:/photon/photon_data    # ~80 GB for world; 8+ GB for Europe
    environment:
      # See photon-docker docs for region/country subsets
      COUNTRIES: fr,de,it,es,uk    # trim to save disk
```

Then in Dawarich `.env`: `PHOTON_API_HOST=photon:2322`.

## Data & config layout

- Postgres — all points, users, trips, stats, sessions
- Redis — job queue + cache
- `tmp/imports/watched/` — drop Google Takeout / OwnTracks / GPX files; watcher picks them up
- `public/` — avatars + other uploads
- `.env` — app config

## Backup

```sh
# DB (CRITICAL — all your location history)
docker exec dawarich_db pg_dump -U postgres dawarich_production | gzip > dawarich-db-$(date +%F).sql.gz

# Uploads / imports
tar czf dawarich-files-$(date +%F).tgz \
  $(docker volume inspect dawarich_dawarich_public -f '{{.Mountpoint}}') \
  $(docker volume inspect dawarich_dawarich_imports -f '{{.Mountpoint}}')
```

**Keep original raw data** (Google Takeout ZIP, OwnTracks archive) even after import. Dawarich is pre-1.0; re-import may be necessary.

## Upgrade

1. Releases: <https://github.com/Freika/dawarich/releases>. Active.
2. **READ THE RELEASE NOTES** — upstream explicitly says automatic updates may break setups.
3. **Back up DB + volumes first** (see above).
4. Docker: update the image tag in compose → `docker compose pull && docker compose up -d`. Migrations run on startup.
5. If migration fails (happens), restore from backup and wait for upstream fix or community workaround on Discord.

## Gotchas

- **Pre-1.0 + fast-moving** — breaking changes + schema migrations are common. Treat Dawarich as a hobbyist project until 1.0. If uptime/stability matters, consider Dawarich Cloud instead.
- **`APPLICATION_HOST(S)` must match your access URL** — mismatch = CSRF errors + mobile apps can't authenticate.
- **TLS is mandatory in practice** — OwnTracks on iOS and Overland refuse plain HTTP. Terminate TLS at reverse proxy or use Tailscale HTTPS.
- **Photon is heavy** — 80+ GB for worldwide geocoding data. For just-your-country, trim via `COUNTRIES` env. For personal use, a public Photon instance is usually fine (rate-limit-aware).
- **Google Takeout import** — large imports (years of Timeline data) take HOURS in Sidekiq. Don't panic if "processing" shows no progress for a while. Logs will confirm work is happening.
- **Data granularity matters** — iOS Dawarich app + Overland are aggressive samplers (points every few seconds when moving). Database grows fast: 1-3 GB/year of active use is typical.
- **Family sharing** — opt-in per user; can be revoked. Live-location has TTL; not a permanent feed unless configured.
- **Privacy stance**: Dawarich self-hosted means your location never leaves your server. Mobile apps send directly to your instance (not through Dawarich's servers). Reverse-geocoding via public Photon leaks coordinates to that Photon operator; use self-hosted Photon for full privacy.
- **Mobile app battery drain** — location tracking is inherently battery-heavy. Dawarich iOS/Android apps optimize but expect ~10-20% extra battery/day with tracking enabled.
- **OwnTracks** is still the most battle-tested mobile tracking protocol; works fine with Dawarich as long as you configure the endpoint right.
- **Home Assistant integration** — Dawarich can receive HA's `device_tracker` state; useful for pulling existing HA location data.
- **Immich/Photoprism integration** — requires API keys; Dawarich pulls metadata + geotag EXIF from those tools to overlay photos on your map.
- **Delete-all-data is idempotent-ish** — but re-imports of the same Google Takeout produce duplicates unless you delete first.
- **Rails upgrades** between releases can be disruptive — the Docker image packages everything, so you only deal with env-var changes + DB migrations.
- **API auth**: API keys per user; keep them secret (they grant full write access to your location history).
- **Trip detection algorithm** sometimes misfires (e.g., long stationary period followed by movement = new trip or not?). Manually edit/merge trips as needed.
- **Photo tile server**: map tiles default to OSM (tile.openstreetmap.org) — don't hammer public OSM at scale; get a Mapbox key or self-host tileserver-gl for heavy personal use.
- **Dawarich Cloud** — upstream's managed option; fair if you want the features without operating the stack.
- **AGPL-3.0** — strong copyleft; if you deploy a fork, source must be available to users.
- **Alternatives worth knowing:**
  - **OwnTracks Recorder** — the OG self-hosted location tracker; simpler; less UI polish; MIT
  - **Traccar** — fleet/vehicle-tracking focused; Java; more features for vehicles than people
  - **Home Assistant** — device_tracker + zones; good for presence; not a timeline tool
  - **PhotoPrism + GeoQ** — photo-centric, not a pure tracker
  - **Google Timeline (on-device only)** — Google's post-2024 solution; data stays on phone
  - **Apple's on-device Significant Locations** — iCloud-synced; privacy-sensitive; can't export easily
  - **Choose Dawarich if:** you want a polished Timeline-replacement webapp with map + trips + family + photos.
  - **Choose OwnTracks Recorder if:** you want minimal, battle-tested, long-running tracker and don't need fancy UI.
  - **Choose Traccar if:** you track vehicles, not people.

## Links

- Repo: <https://github.com/Freika/dawarich>
- Website: <https://dawarich.app>
- Docs: <https://dawarich.app/docs>
- Quickstart: <https://dawarich.app/docs/intro>
- Backup/restore: <https://dawarich.app/docs/tutorials/backup-and-restore>
- Google Takeout import: <https://dawarich.app/docs/tutorials/import-existing-data/google-takeout>
- OwnTracks integration: <https://dawarich.app/docs/tutorials/track-your-location#owntracks>
- iOS app: <https://dawarich.app/docs/dawarich-for-ios/>
- Android app: <https://dawarich.app/docs/dawarich-for-android/>
- Releases: <https://github.com/Freika/dawarich/releases>
- Docker Hub: <https://hub.docker.com/r/freikin/dawarich>
- Discord: <https://discord.gg/pHsBjpt5J8>
- Patreon: <https://www.patreon.com/freika>
