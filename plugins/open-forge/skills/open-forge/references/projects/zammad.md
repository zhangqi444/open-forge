---
name: Zammad
description: "Modern web-based open-source helpdesk / customer support platform — email, chat, telephone, social media, full ticketing workflow, SLAs, knowledge base, text modules, reporting. Owned by Zammad Foundation (independent of Zammad GmbH). Ruby on Rails + Vue. AGPL-3.0."
---

# Zammad

Zammad is **a modern open-source helpdesk / customer support platform** — think Zendesk or Freshdesk, but open source and self-hostable. Multi-channel ticketing: email, web forms, chat widget, telephone (CTI integrations), social media (Twitter/X, Facebook, WhatsApp, Telegram). Full ticket lifecycle with SLAs, escalation, knowledge base, canned responses ("text modules"), scheduler/triggers/automations, reporting/dashboards, time tracking, audit logs.

**Governance + commercial model** (noteworthy):

- Source code is **owned by the Zammad Foundation** — an **independent, non-profit foundation** separate from Zammad GmbH. This protects against "AWS-forks-Elastic" or "HashiCorp-changes-license" scenarios.
- **Zammad GmbH** is the commercial company — hosted cloud service + enterprise support + customers; their revenue funds development but doesn't own the IP.
- **License: AGPL-3.0** — stays open. Commercial relicensing by GmbH isn't possible without Foundation's approval.
- Pattern similar to Odoo/Mattermost's governance separation, but cleaner (Foundation-owned IP is rare).

Features:

- **Multi-channel** — email, web form, chat, phone (CTI), X/Twitter, Facebook, Telegram, WhatsApp Business, SMS
- **Ticketing** — states, priorities, owner/group assignment, tags, links, merge, split
- **SLAs** — first response, solution time, escalation workflows
- **Knowledge base** — customer-facing + internal, multi-language
- **Text modules** — canned responses with variables
- **Triggers + schedulers** — automations on ticket events + time
- **Overviews** — saved filter views per user/role
- **Reporting** — built-in dashboards + exportable
- **Time tracking** — billable hours per ticket
- **Customer portal** — self-service
- **REST API**
- **Multi-tenant** (sort of — one Zammad = one org; multi-org via Groups/Organizations)
- **i18n** — extensive (German origin; strong EU community)
- **SSO** — SAML/OIDC/OAuth/LDAP/Kerberos/Google/Microsoft/GitHub/...
- **CTI integrations** — Asterisk, Placetel, Sipgate, various providers
- **Audit log + GDPR workflows** — data subject access, deletion

- Upstream repo: <https://github.com/zammad/zammad>
- Website: <https://zammad.org> (community) + <https://zammad.com> (commercial)
- Foundation: <https://zammad-foundation.org>
- Docs: <https://docs.zammad.org>
- Helm chart: <https://artifacthub.io/packages/helm/zammad/zammad>
- Docker compose: <https://github.com/zammad/zammad-docker-compose>
- Forum: <https://community.zammad.org>

## Architecture in one minute

- **Ruby on Rails** backend + GraphQL + REST
- **Vue.js** modern frontend
- **PostgreSQL** — DB (primary; MySQL deprecated)
- **Elasticsearch** — full-text ticket search (**required** in production)
- **Redis** — caching + background jobs
- **Nginx** front-end
- **Resource**: small-to-medium: 4 GB RAM + 2 cores for ~20 agents; scales with tickets + ES indexing

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                         |
| ------------------ | -------------------------------------------------------------- | ----------------------------------------------------------------------------- |
| Single VM          | **Official DEB/RPM packages** via packager.io                      | **Upstream-recommended for production**                                           |
| Single VM          | **Docker Compose** (`zammad-docker-compose`)                               | Well-maintained                                                                           |
| Kubernetes         | **Official Helm chart**                                                                       | Production path; actively maintained                                                                                         |
| Managed            | **Zammad Cloud** (SaaS by Zammad GmbH)                                                                     | Paid hosted                                                                                                            |
| Raspberry Pi       | Not recommended — ES is heavy                                                                                             |                                                                                                                                            |

## Inputs to collect

| Input              | Example                              | Phase       | Notes                                                                  |
| ------------------ | ------------------------------------ | ----------- | ---------------------------------------------------------------------- |
| Domain             | `support.example.com`                    | URL         | **Mandatory HTTPS**                                                              |
| DB                 | Postgres 14+                                  | DB          | MySQL deprecated                                                                                 |
| Elasticsearch      | 7.x / 8.x                                             | Search      | Required — not optional                                                                                               |
| Redis              | bundled or external                                                | Cache       | Bundled in compose; external at scale                                                                                                         |
| Admin account      | first sign-up becomes admin                                                 | Bootstrap   | Strong password + 2FA                                                                                                                |
| SMTP in + out      | IMAP/POP3 for inbound; SMTP for outbound                                          | Email       | Core feature — test carefully                                                                                                                           |
| SSL cert           | Let's Encrypt                                                                                 | Security    | Via nginx                                                                                                                                                |
| Social integrations | Twitter API, Facebook, WhatsApp Business, Telegram bot tokens — per channel       | Channels    | Configure as needed                                                                                                                                                      |

## Install via Docker Compose

```sh
git clone https://github.com/zammad/zammad-docker-compose.git
cd zammad-docker-compose
# Edit docker-compose.override.yml — domain, secrets
docker compose up -d
# Wait for initial setup (5-10 min); watch logs
docker compose logs -f zammad-init
```

Browse `https://<host>/` → first-visit setup wizard → creates admin.

## Install via packages (production-recommended)

Follow <https://docs.zammad.org/en/latest/install/package.html> for your distro. Installs Zammad + PG + ES + Redis + Nginx as services.

## First boot

1. Setup wizard → organization name, admin account, email settings
2. Configure **inbound email** (IMAP/POP3) — tickets from email arrive here
3. Configure **outbound SMTP** — responses go out
4. Set up **groups** (teams) + **roles** + **users**
5. Enable channels you need (chat widget, Twitter, etc.)
6. Configure **triggers** + **schedulers** for automations
7. Build knowledge base articles
8. Integrate SSO (SAML/OIDC) for enterprise
9. Test end-to-end: send email to support address → ticket appears → reply → email sent

## Data & config layout

- **Package install**: `/opt/zammad/` app; Postgres + ES + Redis standard paths
- **Docker**: named volumes per service
- Attachments stored in DB (default) or filesystem (configurable) or S3

## Backup

```sh
# Postgres (CRITICAL — all tickets, users, config)
pg_dump -U zammad zammad_production | gzip > zammad-db-$(date +%F).sql.gz
# Attachments (if on filesystem)
sudo tar czf zammad-storage-$(date +%F).tgz /opt/zammad/storage
# Config
sudo tar czf zammad-etc-$(date +%F).tgz /etc/zammad /opt/zammad/config
```

Use Zammad's own backup script: `/opt/zammad/contrib/backup/zammad_backup.sh` (package install).

ES index can be rebuilt (`rake searchindex:rebuild`) — not required in backup.

## Upgrade

1. Releases: <https://github.com/zammad/zammad/releases>. Regular minors.
2. **Back up DB + attachments before every upgrade.**
3. Read release notes — major versions sometimes require Postgres/ES version bumps.
4. Packages: `apt upgrade zammad` — Zammad's package runs migrations + ES rebuild.
5. Docker: bump compose → `docker compose up -d` → init container runs migrations.
6. Test on staging for major version jumps.

## Gotchas

- **Elasticsearch is not optional.** Production Zammad requires ES. If ES is missing/unhealthy → searches broken, performance degrades. Monitor ES health alongside Zammad.
- **PostgreSQL, not MySQL**: MySQL is deprecated. New installs must use Postgres. Migration docs exist for legacy MySQL users.
- **Resource footprint**: ES alone wants 2 GB+ RAM. Underprovisioning = slow tickets + timeout errors. Plan 4+ GB RAM + 2 cores for even small teams.
- **Email deliverability**: Zammad sends outbound email for ticket responses; if SMTP is misconfigured or IP has poor reputation, customer-facing emails land in spam. Use transactional SMTP provider (SendGrid/Mailgun/SES/AWS SES) for reliability.
- **IMAP polling**: inbound email is pulled via IMAP — delay between email arrival and ticket creation is 1-5 min typical. For faster, use catch-all direct-forward to Zammad's API.
- **Channels complexity**: each social channel (Twitter/X, Facebook, WhatsApp) has its own API terms + tokens + limits. Twitter especially volatile post-2023 API changes. Check current integration status.
- **WhatsApp Business API**: commercial offering (Meta charges per conversation); configure carefully.
- **Knowledge base permissions**: public + internal + role-restricted articles. Audit before making public — accidentally public KB can leak internal info.
- **GDPR**: Zammad has data-subject-request tooling; configure retention + anonymization per policy. Strong EU roots mean good GDPR tooling.
- **SLAs**: configure carefully — wrongly-configured SLAs miss alerts or spam. Test with synthetic tickets.
- **Triggers + escalation**: automations can cascade; test in staging before enabling in prod.
- **Audit log**: enable + monitor — required for SOC 2 / ISO 27001.
- **Multi-tenancy**: Zammad uses Organizations + Groups to separate client data but remains single-DB. True multi-tenant (hard isolation) = multiple Zammad instances.
- **Upgrade downtime**: migrations can take minutes-to-hours on large DBs. Schedule maintenance windows.
- **Foundation-owned IP**: comfort signal for long-term license stability.
- **Commercial**: Zammad Cloud + paid support from Zammad GmbH — use if you don't want to operate ES/PG yourself. Pricing: <https://zammad.com/en/pricing>.
- **License**: **AGPL-3.0**.
- **Alternatives worth knowing:**
  - **OTRS / Znuny** (Znuny = OTRS community fork) — Perl-based, older, mature
  - **osTicket** — PHP, simpler, popular
  - **GLPI** (batch 69) — ITSM + CMDB + tickets, broader scope
  - **Freshdesk / Zendesk / HelpScout** — commercial SaaS
  - **FreeScout** — free/open Help Scout clone; PHP
  - **UVdesk** — open-source helpdesk; PHP/Symfony
  - **Faveo** — open-source + commercial editions
  - **HelpDeskZ** — simpler PHP
  - **Choose Zammad if:** multi-channel support + modern UI + foundation-owned IP + AGPL comfort + mid-to-large teams.
  - **Choose osTicket / FreeScout if:** email-only, simpler, smaller team.
  - **Choose GLPI if:** ITSM + CMDB + tickets as part of IT management.
  - **Choose Zendesk/Freshdesk if:** commercial SaaS acceptable.

## Links

- Repo: <https://github.com/zammad/zammad>
- Community site: <https://zammad.org>
- Commercial: <https://zammad.com>
- Foundation: <https://zammad-foundation.org>
- Docs: <https://docs.zammad.org>
- Docker compose: <https://github.com/zammad/zammad-docker-compose>
- Helm chart: <https://artifacthub.io/packages/helm/zammad/zammad>
- Packages: <https://packager.io/gh/zammad/zammad/refs/stable>
- Forum: <https://community.zammad.org>
- Releases: <https://github.com/zammad/zammad/releases>
- Pricing (Cloud): <https://zammad.com/en/pricing>
- OTRS / Znuny (alt): <https://www.znuny.com>
- osTicket (alt): <https://osticket.com>
- FreeScout (alt): <https://freescout.net>
- GLPI (batch 69): <https://github.com/glpi-project/glpi>
