---
name: Laudspeaker
description: "OSS customer engagement + product onboarding platform. Alternative to Braze/OneSignal/Customer.io/FCM/Appcues/Pendo. Visual journey builder, segment builder, multi-channel (push/email/SMS/webhook), A/B tests, Liquid templating. Laudspeaker Cloud commercial tier exists."
---

# Laudspeaker

Laudspeaker is **"Braze / OneSignal / Customer.io / Firebase Cloud Messaging / Appcues / Pendo — but OSS"** — an open-source customer engagement + product onboarding + adoption platform. **Visual journey builder** (complex workflows whole team understands). **Segment builder** (by attributes/actions/campaign-history-retargeting). **Multi-channel messaging**: push + email + SMS + webhooks. **A/B tests + Liquid templating + external-API calls** for personalization.

Built + maintained by **laudspeaker org**. License: check LICENSE. Active; commits-per-month badge; Slack community; hosted "Laudspeaker Cloud" + self-hosted OSS; docs at laudspeaker.com/docs.

Use cases: (a) **replace Braze/Customer.io** — enterprise engagement but self-hosted (b) **product-onboarding flows** — guide users through first-use (c) **churn-reduction campaigns** — re-engage inactive users (d) **A/B test messaging** — compare variants at scale (e) **omni-channel customer communication** — email + push + SMS coordinated (f) **GDPR-compliant engagement** — data stays on your infra (g) **startup without Braze budget** (h) **feature-adoption nudges** — in-app + external messages.

Features (per README):

- **Visual journey builder**
- **Segment builder** — attributes + actions + retargeting
- **Multi-channel messaging**: push, email, SMS, webhooks
- **A/B tests**
- **Liquid templating**
- **External API calls** for personalization
- **Laudspeaker Cloud** (hosted commercial tier)
- **Self-hosted OSS**

- Upstream repo: <https://github.com/laudspeaker/laudspeaker>
- Website: <https://laudspeaker.com>
- Docs: <https://laudspeaker.com/docs/guides/overview/intro/>
- Slack: <https://laudspeakerusers.slack.com>

## Architecture in one minute

- Node.js / NestJS (likely)
- PostgreSQL + ClickHouse (likely — for events) + Redis
- Message queue (Kafka/BullMQ likely)
- **Resource**: moderate-high — microservice stack
- Similar to Dittofeed (106) architecture

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker Compose** | **Upstream**                                                    | **Primary**                                                                        |
| Source             | NestJS                                                                            | Dev                                                                                   |
| **Laudspeaker Cloud** | Hosted commercial                                                                                                    | Pay                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `laudspeaker.example.com`                                   | URL          | TLS                                                                                    |
| Admin creds          | First-boot                                                  | Bootstrap    | Strong                                                                                    |
| PostgreSQL           | Data                                                        | DB           |                                                                                    |
| ClickHouse (if used) | Event analytics                                             | Analytics    |                                                                                    |
| Redis                | Cache + queue                                               | Infra        |                                                                                    |
| Email (SMTP/provider) | SendGrid/Mailgun/AWS SES                                   | Channel      | Deliverability                                                                                    |
| SMS provider         | Twilio / similar                                            | Channel      |                                                                                    |
| Push service         | FCM / APNS                                                  | Channel      |                                                                                    |
| Webhook endpoints    | Customer-facing                                                                                                        | Channel      |                                                                                    |

## Install via Docker

Follow: <https://laudspeaker.com/docs>

```yaml
# MINIMAL SCAFFOLD — production needs full Docker Compose per upstream docs
services:
  laudspeaker:
    image: laudspeaker/laudspeaker:latest        # **pin version**
    environment:
      DATABASE_URL: postgresql://...
      CLICKHOUSE_URL: ...
      REDIS_URL: redis://...
    ports: ["3000:3000"]
    depends_on: [db, clickhouse, redis]

  # db, clickhouse, redis services ...
```

## First boot

1. Follow upstream docs carefully — microservice stack
2. Configure email/SMS/push providers
3. Create first segment
4. Build first journey (visual builder)
5. Test with small audience (1-10 users) before scaling
6. Configure suppression list (per Dittofeed 106 precedent)
7. Put behind TLS reverse proxy
8. Back up DB (PostgreSQL + ClickHouse)

## Data & config layout

- PostgreSQL — journeys, segments, users, templates, config
- ClickHouse — events (sent/delivered/opened/clicked)
- Redis — queue state

## Backup

```sh
docker compose exec db pg_dump -U laudspeaker laudspeaker > laudspeaker-$(date +%F).sql
# ClickHouse: use clickhouse-backup tool
```

## Upgrade

1. Releases: <https://github.com/laudspeaker/laudspeaker/releases>. Active.
2. Read release notes — multi-service migrations tricky
3. Stage in non-production first

## Gotchas

- **104th HUB-OF-CREDENTIALS CROWN-JEWEL TIER 1 — marketing/brand sub-category REINFORCED**:
  - Customer-engagement platform holds: user-PII + full-engagement-history + messaging-provider-creds
  - Compromise → attacker-messages-your-users-as-you + exports-your-customer-list
  - **104th tool in hub-of-credentials family — Tier 1 CROWN-JEWEL**
  - **"marketing-compliance-hub" sub-category extended** — now 6+ tools
  - Distinct from Dittofeed (106) — different feature-emphasis but same risk-profile
- **SIMILAR-TO-DITTOFEED (106) COMPARISON**:
  - Both are customer-engagement platforms
  - Both open-core with commercial hosted tier
  - **Laudspeaker** — visual-journey-builder emphasized
  - **Dittofeed** — Temporal-based workflows
  - Different emphasis; same category
- **OPEN-CORE WITH LAUDSPEAKER CLOUD**:
  - OSS self-host available
  - Laudspeaker Cloud = commercial hosted
  - Features parity may vary
  - **Commercial-tier-taxonomy reinforced** (distinguish from feature-gated-closed-source Dittofeed)
- **MARKETING-COMPLIANCE-SUPPRESSION-LIST (from Dittofeed 106)**:
  - CAN-SPAM + GDPR + CASL require honoring unsubscribes
  - Suppression list must persist across deployments
  - **Recipe convention: "marketing-compliance-suppression-list"** extended (2nd tool — Laudspeaker)
- **EMAIL-SENDING-REPUTATION-WARMUP (from Dittofeed 106)**:
  - Same concerns apply
  - **Recipe convention: "email-sending-reputation-warmup"** extended
- **VISUAL-JOURNEY-BUILDER**:
  - Distinguishing feature
  - Non-devs can build flows
  - **Recipe convention: "visual-no-code-workflow-builder positive-signal"**
  - **NEW positive-signal convention** (Laudspeaker 1st formally)
- **LIQUID TEMPLATING**:
  - Shopify's OSS templating language
  - Common in marketing tools
  - **Recipe convention: "Liquid-templating-engine positive-signal"**
  - **NEW positive-signal convention** (Laudspeaker 1st)
- **EXTERNAL API CALLS FOR PERSONALIZATION**:
  - Messages can pull data from external APIs at send-time
  - **Recipe convention: "external-API-at-send-time flexibility"**
- **A/B TESTING = ENGINEERING-MATURITY**:
  - A/B tests on messaging require careful stats + split logic
  - **Recipe convention: "A/B-testing-built-in positive-signal"**
- **MICROSERVICE-COMPLEXITY-TAX**:
  - PostgreSQL + ClickHouse + Redis + Queue = ops burden
  - **Microservice-complexity-tax: 5 tools** (+Laudspeaker — joins Dittofeed, Convoy, ...)
- **CUSTOMER-PII = GDPR-SENSITIVE**:
  - User profiles + behaviors + messages
  - GDPR Data Processor role for Laudspeaker operator
  - **Recipe convention: "customer-PII-GDPR-processor-role"** — standard for marketing tools
- **INSTITUTIONAL-STEWARDSHIP**: laudspeaker org + commercial-cloud-tier + community + Slack + funded. **90th tool — commercial-parallel-with-OSS-core sub-tier** (Dittofeed+Fasten+KrakenD+Laudspeaker = 4 tools 🎯 **4-TOOL MILESTONE**).
- **TRANSPARENT-MAINTENANCE**: active + commits-per-month-badge + Slack + docs + commercial-cloud. **98th tool in transparent-maintenance family.**
- **CUSTOMER-ENGAGEMENT-CATEGORY:**
  - **Laudspeaker** — visual-journey + multi-channel
  - **Dittofeed** (106) — Temporal workflow + omni
  - **Gophish** (narrower; phishing simulation)
  - **Listmonk** — newsletter-focused
  - **Plunk** — transactional email
  - **Mautic** — mature OSS marketing automation
  - **Braze / Customer.io / OneSignal / Iterable / Appcues / Pendo** (commercial references)
- **ALTERNATIVES WORTH KNOWING:**
  - **Dittofeed** (106) — if you prefer Temporal-workflow focus
  - **Mautic** — if you want decade-old OSS marketing-automation
  - **Listmonk** — if you only need newsletters
  - **Choose Laudspeaker if:** you want visual-journey-builder + multi-channel + modern stack.
- **PROJECT HEALTH**: active + commercial-backed + Slack + docs. Strong.

## Links

- Repo: <https://github.com/laudspeaker/laudspeaker>
- Website: <https://laudspeaker.com>
- Cloud: <https://app.laudspeaker.com>
- Docs: <https://laudspeaker.com/docs>
- Dittofeed (alt — batch 106): <https://github.com/dittofeed/dittofeed>
- Mautic (alt): <https://github.com/mautic/mautic>
- Listmonk (alt): <https://github.com/knadh/listmonk>
