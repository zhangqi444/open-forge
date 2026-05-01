---
name: TRIP
description: "Self-hostable minimalist map tracker and trip planner. Docker. Python/FastAPI + SQLite. itskovacs/trip. POIs, multi-day itineraries, collaboration, OIDC auth. MIT."
---

# TRIP

**Minimalist self-hostable map tracker and trip planner.** *(Tourism and Recreational Interest Points.)* Map and manage points of interest (POI) on interactive maps, plan multi-day trips with detailed itineraries, and collaborate with travel companions. No telemetry, no tracking, no ads. Free forever. MIT license.

Built + maintained by **itskovacs (BZH)**. Live demo at [itskovacs-trip.netlify.app](https://itskovacs-trip.netlify.app/).

- Upstream repo: <https://github.com/itskovacs/trip>
- Docs: <https://itskovacs.github.io/trip/docs/intro>
- Configuration: <https://itskovacs.github.io/trip/docs/getting-started/configuration>
- Demo: <https://itskovacs-trip.netlify.app>
- GHCR: `ghcr.io/itskovacs/trip`

## Architecture in one minute

- **Python / FastAPI** backend
- **SQLite** database
- Port **8000** inside container (upstream maps `127.0.0.1:8080:8000`)
- Data persisted in `./storage` volume
- Optional **OIDC** authentication
- Resource: **tiny** — Python FastAPI + SQLite

## Compatible install methods

| Infra             | Runtime                        | Notes                                                     |
| ----------------- | ------------------------------ | --------------------------------------------------------- |
| **Docker Compose**| `ghcr.io/itskovacs/trip:1`     | **Primary** — see upstream docker-compose.yml             |
| **Docker Run**    | one-liner                      | Quick start                                               |

## Install via Docker Compose

```yaml
services:
  app:
    image: ghcr.io/itskovacs/trip:1
    ports:
      - 127.0.0.1:8080:8000    # local-only by default; remove 127.0.0.1: for LAN access
    volumes:
      - ./storage:/app/storage
    command: ["fastapi", "run", "/app/trip/main.py", "--host", "0.0.0.0"]
```

```bash
docker compose up -d
```

Visit `http://localhost:8080`.

## Install via Docker Run

```bash
docker pull ghcr.io/itskovacs/trip:1
docker run -d -p 8080:8000 -v ./storage:/app/storage ghcr.io/itskovacs/trip:1
```

## First boot

1. Deploy container.
2. Visit `http://localhost:8080`.
3. Create your account (or configure OIDC — see configuration docs).
4. Create **POIs** — pin locations on the map with name, description, category, photos.
5. Create a **Trip** — add POIs to build a multi-day itinerary.
6. Share with companions for collaborative planning.
7. Put behind TLS (especially if exposing beyond localhost).

## Configuration (OIDC + other settings)

Configure via environment variables. Full reference: <https://itskovacs.github.io/trip/docs/getting-started/configuration>

Key variables:

| Variable | Notes |
|----------|-------|
| `OIDC_*` | OIDC provider settings for SSO |
| `REGISTRATION_ENABLED` | Enable/disable open user registration |

## Data & config layout

- `./storage/` — SQLite DB + uploaded images/attachments

## Backup

```sh
docker compose stop app
sudo tar czf trip-$(date +%F).tgz storage/
docker compose start app
```

## Upgrade

1. The `:1` tag tracks the v1.x branch.
2. `docker compose pull && docker compose up -d`
3. Check [releases](https://github.com/itskovacs/trip/releases) for migration notes (especially if named volumes were used pre-v1.5.0 — see migration guide in that release).

## Gotchas

- **Default port binding is `127.0.0.1:8080`** — loopback-only by default (security-conscious default). To expose on LAN: change to `0.0.0.0:8080:8000` in the ports section, or use a reverse proxy.
- **v1.5.0 storage migration.** If you used a named volume before v1.5.0, the upstream release notes include a migration guide to move to the `./storage` bind mount path. Follow this before upgrading past that version.
- **OIDC is optional.** Without it, TRIP has its own username/password registration. Enable `REGISTRATION_ENABLED=false` after creating your account(s) to prevent others from registering on your instance.
- **Collaborative sharing.** TRIP supports sharing trips/POIs with other registered users. For a household or travel group, each member creates an account and you share specific trips.
- **SQLite = single-file backup.** Simple and reliable for personal/small-group use.
- **GHCR, not Docker Hub.** The image is at `ghcr.io/itskovacs/trip:1`, not Docker Hub. Ensure your pull uses the GHCR URL.
- **125k+ Docker pulls** — more widely deployed than the star count might suggest.

## Project health

Active Python/FastAPI development, GHCR CI, 125k+ Docker pulls, docs site, OIDC support. Solo-maintained by itskovacs. MIT license.

## Map/trip-planner-family comparison

- **TRIP** — Python+FastAPI, POI + multi-day trips, OIDC, collaborative, minimal, MIT
- **OpenStreetMap + uMap** — collaborative map creation; no itinerary planning
- **Wanderer** — Go, activity tracking (hikes/rides); GPX-focused; different scope
- **Google Maps Lists** — SaaS, not self-hosted; no multi-day trip planning beyond basic lists
- **TripIt** — SaaS trip organizer; itineraries from email; not self-hosted

**Choose TRIP if:** you want a minimal self-hosted map to pin POIs and build multi-day itineraries with collaborators, with no tracking or ads.

## Links

- Repo: <https://github.com/itskovacs/trip>
- Docs: <https://itskovacs.github.io/trip/docs/intro>
- Configuration: <https://itskovacs.github.io/trip/docs/getting-started/configuration>
- Demo: <https://itskovacs-trip.netlify.app>
