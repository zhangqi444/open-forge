---
name: Reiverr
description: "Single UI for TMDB + streaming-content sources + Sonarr/Radarr — Overseerr alternative. SvelteKit + plugin API (Jellyfin + Torrent-Stream). 2.0 rewrite TV-focused; 1.0 branch stable for web. aleksilassila. Discord. ⚠️ 2.0 early-stage."
---

# Reiverr

Reiverr is **"Overseerr + Jellyseerr — but with built-in playback + a plugin API for multiple sources — and designed for TVs"** — a single UI combining TMDB discovery + playback from Jellyfin + (optional) torrent-streaming via Jackett. Connects to Radarr/Sonarr for request-to-download flow.

## ⚠️ VERSION NOTE

Per README: **"This is the page for Reiverr 2.0, which is a rewrite of the project with TVs in mind. It still lacks many features of the previous version."** The README directs web-only users to Reiverr 1.0 branch which is more stable. This is **honest-rewrite-in-progress** (distinct from Jellystat's paused-rewrite — here the rewrite IS active development).

**Honest-maintainer-declaration: 5 tools** 🎯 **5-TOOL MILESTONE**:
- Scriberr honest-life-pause (109)
- Astuto honest-discontinuation (113)
- Jellystat honest-rewrite-pause (114)
- Stump honest-WIP-pre-1.0 (115)
- **Reiverr honest-active-rewrite-lacks-1.0-features (116 — 5th flavor)**

Built + maintained by **Aleksi Lassila (aleksilassila)**. Active Discord; GHCR images; 1.0 branch preserved.

Use cases: (a) **TV-first media-browser** — big-screen UI (b) **Overseerr + playback** — single UI end-to-end (c) **Jellyfin companion** (d) **TMDB-discovery without Jellyfin** (e) **torrent-stream + Jackett** setup (f) **family-media-living-room UI** (g) **Samsung/LG TV browser** (h) **10-foot-experience apps replacement**.

Features (per README):

- **TMDB discovery** — trending + recommendations + details
- **Playback plugin API** — Jellyfin plugin + Torrent-Stream plugin
- **Sonarr/Radarr integration**
- **TV-first design** (2.0)
- **SvelteKit** likely

- Upstream repo: <https://github.com/aleksilassila/reiverr>
- 1.0 branch: <https://github.com/aleksilassila/reiverr/tree/reiverr-1.0>
- Taskboard: <https://github.com/users/aleksilassila/projects/5>

## Architecture in one minute

- **SvelteKit** likely (Node.js runtime)
- **Config file** driven
- **Plugin architecture** for content-sources
- **Resource**: low — 200-400MB
- **Port**: web UI

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker**         | **`ghcr.io/aleksilassila/reiverr`**                             | **Primary**                                                                        |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `reiverr.example.com`                                       | URL          | TLS                                                                                    |
| TMDB API key         | Required                                                    | Required     |                                                                                    |
| Sonarr URL + API key | If using                                                    | Optional     | Admin scope                                                                                    |
| Radarr URL + API key | If using                                                    | Optional     | Admin scope                                                                                    |
| Jellyfin URL + key   | If playback                                                 | Optional     |                                                                                    |
| Jackett (opt)        | For torrent-streams                                         | Optional     |                                                                                    |

## Install via Docker

```yaml
services:
  reiverr:
    image: ghcr.io/aleksilassila/reiverr:latest        # **pin: 2.0 is early; consider 1.0**
    ports: ["9494:9494"]
    volumes:
      - ./reiverr-config:/config
    restart: unless-stopped

  # 1.0 alternative (more stable; web-only)
  # reiverr-1x:
  #   image: ghcr.io/aleksilassila/reiverr:1.9.1        # example 1.0 tag
```

## First boot

1. Start; browse
2. Config wizard — TMDB, Jellyfin, Sonarr/Radarr
3. Add users
4. Test playback on TV / browser
5. **For production stability, consider 1.0 branch**
6. Put behind TLS

## Data & config layout

- `/config/` — JSON config + users

## Backup

```sh
sudo tar czf reiverr-config-$(date +%F).tgz reiverr-config/
# contains TMDB + Jellyfin + Sonarr/Radarr API keys
```

## Upgrade

1. Releases: <https://github.com/aleksilassila/reiverr/releases>. 2.0 active-early.
2. Breaking changes likely during 2.0 stabilization
3. 1.0 branch maintained separately

## Gotchas

- **133rd HUB-OF-CREDENTIALS TIER 2 — MEDIA-STACK-CREDENTIAL-UI**:
  - Holds TMDB + Jellyfin + Sonarr + Radarr + Jackett API keys
  - Not destructive (Cleanuparr 115 was) — more consumption
  - **133rd tool in hub-of-credentials family — Tier 2**
- **2.0 IS ACTIVE-REWRITE, 1.0 STILL MAINTAINED**:
  - **NEW institutional-stewardship sub-tier: "dual-branch-during-rewrite"** (1st — Reiverr)
  - Honest + supportive
  - **Recipe convention: "dual-branch-stability-handoff positive-signal"**
  - **NEW positive-signal convention** (Reiverr 1st formally)
- **5TH FLAVOR OF HONEST-DECLARATION**:
  - Reiverr 2.0: **active-rewrite-in-progress (lacks 1.0 features, stable 1.0 preserved)**
  - Distinct from Jellystat (114) which is paused entirely during rewrite
  - Distinct from Stump (115) which is pre-1.0 WIP from the start
  - **Honest-maintainer-declaration taxonomy now 5-dimensional**
- **PLUGIN-API FOR CONTENT-SOURCES**:
  - User-installable plugins for playback sources
  - **Recipe convention: "plugin-API-supply-chain-risk callout"** — reinforces Wireflow + prior
  - **Plugin-API-architecture: 2 tools** 🎯 **2-TOOL MILESTONE** (Wireflow + Reiverr 2.0)
- **TV-FIRST-DESIGN**:
  - 10-foot UI; remote-friendly
  - Novel positioning
  - **Recipe convention: "TV-first-10-foot-UI positive-signal"**
  - **NEW positive-signal convention** (Reiverr 1st formally)
- **TORRENT-STREAM-PLUGIN**:
  - Streams torrents directly (Jackett-based)
  - Legal complexity depending on jurisdiction/content
  - **Recipe convention: "torrent-streaming-legal-exposure callout"**
  - **NEW recipe convention** (Reiverr 1st formally)
- **OVERSEERR-ALTERNATIVE-CATEGORY**:
  - **Overseerr/Jellyseerr-alternative: 1 tool** (Reiverr) 🎯 **NEW MILESTONE**
- **PUBLIC TASKBOARD**:
  - <https://github.com/users/aleksilassila/projects/5>
  - Roadmap visible
  - **Recipe convention: "public-taskboard-roadmap positive-signal"**
  - **NEW positive-signal convention** (Reiverr 1st formally)
- **INSTITUTIONAL-STEWARDSHIP**: aleksilassila sole + Discord + GHCR + Taskboard + 1.0-preserved. **119th tool — sole-maintainer-with-dual-branch sub-tier** (NEW soft-tier).
- **TRANSPARENT-MAINTENANCE**: active-2.0 + maintained-1.0 + Discord + Taskboard + badges. **125th tool in transparent-maintenance family.**
- **MEDIA-REQUEST/BROWSER-CATEGORY:**
  - **Reiverr** — TV-first; playback + TMDB + plugin
  - **Overseerr** — request-only; mature
  - **Jellyseerr** — Jellyfin-fork of Overseerr
  - **Ombi** — request-only; mature
- **ALTERNATIVES WORTH KNOWING:**
  - **Overseerr** — if you want request-only + mature
  - **Jellyseerr** — if Jellyfin
  - **Choose Reiverr if:** you want TV-first + built-in playback + willing to tolerate 2.0 rough edges.
- **PROJECT HEALTH**: active + Discord + GHCR + dual-branch-maintained. Strong despite early-2.0.

## Links

- Repo: <https://github.com/aleksilassila/reiverr>
- 1.0 branch: <https://github.com/aleksilassila/reiverr/tree/reiverr-1.0>
- Overseerr (alt): <https://github.com/sct/overseerr>
- Jellyseerr (alt): <https://github.com/Fallenbagel/jellyseerr>
