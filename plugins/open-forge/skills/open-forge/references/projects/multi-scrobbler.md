---
name: Multi-Scrobbler
description: "Self-hosted multi-source music scrobbler. Docker. Node.js. FoxxMD/multi-scrobbler. Monitors Spotify, Plex, Jellyfin, Navidrome, YouTube Music, Kodi, MPD, VLC, Last.fm (50+ sources); scrobbles to Last.fm, ListenBrainz, Maloja, Discord, Koito. MIT."
---

# Multi-Scrobbler

**Self-hosted multi-source, multi-destination music scrobbler.** Monitor your music playback from 25+ sources (Spotify, Plex, Jellyfin, Navidrome, YouTube Music, Kodi, MPD, VLC, Last.fm/ListenBrainz forwarding, Chromecast, Sonos, etc.) and scrobble to 8+ clients (Last.fm, ListenBrainz, Maloja, Libre.fm, Discord Now Playing, Koito, Rocksky, teal.fm). Web UI for status monitoring and control. Queue-based with retry on failure. Multi-user support.

Built + maintained by **FoxxMD**. MIT license.

- Upstream repo: <https://github.com/FoxxMD/multi-scrobbler>
- Docker Hub: <https://hub.docker.com/r/foxxmd/multi-scrobbler>
- Docs: <https://docs.multi-scrobbler.app/>

## Architecture in one minute

- **Node.js** Docker container
- Config: `config/` directory (JSON files) or environment variables
- Web UI on port **9078** (status, logs, control)
- Prometheus metrics endpoint (optional)
- Resource: **very low** — lightweight Node.js daemon

## Compatible install methods

| Infra      | Runtime                     | Notes                                  |
| ---------- | --------------------------- | -------------------------------------- |
| **Docker** | `foxxmd/multi-scrobbler`    | **Primary** — multi-arch (x86/ARM)     |

## Install via Docker Compose

```yaml
services:
  multi-scrobbler:
    image: foxxmd/multi-scrobbler:latest
    container_name: multi-scrobbler
    restart: unless-stopped
    environment:
      - TZ=America/Chicago
    ports:
      - "9078:9078"
    volumes:
      - ./config:/config
      - ./logs:/logs
```

```bash
docker compose up -d
```

Visit `http://localhost:9078`.

## Music sources supported

| Category | Sources |
|----------|---------|
| **Streaming** | Spotify, Deezer, YouTube Music, teal.fm |
| **Media servers** | Plex, Jellyfin, Navidrome/Subsonic, Airsonic, Mopidy, JRiver |
| **Desktop players** | VLC, MPD (Music Player Daemon), MPRIS (Linux desktop), Musikcube |
| **Smart audio** | Sonos, Yamaha MusicCast, Google Cast / Chromecast |
| **Radio/Streaming** | Azuracast, Icecast |
| **Scrobble services** | Last.fm, Libre.fm, ListenBrainz, Maloja (forward/mirror) |
| **Other** | WebScrobbler (browser extension endpoint), Rocksky, Koito, Music Assistant |

## Scrobble clients (destinations)

| Client | Type |
|--------|------|
| Last.fm | Scrobbling |
| ListenBrainz | Scrobbling |
| Maloja | Scrobbling (self-hosted) |
| Libre.fm | Scrobbling |
| Koito | Scrobbling |
| Rocksky | Scrobbling |
| teal.fm | Scrobbling |
| Discord | Now Playing status |

## Inputs to collect

Configuration is done via JSON files in the `./config/` directory.

| Config file | Purpose |
|-------------|---------|
| `config.json` | Global settings |
| `sources.json` | One entry per music source |
| `clients.json` | One entry per scrobble destination |

Or use **environment variables** for simple single-source setups (e.g. `SPOTIFY_CLIENT_ID`, `LASTFM_API_KEY`). See docs for the full list.

## Config example (Spotify → Last.fm)

`config/sources.json`:
```json
[{
  "type": "spotify",
  "name": "my-spotify",
  "data": {
    "clientId": "YOUR_CLIENT_ID",
    "clientSecret": "YOUR_CLIENT_SECRET",
    "redirectUri": "http://localhost:9078/callback"
  }
}]
```

`config/clients.json`:
```json
[{
  "type": "lastfm",
  "name": "my-lastfm",
  "data": {
    "apiKey": "YOUR_API_KEY",
    "secret": "YOUR_SECRET"
  }
}]
```

## Advanced features

| Feature | Details |
|---------|---------|
| Multi-user | Run separate source configs for different users; silo plays to separate clients |
| Source → client routing | Optionally specify which clients a source forwards to |
| Transform rules | Modify track data with regex before scrobbling (fix artist names, etc.) |
| Now Playing | Discord and some clients show "currently listening" status |
| Webhook notifications | Gotify, Ntfy, Apprise for source/client health alerts |
| Healthcheck endpoint | `/health` for uptime monitors |
| Prometheus metrics | `/metrics` for Grafana/Prometheus stack |
| Retry queue | Scrobbles queue and auto-retry on network/client failures |

## Gotchas

- **Spotify OAuth requires a redirect URI.** You need to create a Spotify developer app at [developer.spotify.com](https://developer.spotify.com/) and set the redirect URI to `http://<your-host>:9078/callback`. The web UI guides you through the OAuth flow.
- **Last.fm/ListenBrainz need API keys.** Register apps at last.fm/api/account/create and listenbrainz.org/settings/api-tokens. Multi-scrobbler handles the OAuth flow via the web UI.
- **Sources need to be reachable.** For Plex/Jellyfin webhooks, multi-scrobbler must be reachable from those services. For polling-based sources (Spotify, Subsonic), multi-scrobbler polls the API.
- **MPRIS requires Linux desktop.** The MPRIS source hooks into the D-Bus session bus — it must run on the same Linux desktop machine as the music player. Not useful in a server Docker deployment.
- **Transform rules use regex.** The transform system is powerful (fix artist names, strip featuring artists, etc.) but requires regex knowledge. See the docs for examples.

## Backup

Config files in `./config/` are the only persistent state. Back up that directory.

## Upgrade

```sh
docker compose pull && docker compose up -d
```

## Project health

Active Node.js development, 25+ sources, 8+ clients, web UI, Prometheus metrics, multi-user, MIT license.

## Scrobbler-family comparison

- **Multi-Scrobbler** — Node.js, 25+ sources, 8+ clients, web UI, multi-user, MIT
- **Maloja** — Python, scrobble *destination* (self-hosted Last.fm alternative); pairs well with Multi-Scrobbler
- **Last.fm** — SaaS scrobble destination; not self-hosted
- **ListenBrainz** — Open SaaS + self-hostable; scrobble destination; complements Multi-Scrobbler
- **Scrobble-me-this** — simpler; fewer sources

**Choose Multi-Scrobbler if:** you want one self-hosted daemon to monitor music from any player (Spotify, Jellyfin, Plex, VLC, etc.) and scrobble to any destination (Last.fm, ListenBrainz, Maloja, Discord).

## Links

- Repo: <https://github.com/FoxxMD/multi-scrobbler>
- Docs: <https://docs.multi-scrobbler.app/>
- Quick Start: <https://docs.multi-scrobbler.app//quickstart>
- Docker Hub: <https://hub.docker.com/r/foxxmd/multi-scrobbler>
