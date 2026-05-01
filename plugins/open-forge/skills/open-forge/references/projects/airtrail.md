---
name: AirTrail
description: "Self-hosted personal flight tracker and history logger. Docker. SvelteKit + PostgreSQL. johanohly/AirTrail. Log flights on an interactive world map, view statistics, multi-user, OAuth SSO, import from MyFlightRadar24/TripIt/Flighty/JetLog/App in the Air."
---

# AirTrail

**Self-hosted personal flight tracker.** Log every flight you've taken on an interactive world map. View statistics (total distance, countries visited, airport count, etc.). Multi-user with shared flights. OAuth SSO. Import your existing flight history from MyFlightRadar24, App in the Air, JetLog, TripIt, Flighty, and byAir. Responsive, dark mode.

Built + maintained by **johanohly**. See repo license.

- Upstream repo: <https://github.com/johanohly/AirTrail>
- Docker Hub: `johly/airtrail`
- Docs: <https://airtrail.johan.ohly.dk/docs>
- Demo: <https://demo.airtrail.johan.ohly.dk>

## Architecture in one minute

- **SvelteKit** frontend + backend
- **PostgreSQL** database (via Prisma ORM)
- Port **3000** (configurable)
- Docker Compose: app + postgres
- Resource: **low** — SvelteKit + PostgreSQL

## Compatible install methods

| Infra              | Runtime           | Notes                                                  |
| ------------------ | ----------------- | ------------------------------------------------------ |
| **Docker Compose** | `johly/airtrail`  | **Primary** — see docker/ directory in repo            |

Full install guide: <https://airtrail.johan.ohly.dk/docs/install/docker-compose>

## Install via Docker Compose

```bash
# Get the docker-compose from the repo's docker/ directory
git clone https://github.com/johanohly/AirTrail.git
cd AirTrail/docker
cp .env.example .env
# Edit .env with your settings
docker compose up -d
```

Or see the docs for a standalone compose snippet.

## Inputs to collect

| Input | Notes |
|-------|-------|
| `DATABASE_URL` | PostgreSQL connection string |
| `ORIGIN` | Your public URL (required for SvelteKit CSRF protection) |
| OAuth credentials (optional) | For OAuth SSO (Google, GitHub, etc.) |

## Features overview

| Feature | Details |
|---------|---------|
| Interactive world map | All flights visualized on a world map with arcs |
| Flight history | Log past and future flights; edit/delete anytime |
| Statistics | Total distance, flight count, airports, countries, airlines |
| Multi-user | Multiple user accounts per instance |
| Shared flights | Share specific flights with other users on the instance |
| User authentication | Local accounts + optional OAuth |
| OAuth SSO | Sign in with Google, GitHub, or other OAuth providers |
| Dark mode | Light/dark theme toggle |
| Responsive design | Works on mobile, tablet, and desktop |
| Import: MyFlightRadar24 | Import from MFR24 export |
| Import: App in the Air | Import from AITA export |
| Import: JetLog | Import from JetLog export |
| Import: TripIt | Import from TripIt export |
| Import: Flighty | Import from Flighty export |
| Import: byAir | Import from byAir export |

## First boot

1. Configure `.env` with `DATABASE_URL` and `ORIGIN`.
2. `docker compose up -d`.
3. Visit `http://localhost:3000`.
4. Register your account.
5. Log your first flight (Add Flight → fill in origin/destination/date/airline).
6. Import existing flights from your previous tracking app (Settings → Import).
7. Explore the world map and statistics.
8. (Optional) Configure OAuth in admin settings.
9. Put behind TLS.

## Import guide

| Source app | Export format | Import via |
|------------|--------------|------------|
| MyFlightRadar24 | CSV export | AirTrail → Settings → Import |
| App in the Air | CSV/JSON export | AirTrail → Settings → Import |
| JetLog | JSON export | AirTrail → Settings → Import |
| TripIt | JSON/CSV | AirTrail → Settings → Import |
| Flighty | CSV export | AirTrail → Settings → Import |
| byAir | CSV/JSON | AirTrail → Settings → Import |

## Data sources

AirTrail uses open data for airport information and geography:
- **Airport data**: [OurAirports](https://ourairports.com)
- **Country borders**: GISCO services GeoJSON
- **Country flags**: Flagpedia

## Gotchas

- **`ORIGIN` must match your actual URL.** SvelteKit uses `ORIGIN` for CSRF protection. If it doesn't match the URL you browse to, you'll get CSRF errors on form submissions. Set it to your full public URL (e.g. `https://airtrail.example.com`).
- **Import is one-time.** Imports are additive — importing the same file twice creates duplicate flights. Review before importing, or deduplicate manually.
- **No flight data API.** AirTrail is a manual/import-based tracker. It doesn't connect to live flight data APIs to auto-track flights. You log flights yourself (or import from an app that tracked them).

## Backup

```sh
docker compose exec postgres pg_dump -U airtrail > airtrail-$(date +%F).sql
```

## Upgrade

```sh
docker compose pull && docker compose up -d
# Prisma migrations run automatically
```

## Project health

Active SvelteKit development, PostgreSQL, multi-user, OAuth, 6 import formats. See repo license.

## Flight-tracker-family comparison

- **AirTrail** — SvelteKit, world map, stats, multi-user, OAuth, 6 import formats
- **MyFlightRadar24** — SaaS; gamified; popular; not self-hosted
- **Flighty** — iOS app; not self-hosted
- **JetLog** — simpler self-hosted flight log; no world map visualization; different scope

**Choose AirTrail if:** you want a self-hosted flight log with an interactive world map, statistics, multi-user support, and import from all major flight tracking apps.

## Links

- Repo: <https://github.com/johanohly/AirTrail>
- Docs: <https://airtrail.johan.ohly.dk/docs>
- Demo: <https://demo.airtrail.johan.ohly.dk>
