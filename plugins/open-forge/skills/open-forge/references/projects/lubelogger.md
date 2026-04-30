---
name: LubeLogger
description: "Self-hosted vehicle maintenance + fuel-mileage tracker. LiteDB OR PostgreSQL. Docker + Windows executable + Helm. hargata sole; lubelogger.com website + demo; active. No spreadsheets, no shoeboxes."
---

# LubeLogger

LubeLogger is **"Fleetio / CarCloud / manual spreadsheet — but self-hosted + OSS"** — a web-based vehicle maintenance + fuel mileage tracker. Track oil changes, tire rotations, brake jobs, fuel fills, MPG trends, cost-per-mile. One place for all vehicles in the household (or small fleet).

Built + maintained by **Hargata (hargata)**. License: check LICENSE. Active; Docker + Windows-executable + Helm (via Anza-Labs) + PostgreSQL / LiteDB; lubelogger.com; demo at demo.lubelogger.com (resets every 20 min); ASP.NET-style (Bootstrap + LiteDB + Npgsql dependency).

Use cases: (a) **household-fleet maintenance tracking** — 2-4 cars (b) **small-business fleet** — contractors' vans, landscape trucks (c) **fuel-mileage trends** — MPG by-tank or by-month (d) **service-history before sale** — CarFax-alternative (e) **warranty-claim documentation** — maintenance proof (f) **cost-of-ownership tracking** (g) **preventive-maintenance reminders** (h) **collector-car maintenance log** — resale-value matters.

Features (per README + common-expectations):

- **Vehicle maintenance tracking**
- **Fuel mileage + MPG tracking**
- **Multi-vehicle support**
- **LiteDB (embedded) or PostgreSQL**
- **Docker + Windows-exe + Helm (K8s)**
- **Demo instance** with 20-min reset
- **Bootstrap** UI
- **Images + receipts upload** (expected)

- Upstream repo: <https://github.com/hargata/lubelog>
- Website: <https://lubelogger.com>
- Docs: <https://docs.lubelogger.com>
- Demo: <https://demo.lubelogger.com> (test/1234)
- Helm: <https://artifacthub.io/packages/helm/anza-labs/lubelogger>

## Architecture in one minute

- **ASP.NET Core** (C#)
- **LiteDB (embedded)** OR **PostgreSQL**
- **Bootstrap** UI
- **Resource**: low — 200-400MB RAM
- **Docker + Windows + Kubernetes**

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker**         | **Upstream image**                                              | **Primary**                                                                        |
| **Windows exe**    | Native standalone                                               | Alt for Win users                                                                                   |
| **Kubernetes**     | **Helm (anza-labs)**                                            | Cloud-native                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `vehicles.example.com`                                      | URL          | TLS                                                                                    |
| Admin creds          | First-boot                                                  | Bootstrap    | Strong                                                                                    |
| DB                   | LiteDB (default) OR PostgreSQL                              | DB           | LiteDB simpler; PG scales                                                                                    |
| Image storage        | Uploaded photos/receipts                                    | Storage      |                                                                                    |
| Users                | Family members                                              | Multi-user   |                                                                                    |

## Install via Docker

```yaml
services:
  lubelogger:
    image: hargata/lubelogger:latest        # **pin version**
    volumes:
      - lubelogger-data:/App/data
    ports: ["8080:8080"]
    restart: unless-stopped

volumes:
  lubelogger-data: {}
```

## First boot

1. Start → browse web UI
2. Create admin account
3. Add first vehicle (VIN + make/model/year)
4. Log first fuel-fill + first maintenance record
5. Set preventive-maintenance reminders
6. Put behind TLS reverse proxy
7. Back up DB (LiteDB is a single file; easy)

## Data & config layout

- `/App/data/` — LiteDB + config + images
- PostgreSQL (if configured) — data

## Backup

```sh
sudo tar czf lubelogger-$(date +%F).tgz lubelogger-data/
# If PG: pg_dump in addition
```

## Upgrade

1. Releases: <https://github.com/hargata/lubelog/releases>. Active.
2. Docker pull + restart
3. LiteDB auto-migrates; PG may need migrations

## Gotchas

- **110th HUB-OF-CREDENTIALS TIER 3 — MILD**:
  - Vehicle records + VINs + locations-inferred-from-fuel-fills + service-receipt-photos (may show odometer + name + card-digits)
  - **110th tool in hub-of-credentials family — Tier 3**
  - Not deeply sensitive vs health/finance tools
- **VIN = VEHICLE-IDENTIFIER**:
  - VIN is a public-ish identifier but combined with owner-info could enable title fraud
  - **Recipe convention: "VIN-privacy-mild-callout"** — soft
- **RECEIPT-PHOTOS MAY CONTAIN CARD-DIGITS**:
  - Gas-station receipts sometimes show last-4 of card
  - Not a breach but mildly sensitive
  - **Recipe convention: "receipt-photo-PII-spillover" callout**
  - **NEW recipe convention** (LubeLogger 1st formally; adjacent to Spliit 109 AI-receipt-scanning)
- **LITEDB = SINGLE-FILE DB**:
  - Simpler backup (one file)
  - Less concurrency than PG
  - Good for household scale (100-1000 records)
  - **Recipe convention: "LiteDB-single-file-backup-simplicity positive-signal"**
  - **NEW positive-signal convention** (LubeLogger 1st formally)
- **DUAL DB-CHOICE (LiteDB OR PG)**:
  - Fits deploy size (small → LiteDB; larger/multi-user → PG)
  - **Recipe convention: "dual-database-backend-choice positive-signal"**
  - **NEW positive-signal convention**
- **WINDOWS-EXE + DOCKER + HELM**:
  - Broad deploy options
  - **Recipe convention: "multi-deployment-form-factor positive-signal"**
  - **NEW positive-signal convention**
- **DEMO WITH 20-MIN RESET**:
  - Auto-reset demo (aligned with Baby Buddy 106 hourly-reset)
  - **Hourly-reset-demo-site**: extended — 2 tools now (Baby Buddy + LubeLogger) 🎯 **2-TOOL MILESTONE**
- **COMMUNITY HELM CHART (anza-labs)**:
  - Third-party Helm chart maintainer
  - **Recipe convention: "community-Helm-chart positive-signal"**
- **VEHICLE-TRACKER-CATEGORY (niche):**
  - **LubeLogger** — OSS; web; Docker/Win/K8s
  - **Fleetio** (commercial)
  - **CarCloud** (commercial)
  - **Garage Buddy** (commercial)
  - **Spreadsheets** (zero-cost baseline)
- **INSTITUTIONAL-STEWARDSHIP**: hargata sole + community-Helm-chart + website + demo. **96th tool — sole-maintainer-with-ecosystem-chart sub-tier** (reuses prior).
- **TRANSPARENT-MAINTENANCE**: active + website + demo + docs + multi-form-factor + screenshots. **104th tool in transparent-maintenance family.**
- **ALTERNATIVES WORTH KNOWING:**
  - **Fleetio** (commercial) — if you want hosted + enterprise-fleet
  - **Spreadsheet** — if you want zero-dependency
  - **Choose LubeLogger if:** you want self-hosted + web-UI + multi-vehicle + simple LiteDB.
- **PROJECT HEALTH**: active + sole-maintainer + multi-form-factor + demo + community-Helm. Strong for a niche tool.

## Links

- Repo: <https://github.com/hargata/lubelog>
- Website: <https://lubelogger.com>
- Docs: <https://docs.lubelogger.com>
- Helm: <https://artifacthub.io/packages/helm/anza-labs/lubelogger>
- Demo: <https://demo.lubelogger.com>
