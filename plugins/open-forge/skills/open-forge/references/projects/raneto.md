---
name: Raneto
description: "Markdown-powered knowledge base. Node.js; file-based (no DB); search + browser-markdown-editor + login for edit protection. MIT (check). ryanlelek maintainer; active per CI + FOSSA license-compliance badge."
---

# Raneto

Raneto is **"GitBook / MkDocs / Docusaurus — but Node.js + file-based + lightweight + simple"** — a markdown-powered knowledge base server. All content is **`.md` files on disk** (no database); full-text search across filenames + contents; browser-based markdown editor with login protection; simple + lightweight (file-based, minimal deps). Designed for small-to-medium internal wikis + project docs.

Built + maintained by **Ryan Lelek (ryanlelek)**. License: check repo (README refers to FOSSA license-compliance). Active; Node.js CI + FOSSA shield; mailing list for security alerts.

Use cases: (a) **small internal wiki** — team knowledge-base for Slack-exiles (b) **project documentation** — put .md files; auto-rendered (c) **customer-facing help docs** — password-protect-edits + public-read (d) **personal notes-wiki** — simpler than Obsidian + hosted (e) **markdown-first wiki** — edits via IDE / git; Raneto renders (f) **Flatnotes-like for teams** — multi-page + search (g) **replace Notion** for small teams wanting self-hosted (h) **Static-site alternative** — pure-markdown but without build step.

Features (per README):

- **File-based content** (no DB)
- **Search** — filename + contents
- **Browser markdown editor** — `allow_editing=true`
- **Login system** for edit protection
- **Simple + lightweight**
- **Localization** (LOCALE env)
- **Optional Google Analytics** integration
- **SESSION_SECRET min-32-chars** — sign sessions

- Upstream repo: <https://github.com/ryanlelek/Raneto>
- Homepage: <https://raneto.com>
- Live demo/docs: <https://docs.raneto.com>
- Mailing list: sibforms.com signup link in README

## Architecture in one minute

- **Node.js** (Express-based)
- **No DB** — content = directory of `.md` files
- **Resource**: very low — 100-200MB RAM
- **Port 8080** default

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Node.js**        | **npm / source**                                                | **Primary**                                                                        |
| Docker             | Community images; not upstream primary                                                                            |                                                                                    |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `wiki.example.com`                                          | URL          | TLS recommended                                                                                    |
| `SESSION_SECRET`     | 32+ char random                                             | **CRITICAL** | **IMMUTABLE** (sessions invalidate on change)                                                                                    |
| `BASE_URL`           | `https://wiki.example.com`                                  | URL          |                                                                                    |
| `CONTENT_DIR`        | `content/pages`                                             | Storage      | Path to .md files                                                                                    |
| `ADMIN_USERNAME` + `ADMIN_PASSWORD` | Edit-login                                                                              | Auth         |                                                                                    |
| `AUTHENTICATION`     | true/false                                                                               | Auth         |                                                                                    |
| `ALLOW_EDITING`      | true/false                                                                               | Auth         | Enable web editor                                                                                    |
| `PORT`               | 8080                                                                                                  | Network      |                                                                                    |
| `SITE_TITLE`         | Display title                                                                                                                   | Config       |                                                                                    |
| `LOCALE`             | en / fr / de / ...                                                                                                            | Config       |                                                                                                                                            |

## Install via npm

```sh
git clone https://github.com/ryanlelek/Raneto.git
cd Raneto
npm install
export SESSION_SECRET="$(openssl rand -base64 32)"
export ADMIN_USERNAME=admin
export ADMIN_PASSWORD="$(openssl rand -base64 32)"
export AUTHENTICATION=true
export ALLOW_EDITING=true
export BASE_URL=https://wiki.example.com
export PORT=8080
npm start
```

## First boot

1. Start → browse `http://host:8080`
2. If auth enabled: log in with `ADMIN_USERNAME/PASSWORD`
3. Browse demo content at `content/pages/`
4. Edit or create new markdown files
5. Configure `BASE_URL` to match TLS reverse proxy
6. Mount content dir as volume for persistence
7. Consider putting behind reverse proxy (Caddy/nginx/Traefik/GoDoxy 102)

## Data & config layout

- `content/pages/` — markdown content (configurable via `CONTENT_DIR`)
- `config/config.js` — optional file-based config (env overrides)
- No DB
- No attachments storage beyond what you embed in markdown

## Backup

```sh
# Just the content directory + config:
sudo tar czf raneto-$(date +%F).tgz content/pages/ config/
# Or put content dir in git for versioning:
cd content/pages && git init && git add -A && git commit -m "snapshot"
```

## Upgrade

1. Releases: <https://github.com/ryanlelek/Raneto/releases>. Active.
2. `git pull && npm install && npm start` OR pull Docker image if using Docker
3. Check CHANGELOG for config schema changes
4. **Content dir portability = upgrade-resilient** (no DB migrations)

## Gotchas

- **FILE-BASED CONTENT = GIT-NATIVE WORKFLOW**:
  - Put content dir in git = free history, rollback, diff, PR-review
  - CI can auto-deploy (git push → git pull on server)
  - **Recipe convention: "git-as-backup" extended** (LittleLink 103 precedent)
  - Now **2 tools in "git-as-backup" positive-signal**: LittleLink + Raneto
- **NO DATABASE = ZERO MIGRATION PAIN**:
  - Upgrades never break content
  - Content dir is portable across versions
  - **Recipe convention: "zero-lock-in" extended** — 4 tools now (Flatnotes + Basic Memory + Gramps + Raneto)
  - **Zero-lock-in pattern: 4 tools** — solidifying
- **WIKI-CATEGORY-OVERLAP-WITH-FLATNOTES-BASIC-MEMORY**:
  - **Flatnotes** (101) — single-user notes; simpler
  - **Basic Memory** (102) — MCP-enabled; LLM-aware
  - **Raneto** — team-knowledge-base; auth + editor
  - **Recipe convention: "markdown-file-based-knowledge-base tools" meta-family** — 3 tools now
  - **NEW meta-family: "markdown-file-based-knowledge-base"** — 3 tools: Flatnotes, Basic Memory, Raneto
- **SESSION_SECRET IMMUTABILITY**: **47th tool in immutability-of-secrets family.**
- **SIMPLE AUTH MODEL = SIMPLE ATTACK SURFACE**:
  - Single admin account; no RBAC; no multi-user authoring
  - Good for small teams where "admin" = a few trusted editors
  - Bad for larger teams needing per-editor attribution
- **PUBLIC-READ + AUTH-EDIT PATTERN**:
  - Classic pattern: anyone reads; only logged-in can edit
  - Good for customer-facing help docs
  - **Recipe convention: "public-read-auth-edit" pattern** — common; Gitea/Wiki.js/etc.
- **WEB EDITOR = XSS/MARKDOWN-RENDERING RISK**:
  - Markdown-to-HTML rendering can inject HTML/JS
  - Verify Raneto's markdown renderer strips/sanitizes
  - **Recipe convention: "markdown-XSS-sanitization" callout**
  - **NEW recipe convention** (Raneto 1st explicit)
- **GOOGLE ANALYTICS = TRACKING**:
  - Built-in GA4 integration
  - Visitor-tracking optional
  - **Recipe convention: "analytics-tool-GDPR-compliance" callout** applies (Tianji/Plausible precedents)
- **FOSSA LICENSE-COMPLIANCE BADGE**:
  - FOSSA automates license-scanning of dependencies
  - Unusual for OSS tools to surface this publicly
  - **Recipe convention: "FOSSA-license-compliance-badge" positive-signal** — indicates dependency-license-hygiene
  - **NEW positive-signal convention** (Raneto 1st named)
- **MAILING LIST FOR SECURITY ALERTS**:
  - Subscribe for CVE/security-alerts
  - **Recipe convention: "security-mailing-list" positive-signal**
  - **NEW positive-signal** — notable sign of maintainer-security-awareness
- **HUB-OF-CREDENTIALS TIER 3**:
  - Only admin login + content
  - Low PII; small attack surface
  - **73rd tool in hub-of-credentials family — Tier 3 (low density)**
- **INSTITUTIONAL-STEWARDSHIP**: Ryan Lelek sole + mailing-list + CI. **59th tool — sole-maintainer-with-community sub-tier (28th tool in sub-tier).**
- **TRANSPARENT-MAINTENANCE**: active + CI + FOSSA + releases + mailing-list + demo-site + docs. **67th tool in transparent-maintenance family.**
- **KB-CATEGORY (crowded):**
  - **Raneto** — Node.js; file-based; simple
  - **BookStack** — PHP; DB; books/chapters/pages hierarchy
  - **Wiki.js** — Node.js; rich; pluggable-auth
  - **Outline** — Node; DB; SSO; team-focused
  - **DocPad** (archived)
  - **MkDocs** (static) — Python; static-site generator
  - **GitBook** (commercial)
  - **Notion** (commercial SaaS)
  - **HedgeDoc** — collab markdown
  - **Flatnotes** (101) — single-user notes
  - **Basic Memory** (102) — LLM-aware
  - **Dokuwiki** — PHP; file-based; mature
  - **XWiki** — Java; enterprise
- **ALTERNATIVES WORTH KNOWING:**
  - **BookStack** — if you want books/chapters/pages + DB
  - **Wiki.js** — if you want feature-rich + pluggable-auth
  - **Outline** — if you want polished team + SSO
  - **Dokuwiki** — if you want mature PHP file-based
  - **Choose Raneto if:** you want Node.js + file-based + simple + markdown-only + light.
  - **Choose BookStack if:** you want DB + richer UI + hierarchy.
  - **Choose Wiki.js if:** you want Node.js + feature-richness + SSO.
- **PROJECT HEALTH**: active + CI + FOSSA + long-history + mailing-list. Good signals for a simple tool.

## Links

- Repo: <https://github.com/ryanlelek/Raneto>
- Homepage: <https://raneto.com>
- Docs/demo: <https://docs.raneto.com>
- BookStack (alt): <https://www.bookstackapp.com>
- Wiki.js (alt): <https://js.wiki>
- Outline (alt): <https://www.getoutline.com>
- Dokuwiki (alt PHP): <https://www.dokuwiki.org>
- Flatnotes (batch 101): <https://github.com/dullage/flatnotes>
- Basic Memory (batch 102): <https://github.com/basicmachines-co/basic-memory>
- FOSSA: <https://fossa.com>
