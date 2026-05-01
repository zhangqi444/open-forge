---
name: PdfDing
description: "Selfhosted PDF manager, viewer, and editor — seamless UX on multiple devices. Docker. Django+Python. mrmn2/PdfDing. pdfding.com + demo + docs. Minimal design."
---

# PdfDing

PdfDing is **"Shaarli-style 'ding' for PDFs — minimal manager + viewer + editor"** — a self-hosted PDF manager + viewer + editor. Seamless UX on multiple devices. Minimal, fast, easy-to-set-up Docker deployment. Django/Python.

Built + maintained by **mrmn2**. Docker Hub. Website + demo + docs at pdfding.com / demo.pdfding.com / docs.pdfding.com. **Naming lineage**: "PdfDing" = PDF + "Ding" (German for "thing"), following the tradition of LinkDing, ShaarliDing, etc.

Use cases: (a) **personal PDF library** (b) **PDF viewer in browser** (c) **PDF editor (annotate, etc.)** (d) **replacement for Calibre-for-PDFs** (e) **team-shared PDF archive** (f) **document-archive with search** (g) **mobile-friendly PDF access** (h) **ebooks-plus-PDFs archive**.

Features (per README):

- **PDF manager + viewer + editor**
- **Multi-device seamless UX**
- **Minimal + fast**
- **Easy Docker setup**
- **Django/Python**
- **Live demo + docs site**

- Upstream repo: <https://github.com/mrmn2/PdfDing>
- Website: <https://www.pdfding.com>
- Demo: <https://demo.pdfding.com>
- Docs: <https://docs.pdfding.com>
- Getting started: <https://docs.pdfding.com/getting_started/docker/>

## Architecture in one minute

- **Django** (Python)
- SQLite default
- **Resource**: low
- **Port**: HTTP

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker**         | `mrmn/pdfding`                                                                                                         | **Primary**                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `pdf.example.com`                                           | URL          | TLS                                                                                    |
| Admin                | Bootstrap                                                   | Auth         |                                                                                    |
| Storage              | PDFs                                                        | Storage      |                                                                                    |

## Install via Docker

Per docs.pdfding.com/getting_started/docker:
```yaml
services:
  pdfding:
    image: mrmn/pdfding:latest        # **pin**
    ports: ["8000:8000"]
    volumes:
      - ./pdfding-data:/home/nonroot/pdfding/media
      - ./pdfding-db:/home/nonroot/pdfding/db
    environment:
      - SECRET_KEY=...
      - CSRF_TRUSTED_ORIGINS=https://pdf.example.com
    restart: unless-stopped
```

## First boot

1. Set SECRET_KEY (random)
2. Set CSRF_TRUSTED_ORIGINS for your domain
3. Start
4. Create admin account
5. Upload a PDF; verify viewer
6. Test annotation/edit
7. Put behind TLS
8. Back up PDFs + DB

## Data & config layout

- `/media/` — uploaded PDFs
- `/db/` — SQLite DB (users, metadata, annotations)

## Backup

```sh
sudo tar czf pdfding-$(date +%F).tgz pdfding-data/ pdfding-db/
# Contents: your PDFs (often sensitive docs — contracts, tax returns, medical) — **ENCRYPT**
```

## Upgrade

1. Releases: <https://github.com/mrmn2/PdfDing/releases>
2. Docker pull + restart

## Gotchas

- **200th HUB-OF-CREDENTIALS CROWN-JEWEL TIER 1 — PERSONAL-PDF-ARCHIVE**:
  - 🎯🎯 **200-TOOL HUB-OF-CREDENTIALS MILESTONE at PdfDing** 🎯🎯 — major milestone
  - Holds: **uploaded PDFs** (frequently: tax returns, contracts, medical records, bank statements, legal docs, IDs), user accounts, annotations
  - PDFs often the most-sensitive-single-document-archive in someone's digital life
  - **200th tool in hub-of-credentials family — Tier 1 CROWN-JEWEL**
  - Matures sub-cat: **"PDF-document-archive + personal-documents-high-sensitivity": 1 tool** 🎯 **NEW CROWN-JEWEL Tier 1 sub-category** (PdfDing 1st — distinct from knowledge-base/Paperless-ngx which is OCR-focused)
  - **CROWN-JEWEL Tier 1: 68 tools / 61 sub-categories**
- **DJANGO-SECRET-KEY-REQUIRED**:
  - **SECRET_KEY-generation-randomness-rotation-mandatory** — reinforces Etebase (127), Bugsink (128)
- **CSRF-TRUSTED-ORIGINS**:
  - Django requires explicit list
  - **Recipe convention: "CSRF-TRUSTED-ORIGINS-explicit-list-discipline callout"**
  - **NEW recipe convention** (PdfDing 1st formally)
- **PDF-CONTENT-EXTREMELY-SENSITIVE**:
  - Tax/medical/legal docs
  - **Recipe convention: "personal-PDF-archive-HIGH-sensitivity-recognition callout"**
  - **NEW recipe convention** (PdfDing 1st formally)
- **NONROOT-CONTAINER-USER**:
  - Uses `/home/nonroot` path
  - **Recipe convention: "container-runs-as-nonroot-user positive-signal"**
  - **NEW positive-signal convention** (PdfDing 1st formally)
- **DING-NAMING-FAMILY**:
  - LinkDing, ShaarliDing, PdfDing, etc.
  - **Recipe convention: "Ding-naming-convention-LinkDing-family neutral-signal"**
  - **NEW neutral-signal convention** (PdfDing 1st formally)
  - **Ding-naming-family: 1 tool** 🎯 **NEW FAMILY** (PdfDing — anticipating Linkding arrival)
- **LIVE-DEMO**:
  - **Live-demo-with-public-credentials: 5 tools** 🎯 **5-MILESTONE** (+PdfDing; demo.pdfding.com)
- **INSTITUTIONAL-STEWARDSHIP**: mrmn2 sole-dev + website + demo + docs-site + Docker + CI + minimal-design ethos. **186th tool — sole-dev-minimal-design-tool sub-tier** (NEW-soft).
- **TRANSPARENT-MAINTENANCE**: active + demo + docs + CI + releases. **192nd tool in transparent-maintenance family.**
- **PDF-MANAGER-CATEGORY:**
  - **PdfDing** — minimal; manager+viewer+editor; Django
  - **Paperless-ngx** — OCR-heavy document archive
  - **Stirling PDF** — batch-PDF-tool-swiss-army
  - **Calibre** — e-books (PDFs too)
- **ALTERNATIVES WORTH KNOWING:**
  - **Paperless-ngx** — if you want OCR + structured archive
  - **Stirling PDF** — if you want batch-processing tools
  - **Choose PdfDing if:** you want simple + browser-viewer + archive without OCR overhead.
- **PROJECT HEALTH**: active + demo + docs + CI. Strong.

## Links

- Repo: <https://github.com/mrmn2/PdfDing>
- Website: <https://www.pdfding.com>
- Paperless-ngx (alt): <https://github.com/paperless-ngx/paperless-ngx>
- Stirling PDF (alt): <https://github.com/Frooodle/Stirling-PDF>
