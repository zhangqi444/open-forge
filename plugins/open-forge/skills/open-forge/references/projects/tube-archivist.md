---
name: Tube Archivist
description: "Self-hosted YouTube archiver. Subscribe to channels/playlists, auto-download with yt-dlp, index + search metadata, stream via web player, integrate with Jellyfin/Plex/Kodi. Python + Django + Elasticsearch + Redis + yt-dlp. GPL-2.0."
---

# Tube Archivist

Tube Archivist is the self-hosted **YouTube archiver + media-server-for-YouTube**. Subscribe to channels / playlists → yt-dlp downloads videos on schedule → metadata (title, description, thumbnail, chapters, subtitles) stored in Elasticsearch → play in the web UI or push to Jellyfin/Plex via companion plugins.

Use cases:

- **Channel archival** — save creators you care about before they delete/demonetize/disappear
- **Offline viewing** — watch without internet (flights, trains, outages)
- **Ad-free** — no YouTube ads on downloaded content
- **Education** — tutorial series with local full-text search
- **Family curation** — kid-safe curated channels on local network

> **Legal note (front-loaded):** YouTube's Terms of Service prohibit downloading content for most uses. yt-dlp (and Tube Archivist by extension) operate in the gray area that projects like Piped/Invidious/NewPipe also inhabit. **Personal archival is generally tolerated in practice; republishing or monetizing downloads is not.** Use for personal offline viewing; respect creator wishes + copyright.

Features:

- **Subscribe** to channels + playlists; auto-download new uploads
- **yt-dlp** under the hood — all yt-dlp formats + options available
- **Quality picker** — best, 1080p, 720p, audio-only, etc.
- **Subtitles** — auto + manual captions in multiple languages
- **Chapters** — extracted from video descriptions (like YouTube)
- **Thumbnails + metadata** — titles, descriptions, upload dates, view counts
- **Full-text search** (Elasticsearch) — search across all videos
- **Web player** — HTML5 video + sponsorblock integration (skip sponsor/intro)
- **Shorts** — filter in/out
- **Browser extension (Tube Archivist Companion)** — one-click "archive this video" from YouTube
- **Jellyfin plugin**, **Plex plugin**, **Kodi plugin** — show your archive in your media server
- **Multi-user** with basic roles
- **API** — REST

- Upstream repo: <https://github.com/tubearchivist/tubearchivist>
- Docs: <https://docs.tubearchivist.com>
- Docker Hub: <https://hub.docker.com/r/bbilly1/tubearchivist>
- Discord: <https://www.tubearchivist.com/discord>
- Reddit: <https://www.reddit.com/r/TubeArchivist/>
- Browser extension: <https://github.com/tubearchivist/browser-extension>
- Jellyfin plugin: <https://github.com/tubearchivist/tubearchivist-jf-plugin>
- Plex plugin: <https://github.com/tubearchivist/tubearchivist-plex>

## Architecture in one minute

Multi-container, resource-significant:

1. **tubearchivist** (Django + worker) — web UI + scheduled yt-dlp downloads
2. **Elasticsearch** — indexes all video metadata (full-text search)
3. **Redis** — task queue + cache
4. **yt-dlp** — bundled inside the tubearchivist container

- **RAM baseline**: ~2 GB small, ~4 GB mid-size, more for large ES indices
- **Disk**: your video library — plan 1-5 GB per hour of 1080p video; can balloon fast
- **Network**: downloading is bandwidth-intensive on schedule (often overnight)

## Compatible install methods

| Infra          | Runtime                                              | Notes                                                              |
| -------------- | ---------------------------------------------------- | ------------------------------------------------------------------ |
| Single VM      | **Docker Compose** (upstream)                           | **The way** — 3-container stack                                          |
| Unraid         | Community app                                                  | Popular homelab pattern                                                  |
| Synology       | Community docs (limited by ES RAM)                                  | Works on beefier DSMs                                                            |
| Raspberry Pi   | Possible on Pi 4 with 8 GB but ES is heavy                                | Use a real server if possible                                                              |
| Kubernetes     | Community manifests                                                             | Doable                                                                                   |

## Inputs to collect

| Input              | Example                            | Phase     | Notes                                                          |
| ------------------ | ---------------------------------- | --------- | -------------------------------------------------------------- |
| Domain             | `youtube.example.com`                 | URL       | Reverse proxy with TLS                                             |
| Library path       | `/mnt/youtube:/youtube`                  | Storage   | Where downloaded MP4s live; mount RW                                     |
| Cache path         | `./cache:/cache`                              | Storage   | Thumbnails, chapters, subtitles                                                     |
| Elasticsearch pass | `ELASTIC_PASSWORD`                                 | Auth      | Set once; **losing this = losing the index**                                                  |
| TA_USERNAME        | `admin`                                                   | Bootstrap | Initial admin user                                                                                   |
| TA_PASSWORD        | strong                                                         | Bootstrap | Can be `*_FILE` variant to load from Docker secret                                                         |
| HOST_UID / HOST_GID | `1000` / `1000`                                                   | FS        | Match host user; avoids permission errors on library                                                                   |
| TZ                 | `America/Los_Angeles`                                                    | Locale    | Schedule + timestamps                                                                                                  |
| yt-dlp options     | `YT_DLP_QUALITY=bestvideo[height<=1080]+bestaudio`           | Quality   | Fine-tune format selection                                                                                                        |

## Install via Docker Compose (upstream outline)

```yaml
services:
  tubearchivist:
    image: bbilly1/tubearchivist:v0.5.10   # pin a specific version
    restart: unless-stopped
    depends_on:
      archivist-es: { condition: service_healthy }
      archivist-redis: { condition: service_started }
    environment:
      ES_URL: http://archivist-es:9200
      REDIS_CON: redis://archivist-redis:6379
      HOST_UID: "1000"
      HOST_GID: "1000"
      TA_HOST: youtube.example.com
      TA_USERNAME: admin
      TA_PASSWORD: <strong>
      ELASTIC_PASSWORD: <strong>
      TZ: America/Los_Angeles
    volumes:
      - /mnt/youtube:/youtube
      - ./cache:/cache
    ports:
      - "8000:8000"

  archivist-redis:
    image: redis
    restart: unless-stopped
    depends_on:
      archivist-es: { condition: service_healthy }

  archivist-es:
    image: bbilly1/tubearchivist-es    # pre-configured ES image from upstream
    restart: unless-stopped
    environment:
      ELASTIC_PASSWORD: <strong>
      xpack.security.enabled: "true"
      ES_JAVA_OPTS: "-Xms512m -Xmx512m"
      discovery.type: single-node
      path.repo: "/usr/share/elasticsearch/data/snapshot"
    ulimits:
      memlock: { soft: -1, hard: -1 }
    volumes:
      - ./es:/usr/share/elasticsearch/data
    healthcheck:
      test: ["CMD-SHELL", "curl -s -u elastic:$$ELASTIC_PASSWORD http://localhost:9200 >/dev/null"]
      interval: 30s
      retries: 5
```

Front with Caddy/Traefik for TLS. Browse `https://youtube.example.com` → log in with `TA_USERNAME`.

## First boot

1. Log in as admin
2. **Channels → Subscribe** — paste a channel URL → subscribes; backlog of videos appears
3. Pick a download quality preset in Settings
4. Scheduler kicks in (check cron settings) and starts downloading
5. **Browse/Search** — find + play videos
6. Optional: install the browser extension → one-click archive any YouTube page
7. Optional: install Jellyfin/Plex plugin → your archive appears in your media server

## Data & config layout

- `/youtube/` — MP4 files organized by channel (`<channel>/<video>.mp4`)
- `./es/` — Elasticsearch index (metadata + full-text search)
- `./cache/` — thumbnails, subtitle files, chapter JSON
- Redis volume — task queue state

## Backup

```sh
# ES snapshot (metadata + index — CRITICAL; reindexing 10k videos = slow)
# In TA UI: Settings → Scheduler → Backup → creates tarballs in /cache/backup/

# Media files: back up your library via rsync/borg/rclone
rsync -av /mnt/youtube/ backup-host:/backups/youtube/

# Compose + .env
```

Tube Archivist has a built-in backup feature that snapshots ES + config; configure in Settings.

## Upgrade

1. Releases: <https://github.com/tubearchivist/tubearchivist/releases>. Active.
2. **Back up first** — ES snapshot or TA's built-in backup.
3. Bump tags, `docker compose pull && docker compose up -d`.
4. ES index migrations happen on first boot of new version.
5. Breaking ES schema changes have happened — read release notes.
6. yt-dlp updates come with TA releases; if YouTube breaks yt-dlp mid-version, a dot release usually follows fast.

## Gotchas

- **yt-dlp vs YouTube is a cat-and-mouse game.** YouTube changes something; yt-dlp breaks; the community fixes it within hours-to-days; TA ships a new image. Pin tightly in prod but be ready to update quickly when downloads start failing.
- **Disk space fills fast.** 1080p video = ~1-2 GB/hour. A subscribed channel uploading daily 20-minute videos = ~15 GB/month. Subscribe to 20 such channels = 300 GB/month. Set retention policies + prune old videos.
- **Retention settings** — TA has "keep last N videos per channel" options. Set them before subscribing to a high-volume channel or you'll run out of disk overnight.
- **Elasticsearch is RAM-hungry** — ES is the single biggest memory consumer. Set `ES_JAVA_OPTS=-Xms512m -Xmx512m` for smaller setups (default is higher). Too-low = OOM during indexing; too-high = wasted RAM.
- **File permissions** — set `HOST_UID` / `HOST_GID` to match the user that owns `/mnt/youtube` on the host. Permission errors on media mount are the #1 support question.
- **Shorts filtering** — YouTube Shorts can flood your archive. Settings → Channel → disable Shorts per channel, or globally.
- **Age-restricted + members-only content** — require YouTube account cookies. Export cookies from your browser into a `cookies.txt` and configure TA to use them. Handle with care — the cookies = your YouTube login.
- **2FA on YouTube account** — if you enable 2FA on a Google account used for cookies, the cookies still work but refreshing them is trickier.
- **Private videos** — yt-dlp supports them via cookies; TA inherits that ability.
- **Copyright**: you are downloading copyrighted material. Personal offline archival is generally tolerated (DMCA safe-harbor for users is narrower than for platforms); **do not redistribute, do not host publicly, do not commercialize**. If a creator asks you to take down a copy, do it.
- **YouTube account safety** — if you abuse cookies/API heavily, YouTube may rate-limit or restrict your account. Stick to reasonable download schedules; don't hammer.
- **Jellyfin/Plex plugins** — they make TA's archive appear as a library in your media server so you can play on a TV. Bookmark the plugin install docs in sync with TA version.
- **SponsorBlock** — TA integrates SponsorBlock data to auto-skip sponsored segments during playback. Works in the TA web player; Jellyfin/Plex playback doesn't inherit (use their own SB plugins).
- **yt-dlp extractor bugs** — some channels/playlists have quirks (geo-blocks, region-locked videos, channels that rename). Check logs.
- **Shorts + live streams + premieres** — live streams can be recorded if yt-dlp is invoked during live (rare), premieres work after they end. TA schedules retries.
- **Bandwidth**: if you're on metered/capped internet, be careful. A full channel backfill = hundreds of GB.
- **Legal vs TOS** — YouTube's TOS explicitly prohibits downloading; in most jurisdictions this is a TOS violation (civil), not a criminal act. Personal use is the intent. Respect it.
- **License**: GPL-2.0.
- **Alternatives worth knowing:**
  - **yt-dlp directly** — CLI only; no UI; no auto-subscribe
  - **youtube-dl** — yt-dlp's ancestor; less maintained
  - **Pinchflat** — simpler yt-dlp web UI with Jellyfin integration
  - **PinchFlat / MeTube** — lighter browser-based yt-dlp frontends
  - **Invidious / Piped** — YouTube proxy, not archive (separate recipes)
  - **NewPipe** — Android app, not server
  - **Stacher** — commercial yt-dlp GUI
  - **Choose Tube Archivist if:** you want full archive + search + Jellyfin/Plex integration + scheduled subscriptions.
  - **Choose MeTube/Pinchflat if:** you just want a yt-dlp download queue UI without metadata indexing.
  - **Choose Invidious/Piped if:** you want to *view* YouTube without downloading (no offline).

## Links

- Repo: <https://github.com/tubearchivist/tubearchivist>
- Docs: <https://docs.tubearchivist.com>
- Install: <https://docs.tubearchivist.com/installation/docker-compose/>
- Env vars reference: <https://docs.tubearchivist.com/installation/env-vars/>
- Docker Hub: <https://hub.docker.com/r/bbilly1/tubearchivist>
- Discord: <https://www.tubearchivist.com/discord>
- Reddit: <https://www.reddit.com/r/TubeArchivist/>
- Browser extension: <https://github.com/tubearchivist/browser-extension>
- Jellyfin plugin: <https://github.com/tubearchivist/tubearchivist-jf-plugin>
- Plex plugin: <https://github.com/tubearchivist/tubearchivist-plex>
- FAQ: <https://docs.tubearchivist.com/faq/>
- Releases: <https://github.com/tubearchivist/tubearchivist/releases>
- yt-dlp: <https://github.com/yt-dlp/yt-dlp>
- SponsorBlock: <https://sponsor.ajay.app>
