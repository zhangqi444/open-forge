---
name: osTicket
description: "Widely-used open-source customer support ticket system. PHP + MySQL. Integrates email + phone + web-form inquiries into a multi-user web interface. Long-running project. GPL-2.0. Commercial support available."
---

# osTicket

osTicket is **"the GPL-licensed Zendesk of the PHP era"** — an open-source support ticket system that's been running since mid-2000s, serving small businesses + educational institutions + nonprofits + many internal IT help-desks. Mature + stable + still maintained. Integrates email + phone + web-form inquiries into a multi-user web interface with queues, assignment, SLA tracking, macros, knowledge-base articles, and customer portal.

Built + maintained by **Enhancesoft / osTicket org** (Enhancesoft is the commercial company behind osTicket). **GPL-2.0**. Commercial cloud offering + commercial support available at osticket.com. PHP 8.2-8.4 + MySQL 5.5+.

Use cases: (a) **SMB customer support** ticketing (b) **IT help-desk** — internal ticket flow (c) **nonprofit / educational** support portal (d) **commercial Zendesk alternative** for cost-sensitive ops (e) **multi-department ticket routing** (f) **SLA tracking + reporting**.

Features:

- **Multi-channel intake**: email, phone (recorded), web form, API
- **Assignment + queues**: round-robin, manual, by department
- **Agent collaboration**: internal notes, ticket transfer, watchers
- **Canned responses / macros**
- **Knowledge base + FAQ** — public or internal
- **Customer portal** for self-service
- **SLA tracking + alerts + escalation**
- **Custom forms + fields** per ticket type
- **Reports + analytics**
- **Email piping**: inbound email → auto-create ticket
- **Multi-language** (40+ languages)
- **Multi-tenancy** via department segregation
- **API** for integrations

- Upstream repo: <https://github.com/osTicket/osTicket>
- Homepage: <https://osticket.com>
- Cloud offering: <https://osticket.com/cloud-hosting/>
- Docs: <https://docs.osticket.com/>
- Commercial support: <https://osticket.com/support/>
- Forum: <https://forum.osticket.com/>

## Architecture in one minute

- **PHP 8.2-8.4** (8.4 recommended)
- **MySQL 5.5+** (or MariaDB)
- **mysqli extension** required
- **Apache / nginx / IIS**
- **Recommended PHP extensions**: ctype, fileinfo, gd, gettext, iconv, imap, intl, json, mbstring, OPcache, phar, xml, zip
- **APCu** recommended for caching
- **Resource**: light — 256-512MB RAM; DB modest; scales with ticket volume

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Manual deploy      | **Git clone + `php manage.php deploy --setup /var/www/htdocs/osticket/`** | **Upstream-documented path**                                                   |
| Tarball download   | Release zip → unpack → configure                                          | Classic LAMP install                                                                       |
| Docker             | Community images: `campbellsoftwaresolutions/osticket`, `tiredofit/docker-osticket`     | No upstream-official Docker                                                                           |
| Shared hosting     | Works on any LAMP shared host                                                                   | Historic strength                                                                                      |
| osticket.com cloud | Upstream commercial SaaS                                                                                 | Paid, no self-host                                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `support.example.com`                                       | URL          | TLS mandatory                                                                                    |
| DB                   | MySQL/MariaDB dedicated                                     | DB           | UTF-8mb4 recommended                                                                                    |
| Admin user + password | At installer                                                         | Bootstrap    | **Strong password**                                                                                    |
| Email ingestion       | IMAP/POP3 account for inbound tickets                                              | Integration  | Email → ticket auto-create                                                                                                      |
| SMTP                 | For outbound ticket replies + notifications                                                       | Outbound     | Required for ticketing flow                                                                                                              |
| Custom domain for customer portal   | e.g., support.example.com (same as admin or separate)                                                                             | URL          | Can share host                                                                                                                                      |

## Install (upstream-documented path)

```sh
git clone https://github.com/osTicket/osTicket
cd osTicket
php manage.php deploy --setup /var/www/htdocs/osticket/
# Configure web server to serve /var/www/htdocs/osticket/
# Browse and run installer; it will guide you through DB connection, admin creation, etc.
# After completion: DELETE setup/ folder
```

## First boot

1. Browse `https://support.example.com/`
2. Installer wizard: DB connection + admin creds
3. **Change admin password from any default on first login**
4. Configure incoming email (IMAP/POP3) + outgoing SMTP
5. Create departments + agents + staff groups
6. Define ticket forms + custom fields per department
7. Configure SLAs + escalation rules
8. Build initial Knowledge Base articles
9. **DELETE `/var/www/htdocs/osticket/setup/` folder** (security)
10. Put behind TLS reverse proxy
11. Back up DB + attachment storage

## Data & config layout

- `include/ost-config.php` — DB credentials (or env vars)
- `include/` — core code (don't modify)
- `attachments/` — uploaded files attached to tickets (LARGE over time)
- `scp/` — staff control panel
- **MySQL** — all tickets, users, agents, KB, SLAs, configuration

## Backup

```sh
# DB
mysqldump -uosticket -p${DB_PASSWORD} osticket > osticket-$(date +%F).sql
# Attachments (grows over time)
sudo tar czf osticket-attachments-$(date +%F).tgz attachments/
# Config
cp include/ost-config.php ost-config-$(date +%F).php
```

## Upgrade

1. Releases: <https://github.com/osTicket/osTicket/releases>. Active but slow cadence.
2. Upstream path: `git pull && php manage.php deploy -v /var/www/htdocs/osticket/` then browse to trigger DB migration.
3. Upgrade guide: <https://docs.osticket.com/en/latest/Getting%20Started/Upgrade%20and%20Migration.html>
4. **Back up DB + attachments + codebase BEFORE upgrading**. Major versions = schema changes.

## Gotchas

- **`setup/` folder DELETION MANDATORY after install** — leaving it exposes the install wizard which CAN BE REUSED to overwrite admin credentials or wipe the DB. Same class as WordPress `install.php` caution. **Post-install checklist item: verify `setup/` is deleted.**
- **IMAP for email ingestion** requires careful config:
  - IMAP over IMAPS (TLS) only — never plaintext IMAP
  - Use dedicated IMAP account (tickets@) not a shared inbox
  - Rate-limit ingestion if bombarded
  - **Watch for backscatter** — replying to tickets from forged senders = spam backscatter risk
- **EMAIL DELIVERABILITY**: support ticketing → sending lots of outbound mail. **SPF + DKIM + DMARC MANDATORY** to avoid being marked as spam. Same operational discipline as FreeScout (batch 81), any-mail-sending-tool.
- **Ticket storage grows indefinitely**: each ticket + all replies + attachments accumulates. For a busy helpdesk, DB grows GB-scale over years. Plan archive/purge policy.
- **GDPR + data-retention** for customer support: tickets contain customer PII + sometimes sensitive info (support requests often include screenshots with data). **Data-retention policy + right-to-erasure implementation** required if EU customers. osTicket has deletion features; use them as part of a process.
- **Attachment security**: tickets can include arbitrary file attachments. **Scan for malware** (ClamAV integration or external scanner in your reverse proxy) BEFORE agents open attachments. A tech-support ticket claiming "here's my resume.pdf.exe" is the classic attack vector.
- **Custom fields + forms = template-design discipline**: osTicket's custom-field flexibility is powerful + can create mess if not planned. Agree on schema with support team before building 50 ad-hoc fields.
- **Agent onboarding / offboarding**: each agent has a login + potentially broad DB access. **Disable-on-offboarding checklist**: depart → disable-login → reassign-open-tickets → audit-their-actions-in-logs. Standard HR+IT practice.
- **Hub-of-credentials**: osTicket stores agent passwords + IMAP/POP3 password + SMTP password + integration API keys. **16th tool in hub-of-credentials family, LIGHT-to-MID tier.** Especially IMAP password (gateway to all historical support email) = treat as crown-jewel.
- **No upstream-official Docker image**: community images exist but vary in quality. Check freshness + maintainer trust.
- **PHP version drift**: osTicket 1.18+ requires PHP 8.2+. Older servers with PHP 7.4 won't run current osTicket. Plan PHP upgrades.
- **MySQL > MariaDB compat**: generally works; MySQL-specific SQL quirks occasionally bite edge cases. Test upgrades in staging.
- **Legacy codebase**: PHP patterns show the project's 15+-year history. Modernization ongoing but some endpoints use classic PHP patterns. Not a security problem per se but contributors should read the code carefully.
- **Plugin ecosystem** exists but is smaller than WordPress-class. Official marketplace at osticket.com/plugins. **Same plugin-as-RCE warning** (Shaarli/Piwigo/pyLoad) — only official plugins + trusted community sources.
- **Commercial-tier: "primary-OSS with commercial SaaS + commercial support"**: osTicket primary product is OSS; commercial cloud hosting + commercial paid support tiers fund ongoing dev. Classic healthy-OSS-business-model. Not the same as Feedbin (primary-SaaS); osTicket is primary-OSS + commercial-support.
- **Multi-tenancy**: department-based segregation is NOT true multi-tenancy (one DB, one admin). If you need true tenant isolation, deploy separate osTicket instances per customer-org.
- **Alternatives worth knowing:**
  - **FreeScout** (batch 81) — Laravel + MySQL; modern UI; email-first; growing community
  - **Zammad** — Ruby; modern; commercial+OSS; feature-rich
  - **UVdesk** — Symfony + Node.js; modern
  - **Faveo** — Laravel; OSS+commercial
  - **Chatwoot** — Ruby; live-chat-focused + ticketing
  - **Zendesk / Freshdesk** — commercial SaaS (the market leaders)
  - **Jira Service Management** — commercial (Atlassian-ecosystem)
  - **Request Tracker (RT)** — Perl; long-running; power-user/ISP class
  - **Choose osTicket if:** you want mature + GPL + LAMP-stack-friendly + long-history + commercial support available.
  - **Choose FreeScout if:** you want modern UI + email-first + lighter-weight.
  - **Choose Zammad if:** you want Ruby modern + richer features + budget accepting.
  - **Choose commercial SaaS if:** you don't want ops burden.

## Links

- Repo: <https://github.com/osTicket/osTicket>
- Homepage: <https://osticket.com>
- Docs: <https://docs.osticket.com>
- Upgrade guide: <https://docs.osticket.com/en/latest/Getting%20Started/Upgrade%20and%20Migration.html>
- Cloud: <https://osticket.com/cloud-hosting/>
- Commercial support: <https://osticket.com/support/>
- Forum: <https://forum.osticket.com>
- FreeScout (alt): <https://github.com/freescout-helpdesk/freescout>
- Zammad (alt): <https://zammad.org>
- Chatwoot (alt): <https://www.chatwoot.com>
- Request Tracker (alt): <https://bestpractical.com/request-tracker>
