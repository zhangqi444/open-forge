---
name: Open DroneLog
description: "High-performance drone flight log analyzer. Docker / Tauri desktop. Rust + React + DuckDB. arpanghosh8453/open-dronelog. DJI + Litchi CSV + Airdata. 3D maps, telemetry charts, battery health, HTML reports."
---

# Open DroneLog

**High-performance application for analyzing drone flight logs.** Import DJI logs, Litchi CSV, and Airdata CSV exports; visualize flights on 3D interactive maps with replay; view telemetry charts; track battery health; generate regulatory HTML/PDF reports; and manage a local DuckDB database of your entire flight history. Available as a **Tauri desktop app** (Windows/macOS/Android) or a **Docker-deployable web app**.

Independent project — not affiliated with DJI, DJI Enterprise, Litchi, Airdata, or DroneLogbook.

Built + maintained by **Arpan Ghosh (arpanghosh8453)**.

- Upstream repo: <https://github.com/arpanghosh8453/open-dronelog>
- Website: <https://opendronelog.com>
- Web app (hosted): <https://app.opendronelog.com>
- Docker: `ghcr.io/arpanghosh8453/open-dronelog` or Codeberg mirror
- Releases (desktop app): <https://github.com/arpanghosh8453/open-dronelog/releases>
- PikaPods: [team hosting option](https://www.pikapods.com/pods?run=opendronelog)

## Architecture in one minute

- **Rust** backend + **React** frontend
- **DuckDB** in-process database (high-performance analytics on large flight datasets)
- Desktop: **Tauri v2** (wraps the web app in a native shell — Windows, macOS, Android)
- Web/Docker: serves on port **80** inside container
- Data stored in `/data/drone-logbook` volume
- **Local-first** — all data in a local DuckDB database; no cloud upload required (except optional DJI API key lookup on first import)
- Resource: **low-to-medium** — Rust + DuckDB; efficient for analytics

## Compatible install methods

| Infra           | Runtime                                         | Notes                                                                               |
| --------------- | ----------------------------------------------- | ----------------------------------------------------------------------------------- |
| **Docker**      | `ghcr.io/arpanghosh8453/open-dronelog:latest`   | **Team/shared** deployment; web UI for multiple operators                           |
| **Tauri desktop** | Download from Releases                        | **Personal** use — Windows (.exe/.msi), macOS (.dmg), Android; local DuckDB        |
| **Web app**     | <https://app.opendronelog.com>                  | Hosted; no setup; team option via PikaPods                                          |
| **PikaPods**    | Managed container hosting                       | <$2/month; team use without managing your own server                               |

## Inputs to collect

| Input                         | Example                           | Phase    | Notes                                                                                   |
| ----------------------------- | --------------------------------- | -------- | --------------------------------------------------------------------------------------- |
| Data volume path              | `drone-data:/data/drone-logbook`  | Storage  | Persistent DuckDB database + uploaded files                                             |
| Sync log folder (optional)    | `/path/to/drone/logs:/sync-logs`  | Storage  | Mount host folder → auto-import on schedule                                             |
| DJI API key (optional)        | developer.dji.com                 | Feature  | For enhanced DJI flight data parsing on first import; requires DJI developer account   |
| Profile password (optional)   | `DEFAULT_PROFILE_PASSWORD`        | Auth     | Protect the default profile on first start                                              |
| Master password (optional)    | `PROFILE_CREATION_PASS`           | Auth     | Require a password to create new profiles                                               |

## Install via Docker

```bash
docker run -d \
  --name open-dronelog \
  -p 8080:80 \
  -v drone-data:/data/drone-logbook \
  -e DATA_DIR=/data/drone-logbook \
  -e RUST_LOG=INFO \
  ghcr.io/arpanghosh8453/open-dronelog:latest
```

Visit `http://localhost:8080`.

## Install via Docker Compose

```yaml
services:
  open-dronelog:
    image: ghcr.io/arpanghosh8453/open-dronelog:latest
    container_name: open-dronelog
    ports:
      - "8080:80"
    volumes:
      - drone-data:/data/drone-logbook
      # Optional: auto-sync from host folder
      # - /path/to/drone/logs:/sync-logs:ro
    environment:
      - DATA_DIR=/data/drone-logbook
      - RUST_LOG=INFO
      - KEEP_UPLOADED_FILES=true
      # Optional:
      # - DJI_API_KEY=your_api_key_here
      # - SYNC_LOGS_PATH=/sync-logs
      # - SYNC_INTERVAL=0 0 */8 * * *      # cron: every 8 hours
      # - DEFAULT_PROFILE_PASSWORD=your_password
      # - PROFILE_CREATION_PASS=master_password
    restart: unless-stopped

volumes:
  drone-data:
```

## First boot

1. Deploy container.
2. Visit `http://localhost:8080`.
3. A default **profile** is created. Optionally add a password.
4. **Import flight logs**: drag-and-drop DJI `.txt` files, Litchi CSV, or Airdata CSV exports.
5. Explore: dashboard overview → activity heatmap → click a flight → 3D map replay → telemetry charts.
6. Check **Battery Health** for per-battery cycle counts + capacity trends.
7. Generate an **HTML Report** (Ctrl+P to print as PDF) for regulatory/compliance use.
8. Set up **auto-sync** if you mount a host folder containing logs.
9. For team use: configure **multiple profiles** (one per pilot).

## Supported log formats

| Format | Source | Notes |
|--------|--------|-------|
| DJI `.txt` | DJI GO / DJI Fly / RC-N | Native format |
| Litchi CSV | Litchi app flight logs | Automatic unit detection |
| Airdata CSV | Airdata UAV export | |
| Dronelink / DroneDeploy | Third-party apps | Supported via same parsers |
| Manual entry | No log file needed | Coordinates + metadata manually entered |
| Custom parsers | `plugins/parsers.json` | For non-standard formats |

## Telemetry charts available

Height, speed, battery level, cell voltages, attitude (pitch/roll/yaw), RC signal strength, GPS accuracy, distance-to-home, velocity, battery full capacity, battery remaining capacity. All charts have synchronized drag-to-zoom and collapsible panel controls.

## Environment variables

| Variable | Default | Description |
|----------|---------|-------------|
| `DATA_DIR` | `/data/drone-logbook` | Data directory inside container |
| `RUST_LOG` | `INFO` | Log level |
| `KEEP_UPLOADED_FILES` | `true` | Persist uploaded log files to disk |
| `DJI_API_KEY` | — | DJI developer API key for enhanced parsing |
| `SYNC_LOGS_PATH` | — | Container path to watch for auto-sync |
| `SYNC_INTERVAL` | `0 0 */8 * * *` | Cron expression for sync interval |
| `SESSION_TTL_HOURS` | `24` | Web session lifetime |
| `DEFAULT_PROFILE_PASSWORD` | — | Password for default profile on first start |
| `PROFILE_CREATION_PASS` | — | Master password required to create new profiles |

## Backup

```sh
docker compose stop open-dronelog
sudo docker volume export drone-data | gzip > opendronelog-$(date +%F).tar.gz
docker compose start open-dronelog
```

Or use the in-app **Backup & Restore** feature (Settings) to export the database.

## Upgrade

```sh
docker compose pull && docker compose up -d
```

## Gotchas

- **macOS "damaged file" error on desktop app.** This is Gatekeeper for unsigned binaries (signing costs $99/year Apple developer fee). Fix: `xattr -dr com.apple.quarantine /path/to/OpenDroneLog.app` in Terminal, or right-click → Open. Not a real corruption.
- **DJI API key is optional but improves data quality.** Some DJI flight log fields require a DJI developer API call to decode on first import. Without it, those fields show as unknown. Get a key at [developer.dji.com](https://developer.dji.com/user) — free tier sufficient.
- **Smart deduplication on import.** Duplicate files (same drone serial + battery serial + start time) are silently skipped. No need to filter before importing large folders.
- **Automatic downsampling for large datasets.** DuckDB queries over thousands of flights are fast; the app downsamples rendering for very large telemetry series automatically.
- **Profiles isolate data per pilot.** In a Docker deployment for a team, each pilot creates their own profile (optionally password-protected). Data is isolated between profiles.
- **`PROFILE_CREATION_PASS` for open team deployments.** If your Docker instance is accessible on a LAN, set a master password for profile creation so random users can't create profiles.
- **Security warning for web/Docker.** Upstream explicitly warns: the web app is designed for trusted LAN/VPN use. Don't expose it publicly without authentication.
- **FlyCard social media images.** Generate a shareable 1080×1080 image from any flight — includes stats, map, and branding. Export as PNG.
- **11 languages.** EN, DE, ES, FR, IT, JA, KO, NL, PL, PT, ZH — locale-aware number + date formatting.

## Project health

Active Rust + React development, Tauri desktop app (Windows/macOS/Android), Docker GHCR, Codeberg mirror, PikaPods, docs site. Solo-maintained by Arpan Ghosh.

## Drone-flight-log-family comparison

- **Open DroneLog** — Rust + DuckDB + React, DJI + Litchi + Airdata, Docker + desktop, battery health, HTML reports
- **Airdata UAV** — SaaS, polished, subscription; the main commercial option
- **DroneLogbook** — SaaS, regulatory compliance focus; subscription
- **DroneDeploy / Pix4D** — enterprise mapping platforms; not general log analysis

**Choose Open DroneLog if:** you want a free, self-hosted, high-performance drone flight log analyzer supporting DJI, Litchi, and Airdata formats — with 3D maps, battery health tracking, and regulatory PDF reports.

## Links

- Repo: <https://github.com/arpanghosh8453/open-dronelog>
- Website: <https://opendronelog.com>
- Releases (desktop): <https://github.com/arpanghosh8453/open-dronelog/releases>
- PikaPods: <https://www.pikapods.com/pods?run=opendronelog>
- DJI developer API: <https://developer.dji.com/user>
