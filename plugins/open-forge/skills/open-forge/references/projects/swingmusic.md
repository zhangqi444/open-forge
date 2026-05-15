---
name: swingmusic
description: SwingMusic recipe for open-forge. Covers Docker Compose and script install. SwingMusic is a beautiful self-hosted music streaming server for local audio files with a Spotify-like UI.
---

# SwingMusic

Beautiful, self-hosted music streaming server for local audio files. Spotify-like web UI with artist pages, album art, folder browsing, daily mixes, cross-fade, silence detection, Last.fm scrobbling, multi-user support, and listening statistics. Streams to browser and Android client. Written in Python with a modern React frontend. Upstream: <https://github.com/swingmx/swingmusic>. Docs: <https://swingmx.com/guide/introduction.html>. Website: <https://swingmx.com>.

**License:** MIT · **Language:** Python · **Default port:** 1970 · **Stars:** ~1,900

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose | `ghcr.io/swingmx/swingmusic` | ✅ | **Recommended** — easy, persistent, multi-arch. |
| Install script (Linux/macOS) | `curl -fsSL https://setup.swingmx.com \| bash` | ✅ | Quick bare-metal install. |
| Docker CLI | `ghcr.io/swingmx/swingmusic` | ✅ | Single container without Compose. |
| Windows | Portable build from downloads page | ✅ | Windows homelab. |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| music_dir | "Path to your music library on the host? (e.g. /media/music or /home/user/Music)" | Free-text | Required. |
| config_dir | "Path for SwingMusic config and database? (e.g. /opt/swingmusic/config)" | Free-text | Required. |
| port | "Port to expose? (default: 1970)" | Free-text | Optional. |

## Install — Docker Compose (recommended)

```bash
mkdir swingmusic && cd swingmusic
mkdir -p config

cat > docker-compose.yml << 'COMPOSE'
services:
  swingmusic:
    image: ghcr.io/swingmx/swingmusic:v2.1.4
    container_name: swingmusic
    restart: unless-stopped
    ports:
      - "1970:1970"
    volumes:
      - /path/to/music:/music      # Your music library
      - ./config:/config            # Config and database
COMPOSE

docker compose up -d
```

Access the UI at `http://localhost:1970`.

### Multiple music directories

Mount additional directories as extra volumes:

```yaml
volumes:
  - /media/nas/music:/music
  - /home/user/Music:/music2
  - ./config:/config
```

Then add `/music2` as an additional scan directory inside the app settings.

## Install — Script (Linux/macOS)

```bash
curl -fsSL https://setup.swingmx.com | bash
```

The app starts automatically at `http://localhost:1970`.

## First-run setup

1. Open `http://localhost:1970` in a browser
2. On first run, you'll be prompted to set up your music folder(s)
3. SwingMusic scans your library — large libraries may take a few minutes
4. Create an admin account and start listening

## Features overview

| Feature | Notes |
|---|---|
| Library scanning | Auto-detects MP3, FLAC, AAC, OGG, WAV, and more. Rescans on file changes. |
| Daily mixes | Curated playlists generated from listening history |
| Album versioning | Groups Deluxe/Remaster/Live editions with their base album |
| Folder browser | Browse music by directory structure |
| Silence detection + crossfade | Seamless track transitions |
| Last.fm scrobbling | Configure in Settings → Last.fm |
| Multi-user | Multiple accounts with independent listening history |
| Statistics | Listening activity graphs and insights |
| Android client | <https://github.com/swingmx/android> |

## Software-layer concerns

| Concern | Detail |
|---|---|
| Music directory access | The container must have read access to your music files. Use `:ro` mount flag for read-only safety. |
| Config persistence | Database and settings are stored in `/config`. This must be a persistent volume or bind mount — container restart without it loses all metadata and playlists. |
| Scanning large libraries | Initial scan of 50k+ tracks takes several minutes. CPU usage spikes during scan. |
| GHCR image | The official Docker image is on GitHub Container Registry (`ghcr.io/swingmx/swingmusic`), not Docker Hub. |
| No built-in TLS | SwingMusic serves HTTP only. Use a reverse proxy (nginx/Caddy) with TLS for remote/internet access. |
| Android client | The Android client connects to the same server URL — expose it publicly (with auth/TLS) for remote streaming. |

## Upgrade procedure

```bash
# Docker
docker compose pull
docker compose up -d

# Script install — re-run the install script
curl -fsSL https://setup.swingmx.com | bash
```

## Gotchas

- **Config volume required:** Without a persistent `/config` mount, SwingMusic loses your library index and settings on every container restart. Always mount a persistent directory for `/config`.
- **Music is read-only inside the container:** SwingMusic only reads your music files — it doesn't modify them. Using a `:ro` mount is safe and a good security practice.
- **GHCR not Docker Hub:** The image is `ghcr.io/swingmx/swingmusic`, not on Docker Hub. Pull may require login for unauthenticated rate limits.
- **Initial scan on first run:** Large libraries can take minutes to hours for the first scan. The UI is partially usable during scanning but the library isn't complete until the scan finishes.
- **No transcoding:** SwingMusic streams files as-is — no server-side transcoding to lower bitrates for mobile. Ensure your files are in browser-compatible formats (MP3, AAC, OGG, FLAC).
- **Port 1970:** The default port 1970 is non-standard and usually free. Useful if you have multiple media servers already on common ports (8096, 4040, etc.).

## Upstream links

- GitHub: <https://github.com/swingmx/swingmusic>
- Website / docs: <https://swingmx.com>
- Guide: <https://swingmx.com/guide/introduction.html>
- Downloads: <https://swingmx.com/downloads.html>
- GHCR image: <https://github.com/swingmx/swingmusic/pkgs/container/swingmusic>
- Android client: <https://github.com/swingmx/android>
