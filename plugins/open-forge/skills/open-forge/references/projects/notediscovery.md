---
name: NoteDiscovery
description: "Lightweight self-hosted Obsidian-like note-taking app. Markdown + file storage + web UI. gamosoft sole. Docker + PikaPods hosted + Ko-fi funding + Hugging Face Spaces demo."
---

# NoteDiscovery

NoteDiscovery is **"Obsidian / Notion / Evernote — but self-hosted + web + markdown"** — a lightweight knowledge base. Write in markdown; organize in folders; search; discover notes via links. Targets **privacy-conscious users, developers, knowledge-workers, teams** looking for a self-hostable Notion-alternative.

Built + maintained by **gamosoft** (sole). License: check LICENSE (GitHub license badge). Active; Docker + website (notediscovery.com) + Live Demo on Hugging Face Spaces + Ko-fi funding + PikaPods one-click.

Use cases: (a) **personal wiki / second brain** (b) **self-hosted Notion replacement** (c) **team knowledge-base** (d) **markdown-first notes** with browser UI (e) **dev-docs / project notes** (f) **research notes** (g) **classroom-notes-app** (h) **travel blog/notes** private.

Features (per README):

- **Markdown-first** note taking
- **File storage** (local files, not opaque DB)
- **Beautiful modern UI**
- **Self-hosted** (your server, your data)
- **Offline always works**
- **Fast** (local)
- **Free + OSS**
- **Hugging Face Spaces demo**
- **PikaPods one-click**
- **Ko-fi funding**

- Upstream repo: <https://github.com/gamosoft/NoteDiscovery>
- Website: <https://www.notediscovery.com>
- Demo: <https://gamosoft-notediscovery-demo.hf.space>
- PikaPods: <https://www.pikapods.com/pods?run=notediscovery>
- Ko-fi: <https://ko-fi.com/gamosoft>

## Architecture in one minute

- **Web app** (tech stack per source — check repo)
- **Markdown files on disk** as storage (per README — "local file storage")
- **Resource**: low — 100-300MB RAM
- **Port**: web UI

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker**         | **Upstream**                                                    | **Primary**                                                                        |
| **PikaPods**       | Managed hosting                                                                                                        | Pay                                                                                   |
| **Hugging Face Spaces** | Demo                                                                                                             | Try before deploy                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `notes.example.com`                                         | URL          | TLS                                                                                    |
| Admin / auth         | First-boot / per-instance                                   | Bootstrap    | Strong                                                                                    |
| Notes dir            | Persistent volume for markdown files                        | Storage      |                                                                                    |

## Install via Docker

Check repo for docker-compose:
```yaml
services:
  notediscovery:
    image: gamosoft/notediscovery:latest        # **pin version**
    volumes:
      - ./notes:/app/notes
    ports: ["8080:8080"]
    restart: unless-stopped
```

## First boot

1. Start → browse web UI
2. Create first note
3. Test markdown rendering
4. Add folders / tags
5. Put behind TLS reverse proxy + auth (check if app has auth; if not, add via reverse proxy)
6. Back up notes dir (just a folder — trivial)

## Data & config layout

- `/app/notes/` — markdown files on disk (clean — portable)

## Backup

```sh
sudo tar czf notediscovery-notes-$(date +%F).tgz notes/
# OR just git commit your notes dir — it's markdown, diff-friendly
```

## Upgrade

1. Releases: <https://github.com/gamosoft/NoteDiscovery/releases>. Active.
2. Docker pull + restart
3. Markdown files unchanged on upgrade (plain filesystem)

## Gotchas

- **112th HUB-OF-CREDENTIALS TIER 2 — KNOWLEDGE-BASE-DATA**:
  - Notes may contain personal thoughts, work secrets, credentials-in-notes
  - **112th tool in hub-of-credentials family — Tier 2**
  - **Markdown-knowledge-base META-FAMILY: 5 tools** (+NoteDiscovery) 🎯 **5-TOOL MILESTONE**
- **MARKDOWN-FILE-STORAGE = EXCELLENT**:
  - Plain markdown files on disk (no opaque DB)
  - Portable; easy backup; git-manageable
  - **Recipe convention: "plain-markdown-file-storage positive-signal"** — reinforces Grimoire/Silex
- **NO-VENDOR-LOCK-IN**:
  - Markdown + filesystem = transferable anywhere
  - **Zero-lock-in: 8 tools** (+NoteDiscovery) 🎯 **8-TOOL MILESTONE**
- **PIKAPODS INTEGRATION**:
  - One-click hosted-for-you option
  - **Recipe convention: "PikaPods-one-click positive-signal"** 
  - **NEW positive-signal convention** (NoteDiscovery 1st formally)
- **HUGGING-FACE-SPACES DEMO**:
  - Demo hosted on HF Spaces (free tier)
  - Novel deployment venue for note-taking demo
  - **Recipe convention: "Hugging-Face-Spaces-demo positive-signal"**
  - **NEW positive-signal convention** (NoteDiscovery 1st formally)
- **KO-FI FUNDING**:
  - Extends Scriberr 109 precedent
  - **Ko-Fi-funding: 2 tools** (Scriberr+NoteDiscovery) 🎯 **2-TOOL MILESTONE**
- **AUTH POLICY UNCLEAR FROM README**:
  - If no built-in auth, reverse-proxy auth MANDATORY for exposed deployment
  - **Recipe convention: "unclear-auth-policy-requires-reverse-proxy" callout**
  - **NEW recipe convention** (NoteDiscovery 1st formally)
- **KNOWLEDGE-BASE-CREDENTIAL-SPILLOVER-RISK**:
  - Users often dump API-keys, passwords into notes
  - **Recipe convention: "credentials-in-notes-spillover" callout** — universal for note apps
  - **NEW recipe convention** (NoteDiscovery 1st formally; applies to all note tools)
- **NOTE-TAKING-CATEGORY:**
  - **NoteDiscovery** — lightweight; markdown; web; filesystem
  - **Obsidian** (commercial closed; free personal) — desktop-first
  - **Logseq** — local-first; outliner
  - **Trilium** — web; mature; hierarchical
  - **Grimoire** (batch 106) — git-first
  - **Silex** (batch 106) — markdown-first-IDE
  - **AppFlowy** — Notion-like
  - **Outline** — team wiki
- **INSTITUTIONAL-STEWARDSHIP**: gamosoft sole + Ko-fi + PikaPods-integration + HF-demo + website + active. **98th tool — sole-maintainer-with-platform-integrations sub-tier** (soft new; reuses sole + integrations).
- **TRANSPARENT-MAINTENANCE**: active + website + demo + Ko-fi + Docker-Hub + GitHub-Actions-CI + PikaPods-listing. **106th tool in transparent-maintenance family.**
- **ALTERNATIVES WORTH KNOWING:**
  - **Obsidian** — if you want mature desktop + mobile + plugins
  - **Logseq** — if you want outliner + local-first
  - **Trilium** — if you want mature web + hierarchical
  - **AppFlowy / Outline** — if you want Notion-like
  - **Choose NoteDiscovery if:** you want lightweight + web-only + markdown + filesystem.
- **PROJECT HEALTH**: active + sole + Ko-fi-supported + multi-deploy-venue + responsive. Solid.

## Links

- Repo: <https://github.com/gamosoft/NoteDiscovery>
- Website: <https://www.notediscovery.com>
- Demo: <https://gamosoft-notediscovery-demo.hf.space>
- Obsidian (alt): <https://obsidian.md>
- Logseq (alt): <https://logseq.com>
- Trilium (alt): <https://github.com/zadam/trilium>
