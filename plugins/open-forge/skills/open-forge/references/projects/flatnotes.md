---
name: Flatnotes
description: "Self-hosted database-less note-taking web app. Flat folder of markdown files = storage. Wikilinks, tagging, full-text search. Python + Whoosh. Docker. Active; sole-maintainer sponsorship model. Demo site available."
---

# Flatnotes

Flatnotes is **"Obsidian / Bear / Notion — but database-less + markdown-flat-folder + self-hosted"** — a minimalist note-taking web app that uses a flat folder of markdown files as storage. No database, no proprietary format, no folder hierarchy — just tags + search + wikilinks. The design principle is "don't take your notes hostage": notes are plain markdown files you can move anywhere, use with any editor, back up trivially. The Whoosh search index is the only cache and is incrementally synced on every search.

Built + maintained by **dullage** (sole maintainer) + community. License: check repo. Active; Docker Hub image; demo at demo.flatnotes.io; wiki; GitHub Sponsors.

Use cases: (a) **Obsidian-alternative with browser-only access** — no desktop app needed (b) **family-shared notes** — shared markdown folder for household (c) **lab-notebook** — researcher's markdown-based scratchpad (d) **API-driven note-taking** — REST API for scripting/automation (e) **zero-lock-in PKM** — markdown files move with you (f) **read-only public notes** — read-only mode for publishing notes (g) **mobile-friendly** — responsive web UI for phone use.

Features (from upstream README):

- **Mobile-responsive** web UI
- **Raw/WYSIWYG** markdown editor modes
- **Advanced search** (Whoosh full-text)
- **Tags**
- **Customizable home page**
- **Wikilinks** (`[[My Other Note]]`)
- **Light/dark themes**
- **Multiple auth options**: none / read-only / username-password / 2FA
- **REST API**
- **External-edit-safe**: add/edit/delete files outside Flatnotes while running

- Upstream repo: <https://github.com/dullage/flatnotes>
- Docker Hub: <https://hub.docker.com/r/dullage/flatnotes>
- Demo: <https://demo.flatnotes.io>
- Wiki: <https://github.com/dullage/flatnotes/wiki>

## Architecture in one minute

- **Python** (FastAPI) backend + Vue.js frontend
- **Whoosh** full-text search (Python-native)
- **Markdown files** on disk — the "database"
- **Resource**: low — 100-200MB RAM
- **Port 8080** default

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker**         | **`dullage/flatnotes:latest`**                                  | **Primary**                                                                        |
| Docker Compose     | Shown in README                                                 | Alternative                                                                                   |
| Bare-metal Python  | Pip install + uvicorn                                                                    | DIY                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Data dir             | `/data` volume → host `./flatnotes-data`                    | Storage      | **Your markdown files live here**                                                                                    |
| Auth mode            | none / read-only / password / 2FA                           | **CRITICAL** | **DON'T use `none` on internet-facing**                                                                                    |
| Admin user + pwd     | Username/password auth mode                                 | Bootstrap    | Strong                                                                                    |
| `FLATNOTES_SECRET_KEY` | Session signing                                           | **CRITICAL** | **IMMUTABLE** — invalidates sessions if changed                                                                                    |
| Port                 | 8080 default                                                | Network      |                                                                                    |

## Install via Docker

```sh
docker run -d \
  -p 8080:8080 \
  -v /path/to/notes:/data \
  -e FLATNOTES_AUTH_TYPE=password \
  -e FLATNOTES_USERNAME=admin \
  -e FLATNOTES_PASSWORD='${STRONG_PWD}' \
  -e FLATNOTES_SECRET_KEY='${SECRET}' \
  --name flatnotes \
  dullage/flatnotes:latest        # **pin in prod**
```

## First boot

1. Pick auth mode (password + 2FA strongly recommended for anything internet-facing)
2. Set secret key (keep permanent)
3. Mount data dir (your markdown folder)
4. Start → browse `:8080`
5. Log in → create first note
6. Add tags + try wikilinks
7. Test external-edit (modify file via terminal while Flatnotes is running)
8. Enable 2FA
9. Put behind TLS reverse proxy
10. Back up data dir

## Data & config layout

- `/data/` — all markdown notes (flat; no subfolders)
- `/data/.flatnotes/` — Whoosh search index (rebuildable)
- Env vars — all config

## Backup

```sh
# Trivial — just back up the data dir
sudo tar czf flatnotes-$(date +%F).tgz flatnotes-data/
# Or sync to another location with rsync / git
```

## Upgrade

1. Releases: <https://github.com/dullage/flatnotes/releases>. Active.
2. Docker: pull + restart; no migrations (no DB).
3. Search index rebuilds automatically on next access.

## Gotchas

- **DATABASE-LESS = HUGE PORTABILITY WIN**:
  - Notes are plain markdown; no proprietary format
  - Can use vim/emacs/VSCode/Obsidian/Bear side-by-side
  - Migration to another tool = trivial (just the markdown files)
  - **Recipe convention: "database-less tool — zero-lock-in"** positive signal
  - **NEW: "zero-lock-in" positive-signal convention** (Flatnotes 1st tool named)
  - Related-but-distinct from "standards-first-vendor-lock-mitigation" (OxiCloud 100): standards-first is about protocols; zero-lock-in is about storage format
- **NO-FOLDERS DESIGN = OPINIONATED**:
  - Intentional design: tags + search replace folder hierarchy
  - If you need folder hierarchy → Flatnotes is not for you; use Obsidian/Logseq
  - Good for: search-heavy workflow, low-volume notes, not-deeply-nested knowledge
  - Bad for: archivists, hierarchical-thinkers, Zettelkasten purists (Logseq/Obsidian fit better)
- **WHOOSH SEARCH INDEX** = incremental + Python-native:
  - Rebuilds on file changes
  - Low-resource (Whoosh is pure-Python)
  - No Elasticsearch/Solr complexity
- **AUTH MODES**: "none" mode is DANGEROUS on any internet-facing deploy. Even on LAN:
  - Guest WiFi → notes exposure
  - Kids' devices → accidental edits
  - **Always use password + 2FA for anything not fully isolated**
- **SECRET_KEY IMMUTABILITY**: **40th tool in immutability-of-secrets family.** (40-tool milestone!)
  - Changing SECRET_KEY invalidates all sessions
  - Changing it disconnects all active users
- **NO MULTI-USER ACCOUNTS**:
  - Single-user-per-instance (password auth = one account)
  - Family use case = shared credentials (not ideal)
  - For multi-user PKM → Logseq Sync, Obsidian Sync, Nextcloud Notes with multi-user
- **API = AUTOMATION POSSIBILITY**:
  - REST API enables:
    - Scripts that create notes (meeting-notes-from-calendar)
    - Backup automation
    - Cross-device sync (manual)
    - Bulk imports from other tools
- **PHYSICAL FILE ACCESS = DIRECT EDITING**:
  - Can `sed`, `grep`, `git commit` the markdown files directly
  - Flatnotes picks up changes live
  - **Pattern**: version-control the data dir with git for full history — power-user move
- **LIMITED PLUGIN ECOSYSTEM** (compared to Obsidian):
  - Flatnotes is minimalist by design
  - No plugin marketplace
  - If you need graph-view, canvas, Dataview → Obsidian/Logseq instead
- **SOLE-MAINTAINER**:
  - dullage runs the project solo
  - GitHub Sponsors funds some development
  - **45th tool in institutional-stewardship — sole-maintainer-with-visible-sponsor-support sub-tier (4th tool after MediaManager 97, AdventureLog 98, Viseron 99)**
  - Sub-tier now **4 tools** — further solidified
- **HUB-OF-CREDENTIALS TIER 3 (LOW — just personal notes, usually)**:
  - User's private notes (may contain secrets, journal entries, password hints, etc.)
  - Session cookie (encrypted via SECRET_KEY)
  - **60th tool in hub-of-credentials family — 60-tool MILESTONE**
  - **Tier 3**: low-to-moderate sensitivity typically
  - **Exception**: if notes contain passwords/secrets, escalates to Tier 2 — user's responsibility
- **TRANSPARENT-MAINTENANCE**: active + Docker-pulls-badge + demo site + wiki + releases + 2FA-support. **52nd tool in transparent-maintenance family.**
- **LICENSE CHECK**: verify LICENSE (convention).
- **NOTE-TAKING-CATEGORY (crowded):**
  - **Obsidian** — commercial (free for personal); Electron; huge plugin ecosystem
  - **Logseq** — OSS; block-based; outliner-paradigm
  - **Joplin** — OSS; commercial sync-tier; Electron + mobile apps
  - **Standard Notes** — OSS; E2E-encrypted; commercial-sync-tier
  - **Memos** (batch prior) — social-micro-posts; different shape
  - **SilverBullet** — OSS; minimal; markdown + notebook hybrid
  - **AppFlowy** — OSS; Notion-clone; Rust
  - **Outline** — OSS; team-wiki; BSL license
  - **BookStack** — OSS; team-documentation; PHP
  - **HedgeDoc** — OSS; real-time-collaborative markdown
  - **TiddlyWiki** — OSS; single-HTML-file wiki
  - **Flatnotes** — OSS; markdown-flat-folder; search-focused
- **ALTERNATIVES WORTH KNOWING:**
  - **Choose Flatnotes if:** you want database-less + markdown + simple + browser-only.
  - **Choose Obsidian if:** you want plugin-ecosystem + desktop + local-first.
  - **Choose Logseq if:** you want outliner + graph-view + block-refs.
  - **Choose SilverBullet if:** you want space-script power-user-lua features.
  - **Choose HedgeDoc if:** you want real-time collab.
  - **Choose Joplin if:** you want cross-platform sync + Evernote-shape.
- **PROJECT HEALTH**: active + demo + Docker-pulls + wiki + Sponsors + 2FA. Strong for a minimalist niche tool.

## Links

- Repo: <https://github.com/dullage/flatnotes>
- Docker: <https://hub.docker.com/r/dullage/flatnotes>
- Demo: <https://demo.flatnotes.io>
- Wiki: <https://github.com/dullage/flatnotes/wiki>
- Obsidian (commercial alt): <https://obsidian.md>
- Logseq (alt): <https://logseq.com>
- Joplin (alt): <https://joplinapp.org>
- Standard Notes (alt E2E): <https://standardnotes.com>
- SilverBullet (alt minimal): <https://silverbullet.md>
- HedgeDoc (alt collab): <https://hedgedoc.org>
- TiddlyWiki (alt single-file): <https://tiddlywiki.com>
