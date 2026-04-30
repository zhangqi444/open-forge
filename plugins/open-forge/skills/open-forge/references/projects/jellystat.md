---
name: Jellystat
description: "Open-source Jellyfin statistics app (session monitoring + watch history + library stats). ⚠️ AUTHOR REBUILDING FROM SCRATCH — current codebase on extended pause (honest-rewrite-pause notice). PostgreSQL + Node.js + JWT. CyferShepard sole."
---

# Jellystat

Jellystat is **"Tautulli (for Plex) — but for Jellyfin"** — statistics app for Jellyfin server. Session monitoring + logging, per-library + per-user stats, watch history, user-activity overview, backup/restore of Jellystat data, auto-sync library items, Jellyfin Statistics Plugin integration.

## ⚠️ MAINTAINER STATUS: REBUILD IN PROGRESS — EXTENDED PAUSE

Per README: **"I've decided to rebuild Jellystat from the ground up, using a more modern architecture. ... For now, what this means is, for a while, the project is not going to be updated. I will probably push a few fixes for any major bugs that are easily reproduced."**

This is **honest-rewrite-pause** by maintainer CyferShepard. Distinct from:
- Astuto (113) **honest-discontinuation** (permanent end)
- Scriberr (109) **honest-pause-life-circumstances** (author personal reasons)

Jellystat = **honest-pause-for-rewrite** (technical-reason; intent to return with new version).

**Implication**: current codebase is frozen; major-bugs only. Plan accordingly for new deployments.

Built + maintained by **CyferShepard** (sole). License: check LICENSE. **Current-codebase-paused-rewriting**.

Use cases: (a) **monitor Jellyfin in-session playback** (b) **library-growth tracking** (c) **user-activity reports** (d) **watch-history archive** — Jellyfin forgets; Jellystat remembers (e) **family-server admin tools**.

Features (per README):

- Session monitoring + logging
- Library + user statistics
- Watch history
- User overview + activity
- Watch statistics
- Backup + restore of Jellystat's own data
- Auto-sync library items from Jellyfin
- Jellyfin Statistics Plugin integration

- Upstream repo: <https://github.com/CyferShepard/Jellystat>

## Architecture in one minute

- **Node.js** (TS)
- **PostgreSQL**
- **JWT auth**
- **Resource**: moderate — 200-400MB RAM
- **Port**: web UI + API

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker Compose** | **Upstream**                                                    | **Primary** (while paused)                                                                        |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `jstats.example.com`                                        | URL          | TLS                                                                                    |
| Admin creds          | First-boot                                                  | Bootstrap    |                                                                                    |
| POSTGRES_* (all)     | User, password, IP, port                                    | DB           | ALL required                                                                                    |
| **JWT_SECRET**       | Strong secret                                               | **CRITICAL** |                                                                                    |
| TZ                   | Timezone                                                    | Required     |                                                                                    |
| Jellyfin URL + API key | For data-source                                           | Connect      | Read-access                                                                                    |
| JS_USER / JS_PASSWORD (opt) | Master override (if you forget setup creds)          | Recovery     |                                                                                    |

## Install via Docker

```yaml
services:
  jellystat-db:
    image: postgres:17
    environment:
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: jellystats
    volumes: [pgdata:/var/lib/postgresql/data]

  jellystat:
    image: cyfershepard/jellystat:latest        # **frozen codebase; pin version**
    environment:
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_IP: jellystat-db
      POSTGRES_PORT: 5432
      JWT_SECRET: ${JWT_SECRET}
      TZ: UTC
    ports: ["3000:3000"]
    depends_on: [jellystat-db]

volumes:
  pgdata: {}
```

## First boot

1. Start stack
2. Browse UI; create admin
3. Connect to Jellyfin (URL + API key)
4. Sync library data
5. Explore stats
6. Put behind TLS reverse proxy
7. Back up PG DB + config

## Data & config layout

- PostgreSQL — all Jellyfin-sync'd stats, watch-history, user-data

## Backup

```sh
docker compose exec jellystat-db pg_dump -U $POSTGRES_USER jellystats > jellystat-$(date +%F).sql
```

## Upgrade

1. Releases: <https://github.com/CyferShepard/Jellystat/releases>. **Paused — major-bug fixes only until rewrite**.
2. For now, lock to known-good version
3. Watch for new rewritten version announcement

## Gotchas

- **126th HUB-OF-CREDENTIALS TIER 2 — JELLYFIN-WATCH-HISTORY**:
  - Holds: Jellyfin API key + full watch-history per user + library-indexes + JWT secret
  - **126th tool in hub-of-credentials family — Tier 2**
- **⚠️ HONEST-REWRITE-PAUSE STEWARDSHIP PATTERN**:
  - **NEW institutional-stewardship sub-tier: "honest-rewrite-pause"** (1st — Jellystat)
  - Distinct from Astuto (113 honest-discontinuation) + Scriberr (109 honest-pause-life) 
  - All three are positive-stewardship-despite-negative-outcome variants
  - **Honest-maintainer-declaration: 3 tools** 🎯 **3-TOOL MILESTONE** (Scriberr+Astuto+Jellystat — 3 distinct flavors)
- **FROZEN-CODEBASE-ACCEPTABLE-RISK**:
  - Jellyfin-integration is read-only → smaller attack surface
  - Self-hosted behind reverse-proxy → acceptable during pause
  - Major bugs only will be fixed
  - **Recipe convention: "frozen-codebase-during-rewrite-risk callout"** — similar to but distinct from "unmaintained-but-honestly-declared" (Astuto)
  - **NEW recipe convention** (Jellystat 1st formally)
- **JWT_SECRET + POSTGRES_PASSWORD**:
  - Standard fare for Node+PG stack
- **JS_USER / JS_PASSWORD OVERRIDE**:
  - Admin override creds in env — useful for recovery BUT weakens security model
  - Production: unset after first login
  - **Recipe convention: "admin-override-env-var-discipline" callout**
  - **NEW recipe convention** (Jellystat 1st formally)
- **BACKUP/RESTORE FEATURE BUILT-IN**:
  - Jellystat has built-in backup/restore of its own data
  - **Recipe convention: "built-in-data-export-import positive-signal"**
  - **NEW positive-signal convention** (Jellystat 1st formally)
- **JELLYFIN-STATISTICS-PLUGIN-COMPANION**:
  - Integrates with specific plugin
  - **Recipe convention: "plugin-integration-dependency-chain" callout**
- **SELF-AWARE-REWRITE DECISION**:
  - Author: "A lot of bugs and issues keep piling up, and since it was one of the first projects I made using Node.js there was a lot that I learnt which could have been done better."
  - HONEST self-assessment of code-quality
  - **Recipe convention: "honest-code-quality-assessment positive-signal"**
  - **NEW positive-signal convention** (Jellystat 1st formally)
- **JELLYFIN-DOMINANT-ECOSYSTEM-PLACE**:
  - Jellystat is a leading Jellyfin-stats-tool
  - Community awaits new version
  - **Recipe convention: "ecosystem-leader-under-rewrite callout"**
  - **NEW recipe convention** (Jellystat 1st formally)
- **INSTITUTIONAL-STEWARDSHIP**: CyferShepard sole + honest-rewrite-pause + community-expectations. **112th tool — honest-rewrite-pause sub-tier** (NEW).
- **TRANSPARENT-MAINTENANCE**: partial — **NOT counting toward active-maintenance family (frozen-for-rewrite)**. Reserved for when rewrite ships.
- **JELLYFIN-STATS-CATEGORY:**
  - **Jellystat** — paused for rewrite
  - **Jellyfin native stats** (built-in basic)
  - **jf-stat-reports** — community alternatives emerging
- **ALTERNATIVES WORTH KNOWING:**
  - **Jellyfin native stats** — if you want basic only
  - **Wait for Jellystat rewrite** — if you want future-proof
  - **Tautulli** — if you're on Plex instead
  - **Choose current Jellystat if:** you accept frozen-codebase + need full-stats now.
- **PROJECT HEALTH**: frozen-for-rewrite; author-active-on-rewrite; honest-communication. **Long-term positive; short-term paused.**

## Links

- Repo: <https://github.com/CyferShepard/Jellystat>
- Jellyfin: <https://jellyfin.org>
- Tautulli (Plex equivalent): <https://tautulli.com>
