---
name: TubeSync
description: "PVR for YouTube — syncs channels + playlists to local server as if they were TV-show seasons. Django + yt-dlp + ffmpeg. AGPL-3.0. meeb maintainer; active; Docker-first."
---

# TubeSync

TubeSync is **"Sonarr / Radarr / Lidarr — but for YouTube"** — a PVR-style PVR (personal video recorder) for YouTube that syncs channels + playlists to a local server as if they were TV-show seasons. Downloads + archives + organizes into library for Plex/Jellyfin/Emby/Kodi. Django + yt-dlp + ffmpeg. Automatically checks for new videos on configurable schedule; downloads + renames + files in folder structures compatible with media-servers.

Built + maintained by **Meeb (meeb)** + community. License: **AGPL-3.0**. Active; Docker images primary; extensive docs; Discord; community forums.

Use cases: (a) **YouTube channel auto-archive** — download every new video from favourite creator (b) **offline watching** — kids' content offline for travel (c) **content-preservation** — creator deletes channel / gets banned → you have backup (d) **Jellyfin/Plex library** — YouTube channels appear as TV shows with seasons/episodes (e) **creator discography** — complete channel download for research/reference (f) **bandwidth-shifting** — download at night; watch anytime (g) **kids YouTube without YouTube UI** — no recommendation algorithm (h) **educational content archive** — tutorials + lectures preserved.

Features (per README + docs):

- **YouTube channels + playlists** sync
- **yt-dlp** engine
- **Django** web UI
- **Scheduled checks** + download
- **Plex/Jellyfin/Emby/Kodi** compatible file layout
- **Rate-limiting** + retry logic
- **Quality selection** per source
- **SponsorBlock** integration
- **Cookies** for age-gated content
- **Database**: SQLite by default; PostgreSQL optional

- Upstream repo: <https://github.com/meeb/tubesync>
- Docker Hub: <https://hub.docker.com/r/ghcr.io/meeb/tubesync>

## Architecture in one minute

- **Python + Django**
- **yt-dlp** + **ffmpeg**
- **SQLite / PostgreSQL** DB
- **Celery / Django-Q** task-scheduler
- **Resource**: moderate — 500MB-1GB RAM; CPU for ffmpeg re-mux
- **Port 4848** default

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker**         | **Upstream images**                                             | **Primary**                                                                        |
| Source             | Django + yt-dlp + ffmpeg                                                                            | Dev                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `tubesync.example.com`                                      | URL          | TLS                                                                                    |
| Output library path  | Shared with Plex/Jellyfin                                   | Storage      | Can be LARGE                                                                                    |
| DB                   | SQLite default                                              | DB           | PostgreSQL for large libraries                                                                                    |
| Sources              | Channel URLs + playlist URLs                                | Config       |                                                                                    |
| Schedule             | Check interval per-source                                   | Config       |                                                                                    |
| Cookies (opt)        | For age-gated content                                       | Auth         |                                                                                    |
| SponsorBlock (opt)   | Auto-skip sponsors                                                                                   | Config       |                                                                                    |

## Install via Docker

```yaml
services:
  tubesync:
    image: ghcr.io/meeb/tubesync:v0.17.3        # **pin version**
    environment:
      PUID: 1000
      PGID: 1000
      TZ: America/Los_Angeles
    volumes:
      - ./config:/config
      - ./downloads:/downloads
    ports: ["4848:4848"]
    restart: unless-stopped
```

## First boot

1. Start → browse `:4848`
2. Add first source (YouTube channel URL)
3. Configure output directory + naming
4. Wait for initial sync (may be large)
5. Verify output matches Plex/Jellyfin expected structure
6. Configure schedule
7. Put behind TLS reverse proxy
8. Back up DB + config

## Data & config layout

- `/config/` — Django state + SQLite DB
- `/downloads/` — actual video files
- Library-structure: `/downloads/<source>/Season-XX/...` Plex-compatible

## Backup

```sh
sudo tar czf tubesync-config-$(date +%F).tgz config/
# Videos typically not backed up (re-downloadable from source if still exists)
```

## Upgrade

1. Releases: <https://github.com/meeb/tubesync/releases>. Active.
2. Docker pull + restart; migrations auto-run
3. **yt-dlp updates frequently** — upstream images track

## Gotchas

- **OVERLAP WITH YTDL-SUB (105)**:
  - **ytdl-sub** — YAML-driven CLI; strong metadata adapters
  - **TubeSync** — Django web UI; Sonarr-style PVR paradigm
  - **Choose by preference**: web UI vs YAML
  - **YouTube-PVR-category**: 2 tools (ytdl-sub + TubeSync); adjacent to YouTubeDL-Material (97) / metube / PinchFlat
- **YT-DLP API DRIFT** (same as ytdl-sub 105):
  - YouTube changes break yt-dlp → TubeSync follows
  - Stale TubeSync = broken downloads
  - **Recipe convention: "yt-dlp-API-drift-risk"** — 2 tools now (ytdl-sub + TubeSync)
- **COPYRIGHT + YOUTUBE TOS**:
  - Same as ytdl-sub
  - **Copyright-content-hosting-risk META-FAMILY: now 5 tools** (Grimmory + Wizarr + ytdl-sub + Flood + TubeSync)
- **RATE-LIMITING**:
  - Multiple channels × frequent checks = IP-level rate-limit / IP-ban risk
  - TubeSync defaults are conservative
  - **Recipe convention: "media-scraping-rate-limit"** extended (ytdl-sub 105 precedent)
- **DISK-SPACE CATASTROPHE**:
  - YouTube channel can be 100s of GBs (10-year creator)
  - Start with small channels; add disk before adding large channels
  - **Recipe convention: "TB-scale-storage-requirement" extended**: now 3 tools (Steam Headless + ytdl-sub + TubeSync)
- **COOKIES = GOOGLE-ACCOUNT-CREDENTIALS**:
  - Same risk as ytdl-sub
  - **Browser-cookie-login-credential-risk** applies (ytdl-sub 105 precedent)
- **YOUTUBE CHANNEL DELETION = DATA LOSS MITIGATION**:
  - Primary legitimate use-case: preserve before takedown
  - **Recipe convention: "pre-deletion-archive use-case" positive-rationale**
- **AGPL-3.0 NETWORK-SERVICE**:
  - Self-host + expose = AGPL disclosure applies
  - **16th tool in AGPL-network-service-disclosure**
- **HUB-OF-CREDENTIALS TIER 2/3**:
  - YouTube cookies (if used) = HIGH
  - Without cookies: Tier 3
  - **87th tool in hub-of-credentials family**
- **SPONSORBLOCK INTEGRATION**:
  - Auto-skip sponsor segments
  - **Positive-signal: "SponsorBlock-integration"** (ytdl-sub 105 precedent)
- **INSTITUTIONAL-STEWARDSHIP**: meeb + community. **73rd tool — sole-maintainer-with-community sub-tier (33rd).**
- **TRANSPARENT-MAINTENANCE**: active + Docker + docs + AGPL + releases + yt-dlp-upstream-tracking. **81st tool in transparent-maintenance family.**
- **YOUTUBE-PVR-CATEGORY:**
  - **TubeSync** — Django web UI; Sonarr-style
  - **ytdl-sub** (105) — YAML CLI
  - **YouTubeDL-Material** (97) — web UI simpler
  - **PinchFlat** — Elixir
  - **metube** — Docker + minimal UI
- **ALTERNATIVES WORTH KNOWING:**
  - **ytdl-sub** — if you prefer YAML
  - **PinchFlat** — if you prefer Elixir
  - **metube** — if you want minimal UI + Docker
  - **Choose TubeSync if:** you want Sonarr-style PVR + Django web UI + Docker.
- **PROJECT HEALTH**: active + Docker + docs + community. Strong.

## Links

- Repo: <https://github.com/meeb/tubesync>
- ytdl-sub (batch 105): <https://github.com/jmbannon/ytdl-sub>
- YouTubeDL-Material (batch 97): <https://github.com/Tzahi12345/YoutubeDL-Material>
- PinchFlat (alt): <https://github.com/kieraneglin/pinchflat>
- metube (alt): <https://github.com/alexta69/metube>
- yt-dlp: <https://github.com/yt-dlp/yt-dlp>
