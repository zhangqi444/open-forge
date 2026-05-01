---
name: Notifuse
description: "Platform for sending newsletters + transactional mail. Self-hosted alternative to Mailchimp/Brevo/Mailjet/Listmonk/Mailerlite/Klaviyo/Loop.so. Go + React. Visual email builder (MJML). A/B testing. Notifuse Cloud from $16/mo."
---

# Notifuse

Notifuse is **"Mailchimp / Brevo — but self-hosted"** — a modern platform for sending newsletters + transactional emails. OSS core + commercial cloud parallel. Go + React. Visual drag-and-drop email builder with MJML. Transactional REST API. A/B testing. Campaign + list management.

Built + maintained by **Notifuse** org. Commercial SaaS at notifuse.com ($16/mo starting). Live demo at demo.notifuse.com. Codecov + Go Report Card A+. Active.

Use cases: (a) **transactional email** (password-reset, receipts) (b) **marketing newsletters** (c) **Mailchimp-alternative with data sovereignty** (d) **Listmonk-alternative with visual builder** (e) **A/B subject-line testing** (f) **list segmentation** (g) **campaign scheduling** (h) **contact PII-management with custom fields**.

Features (per README):

- **Visual Email Builder** (MJML)
- **Campaign Management** — create + schedule + send
- **A/B Testing**
- **List Management** — segmentation
- **Contact Profiles** — custom fields
- **Transactional API** — REST
- **Interactive setup wizard**
- **Go + React**

- Upstream repo: <https://github.com/Notifuse/notifuse>
- Website: <https://www.notifuse.com>
- Demo: <https://demo.notifuse.com/console/signin?email=demo@notifuse.com>

## Architecture in one minute

- **Go** backend + **React** frontend
- SQL database (Postgres likely)
- Sending via external provider (SES, Sendgrid, Resend, Mailgun, SMTP)
- **Resource**: moderate
- **Port**: web UI + API

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker Compose** | Self-host                                                                                                              | Primary                                                                                    |
| **Notifuse Cloud** | SaaS ($16/mo)                                                                                                          | Alt                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `notify.example.com`                                        | URL          | **TLS MANDATORY**                                                                                    |
| DB                   | PostgreSQL                                                  | DB           |                                                                                    |
| Sending provider     | SES/Sendgrid/Resend/SMTP                                    | Email        | **CRITICAL** (deliverability)                                                                                    |
| DNS SPF/DKIM/DMARC   | Your sending domain                                         | DNS          | **Required**                                                                                    |
| Admin                | First-boot via wizard                                       | Bootstrap    |                                                                                    |

## Install via Docker Compose

Per repo + website. Typical:
```yaml
services:
  postgres:
    image: postgres:15
  notifuse:
    image: notifuse/notifuse:latest        # **pin**
    ports: ["3000:3000"]
    environment:
      - DATABASE_URL=...
      - SMTP_HOST=...
    depends_on: [postgres]
    restart: unless-stopped
```

## First boot

1. Start; visit UI; run setup wizard
2. Configure sending provider (SES/Resend/SMTP)
3. Verify sending domain (SPF/DKIM/DMARC)
4. Send test email to yourself
5. Create first list; import subscribers
6. Draft first campaign in visual builder
7. Send to test-segment before full-list
8. Back up Postgres
9. **TLS mandatory**

## Data & config layout

- Postgres — contacts, lists, campaigns, templates
- Sending-provider state (external)

## Backup

```sh
pg_dump notifuse > notifuse-$(date +%F).sql
# Contains ALL subscriber PII + sending-provider creds — **ENCRYPT**
```

## Upgrade

1. Releases: <https://github.com/Notifuse/notifuse/releases>
2. DB migrations
3. Docker pull + restart

## Gotchas

- **166th HUB-OF-CREDENTIALS CROWN-JEWEL TIER 1 — NEWSLETTER-PII + SENDING-CREDS**:
  - Holds: ALL subscriber PII + sending-provider creds (SES API key = send-from-your-domain)
  - Bounce/complaint data = sender-reputation material
  - **166th tool in hub-of-credentials family — Tier 1 CROWN-JEWEL**
  - Parallels Keila (117): **"newsletter-tool + subscriber-PII-plus-sending-creds" CROWN-JEWEL Tier 1: 2 tools** (Keila+Notifuse) 🎯 **2-TOOL MILESTONE — MATURED sub-category**
  - **CROWN-JEWEL Tier 1: 57 tools / 51 sub-categories** (sub-cat not new — matured)
- **SENDING-PROVIDER-KEY-ROTATION**:
  - SES/Sendgrid/etc. API keys = full-send-from-your-domain
  - Rotate regularly; scope minimally
  - **Recipe convention: "sending-provider-key-rotation-discipline"** — reinforces Keila (117)
- **SPF/DKIM/DMARC-SETUP**:
  - Deliverability requires correct DNS
  - **Recipe convention: "email-deliverability-SPF-DKIM-DMARC-discipline callout"**
  - **NEW recipe convention** (Notifuse 1st formally; also implied in Keila)
- **SUBSCRIBER-PII-GDPR**:
  - EU subscriber data subject to GDPR
  - **Recipe convention: "GDPR-subscriber-data-rights-discipline"** — reinforces Keila
- **UNSUBSCRIBE-COMPLIANCE (CAN-SPAM, CASL, GDPR)**:
  - One-click unsubscribe required
  - Keep unsubscribe-suppression-list
  - **Recipe convention: "unsubscribe-law-compliance-discipline callout"**
  - **NEW recipe convention** (Notifuse 1st formally)
- **BOUNCE-COMPLAINT-HANDLING**:
  - Automated bounce-handling protects sender-reputation
  - **Recipe convention: "bounce-complaint-automated-handling positive-signal"**
  - **NEW positive-signal convention** (Notifuse 1st formally)
- **A/B-TESTING BUILT-IN**:
  - Subject + content + send-time testing
  - Differentiator
- **INTERACTIVE-SETUP-WIZARD**:
  - First-boot wizard
  - Lower-friction onboarding
  - **Recipe convention: "interactive-setup-wizard positive-signal"**
  - **NEW positive-signal convention** (Notifuse 1st formally)
- **GO-REPORT-CARD-A+**:
  - Public Go code-quality A+
  - **Recipe convention: "Go-Report-Card-A-plus positive-signal"**
  - **NEW positive-signal convention** (Notifuse 1st formally)
- **LIVE-DEMO-WITH-PUBLIC-CREDS**:
  - demo.notifuse.com with published creds
  - **Live-demo-with-public-credentials: 2 tools** (Open Archiver+Notifuse) 🎯 **2-TOOL MILESTONE**
- **COMMERCIAL-PARALLEL (Notifuse Cloud $16/mo)**:
  - **Commercial-parallel-with-OSS-core: 15 tools** 🎯 **15-TOOL MILESTONE**
  - Explicit-pricing-transparency
- **SELF-HOSTED-EMAIL-DELIVERABILITY-COMPLEXITY**:
  - **Self-hosted-email-deliverability-complexity: 3 tools** (Keila+?+Notifuse) 🎯 **3-TOOL MILESTONE** (may need recount)
- **INSTITUTIONAL-STEWARDSHIP**: Notifuse org + website + demo + SaaS + Go-A+ + Codecov + pricing-transparency. **152nd tool — commercial-OSS-with-transparent-pricing sub-tier** (NEW-soft).
- **TRANSPARENT-MAINTENANCE**: active + CI + codecov + Go-report + demo + pricing. **158th tool in transparent-maintenance family.**
- **NEWSLETTER-PLATFORM-CATEGORY:**
  - **Notifuse** — modern; Go+React; MJML
  - **Keila** — Elixir; b117
  - **Listmonk** — Go; minimalist
  - **Mautic** — PHP; marketing-automation heavy
  - **Mailchimp/Brevo/Mailjet/Mailerlite/Klaviyo** — commercial SaaS
- **ALTERNATIVES WORTH KNOWING:**
  - **Listmonk** — if you want lean Go + no visual-builder
  - **Keila** — if you want Elixir + commercial-parallel + OSS heritage
  - **Mautic** — if you want marketing-automation
  - **Choose Notifuse if:** you want visual-builder + transactional + A/B + commercial-parallel.
- **PROJECT HEALTH**: active + commercial-parallel + demo + Go-A+ + codecov + pricing-transparent. Strong.

## Links

- Repo: <https://github.com/Notifuse/notifuse>
- Website: <https://www.notifuse.com>
- Demo: <https://demo.notifuse.com>
- Listmonk (alt): <https://github.com/knadh/listmonk>
- Keila (alt): <https://github.com/pentacent/keila>
