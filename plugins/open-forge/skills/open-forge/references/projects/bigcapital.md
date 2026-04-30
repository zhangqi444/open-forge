---
name: Bigcapital
description: "Self-hosted accounting + inventory software for small-to-medium businesses. Double-entry bookkeeping, invoicing, reports, intelligent reporting. TypeScript + PostgreSQL + Redis. AGPL-3.0. Bigcapital Cloud commercial SaaS available."
---

# Bigcapital

Bigcapital is **"QuickBooks for people who want to own their financial data"** — a modern open-source accounting + inventory platform. Double-entry bookkeeping, invoicing, bills + expenses, inventory tracking, financial statements (P&L, balance sheet, cash flow), multi-currency, tax handling, and "intelligent reporting". Self-host for sovereignty or use **Bigcapital Cloud** at my.bigcapital.app (upstream's commercial SaaS — same product, hosted).

Built + maintained by **bigcapitalhq** (Ahmed Bouhuolia + team). **AGPL-3.0**. Active repo + Docker releases + Discord community + Postman public API workspace. Positions as a **headless accounting platform** with API-first architecture — you can integrate Bigcapital into your existing SaaS/webapp for double-entry bookkeeping as a service.

Use cases: (a) **SMB accounting** replacement for QuickBooks / Xero (b) **freelance / consultant bookkeeping** — simpler than desktop tools (c) **headless accounting backend** — integrate via API into your own SaaS (d) **inventory + invoicing** combined with accounting in one system (e) **tax preparation support** with P&L + expense reports (f) **multi-currency trading** business accounting.

Features (from upstream README + docs):

- **Double-entry bookkeeping** — the accounting foundation
- **Invoicing + Bills + Expenses**
- **Inventory tracking** — SKUs, categories, stock levels
- **Customer + Vendor management** — CRM-lite
- **Financial statements**: P&L, balance sheet, cash flow, trial balance, general ledger
- **Multi-currency** with exchange rate management
- **Tax rates** (VAT, GST, sales tax)
- **Chart of accounts** customization
- **Reconciliation** — bank reconciliation support
- **Reports customization**
- **Multi-user** with role permissions
- **REST API** — headless integration
- **Automation** — recurring invoices + scheduled jobs
- **Notifications**
- **Multi-tenant** via organizations (in cloud; self-host = usually single-tenant per deploy)

- Upstream repo: <https://github.com/bigcapitalhq/bigcapital>
- Homepage: <https://bigcapital.app>
- Cloud (SaaS): <https://my.bigcapital.app>
- Docs: <https://docs.bigcapital.app>
- Docker deployment: <https://docs.bigcapital.app/deployment/docker>
- Discord: <https://discord.com/invite/c8nPBJafeb>
- Postman API: <https://www.postman.com/bigcapital/workspace/bigcapital-api>
- Docker Hub: <https://hub.docker.com/u/bigcapitalhq>

## Architecture in one minute

- **TypeScript / Node.js** (Nest.js-style) backend + **React** frontend
- **PostgreSQL** — primary DB
- **Redis** — caching + queues
- **Separate services**: webapp + server + workers (typical microservices split)
- **Resource**: moderate — 2-4GB RAM; Postgres + Redis + Node workers
- **Ports**: 80/443 via reverse proxy

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker Compose** | **`bigcapitalhq/webapp` + server + workers + Postgres + Redis** | **Upstream-supported** via <https://docs.bigcapital.app/deployment/docker>         |
| Manual             | Node + Postgres + Redis manual setup                                      | Advanced                                                                                   |
| Gitpod             | Dev-mode spinup for evaluation                                                       | Eval only                                                                                            |
| Bigcapital Cloud   | SaaS at my.bigcapital.app                                                                         | Commercial alternative                                                                                           |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `accounting.example.com`                                    | URL          | TLS MANDATORY                                                                                    |
| Postgres             | Dedicated DB + user                                         | DB           | Modern PG (v14+ recommended)                                                                                    |
| Redis                | Local or managed                                                                  | Cache/queue  | Required                                                                                    |
| JWT secret           | Node.js JWT signing key                                                                                        | **CRITICAL** | **IMMUTABLE** — generate + back up                                                                                                      |
| Encryption key       | For sensitive field encryption                                                                                                   | **CRITICAL** | **IMMUTABLE** — losing = cannot decrypt historical data                                                                                                          |
| Admin user + password | At installer                                                                                                                                            | Bootstrap    | Strong password; enable 2FA                                                                                                                                                          |
| SMTP                 | For invoice email, password reset                                                                                                                                                     | Outbound     | Required for workflow                                                                                                                                                                            |
| Stripe / payment gateway (opt)                       | For online invoice payment                                                                                                                                                                                                        | Optional     | Similar considerations as Hi.Events (batch 89)                                                                                                                                                                                                                                                 |

## Install via Docker Compose

Follow upstream's Docker guide: <https://docs.bigcapital.app/deployment/docker>. Typical structure:

```yaml
# Simplified sketch — check upstream docs for current shape
services:
  webapp:
    image: bigcapitalhq/webapp:latest     # **pin version** in prod
  server:
    image: bigcapitalhq/server:latest
    environment:
      - JWT_SECRET=${BIGCAP_JWT_SECRET}
      - ENCRYPTION_KEY=${BIGCAP_ENCRYPTION_KEY}
      - DATABASE_URL=postgres://...
      - REDIS_URL=redis://...
      # SMTP, Stripe, etc.
  workers:
    image: bigcapitalhq/server:latest
    command: ["worker"]
  postgres:
    image: postgres:15
  redis:
    image: redis:7
```

## First boot

1. Browse your Bigcapital domain → sign-up / first-admin flow
2. Create organization → configure: base currency, fiscal year start, tax settings
3. Build chart of accounts (import default or customize)
4. Create customers + vendors
5. Record opening balances
6. Test: create an invoice → email it → verify PDF rendering works
7. Enable 2FA for admin accounts
8. Configure reverse proxy + TLS
9. Back up Postgres + `.env` + encryption key

## Data & config layout

- **PostgreSQL** — ALL your accounting data (transactions, invoices, inventory, customers, audit trail)
- **Redis** — queue + cache
- **Uploaded files** — invoice attachments, logos (local or S3-adapter)
- **`.env`** — secrets (JWT, encryption, DB, Redis, SMTP, Stripe, etc.)

## Backup

```sh
# CRITICAL: encrypted + tested + offsite
pg_dump -Fc bigcapital > bigcapital-$(date +%F).dump
sudo tar czf bigcapital-uploads-$(date +%F).tgz bigcapital-uploads/
# .env and encryption key: password-manager + separate secure backup
```

**Test your restore regularly** — for financial data especially, untested backups = phantom backups. Rehearsal discipline per batch 86 (Chartbrew, 2FAuth).

## Upgrade

1. Releases: <https://github.com/bigcapitalhq/bigcapital/releases>. Active.
2. Docker: pull + restart; DB migrations run automatically.
3. **Back up Postgres + uploads + .env BEFORE upgrading** — accounting data corruption = business-critical damage.
4. Read release notes for breaking changes.
5. Consider a staging environment for major upgrades before touching production.

## Gotchas

- **FINANCIAL DATA = REGULATORY + LEGAL CROWN JEWEL**: accounting records carry:
  - **Tax authority obligations** — retention (typically 5-10 years depending on jurisdiction)
  - **Audit trail integrity** — any change must be traceable
  - **GDPR + PII** — customer/vendor data inside
  - **PCI DSS** (if processing card payments via integration)
  - **SOX / IFRS / GAAP** compliance (for larger or regulated orgs)
  - **Losing / corrupting data = potential legal/tax/regulatory exposure.**
  - **Tier-1 backup discipline**: daily + weekly + monthly rotations, offsite, encrypted, tested restores.
- **DOUBLE-ENTRY INVARIANTS**: corruption of accounting data (unbalanced entries) = hours of forensic cleanup + potential audit findings. **Never modify Bigcapital's DB directly** — always through the UI/API so audit trails + double-entry invariants are maintained. Same class as never-editing-WordPress-wp_options-directly.
- **IMMUTABILITY-OF-SECRETS**: JWT signing key + encryption key are both immutable. **17th tool in immutability-of-secrets family** (+ JWT + encryption keys).
- **HUB-OF-CREDENTIALS Tier 2 (crown-jewel proper) — FINANCIAL DATA SUBTYPE**: Bigcapital stores:
  - Customer/vendor contact info (PII)
  - Full accounting history (financially-sensitive)
  - SMTP creds, Stripe keys, bank reconciliation data
  - Potentially bank-account details (IBAN/routing) for payments
  - **21st tool in hub-of-credentials family.**
  - Higher-than-average sensitivity because **financial-data-specific regulatory framework** piles on top of general data-protection requirements.
- **PAYMENT INTEGRATION = PCI SCOPE** (same warning as Hi.Events batch 89): if you enable online invoice payment via Stripe (etc.), PCI DSS scope kicks in. Stripe Checkout redirect keeps scope narrow; avoid custom card-entry forms on Bigcapital's domain.
- **MULTI-TENANCY vs SINGLE-TENANT**: Bigcapital Cloud is multi-tenant; self-hosted is typically single-tenant. **If you plan to host for multiple unrelated businesses**, consider separate instances per business (DB-level isolation) to contain compromise radius + simplify compliance.
- **FINANCIAL-DATA RETENTION vs GDPR right-to-erasure tension**: accounting law requires 5-10 year retention of transaction records; GDPR requires deletion on request for personal data. Resolution: **pseudonymize customer PII but retain transaction records** — Bigcapital should support this pattern; verify with their specific implementation.
- **FRAUD DETECTION = your responsibility**: Bigcapital records transactions; it doesn't fraud-detect. Audit unusual patterns (duplicate invoices, round-number vendor payments, unexpected new vendors) per established internal controls.
- **UPGRADE-DATA-MIGRATION**: accounting DB schema changes between majors can affect report generation, reconciliation, tax calculations. **Test upgrades in staging with realistic data** + verify key reports (P&L, balance sheet) match before + after.
- **BACKUP RESTORE REHEARSAL** (universal but CRITICAL here): actually restore a backup to a staging environment + verify it works. **Unrestorable backup of financial data = catastrophic.**
- **Commercial-tier**: Bigcapital Cloud at my.bigcapital.app = **"hosted-SaaS-of-OSS-product"** tier (same product, paid-hosted). Taxonomy entry from batch 89 applies.
- **AGPL-3 + commercial SaaS**: transparent model. If you modify Bigcapital + offer as SaaS, AGPL requires source disclosure. Fair.
- **Discord community support**: active. For accounting-critical production issues, consider commercial support path if upstream offers (or the Discord).
- **Multi-language**: check current language coverage — important for international customers.
- **Inventory module integration**: not all accounting tools have inventory built-in; Bigcapital does. For stock-heavy businesses this is a plus vs pure-accounting alternatives.
- **Banking integration (Plaid / bank feeds)**: check upstream for current state. Automated bank-feed import is a huge QBO selling point; Bigcapital's coverage here depends on version.
- **Competitor landscape**:
  - **InvoicePlane** — PHP invoicing-first (lighter, less accounting-rigor)
  - **Akaunting** — PHP/Laravel with paid modules (open-core)
  - **Firefly III** — personal finance, not business-accounting-grade
  - **ERPNext / Frappe** — full ERP including accounting (heavier)
  - **Odoo (community)** — full ERP, open-core-with-licensing-tension
  - **GnuCash** — desktop double-entry (no web)
  - **QuickBooks / Xero / Zoho Books** — commercial SaaS incumbents
  - **Manager.io** — freemium desktop + cloud
  - **Wave** (commercial free+paid, ad-supported)
  - **Choose Bigcapital if:** you want modern TypeScript stack + AGPL + inventory+accounting+invoicing unified + willing to run Postgres+Redis+Node stack.
  - **Choose Akaunting if:** you want Laravel/PHP + open-core.
  - **Choose ERPNext if:** you want full ERP.
  - **Choose QuickBooks/Xero if:** you don't want ops burden + accept SaaS.
- **Project health**: active development + Discord community + documentation + Bigcapital Cloud = commercial funding. Positive signals.

## Links

- Repo: <https://github.com/bigcapitalhq/bigcapital>
- Homepage: <https://bigcapital.app>
- Cloud: <https://my.bigcapital.app>
- Docs: <https://docs.bigcapital.app>
- Docker guide: <https://docs.bigcapital.app/deployment/docker>
- Discord: <https://discord.com/invite/c8nPBJafeb>
- API (Postman): <https://www.postman.com/bigcapital/workspace/bigcapital-api>
- InvoicePlane (alt, invoicing): <https://invoiceplane.com>
- Akaunting (alt, open-core): <https://akaunting.com>
- ERPNext (alt, full ERP): <https://frappe.io/erpnext>
- Firefly III (personal-finance alt): <https://www.firefly-iii.org>
- GnuCash (desktop alt): <https://www.gnucash.org>
