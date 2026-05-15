---
name: Ryot
description: "\"Roll your own tracker\" — self-hosted life-tracking platform. Movies, shows, books, games, music, anime, podcasts, fitness, exercise. Rust backend + React frontend. Pro Features commercial tier. GPL-3.0. Active + growing."
---

# Ryot

Ryot is **"a single self-hosted tracker for everything you consume"** — a universal tracking platform covering movies + shows + books + video games + music + anime + podcasts + measurements + exercises + fitness. Instead of juggling Letterboxd for movies, Goodreads for books, HowLongToBeat for games, Trakt for TV, Strong for workouts, MyFitnessPal for food, Last.fm for music — you run Ryot and log everything in one place. Rust backend for performance, React frontend for modern UX.

Built + maintained by **Diptesh Choudhuri (IgnisDa)** + community. **License: GPL-3.0** (core); **Pro Features** commercial tier at ryot.io. Active development + Discord community + docs.ryot.io.

Use cases: (a) **personal lifelog / tracker** — everything you consume in one place (b) **replace multiple commercial trackers** — Letterboxd + Goodreads + Trakt + Strong + etc. in one app (c) **quantified-self enthusiasts** — fitness + reading + viewing stats with trends (d) **escape commercial-tracker lock-in** — Goodreads (Amazon-owned), Letterboxd, Trakt → self-host (e) **privacy-focused alternative** — no ads, no data harvesting (f) **family tracking hub** — each family member on one instance (g) **data-portable lifelog** — own your entire consumption history as structured data.

Features (from upstream README + docs):

- **Many media types**: movies, shows, books, video games, music, anime, podcasts, manga, visual novels, sleep, measurement
- **Fitness tracking**: workouts, exercises (standalone + interlinked with media)
- **External metadata** via TMDb, IGDB, Google Books, AniList, MAL, MusicBrainz, Listenbrainz, Audible, etc.
- **Import from** Trakt, Letterboxd, Goodreads, Audible, MyFitnessPal, Strong, Hevy, etc.
- **Mobile-friendly PWA** frontend
- **Docker deploy** — docker-compose.yml provided upstream
- **Pro Features commercial tier** — additional features at ryot.io
- **Demo available** at demo.ryot.io

- Upstream repo: <https://github.com/IgnisDa/ryot>
- Homepage / Pro: <https://ryot.io>
- Docs: <https://docs.ryot.io>
- Live demo: <https://demo.ryot.io/_s/acl_vUMPnPirkHlT>
- Discord: <https://discord.gg/D9XTg2a7R8>
- Docker Hub: <https://hub.docker.com/r/ignisda/ryot>
- Releases: <https://github.com/IgnisDa/ryot/releases>

## Architecture in one minute

- **Rust** backend — fast + memory-safe
- **React** frontend
- **PostgreSQL** — primary DB
- **Resource**: moderate — 300-800MB RAM; scales with user count + tracked-item count
- **Port 8000** default

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker compose** | **Upstream-provided `docker-compose.yml`**                      | **Primary path**                                                                   |
| Docker standalone  | `ignisda/ryot:v10.3.0`                                                     | Simpler single-container                                                                                   |
| Bare-metal Rust    | Clone + build with cargo                                                                                   | For Rust-adjacent dev                                                                                               |
| Pro (commercial)   | ryot.io hosted                                                                                                | If you don't want to self-host                                                                                                 |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `ryot.example.com`                                          | URL          | TLS recommended                                                                                    |
| DB                   | PostgreSQL                                                  | DB           | Ryot's only DB                                                                                    |
| Admin creds          | First-boot registration                                                                           | Bootstrap    | Strong password                                                                                    |
| Secret keys          | JWT signing + session                                                                                  | **CRITICAL** | **IMMUTABLE**                                                                                                            |
| External API keys    | TMDb, IGDB, Google Books, etc.                                                                                 | Auth         | For external metadata lookup                                                                                                            |
| SMTP                 | User notifications                                                                                                        | Email        | Nice-to-have                                                                                                                            |

## Install via Docker (upstream quick-start)

```yaml
services:
  ryot-db:
    restart: unless-stopped
    image: postgres:18-alpine
    environment:
      - POSTGRES_PASSWORD=${DB_PASSWORD}
      - POSTGRES_DB=ryot
      - POSTGRES_USER=ryot
    volumes:
      - ./ryot-db:/var/lib/postgresql/data

  ryot:
    image: ignisda/ryot:v10.3.0    # **pin specific version in prod**
    restart: unless-stopped
    environment:
      - DATABASE_URL=postgres://ryot:${DB_PASSWORD}@ryot-db:5432/ryot
      - DEFAULT_MAL_CLIENT_ID=${MAL_ID}       # optional
      - RUST_LOG=info
    ports: ["8000:8000"]
    depends_on: [ryot-db]
```

## First boot

1. Start → browse `http://host:8000` → register admin
2. Configure external metadata APIs (TMDb etc.)
3. Import your data from existing services (Trakt, Letterboxd, Goodreads, etc.)
4. Start logging consumption
5. Explore Fitness section if using that
6. Put behind TLS reverse proxy
7. Back up DB

## Data & config layout

- Postgres volume — everything (users + tracked items + metadata cache + fitness logs)
- No file uploads in a typical deployment (metadata is external + cached)

## Backup

```sh
docker compose exec ryot-db pg_dump -U ryot ryot > ryot-$(date +%F).sql
```

## Upgrade

1. Releases: <https://github.com/IgnisDa/ryot/releases>. Active.
2. Docker: pull + restart; migrations run on startup.
3. Back up DB BEFORE major upgrades.

## Gotchas

- **LIFELOG DATA = EXTREMELY PERSONAL**: Ryot tracks:
  - What movies + shows + books you consume
  - Reading history (political books, self-help, medical research)
  - Music taste
  - Exercise + body metrics (weight, measurements)
  - Sleep patterns
  - Potentially food/nutrition (if using food-tracking)
  - **Aggregate: probably more personal than any single app** — a complete profile of your daily life
  - **45th tool in hub-of-credentials family — CROWN-JEWEL sub-family "LIFELOG"** (new; 1st tool)
  - Overlaps with HEALTHCARE-CROWN-JEWEL (SparkyFitness 94) — fitness tracking subset
  - Overlaps with intellectual-interests-profiling (Kavita, Calibre, LinkAce, bookmark-tools)
  - **Unique: all in one place = more leverage than fragmented individually**
- **THREAT MODEL escalates with aggregation**: Letterboxd knows your movies; Goodreads knows your books; Strong knows your workouts. Each separately is not-that-bad. **Ryot aggregates all of them → one breach exposes your ENTIRE consumption profile.** Security posture must be rigorous:
  - Strong auth + MFA
  - TLS + reverse proxy
  - Backups (encrypted)
  - Regular-security-updates
  - Limit public-facing exposure
- **FAMILY-ACCESS vs SINGLE-USER**: Ryot supports multi-user. Family-access DV-threat-model (from SparkyFitness 94) applies: reading history can reveal private interests (mental health, sexuality research, etc.) — don't assume family members want shared visibility.
- **IMPORT DATA PROVENANCE + PORTABILITY**: Ryot imports from commercial services — your data ends up replicated. If you delete from Letterboxd but it's still in Ryot, what's your current source-of-truth? Design a data-flow before importing bulk.
- **EXTERNAL API RATE LIMITS**: TMDb + IGDB + Google Books + AniList etc. all rate-limit. Ryot caches + batches; don't aggressively bulk-import or you'll hit limits.
- **HUB-OF-CREDENTIALS TIER 2 (AGGREGATE) + LIFELOG sub-family (NEW)**: **Recipe convention: when aggregation of personal data across multiple domains creates a lifelog-profile, flag as LIFELOG-crown-jewel sub-family.** Applicable to: Ryot, certain Home-Assistant-history dumps, Immich-with-full-life-photos, combined-Nextcloud-plus-Immich-plus-Paperless setups.
- **`JWT_SECRET` / signing-key IMMUTABILITY**: **30th tool in immutability-of-secrets family.**
- **COMMERCIAL-TIER**: **open-core / "Pro Features commercial"** at ryot.io. Core is GPL-3 + self-host; Pro tier adds features (backup, priority, cloud-hosted, etc.). **15+th commercial-tier entry (open-core variant).**
- **INSTITUTIONAL-STEWARDSHIP**: IgnisDa (Diptesh) + community + commercial-tier funding. **21st tool in institutional-stewardship — sole-founder-with-commercial-backing sub-tier**. Similar to LinkAce's Kovah (batch 95) + Kaneo's Andrejs (batch 93) pattern.
- **FITNESS TRACKING OVERLAP with SparkyFitness**: Ryot's fitness features overlap with SparkyFitness 94. Ryot is more general-lifelog; SparkyFitness is fitness-specialized. Pick based on primary use case. Not redundant if you have enough data + different-specialty-features matter.
- **PWA vs NATIVE MOBILE APPS**: Ryot's mobile experience is PWA (Progressive Web App) — browser-installable, works offline-ish. SparkyFitness has native iOS/Android apps — deeper platform integration. Pick based on your mobile needs.
- **TRANSPARENT-MAINTENANCE**: GPL-3 + active-releases + Discord + demo + commercial-backing-for-sustainability + docs. **25th tool in transparent-maintenance family.**
- **SOLE-MAINTAINER-with-commercial-backing sub-tier reinforced**: Ryot joins Kaneo (93) + LinkAce (95) as sole-maintainer projects with commercial-Cloud-funding sustainability. **Now 3 tools in this sub-tier; pattern naming-worthy.**
- **GPL-3.0**: source disclosure for modifications; fine for self-host + internal.
- **DATA EXPORT / PORTABILITY**: GPL-3 + open-source means your data is technically portable via DB dump. Verify structured-export features in UI for easier migration.
- **ALTERNATIVES WORTH KNOWING:**
  - **Trakt** — commercial SaaS; movies + shows; network-effects; freemium
  - **Letterboxd** — commercial SaaS; movies-only; polished community
  - **Goodreads** — Amazon-owned; books; shutting-features-slowly
  - **Bookwyrm** — decentralized book-tracking; AGPL; federated (ActivityPub)
  - **HowLongToBeat** — commercial; games
  - **AniList / MyAnimeList** — commercial; anime/manga
  - **Last.fm** / **Listenbrainz** — music scrobbling (Listenbrainz is OSS by MetaBrainz)
  - **Strong / Hevy** — commercial; workouts
  - **SparkyFitness** (batch 94) — self-hosted fitness-specialized
  - **Oku** — self-hosted book tracker; newer
  - **Kyoo** — different niche (self-hosted streaming)
  - **Choose Ryot if:** you want ALL-IN-ONE + self-host + active + commercial-backing + GPL-3.
  - **Choose specialists if:** you want best-of-breed in one domain (Bookwyrm for books + ActivityPub, SparkyFitness for fitness, etc.).
  - **Choose Trakt/Letterboxd if:** you accept commercial + want network-effects (seeing what friends watched).
- **PROJECT HEALTH**: active + Rust + GPL-3 + Pro-tier funding + Discord + demo + many import-sources + multi-domain scope. Strong signals.

## Links

- Repo: <https://github.com/IgnisDa/ryot>
- Homepage: <https://ryot.io>
- Docs: <https://docs.ryot.io>
- Demo: <https://demo.ryot.io/_s/acl_vUMPnPirkHlT>
- Discord: <https://discord.gg/D9XTg2a7R8>
- Pro Features: <https://ryot.io/features>
- Docker: <https://hub.docker.com/r/ignisda/ryot>
- Trakt (alt, commercial): <https://trakt.tv>
- Letterboxd (alt, movies): <https://letterboxd.com>
- Bookwyrm (alt, books federated): <https://joinbookwyrm.com>
- Listenbrainz (alt, music OSS): <https://listenbrainz.org>
- Goodreads (alt, commercial books): <https://www.goodreads.com>
- AniList (alt, anime): <https://anilist.co>
