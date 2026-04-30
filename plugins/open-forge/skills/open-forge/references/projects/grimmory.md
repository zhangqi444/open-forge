---
name: Grimmory
description: "Self-hosted digital library (PDF/EPUB/comics/audiobooks). Community fork of Booklore. Smart shelves + metadata from Google Books/Open Library/Amazon + in-browser reader + Kobo/KOReader sync + OIDC. Check license. Active; Discord community."
---

# Grimmory

Grimmory is **"Calibre-web / Booklore / Kavita / Komga — but Booklore-community-fork + BookDrop + Kobo-sync + OIDC"** — a self-hosted digital library for PDFs, EPUBs, comics, and audiobooks. **Independent community fork of Booklore**. Smart Shelves (rule-based + tags + full-text search); metadata from Google Books + Open Library + Amazon; built-in browser-reader with annotations + highlights + progress; **Kobo sync** + OPDS + KOReader progress sync; multi-user + **OIDC auth**; **BookDrop** (watched folder auto-imports); one-click send-to-Kindle / email / another user.

Built + maintained by **grimmory-tools organization** (community of ex-Booklore users/devs). License: check LICENSE file. Active; Docker Hub (grimmory/grimmory); Discord community; docs at grimmory.org; QUICKSTART guide.

Use cases: (a) **ebook library for family** — share books + separate progress per user (b) **replace Amazon Kindle library** — store DRM-free books + read in browser / Kindle (c) **comics collection** — browse + read comics with progress tracking (d) **Kobo-owner self-hosting** — Kobo-sync is native (e) **audiobook + ebook in one library** — unified metadata (f) **dropped-folder ingestion** — drop files; Grimmory detects + enriches + imports (g) **Booklore alternative** — for those preferring community-steered fork (h) **OPDS-app compatibility** — use any OPDS reader.

Features (per README):

- **Smart Shelves** — rule-based filtering
- **Metadata lookup** — Google Books, Open Library, Amazon
- **Built-in reader** — PDF, EPUB, comics
- **Device Sync** — Kobo, OPDS, KOReader
- **Multi-user** with OIDC
- **BookDrop** — watched folder auto-import
- **One-click sharing** — Kindle / email / user
- **Formats** — PDF, EPUB, CBZ/CBR, audiobooks (detail in docs)

- Upstream repo: <https://github.com/grimmory-tools/grimmory>
- Website: <https://grimmory.org>
- Docs: <https://grimmory.org/docs>
- QUICKSTART: <https://github.com/grimmory-tools/grimmory/blob/main/docs/QUICKSTART.md>
- Docker Hub: <https://hub.docker.com/r/grimmory/grimmory>
- Discord: <https://discord.gg/9YJ7HB4n8T>
- Parent (Booklore): <https://github.com/adityachandelgit/BookLoreApp>

## Architecture in one minute

- **Java/Spring Boot** (inherited from Booklore)
- **Angular** frontend
- **PostgreSQL** — DB
- **Resource**: moderate — 1-1.5GB RAM
- **Port**: web UI

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker Compose** | **Upstream `grimmory/grimmory`**                                | **Primary**                                                                        |
| Source             | Java + Node build                                                                    | Dev                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `books.example.com`                                         | URL          | TLS recommended                                                                                    |
| DB                   | PostgreSQL                                                  | DB           |                                                                                    |
| Admin creds          | First-boot                                                  | Bootstrap    | Strong                                                                                    |
| BookDrop watched dir | Host mount for auto-import                                  | Storage      |                                                                                    |
| Library path         | Where books live                                            | Storage      | Can be LARGE                                                                                    |
| Google Books / OpenLibrary API (opt) | For metadata                                                                                | Integration  |                                                                                    |
| OIDC (opt)           | Provider details                                                                                                      | Auth         | For SSO                                                                                                            |
| SMTP (opt)           | Send-to-email / send-to-Kindle                                                                                                            | Email        |                                                                                                                                            |

## Install via Docker

Follow: <https://grimmory.org/docs>

```yaml
services:
  grimmory:
    image: grimmory/grimmory:latest        # **pin version**
    environment:
      DATABASE_URL: postgresql://grimmory:${DB_PASSWORD}@db:5432/grimmory
      # additional env per upstream QUICKSTART
    volumes:
      - ./books:/books
      - ./bookdrop:/bookdrop
      - grimmory-data:/data
    ports: ["8080:8080"]
    depends_on: [db]

  db:
    image: postgres:17
    environment:
      POSTGRES_DB: grimmory
      POSTGRES_USER: grimmory
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes: [pgdata:/var/lib/postgresql/data]

volumes:
  grimmory-data: {}
  pgdata: {}
```

## First boot

1. Start stack → browse web UI
2. Complete first-boot wizard (admin user)
3. Configure library path
4. Add Google Books/Open Library metadata-provider keys (if needed)
5. Test-drop a book into BookDrop folder → verify auto-import
6. Configure OIDC provider (optional)
7. Invite family users
8. Configure Kobo sync (if Kobo-owner)
9. Test read-in-browser
10. Back up DB + config

## Data & config layout

- Library dir — actual book files
- BookDrop dir — watched for auto-import
- `/data/` — app data + metadata cache + covers
- Postgres DB — library metadata, users, progress, annotations

## Backup

```sh
docker compose exec db pg_dump -U grimmory grimmory > grimmory-$(date +%F).sql
# Books typically not backed up (re-importable from source if preserved)
# But annotations, progress, highlights ARE in DB — BACK UP
sudo tar czf grimmory-data-$(date +%F).tgz grimmory-data/
```

## Upgrade

1. Releases: <https://github.com/grimmory-tools/grimmory/releases>. Active.
2. Docker pull + restart; DB migrations auto-run
3. **Fresh-fork**: watch for divergence from Booklore; check CHANGELOG

## Gotchas

- **COMMUNITY-FORK-OF-ACTIVE-PROJECT PATTERN EXTENDED**:
  - Independent community fork of Booklore
  - **2nd tool in "community-fork-of-active-project" sub-tier** (Stoat 101 was 1st)
  - **Sub-tier now 2 tools** — solidifying
  - Recipe convention: "community-fork-of-active-project" — fork was likely for governance/direction-disagreement; both tools may live in parallel
  - **Fork motivation**: per Grimmory org-name "grimmory-tools" suggests independent-stewardship vs individual-dev
- **EBOOK METADATA FROM THIRD PARTIES**:
  - Google Books, Open Library, Amazon
  - Amazon scraping may violate TOS
  - **Recipe convention: "metadata-scraping-TOS-risk" callout**
  - **NEW recipe convention** (Grimmory 1st for ebooks)
- **COPYRIGHT MATERIAL IN LIBRARY**:
  - Users may upload copyrighted books they don't own
  - Host liability in some jurisdictions (DMCA, EU rules)
  - If publicly-accessible → much higher risk
  - **Recipe convention: "copyrighted-content-hosting-risk" callout** — applies to all ebook/media servers
  - **NEW recipe convention** (formalized at Grimmory)
- **DRM + ENCRYPTED EBOOKS**:
  - Kindle DRM, Adobe DRM, Kobo DRM
  - Grimmory can only serve unencrypted files
  - **Recipe convention: "DRM-content-incompatibility" callout** for ebook tools
- **KOBO SYNC = DEEP INTEGRATION**:
  - Kobo devices sync natively with Grimmory
  - Kobo-sync reverse-engineered; Kobo could change protocol → break
  - **Recipe convention: "vendor-reverse-engineered-sync-protocol-risk" callout**
  - **NEW recipe convention**
- **KINDLE SEND-TO-EMAIL**:
  - Amazon's "send to Kindle" via approved-email
  - Requires SMTP setup
  - Amazon may rate-limit / reject
- **BOOKDROP AUTO-IMPORT**:
  - Watched folder = anyone with write-access can add books
  - If multi-user mount → permissions matter
  - **Recipe convention: "watched-folder-write-permission-discipline" callout**
- **HUB-OF-CREDENTIALS TIER 2**:
  - User accounts + progress + annotations + highlights (personal reading data)
  - OIDC provider trust
  - Google Books / Amazon API keys
  - SMTP creds (for send-to-email)
  - Annotations are PERSONAL DATA — reveal reading interests + private thoughts
  - **78th tool in hub-of-credentials family — Tier 2**
  - **Sub-family: "reading-data-personal-history-risk"** — NEW sub-family
  - **NEW sub-family: "reading-data-personal-history-risk"** — 1st tool named (Grimmory)
- **READING ANNOTATIONS = PRIVATE THOUGHTS**:
  - Highlights + notes + bookmarks = intimate personal data
  - Like journaling/diary tools: memos mayrisk reflect emotions, private interests, political views
  - **Recipe convention: "reading-annotations-intimate-personal-data" callout**
- **INSTITUTIONAL-STEWARDSHIP**: grimmory-tools org (community-fork governance) + Discord-community. **64th tool — community-fork-of-active-project sub-tier (2nd tool).**
- **TRANSPARENT-MAINTENANCE**: active + Discord + Docker-pulls + releases + docs + QUICKSTART + fork-history. **72nd tool in transparent-maintenance family.**
- **FORK-PARENT COMPARISON**:
  - **Booklore** (parent) — continues independently
  - **Grimmory** (fork) — may add features / different priorities
  - Check both repos if feature-matrix matters to you
- **EBOOK-MANAGER-CATEGORY (crowded):**
  - **Grimmory** — Booklore-fork; multi-format; OIDC; BookDrop; Kobo
  - **Booklore** (parent) — if you prefer original
  - **Calibre-web** — PHP web UI over Calibre DB; mature
  - **Kavita** — C#; comics + books + mobile-friendly
  - **Komga** — Java; comics + mangas focus
  - **BookStack** (NOT ebook; wiki-style)
  - **LazyLibrarian** — ebook-PVR (Sonarr-equivalent)
  - **Audiobookshelf** — audiobook focus; separate project
- **ALTERNATIVES WORTH KNOWING:**
  - **Booklore** — the parent; choose if you want upstream-community
  - **Calibre-web** — if you want mature + Python + Calibre-DB-compat
  - **Kavita** — if you want comics + mangas + mobile
  - **Komga** — if you want manga-centric
  - **Audiobookshelf** — if audiobook-first
  - **Choose Grimmory if:** you want Booklore-fork + Kobo-sync + BookDrop + OIDC.
- **PROJECT HEALTH**: active + Discord + Docker + fork-stewardship. Signals developing; fork-risk if forks-don't-stick.

## Links

- Repo: <https://github.com/grimmory-tools/grimmory>
- Website/docs: <https://grimmory.org>
- Booklore (parent): <https://github.com/adityachandelgit/BookLoreApp>
- Calibre-web (alt): <https://github.com/janeczku/calibre-web>
- Kavita (alt comics): <https://www.kavitareader.com>
- Komga (alt comics): <https://komga.org>
- Audiobookshelf (alt audio): <https://www.audiobookshelf.org>
- LazyLibrarian (alt PVR): <https://gitlab.com/LazyLibrarian/LazyLibrarian>
