---
name: Tunarr
description: "Create live TV channels from Plex/Jellyfin/Emby/local media. Spoofed HDHomeRun tuner. M3U output. chrisbenincasa sole. Zlib license. Discord community."
---

# Tunarr

Tunarr is **"PseudoTV / dizqueTV — but modern and maintained"** — build **custom live TV channels** from your existing media libraries (Plex, Jellyfin, Emby, local files). Emulates an **HDHomeRun tuner** so Plex/Jellyfin/Emby see it as a broadcast-TV source; or consume via **M3U** in any IPTV player (Tivimate, UHF). Schedule programs into time-slots; add filler (commercials, music videos, prerolls); drag-and-drop lineup editor.

Built + maintained by **Chris Benincasa (chrisbenincasa)**. License: **Zlib** (uncommon; permissive). Active; Discord; Docker Hub + GitHub Releases.

Use cases: (a) **"always-on TV channel" for kids** — kid-show binge-randomizer (b) **nostalgia-channel** — sitcom-rerun all-day-loop (c) **themed weekend channel** — horror Saturday (d) **music-video-channel** (e) **integrate with Plex-DVR** — record the channel you built (f) **IPTV-on-Apple-TV** — via M3U (g) **family-TV-share** — broadcast-like experience (h) **cord-cutter-ambience** — channel-flipping experience.

Features (per README):

- **Media sources**: Plex + Jellyfin + Emby + local files
- **Channel management**: drag-drop lineup editor
- **Filler content** (commercials/music/prerolls/branding)
- **Per-channel logos** + config backups
- **Scheduling**: time-slot + random-slot
- **Web-based TV guide**
- **Spoofed HDHomeRun tuner** (Plex/Jellyfin/Emby)
- **M3U** for IPTV apps

- Upstream repo: <https://github.com/chrisbenincasa/tunarr>
- Discord: <https://discord.gg/7tUjBbDxag>
- Docker Hub: <https://hub.docker.com/r/chrisbenincasa/tunarr>

## Architecture in one minute

- **Node.js** (likely) or TS
- **SQLite or PostgreSQL** for channel/schedule state
- **Transcoding** via ffmpeg
- **Resource**: moderate — scales with active channels
- **Ports**: HTTP UI + HDHR emulation port

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker**         | **`chrisbenincasa/tunarr`**                                     | **Primary**                                                                        |
| **Native**         | Node                                                                                                                   | Alt                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `tv.example.com`                                            | URL          | TLS                                                                                    |
| **Plex/Jellyfin/Emby token** | API token for each source                           | **CRITICAL** | **Read-access to their libraries**                                                                                    |
| Local media path     | Read-mount                                                   | Storage      | Read-only preferred                                                                                    |
| DB                   | SQLite / PG                                                 | DB           |                                                                                    |
| Network (HDHR)       | Broadcast-discovery                                         | Network      |                                                                                    |

## Install via Docker

```yaml
services:
  tunarr:
    image: chrisbenincasa/tunarr:latest        # **pin version**
    volumes:
      - tunarr-config:/config
      - /media:/media:ro
    ports:
      - "8000:8000"        # UI
      - "5004:5004"        # HDHR
    restart: unless-stopped

volumes:
  tunarr-config: {}
```

## First boot

1. Start → browse web UI
2. Add first media source (Plex + token, Jellyfin + API key, or local path)
3. Create first channel
4. Add programs (drag from library)
5. Add filler content
6. Set schedule
7. In Plex/Jellyfin/Emby: add HDHomeRun tuner pointing at Tunarr
8. OR grab M3U URL for Tivimate/UHF
9. Back up `/config` (holds channel setup + tokens)
10. Put behind TLS + auth

## Data & config layout

- `/config` — channel + schedule state + source-tokens

## Backup

```sh
sudo tar czf tunarr-config-$(date +%F).tgz tunarr-config/
```

## Upgrade

1. Releases: <https://github.com/chrisbenincasa/tunarr/releases>. Active.
2. Docker pull + restart
3. Automatic config backups per README ("automatic configuration backups")
4. **Recipe convention: "automatic-config-backups positive-signal"**
5. **NEW positive-signal convention** (Tunarr 1st formally)

## Gotchas

- **125th HUB-OF-CREDENTIALS TIER 2 — MEDIA-SOURCE-TOKEN-HOLDER**:
  - Holds Plex/Jellyfin/Emby API tokens (full library read)
  - **125th tool in hub-of-credentials family — Tier 2**
- **MEDIA-COPYRIGHT-PASS-THROUGH**:
  - If your source is licensed, pass-through may violate license terms
  - Personal use only
  - **Recipe convention: "media-copyright-pass-through-personal-use" callout** — universal for media tools
- **HDHOMERUN SPOOFING**:
  - Tunarr pretends to be an HDHR device
  - Network-discovery happens via broadcast
  - **Recipe convention: "network-device-emulation-discoverability callout"** — legal-gray
  - **NEW recipe convention** (Tunarr 1st formally)
- **M3U PLAYLIST EXPOSURE**:
  - If M3U URL leaks, anyone can consume your channels
  - **Recipe convention: "M3U-playlist-URL-auth-required" callout**
  - **NEW recipe convention** (Tunarr 1st formally)
- **PSEUDOTV / DIZQUETV LINEAGE**:
  - Tunarr = modern heir; community continuity
  - **Recipe convention: "spiritual-successor-to-abandoned-OSS positive-signal"** — reinforces (extends Astuto 113 fork-pattern)
  - **NEW positive-signal convention** (Tunarr 1st formally)
- **ZLIB LICENSE (uncommon)**:
  - Very permissive; simpler than MIT
  - **Recipe convention: "zlib-license-uncommon-permissive neutral-signal"**
  - **NEW neutral-signal convention** (Tunarr 1st formally; rare)
- **AUTOMATIC CONFIG BACKUPS**:
  - Built-in config history
  - **Recipe convention: "automatic-config-backups positive-signal"**
- **DRAG-DROP LINEUP EDITOR**:
  - Visual-workflow
  - **Recipe convention: "visual-drag-drop-editor positive-signal"** — reinforces Laudspeaker (110)
- **FFMPEG DEPENDENCY**:
  - Transcoding heavy; CPU spike during playback
  - **Recipe convention: "ffmpeg-transcoding-CPU-intensive" callout**
  - **NEW recipe convention** (Tunarr 1st formally)
- **INSTITUTIONAL-STEWARDSHIP**: chrisbenincasa sole + Discord + Docker Hub + GitHub-Releases + zlib + spiritual-continuity. **111th tool — sole-maintainer-with-community-continuity sub-tier** (soft-new).
- **TRANSPARENT-MAINTENANCE**: active + Discord + Docker + releases + community. **118th tool in transparent-maintenance family.**
- **LIVE-TV-CHANNEL-BUILDER-CATEGORY (niche):**
  - **Tunarr** — modern; Plex/Jellyfin/Emby
  - **dizqueTV** — predecessor; aging
  - **PseudoTV** — predecessor
  - **ErsatzTV** — similar; C#; active
  - **No mainstream alternative** — niche
- **ALTERNATIVES WORTH KNOWING:**
  - **ErsatzTV** — if you want C#/.NET
  - **Choose Tunarr if:** you want active + Node-based + Plex/Jellyfin/Emby triple-support.
- **PROJECT HEALTH**: active + Discord + Docker + community. Strong for a niche.

## Links

- Repo: <https://github.com/chrisbenincasa/tunarr>
- ErsatzTV (alt): <https://github.com/jasongdove/ErsatzTV>
- Discord: <https://discord.gg/7tUjBbDxag>
