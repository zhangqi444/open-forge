---
name: Papermerge
description: "Self-hosted document management system for scanned documents. OCR + full-text search + dual-panel browser + tags + hierarchy. PDF/TIFF/JPEG/PNG. Python/Django backend. License: check repo. Active. Meta-repo at ciur/papermerge; core at papermerge/papermerge-core."
---

# Papermerge

Papermerge is **"Mayan EDMS / Paperless-ngx — dual-panel + desktop-feel + long-term-archive-focused"** — an open-source document management system designed for scanned documents + digital archives. OCR extracts text from scans; full-text search + hierarchical folders + tags + dual-panel browser (file-manager-style). Supports PDF, TIFF, JPEG, PNG. Main use case: **long-term storage of digital archives**. Web-based (no exe; access via browser).

Built + maintained by **Eugen Ciur (ciur)** — founder + papermerge/papermerge-core team + community. License: check repo. Active; multi-repo architecture (meta + core + docs); Docker deployment; demo at demo.papermerge.com; YouTube channel; blog.

Use cases: (a) **paperless office** — scan paper docs + make searchable archive (b) **long-term digital archive** — tax records 7+ years, medical records, legal docs (c) **family document management** — birth certs, passports, property deeds (d) **small business document repo** — invoices, contracts, HR files (e) **receipt hoarding for taxes** — OCR makes everything searchable (f) **legacy-scan workflow** — high-volume scanning workflows with auto-import folder (g) **share documents with accountant/lawyer** — per-folder permissions (h) **bank-statement archive** — long-term retention for audits.

Features (per README):

- **Desktop-like web UI** (dual-panel)
- **OpenAPI REST** backend
- **OCR** for PDFs + images
- **Full-text search** after OCR
- **Hierarchical folders + tags**
- **Drag-and-drop**
- **Document preview**
- **PDF/TIFF/JPEG/PNG support**
- **Long-term archive focus**

- Meta-repo: <https://github.com/ciur/papermerge>
- Core: <https://github.com/papermerge/papermerge-core>
- Documentation: <https://github.com/papermerge/documentation>
- Docs: <https://docs.papermerge.io>
- Homepage: <https://papermerge.com>
- Demo: <https://demo.papermerge.com> (demo/demo)
- Blog: <https://papermerge.blog>
- YouTube: <https://www.youtube.com/@papermerge>
- Reddit: <https://www.reddit.com/r/Papermerge/>

## Architecture in one minute

- **Python + Django** — backend
- **React/Mantine** — frontend
- **PostgreSQL / SQLite** — DB
- **Redis** — task queue
- **Celery** — async OCR + import jobs
- **OCRmyPDF** — OCR engine (Tesseract-based)
- **Resource**: moderate-to-heavy — 1-2GB RAM; OCR is CPU-bound
- **Port**: web UI (configurable)

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker Compose** | **Upstream compose files in papermerge-core**                   | **Primary**                                                                        |
| Kubernetes         | Possible; less-documented                                        | DIY                                                                                   |
| Bare-metal Python  | Django-typical install                                                                    | DIY                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `docs.example.com`                                          | URL          | TLS MANDATORY                                                                                    |
| DB                   | PostgreSQL / SQLite                                         | DB           | Postgres recommended for production                                                                                    |
| Redis                | Task queue broker                                           | Queue        |                                                                                    |
| Storage dir          | Document storage (can be LARGE)                             | Storage      | TBs for heavy use                                                                                    |
| `SECRET_KEY`         | Django signing                                              | **CRITICAL** | **IMMUTABLE**                                                                                    |
| OCR languages        | Tesseract trainbands (eng, deu, fra, etc.)                                                                                 | Config       | Affects OCR quality per-language                                                                                    |
| Admin creds          | First-boot                                                                                 | Bootstrap    | Strong                                                                                    |
| IMAP (optional)      | Email-to-document import                                                                                                      | Integration  | Forward invoice emails to import                                                                                                            |

## Install via Docker

Follow upstream compose: <https://docs.papermerge.io>

```yaml
# High-level shape (verify with upstream):
services:
  papermerge:
    image: papermerge/papermerge:3.x        # **pin version — 3.x active**
    environment:
      DATABASE_TYPE: postgres
      DATABASE_URL: postgresql://papermerge:${DB_PASSWORD}@db:5432/papermerge
      REDIS_URL: redis://redis:6379/0
      SECRET_KEY: ${SECRET_KEY}
      DJANGO_SUPERUSER_USERNAME: admin
      DJANGO_SUPERUSER_PASSWORD: ${ADMIN_PASSWORD}
    volumes:
      - papermerge-data:/app/media
    ports: ["12000:80"]

  db:
    image: postgres:17
    environment:
      POSTGRES_DB: papermerge
      POSTGRES_USER: papermerge
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes: [pgdata:/var/lib/postgresql/data]

  redis:
    image: redis:7-alpine

volumes:
  papermerge-data: {}
  pgdata: {}
```

## First boot

1. Start stack → verify all services healthy
2. Browse web UI → log in as admin
3. Configure OCR languages
4. Create folder hierarchy (e.g., Taxes/2024, Medical, Contracts)
5. Upload first document → wait for OCR → verify search finds text
6. Configure IMAP ingestion (optional)
7. Set up auto-import folder mount (optional)
8. Enable 2FA on admin
9. Put behind TLS reverse proxy
10. Back up DB + media + config

## Data & config layout

- `/app/media/` — document storage (originals + OCR output)
- PostgreSQL — metadata + permissions + search index
- Redis — ephemeral task queue
- OCR-processed files vs originals — may be dual-stored

## Backup

```sh
docker compose exec db pg_dump -U papermerge papermerge > papermerge-$(date +%F).sql
sudo tar czf papermerge-media-$(date +%F).tgz papermerge-data/
```

## Upgrade

1. Releases: <https://github.com/papermerge/papermerge-core/releases>. Active.
2. Multi-repo architecture: check core + docs repos for compatibility notes
3. **Papermerge 3.x is current; 2.x → 3.x was a rewrite** — check migration guides carefully
4. Back up BEFORE any major-version upgrade
5. Docker: pull + restart; migrations auto-run

## Gotchas

- **LONG-TERM ARCHIVE FOCUS = DIFFERENT THREAT MODEL**:
  - Papermerge explicitly targets "long-term storage of digital archives"
  - Data-retention: 7-10+ years typical (tax records, legal docs)
  - **Backup + format-longevity matter more than feature-richness**
  - **Recipe convention: "long-term-archive-tool category"** — emphasize backup strategy + format preservation
  - **NEW category: "long-term-archive-tool"** (Papermerge 1st named)
- **PDF/TIFF LONGEVITY**:
  - PDF/A is the archival-PDF standard
  - Papermerge stores original formats — verify PDF/A conversion option
  - TIFF is good for archival
  - **Recipe convention: "archival-format-awareness" callout**
- **OCR = SEARCHABLE BUT NOT ALWAYS ACCURATE**:
  - OCR accuracy depends on scan quality, language, font
  - Handwriting = poor OCR
  - **Verify search results with manual spot-checks** especially for critical documents
- **DOCUMENT CONTENTS = HIGHLY SENSITIVE**:
  - Tax records: income, SSN, dependents
  - Medical: health info
  - Legal: contracts, personal data
  - Financial: bank statements, credit cards
  - **71st tool in hub-of-credentials family — Tier 1 or Tier 2** — document repository sensitivity matches CRM but with additional long-term-retention concern
  - **Consider Tier 1 if document-corpus includes highly-sensitive material** (medical, legal, financial in aggregation)
- **RETENTION + DELETION POLICIES**:
  - Archive tool = documents stay LONG time
  - GDPR right-to-erasure may conflict with tax-retention requirements
  - **Recipe convention: "retention-vs-erasure-conflict" callout** for archive tools
  - **NEW recipe convention**
- **HIPAA/HEALTHCARE USE**:
  - Storing medical records = HIPAA scope
  - BAA with any integrated services
  - Encryption at rest (verify Papermerge configuration)
  - Audit-log access
  - **HEALTHCARE-CROWN-JEWEL sub-family extended**: now 3 tools (SparkyFitness, Garmin-Grafana, Papermerge-for-medical)
  - **Sub-family 3 tools** — solidifying
- **OCR CPU-INTENSIVE**:
  - Heavy CPU load during ingestion
  - Worker pools + rate-limiting
  - Consider separate OCR worker host for large-volume users
- **SECRET_KEY IMMUTABILITY**: **46th tool in immutability-of-secrets family.**
- **META-REPO ARCHITECTURE** (unusual pattern):
  - `ciur/papermerge` = meta-repo for issues + tracking
  - `papermerge/papermerge-core` = actual code
  - `papermerge/documentation` = docs
  - **Recipe convention: "multi-repo-project with meta-tracker" pattern**
  - **NEW convention** — rare; example of project-growth-split
- **MULTI-REPO UPGRADE COORDINATION**:
  - When upgrading, ensure core + docs versions match
  - Check release notes in both repos
- **AUTO-IMPORT FOLDER**:
  - Filesystem-watch → auto-import scanned docs
  - Common pattern: scanner drops to shared folder; Papermerge picks up
  - Security: permissions on shared folder matter (readable only by scanner + Papermerge)
- **EMAIL-TO-IMPORT (IMAP)**:
  - Forward invoice emails → Papermerge ingests + OCRs
  - IMAP creds required — handle like other integration creds
- **DEMO ACCOUNT = demo/demo**:
  - For the HOSTED DEMO site (demo.papermerge.com)
  - Not for self-hosted production — don't carry weak creds over
- **TRANSPARENT-MAINTENANCE**: active + multi-repo + docs + demo + blog + YouTube + Reddit + multi-channel. **65th tool in transparent-maintenance family.**
- **INSTITUTIONAL-STEWARDSHIP**: Eugen Ciur + community. Multi-channel engagement (blog + YouTube + Reddit + Docker) signals serious project ownership. **57th tool — founder-with-multichannel-community sub-tier** (**NEW sub-tier** — distinct from sole-maintainer-with-community in that multi-channel engagement shows public-presence investment).
  - **NEW sub-tier: "founder-with-multichannel-community-engagement"** — 1st tool named (Papermerge)
- **DMS-CATEGORY (crowded):**
  - **Papermerge** — Python/Django; long-term-archive focus
  - **Paperless-ngx** — Python/Django; most-popular; active; fork of Paperless
  - **Mayan EDMS** — Python/Django; enterprise features; mature
  - **OpenKM** — Java; enterprise
  - **Teedy / Sismics Docs** — Java; clean UI
  - **Ascensio-System Nuxeo** — Java; enterprise
  - **EcoDMS** — commercial
  - **Alfresco Community** — Java; enterprise heritage
  - **DocuSeal** — contract-signing focus
- **ALTERNATIVES WORTH KNOWING:**
  - **Paperless-ngx** — most-popular Python DMS; active; similar shape to Papermerge
  - **Mayan EDMS** — more enterprise-features; heavier
  - **Teedy** — if you prefer Java + clean UI
  - **Choose Papermerge if:** you want dual-panel + long-term-archive-focus + multi-repo-architecture + Python.
  - **Choose Paperless-ngx if:** you want most-popular + larger community + Python.
  - **Choose Mayan EDMS if:** you want enterprise-grade.
- **PROJECT HEALTH**: active + multi-repo + multi-channel engagement + demo + docs + long-history. Strong signals.

## Links

- Meta: <https://github.com/ciur/papermerge>
- Core: <https://github.com/papermerge/papermerge-core>
- Docs: <https://docs.papermerge.io>
- Homepage: <https://papermerge.com>
- Demo: <https://demo.papermerge.com>
- Blog: <https://papermerge.blog>
- Paperless-ngx (alt popular): <https://github.com/paperless-ngx/paperless-ngx>
- Mayan EDMS (alt enterprise): <https://www.mayan-edms.com>
- Teedy (alt Java): <https://teedy.io>
- OCRmyPDF: <https://github.com/ocrmypdf/OCRmyPDF>
