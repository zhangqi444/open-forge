---
name: YoutubeDL-Material
description: "Material Design web frontend for yt-dlp/youtube-dl. Queue + subscribe-to-channels + MP3/MP4 + Plex integration. Node.js + Angular. License: MIT. Pairs with yt-dlp (active) as the underlying downloader. Active maintenance."
---

# YoutubeDL-Material

YoutubeDL-Material (YDL-M) is **"the Material-Design web UI on top of yt-dlp/youtube-dl"** — a self-hostable web app that wraps yt-dlp with a user-friendly browser interface. Queue downloads; subscribe to YouTube channels + get new uploads automatically; download MP3 audio or MP4 video; organize into folders; preview in-browser; integrate with Plex; share with family + friends. Angular 15 frontend + Node.js backend + optional MongoDB. Heroku-deployable + Docker.

Built + maintained by **Isaac Grynsztein (Tzahi12345)** + community. **License: MIT**. Active since 2018. Docker + Heroku deployment; Twitch VOD chat support via Twitch Downloader CLI integration.

Use cases: (a) **personal offline archive** of YouTube content — videos/channels you care about before they get deleted/blocked (b) **YouTube-as-a-service** locally — queue, download, watch in-browser; no YouTube ads (c) **channel subscriptions** — auto-download new uploads from subscribed channels (d) **MP3 extraction** from YouTube (e) **Plex integration** — drop downloaded content straight into Plex library (f) **Twitch VOD + chat archiving** — integrated optionally (g) **family-safe YouTube** — downloads pre-approved videos; kids watch offline, no autoplay-algorithm rabbithole.

Features (from upstream README):

- **Material Design** web UI (Angular 15)
- **Node.js** backend
- **yt-dlp/youtube-dl** under the hood
- **Queue + subscriptions** — auto-fetch new uploads
- **MP3 + MP4** formats
- **Plex integration**
- **Twitch VOD chat** download (optional, via Twitch Downloader CLI)
- **Docker + Heroku** deploys
- Light/dark mode

- Upstream repo: <https://github.com/Tzahi12345/YoutubeDL-Material>
- Docker Hub: <https://hub.docker.com/r/tzahi12345/youtubedl-material>
- yt-dlp (active descendant): <https://github.com/yt-dlp/yt-dlp>
- youtube-dl (original, slower-moving): <https://github.com/ytdl-org/youtube-dl>
- Twitch Downloader CLI: <https://github.com/lay295/TwitchDownloader>

## Architecture in one minute

- **Angular 15** frontend
- **Node.js 16+** backend
- **Python + yt-dlp** child-processes for actual downloading
- **Optional MongoDB** — for multi-user or subscription features
- **Optional AtomicParsley** — thumbnail embedding
- **Resource**: moderate — 300-600MB RAM, disk for downloads grows
- **Port 17442** default (configurable)

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker compose** | **`tzahi12345/youtubedl-material`**                             | **Primary**                                                                        |
| Heroku             | One-click deploy                                                          | Commercial PaaS                                                                                   |
| Bare-metal         | Node + Python + yt-dlp system-install                                                     | DIY                                                                                               |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Download directory   | `/data/downloads`                                           | Storage      | May grow LARGE (100s of GB)                                                                                    |
| Audio / Video output | MP3 / MP4 preferences                                       | Config       | Per-user + default                                                                                    |
| MongoDB URL          | Optional; enables multi-user + subscriptions                 | DB           | Without it: single-user + ephemeral                                                                                    |
| Admin password       | Protect web UI                                                                           | Auth         | **CRITICAL if exposed**                                                                                    |
| yt-dlp version       | Pinned or latest                                                                                                  | Dependency   | yt-dlp updates frequently (YouTube changes)                                                                                                            |
| Plex integration     | Plex URL + token                                                                                                                 | Integration  | Optional                                                                                                                            |

## Install via Docker

```yaml
services:
  youtubedl-material:
    image: tzahi12345/youtubedl-material:v4.3.2    # **pin version**
    container_name: ytdlm
    restart: unless-stopped
    ports: ["17442:17442"]
    volumes:
      - ./ytdlm-config:/app/appdata
      - ./ytdlm-downloads:/app/downloads
      - ./ytdlm-subscriptions:/app/subscriptions
    # Optional MongoDB service for multi-user / subscriptions
  mongo-db:
    image: mongo:6
    volumes:
      - ./ytdlm-mongo:/data/db
```

## First boot

1. Start → browse `http://host:17442`
2. Configure admin password
3. Set download directory + formats
4. Paste YouTube URL; verify download works
5. Subscribe to a channel; verify auto-fetch
6. Configure Plex integration (optional)
7. Put behind TLS reverse proxy + auth (don't expose naked)
8. Plan for disk-growth; set retention policy
9. Back up config + mongo + subscriptions folder

## Data & config layout

- `appdata/` — config + user state
- `downloads/` — downloaded media (GROWS UNBOUNDED)
- `subscriptions/` — subscription state + auto-downloaded content
- MongoDB (optional)

## Backup

```sh
sudo tar czf ytdlm-config-$(date +%F).tgz ytdlm-config/ ytdlm-subscriptions/
# Do NOT back up ytdlm-downloads/ unless specifically needed (can be huge)
# MongoDB: mongodump
```

## Upgrade

1. Releases: <https://github.com/Tzahi12345/YoutubeDL-Material/releases>. Active.
2. Docker: pull + restart.
3. **yt-dlp inside container needs periodic update** — YouTube constantly changes + breaks extractors. Container ships with yt-dlp; upgrades ship new yt-dlp. Occasionally, yt-dlp emergency-updates are needed faster than the YDL-M release cycle → update yt-dlp inside the container or pin to newer yt-dlp-only image variant (or maintain own fork).

## Gotchas

- **YOUTUBE TERMS OF SERVICE + LEGALITY**:
  - **YouTube ToS prohibits downloading** content unless a download button is visible
  - **User-facing reality**: downloading for personal offline use is widely done + rarely enforced
  - **Copyright law** varies by jurisdiction: fair-use / private-copy exceptions exist in many (but not all) regions
  - **DMCA + YouTube's automated-removal requests** have been sent to yt-dlp / youtube-dl repos (famously, RIAA→youtube-dl DMCA'd in 2020, GitHub reinstated after EFF intervention)
  - **Running YDL-M for personal use**: low risk
  - **Running YDL-M as public service**: HIGH risk — YouTube + rights-holders will take action
  - **17th tool in network-service-legal-risk family** joining Dispatcharr 96 platform-content-conduit-risk. **NEW: "content-download-from-commercial-platform-risk" sub-family** — distinct from IPTV-piracy-conduit (live streams) + *arr-piracy (torrent indexers) + platform-front-end-proxy (Redlib viewing). YDL-M records+stores+redistributes content. **8th sub-family of network-service-legal-risk.**
- **YOUTUBE CONSTANTLY BREAKS yt-dlp**: Google updates YouTube's player/API/obfuscation frequently (weekly-to-monthly). yt-dlp responds with new releases. If YDL-M ships old yt-dlp, downloads start failing. **Keep yt-dlp updated; pin YDL-M at a version known to work or use rolling-latest with caution.**
- **CAPTCHAS + RATE LIMITING**: YouTube may serve CAPTCHA / throttle / IP-block your server if it detects high-volume downloading. Mitigations:
  - Use cookies from a logged-in account (reduces CAPTCHAs; but risks account-ban if policy-violating)
  - Throttle downloads; use `sleep_interval`
  - Rotate IPs (VPN-sidecar pattern, batch 96)
- **DOWNLOAD DISK GROWTH UNBOUNDED** — set retention policy:
  - Auto-delete watched / N-days-old
  - Set a cap; rotate oldest
  - Monitor with `du -sh` regularly
- **HUB-OF-CREDENTIALS LIGHT → TIER 2**:
  - YouTube cookies (if used — account-compromise risk; elevate to Tier 2)
  - Plex token (if integrated)
  - Admin password
  - Mongo creds
  - **50th tool in hub-of-credentials family — LIGHT without cookies; Tier 2 with cookies.**
- **PUBLIC-EXPOSURE = MAJOR RISK**: if YDL-M is exposed publicly, anyone can:
  - Submit download requests → exhaust your disk + bandwidth
  - Download copyrighted material → DMCA'd to your IP + hosting provider
  - Harvest your YouTube cookies (if stored)
  - **DO NOT expose YDL-M publicly; use VPN / Tailscale / reverse-proxy-auth.**
- **ANGULAR 15 FRONTEND = LEGACY VERSION CONCERN**: Angular releases frequently. Angular 15 is 2022-era; no security-fixes after 2024. For a newer-code-project this is tolerable; for long-term, watch for framework upgrade.
- **MONGODB OPTIONAL BUT RECOMMENDED**: without Mongo, you lose multi-user + subscription features. Simplest self-host is single-user + no Mongo; power-user is with Mongo.
- **SOLE-MAINTAINER-WITH-COMMUNITY**: Isaac Grynsztein (Tzahi12345) + contributors. **17th tool in sole-maintainer-with-community class.**
- **TRANSPARENT-MAINTENANCE**: MIT + active since 2018 + Docker badge metrics + contributors. **32nd tool in transparent-maintenance family.**
- **MIT LICENSE**: permissive; commercial-reuse-friendly.
- **SUSTAINABILITY**: no commercial-Cloud tier; no sponsor-wall observed in README; pure community maintenance. Sustainability = single-maintainer + community contribution. **17th tool in pure-donation/community.**
- **yt-dlp vs youtube-dl HISTORICAL NOTE**: youtube-dl was the original (ytdl-org). yt-dlp is the active fork that moved faster + gained feature-parity+. youtube-dl still lives but yt-dlp is the go-to. YDL-M supports both. **Forking-after-slowdown** pattern (not archival — youtube-dl still alive but slower). Applicable sub-pattern of **forking-after-upstream-archival** (Redlib 95 batch).
- **TWITCH VOD CHAT DOWNLOAD INTEGRATION** — novel feature; requires Twitch Downloader CLI as separate install.
- **PLEX/JELLYFIN/EMBY INTEGRATION ARCHITECTURE**: downloaded content goes into a directory Plex watches. No Plex-specific magic; any media server will pick up the downloads. The "Plex integration" in YDL-M is primarily around triggering library scans or path structures.
- **CATEGORY: CONTENT-DOWNLOAD-FROM-COMMERCIAL-PLATFORM**: YDL-M joins an emerging category:
  - **MeTube** — simpler yt-dlp web wrapper
  - **Tubearchivist** — heavier YouTube-archiving tool (channel-archive focus)
  - **Pinchflat** — YouTube-to-Plex/Jellyfin tool
  - **JDownloader** — multi-site download manager
  - **youtube-dl-webui-plus** — various similar
  - **NEW "content-download-wrapper" category** — web UIs on yt-dlp. Common: YouTube-ToS-risk + yt-dlp-stale-risk + disk-growth + public-exposure-DMCA-risk.
- **RECIPE CONVENTION: "yt-dlp-dependent-tool" status**: tools that wrap yt-dlp share common operational concerns. Applicable to: YDL-M, MeTube, Tubearchivist, Pinchflat, Cobalt (web-based yt-dlp alternative).
- **ALTERNATIVES WORTH KNOWING:**
  - **MeTube** — minimalist yt-dlp web UI; lighter; Docker
  - **Tubearchivist** — YouTube archive-oriented; heavier; Elasticsearch-based
  - **Pinchflat** — YouTube-to-media-server; Plex/Jellyfin-focused; Elixir
  - **Cobalt** — newer; browser-first; simpler
  - **yt-dlp CLI** — if you prefer terminal
  - **JDownloader** — commercial-free-ish; multi-platform; broader
  - **Choose YDL-M if:** you want MATERIAL-UI + queue + subscriptions + Plex + MIT + mature.
  - **Choose MeTube if:** you want minimal + lighter.
  - **Choose Tubearchivist if:** you want YouTube-archive-centric + rich search.
  - **Choose Pinchflat if:** you want deep Plex/Jellyfin integration.
- **PROJECT HEALTH**: active + MIT + Docker + sustained-6-year-development. Single-maintainer-sustainability watch.

## Links

- Repo: <https://github.com/Tzahi12345/YoutubeDL-Material>
- Docker: <https://hub.docker.com/r/tzahi12345/youtubedl-material>
- yt-dlp: <https://github.com/yt-dlp/yt-dlp>
- youtube-dl: <https://github.com/ytdl-org/youtube-dl>
- Twitch Downloader: <https://github.com/lay295/TwitchDownloader>
- MeTube (alt): <https://github.com/alexta69/metube>
- Tubearchivist (alt): <https://tubearchivist.com>
- Pinchflat (alt): <https://github.com/kieraneglin/pinchflat>
- Cobalt (alt): <https://cobalt.tools>
- Plex: <https://plex.tv>
