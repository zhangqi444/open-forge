---
name: its-mytabs-project
description: It's MyTabs recipe for open-forge. Self-hosted guitar/bass tab viewer and player similar to Songsterr. Supports .gp/.gpx/.gp3/.gp4/.gp5/.musicxml/.capx formats, audio sync (MP3/OGG or YouTube), MIDI synth, mute/solo tracks, cursor modes, notes coloring, dark/light mode, tab sharing links. Single container. MIT. Upstream: https://github.com/louislam/its-mytabs
---

# It's MyTabs

A self-hosted, open-source guitar and bass tab viewer and player — similar to Songsterr. View and play Guitar Pro tabs (.gp, .gpx, .gp3, .gp4, .gp5), MusicXML, and .capx files. Sync playback with MP3/OGG audio files or YouTube videos. MIDI synth with per-track mute/solo. Share tabs with others via link.

Upstream: <https://github.com/louislam/its-mytabs>

From the creator of Uptime Kuma. MIT License. Single container. AMD64 + ARM64.

> **Note:** YouTube sync may not work on private IPs (e.g., `192.168.x.x`). Use `localhost` or a public domain instead.

## Compatible combos

| Infra | Notes |
|---|---|
| Any Linux host (AMD64/ARM64) | Single container; file-based data |
| Windows | Native `.exe` available from releases |
| Any OS | Deno-based non-Docker install also available |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Host port?" | Default: `47777` |

## Software-layer concerns

### Image

```
louislam/its-mytabs:1
```

Docker Hub: <https://hub.docker.com/r/louislam/its-mytabs>

### Compose

```yaml
services:
  app:
    image: louislam/its-mytabs:1
    restart: unless-stopped
    ports:
      - "47777:47777"
    volumes:
      - ./data:/app/data
```

> Source: upstream README — <https://github.com/louislam/its-mytabs>

### Docker run (quick start)

```bash
docker run -d \
  --name its-mytabs \
  -p 47777:47777 \
  -v its-mytabs:/app/data \
  --restart unless-stopped \
  louislam/its-mytabs:1
```

Access at `http://localhost:47777`.

### Supported file formats

| Format | Notes |
|---|---|
| `.gp` | Guitar Pro (modern) |
| `.gpx` | Guitar Pro XML |
| `.gp3` | Guitar Pro 3 |
| `.gp4` | Guitar Pro 4 |
| `.gp5` | Guitar Pro 5 |
| `.musicxml` | MusicXML |
| `.capx` | Capella |

### Features

- **Audio sync** — sync tab playback to a `.mp3` or `.ogg` audio file, or a YouTube video URL
- **MIDI synth** — built-in MIDI playback; mute or solo individual tracks
- **Cursor modes** — no cursor (auto-scroll only), highlight current bar, follow cursor
- **Notes coloring** — color-coded note visualization
- **Dark / Light tab colors** — switch display theme
- **Score view** — toggle between tab and standard notation view
- **Share links** — share a specific tab with others via URL
- **Mobile friendly** — responsive UI
- **Browser navigation** — back/forward button support

### Live demo

<https://its-mytabs.kuma.pet/tab/1?audio=youtube-VuKSlOT__9s&track=2>

### Non-Docker install (Deno)

```bash
git clone https://github.com/louislam/its-mytabs.git
cd its-mytabs
git checkout 1.X.X --force   # pin to a release tag
deno task setup
deno task start
```

Requires Deno 2.4.4+.

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

Tab data persists in `./data`.

> Tag `1` is a floating tag (tracks latest 1.x release). Pin to a specific version tag (e.g., `louislam/its-mytabs:1.0.0`) for reproducible deployments.

## Gotchas

- **YouTube sync requires a public domain or localhost** — YouTube embeds are blocked from loading on private IP addresses (`192.168.x.x`, `10.x.x.x`). Use `localhost` for local testing or a real public domain + HTTPS for LAN/remote access.
- **`1` is a floating tag** — `louislam/its-mytabs:1` tracks the latest 1.x release. This can pull in breaking changes. Pin to a specific version tag for stability.
- **No authentication** — the UI is open to anyone who can reach the port. Front with a reverse proxy with auth if exposing publicly.
- **No built-in tab library sync** — It's MyTabs is a viewer/player for files you upload. It does not automatically sync from Songsterr or Guitar Pro online services.
- **MIDI playback requires browser Web Audio API** — works in all modern browsers; may not work in very old browsers or headless environments.

## Links

- Upstream README: <https://github.com/louislam/its-mytabs>
- Docker Hub: <https://hub.docker.com/r/louislam/its-mytabs>
- Releases: <https://github.com/louislam/its-mytabs/releases>
- Live demo: <https://its-mytabs.kuma.pet>
