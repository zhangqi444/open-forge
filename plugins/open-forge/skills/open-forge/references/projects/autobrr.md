---
name: autobrr
description: "Modern download automation for torrents + Usenet. IRC-announce + RSS-announce filter routing to download clients. Go + React. Distroless images. GPL. autobrr org; Swizzin/Saltbox/QuickBox install; Discord. Active."
---

# autobrr

autobrr is **"trackarr / autodl-irssi / flexget — but modern + Go + unified"** — a download-automation tool for torrents + Usenet. Listens to **tracker IRC-announce channels** + RSS feeds + scans for matches against user-defined filters, then passes to configured download clients (qBittorrent/Transmission/Deluge/rTorrent/Sonarr/Radarr/Lidarr/Whisparr/Readarr + Usenet). Draws from torrent-tracker-ecosystem heritage (autodl-irssi) but modernized with Go + React UI. **Distroless** Docker images (minimal attack surface).

Built + maintained by **autobrr org** + community. License: check LICENSE (GPL likely). Active; multi-platform installs (Swizzin / Saltbox / QuickBox / Docker / bare Linux / macOS / Windows); Discord; extensive docs at autobrr.com.

Use cases: (a) **private-tracker-ratio enforcement** — grab releases immediately on announce (b) **Sonarr/Radarr grabber** — autobrr announces to arr-stack (c) **quality-filter pipeline** — regex/advanced filters route to right client (d) **Usenet + torrent unified** — one tool for both (e) **IRC-announce latency advantage** — announce-channel races ahead of tracker RSS (f) **seedbox orchestration** — Swizzin/Saltbox/QuickBox ecosystems (g) **cross-tracker deduplication** — avoid grabbing same release from multiple trackers (h) **size + group + codec filters** — only keep matching releases.

Features (per README + docs):

- **IRC-announce monitoring** (dozens of trackers supported)
- **RSS feed support**
- **Multiple download clients**: qBittorrent, Transmission, Deluge, rTorrent, Sonarr, Radarr, Lidarr, Readarr, Whisparr, SABnzbd, NZBGet
- **Complex filters** — regex, size, group, codec, resolution
- **Distroless Docker images** — minimal-attack-surface
- **React UI**
- **Swizzin / Saltbox / QuickBox** ecosystem integration
- **Windows / macOS / Linux / Docker** install

- Upstream repo: <https://github.com/autobrr/autobrr>
- Docs: <https://autobrr.com>
- Discord: community link per docs

## Architecture in one minute

- **Go** backend
- **React** frontend
- **SQLite / PostgreSQL** DB
- **Resource**: low — 50-200MB RAM
- **Connects to torrent clients + arr-stack + IRC networks + RSS**
- **Port 7474** default

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker Compose** | **Upstream + distroless variants**                              | **Primary**                                                                        |
| **Swizzin / Saltbox / QuickBox** | **First-class ecosystem support**                      | Seedbox ecosystems                                                                                   |
| **Windows / macOS / Linux bare** | Binary                                                                            | Alt                                                                                   |
| **Shared seedbox** | Via provider-supported process                                                                                                             |                                                                                    |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `autobrr.example.com`                                       | URL          | TLS                                                                                    |
| Admin creds          | First-boot                                                  | Bootstrap    | Strong                                                                                    |
| **Tracker IRC nicks + passkeys** | Per-tracker (HIGHLY SENSITIVE)                              | **CRITICAL** | **Passkeys = account-equivalent**                                                                                    |
| Download client creds | qBT / Transmission API                                                                                  | Integration  |                                                                                    |
| Arr-stack API keys   | Sonarr/Radarr/etc.                                          | Integration  |                                                                                    |
| Filter rules         | Per-indexer                                                                                                             | Config       |                                                                                                                                            |
| Indexer definitions  | YAML / built-in                                                                                                            | Config       |                                                                                                                                            |

## Install via Docker

```yaml
services:
  autobrr:
    image: ghcr.io/autobrr/autobrr:latest        # **pin version**
    # Or distroless variant:
    # image: ghcr.io/autobrr/autobrr-distroless:latest
    volumes:
      - autobrr-config:/config
    ports: ["7474:7474"]
    user: 1000:1000
    restart: unless-stopped

volumes:
  autobrr-config: {}
```

## First boot

1. Start container → browse `:7474`
2. Create admin account
3. Add first tracker (IRC channel + credentials)
4. Define filters (size, quality, group, etc.)
5. Connect download clients
6. Enable action → verify first-grab
7. Put behind TLS reverse proxy + auth

## Data & config layout

- `/config/` — SQLite DB + logs + filter state

## Backup

```sh
sudo tar czf autobrr-$(date +%F).tgz autobrr-config/
```

## Upgrade

1. Releases: <https://github.com/autobrr/autobrr/releases>. Active.
2. Docker pull + restart
3. **Distroless images** = smaller + less-attack-surface; consider for production
4. Filter schema may evolve; back up before major versions

## Gotchas

- **PRIVATE-TRACKER PASSKEYS = CROWN-JEWEL**:
  - Each tracker's passkey = credential-equivalent to YOUR TRACKER ACCOUNT
  - Leaked passkey → account stolen (ratio + upload credits gone) → often permanent-ban + hard-to-get-back
  - autobrr stores passkeys for EVERY tracker you configured
  - **91st tool in hub-of-credentials family — Tier 1 CROWN-JEWEL** — sub-category for tracker-passkeys
  - **NEW CROWN-JEWEL Tier 1 sub-category: "private-tracker-credential-aggregator"** — 1st tool named (autobrr)
  - **CROWN-JEWEL Tier 1: 24 tools; 21 sub-categories**
- **IRC NETWORK CREDS**:
  - IRC nickserv password per tracker's network
  - Multi-tracker user = multiple IRC networks
  - Each has separate credential
- **LEGAL/TOS RISK (same as Flood 106)**:
  - Torrenting copyrighted content = potential infringement
  - Private trackers distribute copyrighted material
  - **Copyright-content-hosting-risk META-FAMILY extended**: now 6 tools (+autobrr)
  - **META-FAMILY: 6 tools** — solidifying
- **DOWNLOAD-CLIENT API CREDS**:
  - autobrr has ADMIN access to qBT/Transmission/etc.
  - Compromise = attacker controls torrent clients
- **ARR-STACK API KEYS**:
  - Sonarr/Radarr/Lidarr API keys
  - Compromise = attacker can add/remove media requests, see library
- **FILTER-CORRECTNESS = SLA**:
  - Wrong filter → wrong grabs → wasted upload credits on private trackers → ratio damage → ban
  - Test filters carefully; dry-run mode
  - **Recipe convention: "filter-logic-test-dry-run-mode" callout** positive-signal
  - **NEW recipe convention**
- **IRC-ANNOUNCE LATENCY ADVANTAGE**:
  - IRC-announce beats tracker-RSS by seconds-to-minutes
  - Competitive for private-tracker "freeleech" races
  - **Recipe convention: "IRC-announce-latency-advantage" positive-signal**
  - **NEW positive-signal convention**
- **DISTROLESS IMAGES = MINIMAL ATTACK SURFACE**:
  - No shell, no package-manager, minimal base OS
  - Smaller attack-surface if container compromised
  - **Recipe convention: "distroless-Docker-images positive-signal"**
  - **NEW positive-signal convention** (autobrr 1st formally)
- **SEEDBOX-ECOSYSTEM INTEGRATION**:
  - Swizzin / Saltbox / QuickBox are mature seedbox-provisioning systems
  - First-class support = ecosystem-fit
  - **Recipe convention: "seedbox-ecosystem-first-class-support" positive-signal**
  - **NEW positive-signal convention** (autobrr 1st named)
- **PRIVATE-TRACKER-CREDENTIAL-AGGREGATOR THREAT MODEL**:
  - Targeted by attackers (fake-autobrr malicious updates, tracker-account-steal campaigns)
  - **Mitigation**: only install from upstream; verify signatures; distroless image
  - **Recipe convention: "supply-chain-defense for credential-aggregators" callout**
  - **NEW recipe convention**
- **USENET NZB KEYS**:
  - Usenet provider API-keys also stored
  - Similar sensitivity to tracker passkeys
- **MULTI-CLIENT SUPPORT = BROAD COMPATIBILITY**:
  - qBT + Transmission + Deluge + rTorrent + all-arrs + NZB clients
  - **Multi-client-integration-tests** applies? (unclear; research Flood 106 precedent)
- **INSTITUTIONAL-STEWARDSHIP**: autobrr org + community + Discord + multi-OS-support. **77th tool — org-with-ecosystem-integration sub-tier.**
- **TRANSPARENT-MAINTENANCE**: active + releases + CI + multi-platform + Discord + autobrr.com-docs + distroless-variants + seedbox-ecosystem. **85th tool in transparent-maintenance family** 🎯 **85-TOOL MILESTONE.**
- **ARR-STACK-ECOSYSTEM (category):**
  - **autobrr** — IRC-announce-to-client; automation
  - **Sonarr** — TV
  - **Radarr** — Movies
  - **Lidarr** — Music
  - **Readarr** — Books
  - **Whisparr** — Adult
  - **Prowlarr** — indexer-aggregator
  - **Jackett** — older indexer-proxy
  - **Overseerr / Jellyseerr** — request systems
- **ALTERNATIVES WORTH KNOWING:**
  - **autodl-irssi** — legacy Perl (autobrr's predecessor)
  - **flexget** — Python; broader scope
  - **Prowlarr** — indexer-aggregator; different layer
  - **Choose autobrr if:** you want modern Go + React UI + IRC-announce + distroless.
- **PROJECT HEALTH**: active + Go + distroless + seedbox-ecosystem + Discord + multi-platform. EXCELLENT.

## Links

- Repo: <https://github.com/autobrr/autobrr>
- Docs: <https://autobrr.com>
- Swizzin: <https://swizzin.ltd>
- Saltbox: <https://saltbox.dev>
- QuickBox: <https://quickbox.io>
- Flood (batch 106): <https://github.com/jesec/flood>
- autodl-irssi (predecessor): <https://github.com/autodl-community/autodl-irssi>
