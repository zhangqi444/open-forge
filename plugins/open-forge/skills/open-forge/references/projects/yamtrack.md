---
name: Yamtrack
description: "Self-hosted media tracker for movies/TV/anime/manga/games/books/comics/board-games. Django; AGPL-3.0; OIDC + 100+ social logins; Jellyfin/Plex/Emby integration; Trakt/Simkl/MyAnimeList/AniList/Kitsu import; iCal; Apprise notifications."
---

# Yamtrack

Yamtrack is **"Trakt + MyAnimeList + Goodreads + BoardGameGeek — but self-hosted + unified + OSS"** — a self-hosted media tracker for **movies, TV shows, anime, manga, video games, books, comics, and board games**. Per-season/per-episode TV tracking. Scores, status, progress, repeats, start/end dates, notes. Tracking-history. Custom media entries for niche content. Collaborative personal lists. iCal-subscribable calendar of upcoming releases. **Apprise notifications** (Discord/Telegram/ntfy/Slack/email/etc.). **Jellyfin + Plex + Emby** integration (auto-track). **Trakt/Simkl/MyAnimeList/AniList/Kitsu** import + periodic automatic. **OIDC + 100+ social logins** (via django-allauth).

Built + maintained by **FuzzyGrim (sole maintainer)**. License: **AGPL-3.0**. Active; Codecov + CodeFactor + CI badges; Docker + Docker Compose; demo at yamtrack.fuzzygrim.com.

Use cases: (a) **unified media-tracking-across-formats** — one place for everything (b) **escape Trakt+MAL+Goodreads separate silos** (c) **Jellyfin/Plex watch-history sync** — auto-track without manual entry (d) **calendar-subscription for upcoming releases** (e) **import from legacy trackers** (Trakt/MAL/AniList) (f) **collaborative watchlists** with friends/family (g) **board-game tracking** (rare in media-trackers) (h) **anime + manga tracking** (specialized vs generic tools).

Features (per README):

- **8 media types**: movies, TV, anime, manga, games, books, comics, **board games**
- **Per-season/per-episode TV tracking**
- Scores, status, progress, repeats, dates, notes
- **Tracking-history**
- **Custom media entries**
- **Collaborative personal lists**
- **iCal calendar subscription**
- **Apprise notifications** (Discord/Telegram/ntfy/Slack/email)
- **SQLite or PostgreSQL**
- **Multi-user**
- **OIDC + 100+ social providers** (django-allauth)
- **Jellyfin/Plex/Emby** auto-track integration
- **Import from Trakt/Simkl/MAL/AniList/Kitsu**
- **CSV export/import**

- Upstream repo: <https://github.com/FuzzyGrim/Yamtrack>
- Demo: <https://yamtrack.fuzzygrim.com> (demo/demo)

## Architecture in one minute

- **Python + Django**
- **SQLite / PostgreSQL**
- **Redis** (optional, for caching)
- **Celery** (task queue, for periodic imports)
- **Resource**: moderate — 500MB-1GB RAM
- **Port**: web UI

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker Compose** | **Upstream**                                                    | **Primary**                                                                        |
| Source             | Django                                                                            | Dev                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `yamtrack.example.com`                                      | URL          | TLS                                                                                    |
| Admin creds          | First-boot                                                  | Bootstrap    | Strong                                                                                    |
| `SECRET_KEY` (Django) | Signing                                                    | **CRITICAL** | **IMMUTABLE**                                                                                    |
| DB                   | SQLite / PostgreSQL                                         | DB           |                                                                                    |
| OIDC / social         | Google / GitHub / Discord / ...                            | Auth         | Optional                                                                                    |
| Jellyfin/Plex/Emby API keys | For auto-track                                      | Integration  |                                                                                    |
| Trakt/Simkl/MAL/AniList/Kitsu | For import                                        | Integration  |                                                                                    |
| Apprise URL          | Notification channels                                                                                                 | Notifications |                                                                                    |

## Install via Docker

```yaml
services:
  yamtrack:
    image: ghcr.io/fuzzygrim/yamtrack:latest        # **pin version**
    environment:
      SECRET_KEY: ${SECRET_KEY}
      DATABASE_URL: postgresql://yamtrack:${DB_PASSWORD}@db:5432/yamtrack
    volumes:
      - yamtrack-data:/app/data
    ports: ["8000:8000"]
    depends_on: [db]

  db:
    image: postgres:17
    environment:
      POSTGRES_DB: yamtrack
      POSTGRES_USER: yamtrack
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes: [pgdata:/var/lib/postgresql/data]

volumes:
  yamtrack-data: {}
  pgdata: {}
```

## First boot

1. Start stack → browse web UI
2. Create admin account; enable 2FA
3. Add media API keys (TMDB, IGDB for games, etc.)
4. Link Jellyfin/Plex/Emby if you have them
5. Import from old tracker (if any)
6. Configure Apprise notifications
7. Subscribe iCal calendar externally
8. Put behind TLS reverse proxy
9. Back up DB + data

## Data & config layout

- PostgreSQL / SQLite — all tracking data
- `/app/data/` — uploads + custom media entries + cache

## Backup

```sh
docker compose exec db pg_dump -U yamtrack yamtrack > yamtrack-$(date +%F).sql
sudo tar czf yamtrack-data-$(date +%F).tgz yamtrack-data/
```

## Upgrade

1. Releases: <https://github.com/FuzzyGrim/Yamtrack/releases>. Active.
2. Django migrations auto-run
3. Docker pull + restart

## Gotchas

- **102nd HUB-OF-CREDENTIALS TIER 2 — INTIMATE-MEDIA-HISTORY**:
  - Full media-history = reveals entertainment preferences, political leanings, religious/sexual-preferences (what you watch/read)
  - Adjacent to BookWyrm (108) reading-data-personal-history
  - **Reading/viewing/watching-data-personal-history-risk sub-family: now 3 tools** (Grimmory+Grimoire+BookWyrm+Yamtrack = 4 tools if we count Grimoire; 3 if BookWyrm subsumed into federated)
  - **102nd tool in hub-of-credentials family — Tier 2**
- **MANY-FEDERATED-SERVICE-TOKENS-STORED**:
  - Trakt / Simkl / MAL / AniList / Kitsu / Jellyfin / Plex / Emby / OIDC / 100+ social
  - Any of these tokens compromised → access to YOUR accounts on those services
  - **Recipe convention: "many-integration-tokens-hub attack-surface"** — applies to aggregators
  - **NEW recipe convention** (Yamtrack 1st formally)
- **DJANGO-ALLAUTH + 100+ SOCIAL PROVIDERS**:
  - django-allauth is a well-maintained Django auth-library
  - 100+ social-login providers pre-supported
  - **Recipe convention: "broad-social-auth-provider-support positive-signal"**
  - **NEW positive-signal convention** (Yamtrack 1st formally)
- **AGPL-3.0 NETWORK-SERVICE**:
  - Self-host + expose = AGPL disclosure
  - **18th tool in AGPL-network-service-disclosure**
- **ICAL CALENDAR SUBSCRIPTION**:
  - Upcoming-releases exportable as .ics
  - Integration with standard calendar apps
  - **Recipe convention: "iCal-export-standard-interop positive-signal"**
  - **NEW positive-signal convention** (Yamtrack 1st formally)
- **APPRISE NOTIFICATION LIBRARY**:
  - Apprise = FOSS multi-channel notification library
  - Standard in modern Python self-hosted tools
  - **Recipe convention: "Apprise-multi-channel-notification positive-signal"** — mature standard
  - **NEW positive-signal convention** (Yamtrack 1st formally)
- **8 MEDIA TYPES = BROAD SCOPE**:
  - Most trackers are single-media (Trakt=TV/movies; MAL=anime; Goodreads=books; BGG=board-games)
  - Yamtrack unifies
  - **Recipe convention: "unified-multi-domain-tool positive-signal"** — integration value
- **CODE-QUALITY BADGES (Codecov + CodeFactor)**:
  - Multiple quality-tracking services
  - **Recipe convention: "multiple-code-quality-trackers positive-signal"** — stronger than single-badge
- **SOLE-MAINTAINER NOTE**:
  - FuzzyGrim is sole-maintainer
  - Sole-maintainer-with-community sub-tier extends
  - **88th tool — sole-maintainer-with-community sub-tier (35th)**
- **CUSTOM MEDIA ENTRIES = FLEXIBILITY**:
  - Track niche-content not in standard APIs
  - **Recipe convention: "custom-entries-for-long-tail positive-signal"**
- **TRAKT/SIMKL/MAL IMPORT**:
  - Migration path from legacy trackers
  - **Recipe convention: "migration-import-paths positive-signal"**
- **INSTITUTIONAL-STEWARDSHIP**: FuzzyGrim + community. **88th institutional-stewardship + sole-maintainer-with-community sub-tier.**
- **TRANSPARENT-MAINTENANCE**: active + CI + Codecov + CodeFactor + AGPL + releases + demo + Docker + django-allauth-standard. **96th tool in transparent-maintenance family.**
- **MEDIA-TRACKER-CATEGORY:**
  - **Yamtrack** — 8 types; Django; Apprise
  - **Trakt** (commercial) — TV/movies
  - **MyAnimeList** — anime/manga
  - **Goodreads** (Amazon) — books
  - **BoardGameGeek** — board games
  - **IGDB** (commercial) — games DB
  - **Ryot** — OSS; similar scope
  - **MediaTracker** — OSS; fewer types
- **ALTERNATIVES WORTH KNOWING:**
  - **Ryot** — if you want alt OSS media tracker
  - **Trakt** — if you want just TV/movies + community network
  - **Choose Yamtrack if:** you want 8-types unified + Jellyfin/Plex/Emby sync + self-hosted.
- **PROJECT HEALTH**: active + sole-maintainer + CI + Codecov + demo + Docker + AGPL. Strong for solo project.

## Links

- Repo: <https://github.com/FuzzyGrim/Yamtrack>
- Demo: <https://yamtrack.fuzzygrim.com>
- Ryot (alt): <https://github.com/IgnisDa/ryot>
- MediaTracker (alt): <https://github.com/bonukai/MediaTracker>
- Apprise: <https://github.com/caronc/apprise>
- django-allauth: <https://github.com/pennersr/django-allauth>
