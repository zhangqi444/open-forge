---
name: Agregarr
description: "Self-hosted Plex Collections manager that keeps your Home and Recommended screens fresh. Docker. Next.js. agregarr/agregarr. Integrates Trakt, IMDb, TMDB, Letterboxd, MDBList, FlixPatrol, AniList, MyAnimeList, Tautulli, Overseerr, Radarr, Sonarr. GPL-3.0."
---

# Agregarr

**Keep your Plex Home and Recommended screens dynamic.** Agregarr automatically builds and refreshes Plex Collections from dozens of sources — Trakt, IMDb, TMDB, Letterboxd, MDBList, FlixPatrol Networks Top 10, AniList, MyAnimeList, Tautulli stats, and Overseerr requests. Controls which collections appear on Home/Recommended, when they're visible, and can download missing media via Radarr/Sonarr/Overseerr.

Built + maintained by **agregarr**. GPL-3.0. Inspired by Kometa and built on Overseerr.

- Upstream repo: <https://github.com/agregarr/agregarr>
- Docs: <https://agregarr.org/docs/installation>
- Docker Hub: `agregarr/agregarr`

## Architecture in one minute

- **Next.js** full-stack (App Router)
- **Config volume** — all settings stored in `/app/config`
- Port **7171**
- Optional media volumes (`/data/movies`, `/data/tv`) for Coming Soon / Placeholder feature
- No external database required — config-file based
- Resource: **low** — Node.js, minimal overhead
- Connects to: Plex, Trakt, IMDb, TMDB, Letterboxd, MDBList, FlixPatrol, AniList, MyAnimeList, Tautulli, Overseerr, Radarr, Sonarr

## Compatible install methods

| Infra      | Runtime              | Notes                                           |
| ---------- | -------------------- | ----------------------------------------------- |
| **Docker** | `agregarr/agregarr`  | **Primary** — single container; config volume   |

## Install via Docker

```yaml
services:
  agregarr:
    image: agregarr/agregarr:latest
    container_name: agregarr
    volumes:
      - ./agregarr-config:/app/config
      # Optional: for Coming Soon / Placeholder feature
      # - /path/to/placeholder/movies:/data/movies
      # - /path/to/placeholder/tv:/data/tv
    environment:
      - TZ=America/New_York  # Set to your timezone
    ports:
      - "7171:7171"
    restart: unless-stopped
```

```bash
docker compose up -d
```

Visit `http://localhost:7171` → complete initial setup.

## Environment variables

| Variable | Required | Notes |
|----------|----------|-------|
| `TZ` | Recommended | Your local timezone (e.g. `America/New_York`, `Europe/London`). Used for accurate poster overlay dates/countdowns in Coming Soon collections. See [tz database](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones) for values. |

> All other configuration (Plex token, Trakt/IMDb/etc. API keys, Radarr/Sonarr/Overseerr URLs) is done through the web UI.

## Sources & integrations

| Source | Collection type |
|--------|----------------|
| **Trakt** | Public lists, trending, popular, anticipated, watchlists |
| **IMDb** | Public lists, top charts |
| **TMDB** | Public lists, trending, popular |
| **Letterboxd** | Public lists |
| **MDBList** | Public lists |
| **FlixPatrol** | Networks Top 10 (Netflix, Disney+, etc.) |
| **AniList** | Anime lists and rankings |
| **MyAnimeList** | Anime lists and rankings |
| **Tautulli** | Most popular content on your Plex server |
| **Overseerr** | All requests; per-user request collections |
| **Radarr** | Download missing movies from collections |
| **Sonarr** | Download missing TV shows from collections |

## Features overview

| Feature | Details |
|---------|---------|
| Auto-refreshing collections | Collections updated on every sync (default: every 12 hours) |
| Home/Recommended management | Control which collections appear on Plex Home and Recommended screens |
| Independent reordering | Order collections separately for Home/Recommended vs Library tab |
| Time restrictions | Schedule collections to be active only during specific time periods |
| Visibility scheduling | Set custom days/periods per collection |
| Randomise home order | Rotate home screen collection order on a schedule |
| Grab missing media | Add missing items via Radarr/Sonarr or Overseerr |
| Download filters | Filter by release year, season count, list position, genre, origin country |
| Coming Soon collections | Collections from Radarr/Sonarr monitored content + anticipated Trakt releases |
| Poster overlays | Countdown timers and release date overlays on Coming Soon posters |
| Placeholder media | Fake media entries in Plex for coming-soon content (requires media volumes) |
| Poster templates | Create custom poster templates filled dynamically per collection |
| Preview collections | Preview matching/missing items; add individually to Radarr/Sonarr/Overseerr |
| Collection statistics | Dashboard with Most Popular Collections and recent missing items |
| Exclusion list | Globally exclude specific items from all grab operations |
| Existing collection integration | Manage pre-existing Plex Collections and Default Hubs alongside Agregarr |
| Custom sync scheduling | Override per-collection sync interval |
| Template system | Set collection names with flexible templating and title importing |

## Inputs to collect

| Input | Notes |
|-------|-------|
| Plex URL + token | Required — connect Agregarr to your Plex server |
| Source API keys | Trakt, TMDB, Letterboxd, MDBList, etc. — add only what you use |
| Overseerr URL + API key | Optional — for request-based collections and media requests |
| Tautulli URL + API key | Optional — for Most Popular collections based on play statistics |
| Radarr/Sonarr URLs + API keys | Optional — for downloading missing media |
| Timezone | Set in environment; used for poster countdown overlays |

## Coming Soon / Placeholder volumes

```yaml
volumes:
  - /path/to/placeholder/movies:/data/movies
  - /path/to/placeholder/tv:/data/tv
```

Add these folders to Plex, but **not** to Radarr/Sonarr. Agregarr creates placeholder files that Plex can display; real media replaces them when downloaded.

## Gotchas

- **Config volume must be set correctly.** If Agregarr resets after restart, the config is not persisting. Double-check your volume path — use an absolute path for reliability.
- **Coming Soon feature requires media volumes.** If you don't mount the media volumes, Agregarr can still run and all other features work. Only the Coming Soon / Placeholder feature requires mounted volumes.
- **Timezone matters for poster overlays.** Set `TZ` to your local timezone — it's used for accurate release date and countdown overlays on Coming Soon posters.
- **Develop branch is default.** The main development branch is `develop`. The repo README lives on `develop` — if you see 404s fetching the default branch via API, check `develop`.
- **No external database.** Agregarr stores config in `/app/config` — no separate database container needed.
- **GPL-3.0 license.** Modifications must be released under GPL-3.0.

## Backup

```sh
cp -r ./agregarr-config agregarr-config-$(date +%F)
```

## Upgrade

```sh
docker compose pull && docker compose up -d
```

## Project health

Active Next.js development, rich source integrations (10+ sources), Plex ecosystem, GPL-3.0.

## Plex-automation-family comparison

- **Agregarr** — Next.js, Plex Collections manager, 10+ sources, Home/Recommended control, Coming Soon, GPL-3.0
- **Kometa (formerly PMM)** — Python, Plex Meta Manager, collections + overlays + playlists; broader but CLI-only; MIT
- **Plex-Meta-Manager** → now Kometa
- **Letterboxd Sync** — single-purpose Letterboxd → Plex collections

**Choose Agregarr if:** you want a web UI to automatically keep your Plex Home and Recommended screens fresh with collections from Trakt, IMDb, TMDB, Letterboxd, AniList, and more — with automatic missing media downloads.

## Links

- Repo: <https://github.com/agregarr/agregarr>
- Docs: <https://agregarr.org/docs/installation>
- Placeholder volumes guide: <https://agregarr.org/docs/placeholder-volumes>
