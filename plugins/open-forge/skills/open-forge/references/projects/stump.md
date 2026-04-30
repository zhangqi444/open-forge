---
name: Stump
description: "Rust-based comics/manga/digital-book server with OPDS support. Axum + SeaORM + React. 🚧 WIP — active development; not yet feature-complete. MIT. aaronleopold/stumpapp. Discord. Awesome-Self-Hosted listed."
---

# Stump

Stump is **"Komga + Kavita — but Rust-native + OPDS-focused"** — a free and open source **comics, manga, and digital book server** with **OPDS** support. Built in Rust (Axum + SeaORM) + React frontend. Organizes collections, serves to OPDS clients (eReaders, comics apps), web UI.

## 🚧 WIP DISCLAIMER

Per README: **"Stump is under active development and is an ongoing WIP. Anyone is welcome to try it out, but DO NOT expect a fully featured or bug-free experience."**

This is **honest-WIP-disclaimer** (distinct from paused/discontinued variants). Actively developed, just not yet production-feature-complete. 

**Honest-maintainer-declaration: 4 tools** 🎯 **4-TOOL MILESTONE** — 4 distinct flavors now:
- Scriberr **honest-life-pause** (109)
- Astuto **honest-discontinuation** (113)
- Jellystat **honest-rewrite-pause** (114)
- **Stump honest-WIP-status** (1st — Stump; distinct: active dev but pre-1.0)

Built + maintained by **Aaron Leopold (aaronleopold)** / **stumpapp**. License: **MIT**. Active; Discord; Docker Hub; Awesome-Self-Hosted listed.

Use cases: (a) **OSS Komga/Kavita-alternative** — Rust-native performance (b) **OPDS server** — eReader access (c) **comics/manga collection server** (d) **digital-book hosting** (e) **family comics-lib** (f) **personal-cloud-bookshelf** (g) **Kobo/Kindle OPDS ingestion** (h) **multi-user household book server**.

Features (per README; active-WIP):

- **Rust backend** (Axum) + **React frontend**
- **SeaORM** for DB
- **OPDS support** — for eReader apps
- **Comics + manga + digital books**
- Under active roadmap development

- Upstream repo: <https://github.com/stumpapp/stump>
- Discord: <https://discord.gg/63Ybb7J3as>
- Docker Hub: <https://hub.docker.com/r/aaronleopold/stump>

## Architecture in one minute

- **Rust** (Axum + SeaORM) backend
- **React** frontend
- **SQLite** (SeaORM) likely
- **Resource**: low — Rust tends to
- **Port**: web UI

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker**         | **`aaronleopold/stump`**                                        | **Primary**                                                                        |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `books.example.com`                                         | URL          | TLS                                                                                    |
| Library path         | `/media/books`                                              | Storage      | Read-only preferred                                                                                    |
| Admin creds          | First-boot                                                  | Bootstrap    |                                                                                    |
| OPDS consumers       | eReader apps                                                | Integration  |                                                                                    |

## Install via Docker

```yaml
services:
  stump:
    image: aaronleopold/stump:latest        # **pin - early versions may be breaking**
    volumes:
      - ./stump-config:/config
      - /media/books:/data:ro
    ports: ["10801:10801"]
    restart: unless-stopped
```

## First boot

1. Start; browse web UI
2. Create admin account
3. Add library (point at `/data`)
4. Let scan complete
5. Test OPDS endpoint in eReader app
6. Put behind TLS + auth
7. **Expect rough edges — WIP**

## Data & config layout

- `/config/` — SQLite + config + metadata-cache
- `/data/` — your books (read-only)

## Backup

```sh
sudo tar czf stump-config-$(date +%F).tgz stump-config/
```

## Upgrade

1. Releases: <https://github.com/stumpapp/stump/releases>. Active.
2. **Breaking changes possible during WIP**
3. Test on small lib first

## Gotchas

- **129th HUB-OF-CREDENTIALS TIER 2 — BOOK-LIBRARY-METADATA**:
  - Reading-habit + user-sessions + OPDS-credentials
  - **129th tool in hub-of-credentials family — Tier 2**
- **🚧 WIP-DISCLAIMER = HONEST STEWARDSHIP PATTERN**:
  - Author explicit that it's not production-ready
  - **NEW institutional-stewardship sub-tier: "honest-WIP-disclaimer"** (1st — Stump)
  - **Honest-maintainer-declaration: 4 tools** 🎯 **4-TOOL MILESTONE**
  - Distinguished from discontinuation/pause patterns: Stump is ACTIVELY developing, just pre-1.0
- **PRE-1.0 SOFTWARE OPERATIONAL RISK**:
  - Breaking changes between versions
  - Limited bug-fix velocity (solo)
  - Plan for possible redeploys
  - **Recipe convention: "pre-1.0-operational-discipline callout"**
  - **NEW recipe convention** (Stump 1st formally)
- **READ-ONLY-LIBRARY-MOUNT**:
  - **Read-only-library-mount-discipline: 3 tools** (Polaris+Kyoo+Stump) 🎯 **3-TOOL MILESTONE**
- **OPDS = STANDARD PROTOCOL**:
  - OPDS (Open Publication Distribution System)
  - eReader apps worldwide support it
  - **Recipe convention: "open-standard-protocol-interop positive-signal"**
  - **NEW positive-signal convention** (Stump 1st formally)
- **RUST-NATIVE PERFORMANCE**:
  - **Rust-built-high-throughput-tool: 3 tools** (Polaris+Parseable+Stump) 🎯 **3-TOOL MILESTONE**
- **AWESOME-SELF-HOSTED LISTED**:
  - Curated-list inclusion
  - **Recipe convention: "awesome-self-hosted-listed positive-signal"**
  - **NEW positive-signal convention** (Stump 1st formally)
- **MIT LICENSE**:
  - Permissive
- **DOCKER-HUB-NON-ORG ACCOUNT**:
  - Image at `aaronleopold/stump` — personal account
  - No `stumpapp/stump` on Docker Hub yet
  - Minor consistency note
- **INSTITUTIONAL-STEWARDSHIP**: aaronleopold sole + Discord + Docker Hub + Awesome-SH + WIP-honest. **115th tool — honest-WIP-disclaimer sub-tier** (NEW — positive despite pre-release status).
- **TRANSPARENT-MAINTENANCE**: active + Discord + roadmap + honest-WIP + Docker Hub + releases. **121st tool in transparent-maintenance family.**
- **COMICS/BOOK-SERVER-CATEGORY:**
  - **Stump** — Rust; WIP; OPDS; modern
  - **Komga** — Java/Kotlin; mature; comics-focused
  - **Kavita** — C#; mature; comics + books
  - **Calibre-Web** — Python; mature; books-focused
  - **Calibre** (desktop + optional web) — enterprise
- **ALTERNATIVES WORTH KNOWING:**
  - **Komga** — if you want mature + active + comics
  - **Kavita** — if you want mature + comics+books
  - **Calibre-Web** — if you want books-only + mature
  - **Choose Stump if:** you want Rust + OPDS + willing to tolerate WIP.
- **PROJECT HEALTH**: WIP-active + Discord + MIT + Rust + roadmap-visible. Promising; not-production.

## Links

- Repo: <https://github.com/stumpapp/stump>
- Discord: <https://discord.gg/63Ybb7J3as>
- Komga (alt): <https://github.com/gotson/komga>
- Kavita (alt): <https://github.com/Kareadita/Kavita>
- Calibre-Web (alt): <https://github.com/janeczku/calibre-web>
