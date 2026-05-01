---
name: SoulSync
description: "Intelligent music discovery & automation platform. Docker. Python. Nezreka/SoulSync. Soulseek + Deezer + Tidal + Qobuz downloads, Spotify/last.fm-style discovery, Plex/Jellyfin/Navidrome integration."
---

# SoulSync

**Intelligent music discovery and automation platform for self-hosted libraries.** Bridges streaming services to your local collection: monitors artists for new releases, generates Release Radar / Discovery Weekly / seasonal playlists, downloads missing tracks from Soulseek/Deezer/Tidal/Qobuz/HiFi/YouTube, enriches metadata via 10 worker sources (Spotify, MusicBrainz, iTunes, Deezer, Discogs, AudioDB, Last.fm, Genius, Tidal, Qobuz), organizes files, and scrobbles plays to Last.fm + ListenBrainz. Integrates with Plex, Jellyfin, Navidrome, or standalone.

Built + maintained by **Nezreka (boulderbadgedad)**. Community on Discord + Reddit.

- Upstream repo: <https://github.com/Nezreka/SoulSync>
- Website: <https://www.ssync.net>
- Discord: <https://discord.gg/wGvKqVQwmy>
- Reddit: <https://old.reddit.com/r/ssync/>
- Docker Hub: `boulderbadgedad/soulsync`
- GHCR: `ghcr.io/nezreka/soulsync`

## Architecture in one minute

- **Python** app + web UI (port **8008**)
- Docker Compose stack (upstream ships `docker-compose.yml`)
- External dependencies bundled in the compose: **slskd** (Soulseek client) on `:5030`
- Download sources: Soulseek (via slskd), Deezer (ARL token), Tidal (OAuth), Qobuz (email+pw), HiFi (public API), YouTube (yt-dlp + cookies)
- AcoustID fingerprinting for download verification; MusicBrainz Picard-style release preflight for album consistency
- Media server integration: Plex, Jellyfin, Navidrome, or SoulSync standalone (no media server required)
- Scrobbling: Last.fm + ListenBrainz (from Plex/Jellyfin/Navidrome play events)

## Compatible install methods

| Infra       | Runtime                         | Notes                                              |
| ----------- | ------------------------------- | -------------------------------------------------- |
| **Docker**  | `boulderbadgedad/soulsync`      | **Primary** — `docker-compose up -d`               |
| Unraid      | Community App                   | Listed in Unraid CA store                          |

## Inputs to collect

| Input                           | Example                       | Phase       | Notes                                                                                     |
| ------------------------------- | ----------------------------- | ----------- | ----------------------------------------------------------------------------------------- |
| Media server URL + token        | Plex/Jellyfin/Navidrome       | Integration | Required for scrobbling + library sync; skip for standalone mode                         |
| Soulseek credentials            | username + password           | Download    | Create a Soulseek account; used by slskd                                                  |
| Deezer ARL token (optional)     | long cookie string            | Download    | From browser cookie; for Deezer FLAC/MP3 downloads                                       |
| Tidal OAuth (optional)          | device-flow — interactive     | Download    | Hi-Res FLAC; setup via SoulSync UI                                                        |
| Qobuz (optional)                | email + password              | Download    | Hi-Res Max FLAC; setup via UI                                                             |
| Spotify API keys (optional)     | Client ID + Secret            | Discovery   | For Spotify playlist imports + artist similarity; not required for basic use              |
| Last.fm API key (optional)      | API key                       | Scrobbling  | For scrobbling + recommendations                                                          |
| Music library path              | `/music`                      | Storage     | Mounted into container; SoulSync organizes files here                                     |
| Domain                          | `music.example.com`           | URL         | Optional — front with reverse proxy + TLS                                                 |

## Install via Docker

```bash
curl -O https://raw.githubusercontent.com/Nezreka/SoulSync/main/docker-compose.yml
docker-compose up -d
```

Visit `http://localhost:8008`.

> ⚠️ **Soulseek ban prevention (from README):** After deploy, configure file sharing in slskd at `http://localhost:5030/shares`. Soulseek requires users to share back or bans their account. Set up shared folders immediately.

## Release channels

| Tag          | Registry        | Use when                                              |
|--------------|-----------------|-------------------------------------------------------|
| `:latest`    | Docker Hub      | Stable — default in upstream compose                  |
| `:dev`       | GHCR            | Nightly; new features early, occasional instability   |
| `:2.x`       | Both            | Pin to exact stable release for reproducibility       |

```yaml
# Switch to dev in docker-compose.yml:
image: ghcr.io/nezreka/soulsync:dev
```

## First boot

1. Deploy stack (`docker-compose up -d`).
2. Visit `http://localhost:8008` (or your domain).
3. **Configure slskd**: go to `http://localhost:5030/shares` → set up shared folders. Required to avoid Soulseek bans.
4. Set your **media server** connection (Plex/Jellyfin/Navidrome) or choose standalone.
5. Configure **download sources**: add Soulseek credentials, Deezer ARL, Tidal OAuth, Qobuz if desired.
6. Set **music library path** in SoulSync settings.
7. Add **watchlist artists** — SoulSync will begin monitoring for new releases.
8. Set up **playlists** (Release Radar, Discovery Weekly, etc.).
9. Configure **metadata sources** + **file organization templates**.
10. Enable **scrobbling** (Last.fm / ListenBrainz) if desired.

## Data & config layout

- Music library: host-mounted volume (path you choose)
- SoulSync config + DB: mounted volume (varies by compose template — check upstream `docker-compose.yml`)
- slskd data: separate volume for Soulseek downloads + queue

## Backup

```sh
# Compose down first to avoid DB mid-write
docker-compose down
sudo tar czf soulsync-$(date +%F).tgz <config_vol>/ <db_vol>/ <music_library>/
docker-compose up -d
```

Contents: **full music library + metadata DB + enriched tags + discovered-artist watchlist**. Music files may include copyrighted material — manage responsibly.

## Upgrade

1. Releases: <https://github.com/Nezreka/SoulSync/releases>
2. `docker-compose pull && docker-compose up -d`

## Gotchas

- **Soulseek sharing is mandatory.** Soulseek bans accounts that don't share. Configure slskd's shared folders at `http://localhost:5030/shares` within minutes of first run — not later, not "when I get around to it."
- **Deezer ARL token expires.** It's a session cookie (not an API key); when it expires, Deezer downloads silently stop. Re-extract from browser and update in SoulSync settings.
- **Tidal device-flow OAuth is interactive.** Can't automate — you'll see a URL + code to approve via Tidal's website; do it once during setup.
- **Legal grey area on download sources.** Deezer/Tidal/Qobuz downloads via client reverse-engineering, and Soulseek P2P sharing, operate in a legal grey zone in most jurisdictions. Users accept responsibility for compliance with local laws and ToS. Open-forge documents how to run the software — not an endorsement.
- **YouTube cookie-based auth** — if you hit bot-detection, provide cookies via yt-dlp cookie file mounted into the container.
- **Spotify API keys for discovery** — Spotify's API requires you to register an app (free). Without it, Spotify-sourced playlists and artist-similarity features are limited.
- **Media server webhook** — Scrobbling from Plex/Jellyfin/Navidrome requires SoulSync to receive play events. Some configurations need the media server and SoulSync on the same Docker network or accessible URL.
- **Two services in the compose.** slskd (Soulseek) runs alongside SoulSync — keep both up for Soulseek downloads to work; slskd can be stopped if you only use streaming-service downloads.
- **File organization templates** — SoulSync moves/renames files on disk. Test your template on a small artist first; a bad template that flattens all files to one directory is hard to undo at scale.
- **Blasphemy Mode** — deletes original FLAC after lossy conversion. Irreversible. Only enable if you're confident about your backup + source availability.
- **`:dev` tag is rebuilt nightly** — pinned dev builds (`ghcr.io/nezreka/soulsync:dev-YYYYMMDD-<sha>`) if you want a known-good snapshot without constantly updating.

## Project health

Active, Discord + Reddit community, Docker Hub + GHCR, Unraid CA, `:dev` nightly builds, rich feature set. Solo-maintained by Nezreka. Rapid development pace — check release notes before upgrading.

## Music-automation-family comparison

- **SoulSync** — discovery + download automation, 6 sources, 10 metadata enrichers, media-server integration, Soulseek-first
- **Lidarr** — Sonarr-family, monitors artists, triggers download clients (NZB/torrent), focuses on indexers
- **Beets** — Python CLI, metadata tagging + library organization, no discovery
- **MusicBrainz Picard** — GUI tagger only
- **Navidrome** — music server (plays music); no download automation
- **Plex + PlexAMP** — plays music + some radio; no download automation

**Choose SoulSync if:** you want Spotify-quality personalized discovery + automated downloads from multiple sources feeding your self-hosted library, and you're comfortable with the legal/ToS grey area.

## Links

- Repo: <https://github.com/Nezreka/SoulSync>
- Website: <https://www.ssync.net>
- Discord: <https://discord.gg/wGvKqVQwmy>
- Lidarr (alt): <https://lidarr.audio>
- Beets (alt): <https://beets.io>
