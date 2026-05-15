---
name: Swing Music
description: "Blazingly fast self-hosted music streaming server. Daily Mixes, metadata normalization, silence-detection crossfade. Android client. Python + Vue. swingmx org. GitHub Sponsors. swingmx.com docs + screenshots. r/SwingMusicApp."
---

# Swing Music

Swing Music is **"Spotify but bring-your-own-music + self-hosted"** — a blazingly fast, beautiful music streaming server. Local library → daily-mixes, artist + album pages, metadata-normalization, folder browsing, silence-detection crossfade, collections, statistics. Android client. GitHub Sponsors.

Built + maintained by **swingmx** org. Python + Vue likely. Android companion app. swingmx.com site with downloads + screenshots + docs + guide. Reddit community (r/SwingMusicApp).

Use cases: (a) **self-hosted music streaming** (b) **Plexamp alternative** (c) **local-library-first streaming** (d) **daily-mix / Spotify-DJ clone on own music** (e) **folder-view for collectors** (f) **cross-fade + silence-detect for DJ-ish listening** (g) **album-version awareness** (Deluxe/Remaster) (h) **Android-client companion for mobile listening**.

Features (per README):

- **Daily Mixes** — curated from listening activity
- **Metadata normalization**
- **Album versioning** (Deluxe/Remaster)
- **Related artists + albums**
- **Folder view**
- **Beautiful browser UI**
- **Silence-detection crossfade**
- **Collections**
- **Statistics**
- **Android client**

- Upstream repo: <https://github.com/swingmx/swingmusic>
- Website: <https://swingmx.com>
- Downloads: <https://swingmx.com/downloads>
- Docs: <https://swingmx.com/guide/introduction.html>
- Android: <https://github.com/swingmx/android>
- Sponsor: <https://github.com/sponsors/swingmx>
- Reddit: <https://www.reddit.com/r/SwingMusicApp>

## Architecture in one minute

- **Python** backend + **Vue** frontend likely
- SQLite default
- Indexes local filesystem music
- **Resource**: moderate; metadata-scan can be CPU-heavy initially
- **Port**: HTTP

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Binary**         | Per swingmx.com/downloads                                                                                              | **Primary**                                                                                   |
| **Docker**         | Community images                                                                                                       | Alt                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `music.example.com`                                         | URL          | TLS for Android-client                                                                                    |
| Music library path   | `/music`                                                    | Storage      | **RO mount recommended**                                                                                    |
| Admin                | Bootstrap                                                   | Auth         |                                                                                    |
| Android app          | Per-device                                                  | Clients      |                                                                                    |

## Install via Docker

Check community Docker images. Typical pattern:
```yaml
services:
  swingmusic:
    image: ghcr.io/swingmx/swingmusic:v2.1.4        # **pin** — check upstream
    ports: ["1970:1970"]
    volumes:
      - /music:/music:ro        # **RO mount**
      - ./swingmusic-data:/data
    restart: unless-stopped
```

## First boot

1. Start; browse UI
2. Configure library path
3. Let metadata scan complete (can take minutes-hours for big libraries)
4. Create first playlist / mix
5. Install Android client; connect
6. Put behind TLS
7. Back up `/data` (DB + artwork cache)

## Data & config layout

- `/data/` — SQLite, cached artwork, metadata
- `/music/` — your music files (separate, RO)

## Backup

```sh
sudo tar czf swingmusic-$(date +%F).tgz swingmusic-data/
# Music files backed up separately (likely already)
```

## Upgrade

1. Releases: <https://github.com/swingmx/swingmusic/releases>
2. Docker/binary pull + restart
3. Android app separately

## Gotchas

- **176th HUB-OF-CREDENTIALS Tier 3 — MUSIC-LIBRARY + LISTENING-STATS**:
  - Holds: library index, listening history, user prefs
  - Music files typically RO
  - Statistics = listening-habit-PII
  - **176th tool in hub-of-credentials family — Tier 3**
- **LISTENING-STATS-PII**:
  - Detailed listening history = behavioral PII
  - **Recipe convention: "listening-history-PII-retention-discipline callout"**
  - **NEW recipe convention** (Swing Music 1st formally)
- **READ-ONLY-LIBRARY-MOUNT**:
  - Music library should be RO
  - **Read-only-library-mount-discipline: 4 tools** 🎯 **4-TOOL MILestone** (+Swing Music)
- **METADATA-NORMALIZATION**:
  - Writes back? Check behavior — could modify tags
  - **Recipe convention: "metadata-write-back-flag-review callout"**
  - **NEW recipe convention** (Swing Music 1st formally)
- **NATIVE-ANDROID-COMPANION-APP**:
  - Separate swingmx/android repo
  - **Native-mobile-companion-app: 4 tools** 🎯 **4-TOOL MILESTONE** (+Swing Music)
- **REDDIT-COMMUNITY**:
  - r/SwingMusicApp
  - Community-driven discourse
  - **Recipe convention: "Reddit-subreddit-community-channel neutral-signal"**
  - **NEW neutral-signal convention** (Swing Music 1st formally)
  - **Reddit-community-channel: 1 tool** 🎯 **NEW FAMILY** (Swing Music)
- **GITHUB-SPONSORS-FUNDED**:
  - **GitHub-Sponsors-funding: 3 tools** (DockFlare+Podsync+Swing Music) 🎯 **3-TOOL MILESTONE**
- **CLIENT-APPS-FOR-MOBILE**:
  - Server + client-apps architecture (distinct from Retrom's dedicated-emu-client)
  - **Client-server-architecture: 2 tools** (Retrom+Swing Music) 🎯 **2-TOOL MILESTONE**
- **SILENCE-DETECTION-CROSSFADE**:
  - Rare feature; audio-processing quality-of-life
  - **Recipe convention: "silence-detection-crossfade-audio-processing positive-signal"**
  - **NEW positive-signal convention** (Swing Music 1st formally)
- **INSTITUTIONAL-STEWARDSHIP**: swingmx org + website + docs + Android companion + Sponsors + Reddit. **162nd tool — music-tool-multi-channel-stewardship sub-tier** (NEW-soft).
- **TRANSPARENT-MAINTENANCE**: active + releases + docs + Android-repo + multi-channel. **168th tool in transparent-maintenance family.**
- **MUSIC-STREAMING-CATEGORY:**
  - **Swing Music** — modern; fast; silence-detect crossfade; Android
  - **Navidrome** — dominant OSS; Subsonic-API compat
  - **Jellyfin** — generalist media (music included)
  - **Airsonic-Advanced** — Subsonic fork
  - **Plexamp** — commercial (Plex tier)
  - **Funkwhale** — federated + podcasts
- **ALTERNATIVES WORTH KNOWING:**
  - **Navidrome** — if you want dominant + Subsonic-API
  - **Funkwhale** — if you want federation + podcasts
  - **Choose Swing Music if:** you want modern + fast + silence-detect + daily-mixes.
- **PROJECT HEALTH**: active + website + docs + Android + Sponsors + Reddit. Strong.

## Links

- Repo: <https://github.com/swingmx/swingmusic>
- Website: <https://swingmx.com>
- Android: <https://github.com/swingmx/android>
- Navidrome (alt): <https://github.com/navidrome/navidrome>
- Funkwhale (alt): <https://github.com/funkwhale/funkwhale>
