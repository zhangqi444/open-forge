---
name: wanderer
description: "Self-hosted trail + GPS track catalogue. Upload recorded tracks or plan routes, add metadata to build searchable hiking/cycling/running database. Extensive map integration. Svelte + PocketBase + Meilisearch. AGPL-3.0. Active sole-maintainer project with Discord community."
---

# wanderer

wanderer is **"Strava / AllTrails / Komoot, but self-hosted + your GPS data stays yours"** — a trail database for hikers, cyclists, runners, ski tourers, kayakers. Upload your recorded `.gpx` / `.fit` / `.tcx` tracks from Garmin / Wahoo / iPhone / whatever, or plan new routes. Attach photos, metadata, difficulty, elevation stats. Share with friends or keep private. Search + filter by distance / elevation / region / season / activity type. Web + map interface; extensive map-tile integration.

Built + maintained by **Florian (Flomp) + community** under **open-wanderer** org. **AGPL-3.0**. Sole-maintainer project funded via Buy-Me-A-Coffee + Liberapay. Active Discord + Crowdin translation community.

Use cases: (a) **personal GPS archive** — decades of runs/rides/hikes, searchable (b) **family / friends trail-sharing** — "here's my best hike from last weekend" (c) **outdoor club catalog** — shared trail library for a running/cycling club (d) **replace Strava / AllTrails / Komoot** for privacy + sovereignty (e) **route planner** — draw routes + export to Garmin / phone apps (f) **trail archive** for land-access advocacy or local-trail preservation.

Features (from upstream README):

- **Manage trails** — upload, tag, describe
- **Plan new routes** — point-and-click on map with elevation preview
- **Extensive map integration** — tile providers (OSM, satellite, topographic)
- **Share trails** with other users (public / private / per-user)
- **Explore** other users' public trails
- **Advanced filter + search** — Meilisearch-powered
- **Custom lists** — "summer hikes", "winter rides", "races"
- **GPS format support**: .gpx, .fit, .tcx imports
- **Elevation profiles + 3D map views** (per docs)
- **Photos attached to trails**
- **Translations** via Crowdin (many languages)

- Upstream repo: <https://github.com/open-wanderer/wanderer>
- Homepage: <https://wanderer.to>
- Docs: <https://wanderer.to>
- Installation: <https://wanderer.to/run/installation/from-source>
- Docker compose: <https://raw.githubusercontent.com/open-wanderer/wanderer/main/docker-compose.yml>
- Demo: <https://demo.wanderer.to>
- Discord: <https://discord.gg/USSEBY98CP>
- Crowdin: <https://crowdin.com/project/wanderer>
- Buy Me A Coffee: <https://www.buymeacoffee.com/wanderertrails>
- Liberapay: <https://liberapay.com/wanderer/>
- Roadmap: <https://github.com/users/Flomp/projects/2/views/1>

## Architecture in one minute

- **Svelte (SvelteKit)** frontend
- **Node.js** backend
- **PocketBase** — embedded DB + auth + file-storage
- **Meilisearch** — full-text + filter-search engine
- **Map tiles** from external providers (OSM by default)
- **Resource**: moderate — 500MB-1GB RAM total for webapp + PocketBase + Meilisearch stack
- **Port 3000** (frontend)

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker Compose** | **`docker compose up -d` with upstream `docker-compose.yml`**   | **Upstream-recommended fastest path**                                              |
| Bare-metal         | Node + PocketBase + Meilisearch separately                                | For advanced users per docs/from-source                                                                                   |
| Kubernetes         | Community-assembled manifests                                                                         | Not upstream-primary                                                                                               |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `trails.example.com`                                        | URL          | `ORIGIN` env must match (CORS)                                                                                    |
| `ORIGIN`             | `https://trails.example.com`                                | **CRITICAL** | Must match public URL or CORS errors                                                                                    |
| `MEILI_MASTER_KEY`   | Meilisearch master key                                                          | **CRITICAL** | **IMMUTABLE; change before prod deploy**                                                                                    |
| Admin user + password | First-boot registration                                                                                   | Bootstrap    | Strong password                                                                                    |
| DB / PocketBase data dir | Persistent volume                                                                                                         | Storage      | **Trail data lives here — back up**                                                                                                              |
| Meilisearch data dir | Persistent volume                                                                                                                          | Search       | Regeneratable from PocketBase (re-index)                                                                                                                                            |

## Install via Docker Compose (upstream path)

```sh
mkdir -p wanderer && cd wanderer
wget https://raw.githubusercontent.com/open-wanderer/wanderer/main/docker-compose.yml
# **EDIT docker-compose.yml**:
#   - Set ORIGIN=https://trails.example.com
#   - Change MEILI_MASTER_KEY to a strong random value (openssl rand -hex 32)
docker compose up -d
# First startup can take ~90 seconds
```

## First boot

1. Wait ~90s for first boot (per upstream)
2. Browse `http://localhost:3000` (or your public URL)
3. Register first admin user
4. Upload your first `.gpx` → verify map renders
5. Build filters + custom lists
6. Configure TLS via reverse proxy (SWAG / Caddy / Traefik)
7. Back up PocketBase data + docker-compose env (for `MEILI_MASTER_KEY`)

## Data & config layout

- **PocketBase volume** — trail metadata + users + uploaded .gpx/.fit/.tcx + photos
- **Meilisearch volume** — search index (regenerable from PocketBase)
- **docker-compose env** — `MEILI_MASTER_KEY` + `ORIGIN` + admin auth settings
- **Uploaded media** — often the LARGEST disk consumer (photos attached to trails)

## Backup

```sh
docker compose stop
sudo tar czf wanderer-$(date +%F).tgz ./pb_data ./meili_data
docker compose start
# Also back up docker-compose.yml or .env for secrets (MEILI_MASTER_KEY especially)
```

## Upgrade

1. Releases: <https://github.com/open-wanderer/wanderer/releases>. Active cadence.
2. `docker compose pull && docker compose up -d`
3. **Back up `pb_data` + secrets BEFORE upgrading** — PocketBase schema changes can happen.
4. Read release notes.
5. Meilisearch may need re-index after some upgrades.

## Gotchas

- **GPS TRACK PRIVACY = LOCATION DATA PRIVACY**: your GPS tracks reveal:
  - **Home address** (where tracks start/end)
  - **Work location** (daily commute tracks)
  - **Family + friends' homes** (visited locations)
  - **Daily routines + schedules** (repeat runs at 6am)
  - **Wealthier areas frequented** (socio-economic profiling)
  - **Strava-scandal-class privacy exposure**: in 2018, Strava's global heatmap accidentally mapped secret US military bases via soldiers' runs. Your personal data is less globally consequential but equally personal.
  - **Implication**: default to PRIVATE trails; only make public what you explicitly choose
  - **Trim start/end of tracks** that begin/end at home (built-in in some tools; verify wanderer has this or sanitize pre-upload)
- **`MEILI_MASTER_KEY` IMMUTABILITY**: Meilisearch master key gates search-index access. Change = re-index required. **22nd tool in immutability-of-secrets family.** Set a strong value BEFORE production deployment (upstream README explicitly warns).
- **`ORIGIN` CORS trap**: if you don't update `ORIGIN` to match your public URL, browsers throw CORS errors on all API calls + the app silently fails. **Per upstream README explicit warning.** Newcomer's #1 stumble.
- **Map tile provider terms**: OSM default has usage limits (tile-server-ToS) — fine for personal use, potentially problematic for public instance with high traffic. For serious public deploy:
  - **Self-host tile server** (expensive; disk-heavy)
  - **Use paid commercial tile provider** (Mapbox, Thunderforest, MapTiler)
  - **Cache tiles aggressively** at CDN/reverse-proxy layer
- **FILE UPLOADS = STORAGE GROWTH**: .gpx / .fit files are small but **photos attached to trails are LARGE**. Plan disk. Optional: S3-backend storage via PocketBase.
- **HUB-OF-CREDENTIALS Tier 3 (LIGHT)**: wanderer stores user accounts + Meilisearch master key + map-provider API keys (if any). **26th tool in hub-of-credentials family, LIGHT tier.** Not extreme; worth care.
- **SOLE-MAINTAINER PROJECT**: Florian (Flomp) solo + community-contributor model. **Bus-factor-1 concern mitigated by AGPL + Discord community + multi-channel funding (BMAC + Liberapay) + Crowdin translation community.** If you depend on wanderer for long-term archival, sponsor the maintainer + keep DB backups portable (standard .gpx export).
- **GPS FORMAT INTEROP**: wanderer imports .gpx / .fit / .tcx (industry standards) + should export .gpx. **Your data stays portable** — if wanderer development ever stagnates, export as .gpx and migrate to any other trail tool.
- **GARMIN CONNECT / STRAVA EXPORT**: if migrating from Strava or Garmin, use their "export all my data" features → download archive → bulk-upload to wanderer. Time-consuming but tractable.
- **AGPL-3**: source-disclosure for modifications distributed publicly. Fine for self-host + internal use.
- **INSTITUTIONAL-STEWARDSHIP — sole-maintainer-tier** (like Memories batch 88 pulsejet): similar framing. Bus-factor-1 but OSS-license-makes-forkable + active-community-presence. **Pattern: "sole-maintainer with community"**.
- **GDPR considerations**: trails + photos are personal data. For multi-user instance:
  - Provide privacy notice
  - Right to erasure flow (delete user + all trails)
  - Data export (standard .gpx) for portability rights
- **NO COMMERCIAL-TIER**: wanderer is pure-community-funded via donations. **"services-around-OSS / pure-donation"** pattern (like SWAG, LinkStack in this batch).
- **WCAG / accessibility**: not extensively documented as a feature (unlike LimeSurvey batch 90 explicit WCAG 2.0 claim). For accessibility-sensitive deployment, audit with screen-reader tools before committing.
- **ROUTE-PLANNING LEGAL**: planning a route that crosses private property or restricted areas → legal implications on trail data accuracy. **Wanderer ≠ legal route-publisher; users' responsibility to verify land access.**
- **PHOTO-UPLOAD EXIF**: photos carry GPS coords in EXIF → layered privacy (trail GPS + photo GPS). Consider strip-EXIF on upload.
- **Alternatives worth knowing:**
  - **Strava** — commercial SaaS; network effects for segments + KOMs; privacy concerns
  - **Komoot** — commercial SaaS; route-planning-primary
  - **AllTrails** — commercial SaaS; curated trail-catalog-first
  - **RidewithGPS** — commercial SaaS; cycling-primary
  - **Trailforks** — MTB-primary
  - **OpenTracks** (Android app, no server) — private-first local-only
  - **GeoTracker** (Android app) — similar
  - **FitTrackee** — OSS + Python self-hosted activity tracker (trail-light)
  - **GPXmagic** — OSS .gpx editor
  - **Choose wanderer if:** you want self-hosted + trail-catalog-first + AGPL + GPS + map-rich + active-community.
  - **Choose FitTrackee if:** you want Python/Flask stack + similar goals + arguably smaller scope.
  - **Choose Strava if:** you want network effects + commercial features + accept SaaS + privacy tradeoffs.
  - **Choose OpenTracks (app) if:** you want local-only + no server + private by default.
- **Project health**: active repo + Discord + Crowdin + donations-funded + AGPL + core features solid + community-translation-effort. Sole-maintainer risk but high quality.

## Links

- Repo: <https://github.com/open-wanderer/wanderer>
- Homepage: <https://wanderer.to>
- Install: <https://wanderer.to/run/installation/from-source>
- Demo: <https://demo.wanderer.to>
- Discord: <https://discord.gg/USSEBY98CP>
- Buy Me A Coffee: <https://www.buymeacoffee.com/wanderertrails>
- Liberapay: <https://liberapay.com/wanderer/>
- FitTrackee (alt, OSS Python): <https://github.com/SamR1/FitTrackee>
- OpenTracks (alt, Android local): <https://github.com/OpenTracksApp/OpenTracks>
- Strava (commercial alt): <https://www.strava.com>
- Komoot (commercial alt): <https://www.komoot.com>
- PocketBase (DB): <https://pocketbase.io>
- Meilisearch (search): <https://www.meilisearch.com>
