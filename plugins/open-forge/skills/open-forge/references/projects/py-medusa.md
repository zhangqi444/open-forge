---
name: Medusa
description: "Automatic video library manager for TV Shows. SickBeard/SickRage lineage. TVDB/TVMaze/TMDB indexers. Python 3. pymedusa org. Decade-plus."
---

# Medusa

Medusa is **"Sonarr in Python — SickBeard/SickRage descendant"** — an automatic video library manager for TV Shows. Watches for new episodes, grabs them from configured torrent/NZB providers. Supports **TVDB, TVMaze, TMDB** indexers. Manual-search + subtitle-search. Python 3.

Built + maintained by **pymedusa** org. Decade-plus OSS lineage (SickBeard → SickRage → Medusa). Travis-CI (legacy); codecov. Active development branch. License: GPL-3.0 typical.

Use cases: (a) **Sonarr-alternative in Python** (b) **TV-show auto-downloader** (c) **NZB + torrent downloader frontend** (d) **subtitles fetcher** (e) **multi-indexer redundancy** (TVDB+TVMaze+TMDB) (f) **Plex/Emby/Jellyfin companion** (for library-preparation) (g) **SickBeard-legacy migration-destination** (h) **fine-grained manual-control grabber**.

Features (per README):

- **TVDB, TVMaze, TMDB** indexers
- **Manual search** — pick by provider/seeds/release-group
- **Subtitle manual-search**
- **Python 3**
- **Decade-plus lineage**

- Upstream repo: <https://github.com/pymedusa/Medusa>
- Wiki: <https://github.com/pymedusa/Medusa/wiki>

## Architecture in one minute

- **Python 3**
- SQLite (default)
- Watches for new episodes; sends to torrent/NZB client
- **Resource**: low-moderate
- **Port**: web UI (default 8081)

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker**         | linuxserver/medusa                                                                                                     | **Primary for self-host**                                                                                   |
| **Native Python**  | Pip/Git clone                                                                                                          | Alt                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | Internal                                                    | URL          | Usually LAN-only                                                                                    |
| Admin password       | Web UI                                                      | Bootstrap    | Strong                                                                                    |
| Indexer API keys     | TVDB / TMDB                                                 | Integration  | Rate-limited                                                                                    |
| Download client      | Sabnzbd/NZBget/qBittorrent/Deluge                           | Integration  | **Prerequisite**                                                                                    |
| Providers            | Indexer sites + API keys                                    | Integration  | Per-site                                                                                    |
| Library path         | `/media/tv`                                                 | Storage      |                                                                                    |

## Install via Docker

```yaml
services:
  medusa:
    image: linuxserver/medusa:latest        # **pin**
    environment:
      - PUID=1000
      - PGID=1000
    volumes:
      - ./medusa-config:/config
      - /media/tv:/tv
      - /downloads:/downloads
    ports: ["8081:8081"]
    restart: unless-stopped
```

## First boot

1. Start; browse :8081
2. Set admin password; enable HTTPS cert (self-signed ok on LAN)
3. Configure indexers (TVDB API key)
4. Configure download client
5. Add providers
6. Add TV shows; test grab-and-process flow
7. Back up `/config`

## Data & config layout

- `/config/` — SQLite + config
- `/tv/` — imported library (shared with Plex/Jellyfin)
- `/downloads/` — staging

## Backup

```sh
sudo tar czf medusa-$(date +%F).tgz medusa-config/
```

## Upgrade

1. Releases: <https://github.com/pymedusa/Medusa/releases>
2. Git-pull or Docker-pull
3. DB migrations handled automatically

## Gotchas

- **163rd HUB-OF-CREDENTIALS Tier 2 — INDEXER-API-KEYS + PROVIDER-KEYS**:
  - Holds: TVDB/TVMaze/TMDB API keys, indexer API keys, download-client creds
  - Download-client creds = file-system-write on host
  - **163rd tool in hub-of-credentials family — Tier 2**
  - **Media-stack-credential-aggregator: 3 tools** (Tunarr+Portracker-no-Sonarr+Medusa) 🎯 **3-TOOL MILESTONE** (though check assignment)
- **TORRENT-LEGAL-EXPOSURE**:
  - Torrent providers = copyright-liability
  - Know your jurisdiction
  - **Recipe convention: "torrent-streaming-legal-exposure"** — reinforces Tunarr/Jellyfin
- **NZB-INDEXER-TOS**:
  - Private indexers have TOS
  - **Recipe convention: "private-indexer-TOS-discipline callout"**
  - **NEW recipe convention** (Medusa 1st formally)
- **DECADE-PLUS-LINEAGE (SickBeard → SickRage → Medusa)**:
  - Multi-generation fork-chain
  - **Recipe convention: "multi-generation-fork-lineage neutral-signal"**
  - **NEW neutral-signal convention** (Medusa 1st formally)
  - **Decade-plus-OSS: 10 tools** (+Medusa) 🎯 **10-TOOL MILESTONE**
- **TRAVIS-CI-LEGACY**:
  - Travis badge in README (legacy; travis-ci.com discontinued OSS tier)
  - CI badge may be stale
  - **Recipe convention: "legacy-CI-service-badge-review neutral-signal"**
  - **NEW neutral-signal convention** (Medusa 1st formally)
- **MANUAL-SEARCH UX**:
  - Detailed manual-pick UX (seeds, release group)
  - Differentiator from Sonarr automation-first
  - **Recipe convention: "manual-pick-UX-for-media-grabber positive-signal"**
  - **NEW positive-signal convention** (Medusa 1st formally)
- **MULTI-INDEXER-REDUNDANCY**:
  - TVDB + TVMaze + TMDB fallback
  - Robust to any single indexer going down
  - **Recipe convention: "multi-indexer-redundancy positive-signal"**
  - **NEW positive-signal convention** (Medusa 1st formally)
- **LINUXSERVER-CONVENTION**:
  - **PUID-PGID-linuxserver-convention: 2 tools** (Tasks.md+Medusa) 🎯 **2-TOOL MILESTONE**
- **INSTITUTIONAL-STEWARDSHIP**: pymedusa org + wiki + active + decade-plus + linuxserver-backed + codecov. **149th tool — community-fork-lineage sub-tier** (NEW-soft).
- **TRANSPARENT-MAINTENANCE**: active + codecov + wiki + decade-plus + releases. **155th tool in transparent-maintenance family.**
- **AUTO-TV-DOWNLOADER-CATEGORY:**
  - **Medusa** — Python; SickBeard-lineage; manual-search-focus
  - **Sonarr** — dominant; C#; automation-first
  - **SickChill** — SickRage-fork
  - **Flexget** — rule-engine approach
- **ALTERNATIVES WORTH KNOWING:**
  - **Sonarr** — if you want dominant + automation-first + larger community
  - **SickChill** — alternative SickRage-fork
  - **Choose Medusa if:** you want Python + manual-control + SickBeard-lineage continuity.
- **PROJECT HEALTH**: active + decade-plus-lineage + codecov + wiki. Steady; niche given Sonarr dominance but stable community.

## Links

- Repo: <https://github.com/pymedusa/Medusa>
- Sonarr (alt): <https://github.com/Sonarr/Sonarr>
- SickChill (alt): <https://github.com/SickChill/SickChill>
