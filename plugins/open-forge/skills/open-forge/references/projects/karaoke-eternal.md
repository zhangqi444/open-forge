---
name: karaoke-eternal
description: Karaoke Eternal recipe for open-forge. Self-hosted karaoke party server where guests queue songs from their phone browser. Plays MP3+G, MP4, and WebGL visualizations. Available via Docker or npm. Source: https://github.com/bhj/KaraokeEternal
---

# Karaoke Eternal

Self-hosted karaoke party server where everyone can find and queue songs from their phone's browser. The player runs fullscreen in a browser on your display/TV. Supports MP3+G (with CDG lyrics, including zipped), MP4 video karaoke, and music-synced WebGL visualizations with automatic lyrics background removal. Features easy join via QR codes, guest accounts, multiple simultaneous rooms with optional passwords, and a dynamic queue system. No microphones required — the server only outputs music. Upstream: https://github.com/bhj/KaraokeEternal. Docs: https://www.karaoke-eternal.com/docs/.

## Compatible install methods

| Method | Platform | Notes |
|---|---|---|
| Docker / Docker Compose | Linux | Recommended for dedicated servers and NAS devices |
| npm (global) | Linux / macOS / Windows | Simple install on any Node.js machine |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| install | "Media library path?" | Path to your karaoke files (MP3+G, MP4) |
| install | "Port?" | Default: 8080 |
| install | "Timezone?" | For file timestamps and scheduling |
| auth | "Admin username + password?" | Created during web-based first-run setup |

## Software-layer concerns

### Method 1: Docker Compose (recommended)

  services:
    karaoke-eternal:
      container_name: karaoke-eternal
      image: radrootllc/karaoke-eternal
      restart: unless-stopped
      ports:
        - 8080:8080
      volumes:
        - /path/to/your/karaoke/files:/music:ro  # your media library (read-only)
        - karaoke-data:/config                    # persistent app data
      environment:
        - PUID=1000
        - PGID=1000
        - TZ=America/New_York

  volumes:
    karaoke-data:

  docker compose up -d

### Method 2: npm (global install)

  # Prerequisites: Node.js v24+
  npm i -g karaoke-eternal

  # Start the server:
  karaoke-eternal

  # Or with options:
  karaoke-eternal --port 8080 --mediaPath /path/to/karaoke/files

  # Runs at: http://localhost:8080/

### First-time setup

  # Navigate to http://your-server:8080/
  # On first visit, you'll be prompted to create an admin account.
  # Then add your media library path in Settings → Media Folders.
  # Click "Scan" to index your karaoke files.

### Supported file formats

  # MP3+G: .mp3 + .cdg files with the same base name (or zipped together as .zip)
  # MP4:   .mp4 video karaoke files
  # Visualizations: applied automatically when no video/CDG is available

### File / data locations

  # Docker: /config inside container (mapped to karaoke-data volume)
  # npm (Linux): ~/.karaoke-eternal/
  # npm (macOS): ~/Library/Application Support/karaoke-eternal/
  # npm (Windows): %APPDATA%\karaoke-eternal\

  # Contains: SQLite database, logs, preferences

### Multi-room setup

  # Create multiple rooms in Admin → Rooms.
  # Each room has its own queue and optionally a password.
  # Each room needs its own "player" browser tab/window open on the display.

### Using the app

  # Guest joining:
  # - Share the QR code displayed on the player screen
  # - Guests open the URL on their phone browser — no app install needed
  # - Guests search for songs and add them to the queue

  # Player:
  # - Open http://your-server:8080/ on the device connected to your TV/speakers
  # - Click the Player icon to enter fullscreen player mode

### Ports

  8080/tcp   # Web server (app + player)

### Reverse proxy (nginx)

  location / {
      proxy_pass http://127.0.0.1:8080;
      proxy_set_header Host $host;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_http_version 1.1;
      proxy_set_header Upgrade $http_upgrade;
      proxy_set_header Connection "upgrade";
  }

## Upgrade procedure

  # Docker:
  docker compose pull && docker compose up -d

  # npm:
  npm update -g karaoke-eternal

## Gotchas

- **Node.js v24+ required**: the npm package requires Node.js v24 or later. Check your version with `node --version` before installing.
- **MP3+G files must share a base name**: the `.mp3` and `.cdg` files must have identical base names (e.g. `Song Name.mp3` + `Song Name.cdg`) or be zipped together as `Song Name.zip`.
- **Media path read-only in Docker**: mount your karaoke library as read-only (`:ro`) for safety. Karaoke Eternal only reads files; it never modifies them.
- **Player tab must stay open**: the player (fullscreen karaoke display) runs in a browser tab. If that tab is closed or the browser crashes, playback stops. Keep it open on the TV/display device.
- **Microphones not included**: Karaoke Eternal outputs music only. Run your microphones directly into a mixer/speakers alongside your audio output from the browser — the software doesn't handle mic input.
- **WebSocket required for proxy**: if using a reverse proxy, ensure WebSocket upgrade headers are forwarded. Without them, the real-time queue updates won't work.

## References

- Upstream GitHub: https://github.com/bhj/KaraokeEternal
- Documentation: https://www.karaoke-eternal.com/docs/
- Getting started: https://www.karaoke-eternal.com/docs/getting-started/
- Docker image: https://hub.docker.com/r/radrootllc/karaoke-eternal
- npm package: https://www.npmjs.com/package/karaoke-eternal
- Discord: https://discord.gg/PgqVtFq
