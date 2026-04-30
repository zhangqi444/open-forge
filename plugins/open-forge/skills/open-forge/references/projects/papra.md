---
name: Papra
description: "Minimalist self-hosted document-management + archiving platform — upload/store/search/tag personal documents. Full-text search, OCR, email ingestion, folder ingestion, tagging rules, API/SDK/webhooks. TypeScript. AGPL-3.0."
---

# Papra

Papra is **"a personal digital archive for receipts, warranties, contracts, PDFs, and scanned paper"** — a minimalist self-hosted document management platform. Upload documents (or email-forward or folder-ingest), Papra OCR-extracts text, auto-tags based on rules, stores them, makes them full-text searchable with advanced filters. Designed for the "forget it and retrieve it when you need it" pattern rather than active document collaboration.

Built + maintained by **corentinth / papra-hq** (primarily solo core; growing contributor base). Docker image <200MB; runs on x86, ARM64, ARMv7. Active development; some features in-roadmap.

Features:

- **Upload / store / manage** documents
- **Organizations** — multi-user spaces for family/team/colleague shared archives
- **Full-text search** + advanced filters
- **Authentication** — user accounts
- **Tags** + auto-tagging via **tagging rules**
- **Email ingestion** — forward to a generated address; auto-import
- **Content extraction / OCR** — images + scanned PDFs made searchable
- **Folder ingestion** — drop files in a directory; auto-import
- **CLI** — manage from command line
- **API + SDK + webhooks** — build on top
- **i18n** — multi-language
- **Custom properties** per organization
- **Dark mode**
- **Responsive** — desktop + mobile

Roadmap (per upstream): sharing, document requests (upload links for others), mobile app, desktop app, browser extension, AI tagging.

- Upstream repo: <https://github.com/papra-hq/papra>
- Homepage: <https://papra.app>
- Demo (client-only): <https://demo.papra.app>
- Docs: <https://docs.papra.app>
- Self-hosting guide: <https://docs.papra.app/self-hosting/using-docker>
- Roadmap: <https://github.com/orgs/papra-hq/projects/2>
- Discord: <https://papra.app/discord>
- Sponsor: <https://github.com/sponsors/corentinth> / <https://buymeacoffee.com/cthmsst>

## Architecture in one minute

- **TypeScript** / SolidStart frontend + Hono backend (monorepo)
- **SQLite** database (default) — simple, embedded; alternative databases may be available per recent versions
- **File storage**: local filesystem or S3-compatible
- **OCR**: Tesseract-based (or similar embedded engine)
- **Docker image** ~200MB; small resource footprint

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Single VM          | **Docker** (official image)                                        | **Upstream-primary**                                                               |
| Bare-metal Node    | Monorepo build                                                             | Possible; Docker strongly preferred                                                        |
| Raspberry Pi       | ARM64 + ARMv7 images                                                                | First-class ARM support                                                                                |
| Kubernetes         | Standard Docker deploy                                                                               | Works                                                                                                                |

## Inputs to collect

| Input                    | Example                                                   | Phase        | Notes                                                                    |
| ------------------------ | --------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain                   | `papra.example.com`                                             | URL          | TLS reverse proxy                                                                                  |
| Storage                  | local path (`/data`) OR S3                                               | Storage      | Local simplest; S3 for scale                                                                    |
| Email ingestion (opt)    | SMTP inbound OR IMAP poll                                                       | Ingress      | Requires email infrastructure — see Gotchas                                                                  |
| OIDC (opt)               | per upstream docs                                                                     | Auth         | If wanted; check config                                                                                           |
| Session secret           | random 32+ chars                                                                              | Secret       | Immutability: rotating invalidates sessions                                                                                                  |
| Folder ingestion path    | `/ingest` watched directory                                                                                  | Ingress      | Drop files → auto-imported                                                                                                                  |

## Install via Docker

Per <https://docs.papra.app/self-hosting/using-docker>:
```yaml
services:
  papra:
    image: ghcr.io/papra-hq/papra:0.x                # pin version
    restart: unless-stopped
    ports: ["1221:1221"]
    volumes:
      - ./papra-data:/app/app-data
    environment:
      AUTH_SECRET: ${SESSION_SECRET}
      BASE_URL: https://papra.example.com
      # OCR / email / storage config per docs
```

## First boot

1. Start container; browse URL; create admin account
2. Create your first organization
3. Upload a test document → verify OCR extracts text → verify search finds it
4. Configure tagging rules based on recurring document types (receipts vs warranties vs bills)
5. (opt) Set up email ingestion — forward documents to generated address
6. (opt) Set up folder ingestion — scanner auto-drops to watched dir
7. Put behind TLS
8. Back up `/app/app-data` volume

## Data & config layout

- `/app/app-data/` — SQLite DB + uploaded files + OCR cache
- Config via env vars
- Logs to stdout (container)

## Backup

```sh
# Simple: tar the volume (stop container first for consistency, or use SQLite online backup)
docker compose stop papra
sudo tar czf papra-$(date +%F).tgz papra-data/
docker compose start papra
```

For S3 storage, sync the bucket + DB separately.

## Upgrade

1. Releases: <https://github.com/papra-hq/papra/releases>. Active.
2. Docker: bump tag; restart. Migrations run on boot.
3. **Back up before major version bumps.**
4. Pre-stable phase — read changelog. Breaking changes possible until stable.

## Gotchas

- **"Archival" mindset, not active collaboration.** Papra is built for the "store + forget + retrieve" pattern — personal archive of receipts/warranties/docs. NOT a live collaboration tool like Paperless-ngx (which has strong consumer mindshare) or Nextcloud. Match your use case.
- **Paperless-ngx comparison**: Paperless-ngx is the incumbent self-hosted document archive — older, larger community, mature OCR pipeline, more features. Papra is newer, slimmer Docker image, simpler UX, more-modern stack (TypeScript vs Python/Django). If you want battle-tested + rich features → Paperless-ngx. If you want minimalist + clean + evolving → Papra.
- **Active development = pre-stable.** Upstream explicitly says "core functionalities are stable and usable" but breaking changes may still occur. Pin versions; read changelogs; back up before upgrade.
- **OCR accuracy** depends on document quality. Low-res phone photos of receipts = mixed results. Fixes: (a) better scans (b) post-OCR manual edits (c) use a dedicated scanner.
- **Email ingestion requires email infrastructure.** You need an MX record + inbound mail path — either SMTP inbound OR IMAP polling. Self-hosting email is hard (per AnonAddy batch 79). Easiest: (a) use a forwarding-only domain at a provider with IMAP (b) pair with AnonAddy (c) use Papra's managed variant if offered.
- **Folder ingestion pattern**: Papra watches a directory; dropping files there = import. Great for **network scanners** that can write to a share. Combine with Samba/NFS for "scanner → network share → Papra" pipeline.
- **Full-text search over OCR'd text** means search quality = OCR quality. Verify on your doc corpus.
- **SQLite single-user considerations**: Papra's default SQLite is fine for personal/family archives. For team archives with heavy concurrent writes, consider alternatives.
- **Backup encryption matters**: personal archives contain sensitive info (SSN in tax docs, medical records, legal contracts). Encrypt backups + store off-site. Classic privacy-of-backups concern (family-timeline class from batch 79 AnonAddy).
- **"Tagging rules" are DIY-automation**: Papra provides rule engine; you define patterns. Think "if sender contains 'amazon.com' → tag 'shopping'". Power increases with investment.
- **Custom properties per organization** — define per-org fields (e.g., receipt → amount, vendor, date). Structured metadata alongside free-text tags.
- **AGPL-3.0 license** — standard network-service copyleft. Self-host privately or disclose source if running a commercial service. Same class as AnonAddy (batch 79), MiroTalk (batch 80), WriteFreely (batch 74).
- **Bus-factor-1 mitigation**: corentinth is solo core. Mitigations: (a) AGPL open-source (b) growing contributor base (c) simple TypeScript stack (re-buildable by many) (d) standard Docker deploy (easy to run on alternative forks). Still: don't depend on a single-dev project for mission-critical workflows without a Plan B.
- **Sponsor / contact-for-sponsorship**: if Papra is valuable to your org, sponsor corentinth or inquire about corporate sponsorship. Consistent with managed-tier-funds-upstream pattern.
- **Document requests feature (coming)** — upload links for others to add docs. Useful for tax prep / shared ops. Until shipped, workaround: shared org + guest users.
- **Exit strategy**: documents are files on disk + SQLite DB → trivially exportable. Low lock-in. Plus: CLI for bulk ops.
- **Alternatives worth knowing:**
  - **Paperless-ngx** — the incumbent; Python/Django; larger community; mature
  - **Mayan EDMS** — heavier enterprise DMS; workflow engine
  - **Docspell** — Scala-based; opinionated + powerful
  - **Teedy** — Java-based document manager
  - **Nextcloud + Tesseract app** — if already running Nextcloud
  - **DEVONthink** (macOS commercial) — gold-standard proprietary
  - **Choose Papra if:** minimalist TypeScript stack + simple Docker + active development.
  - **Choose Paperless-ngx if:** want mature community + proven OCR pipeline + richer features today.
  - **Choose Docspell if:** want more advanced features + don't mind JVM.

## Links

- Repo: <https://github.com/papra-hq/papra>
- Homepage: <https://papra.app>
- Docs: <https://docs.papra.app>
- Self-hosting: <https://docs.papra.app/self-hosting/using-docker>
- Demo: <https://demo.papra.app>
- Roadmap: <https://github.com/orgs/papra-hq/projects/2>
- Discord: <https://papra.app/discord>
- Releases: <https://github.com/papra-hq/papra/releases>
- Sponsor (GH): <https://github.com/sponsors/corentinth>
- Sponsor (BMC): <https://buymeacoffee.com/cthmsst>
- Paperless-ngx (alt): <https://github.com/paperless-ngx/paperless-ngx>
- Docspell (alt): <https://github.com/eikek/docspell>
- Mayan EDMS (alt): <https://www.mayan-edms.com>
