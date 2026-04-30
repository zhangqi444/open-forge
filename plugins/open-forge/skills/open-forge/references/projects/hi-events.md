---
name: Hi.Events
description: "Open-source event ticketing + management platform — self-hosted Eventbrite alternative. Laravel (PHP) + React. Self-hosted or cloud. AGPL-3.0. Multi-language UI. For nightlife, conferences, festivals, community events."
---

# Hi.Events

Hi.Events is **"your own self-hosted Eventbrite — without per-ticket fees or data lock-in"** — an open-source event ticketing + management platform built for nightlife promoters, festival organizers, venues, community groups, and conference hosts. Most commercial ticketing platforms (Eventbrite, Tickettailor, Dice.fm) charge per-ticket fees + lock your customer data into their ecosystem. Hi.Events gives organizers full control over branding, checkout, customer data, and infrastructure.

Built + maintained by **HiEventsDev** (Dave Earley + team). **AGPL-3.0**. **Cloud offering at app.hi.events** (same-product-hosted model) + self-host path. Heavy i18n (14+ languages).

Use cases: (a) **conference ticket sales** with tiered pricing (b) **nightlife event promotion** + QR-ticket door check-in (c) **festival multi-day pass sales** (d) **workshop / class registration** (e) **community group events** — RSVPs + paid tickets (f) **venue ticketing** — dedicated instance for a physical venue (g) **free-event registration** — data collection without payment processing.

Features (from upstream README):

- **Flexible ticket types**: free, paid, donation, tiered
- **Hidden / locked tickets** behind promo codes
- **Promo codes + pre-sale access**
- **Product add-ons** — merch, upgrades, extras
- **Capacity management** + shared limits
- **Full tax + fee support** (VAT, service fees)
- **Custom branding** per event
- **Multi-event, multi-organizer** single-instance
- **Payments**: Stripe integration (other processors per docs)
- **QR-code tickets** for door scan-in
- **Attendee check-in app** (likely; check upstream docs)
- **Email templates** for attendees
- **Reporting + analytics**
- **API** for integrations
- **14+ languages** — Deutsch, Português, Français, Italiano, Nederlands, Español, 中文, 繁體中文, 日本語, Tiếng Việt, Türkçe, Magyar, Polski, English

- Upstream repo: <https://github.com/HiEventsDev/Hi.Events>
- Homepage: <https://hi.events>
- Cloud offering: <https://app.hi.events>
- Docs: <https://hi.events/docs>
- Live demo: <https://app.hi.events/event/2/hievents-conference-2030>
- Docker image (all-in-one): <https://hub.docker.com/r/daveearley/hi.events-all-in-one>

## Architecture in one minute

- **Laravel (PHP 8.x)** backend + **React (TypeScript)** frontend
- **MySQL / MariaDB / Postgres** — primary DB
- **Redis** — cache + queues
- **Stripe** — payment processor (primary)
- **Resource**: moderate — 1-2GB RAM; DB + Redis + PHP-FPM stack
- **Ports**: 80/443 via web server

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Docker (all-in-one) | **`daveearley/hi.events-all-in-one`** — simple deploy          | **Easiest self-host path**                                                         |
| Docker compose     | Upstream provides compose files                                           | More control                                                                               |
| Manual Laravel     | Laravel + React build + MySQL + Redis                                                      | Advanced                                                                                             |
| Cloud SaaS         | app.hi.events — upstream-hosted                                                                          | For non-self-host users                                                                                                |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `tickets.example.com`                                       | URL          | TLS mandatory                                                                                    |
| DB credentials       | MySQL/Postgres connection                                              | DB           | Dedicated user                                                                                    |
| Redis connection     | local or external                                                          | Cache/jobs   | Required                                                                                                      |
| `APP_KEY`            | Laravel app key                                                                                       | **CRITICAL** | **IMMUTABLE** — encrypts sessions, data; losing = re-encrypt everything                                                                                                                                     |
| Admin user + password | At installer                                                                                                 | Bootstrap    | **Strong password**                                                                                                                                 |
| Stripe API keys (opt) | live + secret                                                                                                                                    | Payments     | For paid tickets                                                                                                                                                         |
| SMTP                 | For ticket + notification emails                                                                                                                                             | Outbound     | Required for ticketing flow                                                                                                                                                                              |

## Install (Docker all-in-one, quickest)

```yaml
services:
  hi-events:
    image: daveearley/hi.events-all-in-one:latest   # **pin version** in prod
    restart: unless-stopped
    environment:
      - APP_KEY=${HI_EVENTS_APP_KEY}          # generate via `php artisan key:generate` OR 32-byte random
      - APP_URL=https://tickets.example.com
      - DB_HOST=db
      - DB_DATABASE=hievents
      - DB_USERNAME=hievents
      - DB_PASSWORD=${DB_PASSWORD}
      - REDIS_HOST=redis
      - STRIPE_PUBLIC_KEY=${STRIPE_PUBLIC}
      - STRIPE_SECRET_KEY=${STRIPE_SECRET}
      # ... plus SMTP + other Laravel env vars
    ports: ["8080:80"]
    depends_on: [db, redis]
  # + mysql / mariadb / postgres + redis
```

For separated-services deployment, follow upstream Docker compose files in <https://hi.events/docs>.

## First boot

1. Browse `https://tickets.example.com/`
2. Setup wizard: create organizer account + first admin
3. Configure organizer profile: name, logo, branding
4. Create first event: title, dates, venue, tickets
5. Configure Stripe for payments (test mode first)
6. Configure SMTP → send test email
7. Publish event → test purchase flow with Stripe test card
8. Share event URL → verify public checkout works
9. Plan door-check-in workflow + QR scanner app
10. Back up DB + Redis + uploads

## Data & config layout

- **DB** — events, tickets, orders, attendees, users, promo codes, customization
- **Redis** — queues (email jobs, webhook retries) + cache
- **File uploads** — event images, logos, ticket attachments (local or S3-adapter)
- **`.env`** — secrets + config (APP_KEY, DB, Stripe, SMTP, etc.)

## Backup

```sh
# DB
docker compose exec db mysqldump -uhievents -p${DB_PASSWORD} hievents > hievents-$(date +%F).sql
# Redis — usually regeneratable but back up for in-flight jobs
# Uploads
sudo tar czf hievents-uploads-$(date +%F).tgz hievents-uploads/
# .env — secrets; encrypted backup
```

## Upgrade

1. Releases: <https://github.com/HiEventsDev/Hi.Events/releases>. Active.
2. Docker: pull new image + restart; Laravel migrations auto-run.
3. **Back up DB + uploads FIRST** — major versions may have migration impacts.
4. Check release notes for breaking changes.

## Gotchas

- **PAYMENT PROCESSING = HIGHEST-STAKES INFRASTRUCTURE**: Hi.Events handles real money via Stripe. **Any security incident = direct financial loss + customer-payment-data exposure.**
  - TLS MANDATORY
  - Stripe API keys = crown-jewel secrets
  - **PCI DSS scope** — if you process card data through Hi.Events, you're in PCI scope. Stripe's tokenization + Hi.Events redirecting to Stripe Checkout = MUCH lower PCI scope than processing cards yourself, but **check your PCI responsibility matrix**.
  - Enable Stripe's anti-fraud (Radar) + 3D Secure 2 requirements.
- **APP_KEY IMMUTABILITY** (Laravel standard): the `APP_KEY` encrypts session cookies, encrypted DB fields, etc. Losing it = brick the app + can't decrypt historical encrypted data. **Store in password manager + infrastructure vault.** **14th tool in immutability-of-secrets family.**
- **HUB-OF-CREDENTIALS crown-jewel**: Hi.Events stores:
  - **Stripe secret keys** (money-mover)
  - **SMTP passwords** (email gateway)
  - **All customer PII** — names, emails, phone numbers, possibly billing addresses
  - **Event attendee list** (who's going where)
  - **18th tool in hub-of-credentials family, Tier 2 (crown-jewel proper)**.
  - Defense: dedicated host, TLS, secrets-manager integration, regular backups, DB field encryption for PII.
- **GDPR / privacy COMPLIANCE** (CRITICAL for event ticketing):
  - Attendee data = personal data
  - Need a privacy policy + lawful basis for processing
  - Right to erasure implementation (delete-my-account flow)
  - Data-retention policy
  - Cross-border data-transfer considerations if organizers are in one jurisdiction + attendees in another
  - Same class of concern as osTicket (customer data) + Chartbrew (analytics data across sources)
- **EMAIL DELIVERABILITY**: transactional email for tickets = cannot go to spam. **SPF + DKIM + DMARC MANDATORY** on your sending domain. Use a reputable transactional-mail provider (SES / Postmark / Mailgun / SendGrid) rather than raw SMTP if volume is high. Same class as osTicket / FreeScout / every-transactional-mail-tool.
- **Door-check-in UX matters** for live events: if the check-in tool is slow or unreliable, you have angry crowds. **Test the check-in app workflow in a real pre-event dry-run** with actual network conditions at your venue (often bad wifi at festivals + concerts).
- **Stripe-or-alternative considerations**: README prominently shows Stripe; check current upstream docs for other processors (PayPal / Square / Mollie / regional processors). If you're in a region where Stripe isn't available or suboptimal, verify Hi.Events has your processor.
- **Fraud + chargebacks**: ticket scalping + credit-card fraud are ever-present in ticketing. **Familiarize yourself with Stripe Radar rules + chargeback dispute workflow.** Budget time for fraud management on high-volume events.
- **Scalability for sudden spikes**: popular event ticket sales see massive spikes (Taylor Swift concert-scale). Hi.Events needs scale planning: DB connections, Redis for queues, CDN for assets. **Dedicated Redis with persistence** + **queue workers scaled separately** + **autoscaling web tier** for big-event days.
- **Multi-organizer on single instance**: Hi.Events supports multiple organizers. **Tenant isolation is logical (same DB)** — if one organizer's admin is compromised, carefully scoped RBAC limits blast radius but doesn't eliminate DB-level access risk. For high-risk separation (e.g., each organizer is a different business client), consider separate Hi.Events instances.
- **AGPL-3.0 for a ticketing SaaS**: fine for self-hosting internally. If you offer Hi.Events as a SaaS to third parties (competing with app.hi.events), AGPL kicks in on your modifications — you must publish source. Upstream has cloud offering that monetizes this reasonably.
- **Commercial-tier: "same-product hosted"** pattern (Piwigo 88, AzuraCast 87 + Hi.Events 89) — consistent with taxonomy.
- **Cloud offering vs self-host**: organizations often start on app.hi.events cloud + migrate to self-host at scale. Data portability should be validated BEFORE commitment. Ask upstream about import/export guarantees.
- **Language coverage** is a real strength: 14+ translations = global reach for non-English markets. Rare in self-hosted ticketing space.
- **Project health**: active trending (Trendshift badge), active repo, upstream cloud commercial-funding, growing community. Good signals.
- **Alternatives worth knowing:**
  - **Pretix** — German OSS ticketing (AGPL); mature; more B2B-conference-focused
  - **Alf.io** — Italian OSS conference ticketing (GPL); mature
  - **Eventbrite** — commercial SaaS, market incumbent
  - **Tickettailor** — commercial SaaS, per-ticket fees
  - **Dice.fm** — commercial SaaS, nightlife-focused
  - **Humanitix** — commercial SaaS, charity-donation-model
  - **Attendize** — older PHP OSS ticketing; less-maintained
  - **Choose Hi.Events if:** you want modern Laravel-React + AGPL + multi-language + active development + willing to self-host or use upstream cloud.
  - **Choose Pretix if:** you want conference-focused + mature + German-engineered + power-user.
  - **Choose Alf.io if:** you want conference-focused + mature + Java-ecosystem.
  - **Choose commercial SaaS if:** you don't want infrastructure + accept per-ticket fees + accept data-in-vendor-cloud.

## Links

- Repo: <https://github.com/HiEventsDev/Hi.Events>
- Homepage: <https://hi.events>
- Cloud: <https://app.hi.events>
- Docs: <https://hi.events/docs>
- Docker: <https://hub.docker.com/r/daveearley/hi.events-all-in-one>
- Pretix (alt, conference): <https://pretix.eu>
- Alf.io (alt, conference): <https://alf.io>
- Attendize (alt, older): <https://github.com/Attendize/Attendize>
- Stripe (primary payment processor): <https://stripe.com>
