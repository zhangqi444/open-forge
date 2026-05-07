---
name: synctube
description: SyncTube recipe for open-forge. Lightweight synchronized video watching with chat. Supports YouTube, Streamable, VK, PeerTube, raw mp4/m3u8. Leader-based playback control. Node.js/Haxe, Docker or npm. Source: https://github.com/RblSb/SyncTube
---

# SyncTube

Lightweight synchronized video watching room with chat. Watch YouTube, Streamable, VK, PeerTube, raw MP4/M3U8, and other media together in real-time. Leader-based playback control (play/pause/seek synced for all), external subtitle support (vtt/srt/ass), external audio track support, playback rate sync, hotkeys, and a native mobile client. Simple to run locally or self-host. MIT licensed. Built with Haxe + Node.js.

Upstream: <https://github.com/RblSb/SyncTube> | Demo: <https://synctube.onrender.com/>

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any | Docker (build from source) | Official Dockerfile in repo |
| Any | Docker Compose | Compose file in repo |
| Linux / macOS / Windows | Node.js 14+ | Direct npm run |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| config | Port | Default: 4200 |
| config | User config directory | `user/` — server settings, emotes, permissions |

## Software-layer concerns

### Architecture

- Node.js server (compiled from Haxe) — handles room state, WebSocket sync, chat
- No external database — state is in-memory per session
- Static file serving — built-in

### Port

Default port is **4200**. Configurable via server settings in `user/` directory.

### Config / customization

The `user/` directory holds server-side customization:
- `user/settings.json` — server config (port, permissions, etc.)
- `user/emotes/` — custom emoji
- `user/res/` — override any frontend file

Mount `user/` as a Docker volume to persist config across container restarts.

See `user/README.md` in the repo for full config reference.

### Optional: YouTube cache

To enable server-side YouTube video caching (for the "Cache on server" feature):
```bash
npm i https://github.com/RblSb/ytdlp-nodejs
# Also install ffmpeg on the host system
sudo apt install ffmpeg
```
Default cache size is 3.0 GiB. Optional — not needed for basic use.

## Install — Docker Compose (recommended)

```bash
git clone https://github.com/RblSb/SyncTube.git
cd SyncTube

docker compose up -d
```

Default `docker-compose.yml`:
```yaml
services:
  synctube:
    build: .
    ports:
      - "4200:4200"
    volumes:
      - "${PWD}/user:/usr/src/app/user"
```

Access at http://localhost:4200. Share the link with friends to watch together.

**Note:** The Docker container hides the real local/global IPs in the startup output — find your public IP manually if sharing with users outside your LAN.

## Install — Docker run

```bash
git clone https://github.com/RblSb/SyncTube.git
cd SyncTube
docker build -t synctube .
docker run --rm -it -p 4200:4200 -v ${PWD}/user:/usr/src/app/user synctube
```

## Install — Node.js (local)

```bash
# Requires Node.js 14+
git clone https://github.com/RblSb/SyncTube.git
cd SyncTube
npm ci
node build/server.js
# Open the "Local" link shown in terminal
# Share the "Global" link with friends
```

## Upgrade procedure

```bash
git pull
docker compose up -d --build
```

## How to use

1. Open the app in your browser
2. Log in with any nickname
3. Click the "+" button to add a video URL (YouTube or direct MP4 link)
4. Click **Leader** to take control of playback for all viewers
5. Use chat to communicate while watching

Playback controls: `Alt-P` for global play/pause, see upstream for full hotkey list.

## Gotchas

- Docker hides real IPs in the startup message — the displayed "Local" and "Global" URLs may show container-internal addresses. Check your actual server IP/domain for sharing with remote viewers.
- Leader button is required for synchronized control — without it, each user controls their own playback independently.
- No built-in authentication or room passwords by default — anyone with the link can join. Configure permissions in `user/settings.json`.
- YouTube playback in Docker may hit API limits on heavily used instances; the optional ytdlp caching feature helps mitigate this.
- `requestLeaderOnPause` and `unpauseWithoutLeader` settings in `user/settings.json` simplify controls for small group watching sessions.

## Links

- Source: https://github.com/RblSb/SyncTube
- User config reference: https://github.com/RblSb/SyncTube/blob/master/user/README.md
- Demo: https://synctube.onrender.com/
- Mobile client: https://github.com/RblSb/SyncTubeApp
