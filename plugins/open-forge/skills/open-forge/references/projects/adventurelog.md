---
name: AdventureLog
description: "Travel tracker + trip planner. Log adventures, mark world map, plan trips collaboratively, share with friends. SvelteKit + Django. GPL-3.0. Active; sole-maintainer-with-sponsors; demo at demo.adventurelog.app."
---

# AdventureLog

AdventureLog is **"Polarsteps / TripIt / Google Maps Timeline — self-hosted and yours"** — a travel companion for logging trips, marking places you've been on a world map, planning future trips collaboratively, and sharing experiences with friends and family. Built by a solo maintainer after years of not finding an open-source, modern, user-friendly travel app. SvelteKit + Django + PostgreSQL.

Built + maintained by **Sean Morley (seanmorley15)** + community. **License: GPL-3.0**. Active; Discord community; demo at demo.adventurelog.app; "sponsor me" funding model + translation community.

Use cases: (a) **personal travel log** — places visited, trips taken, memories attached (b) **world-map visualization** of "countries visited" / "continents covered" / bucket-list (c) **collaborative trip planning** — plan a multi-city trip with partner + friends (d) **escape Polarsteps** (commercial SaaS) / **Google Timeline** (privacy concerns) for travel logging (e) **couple / family travel archive** — build a shared history over years (f) **bucket-list tracking** — mark "want-to-visit" + tick-off when done (g) **privacy-conscious travel logging** — location data stays in your instance.

Features (from upstream + docs):

- **Log adventures** with photos + text + maps
- **World map** with visited locations highlighted
- **Trip planner** — collaboratively build itineraries
- **Collections** — group adventures by theme/trip
- **Sharing** with friends/family
- **Visited countries/regions** tracking
- **OIDC / OAuth** (recent additions)
- **PWA mobile-friendly**
- **Translation support** via Weblate

- Upstream repo: <https://github.com/seanmorley15/AdventureLog>
- Homepage: <https://adventurelog.app>
- Docs: <https://adventurelog.app/docs>
- Demo: <https://demo.adventurelog.app>
- Discord: <https://discord.gg/wRbQ9Egr8C>
- Sponsor: <https://seanmorley.com/sponsor>

## Architecture in one minute

- **SvelteKit** frontend
- **Django** (Python) backend — REST API
- **PostgreSQL** — DB (with PostGIS for geo)
- **Nginx** — frontend
- **Redis** (some setups) — cache/queue
- **Resource**: moderate — 500MB-1GB RAM
- **Port**: 8015 (frontend) + 8016 (backend) default

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker compose** | **Upstream-provided multi-service stack**                       | **Primary**                                                                        |
| Kubernetes         | Community chart                                                           | Homelab k8s                                                                                   |
| Bare-metal         | Django + SvelteKit + Postgres                                                                               | DIY                                                                                               |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `adventure.example.com`                                     | URL          | TLS recommended                                                                                    |
| PG + PostGIS         | Postgres with PostGIS extension enabled                     | DB           | PostGIS required for geo features                                                                                    |
| `SECRET_KEY`         | Django signing                                                                                    | **CRITICAL** | **IMMUTABLE**                                                                                    |
| Admin creds          | First-boot register                                                                           | Bootstrap    | Strong                                                                                    |
| Map tile provider    | OpenStreetMap default; Mapbox if custom                                                                                | Config       | OSM is free+community-respectful; Mapbox is commercial                                                                                                            |
| Photo storage        | Local filesystem or S3                                                                                                            | Storage      | Travel photos can be BIG                                                                                                                            |
| OIDC config          | (optional) SSO provider                                                                                                                            | SSO          | For family-sharing-via-org                                                                                                                                            |

## Install via Docker compose (typical)

See upstream + docs for full compose. Typical stack:

```yaml
services:
  server:
    image: ghcr.io/seanmorley15/adventurelog-server:latest   # **pin version**
    depends_on: [db]
    environment:
      - SECRET_KEY=${SECRET_KEY}
      - PGHOST=db
      - PGDATABASE=database
      - PGUSER=adventure
      - PGPASSWORD=${DB_PASSWORD}
      - FRONTEND_URL=https://adventure.example.com
    volumes:
      - ./adventure-server:/code/media
    ports: ["8016:80"]

  frontend:
    image: ghcr.io/seanmorley15/adventurelog-frontend:latest
    environment:
      - PUBLIC_SERVER_URL=https://adventure-api.example.com
    ports: ["8015:3000"]

  db:
    image: postgis/postgis:15-3.3
    environment:
      - POSTGRES_DB=database
      - POSTGRES_USER=adventure
      - POSTGRES_PASSWORD=${DB_PASSWORD}
    volumes:
      - ./adventure-db:/var/lib/postgresql/data
```

## First boot

1. Start → browse frontend at `:8015`
2. Register admin
3. Log first adventure
4. Add photos + maps
5. Create a trip + invite friends (if collaborative)
6. Put behind TLS reverse proxy
7. Configure OIDC if desired
8. Back up DB + photos

## Data & config layout

- Postgres volume — users, adventures, trips, collections
- `/code/media/` — uploaded photos + attachments
- `.env` — SECRET_KEY + DB + OAuth + Mapbox

## Backup

```sh
docker compose exec db pg_dump -U adventure database > adventure-$(date +%F).sql
sudo tar czf adventure-photos-$(date +%F).tgz adventure-server/
```

## Upgrade

1. Releases: <https://github.com/seanmorley15/AdventureLog/releases>. Active.
2. Docker: pull + migrate.
3. Back up BEFORE major upgrades.

## Gotchas

- **LOCATION-HISTORY IS EXTREMELY PERSONAL**:
  - "Places I've been" = stalking vector if compromised
  - Habit profiling (regular routes, cafes, etc.)
  - Home address often inferred from activity start-point
  - **Treat AdventureLog data as highly-personal** — aligns with Ryot 95 LIFELOG sub-family
  - **46th tool in hub-of-credentials family — Tier 2 with location-specific sensitivity**
- **DV-THREAT-MODEL applies** (SparkyFitness 94, Ryot 95, KitchenOwl 96, Baikal 98): shared-trip feature = partner access to location history → stalking risk in separation scenarios. Recipe convention: document access-removal flow for shared data.
- **LOCATION-HISTORY-IS-LIFELOG-ADJACENT**: AdventureLog aggregates "where you've been". Combined with Ryot (life-tracking) + Garmin-Grafana 98 (fitness + GPS activity) → **TRUE LIFELOG at aggregate level**. Recipe convention: warn when combining multiple data-aggregating tools amplifies LIFELOG-CROWN-JEWEL risk.
- **OSM vs MAPBOX TILES**:
  - **OpenStreetMap**: free, community, slower, usage-policy-aware (respect OSM's tile-usage guidelines for high-volume apps)
  - **Mapbox**: commercial, faster, generous-free-tier, API-key-required, more-customizable
  - For personal use: OSM fine
  - For moderate-load: Mapbox or self-host OSM tiles
  - **Recipe convention: "map-tile-provider selection"** for geo-visualization tools
- **PHOTO UPLOAD STORAGE GROWS UNBOUNDED**: travel photos are large (2-5MB per DSLR photo; 4-8MB per modern phone photo; unhashed HDR = 10+MB). 1000-photo trip → several GB. Plan:
  - Compression on upload (if supported)
  - S3-backed storage for scale
  - Lifecycle policies (auto-archive old)
- **PHOTO EXIF METADATA** = PRIVACY LEAK in shared content:
  - Phone photos embed GPS coordinates in EXIF
  - Sharing a photo = sharing exact location
  - **Strip EXIF on upload if sharing public** (verify AdventureLog does this or do it yourself)
  - **Recipe convention: "EXIF-scrubbing-on-upload"** for photo-sharing tools
- **HUB-OF-CREDENTIALS TIER 2**: users + photos + locations + OIDC tokens + DB creds + map API keys. **46th tool hub-of-credentials.**
- **`SECRET_KEY` IMMUTABILITY** (Django): **34th tool in immutability-of-secrets family.**
- **POSTGIS DEPENDENCY**: requires PG with PostGIS extension. Standard `postgis/postgis` image handles this; vanilla postgres will fail on geo-queries. Common deployment stumble.
- **SOLE-MAINTAINER-WITH-COMMUNITY + sponsor support**: Sean Morley + sponsors + community. **18th tool in sole-maintainer-with-community class**; **2nd tool in sole-maintainer-with-visible-sponsor-support sub-tier** (MediaManager 97 was 1st). Sub-tier solidifying at 2 tools.
- **TRANSPARENT-MAINTENANCE**: GPL-3 + Discord + demo + docs + Weblate translations + active. **38th tool in transparent-maintenance family.**
- **INSTITUTIONAL-STEWARDSHIP**: Sean Morley + sponsors + community. **31st tool in institutional-stewardship.**
- **GPL-3.0**: source disclosure; fine for self-host; not for commercial-SaaS-redistribution.
- **TRIP-PLANNING = CALENDAR-ADJACENT**: AdventureLog trip dates + Baikal's CalDAV events could theoretically sync (future feature? ifttt?). For now they're separate. Recipe: if using both, consider export-import workflows.
- **COLLABORATIVE-PLANNING SHARING**: share a trip planning doc with partner. Access-control + link-expiry + revocation flows matter. Common shared-document-features concerns.
- **ALTERNATIVES WORTH KNOWING:**
  - **Polarsteps** — commercial SaaS; mobile-first; generous free-tier
  - **TripIt** — commercial SaaS; email-forward-based
  - **Wanderer** (batch 91) — hiking/trails-focused; different niche
  - **PhotoMap / Marble** — simpler "where I've been" marker apps
  - **Google Maps Timeline** — Google-integrated; privacy trade-off
  - **Visited (iOS app)** — commercial; beautiful
  - **Ubikarte / OSM-based-tools** — various
  - **Life360 / Find-my-Friends** — family-tracking (different use case)
  - **Choose AdventureLog if:** you want SvelteKit + GPL-3 + self-host + collaborative + rich-features.
  - **Choose Polarsteps if:** you want commercial + mobile-first + auto-tracking.
  - **Choose Wanderer if:** you want hiking + trails focus.
- **PROJECT HEALTH**: active + GPL-3 + sponsor-backed + Discord + demo + sister-projects-ecosystem-emerging. Strong for a sole-maintainer project.

## Links

- Repo: <https://github.com/seanmorley15/AdventureLog>
- Homepage: <https://adventurelog.app>
- Docs: <https://adventurelog.app/docs>
- Demo: <https://demo.adventurelog.app>
- Discord: <https://discord.gg/wRbQ9Egr8C>
- Sponsor: <https://seanmorley.com/sponsor>
- Polarsteps (commercial alt): <https://www.polarsteps.com>
- Wanderer (hiking alt): <https://wanderer.to>
- TripIt (commercial alt): <https://www.tripit.com>
- PostGIS: <https://postgis.net>
