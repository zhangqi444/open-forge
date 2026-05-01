---
name: Manyfold
description: "Self-hosted web app for managing a collection of 3D models, particularly focused on 3D printing. Ruby on Rails + Sidekiq. manyfold3d org. manyfold.app. Matrix chat. Fediverse. OpenCollective. All-contributors badge. Demo at try.manyfold.app."
---

# Manyfold

Manyfold is **"Thingiverse/Printables/MyMiniFactory — but self-hosted + OSS"** — a web app for managing a collection of 3D models, particularly focused on 3D printing. Organize STLs/3MFs with metadata, tags, licenses. Community-focused stewardship.

Built + maintained by **manyfold3d** org. Ruby on Rails + Sidekiq. Multi-channel community: GitHub, Matrix, Fediverse (Mastodon at 3dp.chat/@manyfold). OpenCollective funded. All-contributors badge. Demo at try.manyfold.app. manyfold.app site.

Use cases: (a) **3D-print model library** (b) **MakerLab / hackerspace shared-model-repo** (c) **personal STL organizer** (d) **tagged + categorized + licensed model browser** (e) **multi-user model sharing** (f) **Rails-app-community model** (g) **3D-printer-workflow front-end** (h) **alternative to cloud-hosted Thingiverse/Printables**.

Features (per README + docs):

- **Self-hosted 3D model management**
- **3D-print-focused**
- **Rails + Sidekiq** architecture
- **Demo available** at try.manyfold.app
- **Multi-community-channel presence**

- Upstream repo: <https://github.com/manyfold3d/manyfold>
- Website: <https://manyfold.app>
- Demo: <https://try.manyfold.app>
- Matrix: <https://matrix.to/#/#manyfold:matrix.org>
- Fediverse: <https://3dp.chat/@manyfold>
- Donations: <https://opencollective.com/manyfold>

## Architecture in one minute

- **Ruby on Rails** server
- **Sidekiq** background jobs (for thumbnailing, scanning, etc.)
- Server-side-rendered HTTP (no XHR/WS yet)
- Database (Postgres typical for Rails)
- **Resource**: moderate
- **Port**: HTTP

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker Compose** | App + Postgres + Redis (for Sidekiq)                                                                                   | **Primary**                                                                                   |
| **Native Rails**   | For devs                                                                                                               | Alt                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `manyfold.example.com`                                      | URL          | TLS                                                                                    |
| Postgres             | Data                                                        | DB           |                                                                                    |
| Redis                | Sidekiq queue                                               | Infra        |                                                                                    |
| Storage path         | STL / 3MF files                                             | Storage      | **Can be large**                                                                                    |
| Admin                | First-boot                                                  | Bootstrap    |                                                                                    |
| SMTP                 | User emails                                                 | Email        | Optional                                                                                    |

## Install via Docker Compose

See <https://manyfold.app/> for canonical compose. Typical:
```yaml
services:
  postgres:
    image: postgres:15
  redis:
    image: redis:7
  manyfold:
    image: manyfold3d/manyfold:v0.X.Y        # **pin**
    ports: ["3000:3000"]
    depends_on: [postgres, redis]
    volumes:
      - ./manyfold-data:/data
      - /3d-models:/models        # your STL collection
    environment:
      - DATABASE_URL=...
      - REDIS_URL=...
      - SECRET_KEY_BASE=...
```

## First boot

1. Start
2. Create admin
3. Configure library path
4. Scan library (background job thumbnails + metadata extracts)
5. Add tags + categories
6. Test multi-user flow if needed
7. Put behind TLS
8. Back up Postgres + /data

## Data & config layout

- Postgres — metadata, users, tags
- /data — thumbnails + extracted metadata
- /models — user's STL collection (separate mount)

## Backup

```sh
pg_dump manyfold > manyfold-$(date +%F).sql
sudo tar czf manyfold-data-$(date +%F).tgz manyfold-data/
# Raw STL files likely on separate storage
```

## Upgrade

1. Releases: <https://github.com/manyfold3d/manyfold/releases>
2. DB migrations (Rails-standard)
3. Docker pull + restart

## Gotchas

- **169th HUB-OF-CREDENTIALS Tier 2 — 3D-MODEL-LIBRARY**:
  - Holds: library metadata, user accounts, model licenses (some models have restrictive licenses)
  - STL/3MF files separately (may include commercial-licensed models)
  - **169th tool in hub-of-credentials family — Tier 2**
- **MODEL-LICENSE-AWARENESS**:
  - Thingiverse/Printables models have varied licenses (CC, commercial, etc.)
  - License metadata matters for redistribution
  - **Recipe convention: "3D-model-license-metadata-discipline callout"**
  - **NEW recipe convention** (Manyfold 1st formally)
- **STL-STORAGE-SIZE**:
  - 3D model files can be large (GB-range)
  - Object-storage or large-disk
  - **Recipe convention: "large-binary-asset-storage-planning callout"**
  - **NEW recipe convention** (Manyfold 1st formally)
- **RAILS + SIDEKIQ ECOSYSTEM**:
  - **Rails-framework: 1 tool** 🎯 **NEW FAMILY** (Manyfold)
  - **Sidekiq-background-jobs: 1 tool** 🎯 **NEW FAMILY** (Manyfold; Ruby BG-job ecosystem)
- **MULTI-COMMUNITY-CHANNEL-PRESENCE**:
  - GitHub + Matrix + Fediverse + OpenCollective — robust
  - **Multi-community-channel-presence: 3 tools** (Donetick+Open Archiver+Manyfold) 🎯 **3-TOOL MILESTONE**
- **FEDIVERSE-NATIVE-ORG-PRESENCE**:
  - Separate 3dp.chat Fediverse instance
  - **Recipe convention: "Fediverse-native-org-presence positive-signal"**
  - **NEW positive-signal convention** (Manyfold 1st formally)
- **MATRIX-CHAT-COMMUNITY**:
  - **Matrix-chat-community: 3 tools** (Ferron+Meet+Manyfold) 🎯 **3-TOOL MILESTONE**
- **OPENCOLLECTIVE-TRANSPARENT-FUNDING**:
  - **Open-Collective-transparent-finances: 5 tools** (+Manyfold) 🎯 **5-TOOL MILESTONE**
- **ALL-CONTRIBUTORS-BADGE**:
  - **All-contributors-badge: 2 tools** (ShellHub+Manyfold) 🎯 **2-TOOL MILESTONE**
- **LIVE-DEMO**:
  - try.manyfold.app; no-install to try
  - **Live-demo-available: N tools** (continuing family)
- **GOOD-FIRST-ISSUE-LABEL**:
  - Explicit good-first-issue triage
  - Welcoming to newcomers
  - **Recipe convention: "good-first-issue-label-welcoming positive-signal"**
  - **NEW positive-signal convention** (Manyfold 1st formally)
- **PUBLIC-ROADMAP-BOARD**:
  - Development roadmap on GitHub Projects
  - **Recipe convention: "public-taskboard-roadmap"** — reinforces Reitti (116)
- **INSTITUTIONAL-STEWARDSHIP**: manyfold3d org + website + demo + Matrix + Fediverse + OpenCollective + all-contributors + roadmap + good-first-issue. **155th tool — community-driven-niche-OSS sub-tier** (NEW-soft).
- **TRANSPARENT-MAINTENANCE**: active + demo + multi-channel-community + roadmap + good-first-issue. **161st tool in transparent-maintenance family.**
- **3D-MODEL-LIBRARY-CATEGORY:**
  - **Manyfold** — Rails; 3D-print-focused
  - **Thangs** — commercial cloud
  - **Printables/Thingiverse/MyMiniFactory** — commercial/community clouds
- **ALTERNATIVES WORTH KNOWING:**
  - **Thingiverse/Printables** — if you want public community + don't need self-host
  - **Choose Manyfold if:** you want self-hosted + private + license-tracking.
- **PROJECT HEALTH**: excellent — multi-channel + OpenCollective + demo + all-contributors + roadmap. Model community-driven project.

## Links

- Repo: <https://github.com/manyfold3d/manyfold>
- Website: <https://manyfold.app>
- Demo: <https://try.manyfold.app>
