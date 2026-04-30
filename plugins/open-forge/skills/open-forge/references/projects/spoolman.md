---
name: Spoolman
description: "3D-printer filament spool inventory + weight tracking. Integrates with OctoPrint/Moonraker/Klipper/Home Assistant. SQLite/PG/MySQL/Cockroach. 18-language Weblate localization. Donkie sole. Central community filament DB. Prometheus metrics."
---

# Spoolman

Spoolman is **"a database for your 3D-printer filament spools — weighs them in real-time as you print, updates via OctoPrint/Moonraker, and prints QR-code labels"** — a self-hosted web service for filament inventory. Tracks: filament types, manufacturers, individual spools, remaining weight, usage history. **Integrates** directly with OctoPrint, Moonraker (Fluidd/KlipperScreen/Mainsail), Home Assistant, OctoEverywhere — auto-updates spool weights as printing progresses. **Custom fields + QR-code labels + Prometheus metrics + 18-language i18n + REST API + WebSockets**.

Built + maintained by **Donkie** (sole). License: check LICENSE. Active; Weblate hosting; community-supported filament DB ([SpoolmanDB](https://github.com/Donkie/SpoolmanDB)).

Use cases: (a) **3D-printer-farm operator** — track 20+ spools (b) **hobbyist with multi-filament printer** — know remaining weight per spool (c) **making-business inventory** — cost per print (d) **OctoPrint + Moonraker ecosystem** — auto-update (e) **print-farm analytics** — Prometheus dashboards (f) **label-printing workflow** — QR-code on each spool (g) **Home Assistant dashboard** — filament-low alerts (h) **multi-printer fleet** — simultaneous updates.

Features (per README):

- **Filament management** (types, manufacturers, spools)
- **REST API** (`/api/v1/*`)
- **WebSocket real-time updates**
- **Central community filament DB** (SpoolmanDB)
- **Web client** (18 Weblate-translated languages)
- **Custom fields**
- **QR-code label printing**
- **SQLite / PostgreSQL / MySQL / CockroachDB**
- **Multi-printer concurrent updates**
- **Prometheus metrics** (historical)
- **Integrations**: OctoPrint, Moonraker, OctoEverywhere, Home Assistant

- Upstream repo: <https://github.com/Donkie/Spoolman>
- Wiki / Install: <https://github.com/Donkie/Spoolman/wiki>
- API docs: <https://donkie.github.io/Spoolman/>
- Community DB: <https://github.com/Donkie/SpoolmanDB>

## Architecture in one minute

- **Python FastAPI** backend + web UI
- **SQLite** default; PG/MySQL/Cockroach optional
- **Resource**: low — 100-300MB RAM
- **Port**: web UI + API + WS

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker**         | **`ghcr.io/donkie/spoolman`**                                   | **Primary**                                                                        |
| **Native Python**  | Pip install                                                                                                            | Alt                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `spoolman.example.com`                                      | URL          | TLS                                                                                    |
| DB                   | SQLite (default) or PG/MySQL/Cockroach                      | DB           | SQLite fine for hobbyist                                                                                    |
| Printer integrations | Moonraker / OctoPrint URLs                                  | Config       | Outbound from Spoolman                                                                                    |
| Label printer (opt)  | For QR-code printing                                        | Hardware     |                                                                                    |
| Admin / auth         | Built-in                                                    | Bootstrap    | Check if auth built-in; add reverse-proxy auth if not                                                                                    |

## Install via Docker

```yaml
services:
  spoolman:
    image: ghcr.io/donkie/spoolman:latest        # **pin version**
    environment:
      TZ: UTC
    volumes:
      - spoolman-data:/home/app/.local/share/spoolman        # SQLite default
    ports: ["7912:8000"]
    restart: unless-stopped

volumes:
  spoolman-data: {}
```

## First boot

1. Start → browse web UI
2. Add first vendor, filament type
3. Register first spool (scan QR or manual)
4. Configure Moonraker → Spoolman URL in printer config
5. Start first print; verify weight updates
6. Enable Prometheus scraping if desired
7. Put behind TLS reverse proxy
8. Back up DB

## Data & config layout

- `/home/app/.local/share/spoolman` — SQLite + uploads
- PG/MySQL/Cockroach (if used) — full data
- Prometheus series — retained per-TSDB config

## Backup

```sh
sudo tar czf spoolman-data-$(date +%F).tgz spoolman-data/
# if PG: pg_dump in addition
```

## Upgrade

1. Releases: <https://github.com/Donkie/Spoolman/releases>. Active.
2. Docker pull + restart
3. DB migrations auto (check release notes)

## Gotchas

- **117th HUB-OF-CREDENTIALS TIER 3 — MILD**:
  - Inventory + usage-stats + printer-integration-tokens
  - Not deeply sensitive — hobby/business inventory
  - **117th tool in hub-of-credentials family — Tier 3**
- **PRINTER-INTEGRATION-TOKEN-HOLDER**:
  - Moonraker and OctoPrint creds if Spoolman pushes (less common; usually printer → Spoolman)
  - **Recipe convention: "printer-integration-API-token-holder" callout**
- **COMMUNITY FILAMENT DB (SpoolmanDB)**:
  - Separate repo; curated contributions
  - **Recipe convention: "community-supported-data-DB-separate-repo positive-signal"**
  - **NEW positive-signal convention** (Spoolman 1st formally)
- **WEBLATE-HOSTED-TRANSLATION (18 langs)**:
  - Community-translation infrastructure (like AliasVault's Crowdin)
  - **Community-translation-infrastructure: 2 tools** (AliasVault Crowdin + Spoolman Weblate) 🎯 **2-TOOL MILESTONE**
  - **Recipe convention: "Weblate-hosted-translation positive-signal"**
  - **NEW positive-signal convention** (Spoolman 1st formally)
- **QR-CODE LABEL PRINTING**:
  - Built-in label-print workflow
  - **Recipe convention: "built-in-label-printing positive-signal"**
  - **NEW positive-signal convention** (Spoolman 1st formally)
- **PROMETHEUS-METRICS BUILT-IN**:
  - Observability primitive
  - **Recipe convention: "Prometheus-metrics-built-in positive-signal"**
  - **NEW positive-signal convention** (Spoolman 1st formally — many tools have this; formalizing)
- **MULTI-DB-BACKEND**:
  - SQLite + PG + MySQL + Cockroach
  - **Dual-database-backend-choice: 2 tools** (LubeLogger+Spoolman) 🎯 - BUT Spoolman has 4 backends = stronger
  - **Quad-database-backend-choice**: **NEW** — Spoolman 1st (rare)
  - **Recipe convention: "multi-DB-backend-choice positive-signal"**
- **REST API + OPENAPI (likely)**:
  - Documented API for custom integrations
  - **Recipe convention: "documented-REST-API positive-signal"** — standard
- **NICHE-HOBBYIST TOOL**:
  - 3D printing community; engaged; niche but passionate
  - **Recipe convention: "niche-hobbyist-community positive-signal"**
  - **NEW positive-signal convention** (Spoolman 1st formally)
- **INSTITUTIONAL-STEWARDSHIP**: Donkie sole + community filament-DB + Weblate-translators + integrations-ecosystem. **103rd tool — sole-maintainer-with-community-data-DB sub-tier** (NEW soft-tier).
- **TRANSPARENT-MAINTENANCE**: active + Wiki + API-docs + Weblate + community-DB + integrations-documented + releases. **111th tool in transparent-maintenance family.**
- **3D-PRINTING-INVENTORY-CATEGORY (niche):**
  - **Spoolman** — spool inventory + weight tracking
  - **Prusa Link / Slicer** — printer-first
  - **OctoPrint + plugins** — general 3D-printer hub
  - **Home-grown spreadsheets** (common)
- **ALTERNATIVES WORTH KNOWING:**
  - **OctoPrint + Spoolman plugin** — if you want OctoPrint-native
  - **Spreadsheet** — if you only have 1-2 printers
  - **Choose Spoolman if:** you want dedicated inventory + integrations + QR-labels + multi-printer.
- **PROJECT HEALTH**: active + sole + community-DB + Weblate + ecosystem-integrations + Prometheus-metrics. EXCELLENT for niche tool.

## Links

- Repo: <https://github.com/Donkie/Spoolman>
- Wiki: <https://github.com/Donkie/Spoolman/wiki>
- SpoolmanDB: <https://github.com/Donkie/SpoolmanDB>
- API: <https://donkie.github.io/Spoolman/>
- Weblate: <https://hosted.weblate.org/projects/spoolman/>
