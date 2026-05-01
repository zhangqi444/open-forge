---
name: Retrom
description: "Centralized game library/collection management service with focus on emulation. Host games on one device; clients connect from anywhere. JMBeresford. Discord. Wiki quick-start. Client releases on GitHub."
---

# Retrom

Retrom is **"Plex for ROMs / emulator games — centralized library + clients on any device"** — host your game collection (emulation-focused) on a single device, then connect clients from any number of other devices to **install/download/play** those games remotely. Centralized config + metadata; distributed play.

Built + maintained by **JMBeresford**. Discord community. Active wiki + quick-start guide. Pre-built client releases on GitHub.

Use cases: (a) **central ROM-library hosted once, played anywhere** (b) **retro-emulation library** for household (c) **family game collection with metadata** (d) **client-server game-library vs per-device duplicate libraries** (e) **cross-device save + metadata sync** (f) **emulator-first game-management** (g) **LibreELEC/Kodi-style game-library UX** (h) **self-hosted Steam-like library for ROMs**.

Features (per README):

- **Centralized library**
- **Configure once, play anywhere**
- **Emulation-focus**
- **Client apps** (download from releases)
- **Quick-start wiki**

- Upstream repo: <https://github.com/JMBeresford/retrom>
- Wiki: <https://github.com/JMBeresford/retrom/wiki>
- Quick-start: <https://github.com/JMBeresford/retrom/wiki/Quick-Start>
- Client downloads: <https://github.com/JMBeresford/retrom/releases/latest>

## Architecture in one minute

- **Server** (likely Rust or Go)
- **Client apps** for desktop/mobile
- Database for metadata
- Storage for ROM files
- **Resource**: moderate — ROM storage can be huge

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker**         | Server                                                                                                                 | **Primary**                                                                                   |
| **Client apps**    | Per-device                                                                                                             | From releases                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | LAN usually                                                 | URL          |                                                                                    |
| ROM storage path     | `/games`                                                    | Storage      | **Can be huge**                                                                                    |
| Admin creds          | Bootstrap                                                   | Bootstrap    |                                                                                    |
| Emulator configs     | Per-platform                                                | Config       | Per-client                                                                                    |

## Install via Docker

See <https://github.com/JMBeresford/retrom/wiki/Quick-Start> for current command. Typical pattern:
```yaml
services:
  retrom:
    image: jmberesford/retrom:latest        # **pin**
    volumes:
      - ./retrom-config:/config
      - /games:/games:ro        # **RO mount — ROMs can be read-only**
    ports: ["5100:5100"]
    restart: unless-stopped
```

Install clients on each device from the releases page.

## First boot

1. Start server
2. Create admin
3. Point at ROM library
4. Let metadata-scan run (queries IGDB/etc.)
5. Install client on a device; connect
6. Test play-via-emulator flow
7. Back up config + metadata DB

## Data & config layout

- `/config/` — DB + configs
- `/games/` — ROM files (separate; often huge)

## Backup

```sh
sudo tar czf retrom-$(date +%F).tgz retrom-config/
# ROM files separately (huge, often already-backed-up elsewhere)
```

## Upgrade

1. Releases: <https://github.com/JMBeresford/retrom/releases>
2. Server + matching client version
3. Docker pull + restart

## Gotchas

- **168th HUB-OF-CREDENTIALS Tier 3 — GAME-LIBRARY-METADATA**:
  - Holds: library metadata, user accounts, save-game data (if synced)
  - ROM files separately (bigger sensitivity-vector: copyright)
  - **168th tool in hub-of-credentials family — Tier 3**
- **ROM-COPYRIGHT-LEGAL-EXPOSURE**:
  - ROM distribution (especially of non-freeware games) is copyright-infringing in most jurisdictions
  - Personal-backups legal in some countries, not others
  - **Recipe convention: "ROM-distribution-copyright-legal-exposure callout"**
  - **NEW recipe convention** (Retrom 1st formally; HIGH-severity similar to torrent-streaming)
- **CLIENT-VERSION-COMPAT**:
  - Server + client version-lockstep
  - **Recipe convention: "server-client-version-lockstep-discipline callout"**
  - **NEW recipe convention** (Retrom 1st formally)
- **EMULATOR-PER-DEVICE-CONFIG**:
  - Emulator binaries + core configs per-client
  - Non-trivial UX complexity
  - **Recipe convention: "per-client-emulator-config-discipline neutral-signal"**
  - **NEW neutral-signal convention** (Retrom 1st formally)
- **CLIENT-SERVER-ARCHITECTURE**:
  - Distinct from Fladder (single client)
  - **Client-server-architecture: 1 tool** 🎯 **NEW FAMILY** (Retrom — client-and-server both distributed)
- **ROM-RO-MOUNT**:
  - ROM files should be read-only mount
  - **Read-only-library-mount-discipline: 3 tools** 🎯 **3-TOOL MILESTONE** (+Retrom)
- **METADATA-SCRAPER-RATE-LIMITS**:
  - IGDB/similar rate limits
  - **Recipe convention: "metadata-scraper-rate-limit-discipline callout"**
  - **NEW recipe convention** (Retrom 1st formally)
- **INSTITUTIONAL-STEWARDSHIP**: JMBeresford + Discord + wiki + quick-start + client releases + active. **154th tool — sole-dev-client-server-architecture sub-tier** (NEW-soft).
- **TRANSPARENT-MAINTENANCE**: active + wiki + quick-start + releases + client-releases. **160th tool in transparent-maintenance family** 🎯 **160-TOOL TRANSPARENT-MAINTENANCE MILESTONE at Retrom**.
- **ROM-LIBRARY-CATEGORY:**
  - **Retrom** — client-server; emulation-focused
  - **RomM** — web-first OSS ROM library
  - **EmulationStation** — frontend; not server
  - **RetroArch** — multi-emu frontend; not a library-manager
  - **Lutris** — Linux game-launcher
- **ALTERNATIVES WORTH KNOWING:**
  - **RomM** — if you want web-first
  - **EmulationStation** — if you want per-device frontend only
  - **Choose Retrom if:** you want central-server + connected clients + emulation-first.
- **PROJECT HEALTH**: active + Discord + wiki + client releases. Strong for sole-dev + client-server.

## Links

- Repo: <https://github.com/JMBeresford/retrom>
- Wiki: <https://github.com/JMBeresford/retrom/wiki>
- RomM (alt): <https://github.com/rommapp/romm>
