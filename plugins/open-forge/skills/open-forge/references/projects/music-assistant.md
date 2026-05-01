---
name: Music Assistant
description: "Free open-source music library manager connecting streaming services and smart speakers. Docker or Home Assistant add-on. Python. music-assistant/server. Spotify/Tidal/YTMusic + Sonos/Chromecast/Squeezebox."
---

# Music Assistant

**Free, open-source music library manager** that connects streaming services and your local music library to a wide range of connected speakers. The server is the core — it must run always-on (NAS, Pi, NUC, Home Assistant host). Clients (companion apps, Home Assistant integration) talk to the server to play music anywhere.

Built + maintained by the **Music Assistant team** under the Open Home Foundation.

- Upstream repo: <https://github.com/music-assistant/server>
- Docs: <https://music-assistant.io>
- Beta docs: <https://beta.music-assistant.io>
- Issue tracker: <https://github.com/music-assistant/support/issues>
- Discord: (community — see docs site)

## Architecture in one minute

- **Python** server (custom binary dependencies + ffmpeg; **cannot run as bare pypi package**)
- Two install methods: **Docker container** or **Home Assistant Add-on** (recommended when HA is present)
- REST + WebSocket API; companion apps (iOS/Android/Web) connect to the server
- Music providers: Spotify, Tidal, YouTube Music, Qobuz, SoundCloud, Deezer, local library (file system)
- Speaker providers: Sonos, Chromecast/Google Cast, Snapcast, Squeezebox/Logitech Media Server, AirPlay, Fully Kiosk, Home Assistant media players
- Resource: **medium** — Python + audio transcoding via ffmpeg; 1–2 GB RAM recommended

## Compatible install methods

| Infra                      | Runtime                              | Notes                                                                       |
| -------------------------- | ------------------------------------ | --------------------------------------------------------------------------- |
| **Home Assistant Add-on**  | HA Supervisor add-on store           | **Recommended if you run HA** — easiest install, supervised updates         |
| **Docker**                 | `ghcr.io/music-assistant/server`     | For standalone deploys (NAS, VPS, Pi without HA)                            |

## Inputs to collect

| Input                          | Example                           | Phase    | Notes                                                                                  |
| ------------------------------ | --------------------------------- | -------- | -------------------------------------------------------------------------------------- |
| Music provider credentials     | Spotify OAuth / Tidal / etc.      | Auth     | Configured in MA web UI → Providers; OAuth flows handled in-app                        |
| Local music path               | `/music`                          | Storage  | Mount into Docker container; MA scans and indexes                                      |
| Speaker discovery              | LAN (mDNS / SSDP)                 | Network  | MA auto-discovers Sonos/Chromecast if on same network segment; host networking helps   |
| Domain (optional)              | `music.example.com`               | URL      | Reverse proxy + TLS; needed for OAuth provider callbacks                               |

## Install via Docker

```yaml
services:
  music-assistant:
    image: ghcr.io/music-assistant/server:latest
    container_name: music-assistant
    network_mode: host            # recommended for mDNS/SSDP speaker discovery
    volumes:
      - ./ma-data:/data
      - /path/to/music:/music:ro  # local library (optional)
    environment:
      - LOG_LEVEL=info
    restart: unless-stopped
```

> **Why `network_mode: host`?** Speaker discovery relies on mDNS (Chromecast/AirPlay) and SSDP (Sonos). These multicast protocols don't traverse Docker bridge networks by default. Host networking is the easiest fix; alternatively, configure `--net=macvlan` or a mDNS reflector (e.g., `avahi-daemon`).

Visit `http://<host>:8095` (default port).

## Install via Home Assistant Add-on

See <https://music-assistant.io/installation/> — click "Add to Home Assistant" badge in the docs, install the add-on repository, install Music Assistant Server, start it. HA integration available from the Integrations page.

## First boot

1. Deploy server.
2. Visit `http://<host>:8095` → web UI.
3. Add **music providers** (Settings → Providers → Music): connect Spotify, Tidal, YouTube Music, local library, etc.
4. Add **player providers** (Settings → Providers → Players): auto-discovered Sonos/Chromecast, or add manually.
5. Browse your library → play to a room.
6. If using HA: install the Music Assistant HA integration for voice control + automations.

## Data & config layout

- `/data/` — MA database (SQLite), cache, provider tokens, config
- Local music: externally managed; MA scans it read-only

## Backup

```sh
docker compose stop music-assistant
sudo tar czf ma-$(date +%F).tgz ma-data/
docker compose start music-assistant
```

Contents: provider OAuth tokens (Spotify/Tidal/etc.) + library metadata cache + playback history. The OAuth tokens = access to your streaming accounts; treat as secrets.

## Upgrade

1. Releases: <https://github.com/music-assistant/server/releases>
2. Docker: `docker compose pull && docker compose up -d`
3. HA Add-on: update via HA Supervisor → Add-ons → Music Assistant → Update.

## Gotchas

- **Cannot run as standalone Python package.** MA bundles compiled C binaries (audio processing) and ffmpeg. The only supported installation paths are Docker or HA add-on. Installing via `pip install music-assistant` will fail or produce a broken server.
- **`network_mode: host` for speaker discovery.** mDNS (Chromecast/AirPlay) and SSDP (Sonos) use multicast on the LAN. Docker bridge mode blocks multicast. Use `network_mode: host`, macvlan, or a LAN-side mDNS reflector. This is the #1 reason speakers don't appear after install.
- **Spotify: provider credentials + OAuth.** Spotify's API requires you to create a developer app (free). The web UI walks you through the OAuth flow. Without it, Spotify tracks can't be played.
- **Tidal / Qobuz / Deezer: account required.** These are subscription-tier providers; MA is a client that plays your subscription. You pay Tidal/Qobuz directly.
- **HA is the recommended deployment context.** The README explicitly says MA is "tailored to use side by side with Home Assistant … for automation." Standalone Docker is fully supported but you lose HA voice control + entity integrations.
- **Squeezebox/LMS support.** If you have legacy Logitech Media Server infrastructure, MA can function as an LMS-compatible server. Niche but powerful for Squeezebox hardware owners.
- **Provider API changes.** Streaming provider clients are reverse-engineered or use official APIs with volatile terms. A provider may break after a streaming service changes their API. Check the issue tracker if a provider stops working.
- **Snapcast integration.** MA supports Snapcast (multi-room sync audio server). Run Snapcast alongside MA for precision-sync whole-home audio.
- **Port 8095 is the default.** Override with `MA_WEB_PORT` env var if needed.

## Project health

Active Python development, CI, Docker Hub (GHCR), Home Assistant Add-on store, Open Home Foundation project, docs site, Discord. Multi-contributor team.

## Music-streaming-server-family comparison

- **Music Assistant** — Python, streaming providers + local + smart speakers, HA-native
- **Navidrome** — Go, Subsonic API, local library streaming, no smart-speaker control
- **LMS (Lightweight Music Server)** — C++, Subsonic API, local + MusicBrainz
- **Volumio** — Linux distro for dedicated audio hardware, local + streaming
- **Plex + PlexAMP** — multi-media, streaming via internet, account required
- **Roon** — audiophile streaming + management, paid subscription

**Choose Music Assistant if:** you want to bridge streaming services (Spotify/Tidal/YouTube Music) with whole-home smart speakers (Sonos/Chromecast) and Home Assistant automations.

## Links

- Repo: <https://github.com/music-assistant/server>
- Docs: <https://music-assistant.io/installation/>
- HA Add-on: install from docs site
- Support/issues: <https://github.com/music-assistant/support/issues>
- Navidrome (local-library alt): <https://www.navidrome.org>
- Snapcast (multi-room sync): <https://github.com/badaix/snapcast>
