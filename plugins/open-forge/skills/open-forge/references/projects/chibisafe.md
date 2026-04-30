---
name: Chibisafe
description: "TypeScript file uploader service. Public / user-accounts / invite-only modes. S3 support, chunked uploads, API keys, dashboard-config, ShareX integration, albums, snippets, URL shortener, iOS shortcut. MIT. pitu sole + Patreon/BMC + Discord."
---

# Chibisafe

Chibisafe is **"Lolisafe / Zipline / Gokapi — but TypeScript + dashboard-configurable + ShareX-first"** — a file uploader service in TypeScript. Accepts files/photos/documents → returns shareable link. Public / user-accounts / **invite-only modes**. Big files chunked for reliability. **S3 storage support**. API keys for programmatic use. **Everything configurable from the dashboard UI** (name, rate-limit, max file size, extensions, meta descriptions — no touching env/config files). **Albums + folders**, **Snippets/Gists**, **file tagging**, **user quotas**, **URL shortener** built-in. **ShareX** out-of-the-box integration. **iOS shortcut** + **browser extension**. Extensible.

Built + maintained by **pitu (sole maintainer)** + Discord community + Patreon/BMC funded. License: **MIT**. Active; **v6 "Holo"** current; chibisafe.app for docs; repobeats.axiom.co analytics badge.

Use cases: (a) **personal file-sharing + screenshot-hosting** — ShareX desktop + upload (b) **community / friend-group file-share** — invite-only mode (c) **developer workflow** — API + browser-extension + iOS-shortcut (d) **replace Imgur / Gyazo** — own-hosted screenshots + images (e) **one-tool-file-albums + snippets + URL-shortener** (f) **organizational quota-enforcement** — per-user quotas (g) **no-code admin** — everything via dashboard (h) **lightweight file-vault**.

Features (per README):

- **File upload** (public/user/invite-only modes)
- **S3 storage support**
- **Chunked uploads** for big files
- **Masonry browsing** for media files
- **Direct share links** to files
- **Albums / folders** with share-links
- **Snippets / Gists** (code-paste with direct links)
- **File tagging + management**
- **User management + quotas**
- **URL shortener** built-in
- **ShareX** out-of-the-box
- **iOS shortcut** for upload
- **Browser extension**
- **API keys** for programmatic use
- **Dashboard configuration** (no config files needed)

- Upstream repo: <https://github.com/chibisafe/chibisafe>
- Docs: <https://chibisafe.app>
- Discord: <https://discord.gg/5g6vgwn>
- Patreon: <https://www.patreon.com/pitu>

## Architecture in one minute

- **TypeScript** (Node.js backend + React frontend)
- **SQLite / PostgreSQL** DB
- **S3-compatible** object storage (optional; local otherwise)
- **Resource**: low-moderate — 300-500MB RAM
- **Port 8000 / 24424** default

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker Compose** | **Upstream**                                                    | **Primary**                                                                        |
| Source             | Node.js                                                                            | Dev                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `upload.example.com`                                        | URL          | TLS                                                                                    |
| Admin creds          | First-boot                                                  | Bootstrap    | Strong                                                                                    |
| `SECRET` / JWT key   | Session signing                                             | **CRITICAL** | **IMMUTABLE**                                                                                    |
| Storage backend      | Local OR S3                                                 | Storage      |                                                                                    |
| S3 creds (if S3)     | Bucket + keys + endpoint                                    | Storage      |                                                                                    |
| Public/user/invite mode | Decide at deploy                                                                                                    | Policy       |                                                                                    |
| Rate limits          | Per-IP / per-user                                                                                                      | Config       |                                                                                    |

## Install via Docker

Follow: <https://chibisafe.app>

```yaml
services:
  chibisafe:
    image: chibisafe/chibisafe:latest        # **pin version**
    volumes:
      - chibisafe-data:/app/uploads
      - chibisafe-db:/app/database
    ports: ["8000:8000"]
    restart: unless-stopped

volumes:
  chibisafe-data: {}
  chibisafe-db: {}
```

## First boot

1. Start → browse web UI
2. Create admin account
3. Decide mode (public / user / invite-only)
4. Configure from DASHBOARD (no env-file editing)
5. Test upload (small + chunked-big)
6. Configure rate-limits + max-size
7. Integrate ShareX / iOS-shortcut / browser-extension
8. Put behind TLS reverse proxy
9. Back up DB + uploads

## Data & config layout

- `/app/database/` — SQLite (if SQLite) — all metadata
- `/app/uploads/` — local storage
- S3 bucket (if S3-backed)

## Backup

```sh
sudo tar czf chibisafe-$(date +%F).tgz chibisafe-db/ chibisafe-data/
# If S3-backed: config-DB is what matters
```

## Upgrade

1. Releases: <https://github.com/chibisafe/chibisafe/releases>. Active.
2. Docker pull + restart
3. **V6 "Holo"** — migrations from v5 need care; read release notes
4. **Major-version-breaking-migration** — follow upstream guide

## Gotchas

- **PUBLIC MODE = ABUSE MAGNET**:
  - Public = anyone can upload (no auth)
  - **META-FAMILY: "public-UGC-host-abuse-conduit-risk"** extended
  - **Now 8 tools** (Slash + Zipline + Opengist + OxiCloud + FileGator + PicoShare + Gokapi + **Chibisafe**)
  - **8-tool milestone 🎯**
  - **Mitigation**: use invite-only or user mode; avoid public
- **INVITE-ONLY MODE = REASONABLE DEFAULT**:
  - Invitation required to create account
  - **Recipe convention: "invite-only-as-default-defense positive-signal"**
  - **NEW positive-signal convention** (chibisafe 1st formalized; prior: Wizarr 105 had similar)
- **DASHBOARD CONFIG = DOUBLE-EDGED**:
  - **PRO**: operators can tune without editing configs / restarting
  - **CON**: admin-compromise = runtime-config-rewrite attack
  - **Recipe convention: "runtime-dashboard-config attack-surface" callout**
  - **NEW recipe convention** (chibisafe 1st formally)
- **SHAREX OUT-OF-THE-BOX**:
  - ShareX (Windows screenshot tool) integration by default
  - Common Zipline pattern (also Zipline 98)
  - **Recipe convention: "ShareX-upload-integration positive-signal"**
  - **NEW positive-signal convention**
- **IOS SHORTCUT + BROWSER EXTENSION**:
  - Multi-platform upload flexibility
  - **Recipe convention: "multi-platform-upload-integration positive-signal"**
- **CHUNKED UPLOADS**:
  - Big files split into chunks — handles network issues
  - **Recipe convention: "chunked-uploads-for-reliability positive-signal"**
  - **NEW positive-signal convention**
- **URL SHORTENER BUILT-IN = FEATURE-CREEP / CONVENIENCE**:
  - URL shortener baked in
  - Could be attack-vector for malicious-URL-hosting
  - **Recipe convention: "URL-shortener-abuse-vector" callout**
  - **NEW recipe convention** (chibisafe 1st)
- **SNIPPETS/GISTS BUILT-IN**:
  - Code paste with links
  - Similar to Opengist (prior batch)
  - **Multi-function-file-tool**: adds another use-case (and attack-surface)
- **95th HUB-OF-CREDENTIALS TIER 2**:
  - User accounts + API keys + S3 creds + URL-shortener + etc.
  - **95th tool in hub-of-credentials family — Tier 2**
- **MULTI-FUNCTION TOOL = ATTACK-SURFACE EXPANSION**:
  - Files + albums + snippets + URL-shortener + tags = bigger codebase
  - More features = more CVE-opportunity
  - **Recipe convention: "multi-function-tool-attack-surface-expansion" callout**
  - **NEW recipe convention** (chibisafe 1st)
- **V6 MAJOR-MIGRATION**:
  - Major version ("Holo") = breaking migration
  - **Recipe convention: "major-version-breaking-migration" extended**: prior Grimoire 106 + now chibisafe
  - 2 tools now
- **INSTITUTIONAL-STEWARDSHIP**: pitu sole + Patreon + BMC + Discord + community. **81st tool — sole-maintainer-with-multi-stream-monetization sub-tier** (reuses tududi 107 precedent).
  - **NOT NEW** sub-tier — already established by tududi
- **TRANSPARENT-MAINTENANCE**: active + docs + Discord + Patreon + BMC + Repobeats + releases + v6-migration-doc. **89th tool in transparent-maintenance family.**
- **FILE-UPLOADER-CATEGORY (crowded):**
  - **Chibisafe** — TypeScript; dashboard-config; ShareX; multi-feature
  - **Zipline** — Node; ShareX-focused
  - **Gokapi** — Go; e2e + S3 + OIDC
  - **PicoShare** — Go; simplest
  - **Firefly/PingVin** — Node
  - **Lolisafe** — chibisafe's predecessor (legacy)
  - **Transfer.sh** — CLI
- **ALTERNATIVES WORTH KNOWING:**
  - **Zipline** — if you want alternative ShareX-focused
  - **Gokapi** (batch 107) — if you want Go + e2e + OIDC
  - **PicoShare** — if you want minimal
  - **Choose chibisafe if:** you want TypeScript + dashboard-config + multi-feature + ShareX + iOS-shortcut.
- **PROJECT HEALTH**: active + sole-maintainer + Discord + Patreon + sustained. Decent for solo-maintainer (depends on pitu).

## Links

- Repo: <https://github.com/chibisafe/chibisafe>
- Docs: <https://chibisafe.app>
- Discord: <https://discord.gg/5g6vgwn>
- Zipline (alt): <https://github.com/diced/zipline>
- Gokapi (batch 107): <https://github.com/Forceu/Gokapi>
- PicoShare (batch 103): <https://github.com/mtlynch/picoshare>
- Lolisafe (predecessor): <https://github.com/WeebDev/lolisafe>
