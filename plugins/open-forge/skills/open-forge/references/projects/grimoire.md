---
name: Grimoire
description: "Bookmark manager for the wizards. SvelteKit. Multi-user + fuzzy search + tags + categories + metadata extraction + personal notes + browser extension. v0.4 migration caveat from v0.3.X. Active; Goniszewski sole maintainer."
---

# Grimoire

Grimoire is **"Linkwarden / Shaarli / Shiori — but SvelteKit + wizard-themed + polished UI"** — a bookmark manager with a playful magical aesthetic. Multi-user bookmark management + fuzzy search + tags + categories + auto-metadata-extraction (fetches + stores + refreshes page metadata) + personal notes per bookmark + dark mode + integration API + official browser extension (`grimoire companion`).

Built + maintained by **Robert Goniszewski (goniszewski)**. License: check LICENSE file (MIT-adjacent typical). Active; GitHub Actions CI + releases; Docker Hub; grimoire.pro domain; **v0.4 introduced a breaking storage + auth change from v0.3.X with a built-in migration tool**.

Use cases: (a) **personal bookmarks repository** — replace browser-bookmark-bar with searchable/tagged (b) **multi-user family bookmark-share** — each user their own collection (c) **research archive** — fetch-metadata-at-save = link-rot mitigation (d) **reading-list workflow** — track unread vs read; personal notes (e) **import from browser** — via API or extension (f) **replace Pinboard (paid)** — equivalent self-hosted (g) **replace Pocket** — Mozilla-deprecated Pocket recently (h) **creative/research curator** — tag + categorize + annotate.

Features (per README):

- **Multi-user** accounts with own bookmarks/tags/categories
- **Fuzzy search**
- **Tags + categories**
- **Metadata extraction** — fetch + store + refresh
- **Personal notes** per bookmark
- **Integration API** — add bookmarks from other sources
- **Dark mode**
- **Browser extension** (grimoire companion)

- Upstream repo: <https://github.com/goniszewski/grimoire>
- Website/docs: <https://grimoire.pro>
- Browser extension: <https://github.com/goniszewski/grimoire-web-extension>
- Migration tool docs (v0.3 → v0.4): <https://grimoire.pro/docs/migration-tool/>

## Architecture in one minute

- **SvelteKit** (Node.js-based)
- **Local file storage** (v0.4+); previously PocketBase (v0.3.X)
- **Resource**: low — 150-300MB RAM
- **Port 5173** default

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker Compose** | **Upstream images**                                             | **Primary**                                                                        |
| Source             | `pnpm / npm` dev build                                                                    |                                                                                    |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `bookmarks.example.com`                                     | URL          | TLS recommended                                                                                    |
| Data volume          | For storage path                                            | Storage      |                                                                                    |
| Admin creds          | First-boot                                                  | Bootstrap    | Strong                                                                                    |
| `PUBLIC_ORIGIN`      | Your URL                                                    | Config       |                                                                                    |
| SMTP (opt)           | For emails                                                                                 | Email        |                                                                                    |

## Install via Docker Compose

Follow: <https://grimoire.pro/docs/installation/>

```yaml
services:
  grimoire:
    image: goniszewski/grimoire:latest        # **pin version**
    environment:
      PUBLIC_ORIGIN: https://bookmarks.example.com
    volumes:
      - grimoire-data:/app/data
    ports: ["5173:5173"]

volumes:
  grimoire-data: {}
```

## First boot

1. Start → browse `:5173`
2. Create first account (admin)
3. Install browser extension → link to Grimoire
4. Create tags + categories structure
5. Save first bookmark → verify metadata fetched
6. Put behind TLS reverse proxy
7. Back up data volume

## Data & config layout

- `/app/data/` — DB + metadata + assets
- Browser extension stores API key locally on each browser

## Backup

```sh
sudo tar czf grimoire-$(date +%F).tgz grimoire-data/
```

## Upgrade

1. Releases: <https://github.com/goniszewski/grimoire/releases>. Active.
2. **If on v0.3.X — READ MIGRATION DOCS before pulling v0.4+**: storage + auth model changed
3. Use built-in migration tool: <https://grimoire.pro/docs/migration-tool/>
4. Back up BEFORE migration

## Gotchas

- **MAJOR-VERSION STORAGE-MIGRATION (v0.3 → v0.4)**:
  - README banner explicitly warns
  - Storage + auth model changed
  - Built-in migration tool provided
  - **Recipe convention: "major-version-breaking-migration with migration-tool" sub-convention**
  - **NEW recipe convention** (Grimoire 1st named)
  - **Recipe convention reinforced: "breaking-change-transparency"** (positive signal — maintainer announced prominently)
- **ZERO-v1.0 CAVEAT**:
  - Grimoire is still pre-1.0 (v0.4 currently)
  - Pre-1.0 projects may have more-frequent breaking changes
  - **Recipe convention: "pre-1.0-project-breaking-change-risk" callout**
  - **NEW recipe convention**
- **BOOKMARK CONTENTS = PERSONAL-BROWSING-PATTERN PII**:
  - What you bookmark = what interests you (politics, health, relationships)
  - Tags + categories + notes reveal thought-patterns + priorities
  - **82nd tool in hub-of-credentials family — Tier 2**
  - **Sub-family: "reading-browsing-personal-history-risk"** — extends Grimmory 105's "reading-data-personal-history-risk"
  - **Consolidated sub-family: "reading/browsing-data-personal-history-risk"** — 2 tools (Grimmory + Grimoire)
  - **Sub-family now 2 tools** — solidifying
- **METADATA-FETCH = SSRF SURFACE**:
  - Grimoire fetches arbitrary URLs users submit
  - Attacker submits internal URL (http://localhost, metadata-service IPs) → Grimoire fetches → SSRF
  - **Recipe convention: "URL-fetcher-SSRF-mitigation" callout** — ensure Grimoire validates/blocklists internal IPs
  - **NEW recipe convention** (Grimoire 1st explicit; Linkwarden-equivalent)
- **URL-FETCH + PERIODIC REFRESH**:
  - Grimoire re-fetches metadata periodically
  - Heavy load if many users have many bookmarks
  - **Recipe convention: "periodic-refetch-load-budget" callout**
- **BROWSER EXTENSION API KEY = ACCOUNT ACCESS**:
  - Extension stores API key locally
  - If browser compromised → API key exfiltrable
  - **Recipe convention: "browser-extension-token-local-storage-risk" callout**
  - **NEW recipe convention**
- **INTEGRATION API = OPEN SURFACE**:
  - API to add bookmarks from other sources (Zapier, automation)
  - Another credential with write-access
- **MAGICAL-WHIMSICAL BRANDING**:
  - "Wizards", "magical", "transmute", "enchanted"
  - Playful branding may signal hobbyist project (not corporate)
  - Can be positive (authenticity) or negative (under-invested seriousness)
  - **Neutral signal — read maintenance + tests instead**
- **INSTITUTIONAL-STEWARDSHIP**: goniszewski sole. **68th tool — sole-maintainer-with-community sub-tier (32nd).**
- **TRANSPARENT-MAINTENANCE**: active + CI + releases + Docker + migration-tool + grimoire.pro-domain + browser-extension-separate-repo. **76th tool in transparent-maintenance family.**
- **BOOKMARK-MANAGER-CATEGORY (crowded):**
  - **Grimoire** — SvelteKit; wizard-themed
  - **Linkwarden** — Next.js; archival-focus
  - **Shaarli** — PHP; oldest
  - **Shiori** — Go; lightweight
  - **Raindrop.io** (commercial)
  - **Pinboard** (commercial)
  - **Hoarder** — Next.js; AI-tagging
  - **LinkAce** (batch 95) — PHP; mature
  - **Booky** — newer
- **ALTERNATIVES WORTH KNOWING:**
  - **Linkwarden** — if you want Next.js + archival screenshot + mature
  - **Shiori** — if you want Go + lightweight
  - **Hoarder** — if you want AI-auto-tagging
  - **LinkAce** (batch 95) — if you want PHP + mature
  - **Choose Grimoire if:** you want SvelteKit + playful-branding + browser-extension + fuzzy-search.
- **PROJECT HEALTH**: active + v0.4 with migration + CI + browser-extension. Signals active development despite pre-1.0.

## Links

- Repo: <https://github.com/goniszewski/grimoire>
- Docs: <https://grimoire.pro>
- Linkwarden (alt): <https://linkwarden.app>
- Shiori (alt): <https://github.com/go-shiori/shiori>
- Shaarli (alt): <https://shaarli.readthedocs.io>
- Hoarder (alt AI): <https://github.com/hoarder-app/hoarder>
- LinkAce (batch 95): <https://github.com/Kovah/LinkAce>
