---
name: Immich Power Tools
description: "Unofficial Immich client. Bulk people-mgmt, merge-suggestions, missing-location fill, potential-album detection, smart search, analytics, bulk date offset. Docker. varunraj sole. Unofficial — not from Immich team."
---

# Immich Power Tools

Immich Power Tools is **"Immich is great, but some tasks are faster in a dedicated tool — here's that tool"** — an **unofficial** Immich client providing **bulk + advanced workflows** that the main Immich UI doesn't emphasize. Bulk people-editing (combine 1000 faces at once), smart search ("show me all my photos from 2024 of <person>"), missing-location filling, potential-album suggestions, date-offset fixing. Built because varunraj migrated from Google Photos and needed tools that Google Photos had but Immich lacked.

Built + maintained by **Varun Raj (varunraj)**. License: check LICENSE. Active; Docker via GHCR; Buy-Me-a-Coffee funding. Designed to run **alongside** Immich in same compose network.

Use cases: (a) **post-Google-Photos-migration** — bulk-cleanup newly-imported library (b) **people-face-merge** — Immich has similar-suggestion; this tool does it faster for thousands (c) **missing-location geotag-fill** — assets without location (d) **potential-album-discovery** — suggest albums from clustering (e) **natural-language search** — "2024 of John" (f) **bulk date offset** — fix timestamps drifted from reality (g) **library analytics** — EXIF + trends.

Features (per README):

- **Bulk people data edit**
- **People Merge Suggestion** (similarity-based, bulk)
- **Update Missing Locations**
- **Potential Albums** (suggest via clustering)
- **Analytics** (assets over time, EXIF stats)
- **Smart Search** (natural language)
- **Bulk Date Offset**

- Upstream repo: <https://github.com/immich-power-tools/immich-power-tools>
- Demo video: <https://www.loom.com/embed/13aa90d8ab2e4acab0993bdc8703a750>
- BuyMeACoffee: <https://www.buymeacoffee.com/varunraj>

## Architecture in one minute

- **Next.js** (React) app
- **Connects to Immich API** (needs API key + URL)
- **Resource**: low — 100-300MB RAM
- **Port**: 3000 (default)
- **Data storage**: minimal — just config / tokens

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker Compose** | **Alongside Immich** (shared network)                           | **Primary**                                                                        |
| **Docker standalone** | With `IMMICH_URL` + API key                                                                                          | Alt                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Immich URL           | Internal: `http://immich-server:2283`                       | Connect      |                                                                                    |
| **Immich API key**   | User-scoped API key                                         | **CRITICAL** | **Full access to Immich library**                                                                                    |
| Domain               | `photos-tools.example.com`                                  | URL          | TLS + auth (this tool wraps Immich credentials!)                                                                                    |
| Admin creds (if any) | Per-app auth                                                | Bootstrap    |                                                                                    |

## Install via Docker Compose (alongside Immich)

```yaml
services:
  # (existing Immich services)
  
  power-tools:
    container_name: immich_power_tools
    image: ghcr.io/immich-power-tools/immich-power-tools:latest        # **pin version**
    volumes:
      - immich-power-tools-data:/app/data
    ports: ["8001:3000"]
    env_file: [.env]        # IMMICH_URL, API key, etc.
    networks: [immich_default]        # same as Immich
    restart: unless-stopped

volumes:
  immich-power-tools-data: {}
```

## First boot

1. Generate Immich API key (Immich UI → Account Settings → API Keys)
2. Start Power Tools
3. Verify connection to Immich
4. Try people-merge-suggestions first (most valuable)
5. **Test on a small subset before bulk operations** — UNDO is often impossible in bulk
6. Put behind TLS reverse proxy + auth
7. Back up Immich DB before any large bulk ops

## Data & config layout

- `/app/data/` — minimal (tokens / app-state)
- ALL real data stays in Immich

## Backup

Back up Immich (primary data); Power Tools itself has minimal state.

## Upgrade

1. Releases: <https://github.com/immich-power-tools/immich-power-tools/releases>. Active.
2. Docker pull + restart
3. Immich API-version compatibility: check notes
4. **If Immich major-version changes** → may need coordinated upgrade

## Gotchas

- **114th HUB-OF-CREDENTIALS TIER 2 — IMMICH-API-KEY-HOLDER**:
  - Holds Immich API key with full library-access
  - Compromise → access to entire photo library (may contain PII, faces, locations)
  - **114th tool in hub-of-credentials family — Tier 2**
- **UNOFFICIAL TOOL RISK**:
  - Not maintained by Immich team
  - Immich API changes could break tool
  - **Recipe convention: "unofficial-companion-tool-API-drift-risk" callout**
  - **NEW recipe convention** (Immich Power Tools 1st formally)
  - **Tool-API-version-compatibility-matrix: 4 tools** (adjacent)
- **BULK-DESTRUCTIVE-OPERATIONS-DANGER**:
  - Merge-people-in-bulk, date-offset, missing-location — all modify library
  - Immich has limited undo
  - Test on small subset FIRST
  - Back up DB before bulk ops
  - **Recipe convention: "bulk-destructive-operations-danger" callout**
  - **NEW recipe convention** (Immich Power Tools 1st formally)
- **NATURAL-LANGUAGE SEARCH = LLM?**:
  - "Show me all my photos from 2024 of <person>" — may involve LLM
  - If LLM, could send data externally (check)
  - **Recipe convention: "natural-language-search-may-involve-LLM" callout**
- **FACIAL-RECOGNITION-DATA-BACKED-BY-IMMICH**:
  - Tool uses Immich's face vectors
  - Doesn't recompute — but exposes Immich's face-data via its UI
  - **Recipe convention: "facial-recognition-data-handling callout"** — privacy
- **SMART-SEARCH-RESULTS MAY EXPOSE METADATA**:
  - Results pages show thumbnails + metadata
  - Ensure auth before exposing
- **NEXT.JS SSR**:
  - Vercel-optimization leakage (see Spliit 109)
  - Self-hosted Next.js = check telemetry opts
- **ECOSYSTEM: UNOFFICIAL-IMMICH-TOOLS-FAMILY**:
  - Immich Power Tools
  - immich-frame (wall display)
  - immich-kiosk (kiosk)
  - immich-go (CLI)
  - **Recipe convention: "unofficial-ecosystem-tools-family positive-signal"** — community signal
  - **NEW positive-signal convention** (Immich Power Tools 1st formally)
- **SINGLE-USER-FOCUS**:
  - Immich is multi-user; Power Tools is often single-admin-focus
  - Permission-model may not map perfectly
  - **Recipe convention: "single-admin-companion-tool callout"** — be careful with multi-user Immich
- **BUY-ME-A-COFFEE FUNDING**:
  - Extends Ko-fi family
  - **Community-funding (BuyMeACoffee + Ko-fi + Open-Collective): varied** — micro-funding signal
  - **Recipe convention: "BuyMeACoffee-funding positive-signal"** — common
- **INSTITUTIONAL-STEWARDSHIP**: varunraj sole + BMC + active + GHCR. **100th tool 🎯 100-TOOL MILESTONE in institutional-stewardship family — "sole-maintainer-with-public-funding" sub-tier**.
  - **🎯 INSTITUTIONAL-STEWARDSHIP: 100 TOOLS MILESTONE AT IMMICH POWER TOOLS**
- **TRANSPARENT-MAINTENANCE**: active + GHCR + demo-video + funding + compose-example + docs. **108th tool in transparent-maintenance family.**
- **COMPANION-TOOL-CATEGORY (niche):**
  - **Immich Power Tools** — bulk + smart-search
  - **immich-frame** — display-kiosk
  - **immich-kiosk** — kiosk wall
  - **immich-go** — CLI uploader
  - Target primary-tool: **Immich** (major OSS photos)
- **ALTERNATIVES:**
  - **Immich native UI** — if core workflows are enough
  - **Lychee / PhotoPrism** — alternative photo-managers (different scope)
  - **Choose Immich Power Tools if:** you're deep into Immich and need bulk-ops.
- **PROJECT HEALTH**: active + companion-to-major-OSS + sole + BMC-funded. Good. Watch for Immich major-version breakage.

## Links

- Repo: <https://github.com/immich-power-tools/immich-power-tools>
- Immich: <https://github.com/immich-app/immich>
- Demo video: <https://www.loom.com/embed/13aa90d8ab2e4acab0993bdc8703a750>
