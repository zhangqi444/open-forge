---
name: Beatbump
description: "Privacy-respecting alternative frontend for YouTube Music. Docker. SvelteKit. snuffyDev/Beatbump. No ads, no tracking, automix, local playlists, group sessions via WebRTC, background play. ⚠️ NO LONGER ACTIVELY DEVELOPED."
---

# Beatbump

**Privacy-respecting alternative frontend for YouTube Music.** Browse and listen to YouTube Music without ads, tracking, or account requirements. Automix for continuous playback, local playlist management (stored in-browser with IndexedDB), P2P group listening sessions via WebRTC, and background play on mobile. SvelteKit app deployable with Docker.

Built + maintained by **snuffyDev**. AGPL-3.0 license.

> ⚠️ **NO LONGER ACTIVELY DEVELOPED.** The README states development has stopped due to changes made by YouTube. The codebase is functional and public instances continue running, but receives no new features or bug fixes. Consider alternatives like Hyperpipe or use the official YouTube Music app with uBlock Origin.

- Upstream repo: <https://github.com/snuffyDev/Beatbump>
- Official instance: <https://beatbump.io>
- Community instances: bb.vern.cc and others

## Architecture in one minute

- **SvelteKit** (TypeScript) frontend + serverless-style backend
- **Custom YouTube Music API wrapper** (not an official API)
- Port **443** (in Docker — adjust to HTTP port for reverse proxy)
- Playlists stored in-browser **IndexedDB** — no backend database
- Group sessions via **WebRTC mesh** (P2P, no relay server needed)
- Optional `hls-proxy-rewriter` proxy service for HLS stream handling
- Resource: **low** — SvelteKit; mostly client-side rendering

## Compatible install methods

| Infra      | Runtime          | Notes                                           |
| ---------- | ---------------- | ----------------------------------------------- |
| **Docker** | build from source| `docker compose up -d`; builds from GitHub       |
| **Hosted** | beatbump.io      | Official instance; community instances available |

## Install via Docker Compose

```yaml
services:
  app:
    build:
      context: ./app
      dockerfile: Dockerfile
      args:
        - PORT=3000
    ports:
      - "3000:3000"
    environment:
      PORT: 3000
      VITE_DOMAIN: "your-domain.com"
      VITE_SITE_URL: "https://your-domain.com"

  proxy:
    build:
      context: ./packages/proxy-server/deno
      dockerfile: Dockerfile
    ports:
      - "3001:3001"
```

```bash
git clone https://github.com/snuffyDev/Beatbump.git
cd Beatbump
# Edit VITE_DOMAIN and VITE_SITE_URL
docker compose up -d
```

Or just use the hosted instance at <https://beatbump.io>.

## Features overview

| Feature | Details |
|---------|---------|
| Music playback | Audio-only streams from YouTube Music |
| No ads | No YouTube ads |
| No tracking | No Google tracking/analytics |
| No account needed | Browse and play without signing in |
| Search | Artists, songs, albums, playlists |
| Automix | Continuous playback based on current track |
| Local playlists | Create and manage playlists in-browser (IndexedDB) |
| Favorites | Save tracks locally |
| P2P sync | Peer-to-Peer playlist sync via WebRTC |
| Group sessions | Listen together via WebRTC mesh network |
| Background play | Mobile background audio (iOS 15.6+) |
| Artist pages | Browse artist discographies |
| Album pages | Browse and play albums |

## Gotchas

- **⚠️ Not actively developed.** YouTube's API changes have broken Beatbump. No new fixes are being made. The app may stop working at any time if YouTube changes break the underlying API wrapper.
- **Building from source required.** There's no pre-built Docker Hub image — you must clone the repo and `docker compose up` (which builds the SvelteKit app). Build may take several minutes.
- **YouTube Music API is unofficial.** Beatbump uses a reverse-engineered wrapper around the YouTube Music internal API. This is fragile — YouTube can break it without notice, and the app has no official API access.
- **Playlists are browser-local.** Your playlists live in the browser's IndexedDB — they're tied to that browser profile, not synced to a server. Clearing browser data loses your playlists. The P2P sync feature can help export between devices.
- **Group sessions via WebRTC mesh.** Group sessions use a mesh topology — all peers connect to each other. Works well for small groups (2–5 people); larger groups may have connection issues.
- **HLS proxy service.** The `proxy` service in the compose is a HLS stream rewriter. Some streams require it for proper playback. Include both services.
- **Legal note.** Accessing YouTube content via unofficial API wrappers may violate YouTube's Terms of Service. Use responsibly.

## Alternatives (actively maintained)

If Beatbump stops working due to YouTube changes:
- **Hyperpipe** — React, YouTube Music alternative frontend; actively maintained
- **Invidious** — Go, YouTube video frontend (not music-specific)
- **Piped** — Java + Vue, YouTube frontend; actively maintained

## Project health

⚠️ **No longer actively developed.** Functional but frozen. Public instance (beatbump.io) continues running. AGPL-3.0.

## YouTube-Music-frontend-family comparison

- **Beatbump** — SvelteKit, YouTube Music, group sessions, local playlists, ⚠️ unmaintained
- **Hyperpipe** — React, YouTube Music alt; actively maintained; similar scope
- **Invidious** — Go, YouTube video frontend; no music-specific features

**⚠️ Consider Hyperpipe as an actively maintained alternative.**

## Links

- Repo: <https://github.com/snuffyDev/Beatbump>
- Official instance: <https://beatbump.io>
- Hyperpipe (maintained alt): <https://github.com/TeamPiped/Hyperpipe>
