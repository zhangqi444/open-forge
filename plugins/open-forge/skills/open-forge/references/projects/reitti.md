---
name: Reitti
description: "Personal location-tracking + movement-analysis app — Finnish for 'route/path'. Visit detection; trip analysis; significant-places; multi-user-map; live-mode + kiosk display; GPX/Google-Takeout/GeoJSON import. dedicatedcode."
---

# Reitti

Reitti is **"Google Timeline — but self-hosted + family-capable + kiosk-ready"** — a comprehensive personal location-tracking and analysis app. Automatically detects **visits** (where you spend time) and **trips** (movements with transport-mode: walk/cycle/drive). Recognizes **significant places**. Timeline view with duration/distance. Raw GPS-track visualization. **Multi-user view** for family/friends on one map. **Live-mode** for kiosk-style dashboards. **Fullscreen-mode** for wall-mount kiosks. Imports GPX, Google Takeout JSON, Google Timeline Exports, GeoJSON.

Built + maintained by **dedicatedcode** org. License: check LICENSE. Active; screenshots-rich README; banner branding.

Use cases: (a) **Google-Maps-Timeline self-hosted replacement** — escape cloud tracking (b) **family-location-dashboard kiosk** — wall-mount where-is-everyone (c) **personal-travel-log** — visualize years of trips (d) **movement-habit-analysis** (e) **kiosk-display-for-ops-center** (f) **GPX-trip-archive with analysis** (g) **privacy-first-location-tracking** (h) **cyclist/hiker trip-log**.

Features (per README):

- **Visit detection** — auto-identify places
- **Trip analysis** — with transport-mode detection
- **Significant places** — named + categorized
- **Timeline view**
- **Raw GPS tracks** visualization
- **Multi-user view** — family map
- **Live mode** — real-time map updates
- **Fullscreen / kiosk mode**
- **Multiple import formats** — GPX, Google Takeout, Google Timeline, GeoJSON

- Upstream repo: <https://github.com/dedicatedcode/reitti>

## Architecture in one minute

- **JVM** app (typical for dedicatedcode)
- **PostgreSQL + PostGIS** likely
- **Tile-server**: external (OpenStreetMap tiles usually)
- **Resource**: moderate — spatial queries need RAM
- **Port**: web UI

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker Compose** | **App + PG/PostGIS**                                            | **Primary**                                                                        |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `reitti.example.com`                                        | URL          | TLS (contains private location data!)                                                                                    |
| Admin creds          | First-boot                                                  | Bootstrap    | Strong                                                                                    |
| PostgreSQL + PostGIS | Data                                                        | DB           |                                                                                    |
| Import files         | GPX / Takeout                                               | Ingestion    | May be GB of data                                                                                    |
| GPS source           | OwnTracks / Traccar / phone                                 | Ingestion    | Per-user token                                                                                    |

## Install via Docker

Check <https://github.com/dedicatedcode/reitti> for exact compose; typical pattern:

```yaml
services:
  db:
    image: postgis/postgis:16-3.4
    environment:
      POSTGRES_USER: reitti
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_DB: reitti
    volumes: [pgdata:/var/lib/postgresql/data]

  reitti:
    image: dedicatedcode/reitti:latest        # **pin version**
    ports: ["8080:8080"]
    environment:
      DB_URL: jdbc:postgresql://db:5432/reitti
      DB_USER: reitti
      DB_PASSWORD: ${DB_PASSWORD}
    depends_on: [db]

volumes:
  pgdata: {}
```

## First boot

1. Start stack
2. Create admin account
3. Add additional family users
4. Configure phone GPS source (OwnTracks / Traccar)
5. Import GPX or Google Takeout archive
6. Watch visit/trip detection run
7. Set up kiosk display (fullscreen + live-mode)
8. **Put behind TLS** — location data is highly sensitive
9. Back up PG

## Data & config layout

- **PostgreSQL + PostGIS** — locations, visits, trips, places, users
- Tiles cached or fetched from OSM

## Backup

```sh
docker compose exec db pg_dump -U reitti reitti > reitti-$(date +%F).sql
# **ENCRYPT — contains your complete movement history**
```

## Upgrade

1. Releases: <https://github.com/dedicatedcode/reitti/releases>.
2. DB migrations — read notes
3. Docker pull + restart

## Gotchas

- **132nd HUB-OF-CREDENTIALS CROWN-JEWEL TIER 1 — LOCATION-HISTORY-AGGREGATOR**:
  - **HIGHEST personal-sensitivity** short of banking credentials
  - Holds: complete movement history (home/work/dates/routines) + family members + ingestion tokens
  - Leak = stalking, physical-security, burglary-planning risk
  - **132nd tool in hub-of-credentials family — Tier 1 CROWN-JEWEL**
  - **NEW CROWN-JEWEL Tier 1 sub-category: "location-history + movement-pattern-aggregator"** (1st — Reitti; distinct — physical-world-surveillance-grade data)
  - **CROWN-JEWEL Tier 1: 38 tools / 35 sub-categories**
- **LOCATION-DATA-PHYSICAL-SECURITY-RISK**:
  - Home address, work address, routines, family-member locations
  - Much worse than most credential leaks
  - **Recipe convention: "location-data-is-physical-security-data callout"**
  - **NEW recipe convention** (Reitti 1st formally) — HIGHEST-severity
- **KIOSK-DISPLAY-MODE OPERATIONAL-SECURITY**:
  - Fullscreen kiosk shows family positions
  - Don't mount in public-viewable location!
  - **Recipe convention: "kiosk-display-shoulder-surfing-risk callout"**
  - **NEW recipe convention** (Reitti 1st formally)
- **MULTI-USER FAMILY MAP**:
  - All family members visible on one map
  - Consent discussion needed (especially teens)
  - **Recipe convention: "family-surveillance-consent-discipline callout"**
  - **NEW recipe convention** (Reitti 1st formally)
- **GPS-INGESTION-TOKEN-DISCIPLINE**:
  - Per-user token for phone ingestion
  - Leaked token = impersonation + false-data-injection
  - **Recipe convention: "per-user-ingestion-token-rotation callout"**
- **TILE-SERVER-OSM-USAGE-POLICY**:
  - Default fetches from OpenStreetMap tile servers
  - OSM has heavy-use tile-policy — cache or self-host tiles if high volume
  - **Recipe convention: "OSM-tile-usage-policy-compliance callout"**
  - **NEW recipe convention** (Reitti 1st formally)
- **GOOGLE-TAKEOUT-IMPORT = ESCAPE FROM BIG-TECH**:
  - Makes migration away from Google Timeline easy
  - **Recipe convention: "big-tech-escape-import positive-signal"**
  - **NEW positive-signal convention** (Reitti 1st formally)
- **FINNISH PROJECT-NAME ETYMOLOGY**:
  - "Reitti" = route/path in Finnish
  - **Recipe convention: "non-English-project-name-etymology neutral-signal"**
  - **NEW neutral-signal convention** (Reitti 1st formally)
- **INSTITUTIONAL-STEWARDSHIP**: dedicatedcode org + rich README + screenshots + multi-feature. **118th tool — niche-active-org sub-tier** (reuses prior).
- **TRANSPARENT-MAINTENANCE**: active + feature-rich + screenshots + imports from 4 formats. **124th tool in transparent-maintenance family.**
- **LOCATION-TRACKING-CATEGORY:**
  - **Reitti** — visits + trips + multi-user + kiosk
  - **Dawarich** — Ruby; location-archive + timeline
  - **OwnTracks** — iOS/Android app + recorder; data-only
  - **Traccar** — GPS-tracking (fleet-oriented)
  - **PhoneTrack (Nextcloud)** — NC-ecosystem
- **ALTERNATIVES WORTH KNOWING:**
  - **Dawarich** — if you want Ruby + cleaner focus on Google Timeline replacement
  - **OwnTracks recorder** — if you want data-only, bring-your-own-viewer
  - **Traccar** — if you want fleet/IoT
  - **Choose Reitti if:** you want family-map + kiosk + transport-mode-detection.
- **PROJECT HEALTH**: active + feature-rich + screenshots + multi-user. Strong.

## Links

- Repo: <https://github.com/dedicatedcode/reitti>
- Dawarich (alt): <https://github.com/Freika/dawarich>
- OwnTracks: <https://owntracks.org>
- Traccar (alt): <https://github.com/traccar/traccar>
