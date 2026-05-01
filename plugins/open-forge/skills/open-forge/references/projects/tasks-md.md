---
name: Tasks.md
description: "Self-hosted Markdown file-based task management board. Cards are Markdown files. Single Docker image; SQLite-less design. Subpath-reverse-proxy ready. PWA. 3 built-in themes. baldissaramatheus."
---

# Tasks.md

Tasks.md is **"Trello — but every card is just a .md file in a folder"** — a Kanban board where cards are Markdown files. **File-system is the data model**. Easy Docker install. Light/dark themes (synced to OS). 3 color themes (Adwaita, Nord, Catppuccin). Subpath reverse-proxy ready (env var). PWA installable. Multilingual (browser-detected, user-persistent).

Built + maintained by **Matheus Baldissara (BaldissaraMatheus)**. Docker Hub. Released v3 (with migration guide v2→v3).

Use cases: (a) **Git-backed Kanban** — `.md` files commit naturally (b) **simple self-hosted Trello** (c) **family task-board** (d) **Markdown-first productivity** (e) **Obsidian-adjacent Kanban** (with same folder) (f) **minimalist team-board** (g) **local+portable task board** (h) **no-database Kanban**.

Features (per README):

- **Cards = Markdown files**
- **Modern responsive UI**
- **Single Docker image**
- **Light/dark + 3 themes** (Adwaita, Nord, Catppuccin)
- **Subpath reverse-proxy** support
- **PWA installable**
- **Multilingual** (auto-detect + per-user)

- Upstream repo: <https://github.com/BaldissaraMatheus/Tasks.md>
- Migration guide v2→v3: <https://github.com/BaldissaraMatheus/Tasks.md/blob/main/migration-guide.md>

## Architecture in one minute

- **Node.js or PHP** likely (check Dockerfile)
- **No database** — files on disk
- **Resource**: very-low — ~100MB
- **Port**: 8080
- **PWA**: installable from browser

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker**         | **`baldissaramatheus/tasks.md`**                                | **Primary**                                                                        |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain / subpath     | `/tasks` or root                                            | URL          | BASE_PATH env                                                                                    |
| PUID / PGID          | Typically 1000                                              | FS           | Owner discipline                                                                                    |
| Tasks directory      | `/path/to/tasks` — your MD files live here                  | Storage      | **Git-backable**                                                                                    |
| Config directory     | For user prefs                                              | Storage      |                                                                                    |
| TITLE                | Displayed name                                              | Optional     |                                                                                    |
| BASE_PATH            | `/tasks` or blank                                           | Optional     | **PWA breaks if non-root**                                                                                    |

## Install via Docker

```sh
docker run -d \
  --name tasks.md \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TITLE="Family Tasks" \
  -e BASE_PATH="" \
  -e LOCAL_IMAGES_CLEANUP_INTERVAL=1440 \
  -p 8080:8080 \
  -v /srv/tasks-md/tasks/:/tasks/ \
  -v /srv/tasks-md/config/:/config/ \
  --restart unless-stopped \
  baldissaramatheus/tasks.md:3        # **pin v3**
```

## First boot

1. Create tasks dir and config dir owned by PUID:PGID
2. Start
3. Browse → create a lane, add a card
4. Inspect the tasks directory — see the .md files
5. **Consider `git init`** in tasks dir for version-control
6. Install as PWA on devices (if BASE_PATH is root)
7. Put behind TLS reverse proxy

## Data & config layout

- `/tasks/` — the .md files (your cards)
- `/config/` — UI prefs, themes, locales per user

## Backup

```sh
# Simply git init + commit tasks dir
cd /srv/tasks-md/tasks && git init && git add . && git commit -m "initial"
# Or tar:
sudo tar czf tasks-md-$(date +%F).tgz /srv/tasks-md/
```

## Upgrade

1. Releases: <https://github.com/BaldissaraMatheus/Tasks.md/releases>
2. **v2→v3 migration required** — read migration-guide.md
3. Docker pull new version + restart

## Gotchas

- **139th HUB-OF-CREDENTIALS Tier 3 — MILD**:
  - Plain-text Markdown files on disk
  - No auth built-in (usually — put behind auth proxy)
  - Tasks may contain notes, URLs, maybe accidentally secrets
  - **139th tool in hub-of-credentials family — Tier 3**
- **NO-AUTH-BY-DEFAULT**:
  - Must be behind auth reverse proxy
  - **Recipe convention: "no-auth-must-reverse-proxy-gate callout"** — reinforces
- **FILE-SYSTEM-IS-DATA-MODEL**:
  - Cards = files; no DB
  - Enables Git version-control
  - Enables symlinks to Obsidian vault etc.
  - **File-system-as-data-model: 2 tools** (PiGallery2 directory-first + Tasks.md files-as-cards) 🎯 **2-TOOL MILESTONE**
  - **Recipe convention: "file-system-is-data-model positive-signal"**
  - **NEW positive-signal convention** (Tasks.md 1st formally)
- **GIT-NATURAL-BACKUP**:
  - Because cards are files, `git add .` just works
  - **Recipe convention: "Git-backed-plain-text-archive positive-signal"**
  - **NEW positive-signal convention** (Tasks.md 1st formally)
- **V2→V3 MIGRATION TAX**:
  - Author provides migration guide (honest + good)
  - But: operators must read + plan
  - **Recipe convention: "major-version-migration-guide-required callout"**
  - **Recipe convention: "author-provided-migration-guide positive-signal"**
  - **NEW conventions** (Tasks.md 1st formally)
- **PWA-NEEDS-ROOT-BASE-PATH**:
  - README warns PWA breaks with non-root BASE_PATH
  - Tradeoff: subpath-deploy vs PWA
  - **Recipe convention: "subpath-deploy-vs-PWA-tradeoff callout"**
  - **NEW recipe convention** (Tasks.md 1st formally)
- **IMAGE-CLEANUP-INTERVAL-CONFIG**:
  - LOCAL_IMAGES_CLEANUP_INTERVAL (minutes) for orphan-image cleanup
  - Good hygiene
  - **Recipe convention: "orphan-image-cleanup-schedule positive-signal"**
  - **NEW positive-signal convention** (Tasks.md 1st formally)
- **PUID/PGID-LINUXSERVER-CONVENTION**:
  - Standard linuxserver.io-style PUID/PGID
  - **PUID-PGID-linuxserver-convention: 1 tool** 🎯 **NEW FAMILY** (Tasks.md)
- **3-THEME-CHOICE**:
  - Respects user-preference
  - **Recipe convention: "multiple-color-theme-choice positive-signal"** — minor-positive
- **INSTITUTIONAL-STEWARDSHIP**: BaldissaraMatheus sole + Docker Hub + migration-guide + v3-released + themes. **125th tool — sole-maintainer-with-migration-guide sub-tier** (NEW-soft).
- **TRANSPARENT-MAINTENANCE**: active + Docker Hub + releases + migration-guide + screenshots. **131st tool in transparent-maintenance family.**
- **MARKDOWN-KNOWLEDGE-BASE META-FAMILY: 6 tools** (+Tasks.md) 🎯 **6-TOOL MILESTONE** (NoteDiscovery-style expansion)
- **KANBAN-CATEGORY:**
  - **Tasks.md** — files-as-cards; minimal
  - **Planka** — Trello-clone; Node+PG
  - **Wekan** — mature-Kanban; MongoDB
  - **Focalboard** — Mattermost-adjacent
  - **Kanboard** — PHP; mature
- **ALTERNATIVES WORTH KNOWING:**
  - **Planka** — if you want full Trello features + multi-user
  - **Wekan** — if you want mature + heavy-featured
  - **Choose Tasks.md if:** you want Markdown-first + Git-backable + minimalist.
- **PROJECT HEALTH**: active + v3 + migration-support + Docker Hub. Strong for niche.

## Links

- Repo: <https://github.com/BaldissaraMatheus/Tasks.md>
- Migration v2→v3: <https://github.com/BaldissaraMatheus/Tasks.md/blob/main/migration-guide.md>
- Planka (alt): <https://github.com/plankanban/planka>
- Wekan (alt): <https://github.com/wekan/wekan>
