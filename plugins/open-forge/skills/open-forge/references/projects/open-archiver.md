---
name: Open Archiver
description: "Self-hosted platform for email archiving from Google Workspace, Microsoft 365, PST files, generic IMAP. Tamper-proof record. Full-text search. PostgreSQL + Meilisearch + Redis + SvelteKit + TypeScript. LogicLabs-OU. Live demo. Discord + Bluesky."
---

# Open Archiver

Open Archiver is **"self-hosted Mimecast / Barracuda Email Archiver — but open-source + sovereign + no vendor lock-in"** — a platform for archiving, storing, indexing, and searching emails from **Google Workspace (Gmail), Microsoft 365, PST files, and generic IMAP mailboxes**. Tamper-proof record; full-text search across emails + attachments.

Built + maintained by **LogicLabs-OU** org. Live demo at demo.openarchiver.com. Discord + Bluesky community.

Use cases: (a) **regulatory email-archiving** (financial services, healthcare) (b) **tamper-proof litigation hold** (c) **eDiscovery-ready archive** (d) **departed-employee mailbox archive** (e) **long-term email retention** (f) **PST-file ingestion from legacy systems** (g) **cross-platform unified archive** (Gmail+O365) (h) **sovereign archive outside vendor lock-in**.

Features (per README):

- **Google Workspace (Gmail) ingest**
- **Microsoft 365 ingest**
- **PST file ingest**
- **Generic IMAP ingest**
- **PostgreSQL** for metadata
- **Meilisearch** full-text search
- **Redis** cache
- **SvelteKit + TypeScript** frontend
- **Docker Compose** deploy

- Upstream repo: <https://github.com/LogicLabs-OU/OpenArchiver>
- Demo: <https://demo.openarchiver.com> (user: `demo@openarchiver.com` / pw: `openarchiver_demo`)
- Discord: <https://discord.gg/MTtD7BhuTQ>
- Bluesky: <https://bsky.app/profile/openarchiver.bsky.social>

## Architecture in one minute

- **SvelteKit + TypeScript** frontend
- **PostgreSQL** — archive metadata + users
- **Meilisearch** — full-text search
- **Redis** — cache + queues
- **Object-storage / filesystem** — raw .eml blobs
- **Resource**: can grow to TBs for email archive
- Multi-service stack

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker Compose** | Primary                                                                                                                | Upstream                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `archive.example.com`                                       | URL          | TLS                                                                                    |
| Google OAuth         | Workspace admin delegation                                  | Integration  | **Domain-wide delegation needed**                                                                                    |
| M365 OAuth           | Graph API app                                               | Integration  |                                                                                    |
| IMAP creds           | Per-mailbox                                                 | Integration  |                                                                                    |
| Storage backend      | Filesystem / S3 / MinIO                                     | Storage      | **Huge data**                                                                                    |
| PostgreSQL           | Data                                                        | DB           |                                                                                    |
| Meilisearch key      | API key                                                     | Search       |                                                                                    |
| Redis                | Cache                                                       | Infra        |                                                                                    |

## Install via Docker Compose

See README + <https://github.com/LogicLabs-OU/OpenArchiver>. Typical:
```yaml
services:
  postgres:
    image: postgres:15
  meilisearch:
    image: getmeili/meilisearch:v1.X        # **pin**
  redis:
    image: redis:7
  openarchiver:
    image: logiclabs/open-archiver:latest        # **pin**
    depends_on: [postgres, meilisearch, redis]
    volumes:
      - ./archive-data:/data
    environment:
      - DATABASE_URL=...
      - MEILI_KEY=${MEILI_KEY}
```

## First boot

1. Deploy stack
2. Create admin
3. Configure Google Workspace domain-delegation
4. Or configure M365 Graph app
5. Or upload PST files
6. Let ingest run (can take days for large orgs)
7. Configure retention policy
8. Put behind TLS
9. Back up PostgreSQL + archive blobs + Meilisearch indexes

## Data & config layout

- PostgreSQL — metadata
- Archive blob storage — .eml files (huge!)
- Meilisearch — search indexes

## Backup

```sh
pg_dump openarchiver > openarchiver-$(date +%F).sql
# Plus archive-blob storage (TBs)
# Meilisearch can be rebuilt from archive blobs
# **ENCRYPT — contains ALL emails**
```

## Upgrade

1. Releases: <https://github.com/LogicLabs-OU/OpenArchiver/releases>
2. DB migrations
3. Docker pull + restart

## Gotchas

- **160th HUB-OF-CREDENTIALS CROWN-JEWEL TIER 1 — EVERY-EMAIL-EVER-SENT**:
  - Holds: **ALL archived emails from ALL archived users** — executive comms, HR discussions, legal, IP, customer data
  - **Highest-sensitivity hub-of-credentials in the catalog** — on par with PII-core (gitea-clone) and secret-manager (vaultwarden)
  - Google Workspace service-account with domain-wide delegation = **God-mode on Workspace**
  - M365 Graph app = **similar scope on M365**
  - **160-TOOL HUB-OF-CREDENTIALS MILESTONE at Open Archiver**
  - **NEW CROWN-JEWEL Tier 1 sub-category: "email-archive-aggregator + workspace-domain-delegation"** (1st — Open Archiver; HIGHEST-severity — full workspace-read access)
  - **CROWN-JEWEL Tier 1: 54 tools / 49 sub-categories**
- **DOMAIN-WIDE-DELEGATION RISK**:
  - Google Workspace service-account with domain-wide-delegation = read ANY user's mail
  - Rotate regularly; restrict scopes
  - **Recipe convention: "Google-Workspace-domain-wide-delegation-HIGHEST-severity callout"**
  - **NEW recipe convention** (Open Archiver 1st formally; HIGHEST-severity)
- **M365-GRAPH-APP-PERMISSIONS**:
  - Mail.Read permission = read all users' mail
  - Similar god-mode
  - **Recipe convention: "M365-Graph-Mail.Read-HIGHEST-severity callout"**
  - **NEW recipe convention** (Open Archiver 1st formally)
- **REGULATORY-COMPLIANCE (SEC/HIPAA/FINRA)**:
  - Email archiving often regulated
  - Tamper-evidence + retention required
  - **Recipe convention: "regulated-archive-legal-hold-discipline callout"**
  - **NEW recipe convention** (Open Archiver 1st formally)
- **TAMPER-PROOF CLAIM-VERIFICATION**:
  - "Tamper-proof" must be verified — check actual WORM / hash-chain / signed-archive
  - **Recipe convention: "tamper-proof-implementation-verification callout"**
  - **NEW recipe convention** (Open Archiver 1st formally)
- **STORAGE-COST-AT-SCALE**:
  - Email archives grow to TBs
  - Object-storage recommended
  - **Recipe convention: "petabyte-scale-storage-architecture-planning callout"**
  - **NEW recipe convention** (Open Archiver 1st formally)
- **PST-INGEST-LEGACY-IMPORT**:
  - PST support for legacy-Exchange migration
  - Rare + valuable
  - **Recipe convention: "legacy-format-ingest-support positive-signal"**
  - **NEW positive-signal convention** (Open Archiver 1st formally)
- **LIVE-DEMO-WITH-PUBLIC-CREDS**:
  - demo.openarchiver.com with published creds
  - Rare transparency
  - **Recipe convention: "live-demo-with-public-credentials positive-signal"**
  - **NEW positive-signal convention** (Open Archiver 1st formally)
- **MULTI-COMMUNITY-CHANNEL (Discord + Bluesky)**:
  - **Multi-community-channel-presence: 2 tools** (Donetick+Open Archiver) 🎯 **2-TOOL MILESTONE**
  - **Fediverse-plus-X-presence: 2 tools** (Donetick+Open Archiver) 🎯 (broader category)
- **INSTITUTIONAL-STEWARDSHIP**: LogicLabs-OU + demo + Discord + Bluesky + docs + screenshots + active. **146th tool — small-org-with-live-demo sub-tier** (NEW-soft).
- **TRANSPARENT-MAINTENANCE**: active + demo + screenshots + Discord + Bluesky + releases. **152nd tool in transparent-maintenance family.**
- **EMAIL-ARCHIVE-CATEGORY:**
  - **Open Archiver** — modern OSS; multi-platform; sovereign
  - **MailArchiva** — commercial + free edition
  - **Mailpiler** — OSS; mature
  - **Benno MailArchiv** — German OSS
  - **ArcTitan** — commercial
  - **Mimecast/Barracuda/Proofpoint** — commercial SaaS
- **ALTERNATIVES WORTH KNOWING:**
  - **Mailpiler** — if you want mature OSS + MTA-based capture
  - **MailArchiva** — if you want commercial-support option
  - **Choose Open Archiver if:** you want modern + Google+M365+PST+IMAP ingest + SvelteKit UX.
- **PROJECT HEALTH**: active + demo + community + modern-stack. Emerging for this critical use-case.

## Links

- Repo: <https://github.com/LogicLabs-OU/OpenArchiver>
- Demo: <https://demo.openarchiver.com>
- Mailpiler (alt): <https://github.com/jsuto/piler>
- MailArchiva (alt commercial): <https://www.mailarchiva.com>
