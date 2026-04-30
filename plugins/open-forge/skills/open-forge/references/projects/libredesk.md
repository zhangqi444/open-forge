---
name: Libredesk
description: "Modern OSS self-hosted omnichannel customer support desk. Live chat + email + more in single binary. Zerodha Tech. Go. Granular permissions + SLA + automations + CSAT + macros + auto-assignment + AI-assist + webhooks. libredesk.io."
---

# Libredesk

Libredesk is **"Zendesk / Freshdesk / Intercom — but OSS + single-binary + Zerodha-Tech-backed"** — a modern OSS self-hosted **omnichannel customer support desk**. **Live chat + email + more** in one inbox. Granular permissions (roles/teams/agents). Automations (auto-tag, assign, route). **CSAT surveys**. Macros. SLA management. Custom attributes. **AI-assist** (rewrite responses). Activity logs. Webhooks for integration. Written as single binary.

Built + maintained by **Abhinav (abhinavxd)** + **Zerodha Tech** (Zerodha is major Indian brokerage; Zerodha Tech = open-source arm, maintainer of **listmonk + kite-connect + ... **). License: check LICENSE. Active; libredesk.io website; demo at demo.libredesk.io.

Use cases: (a) **replace Zendesk** — for small/medium teams priced out (b) **single-binary support-desk** — easier ops than Kayako/osTicket (c) **GDPR-compliant support** — your data, your infra (d) **startup-customer-support** — growth-stage pre-Zendesk (e) **omni-channel unified inbox** — email + live-chat + more (f) **SLA-driven workflow** — ticket-escalation + tracking (g) **automation-heavy support-ops** — auto-assign + auto-tag (h) **multi-agent team** with granular-RBAC.

Features (per README):

- **Omnichannel inbox** (live chat + email + more)
- **Live chat widget** (embed on website)
- **Granular permissions** (custom roles, teams, agents)
- **Automations** (auto-tag, assign, route)
- **CSAT surveys**
- **Macros** (response templates)
- **Organization**: tags, custom statuses, snoozing, search
- **Auto-assignment** (by capacity / criteria)
- **SLA management** (response-time + escalation)
- **Custom attributes** (contacts, conversations)
- **AI-assist** (rewrite responses)
- **Activity logs** (audit)
- **Webhooks** (integrations)
- **Single binary**

- Upstream repo: <https://github.com/abhinavxd/libredesk>
- Website: <https://libredesk.io>
- Demo: <https://demo.libredesk.io>
- Zerodha Tech: <https://zerodha.tech>

## Architecture in one minute

- **Go** single binary (likely — Zerodha Tech style)
- **PostgreSQL** DB
- **Redis** (queue/cache)
- **Resource**: moderate — 200-500MB RAM
- **Port**: web UI + live-chat widget endpoint

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker Compose** | **Upstream**                                                    | **Primary**                                                                        |
| **Binary**         | Single Go binary                                                                            | Alt                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `support.example.com`                                       | URL          | TLS MANDATORY — customer-facing                                                                                    |
| Admin creds          | First-boot                                                  | Bootstrap    | Strong                                                                                    |
| PostgreSQL           | Data                                                        | DB           |                                                                                    |
| Redis                | Queue                                                       | Infra        |                                                                                    |
| Email (IMAP + SMTP)  | Ingest support mailboxes + send                             | Channels     |                                                                                    |
| Live-chat widget domain | Where widget embeds                                      | Config       |                                                                                    |
| Webhook URLs         | Integration endpoints                                                                                                  | Integration  |                                                                                    |
| AI provider (opt)    | For AI-assist (rewrite)                                     | AI           | **Data-exfil concern**                                                                                    |

## Install via Docker

Follow: <https://libredesk.io> (check README for docker-compose snippet)

```yaml
services:
  libredesk:
    image: libredesk/libredesk:latest        # **pin version**
    environment:
      DATABASE_URL: postgresql://libredesk:${DB_PASSWORD}@db:5432/libredesk
      REDIS_URL: redis://redis:6379
    volumes:
      - libredesk-data:/data
    ports: ["9000:9000"]
    depends_on: [db, redis]

  db:
    image: postgres:17
    environment:
      POSTGRES_DB: libredesk
      POSTGRES_USER: libredesk
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes: [pgdata:/var/lib/postgresql/data]

  redis:
    image: redis:7-alpine

volumes:
  libredesk-data: {}
  pgdata: {}
```

## First boot

1. Start stack → browse web UI
2. Create admin + enable MFA
3. Configure IMAP + SMTP for email-ingest
4. Embed live-chat widget on your site
5. Create first team + agents
6. Set up SLAs
7. Configure automation rules (auto-tag, auto-assign)
8. Test CSAT on a closed ticket
9. Put behind TLS reverse proxy
10. Back up DB

## Data & config layout

- PostgreSQL — all tickets, conversations, customers, macros, automations
- `/data/` — attachments, logs

## Backup

```sh
docker compose exec db pg_dump -U libredesk libredesk > libredesk-$(date +%F).sql
sudo tar czf libredesk-data-$(date +%F).tgz libredesk-data/
```

## Upgrade

1. Releases: <https://github.com/abhinavxd/libredesk/releases>. Active.
2. Docker pull + restart
3. DB migrations; read release notes

## Gotchas

- **111th HUB-OF-CREDENTIALS CROWN-JEWEL TIER 1 — CUSTOMER-SUPPORT-DATA**:
  - Customer-support platform holds: customer-PII + full-conversation-history + email-creds (IMAP/SMTP) + SSO-trust + live-chat-cookies
  - Compromise → conversations exposed + impersonation (phish-as-your-support) + customer-data leak
  - **111th tool in hub-of-credentials family — Tier 1 CROWN-JEWEL**
  - **NEW CROWN-JEWEL Tier 1 sub-category: "customer-support-desk-data-hub"** (1st — Libredesk)
  - **CROWN-JEWEL Tier 1: 30 tools / 27 sub-categories** 🎯 **30-TOOL MILESTONE**
- **LIVE-CHAT-WIDGET ON CUSTOMER-SITE**:
  - Widget loads from Libredesk
  - If compromised → malicious JS on all customer-sites
  - **Recipe convention: "embed-widget-on-customer-site trust-boundary" callout**
  - **NEW recipe convention** (Libredesk 1st formally)
- **EMAIL INGEST = IMAP CREDS**:
  - IMAP credentials for support@ mailboxes
  - Compromise = email-archive-exfiltration
  - **Recipe convention: "email-ingest-IMAP-creds-risk" callout**
  - **NEW recipe convention** (Libredesk 1st formally)
- **AI-ASSIST FOR RESPONSE-REWRITING**:
  - Customer messages may go to 3rd-party LLM
  - GDPR processor transfer concern
  - **LLM-feature-sends-data-externally: 4 tools** (EventCatalog+Spliit+Kite+Libredesk) 🎯 **4-TOOL MILESTONE**
  - Self-hosted LLM mitigates
- **CSAT SURVEYS = CUSTOMER-CONTACT**:
  - Email/SMS sent to customers
  - Legal: CAN-SPAM, TCPA, GDPR apply
  - **Recipe convention: "customer-survey-compliance" callout**
- **ACTIVITY LOGS = AUDIT TRAIL**:
  - Positive for compliance
  - Also: contains historical PII — need retention policy
  - **Recipe convention: "audit-log-retention-policy"** — standard
- **ZERODHA TECH BACKING = INSTITUTIONAL**:
  - Zerodha is major Indian brokerage; Zerodha Tech = OSS arm
  - **Also maintainers of**: listmonk (newsletter), kite-connect (trading), dungbeetle (batch processing), others
  - **Recipe convention: "commercial-company-with-strong-OSS-arm positive-signal"**
  - **NEW positive-signal convention** (Libredesk 1st formally; also applies retroactively to listmonk)
  - **NEW institutional-stewardship sub-tier: "commercial-company-with-OSS-arm"** (1st — Libredesk/Zerodha Tech)
- **SLA MANAGEMENT = ENTERPRISE-FEATURE**:
  - Response-time targets + escalation
  - Less common in OSS; enterprise-grade feature
  - **Recipe convention: "SLA-management positive-signal"**
  - **NEW positive-signal convention** (Libredesk 1st formally)
- **OMNICHANNEL COMPLEXITY**:
  - Email + chat + "more" = multi-channel coordination state
  - Session-continuity across channels = hard problem
  - **Recipe convention: "omnichannel-session-continuity-complexity" callout**
- **MACROS = COMPLIANCE RISK**:
  - Canned-responses can get outdated → wrong legal/compliance info sent
  - **Recipe convention: "macro-content-staleness-risk" callout**
  - **NEW recipe convention**
- **CUSTOMER-SUPPORT-CATEGORY:**
  - **Libredesk** — modern; single-binary; Zerodha Tech
  - **Chatwoot** — OSS; mature; more features; Ruby
  - **osTicket** — legacy PHP; mature
  - **Zammad** — Ruby; mature; EU
  - **FreeScout** — PHP; Laravel
  - **Kimai** (commercial reference: Zendesk, Freshdesk, Intercom, Help Scout)
- **INSTITUTIONAL-STEWARDSHIP**: abhinavxd + Zerodha Tech + community. **97th tool — commercial-company-with-OSS-arm sub-tier** (NEW).
- **TRANSPARENT-MAINTENANCE**: active + Zerodha-backed + demo + website + single-binary + docs. **105th tool in transparent-maintenance family.**
- **ALTERNATIVES WORTH KNOWING:**
  - **Chatwoot** — if you want mature OSS + more features + Ruby
  - **osTicket** — if you want mature legacy PHP
  - **Zammad** — if you want EU-based OSS support-desk
  - **Choose Libredesk if:** you want modern single-binary Go + granular-RBAC + SLA + AI-assist.
- **PROJECT HEALTH**: active + Zerodha Tech + modern-Go + demo + website. Strong.

## Links

- Repo: <https://github.com/abhinavxd/libredesk>
- Website: <https://libredesk.io>
- Demo: <https://demo.libredesk.io>
- Chatwoot (alt): <https://github.com/chatwoot/chatwoot>
- Zammad (alt): <https://github.com/zammad/zammad>
- osTicket (alt): <https://github.com/osTicket/osTicket>
- Zerodha Tech: <https://zerodha.tech>
