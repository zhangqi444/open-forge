---
name: FreeScout
description: "Self-hosted help-desk + shared-inbox — free open-source alternative to Zendesk + Help Scout. Email-centric ticketing, no user/ticket/mailbox limits, mobile apps, paid modules. PHP (Laravel) + MySQL/MariaDB/Postgres. AGPL-3.0."
---

# FreeScout

FreeScout is **"Zendesk/Help Scout for teams who want to self-host"** — a free, AGPL-3.0 help-desk built on Laravel that turns a shared mailbox into a ticketing system. Agents see conversations, internal notes, customer history; customers see threaded email replies. **No user limits, no ticket limits, no mailbox limits.** 30+ languages. Mobile apps (iOS + Android) + macOS menu-bar app (community).

Commercial ecosystem: **paid modules** for time tracking, workflow automation, tags, reports, billing/invoicing, knowledge base, chat widget, Telegram/WhatsApp channels, etc. Base product + core is 100% free; modules are one-time purchases that fund development.

Built + maintained by **freescout-help-desk**. Developed **from scratch**, not forked from Help Scout (upstream is explicit about not using Help Scout's copyrighted materials).

Features (core / free):

- **No limits** on users/tickets/mailboxes
- **Email integration** — IMAP fetch, SMTP send, modern Microsoft Exchange authentication (OAuth)
- **100% mobile-friendly UI** + native mobile apps
- **Collision detection** — alert when 2 agents open same conversation
- **Starred / forward / merge / move conversations**
- **Phone conversations** + **internal notes**
- **Multi-recipient new conversations**
- **Push notifications**
- **Follow conversations**, **auto-reply**, **templates**, **open tracking**
- **Pasting screenshots from clipboard** into replies
- **Web installer + updater**
- **Per-user notification config**
- **Full-text search**
- **Screen-reader accessible**

Popular paid modules (one-time purchase): Knowledge Base, Custom Fields, Tags, Workflows, SLA, Satisfaction Ratings, Chat, Time Tracking, Reports, Teams, Ratings, Telegram/WhatsApp/Facebook Messenger channels.

- Upstream repo: <https://github.com/freescout-help-desk/freescout>
- Homepage: <https://freescout.net>
- Docs + wiki: <https://github.com/freescout-help-desk/freescout/wiki>
- Demo: <https://demo.freescout.net>
- Modules (marketplace): <https://freescout.net/modules/>
- Android app: <https://freescout.net/android-app/>
- iOS app: <https://freescout.net/ios-app/>
- macOS menubar (community Scouter): <https://github.com/jonalaniz/scouter>
- Security: <https://freescout.net/security>
- Cloud hosting: <https://freescout.net/cloud-hosting/>

## Architecture in one minute

- **PHP 7.1 – 8.x** / **Laravel** framework
- **MySQL 5+, MariaDB 5+, or PostgreSQL**
- **Nginx / Apache / IIS** web server
- **Queue worker** (Laravel queues) for background jobs (email sending, notifications)
- **Scheduler** (cron) for periodic tasks
- **Resource**: moderate — 500MB-1GB RAM for modest teams; scales with active tickets + modules

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Shared hosting     | Most shared-host providers with PHP 7.1+ + MySQL work                                | **Supported** — per-upstream; rare for a tool this capable                         |
| Docker             | Community images (third-party; upstream not first-party Docker)          | Works; watch version pinning                                                               |
| VPS + LAMP/LEMP    | Manual install via web installer                                                                    | **Upstream-documented path**                                                                              |
| Bare-metal         | Standard Laravel deploy                                                                                         | Well-documented                                                                                                      |
| Managed            | FreeScout Cloud (commercial hosting by upstream)                                                                                   | Funds upstream                                                                                                                |

## Inputs to collect

| Input                    | Example                                                   | Phase        | Notes                                                                    |
| ------------------------ | --------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain                   | `help.example.com`                                              | URL          | TLS required                                                                                      |
| Web server               | Nginx / Apache                                                          | Infra        | PHP-FPM behind it                                                                                  |
| PHP                      | 7.1 – 8.x with required extensions                                              | Prereq       | See wiki for extension list (mbstring, xml, curl, gd, etc.)                                                                                 |
| Database                 | MySQL 5+ / MariaDB 5+ / Postgres                                                     | DB           | Create DB + user before install                                                                                                 |
| `APP_KEY`                | Laravel secret — auto-generated by installer                                                          | Secret       | **Immutable once set** — rotating breaks encrypted cookies/db fields                                                                                  |
| SMTP (outbound)          | Email provider                                                                      | Email        | Required for sending replies                                                                                                      |
| IMAP / OAuth (inbound)   | Gmail / O365 / generic IMAP per mailbox                                                                       | Email        | Modern Exchange = OAuth preferred                                                                                                        |
| Queue worker             | Systemd unit running `php artisan queue:work`                                                                                | Background   | Otherwise emails queue but never send                                                                                                                |
| Cron                     | `* * * * * cd /path && php artisan schedule:run`                                                                              | Background   | Required for scheduled tasks                                                                                                                 |

## Install via web installer (VPS path)

Per upstream wiki:
1. Provision VPS with PHP 7.1+ + MySQL + Nginx/Apache + SSL cert
2. Clone: `git clone https://github.com/freescout-help-desk/freescout.git`
3. Point webserver at `public/` directory
4. Visit URL → web installer walks through DB setup + admin creation
5. Configure cron + queue worker (systemd unit)
6. Configure mailbox (IMAP + SMTP OR OAuth)

See <https://github.com/freescout-help-desk/freescout/wiki> for step-by-step.

## First boot

1. Web installer → create first mailbox + admin
2. Configure inbound email (IMAP poll or OAuth push)
3. Configure outbound SMTP
4. Set up queue worker (CRITICAL — without it replies don't send)
5. Set up cron (CRITICAL — without it scheduled tasks don't run)
6. Put behind TLS
7. Create team members + assign mailboxes
8. Send test email to mailbox → verify ticket appears → reply → verify customer receives
9. Install any needed paid modules from marketplace
10. Back up DB + `storage/` (uploaded attachments)

## Data & config layout

- **Database** — conversations, customers, users, notes
- **`storage/app/`** — uploaded attachments
- **`.env`** — DB creds, APP_KEY, mail config
- **Modules** — installed into `Modules/` directory

## Backup

```sh
mysqldump -u freescout -p freescout | gzip > freescout-db-$(date +%F).sql.gz
sudo tar czf freescout-storage-$(date +%F).tgz storage/ .env
```

Test restores quarterly — a help-desk's DB matters.

## Upgrade

1. Releases: <https://github.com/freescout-help-desk/freescout/releases>. Active.
2. **Built-in web updater** — UI-driven upgrade.
3. Or CLI: `git pull + php artisan migrate + restart queue worker`.
4. **Back up DB first** — Laravel migrations can be irreversible.
5. Module updates separate from core.

## Gotchas

- **Queue worker + cron are NOT optional.** Without them, emails don't send, notifications don't fire, scheduled cleanups don't run. Both MUST be systemd services with restart-on-failure. Daily-startup-checklist item.
- **APP_KEY immutability** (Laravel class) — set during install + NEVER rotate. Rotating invalidates encrypted DB fields (including stored passwords for IMAP accounts). Same class as Statamic APP_KEY (batch 77), Wakapi salt (batch 81), JWT_SECRET (Fider batch 82).
- **IMAP OAuth for Gmail/O365** — modern providers block basic-auth IMAP. You MUST configure OAuth (Gmail: Google Cloud project + consent screen + scopes; O365: app registration). This takes 30-60 min. Without OAuth, you're stuck with App Passwords (Gmail legacy) or deprecated basic-auth (O365).
- **Email ingress latency**: IMAP polling = new tickets appear within polling interval (default 1-5min). For instant ingress, use "pipe-to-script" with a local MTA instead (advanced).
- **Shared hosting can work** — upstream explicitly calls this out, which is unusual for a tool with this scope. Tradeoff: shared hosting = limited queue-worker options, possibly no systemd, often no long-running PHP processes. Works for small teams; production at scale needs a VPS.
- **Customer PII stored**: full email addresses, names, phone numbers, conversation content. GDPR + data-retention policy applicable. Provide export + delete-on-request processes.
- **Module marketplace trust**: paid modules are officially distributed via freescout.net. Stick to official modules for security; third-party modules = vet before install.
- **"No limits on users/tickets/mailboxes"** means FreeScout scales with your infra — not the license. MySQL + PHP-FPM tuning matters as ticket volume grows. At 100K+ tickets: indexing, partitioning, full-text search tuning.
- **Full-text search** is bundled but depends on DB capabilities. MySQL fulltext is limited; consider Elasticsearch/Meilisearch integration for power users (if a module exists).
- **Email threading accuracy** = quality of life. FreeScout's threading depends on Message-ID / In-Reply-To headers. Occasional threading misses happen; rarely enough to matter.
- **AGPL-3.0 for CORE** — free self-host fine; running as modified commercial SaaS triggers source-disclosure. Same class as Papra, AnonAddy, MiroTalk, Fider.
- **Paid modules are proprietary** (one-time purchase, per-module) + distributed separately. Unusual but viable open-core funding model. You can self-host the core AGPL forever without modules; pay only for extras that matter. Genuinely transparent funding approach.
- **Customer-facing reply emails come FROM your configured SMTP** — deliverability + SPF + DKIM + DMARC matter. Same SMTP-deliverability concerns as AnonAddy (batch 79). For production: use a transactional-email provider (SendGrid / Postmark / Amazon SES / Mailgun) with proper DNS config rather than raw SMTP.
- **Mobile apps**: official iOS + Android. If you have a reverse-proxy with HTTP basic auth in front, the apps might not support that; keep auth at the Laravel level.
- **Project health**: freescout-help-desk team + growing community + module-marketplace revenue. Mature + sustained. Healthy bus-factor.
- **Alternatives worth knowing:**
  - **Zammad** — enterprise-class self-hosted help-desk; Ruby on Rails + Elasticsearch; heavier; very feature-rich
  - **osTicket** — classic PHP help-desk; simpler; less polished UI
  - **UVdesk** — Symfony-based; enterprise-y
  - **Chatwoot** — support-chat-first + email; Ruby on Rails; excellent modern UX
  - **Helpy** — Ruby on Rails; older
  - **Help Scout / Zendesk / Intercom** — commercial SaaS
  - **Choose FreeScout if:** email-centric support + want simple PHP/MySQL stack + small-to-medium team + OSS core + paid-module ecosystem.
  - **Choose Zammad if:** need heavier features (SLA, escalation, CTI integration) + OK with Rails + Elasticsearch.
  - **Choose Chatwoot if:** chat + email + modern UX priority.
- **License**: **AGPL-3.0**.

## Links

- Repo: <https://github.com/freescout-help-desk/freescout>
- Homepage: <https://freescout.net>
- Wiki / docs: <https://github.com/freescout-help-desk/freescout/wiki>
- Demo: <https://demo.freescout.net>
- Modules: <https://freescout.net/modules/>
- Security: <https://freescout.net/security>
- Cloud hosting: <https://freescout.net/cloud-hosting/>
- Releases: <https://github.com/freescout-help-desk/freescout/releases>
- Android: <https://freescout.net/android-app/>
- iOS: <https://freescout.net/ios-app/>
- Zammad (alt): <https://zammad.org>
- Chatwoot (alt): <https://www.chatwoot.com>
- osTicket (alt): <https://osticket.com>
