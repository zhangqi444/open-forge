---
name: Yubal
description: "Self-hosted YouTube Music downloader with organized library output. Docker. Python/yt-dlp. guillevc/yubal. Artist/album folder structure, synced LRC lyrics, ReplayGain, playlist M3U, browser extension, Navidrome/Jellyfin ready."
---

# Yubal

**Self-hosted YouTube Music downloader that produces a clean, organized music library.** Paste any YouTube Music URL (track, album, playlist); Yubal downloads the audio, tags it with full metadata, creates an Artist/Album/Track folder structure, generates synced `.lrc` lyrics, adds ReplayGain tags, and exports M3U playlist files. Browser extensions for Firefox and Chrome. Integrates with Navidrome, Jellyfin, and Gonic.

Built + maintained by **guillevc**. See repo license.

- Upstream repo: <https://github.com/guillevc/yubal>
- GHCR: `ghcr.io/guillevc/yubal`
- Firefox Add-on: <https://addons.mozilla.org/firefox/addon/yubal/>
- Unraid template: community Docker template available

## Architecture in one minute

- **Python + yt-dlp** for audio download + metadata
- **Web UI** for job queue management (real-time progress via SSE)
- Scheduled sync via configurable cron expression
- Output: `Artist / Year - Album / Track - Title.opus` + `.lrc` + `cover.jpg`
- M3U files reference tracks by relative path (deduplication across playlists)
- Port **8000** (web UI)
- Data dir: `./data` — downloads + library; Config dir: `./config`
- `PUID`/`PGID` for file ownership matching host user
- Resource: **low** — Python; bandwidth-bound during downloads

## Compatible install methods

| Infra      | Runtime                     | Notes                               |
| ---------- | --------------------------- | ----------------------------------- |
| **Docker** | `ghcr.io/guillevc/yubal`    | **Primary** — GHCR                  |
| **Unraid** | Community Docker template   | Unraid forum thread available       |

## Install via Docker Compose

```yaml
services:
  yubal:
    image: ghcr.io/guillevc/yubal:v0.8.0
    container_name: yubal
    ports:
      - 8000:8000
    environment:
      PUID: 1000               # match your host UID (run: id -u)
      PGID: 1000               # match your host GID (run: id -g)
      YUBAL_SCHEDULER_CRON: "0 0 * * *"   # daily sync at midnight
      YUBAL_DOWNLOAD_UGC: false           # skip user-generated content
      YUBAL_TZ: UTC
    volumes:
      - ./data:/app/data       # downloaded music library
      - ./config:/app/config   # settings + subscriptions DB
    restart: unless-stopped
```

Visit `http://localhost:8000`.

## First boot

1. Set `PUID`/`PGID` to match your host user (`id -u` / `id -g`) so files are writable.
2. `docker compose up -d`.
3. Visit `http://localhost:8000`.
4. Paste a YouTube Music URL (track, album, or playlist) → Download.
5. Watch real-time progress in the UI.
6. (Optional) Subscribe to playlists for automatic scheduled sync.
7. Point Navidrome, Jellyfin, or Gonic at the `./data` directory.
8. Put behind TLS.

## Output structure

```
data/
├── Pink Floyd/
│   └── 1973 - The Dark Side of the Moon/
│       ├── 01 - Speak to Me.opus
│       ├── 01 - Speak to Me.lrc     ← synced lyrics
│       └── cover.jpg
├── Radiohead/
│   └── 1997 - OK Computer/
│       ├── 01 - Airbag.opus
│       └── cover.jpg
└── _Playlists/
    ├── My Favorites [id].m3u        ← relative paths, deduplicates tracks
    └── My Favorites [id].jpg
```

## Key configuration variables

| Variable | Default | Description |
|----------|---------|-------------|
| `PUID` / `PGID` | `1000` | File ownership UID/GID |
| `YUBAL_AUDIO_FORMAT` | `opus` | `opus`, `mp3`, or `m4a` |
| `YUBAL_AUDIO_QUALITY` | `0` | Transcode quality (0=best, 10=worst) |
| `YUBAL_SCHEDULER_ENABLED` | `true` | Enable auto-sync scheduler |
| `YUBAL_SCHEDULER_CRON` | daily | Cron expression for sync |
| `YUBAL_DOWNLOAD_UGC` | `false` | Download user-generated content playlists |
| `YUBAL_TZ` | `UTC` | Timezone for scheduler |

## Browser extension

Download tracks and subscribe to playlists directly from YouTube and YouTube Music — without leaving the page.

- **Firefox**: <https://addons.mozilla.org/firefox/addon/yubal/>
- **Chrome**: manual install from GitHub releases (unpacked extension)

The extension adds a Yubal download button to YouTube Music pages.

## Media server integration

Yubal's output is tested with:
- **Navidrome** — point library path at `./data`; Navidrome scans and indexes automatically
- **Jellyfin** — add music library pointing to `./data`
- **Gonic** — Subsonic-compatible server; mount `./data` as music dir

The Artist/Album/Track folder structure + proper ID3/Opus tags ensure correct metadata scanning in all supported servers.

## Gotchas

- **YouTube Music source only.** Yubal downloads from YouTube Music (not Spotify). Use Spooty for Spotify. For best results, use YouTube Music URLs specifically (music.youtube.com) — regular YouTube URLs may work but with lower metadata quality.
- **`PUID`/`PGID` must match host user.** If mismatched, the container writes files as root — you can't easily manage them from the host. Run `id -u && id -g` and set those values.
- **Opus format is default.** `opus` gives the best quality/size ratio for streaming. For media players/servers that don't support opus (rare), use `mp3` or `m4a`.
- **Smart deduplication.** The same track appearing in 10 playlists is stored only once in the Artist/Album folder — the M3U files reference it with relative paths. This saves disk space but means deleting a track affects all playlists referencing it.
- **Synced LRC lyrics.** `.lrc` files contain synced (karaoke-style) lyrics from YouTube Music. Supported by Navidrome, Jellyfin, and some music players. Not all tracks have synced lyrics available.
- **ReplayGain tags.** Applied to normalize loudness across your library. Supported by most music players and servers. If you prefer other normalization approaches, this can be configured.
- **Scheduled sync.** Subscribed playlists sync on the cron schedule. New tracks added to subscribed YouTube Music playlists appear in your library automatically.

## Backup

```sh
docker compose stop yubal
sudo tar czf yubal-$(date +%F).tgz data/ config/
docker compose start yubal
```

## Upgrade

```sh
docker compose pull && docker compose up -d
```

## Project health

Active Python/yt-dlp development, GHCR, Firefox + Chrome extensions, Navidrome/Jellyfin/Gonic support, Unraid template, ReplayGain, synced lyrics. Solo-maintained by guillevc.

## YouTube-music-downloader-family comparison

- **Yubal** — Python+yt-dlp, organized library, LRC lyrics, ReplayGain, browser extension, media server ready
- **yt-dlp** — CLI only; no library organization; the underlying tool Yubal uses
- **Spooty** — NestJS, Spotify URL input → YouTube download; different source (Spotify not YTM)
- **Explo** — Go, ListenBrainz recommendations → YouTube download; discovery-driven not URL-driven
- **Lidarr** — C#, artist-based acquisition via Usenet/torrent; no YouTube Music integration

**Choose Yubal if:** you want a self-hosted, organized YouTube Music downloader with browser extension, LRC lyrics, ReplayGain, and direct Navidrome/Jellyfin integration.

## Links

- Repo: <https://github.com/guillevc/yubal>
- GHCR: `ghcr.io/guillevc/yubal`
- Firefox extension: <https://addons.mozilla.org/firefox/addon/yubal/>
