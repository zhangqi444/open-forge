---
name: Spliit
description: "Splitwise alternative — share expenses with friends/family. Next.js + Prisma + PostgreSQL. PWA. Receipt scanning. Vercel-deploy ready OR self-host. Official instance at spliit.app. spliit-app org."
---

# Spliit

Spliit is **"Splitwise — but FOSS + Next.js + self-hostable + Vercel-deployable"** — an open-source alternative to Splitwise. Create groups, share with friends, create expenses (with descriptions), see group balances, create reimbursement expenses, mark favorites, search, upload receipt images, AI-scan receipts to auto-create expenses. **Progressive Web App** (install on phone). Use the **official instance at spliit.app**, OR self-host (1-click Vercel deploy, or Docker).

Built + maintained by **spliit-app org**. License: check LICENSE. Active; Next.js + TailwindCSS + shadcn/UI + Prisma + Vercel-hosted; Discord community.

Use cases: (a) **household/roommate expense tracking** (b) **group trip / vacation cost-split** (c) **couple's shared-expenses** (d) **family reimbursement tracking** (e) **escape Splitwise paywall** (premium features paywalled) (f) **GDPR-compliant expense sharing** (g) **receipt-image-archive + search** (h) **PWA-on-phone** — no app-store needed.

Features (per README):

- **Create groups** + share via link
- **Expenses with descriptions**
- **Group balances**
- **Reimbursement expenses**
- **Progressive Web App**
- **Uneven split** support
- **Favorite groups**
- **Per-user identity in group**
- **Expense categories**
- **Search** in group
- **Receipt image upload**
- **AI receipt scanning** → auto-create expense (new feature)

- Upstream repo: <https://github.com/spliit-app/spliit>
- Official instance: <https://spliit.app>
- Discord: <https://discord.gg/YSyVXbwvSY>

## Architecture in one minute

- **Next.js** (React)
- **TailwindCSS + shadcn/UI**
- **Prisma ORM**
- **PostgreSQL**
- **Resource**: low-moderate — 200-400MB RAM
- **Vercel-compatible** deployment

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker Compose** | **Next.js + Postgres**                                          | **Primary self-host**                                                                        |
| **Vercel 1-click** | **Official Vercel + Postgres**                                  | Non-self-host                                                                                   |
| Source             | Next.js                                                                            | Dev                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `spliit.example.com`                                        | URL          | TLS                                                                                    |
| PostgreSQL           | Data                                                        | DB           |                                                                                    |
| S3 / compatible (opt) | Receipt-image storage                                      | Storage      |                                                                                    |
| OpenAI API key (opt) | Receipt-scanning AI                                         | **SENSITIVE** | Sent to OpenAI; review contents                                                                                    |
| `NEXTAUTH_SECRET` / JWT | Session signing                                          | **CRITICAL** | **IMMUTABLE**                                                                                    |

## Install via Docker

```yaml
services:
  spliit:
    image: (build from source OR use community image)        # **pin version**
    environment:
      POSTGRES_PRISMA_URL: postgresql://spliit:${DB_PASSWORD}@db:5432/spliit?pgbouncer=true
      POSTGRES_URL_NON_POOLING: postgresql://spliit:${DB_PASSWORD}@db:5432/spliit
      NEXTAUTH_SECRET: ${SECRET}
      # OPENAI_API_KEY: ... # optional for receipt-scan
    ports: ["3000:3000"]
    depends_on: [db]

  db:
    image: postgres:17
    environment:
      POSTGRES_DB: spliit
      POSTGRES_USER: spliit
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes: [pgdata:/var/lib/postgresql/data]

volumes:
  pgdata: {}
```

## First boot

1. Start → browse web UI
2. Create first group
3. Add expenses; test balance calculations
4. Upload receipt; test AI-scan (if configured)
5. Install as PWA on phone
6. Put behind TLS reverse proxy + optional auth
7. Back up DB regularly

## Data & config layout

- PostgreSQL — all groups, expenses, receipts
- Receipt images — local or S3 (if configured)

## Backup

```sh
docker compose exec db pg_dump -U spliit spliit > spliit-$(date +%F).sql
```

## Upgrade

1. Releases: <https://github.com/spliit-app/spliit/releases>. Active.
2. Prisma migrations run automatically
3. Docker pull + restart

## Gotchas

- **99th HUB-OF-CREDENTIALS TIER 2 — FINANCIAL-DATA SUB-FAMILY**:
  - Expense amounts + descriptions + receipt images = financial data
  - Reveals spending patterns, relationships, locations (receipts)
  - **Financial-data-sub-family**: already named? (yes — Actual Budget, Firefly III, Maybe, ...) — **Spliit 99th tool joining existing financial-data sub-family**
  - **99th tool in hub-of-credentials family — Tier 2**
  - **Approaching 100-tool hub-of-credentials milestone!**
- **SHARED-GROUP-DATA + MULTI-USER CONSENT**:
  - Group members share expense data by design
  - Adding member = consent from all existing members?
  - GDPR issue: each participant has own personal-data rights
  - **Recipe convention: "multi-user-shared-data-consent" callout**
  - **NEW recipe convention** (Spliit 1st formally)
- **AI-RECEIPT-SCANNING = DATA-EXFILTRATION**:
  - Receipt images sent to OpenAI (if feature enabled)
  - Contains: merchant name, amount, date, location, sometimes card-digits
  - **EU-users**: GDPR transfer-to-US issue
  - **Recipe convention: "LLM-feature-sends-data-externally"** extended (EventCatalog 108 was 1st; Spliit 2nd)
  - **2 tools now** in this META-FAMILY
  - Consider: local LLM (Ollama) for privacy
- **OFFICIAL INSTANCE VS SELF-HOST**:
  - spliit.app is run by maintainer
  - Provides easy default; users may never self-host
  - **Recipe convention: "official-hosted-instance-for-OSS" tradeoff**
  - Self-host if: privacy-sensitive, data-sovereignty, cost avoidance (none for Spliit free tier)
- **NEXT.JS + VERCEL LOCK-IN RISK**:
  - Some Next.js features (Edge Runtime, ISR, Server Actions) are Vercel-optimized
  - Self-hosting may miss features
  - **Recipe convention: "Next.js-Vercel-optimization-leakage" callout**
  - **NEW recipe convention** (Spliit 1st formally)
- **PROGRESSIVE WEB APP**:
  - Install-on-phone without app-store
  - Good UX; reduces iOS/Android-friction
  - **Recipe convention: "PWA-no-app-store positive-signal"**
  - **NEW positive-signal convention** (Spliit 1st formalized)
- **RECEIPT IMAGE UPLOAD = STORAGE GROWTH**:
  - Receipts are large; group-lifetime adds up
  - S3 backend recommended for scale
- **SPLITWISE-ALTERNATIVE CATEGORY (emerging):**
  - **Spliit** — Next.js; PWA
  - **Shumi** — Go; simpler
  - **Splid** — iOS-first
  - **Tricount** — commercial
  - **Splitwise** (commercial reference)
- **INSTITUTIONAL-STEWARDSHIP**: spliit-app org + Discord + official-instance. **85th tool — org-with-official-hosted-instance sub-tier.**
  - **Hosted-OSS-as-service: 2 tools** (prior tududi 107 + **Spliit**)
  - **2-tool milestone**
- **TRANSPARENT-MAINTENANCE**: active + Discord + Vercel-deploy + issues-linked-to-features + stack-documented. **93rd tool in transparent-maintenance family.**
- **ALTERNATIVES WORTH KNOWING:**
  - **Splitwise** — commercial reference; not self-hosted
  - **Actual Budget** (prior batches) — if you want broader personal-finance + budget
  - **Firefly III** (prior batches) — if you want full accounting (not shared)
  - **Choose Spliit if:** you want Splitwise-clone + self-hostable + modern-UX + PWA.
- **PROJECT HEALTH**: active + Discord + Vercel-ready + official-instance. Strong.

## Links

- Repo: <https://github.com/spliit-app/spliit>
- Official: <https://spliit.app>
- Splitwise (commercial ref): <https://www.splitwise.com>
- Actual Budget: <https://actualbudget.org>
- Firefly III: <https://www.firefly-iii.org>
