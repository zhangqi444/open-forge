---
name: Watcharr
description: "Self-hosted watched list for movies and TV shows. Docker. Go + Svelte. sbondCo/Watcharr. Local DB, Jellyfin/Plex/Emby sync, activity feed, custom lists, tags, filters, offline-capable PWA."
---

# Watcharr

**Self-hosted application to track movies and TV shows you've watched.** Mark content as watched/watching/planned/dropped; rate, review, tag, and filter your library. Syncs watched status from Jellyfin, Plex, and Emby. Multi-user, activity feed, custom lists, season/episode-level tracking, offline-capable PWA. TMDB for metadata. No subscription, no tracking, your data.

Built + maintained by **sbondCo**. MIT license.

- Upstream repo: <https://github.com/sbondCo/Watcharr>
- Docs: <https://watcharr.app/docs>
- Docker Hub: <https://hub.docker.com/r/sbondco/watcharr>
- GHCR: `ghcr.io/sbondco/watcharr`
- Discord: <https://discord.gg/rDW3pqRnnS>

## Architecture in one minute

- **Go** backend + **Svelte** frontend
- **SQLite** database (stored in `/data` volume)
- Port **3080** inside container
- **TMDB API** for movie/TV metadata (free API key required)
- Optional: **Jellyfin / Plex / Emby** integration for syncing watched status
- PWA — installable on any device; offline access to your list
- Resource: **low** — Go binary + SQLite

## Compatible install methods

| Infra        | Runtime                       | Notes                                            |
| ------------ | ----------------------------- | ------------------------------------------------ |
| **Docker**   | `ghcr.io/sbondco/watcharr`    | **Primary** — GHCR + Docker Hub                  |

## Inputs to collect

| Input                            | Example                           | Phase    | Notes                                                                                         |
| -------------------------------- | --------------------------------- | -------- | --------------------------------------------------------------------------------------------- |
| TMDB API key                     | from themoviedb.org               | Config   | **Required** for metadata. Free at: <https://www.themoviedb.org/settings/api>                |
| Domain                           | `watchlist.example.com`           | URL      | Reverse proxy + TLS                                                                           |
| Jellyfin/Plex/Emby (optional)    | URL + API key / token             | Sync     | Sync watched status bidirectionally                                                           |

## Install via Docker

```yaml
services:
  watcharr:
    image: ghcr.io/sbondco/watcharr:v3.0.1
    container_name: watcharr
    ports:
      - "3080:3080"
    volumes:
      - ./watcharr-data:/data
    environment:
      - TMDB_KEY=your_tmdb_api_key_here
    restart: unless-stopped
```

```bash
docker compose up -d
```

Visit `http://localhost:3080`.

## First boot

1. Set `TMDB_KEY` in environment before starting.
2. Deploy container.
3. Visit `http://localhost:3080` → create admin account.
4. Configure **server settings** (admin panel):
   - Base URL (for PWA install links)
   - Jellyfin/Plex/Emby integration credentials
   - Registration settings (open or invite-only)
5. Search for a movie or show → add to your list with a status.
6. Install as **PWA** for offline access.
7. Put behind TLS.

## Status types

| Status | Icon | Meaning |
|--------|------|---------|
| **Watched** | ✅ | Completed |
| **Watching** | 👁️ | Currently watching |
| **Planned** | 🔖 | Want to watch |
| **Hold** | ⏸️ | On hold |
| **Dropped** | 🚫 | Stopped watching |

## Features overview

| Feature | Details |
|---------|---------|
| Content search | Search TMDB; add movies + TV shows to your list |
| Status tracking | Watched / Watching / Planned / Hold / Dropped |
| Ratings | 0–10 star rating per title |
| Reviews | Write text reviews per title |
| Tags | Custom tags; filter by tag |
| Season/episode | Track watched at season or episode level (TV shows) |
| Custom lists | Create named lists beyond the default status categories |
| Activity feed | Timeline of your recent additions + status changes |
| Multi-user | Each user has their own list; admin manages users |
| Jellyfin sync | Mark as watched in Watcharr ↔ Jellyfin |
| Plex sync | Same (Plex Pass required for webhooks; polling otherwise) |
| Emby sync | Same |
| PWA | Install on iOS/Android/desktop; offline list access |
| Filters | Filter by status, genre, tag, rating, year, etc. |
| Upcoming | See upcoming releases for content on your list |
| Notifications | Bell alerts for upcoming releases |

## Data & config layout

- `./watcharr-data/` — SQLite DB (all lists, ratings, reviews, users, tags)

## Backup

```sh
docker compose stop watcharr
sudo tar czf watcharr-$(date +%F).tgz watcharr-data/
docker compose start watcharr
```

## Upgrade

1. Releases: <https://github.com/sbondCo/Watcharr/releases>
2. `docker compose pull && docker compose up -d`

## Gotchas

- **TMDB API key is required.** All content search and metadata (posters, descriptions, ratings) comes from The Movie Database. Register at tmdb.org → API → Request an API Key — free for personal use. Without it, no search results.
- **Plex sync via webhooks requires Plex Pass.** Same limitation as WatchState — Plex webhooks are a Plex Pass feature. Without Plex Pass, sync uses polling.
- **Episode-level tracking is optional.** By default, marking a TV show as watched marks the whole show. Enable episode-level tracking per show if you want granular season/episode status.
- **Multi-user with isolated lists.** Each user has their own completely separate watch list. No shared "household" list view — but the activity feed shows recent additions across users (configurable).
- **PWA offline access = cached list.** You can view your list offline; searching for new content requires network (TMDB call). The Go backend uses a local TMDB cache to reduce API calls.
- **TMDB image CDN.** Poster images load from TMDB's CDN. Cached locally after first load; requires internet on first access.
- **Base URL setting matters for PWA.** Set your public URL in admin settings so PWA manifests and share links generate correctly.
- **Custom lists complement status filters.** Use custom lists for things like "Watch with kids", "Film club picks", "Must rewatch" — beyond the default 5 statuses.

## Project health

Active Go + Svelte development, Docker Hub + GHCR, Discord, docs site, Jellyfin + Plex + Emby integration, PWA. Solo-maintained by sbondCo. MIT license.

## Watch-tracking-family comparison

- **Watcharr** — Go + Svelte, SQLite, Jellyfin/Plex/Emby sync, PWA, multi-user, tags, MIT
- **Letterboxd** — SaaS, film-focused (movies only), social feed; not self-hosted
- **Simkl** — SaaS, movies + TV + anime, media server sync; not self-hosted
- **Trakt** — SaaS, movies + TV, media player scrobbling; not self-hosted
- **Stash** — self-hosted media library manager; adult-content focused; different scope
- **Jellyfin** — media server with built-in watched tracking; not a dedicated tracking app

**Choose Watcharr if:** you want a clean, self-hosted watch-tracker for movies and TV with Jellyfin/Plex/Emby sync, episode tracking, ratings, and a PWA — without giving your data to Letterboxd or Trakt.

## Links

- Repo: <https://github.com/sbondCo/Watcharr>
- Docs: <https://watcharr.app/docs>
- Docker Hub: <https://hub.docker.com/r/sbondco/watcharr>
- TMDB API key: <https://www.themoviedb.org/settings/api>
- Discord: <https://discord.gg/rDW3pqRnnS>
