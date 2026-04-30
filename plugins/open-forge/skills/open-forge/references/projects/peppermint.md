---
name: Peppermint
description: "Self-hosted ticket management + help desk. Multi-tenant, markdown tickets, customer portal, notebook with todos. Node.js + PostgreSQL. AGPL-3.0 (verify). Backed by DigitalOcean (open-source credits). Active; beta-version 0.2.x."
---

# Peppermint

Peppermint is **"Zendesk / Freshdesk / Jira Service Management — self-hosted + simple + modern"** — a ticket management + help desk solution for internal IT, customer support, managed service providers, and agencies. Create tickets via web portal / email; track client-history; attach files; mark as internal; use the built-in notebook for todos; responsive UI works mobile to 4k; docker + pm2 deployment options. Still in 0.2.x (beta) with active development trajectory.

Built + maintained by **Peppermint-Lab** (jwandrews99 founder) + DigitalOcean-sponsored credits. License: check repo. Active; Docker Hub; DigitalOcean OSS-partner badge; community-contributor-welcoming.

Use cases: (a) **internal IT helpdesk** — employees submit tickets for laptop/access/software issues (b) **external customer support** — external portal for customer issues (c) **managed services provider** — ticket-per-client; track resolution times + billable hours (d) **escape Zendesk costs** ($19-99/mo/agent) for small teams (e) **agency project-ticket-tracking** — layered on top of project-mgmt tools (f) **notebook with todos** alongside tickets — lightweight PKM (g) **beta-aware small-team adopter** — willing to deploy 0.2.x in exchange for ownership.

Features (from upstream README):

- **Ticket creation** with markdown editor + file uploads
- **Client-history logs**
- **Markdown-based notebook with todo lists**
- **Responsive design** (mobile to 4K)
- **Docker + pm2 deployments**
- **Simple workflow**

- Upstream repo: <https://github.com/Peppermint-Lab/peppermint>
- Docker: <https://hub.docker.com/r/pepperlabs/peppermint>

## Architecture in one minute

- **Node.js** backend + frontend
- **PostgreSQL** — DB
- **Resource**: moderate — 300-500MB RAM
- **Ports 3000 + 5003** (web + API)

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker compose** | **`pepperlabs/peppermint:latest` + postgres**                   | **Primary**                                                                        |
| pm2                | Node process manager                                                      | Bare-metal                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `support.example.com`                                       | URL          | TLS MANDATORY                                                                                    |
| DB                   | PostgreSQL                                                  | DB           |                                                                                    |
| `SECRET`             | Session/JWT signing                                                                                    | **CRITICAL** | **IMMUTABLE; README shows `'peppermint4life'` — CHANGE IT**                                                                                    |
| Admin creds          | First-boot                                                                                 | Bootstrap    | Strong                                                                                    |
| SMTP                 | Email-to-ticket + notifications                                                                                  | Email        | Core to helpdesk workflow                                                                                                            |
| Client portal access | Public or invite-only                                                                                                            | Policy       | Public portal = more spam                                                                                                                            |

## Install via Docker

```yaml
services:
  peppermint_postgres:
    container_name: peppermint_postgres
    image: postgres:17     # **pin**; readme says `:latest` — pin in prod
    restart: always
    volumes:
      - pgdata:/var/lib/postgresql/data
    environment:
      POSTGRES_USER: peppermint
      POSTGRES_PASSWORD: ${DB_PASSWORD}     # **don't use the default `1234` from readme**
      POSTGRES_DB: peppermint

  peppermint:
    container_name: peppermint
    image: pepperlabs/peppermint:latest     # **pin version**
    ports: ["3000:3000", "5003:5003"]
    restart: always
    depends_on: [peppermint_postgres]
    environment:
      DB_USERNAME: "peppermint"
      DB_PASSWORD: ${DB_PASSWORD}
      DB_HOST: "peppermint_postgres"
      SECRET: ${SECRET}                     # **CHANGE from readme default `peppermint4life`**

volumes:
 pgdata:
```

## First boot

1. Start → browse `http://host:3000`
2. Register first admin
3. Configure SMTP for email notifications + email-to-ticket
4. Create first ticket
5. Invite team members
6. Configure customer portal (public or invite-only)
7. Put behind TLS reverse proxy
8. Back up DB

## Data & config layout

- Postgres volume — tickets, users, clients, notebook content, attachments
- Attachments — inside DB or filesystem; verify upstream behavior + storage planning

## Backup

```sh
docker compose exec peppermint_postgres pg_dump -U peppermint peppermint > peppermint-$(date +%F).sql
```

## Upgrade

1. Releases: <https://github.com/Peppermint-Lab/peppermint/releases>. Active.
2. Docker: pull + restart; migrations auto-run.
3. **0.2.x indicates pre-1.0 — expect breaking changes** + test upgrades in staging.
4. Back up BEFORE ALL upgrades.

## Gotchas

- **README DEFAULT CREDS ARE DANGEROUS**:
  - README's sample compose shows `POSTGRES_PASSWORD: 1234` + `SECRET: 'peppermint4life'`
  - **DO NOT run with these defaults in any production setup**
  - Change both before first boot; use env-file with strong secrets
  - **8th tool in default-creds-risk class** (reinforces earlier pattern)
- **LICENSE CHECK**: README doesn't clearly state license. Docker pulls badge + public repo imply open source; verify LICENSE file before commercial use (LICENSE-file-verification-required convention — MediaManager 97, Zipline 98, Vito 99 precedents).
- **HELPDESK TICKETS = SENSITIVE CUSTOMER DATA**:
  - Customer PII (name, email, phone)
  - Internal workflow notes (possibly about specific people / issues)
  - Password reset requests (may include old passwords, social engineering context)
  - Complaint details (potentially legal-exposing)
  - Billing info (if ticket-to-invoice)
  - **50th tool in hub-of-credentials family — Tier 2 with customer-PII-density warning**
  - **GDPR Art-6 lawful basis**: typically contract or legitimate interest
  - **Data-retention policy** for closed tickets — mandatory under GDPR
  - **DSAR flow** — customer can request copy or deletion
  - **Recipe convention: "data-collection-tool regulatory-framework"** (OpnForm 95 precedent) applies to all customer-data-collecting tools.
- **EMAIL-TO-TICKET = SPAM VECTOR**: if emails become tickets automatically:
  - Spam email floods ticket queue
  - Phishing attempts arrive as tickets
  - **Mitigation**: email filters before ticket creation; ignore-patterns; Captcha on submit form
- **ATTACHMENT UPLOADS = SAME RISK AS ZIPLINE/FILE-HOSTS**: users attach files to tickets; attackers can use this to upload malware + phishing content. Less public than Zipline (usually authenticated) but non-zero.
- **PUBLIC CUSTOMER PORTAL** — careful design:
  - Signup-required vs open submission
  - Rate-limiting
  - Captcha
  - XSS protection in ticket content rendering
  - **Markdown rendering = XSS-adjacent** (Opengist 98 precedent)
- **DIGITALOCEAN OSS SPONSORSHIP**: Peppermint appears in DigitalOcean's open-source credits program. Positive signal of ecosystem-support but doesn't imply DigitalOcean involvement in development. **Recipe convention: "sponsor-credit signal"** — cloud-provider-sponsored-credits is a form of commercial backing without equity involvement.
- **BETA-STATUS 0.2.x**: expect breaking changes + occasional bugs. Back up religiously; pin versions; test upgrades.
- **SECRET IMMUTABILITY**: **37th tool in immutability-of-secrets family.**
- **SOLE-MAINTAINER-WITH-COMMUNITY**: jwandrews99 + DigitalOcean credits + community. **21st tool in sole-maintainer-with-community class.**
- **INSTITUTIONAL-STEWARDSHIP**: Peppermint-Lab org + DigitalOcean sponsorship. **35th tool in institutional-stewardship — sole-maintainer-with-sponsor-credits sub-tier** (1st explicit; variant of sole-maintainer-with-visible-sponsor-support but specifically cloud-provider-credits rather than GitHub-Sponsors+BMC).
- **TRANSPARENT-MAINTENANCE**: active commits + Docker Hub metrics + DigitalOcean-credit-sponsor + active community. **42nd tool in transparent-maintenance family.**
- **SUSTAINABILITY**: DigitalOcean credits help with hosting but don't fund maintainer. Project relies on sole-maintainer energy + community contribution.
- **HELPDESK-CATEGORY**:
  - **osTicket** (batch 89) — mature PHP
  - **Zammad** — Ruby + Node; more-featured
  - **FreeScout** — Help Scout alternative; Laravel
  - **Helpy.io** — older but functional
  - **UVdesk** — PHP Symfony-based
  - **ERPNext/Frappe Helpdesk** — integrated with broader ERP
  - **Mautic** — marketing automation with ticket-adjacent features
  - **Chatwoot** — Slack-like customer-support; different shape
  - **Jira Service Management** — commercial; enterprise
  - **Zendesk / Freshdesk / HelpScout / Intercom** — commercial SaaS
- **ALTERNATIVES WORTH KNOWING:**
  - **FreeScout** — closest match: modern + Laravel + AGPL
  - **Zammad** — more-feature-rich; heavier stack
  - **osTicket** — matter; PHP; mature
  - **Chatwoot** — for chat-first rather than email-first
  - **Choose Peppermint if:** you want Node + simple + beta-acceptable + modern + DigitalOcean-aligned.
  - **Choose FreeScout if:** you want Laravel + AGPL + Help-Scout-parity + more mature.
  - **Choose Zammad if:** you want polished + feature-rich + Ruby + still-OSS.
  - **Choose Chatwoot if:** chat-first rather than email-first.
  - **Choose osTicket if:** you want classical + PHP + proven.
- **PROJECT HEALTH**: active + beta-version + DigitalOcean sponsored-credits. Sustainability + 1.0-release trajectory worth monitoring.

## Links

- Repo: <https://github.com/Peppermint-Lab/peppermint>
- Docker: <https://hub.docker.com/r/pepperlabs/peppermint>
- FreeScout (alt): <https://freescout.net>
- Zammad (alt): <https://zammad.com>
- osTicket (alt, batch 89): <https://osticket.com>
- Chatwoot (chat-first alt): <https://www.chatwoot.com>
- ERPNext Helpdesk (integrated alt): <https://erpnext.com>
- Zendesk (commercial alt): <https://www.zendesk.com>
- Freshdesk (commercial alt): <https://freshdesk.com>
- HelpScout (commercial alt): <https://www.helpscout.com>
