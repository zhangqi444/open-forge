---
name: Mautic
description: The world's largest open-source marketing automation platform. Email campaigns, landing pages, forms, contact segmentation, lead scoring, drip campaigns, integrations with CRMs. Verified Digital Public Good. Symfony (PHP) + MySQL/MariaDB. GPL-3.0-or-later.
---

# Mautic

Mautic is the canonical open-source marketing automation platform — a self-hosted alternative to HubSpot, Marketo, ActiveCampaign, and Pardot. It lets you run email campaigns, build landing pages, capture leads via forms, segment contacts, score leads based on behavior, trigger drip campaigns, and integrate with CRMs + hundreds of other apps. Verified as a UN Digital Public Good.

Core features:

- **Contacts + companies** — CRM-lite with custom fields
- **Segments** — static or dynamic (rules-based)
- **Email campaigns** — drag-and-drop builder, A/B testing, split sends, timezone-aware
- **Landing pages + forms** — build + track conversions
- **Marketing campaigns** — visual workflow builder (if-this-then-that + waits + branches)
- **Lead scoring** — rule-based scoring; segment by score
- **Focus items** — pop-ups, bars, slide-ins
- **Reports + dashboards** — conversion funnels, campaign analytics
- **Integrations** — hundreds, including Salesforce, HubSpot, Zoho, Sugar, Pipedrive, Mailchimp, Twilio, WhatsApp, Slack, Zapier
- **Multi-channel** — email, SMS (Twilio), web push, Apple/Google Web, social
- **GDPR tools** — consent management, right-to-be-forgotten
- **REST API** + webhooks
- **Plugin architecture** — Symfony bundles

- Upstream repo: <https://github.com/mautic/mautic>
- Website: <https://mautic.org>
- Docs: <https://docs.mautic.org>
- Community: <https://mautic.org/community>
- Downloads: <https://mautic.org/download>
- DPG registry: <https://digitalpublicgoods.net/r/mautic>

## Architecture in one minute

- **Symfony 6.x** (PHP 8.1+) + Twig templates
- **MySQL 8.0+ / MariaDB 10.6+** — Postgres is NOT supported
- **Cron** — absolutely required for segment updates, campaign triggers, email sends
- **Queue** — recommended (RabbitMQ or DB queue) for high-volume email
- **Redis** — optional (cache + rate limiting)
- **Mailer** — SMTP / Amazon SES / SendGrid / Mailgun / Postmark / SparkPost
- Standard LAMP/LEMP deployment — but operationally heavy due to cron + mailing complexity

## Compatible install methods

| Infra       | Runtime                                           | Notes                                                            |
| ----------- | ------------------------------------------------- | ---------------------------------------------------------------- |
| Single VM   | Native LAMP/LEMP                                    | **Upstream-documented**                                            |
| Single VM   | Docker (community images)                             | `mautic/mautic` on Docker Hub (community-maintained)                    |
| Kubernetes  | Community manifests                                      | Complex due to cron sidecar + mailer queue                                  |
| Managed     | Mautic Inc. hosted + many partner hosts                    | Cost varies                                                                     |
| PaaS        | Platform.sh / Cloudron / Elestio / YunoHost                  | 1-click                                                                             |

## Inputs to collect

| Input                   | Example                          | Phase     | Notes                                                          |
| ----------------------- | -------------------------------- | --------- | -------------------------------------------------------------- |
| Site URL                | `https://marketing.example.com`    | URL       | Used in tracking pixels, form submissions, unsub links            |
| DB                      | MySQL/MariaDB creds                | DB        | MySQL 8+ / MariaDB 10.6+                                              |
| Admin user              | set via install wizard              | Bootstrap | Don't expose before setup                                                   |
| Mailer (SMTP/SES/etc.)  | host + port + creds                  | Email     | **Email-sending reputation** is the make-or-break issue (see gotchas)       |
| From address            | `no-reply@example.com`                | Email     | Must be at a domain you own with SPF/DKIM/DMARC configured                        |
| Bounce + tracking domain | `mautic.example.com`                  | DNS       | Dedicated domain for tracking pixels to avoid poisoning your main domain                |
| Cron                    | every 5-15 min                         | Schedule  | Multiple commands; see below                                                                    |
| Queue                   | DB or RabbitMQ                          | Perf      | For high-volume sends                                                                                       |
| TLS                     | Let's Encrypt                            | Security  | Mandatory for tracking cookies                                                                                       |

## Install via Docker Compose (community image)

```yaml
services:
  mautic:
    image: mautic/mautic:7-apache          # pin specific tag in prod
    container_name: mautic-web
    restart: unless-stopped
    depends_on:
      db: { condition: service_healthy }
    ports:
      - "8080:80"
    environment:
      DB_HOST: db
      DB_PORT: "3306"
      DB_NAME: mautic
      DB_USER: mautic
      DB_PASSWORD: <strong>
      MAUTIC_TRUSTED_PROXIES: '["0.0.0.0/0"]'
      MAUTIC_RUN_CRON_JOBS: "false"        # run in dedicated container below
    volumes:
      - mautic-config:/var/www/html/config
      - mautic-logs:/var/www/html/var/logs
      - mautic-media:/var/www/html/docroot/media

  mautic-cron:
    image: mautic/mautic:7-apache
    container_name: mautic-cron
    restart: unless-stopped
    depends_on: [db, mautic]
    command: /usr/local/bin/cron.sh
    environment:
      DB_HOST: db
      DB_NAME: mautic
      DB_USER: mautic
      DB_PASSWORD: <strong>
    volumes:
      - mautic-config:/var/www/html/config
      - mautic-logs:/var/www/html/var/logs
      - mautic-media:/var/www/html/docroot/media

  mautic-worker:
    image: mautic/mautic:7-apache
    container_name: mautic-worker
    restart: unless-stopped
    depends_on: [db, mautic]
    command: php /var/www/html/bin/console messenger:consume email --time-limit=3600
    environment:
      DB_HOST: db
      DB_NAME: mautic
      DB_USER: mautic
      DB_PASSWORD: <strong>

  db:
    image: mariadb:11
    container_name: mautic-db
    restart: unless-stopped
    environment:
      MARIADB_ROOT_PASSWORD: <strong-root>
      MARIADB_DATABASE: mautic
      MARIADB_USER: mautic
      MARIADB_PASSWORD: <strong>
    command: --max_allowed_packet=67108864 --innodb_buffer_pool_size=512M
    volumes:
      - mautic-db:/var/lib/mysql
    healthcheck:
      test: ["CMD", "healthcheck.sh", "--connect"]
      interval: 10s

volumes:
  mautic-config:
  mautic-logs:
  mautic-media:
  mautic-db:
```

First visit → install wizard (DB check, admin create, mailer config). Once done, the wizard disables itself.

## Cron commands (critical)

Mautic **will not work** without these running on a schedule. Typical crontab on host:

```
*/5 * * * * php /path/bin/console mautic:segments:update
*/5 * * * * php /path/bin/console mautic:campaigns:update
*/5 * * * * php /path/bin/console mautic:campaigns:trigger
*/5 * * * * php /path/bin/console mautic:emails:send
*/5 * * * * php /path/bin/console mautic:fetch:email
*/15 * * * * php /path/bin/console mautic:email:process
0 */6 * * * php /path/bin/console mautic:maintenance:cleanup
```

Full list at <https://docs.mautic.org/en/5.x/configuration/cron_jobs.html>.

## First boot

1. Install wizard: DB check → DB setup → admin account → mailer → done
2. Log in → configure:
   - Main Menu → Contacts → import or connect via API
   - Channels → Emails → create templates
   - Components → Landing Pages / Forms / Focus
   - Configuration → Email Settings → configure sender domain + DKIM
3. Create first segment (rule-based) + first campaign
4. Test-send to yourself; verify tracking pixels fire, unsub works

## Data & config layout

- `config/local.php` — local overrides
- `app/config/local.php` — legacy; depends on version
- `docroot/media/` — uploaded images, email assets
- `var/logs/` — application logs
- `var/cache/` — cache (safe to flush)
- `var/spool/` — email spool if using file-queue
- DB — everything: contacts, campaigns, segments, reports

## Backup

```sh
# DB (CRITICAL — all contacts, campaigns, stats)
mysqldump -umautic -p --single-transaction mautic | gzip > mautic-db-$(date +%F).sql.gz

# Media (images, email assets)
tar czf mautic-media-$(date +%F).tgz docroot/media

# Config
cp config/local.php mautic-config-$(date +%F).bak
```

## Upgrade

1. Releases: <https://github.com/mautic/mautic/releases>. Active.
2. **Back up DB, config, media BEFORE every upgrade** — Mautic migrations can be slow + occasionally fail on big DBs.
3. Upgrade path: use the in-app upgrader (Configuration → Upgrade) OR manually: stop cron + workers → `git pull` (or re-extract release zip) → `composer install --no-dev` → `php bin/console mautic:update:apply` → `php bin/console cache:clear` → restart.
4. Major versions (4.x → 5.x) have had breaking changes; follow upstream migration docs.
5. Long-running migrations: some updates take hours on DBs with millions of contacts — schedule downtime.

## Gotchas

- **Email sending reputation is everything.** Running Mautic from a fresh IP without warming up reputation = your emails go to spam. You need:
  - **SPF + DKIM + DMARC** configured on your sending domain
  - **Dedicated sending IP** (or use SES/SendGrid/Postmark/Mailgun as relays)
  - **Warm-up** — start slow (few hundred/day) and ramp up over weeks
  - **List hygiene** — remove bounces + unengaged recipients
- **Use a dedicated tracking subdomain** (`mautic.example.com` for tracking pixels) — do NOT let Mautic cookies pollute your main domain. If tracking gets flagged by security vendors, only the subdomain is blacklisted, not your marketing domain.
- **Cron is the #1 operational issue** — if cron stops, segments don't update, campaigns don't send, emails queue indefinitely. Monitor cron health religiously (e.g., with Healthchecks).
- **Queue worker** (Symfony Messenger) — new in Mautic 5; required for scalable sends. The old "file spool + cron-processed" mode is legacy.
- **MySQL only** — no Postgres support. Check latest docs in case this changed.
- **DB can grow FAST** — every page view, form submit, email open, link click = a DB row. Campaign stats, audit logs, IP geolookups. Plan 50-100 MB per 1000 highly-engaged contacts/year. Old data cleanup is critical.
- **`mautic:maintenance:cleanup`** deletes old audit logs, anonymized contacts. Tune `--days-old=N` so DB doesn't bloat.
- **GDPR**: Mautic has tools for consent management, DSAR (data-subject access requests), right-to-be-forgotten. Use them. Having marketing data = compliance obligations.
- **Double opt-in**: configure double opt-in for EU contacts. Single opt-in is legal in some jurisdictions but risky.
- **Unsubscribe compliance**: Mautic's default unsub flow is functional but bland. Customize; test with every campaign.
- **IP warming**: dedicated IP takes 4-8 weeks to build reputation. Shared IPs on SendGrid/Postmark/Mailgun have built-in reputation — safer for small senders.
- **Tracking JS** must be embedded on your site for full contact scoring via page-view behavior. Copy from Channels → Tracking Code.
- **High-volume sends (>100k/day)** need tuned MySQL, Redis, queue workers, and likely a dedicated mail relay (SES/SendGrid Pro). Mautic scales but you need operational discipline.
- **Plugin ecosystem** is smaller than HubSpot/Salesforce but nonzero; check Marketplace.
- **Composer install** on a low-memory VM (< 2 GB RAM) can OOM — use `COMPOSER_MEMORY_LIMIT=-1` or install on a bigger host + copy.
- **File permissions** — www-data must own `var/cache`, `var/logs`, `var/spool`, `docroot/media`. Missing = wizard fails silently.
- **Public-facing forms & landing pages** mean bots will try to submit. Configure CAPTCHA + honeypot.
- **Transactional emails vs marketing emails** — use separate "channels" in Mautic; segment reputation by traffic type. Sending both via the same IP pollutes reputation.
- **Mautic Inc.** (the company) offers paid hosting + enterprise support. The Community edition (this repo) has no features behind a paywall; the commercial offering is hosting + support.
- **Legacy v3 → v5 migration** is non-trivial. Big v2 upgrades had data-loss reports years ago; v5 migrations are smoother but back up anyway.
- **Digital Public Good verified** (since 2024) — validates the project's compliance with UN DPG standards.
- **GPL-3.0-or-later license** — copyleft.
- **Alternatives worth knowing:**
  - **Sendy** — simpler; commercial one-time license; Amazon SES-focused
  - **Listmonk** — Go-based; simpler; email-only (no campaigns/forms) (separate recipe)
  - **EspoCRM** — CRM with marketing modules; simpler than full Mautic
  - **HubSpot / Marketo / Pardot / ActiveCampaign / Brevo** — commercial SaaS
  - **Klaviyo / Omnisend** — e-commerce-focused SaaS
  - **Postal** — self-host mail server (complementary, not a replacement)
  - **Choose Mautic if:** you want full-featured marketing automation + OK with operational complexity + don't want vendor lock-in.
  - **Choose Listmonk if:** you just want to send newsletters (no segmentation/scoring/landing pages).
  - **Choose Brevo/ActiveCampaign if:** you want managed SaaS without the ops burden.

## Links

- Repo: <https://github.com/mautic/mautic>
- Website: <https://mautic.org>
- Docs: <https://docs.mautic.org>
- Downloads: <https://mautic.org/download>
- Community: <https://mautic.org/community>
- Install guide: <https://docs.mautic.org/en/5.x/getting_started/installation.html>
- Cron jobs reference: <https://docs.mautic.org/en/5.x/configuration/cron_jobs.html>
- System requirements: <https://docs.mautic.org/en/5.x/getting_started/how_to_install_mautic.html>
- Digital Public Good: <https://digitalpublicgoods.net/r/mautic>
- Releases: <https://github.com/mautic/mautic/releases>
- Docker Hub (community): <https://hub.docker.com/r/mautic/mautic>
- Upgrade guide: <https://docs.mautic.org/en/5.x/install/upgrade.html>
- Forum: <https://forum.mautic.org>
- Slack: <https://mautic.org/slack>
