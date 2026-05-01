---
name: Nodecast TV
description: "Self-hosted IPTV web player with EPG, VOD, and Series. Docker. Node.js. technomancer702/nodecast-tv. Xtream Codes + M3U support, virtual scrolling for 7000+ channels, hardware transcoding (NVENC/QSV/VAAPI), OIDC SSO."
---

# Nodecast TV

**Modern self-hosted IPTV web player.** Watch live TV, browse an EPG grid guide, and stream movies and series from any Xtream Codes or M3U IPTV source. Handles 7000+ channels via virtual scrolling. Hardware-accelerated transcoding (NVIDIA NVENC, AMD AMF, Intel QuickSync, VAAPI). Smart audio downmix for 5.1 surround. User authentication with admin and viewer roles. OIDC SSO support.

Built + maintained by **technomancer702**. See repo license.

- Upstream repo: <https://github.com/technomancer702/nodecast-tv>
- Docker Hub: built from source via Docker Compose

## Architecture in one minute

- **Node.js** backend + web frontend
- **Xtream Codes API** or **M3U** playlists as IPTV sources
- Hardware transcoding: ffmpeg with NVENC/AMF/QSV/VAAPI
- Port **3000** (web UI)
- Data volume: `./data:/app/data`
- Resource: **low-medium** baseline; **medium-high** with active transcoding

## Compatible install methods

| Infra      | Runtime                        | Notes                                              |
| ---------- | ------------------------------ | -------------------------------------------------- |
| **Docker** | build from GitHub source       | `docker-compose up -d`; builds image from source   |
| **Node**   | `npm install && npm run dev`   | Local dev; Node.js v14+                            |

## Install via Docker Compose

```yaml
services:
  nodecast-tv:
    build: https://github.com/technomancer702/nodecast-tv.git#main
    container_name: nodecast-tv
    ports:
      - "3000:3000"
    volumes:
      - ./data:/app/data
    restart: unless-stopped
    environment:
      - NODE_ENV=production
      - PORT=3000
```

```bash
docker compose up -d
```

Visit `http://localhost:3000`.

## Hardware transcoding

**Intel (QSV) & AMD (VAAPI):**

```yaml
    devices:
      - /dev/dri:/dev/dri
    group_add:
      - video  # or the GID of the 'render' group
```

**NVIDIA (NVENC):**

```yaml
    runtime: nvidia
    environment:
      - NVIDIA_VISIBLE_DEVICES=all
      - NVIDIA_DRIVER_CAPABILITIES=all
```

Requires: NVIDIA Container Toolkit on the host for NVENC; `/dev/dri` passthrough for QSV/VAAPI.

## First boot

1. `docker compose up -d`.
2. Visit `http://localhost:3000`.
3. Log in (first user created is admin).
4. Add an **IPTV source**: Settings → Sources:
   - **Xtream Codes**: enter server URL, username, password
   - **M3U**: enter M3U playlist URL
5. Wait for channels/EPG to sync.
6. Browse Live TV, TV Guide, Movies, or Series.
7. Add favorites for quick access.
8. Put behind TLS.

## Features overview

| Feature | Details |
|---------|---------|
| Live TV | Fast channel zapping, category grouping, search |
| TV Guide (EPG) | Interactive 24-hour grid with search + zoom |
| Movies (VOD) | Posters, metadata, category browsing |
| Series | Seasonal episode lists with metadata |
| Favorites | Unified favorites for channels, movies, series |
| Search | Cross-content search |
| Authentication | Admin + viewer roles |
| OIDC SSO | Authentik, Keycloak, and other OIDC providers |
| Virtual scrolling | Handles 7000+ channels smoothly |
| Hardware transcoding | NVENC, AMF, QSV, VAAPI |
| Audio downmix | 5.1→2.0 presets: ITU, Night Mode, Cinematic |
| Stream processing | Auto-detect codec → smart remux/transcode |
| Playback prefs | Volume memory, auto-play |
| Hidden categories | Admin can hide content categories |

## Audio downmix presets

| Preset | Use case |
|--------|---------|
| ITU | Standard broadcast downmix |
| Night Mode | Compressed dynamics for late-night viewing |
| Cinematic | Theatrical sound balance |
| Auto passthrough | For displays with surround sound capability |

## Gotchas

- **Requires an Xtream Codes or M3U IPTV subscription.** Nodecast TV is a player/frontend — it doesn't provide any IPTV content itself. You need an IPTV provider that offers Xtream Codes API access or an M3U URL.
- **Builds from source.** The Docker Compose file builds the image directly from GitHub. This means: first build takes several minutes; no pre-built Docker Hub image to pull. For production, consider building once and tagging locally.
- **Hardware transcoding needs host GPU.** NVENC requires an NVIDIA GPU + NVIDIA Container Toolkit installed on the host. QSV/VAAPI requires `/dev/dri` device passthrough. Without GPU pass-through, all transcoding is CPU-based.
- **EPG sync time.** Large EPG feeds (7-day guide for thousands of channels) can take several minutes to sync on first run. Be patient; don't restart mid-sync.
- **OIDC configuration.** OIDC SSO setup requires configuring the redirect URI in your identity provider (e.g., Authentik/Keycloak) to match your Nodecast TV URL. See the pull request linked in the README for setup details.
- **Xtream Codes API.** The app uses the Xtream Codes API for channel lists, EPG, and VOD metadata. If your provider uses a non-standard Xtream Codes implementation, some features may not work correctly.
- **5.1 audio streams.** Many IPTV streams broadcast in 5.1 surround — without downmix, stereo-only outputs sound wrong. The built-in downmix presets handle this; select the appropriate preset for your audio setup.

## Backup

```sh
sudo tar czf nodecast-$(date +%F).tgz data/
```

## Upgrade

```sh
docker compose pull && docker compose build --no-cache && docker compose up -d
```

## Project health

Active Node.js development, hardware transcoding (NVENC/QSV/VAAPI/AMF), OIDC SSO, virtual scrolling for large playlists. Solo-maintained by technomancer702.

## IPTV-player-family comparison

- **Nodecast TV** — Node.js, Xtream+M3U, EPG grid, VOD+Series, HW transcode, OIDC, 7000+ ch
- **Jellyfin** — media server that can play IPTV (Live TV plugin + tuner); heavier; broader scope
- **Streamyfin** — Jellyfin client; not a standalone IPTV player
- **IPTVnator** — Electron app (desktop); no web server; no transcoding
- **Threadfin** — Go, M3U proxy + EPG; pairs with Plex/Emby/Jellyfin tuner

**Choose Nodecast TV if:** you want a self-hosted IPTV web player with EPG, VOD, series support, and hardware transcoding for an Xtream Codes or M3U subscription.

## Links

- Repo: <https://github.com/technomancer702/nodecast-tv>
