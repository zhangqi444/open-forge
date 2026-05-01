---
name: Aurral
description: "Self-hosted music discovery and request manager for Lidarr. Docker. Node.js. lklynet/aurral. MusicBrainz artist search, library-aware recommendations, Last.fm/tag trends, scheduled flows, Spotify playlist import, Navidrome integration. MIT."
---

# Aurral

**Self-hosted music discovery and request manager for Lidarr.** Search MusicBrainz, add artists to Lidarr with granular monitoring options, discover new artists based on your library + tags + Last.fm trends, build scheduled dynamic playlists (flows), and import Spotify playlists. Navidrome integration for smart playlists. Safe for your library — main changes go through Lidarr's API; flows write to a separate download area.

Built + maintained by **lklynet**. MIT license.

- Upstream repo: <https://github.com/lklynet/aurral>
- GHCR: `ghcr.io/lklynet/aurral`
- Docs: <https://aurral.org>
- Discord: <https://discord.gg/cpPYfgVURJ>

## Architecture in one minute

- **Node.js** backend + frontend (single container)
- Port **3001**
- Data stored in `/app/backend/data` volume
- Downloads stored in `/app/downloads` volume (separate from main library)
- Talks to **Lidarr** API for music management
- Optional: **Navidrome** for smart playlist exposure
- Resource: **very low** — lightweight Node.js

## Compatible install methods

| Infra      | Runtime                    | Notes                             |
| ---------- | -------------------------- | --------------------------------- |
| **Docker** | `ghcr.io/lklynet/aurral`   | **Primary** — single container    |

## Install via Docker Compose

```yaml
services:
  aurral:
    image: ghcr.io/lklynet/aurral:latest
    restart: unless-stopped
    ports:
      - "3001:3001"
    environment:
      - DOWNLOAD_FOLDER=${DL_FOLDER:-./data/downloads}
    volumes:
      - ${DL_FOLDER:-./data/downloads}:/app/downloads
      - ${STORAGE:-./data}:/app/backend/data
```

```bash
docker compose up -d
```

Visit `http://localhost:3001` and complete onboarding (connect Lidarr, set API keys).

## Inputs to collect

| Input | Phase | Notes |
|-------|-------|-------|
| Lidarr URL + API key | Onboarding | Required — connect to your Lidarr instance |
| Last.fm API key (optional) | Onboarding | For Last.fm-based discovery and trends |
| Navidrome URL + credentials (optional) | Onboarding | For smart playlist integration |

## Features overview

| Feature | Details |
|---------|---------|
| Artist search | Search MusicBrainz; add artists to Lidarr with custom monitor options |
| Monitor options | None, All, Future, Missing, Latest, First — granular per-artist |
| Album requests | Add specific albums from release groups |
| Library browsing | Browse your Lidarr library in Aurral's clean UI |
| Request history | Track queued, downloading, and imported requests |
| Discovery | Daily Discover: library-aware recommendations based on tags, trends, Last.fm data |
| Flows | Dynamic scheduled playlists; auto-refresh on a schedule |
| Flow customization | Adjust Discover / Mix / Trending balance; per-flow timing; weekly or custom days |
| Static playlists | Import JSON playlists; save from flows; edit tracklists in-app |
| Spotify import | Import Spotify playlists via built-in button or [Aurral Convert](https://aurral.org/aurral-convert) helper |
| OPML/JSON export | Export flows to JSON; share and re-import |
| Navidrome integration | Expose Aurral flows as Navidrome smart playlists in `Aurral Weekly Flow` library |
| Safe library separation | Flows/playlists write to a dedicated download folder; main library stays untouched |

## Flows and Playlists explained

**Flows** = dynamic playlists that refresh on a schedule:
- Configure size (number of tracks), source mix (Discover/Mix/Trending ratio), focus filters
- Set refresh schedule (weekly, custom days, specific hours)
- Downloads go to a separate folder, not your main Lidarr library
- If Navidrome is connected, flows appear as smart playlists

**Static Playlists** = fixed tracklists:
- Import from a JSON file (hand-built or exported from a flow)
- Import from Spotify (via the convert helper or built-in button)
- Edit tracklist names and tracks directly in Aurral

## Spotify playlist import

1. Export your Spotify playlist via [Exportify](https://exportify.net/) or use the built-in Aurral Spotify button
2. Use the [Aurral Convert helper](https://aurral.org/aurral-convert) to convert Spotify tracks to MusicBrainz format
3. Import the resulting JSON into Aurral as a static playlist
4. Aurral cross-references against your existing Lidarr library

## Gotchas

- **Lidarr is required.** Aurral is a companion app for Lidarr — not a standalone music manager. You need a working Lidarr instance before setting up Aurral.
- **Flows are in a separate download area.** Flow downloads are intentionally isolated from your main Lidarr library. This is by design — to keep curated playlists separate from your permanent collection. Navidrome can expose both areas.
- **Last.fm API key for discovery.** The best discovery experience uses Last.fm data. Without a Last.fm API key, discovery falls back to library + tags only. Get a free Last.fm API key at last.fm/api.
- **Spotify import is not direct.** There's no direct Spotify API integration — you export from Spotify, convert the format, then import. The conversion helper at aurral.org/aurral-convert simplifies this.

## Backup

```sh
docker compose stop aurral
sudo tar czf aurral-$(date +%F).tgz ./data/
docker compose start aurral
```

## Upgrade

```sh
docker compose pull && docker compose up -d
```

## Project health

Active Node.js development, Lidarr integration, MusicBrainz, Last.fm discovery, Navidrome smart playlists, Spotify import. MIT license.

## Music-request-family comparison

- **Aurral** — Node.js, Lidarr companion, MusicBrainz search, Last.fm discovery, flows/playlists, Navidrome, MIT
- **Lidarr** — Go, the core music download manager Aurral wraps
- **Headphones** — Python, similar Lidarr-predecessor; mostly replaced by Lidarr
- **Navidrome** — Go, music server; Aurral integrates with it for smart playlists

**Choose Aurral if:** you use Lidarr for music and want library-aware artist discovery, scheduled dynamic playlists (flows), Spotify playlist import, and Navidrome smart playlist integration.

## Links

- Repo: <https://github.com/lklynet/aurral>
- Docs: <https://aurral.org>
- Spotify import helper: <https://aurral.org/aurral-convert>
- Discord: <https://discord.gg/cpPYfgVURJ>
