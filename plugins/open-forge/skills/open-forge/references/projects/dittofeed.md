---
name: Dittofeed
description: "Open-source customer engagement platform (email/SMS/push/WhatsApp/Slack). Broadcasts + automated journeys + segments + MJML templates. Segment/ETL integrations. Open-core with licensed enterprise features. MIT on OSS core; active."
---

# Dittofeed

Dittofeed is **"OneSignal / Customer.io / Segment Engage / Braze — but open-source + self-hosted"** — an omni-channel customer-engagement + messaging platform. Send broadcasts OR create automated user-journeys along email + mobile push + SMS + **WhatsApp** + **Slack** + more. Integrate user data via **Segment** or **Reverse ETL** or **Dittofeed API**. Build highly-customizable user segments; design messages in HTML/MJML or low-code editor; track + analyze performance; **embed in your own app via iframe or headless React component**.

Built + maintained by **Dittofeed team** (commercial-tier: multi-tenancy + embedding + white-labeling sold as licensed closed-source). License: **MIT on OSS core** (verify); closed-source extensions. Active; Docker Compose install; Discord community; commercial-cloud at app.dittofeed.com.

Use cases: (a) **self-hosted customer-messaging** — replace paid SaaS ($$$/mo for 10k+ users) (b) **marketing automation** — drip campaigns, onboarding flows, re-engagement (c) **transactional + marketing unified** — single platform for welcome + receipt + newsletter (d) **journey-builder** — event-triggered multi-step flows (e) **Segment replacement** — ingest events via Segment-compatible API (f) **multi-channel campaigns** — email + SMS + push + WhatsApp in one journey (g) **embed in your own SaaS** — white-label customer-messaging for your users (h) **developer-first dev workflow** — APIs + Git-managed templates.

Features (per README):

- **Broadcasts + journeys** — one-off + automated
- **Multi-channel**: email, SMS, mobile-push, WhatsApp, Slack, more
- **Segmentation** — multi-operator user-segments
- **Template editor** — HTML/MJML or low-code
- **Segment + Reverse ETL + API** user-data ingestion
- **ESP integrations** — Sendgrid, Amazon SES, Postmark, Resend
- **Analytics dashboard**
- **Embed tools** via iframe or headless React (commercial tier)

- Upstream repo: <https://github.com/dittofeed/dittofeed>
- Website: <https://dittofeed.com>
- Cloud: <https://app.dittofeed.com>
- Docs: <https://docs.dittofeed.com>
- Local dev: <https://docs.dittofeed.com/contributing/running-locally>
- Discord: <https://discord.gg/HajPkCG4Mm>

## Architecture in one minute

- **TypeScript / Node.js** stack
- **ClickHouse** — event analytics
- **PostgreSQL** — metadata
- **Temporal** — workflow engine for journeys
- **Kafka** (via Redpanda) — event streaming
- **Resource**: HEAVY — 4-8GB RAM recommended (ClickHouse + Temporal + Kafka + Postgres + Node services)
- **Multi-service architecture** — significant ops burden

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker Compose** | **Upstream compose**                                            | **Primary**                                                                        |
| **Helm / K8s**     | Production-scale                                                                            | Typical for enterprise                                                                                   |
| Cloud              | app.dittofeed.com commercial                                                                                                             | Hosted                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `engage.example.com`                                        | URL          | TLS MANDATORY                                                                                    |
| DB                   | PostgreSQL 13+                                              | DB           |                                                                                    |
| ClickHouse           | Event-analytics                                             | DB           |                                                                                    |
| Kafka / Redpanda     | Event stream                                                | Queue        |                                                                                    |
| Temporal             | Workflow engine                                             | Workflow     |                                                                                    |
| **ESP creds**        | Sendgrid / SES / Postmark / Resend                          | **CRITICAL** | **Outbound mass-email**                                                                                    |
| **SMS creds**        | Twilio / MessageBird                                                                                    | Integration  |                                                                                    |
| **WhatsApp Business API** | Meta Business                                                                                                 | Integration  | BSP-mediated                                                                                    |
| Slack bot            | For Slack-channel messaging                                                                                                            | Integration  |                                                                                                                                            |
| Admin creds          | First-boot                                                                                                            | Bootstrap    | Strong                                                                                                            |

## Install via Docker Compose

```sh
git clone https://github.com/dittofeed/dittofeed.git
cd dittofeed
docker compose up -d
# See docs for full config
```

## First boot

1. Deploy full stack (may take several minutes)
2. Browse admin UI
3. Connect ESP (Sendgrid/SES/Postmark)
4. Create user-data source (Segment integration OR direct API)
5. Design first template (MJML or low-code)
6. Define first segment
7. Create first broadcast OR journey
8. Send test message to yourself
9. Enable analytics + tracking
10. Back up Postgres + ClickHouse

## Data & config layout

- PostgreSQL — workflows, journeys, templates, segments
- ClickHouse — event analytics (large-volume)
- Kafka/Redpanda — event-stream buffers
- Temporal — workflow state

## Backup

```sh
docker compose exec postgres pg_dump -U dittofeed dittofeed > dittofeed-$(date +%F).sql
# ClickHouse backups: use clickhouse-backup tool OR snapshot volumes
# Temporal: state in Postgres (depends on config)
```

## Upgrade

1. Releases: <https://github.com/dittofeed/dittofeed/releases>. Active.
2. Multi-service = coordinated upgrade; check CHANGELOG
3. Back up BEFORE

## Gotchas

- **CUSTOMER-ENGAGEMENT = HIGHEST-STAKES CROWN-JEWEL**:
  - Full contact list + communication preferences + event timeline + message history per-user
  - ESP creds = outbound-email-ability-to-your-whole-list
  - Misconfigured segment → send to 10k wrong people → reputation damage + GDPR violation
  - **86th tool in hub-of-credentials family — Tier 1 CROWN-JEWEL**
  - **Sub-category "marketing/brand" reinforced** (earlier: Mixpost/MediaManager/etc.) — now Dittofeed is 5+ tool in marketing crown-jewel
  - **Marketing/brand CROWN-JEWEL sub-category: 5+ tools**
  - **CROWN-JEWEL Tier 1: 22 tools; 19 sub-categories**
- **GDPR/CAN-SPAM/PECR COMPLIANCE**:
  - Marketing to EU = GDPR explicit-consent required
  - US: CAN-SPAM requires unsubscribe + physical address
  - EU ePrivacy (PECR) = electronic-communications-specific rules
  - Suppression-list management (unsubscribed + bounced + complained)
  - **Recipe convention: "marketing-compliance-suppression-list" callout**
  - **NEW recipe convention** (Dittofeed 1st formally for marketing-tools)
- **ESP REPUTATION + DELIVERABILITY**:
  - Mass-sending from new domain → low deliverability (spam-folder)
  - Warm-up schedules + proper SPF/DKIM/DMARC + BIMI + list-hygiene
  - **Recipe convention: "email-sending-reputation-warmup" callout**
  - **NEW recipe convention**
- **OPEN-CORE + CLOSED-SOURCE COMMERCIAL TIER**:
  - README explicit: multi-tenancy + embedding + white-labeling sold as licensed closed-source
  - **Commercial-tier-taxonomy: "open-core-with-licensed-closed-source-extensions"** — distinct from EspoCRM's "open-core-with-commercial-extensions" because Dittofeed's extensions are licensed-but-not-open
  - **NEW sub-category: "open-core-with-licensed-closed-source-extensions"** — 1st tool named (Dittofeed)
  - Care required: don't accidentally build on closed-source tier assumption
- **HEAVY MULTI-SERVICE ARCHITECTURE**:
  - Postgres + ClickHouse + Kafka/Redpanda + Temporal + Node services
  - 4-8GB RAM minimum
  - Operational complexity = HIGH
  - **Recipe convention: "microservice-complexity-tax"** extended — now 4+ tools (Stoat + Peppermint + Convoy + Dittofeed)
- **TEMPORAL-BASED WORKFLOWS**:
  - Temporal = mature workflow engine
  - Positive: durable execution, retries, visibility
  - Negative: operational + learning curve
  - **Recipe convention: "Temporal-workflow-engine" positive-signal**
  - **NEW positive-signal convention**
- **CLICKHOUSE FOR EVENT-ANALYTICS**:
  - ClickHouse = columnar DB designed for analytics
  - Positive: fast aggregations on event-data
  - Negative: additional ops burden + learning curve
  - **Recipe convention: "ClickHouse-for-event-analytics" positive-signal**
  - **NEW positive-signal convention**
- **MJML EMAIL-TEMPLATING**:
  - MJML = standard for responsive-email-templates
  - Renders to standards-compliant HTML
  - **Recipe convention: "MJML-email-templates positive-signal"**
  - **NEW positive-signal convention**
- **SEGMENT-COMPATIBLE API**:
  - Accept events via Segment-compatible ingestion
  - Reduces migration barrier from Segment
  - **Recipe convention: "vendor-compatible-ingestion-API" positive-signal**
- **EVENT-PIPELINE OVERLAP WITH CONVOY (105)**:
  - Dittofeed ingests events for segmentation
  - Convoy routes events as webhooks
  - Different use-cases but similar event-streaming DNA
- **HUB-OF-CREDENTIALS TIER 1 DENSITY**:
  - ESP creds (Sendgrid/SES/Postmark)
  - SMS creds (Twilio/etc.)
  - WhatsApp Business API tokens (BSP)
  - Slack bot token
  - Segment integration secret
  - All customer PII
  - Suppression/preference state
- **INSTITUTIONAL-STEWARDSHIP**: Dittofeed commercial-team + Discord-community. **72nd tool — founder-with-commercial-tier-funded-development sub-tier.**
- **TRANSPARENT-MAINTENANCE**: active + cloud + Discord + docs + open-core + commercial-tier. **80th tool in transparent-maintenance family** 🎯 **80-TOOL MILESTONE.**
- **CUSTOMER-ENGAGEMENT-CATEGORY:**
  - **Dittofeed** — OSS + commercial tier
  - **Mautic** — OSS PHP; marketing-automation; older
  - **Listmonk** — OSS newsletter focus
  - **Customer.io / Braze / Iterable / OneSignal** (commercial)
  - **Segment + Iterable combo** (commercial stacked)
  - **Knock** — OSS notifications infrastructure
  - **NotificationAPI / Courier** (commercial notification-as-a-service)
- **ALTERNATIVES WORTH KNOWING:**
  - **Mautic** — if you want PHP + mature OSS + marketing-first
  - **Listmonk** — if you want newsletter-only + simple + Go
  - **Knock** — if you want notifications-infrastructure layer
  - **Commercial**: if you don't want to self-host the multi-service stack
  - **Choose Dittofeed if:** you want TS stack + journeys + OSS core + enterprise extension options.
- **PROJECT HEALTH**: active + multi-service + Discord + commercial-tier + docs. Strong.

## Links

- Repo: <https://github.com/dittofeed/dittofeed>
- Docs: <https://docs.dittofeed.com>
- Website: <https://dittofeed.com>
- Cloud: <https://app.dittofeed.com>
- Discord: <https://discord.gg/HajPkCG4Mm>
- Mautic (alt PHP): <https://www.mautic.org>
- Listmonk (alt newsletter): <https://listmonk.app>
- Knock (alt OSS): <https://knock.app>
- Customer.io (commercial alt): <https://customer.io>
- OneSignal (commercial alt): <https://onesignal.com>
