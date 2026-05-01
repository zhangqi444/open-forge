---
name: Podsync
description: "Turn YouTube + Vimeo channels/playlists into podcast feeds. Go. mxpv/podsync. Cron-based. OPML export. GitHub Sponsors + Patreon funded. Nightly CI + Go Report badges."
---

# Podsync

Podsync is **"YouTube/Vimeo → podcast-RSS bridge"** — a simple, free service that lets you listen to any YouTube or Vimeo channel, playlist, or user videos in **podcast format**. Podcast apps get auto-download, sync, offline — none of which YouTube/Vimeo provide natively.

Built + maintained by **mxpv**. Go. GitHub Sponsors + Patreon. CI + nightly-CI + Go Report Card badges.

Use cases: (a) **subscribe to YouTube channels** in Overcast/Pocket Casts (b) **offline-listen to Vimeo content** (c) **mp3-extract lectures/talks** (d) **follow creators without YouTube app** (e) **privacy-preserving YouTube consumption** (no tracking-app) (f) **audio-only from video content** (g) **cron-scheduled updates** (h) **automated podcast feed for your own channel subset**.

Features (per README):

- **YouTube + Vimeo** support
- **Video or audio**, quality + height selectable
- **mp3 encoding**
- **Cron-expression** scheduler
- **Episode filtering** (title + duration)
- **Feed customization** (artwork, category, language)
- **OPML export**
- **Episode cleanup** (keep last X)
- **Configurable hooks** for custom workflows

- Upstream repo: <https://github.com/mxpv/podsync>
- Sponsor: <https://github.com/sponsors/mxpv> + <https://www.patreon.com/podsync>

## Architecture in one minute

- **Go** binary
- **yt-dlp / youtube-dl** under the hood (likely)
- **ffmpeg** for mp3-encode
- **Resource**: low-moderate; burst during download
- **Port**: HTTP for RSS-feed + media

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker**         | Upstream                                                                                                               | **Primary**                                                                                   |
| **Binary**         | Native                                                                                                                 | Alt                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| YouTube API key      | Google Cloud console                                        | Secret       | Free-tier-quota limits                                                                                    |
| Vimeo token (opt)    | For Vimeo feeds                                             | Secret       | Optional                                                                                    |
| Domain               | `podsync.example.com`                                       | URL          | Podcast apps need HTTPS                                                                                    |
| Storage              | mp3/mp4 cache                                               | Storage      | Can grow large                                                                                    |
| Feeds config         | Per-channel cron + filters                                  | Config       | `config.toml`                                                                                    |

## Install via Docker

```yaml
services:
  podsync:
    image: mxpv/podsync:latest        # **pin**
    ports: ["8080:8080"]
    volumes:
      - ./podsync-config:/config        # config.toml here
      - ./podsync-data:/data            # mp3/mp4 cache
    restart: unless-stopped
```

Example `config.toml`:
```toml
[server]
port = 8080
hostname = "https://podsync.example.com"

[tokens]
youtube = "YOUR_API_KEY"

[feeds.my-lectures]
url = "https://www.youtube.com/c/example-channel"
update_period = "6h"
format = "audio"
quality = "low"
page_size = 20
cron_schedule = "0 */6 * * *"
clean.keep_last = 50
```

## First boot

1. Get YouTube API key (quota-limited)
2. Write config.toml with feeds
3. Start Podsync
4. Let cron pull first batch
5. Browse RSS at `https://podsync.example.com/my-lectures.xml`
6. Subscribe in podcast app
7. Put behind TLS (podcast apps enforce HTTPS)
8. Back up config + data

## Data & config layout

- `/config/config.toml`
- `/data/` — cached media

## Backup

```sh
sudo tar czf podsync-$(date +%F).tgz podsync-config/
# Media cache is regenerable — exclude if too big
```

## Upgrade

1. Releases: <https://github.com/mxpv/podsync/releases>
2. Check config.toml schema changes
3. Docker pull + restart

## Gotchas

- **172nd HUB-OF-CREDENTIALS Tier 2 — YOUTUBE-API-KEY + VIMEO-TOKEN**:
  - Holds: YouTube API key (quota), Vimeo token, optionally cookies for private/age-gated content
  - **172nd tool in hub-of-credentials family — Tier 2**
- **YOUTUBE-TOS-AWARENESS**:
  - Downloading YouTube content has TOS + copyright considerations
  - yt-dlp usage in gray zone
  - **Recipe convention: "YouTube-TOS-personal-use-discipline callout"**
  - **NEW recipe convention** (Podsync 1st formally)
- **YOUTUBE-API-QUOTA**:
  - Free-tier daily quota 10k units
  - Feed-heavy config can exhaust
  - **Recipe convention: "API-quota-budget-planning callout"**
  - **NEW recipe convention** (Podsync 1st formally)
- **HTTPS-MANDATORY-FOR-PODCAST-APPS**:
  - Apple Podcasts + most apps require HTTPS
  - **Recipe convention: "podcast-RSS-HTTPS-mandatory callout"**
  - **NEW recipe convention** (Podsync 1st formally)
- **STORAGE-GROWTH-UNBOUNDED**:
  - mp3/mp4 cache grows; use clean.keep_last
  - **Recipe convention: "media-cache-cleanup-policy-discipline callout"**
  - **NEW recipe convention** (Podsync 1st formally)
- **DUAL-SPONSOR (GH Sponsors + Patreon)**:
  - Multi-platform funding
  - **Multi-platform-funding: 1 tool** 🎯 **NEW FAMILY** (Podsync — distinct from single-platform-funding tools)
  - **GitHub-Sponsors-funding: 2 tools** (DockFlare+Podsync) 🎯 **2-TOOL MILESTONE**
  - **Patreon-sponsored: 2 tools** (Cloud Commander+Podsync) 🎯 **2-TOOL MILESTONE**
- **GO-REPORT-CARD**:
  - Public go-quality
  - **Go-Report-Card-transparent-quality: 2 tools** (Notifuse-A+, Podsync) 🎯 **2-TOOL MILESTONE** (transparent reporting)
- **NIGHTLY-CI**:
  - **Nightly-CI-quality-ops: 2 tools** (Jellystat+Podsync) 🎯 **2-TOOL MILESTONE**
- **HOOKS-FOR-CUSTOM-INTEGRATIONS**:
  - **Plugin-API-architecture: 4 tools** 🎯 **4-TOOL MILESTONE** (continuing)
- **OPML-EXPORT**:
  - Standard format export
  - **Recipe convention: "standard-format-export-portability positive-signal"**
  - **NEW positive-signal convention** (Podsync 1st formally)
- **INSTITUTIONAL-STEWARDSHIP**: mxpv sole-dev + dual-sponsor + Go-Report + nightly-CI + plugin-hooks + OPML-export. **158th tool — responsibly-funded-sole-dev sub-tier** (NEW-soft).
- **TRANSPARENT-MAINTENANCE**: active + nightly-CI + Go-Report + releases + dual-funding. **164th tool in transparent-maintenance family.**
- **YOUTUBE-TO-RSS-CATEGORY:**
  - **Podsync** — YouTube + Vimeo → podcast
  - **rsshub** — RSS-hub for many sources including YouTube
  - **FreshRSS + YouTube-feed ext** — if you already run FreshRSS
  - **Invidious** — alternative frontend (different use-case)
- **ALTERNATIVES WORTH KNOWING:**
  - **RSSHub** — if you want many-source aggregator
  - **Choose Podsync if:** you want podcast-format output + mp3-encoding + offline.
- **PROJECT HEALTH**: active + dual-funding + Go-Report + nightly-CI. Strong sole-dev project.

## Links

- Repo: <https://github.com/mxpv/podsync>
- RSSHub (alt): <https://github.com/DIYgod/RSSHub>
