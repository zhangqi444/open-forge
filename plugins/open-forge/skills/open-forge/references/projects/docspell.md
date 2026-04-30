---
name: Docspell
description: "Personal Document Management System (DMS). OCR + NLP auto-tagging + email-integration. Scala + Stanford CoreNLP. REST API + Android + CLI. eikek. Gitter chat. Docker Hub multi-image."
---

# Docspell

Docspell is **"Paperless-NGX — but Scala + NLP-heavy + email-first + Android-app"** — a personal Document Management System (DMS). Scan papers → OCR → **NLP-based auto-tagging** (Stanford CoreNLP; suggests correspondents, tags, dates). Email ingestion. Fulltext search. Mobile-friendly SPA + **Android app** + **CLI (dsc)**. Targets **home, family, small company/group** use.

Built + maintained by **Eike Kettner (eikek)** (sole). License: **GPL-v3** (Stanford CoreNLP is GPL). Active; Scala Steward auto-update; Gitter chat; Docker Hub `docspell/*` multi-container.

Use cases: (a) **paperless home** — scan + OCR + auto-tag (b) **email-archive DMS** — receipts auto-ingested (c) **tax-prep organization** — date-extracted metadata (d) **small-business docs** — invoices, receipts, contracts (e) **legal document archive** with NLP tagging (f) **landlord-property docs** (g) **receipts for expense-reports** (h) **insurance-claim documentation**.

Features (per README):

- **OCR** (Tesseract)
- **NLP** correspondent/tag/date suggestion (Stanford CoreNLP)
- **Email integration** (IMAP)
- **Fulltext search**
- **REST/HTTP API**
- **Android app** (separate repo)
- **CLI (dsc)** (separate repo)
- **Custom fields + tags + correspondents**
- **Machine learning from your existing corpus**
- **Mobile-friendly SPA**

- Upstream repo: <https://github.com/eikek/docspell>
- Website: <https://docspell.org>
- Android: <https://github.com/docspell/android-client>
- CLI (dsc): <https://github.com/docspell/dsc>
- Gitter: <https://gitter.im/eikek/docspell>
- Docker: <https://hub.docker.com/u/docspell>

## Architecture in one minute

- **Scala** REST server (`docspell/restserver`)
- **Joex** processing worker (OCR, NLP)
- **PostgreSQL** DB
- **Solr** (optional) for fulltext
- **Resource**: moderate-high — CoreNLP uses Java heap; OCR CPU-heavy

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker Compose** | **Multi-container** (restserver + joex + db)                    | **Primary**                                                                        |
| **Native**         | Java/Scala JARs                                                                                                        | Alt                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `docs.example.com`                                          | URL          | TLS                                                                                    |
| Admin creds          | First-boot                                                  | Bootstrap    | Strong                                                                                    |
| PostgreSQL           | Data                                                        | DB           |                                                                                    |
| Solr (opt)           | Fulltext                                                    | Infra        |                                                                                    |
| IMAP creds           | For email ingest                                            | Channels     | Per-user                                                                                    |
| Document uploads     | Disk / volume                                               | Storage      | OCR'd + kept                                                                                    |

## Install via Docker

Follow: <https://docspell.org/docs/install/docker/>

```yaml
services:
  db:
    image: postgres:17
    environment:
      POSTGRES_USER: dbuser
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_DB: dbname
    volumes: [pgdata:/var/lib/postgresql/data]

  solr:
    image: solr:9
    # or skip for no-fulltext

  joex:
    image: docspell/joex:latest        # **pin**
    environment:
      DOCSPELL_JOEX_JDBC_URL: jdbc:postgresql://db:5432/dbname
      DOCSPELL_JOEX_JDBC_USER: dbuser
      DOCSPELL_JOEX_JDBC_PASSWORD: ${DB_PASSWORD}
    depends_on: [db]
    volumes: [joex-tmp:/opt/joex-tmp]

  restserver:
    image: docspell/restserver:latest        # **pin**
    environment:
      DOCSPELL_SERVER_JDBC_URL: jdbc:postgresql://db:5432/dbname
      DOCSPELL_SERVER_JDBC_USER: dbuser
      DOCSPELL_SERVER_JDBC_PASSWORD: ${DB_PASSWORD}
    ports: ["7880:7880"]
    depends_on: [db, joex]

volumes:
  pgdata: {}
  joex-tmp: {}
```

## First boot

1. Start stack
2. Create first user account; set strong password
3. Configure IMAP mailbox for email-ingest (optional)
4. Upload first document; watch OCR + NLP enrichment
5. Set correspondent suggestions
6. Install Android app for on-phone upload
7. Put behind TLS reverse proxy
8. Back up PG + document storage

## Data & config layout

- PostgreSQL — metadata, users, tags
- Document storage — OCR'd PDFs, originals
- Solr (if enabled) — fulltext index (rebuildable)

## Backup

```sh
docker compose exec db pg_dump -U dbuser dbname > docspell-$(date +%F).sql
sudo tar czf docspell-docs-$(date +%F).tgz docspell-docs/
# Solr is rebuildable from docs+DB
```

## Upgrade

1. Releases: <https://github.com/eikek/docspell/releases>. Active (Scala Steward-aided).
2. Read release notes — DB migrations
3. Scala Steward auto-updates dependencies = good, but major releases need review

## Gotchas

- **127th HUB-OF-CREDENTIALS CROWN-JEWEL TIER 1 — DOCUMENT-ARCHIVE + EMAIL-CREDENTIALS**:
  - Holds: ALL scanned documents (tax, legal, financial, ID) + IMAP creds + API tokens + NLP corpus of your correspondence
  - **127th tool in hub-of-credentials family — Tier 1 CROWN-JEWEL**
  - **NEW CROWN-JEWEL Tier 1 sub-category: "personal-DMS + email-ingest-IMAP-creds"** (1st — Docspell; distinct from Libredesk's IMAP — this is personal-PII-document archive)
  - **CROWN-JEWEL Tier 1: 36 tools / 33 sub-categories**
- **NLP-ON-PERSONAL-CORRESPONDENCE**:
  - Stanford CoreNLP runs on your documents
  - Local-only (no external LLM calls) — privacy-positive
  - Builds a rich metadata-corpus of your life
  - **Recipe convention: "local-NLP-on-personal-data positive-signal"**
  - **NEW positive-signal convention** (Docspell 1st formally)
- **SCALA-STEWARD AUTO-DEP-UPDATES**:
  - Bot that proposes dependency upgrades
  - Reduces security-lag
  - **Recipe convention: "Scala-Steward-automated-dep-updates positive-signal"**
  - **NEW positive-signal convention** (Docspell 1st formally)
- **MULTI-CONTAINER-COMPLEXITY**:
  - restserver + joex + db + (optional solr) = 3-4 containers
  - Joex is a SEPARATE worker — important for resource-planning
  - **Microservice-complexity-tax: 6 tools** (+Docspell) 🎯 **6-TOOL MILESTONE**
- **GPL-v3 DUE TO CoreNLP**:
  - Stanford CoreNLP is GPL-v3
  - Enforces strong copyleft
  - **Recipe convention: "GPL-dependency-cascades-license"** — important for redistribution
  - **NEW recipe convention** (Docspell 1st formally)
- **OCR + NLP CPU-INTENSIVE**:
  - Joex worker uses significant CPU during ingestion
  - Queue-ing is built-in
  - **Recipe convention: "worker-queue-backpressure-discipline" positive-signal**
- **ANDROID-CLIENT COMPANION**:
  - Scan + upload from phone
  - **Recipe convention: "native-mobile-companion-app positive-signal"** — reinforces AliasVault (112)
- **CLI COMPANION (dsc)**:
  - Scriptable ingestion
  - **Recipe convention: "CLI-companion-for-automation positive-signal"**
  - **NEW positive-signal convention** (Docspell 1st formally)
- **IMAP-INGESTION LOOP**:
  - Periodic scan of mailboxes
  - **Recipe convention: "IMAP-polling-for-document-ingest callout"**
  - **NEW recipe convention** (Docspell 1st formally)
- **GITTER CHAT (legacy-era)**:
  - Community on Gitter (Element/Matrix now owns; Gitter is aging)
  - **Recipe convention: "Gitter-legacy-community-channel neutral-signal"**
  - **NEW neutral-signal convention** (Docspell 1st formally)
- **INSTITUTIONAL-STEWARDSHIP**: eikek sole + Scala-Steward + Android-app + CLI + Gitter + website + demos. **113th tool — sole-maintainer-with-ecosystem-siblings sub-tier**.
- **TRANSPARENT-MAINTENANCE**: active + Scala-Steward + releases + Docker Hub + website + docs + Android + CLI. **119th tool in transparent-maintenance family.**
- **DMS-CATEGORY:**
  - **Docspell** — Scala; NLP-heavy; email-first; Android
  - **Paperless-NGX** (Python) — dominant OSS; mature; consumer
  - **Mayan EDMS** — Python/Django; enterprise-style
  - **Teedy** (formerly Sismics Docs) — Java
  - **PaperMerge** — Python
- **ALTERNATIVES WORTH KNOWING:**
  - **Paperless-NGX** — if you want dominant OSS + easier
  - **Mayan EDMS** — if you want enterprise features
  - **Teedy** — if you want Java
  - **Choose Docspell if:** you want Scala + NLP + email-first + Android + CLI.
- **PROJECT HEALTH**: active + Scala-Steward + Android + CLI + docs. Strong.

## Links

- Repo: <https://github.com/eikek/docspell>
- Website: <https://docspell.org>
- Paperless-NGX (alt): <https://github.com/paperless-ngx/paperless-ngx>
- Mayan EDMS (alt): <https://www.mayan-edms.com>
- CoreNLP: <https://github.com/stanfordnlp/CoreNLP>
