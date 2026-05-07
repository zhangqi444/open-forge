---
name: Stretto
description: Open-source web-based music player that backs tracks with YouTube/SoundCloud audio. Supports Spotify/iTunes playlist import, library sync, lyric fetching, and music discovery. MIT licensed.
website: https://github.com/benkaiser/stretto
source: https://github.com/benkaiser/stretto
license: MIT
stars: 632
tags:
  - music
  - media-player
  - youtube
  - spotify
platforms:
  - JavaScript
  - Docker
---

# Stretto

Stretto is an open-source web-based music player. It backs your music library with YouTube or SoundCloud audio sources, allowing you to build and play a personal library without storing audio files. Features include Spotify/iTunes playlist import, cross-device library sync, automatic lyric fetching, and music discovery through iTunes/Spotify charts.

Source: https://github.com/benkaiser/stretto  
Hosted version: https://next.kaiserapps.com/  
Latest: check https://github.com/benkaiser/stretto/releases

> **Note**: Stretto depends on third-party services (YouTube, SoundCloud) as audio sources and requires a Chrome extension for downloading tracks to the browser. Review ToS implications for your use case.

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VM / VPS | Docker + MongoDB | Recommended |
| Any Linux VM / VPS | Node.js 12+ + MongoDB | Native install |

## Inputs to Collect

**Phase: Planning**
- MongoDB connection URL
- Application URL (`APP_URL`) — needed for OAuth callbacks
- Google OAuth client ID (for YouTube integration)
- Spotify client ID (for Spotify import)
- SoundCloud client ID (for SoundCloud integration)
- Port to expose (default: `3000`)

## Software-Layer Concerns

**`.env` file:**
```env
PORT=3000
ENV=production
APP_URL=https://music.example.com
MONGO_URL=mongodb://mongo:27017/stretto
GOOGLE_CLIENT_ID=your-google-client-id
SPOTIFY_CLIENT_ID=your-spotify-client-id
SOUNDCLOUD_CLIENT_ID=your-soundcloud-client-id
```

**Docker Compose:**
```yaml
services:
  mongo:
    image: mongo:6
    restart: unless-stopped
    volumes:
      - stretto_db:/data/db

  web:
    image: node:18-alpine
    working_dir: /app
    command: sh -c "npm install && npm start"
    environment:
      PORT: 3000
      ENV: production
      APP_URL: https://music.example.com
      MONGO_URL: mongodb://mongo:27017/stretto
      GOOGLE_CLIENT_ID: CHANGE_ME
      SPOTIFY_CLIENT_ID: CHANGE_ME
      SOUNDCLOUD_CLIENT_ID: CHANGE_ME
    depends_on:
      - mongo
    ports:
      - 3000:3000
    volumes:
      - ./:/app
      - /app/node_modules

volumes:
  stretto_db:
```

**Or use the dev quickstart:**
```bash
git clone https://github.com/benkaiser/stretto
cd stretto
cp .env.example .env
# Edit .env with your credentials
bin/go     # runs docker-compose up
```

**Requirements:**
- Node.js 12+ (18+ recommended)
- MongoDB
- API keys: Google (YouTube Data API v3), Spotify, SoundCloud

**Chrome extension:** Users need the [Stretto Helper Extension](https://github.com/benkaiser/Stretto-Helper-Extension) to download/stream audio via YouTube — the extension intercepts requests in the browser.

## Upgrade Procedure

1. `git pull` in the stretto directory
2. `docker-compose down && docker-compose up -d --build`
3. Check changelog: https://github.com/benkaiser/stretto/releases

## Gotchas

- **Third-party dependencies**: All audio comes from YouTube/SoundCloud — if those services change their APIs or terms, Stretto may break
- **Chrome extension required**: Audio playback requires the companion Chrome extension; not compatible with other browsers without it
- **API keys required**: You must register your own Google, Spotify, and SoundCloud developer apps and obtain client IDs
- **Node.js 12 in compose file**: The original docker-compose uses an old Node version — update to Node 18 LTS for better compatibility
- **Library sync**: Syncing between devices requires both to be logged in with the same account on your self-hosted instance
- **Spotify import ≠ Spotify playback**: Stretto imports Spotify playlists but plays them through YouTube; it does not use Spotify's audio directly

## Links

- Upstream README: https://github.com/benkaiser/stretto/blob/master/README.md
- Chrome extension: https://github.com/benkaiser/Stretto-Helper-Extension
- Hosted version: https://next.kaiserapps.com/
- Spotify import: https://next.kaiserapps.com/spotify/
