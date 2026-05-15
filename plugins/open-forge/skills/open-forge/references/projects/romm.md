---
name: RomM
description: "Beautiful, powerful, self-hosted ROM manager and player. Organize your retro game collection (Atari → modern) with rich metadata (IGDB/Screenscraper/MobyGames), cover art, play-in-browser (EmulatorJS + RetroArch Web), EmulatorJS save states, play-time tracking. Python/FastAPI + Vue.js + MariaDB. AGPL-3.0."
---

# RomM

RomM is a slick, modern **ROM manager and browser-based player** for your retro game collection. Drop ROM files in folders, RomM scans them, pulls cover art + metadata from IGDB / ScreenScraper / MobyGames, organizes them by platform, and lets you **play them directly in your browser via EmulatorJS** with save states, playtime tracking, and an actually nice UX.

The retrogaming self-hosting space used to be "RetroPie on a Pi + ROMHut scraped cover art + nothing sharable." RomM makes it feel like a real game library product — Plex for retro games.

What you get:

- **Multi-platform support** — 100+ consoles (NES, SNES, N64, GBA, GBC, PS1, PS2, PSP, Dreamcast, Saturn, Atari, Arcade/MAME, DOS, ScummVM, ...)
- **Metadata scraping** — IGDB (primary) + ScreenScraper + MobyGames; covers, screenshots, descriptions, release dates, genres
- **Play in browser** via EmulatorJS (RetroArch cores compiled to WASM)
- **Save states** (cloud-synced across devices)
- **Playtime tracking** per ROM
- **Library stats** — most played, recently added, by platform
- **File management** — rename based on metadata, detect duplicates, regions, revisions
- **Multi-user** with per-user saves + library access
- **Mobile-friendly** UI (PWA installable)
- **API** for automations (bulk import, external players)
- **Companion apps** emerging in ecosystem

- Upstream repo: <https://github.com/rommapp/romm>
- Website: <https://romm.app>
- Docs: <https://docs.romm.app>
- Docker Hub: <https://hub.docker.com/r/rommapp/romm>
- Discord: <https://discord.gg/P5HtHnhUDH>
- Demo: link in README

## Architecture in one minute

- **Backend**: Python 3.11+, FastAPI, Uvicorn
- **Frontend**: Vue.js 3, Vite
- **DB**: MariaDB 10.6+ / MySQL 8+ (Postgres NOT supported)
- **Cache**: Redis
- **Storage**: local filesystem (mounts your ROM directory read-only by convention)
- **Metadata sources**: IGDB (API key required), ScreenScraper (account), MobyGames (optional API key)
- **EmulatorJS** embedded for browser play

## Compatible install methods

| Infra       | Runtime                                                 | Notes                                                           |
| ----------- | ------------------------------------------------------- | --------------------------------------------------------------- |
| Single VM   | **Docker Compose** (upstream-provided)                     | **The way**                                                         |
| NAS         | Synology / QNAP / Unraid Docker                                | Common — NAS is where the ROMs live                                     |
| Raspberry Pi | arm64 image                                                   | Works on Pi 4/5; metadata scraping + EmulatorJS in-browser playable          |
| Kubernetes  | Community manifests                                                | Straightforward                                                                     |

## Inputs to collect

| Input          | Example                         | Phase     | Notes                                                           |
| -------------- | ------------------------------- | --------- | --------------------------------------------------------------- |
| ROMs dir       | `/mnt/nas/roms/`                  | Storage   | Expected layout: `ROMS/<platform-slug>/<gamefile>.<ext>`            |
| Library dir    | `/library` (inside container)       | Storage   | Per upstream compose                                                    |
| Assets dir     | `/library/resources`                  | Storage   | Covers, screenshots, save states, metadata cache                                |
| DB             | MariaDB (in compose)                    | DB        | `mariadb:10.x`; external DB supported                                                |
| Redis          | in compose                                | Cache     | Small                                                                                        |
| IGDB API key   | from <https://api-docs.igdb.com/>          | Metadata  | **Required** for primary metadata                                                                                    |
| ScreenScraper  | account at screenscraper.fr                  | Metadata  | **Strongly recommended** — covers rival IGDB gaps (obscure consoles)                                                                       |
| MobyGames      | API key                                        | Metadata  | Optional; richer description data                                                                                                           |
| Domain         | `romm.example.com`                              | URL       | Reverse proxy with TLS                                                                                                                               |
| Admin user     | first-run wizard                                    | Bootstrap | Per-user library access                                                                                                                                   |

## Install via Docker Compose

```yaml
services:
  romm:
    image: rommapp/romm:4.8.1                # pin to a specific version tag
    container_name: romm
    restart: unless-stopped
    depends_on: [romm_db, romm_redis]
    ports:
      - "8080:8080"
    environment:
      DB_HOST: romm_db
      DB_PORT: 3306
      DB_NAME: romm
      DB_USER: romm
      DB_PASSWD: <strong>
      REDIS_HOST: romm_redis
      REDIS_PORT: 6379
      ROMM_BASE_PATH: /romm
      # Metadata providers — get API keys from each:
      IGDB_CLIENT_ID: <your-igdb-client-id>
      IGDB_CLIENT_SECRET: <your-igdb-client-secret>
      STEAMGRIDDB_API_KEY: <optional>
      SCREENSCRAPER_USER: <ssu>
      SCREENSCRAPER_PASSWORD: <ssp>
      MOBYGAMES_API_KEY: <optional>
      # First admin
      ROMM_AUTH_SECRET_KEY: <random-32-chars>
      DISABLE_CSRF_PROTECTION: "false"
    volumes:
      - romm-resources:/romm/resources
      - romm-redis-data:/redis-data
      - /mnt/nas/roms:/romm/library:ro     # mount read-only — RomM reorganizes via DB, not by moving files
      - romm-assets:/romm/assets           # save states, covers overrides
      - romm-config:/romm/config

  romm_db:
    image: mariadb:10.11
    container_name: romm_db
    restart: unless-stopped
    environment:
      MARIADB_ROOT_PASSWORD: <strong-root>
      MARIADB_DATABASE: romm
      MARIADB_USER: romm
      MARIADB_PASSWORD: <strong>
    volumes:
      - romm-db:/var/lib/mysql
    healthcheck:
      test: ["CMD", "healthcheck.sh", "--connect"]
      interval: 10s

  romm_redis:
    image: redis:7-alpine
    container_name: romm_redis
    restart: unless-stopped
    volumes:
      - romm-redis-data:/data

volumes:
  romm-resources:
  romm-assets:
  romm-config:
  romm-redis-data:
  romm-db:
```

Browse `http://<host>:8080` → first-run creates admin account.

## Folder layout for ROMs

Default expected layout inside the mounted library dir:

```
library/
├── roms/
│   ├── nes/
│   │   ├── Super Mario Bros.nes
│   │   └── ...
│   ├── snes/
│   │   └── ...
│   ├── psx/
│   │   ├── Final Fantasy VII (Disc 1).chd
│   │   └── ...
│   └── ...
└── bios/
    ├── psx/
    │   └── scph1001.bin
    └── ...
```

Use **platform slugs** from the RomM docs (`nes`, `snes`, `psx`, `gba`, `n64`, `md` for Mega Drive, ...). Wrong slugs = platform not detected.

## First boot

1. Register admin
2. Settings → Metadata providers → enter IGDB / ScreenScraper / MobyGames credentials
3. Settings → Scan → run initial library scan; metadata populates (takes minutes to hours depending on size)
4. Browse Library → each platform → each game → cover + metadata visible
5. Click a game → "Play in browser" → EmulatorJS loads the ROM
6. Upload BIOS files (required for PSX, Saturn, Dreamcast, ...) via UI

## BIOS requirements

Many consoles need BIOS files to emulate (PSX, Saturn, Sega CD, Neo Geo, Dreamcast, ...). RomM does **not ship BIOS** — you must obtain legally. Upload via UI (Settings → BIOS Manager) or place in `library/bios/<platform>/`.

## Data & config layout

- DB — all metadata, user accounts, library state, playtime stats
- `resources/` — scraped covers, screenshots, metadata cache
- `assets/` — user-uploaded covers (overrides), save states
- `library/` — your ROM files (read-only mount recommended)
- Redis — session cache, task queue

## Backup

```sh
# DB (CRITICAL — all metadata + user state + save states metadata)
docker exec romm_db mysqldump -uromm -p --single-transaction romm | gzip > romm-db-$(date +%F).sql.gz

# Resources + assets (covers, save states)
docker run --rm -v "$(pwd)/romm-resources:/src" -v "$(pwd):/backup" alpine \
  tar czf /backup/romm-resources-$(date +%F).tgz -C /src .
```

ROM files themselves: you already have them (the library is yours), but include in backup strategy for completeness.

## Upgrade

1. Releases: <https://github.com/rommapp/romm/releases>. Very active (1-2 releases/month).
2. **Back up DB first** — schema migrations happen most releases.
3. Docker: `docker compose pull && docker compose up -d`. Migrations run on startup.
4. Breaking changes are called out in release notes — read before upgrading across majors.

## Gotchas

- **Legal caveat**: ROMs are copyrighted for most games. Public distribution is illegal in most jurisdictions. RomM is a **manager** — legality of your library depends on whether you own the originals, have legal backups, or the title is abandonware/homebrew. Don't expose RomM publicly with copyrighted ROMs; keep it behind VPN or LAN.
- **BIOS files are similarly copyrighted** — same caveats. Do not post your BIOS to public RomM instances.
- **IGDB rate limits** — large scans of 1000+ games hit rate limits; scans pause and resume. Patience.
- **ScreenScraper is worth the registration** — covers many obscure consoles IGDB doesn't (SG-1000, PC Engine, FM Towns, etc.) + higher-quality regional covers.
- **Platform slugs matter** — wrong slug = RomM ignores the folder. Full list in docs.
- **ROMs can be reorganized** by RomM's rename feature — writes new filenames based on metadata. **Back up first** — if wrong, hard to undo. Many users keep library read-only and live with raw filenames.
- **MariaDB / MySQL required** — no SQLite, no Postgres (as of current version). Plan your DB.
- **EmulatorJS in-browser** is great for 8/16-bit systems; PSX + N64 + Dreamcast are playable but performance varies by browser/device. Not a replacement for a real RetroArch install for high-end consoles.
- **Save states** are cloud-synced across devices when using the same RomM user — cool feature.
- **Cover art overrides** — upload custom art via Assets → Manage for titles whose auto-scraped art is wrong/missing.
- **Multi-disc games** (PSX `.cue/.bin`, `.chd`) — RomM handles via M3U playlists. Follow docs for proper naming.
- **Arcade / MAME ROM sets** — MAME is version-specific; RomM doesn't validate ROM sets against a specific MAME version. Use CLRMAMEPro externally.
- **Chiptune/music ROMs** (PSF, NSF, etc.) — supported via EmulatorJS; niche but works.
- **Reverse proxy + WebSocket** — EmulatorJS streams games via WebSocket; reverse proxy must allow upgrade headers (nginx `proxy_http_version 1.1;` + upgrade/connection headers).
- **Mobile play** — PWA + touch controls; fun for 8/16-bit on phone. Bluetooth controllers work in most browsers.
- **Metadata re-match**: if a title was incorrectly matched (different game with same filename), per-ROM "Manually match" lets you fix.
- **Hash matching**: RomM computes file hashes → match against IGDB / RHDN databases — more reliable than filename guessing.
- **Young project**: RomM appeared ~2023 and took off fast. Active development; features ship fast but breaking changes happen. Pin image version.
- **AGPL-3.0** — strong copyleft; network-use counts.
- **Companion apps emerging** — mobile apps for remote library browsing, automation scripts for importing from different sources. Ecosystem growing.
- **Alternatives worth knowing:**
  - **Hyperspin / LaunchBox (commercial)** — Windows; mature; not self-hosted
  - **ES-DE / EmulationStation** — desktop frontend
  - **Batocera / RetroPie** — dedicated retro-gaming OS; stand-alone device
  - **Gamevault** — similar concept; more Steam-like commercial games focus
  - **Romulus / Romcenter** — DAT-based ROM organization tools; no play features
  - **RetroArch (standalone)** — emulator frontend; not a library manager
  - **Choose RomM if:** you want a Plex-like library with metadata + browser play + per-user save states + a modern UI.
  - **Choose Gamevault if:** you also want modern PC games (not just retro).
  - **Choose Batocera if:** you want a dedicated retro gaming appliance device.

## Links

- Repo: <https://github.com/rommapp/romm>
- Website: <https://romm.app>
- Docs: <https://docs.romm.app>
- Discord: <https://discord.gg/P5HtHnhUDH>
- Docker Hub: <https://hub.docker.com/r/rommapp/romm>
- Releases: <https://github.com/rommapp/romm/releases>
- Supported platforms list: <https://docs.romm.app/latest/Getting-Started/Supported-Platforms/>
- Folder structure: <https://docs.romm.app/latest/Getting-Started/Folder-Structure/>
- Metadata setup: <https://docs.romm.app/latest/Getting-Started/Metadata-Sources/>
- EmulatorJS: <https://emulatorjs.org>
- IGDB API: <https://api-docs.igdb.com/>
- ScreenScraper: <https://www.screenscraper.fr>
- MobyGames API: <https://www.mobygames.com/info/api>
