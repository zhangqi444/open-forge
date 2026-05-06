---
name: hi.events
description: Hi.Events recipe for open-forge. Open-source event ticketing and management platform — sell tickets, manage events, custom pages, embeddable widget. Docker all-in-one install. Upstream: https://github.com/HiEventsDev/hi.events
---

# Hi.Events

Open-source event ticketing and management platform. Sell tickets online for conferences, concerts, nightlife, workshops, and festivals. Self-hosted alternative to Eventbrite, Tickettailor, and Dice.fm — full control over branding, data, and checkout.

3,766 stars · AGPL-3.0

Upstream: https://github.com/HiEventsDev/hi.events
Website: https://hi.events
Docs: https://hi.events/docs
Demo: https://app.hi.events/event/2/hievents-conference-2030
Docker Hub: https://hub.docker.com/r/daveearley/hi.events-all-in-one

## What it is

Hi.Events provides a full event ticketing stack:

- **Flexible tickets** — Free, paid, donation, tiered pricing; hidden tickets behind promo codes
- **Promo codes** — Discount codes and pre-sale access
- **Product add-ons** — Sell merch, upgrades, extras alongside tickets
- **Tax & fee support** — VAT, service fees, configurable
- **Capacity management** — Per-ticket-type limits and shared capacity pools
- **Custom checkout** — Custom questions at checkout for attendee data collection
- **PDF tickets** — Customizable ticket design with QR codes
- **Attendee check-in** — QR code scanning for event check-in
- **Event page builder** — Drag-and-drop event page customization
- **Embeddable widget** — Embed ticket sales on your own website
- **Organizer homepage** — Branded organizer page listing all events
- **SEO tools** — Meta tags, Open Graph
- **Refunds** — Manage refunds and cancellations
- **Notifications** — Automated email confirmations and reminders
- **Stripe integration** — Payment processing via Stripe (required for paid tickets)
- **Multi-event** — Manage multiple events from one account
- **Waiting lists** — Collect waitlist signups when sold out

## Compatible combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Docker | All-in-one container | Easiest; hi.events-all-in-one image bundles PHP + frontend + queue worker |
| Docker Compose | all-in-one + postgres + redis | Recommended for production |

## Inputs to collect

### Phase 1 — Pre-install
- Public URL for the frontend (VITE_FRONTEND_URL)
- Public URL for the API (VITE_API_URL_CLIENT and VITE_API_URL_SERVER)
- App name (VITE_APP_NAME)
- Stripe publishable key and secret key (for paid ticket processing)
- Stripe webhook secret (configure at dashboard.stripe.com/webhooks)
- SMTP credentials for email (ticket confirmations, notifications)
- Postgres database credentials
- Random APP_KEY (32-char base64) and JWT_SECRET

### Phase 2 — Optional
- APP_DISABLE_REGISTRATION — disable public registration (single-organizer mode)
- FILESYSTEM_PUBLIC_DISK — s3 for storing files in S3 instead of local
- CDN URL for assets

## Software-layer concerns

### Ports
- 8123 — all-in-one HTTP (map to 80/443 via reverse proxy)

### Key environment variables
  VITE_FRONTEND_URL=https://tickets.example.com
  VITE_API_URL_CLIENT=https://tickets.example.com/api
  VITE_API_URL_SERVER=http://all-in-one/api
  VITE_APP_NAME=My Ticketing Platform
  APP_KEY=base64:<random-32-bytes>
  JWT_SECRET=<random-secret>
  DATABASE_URL=postgresql://postgres:secret@postgres:5432/hi-events
  REDIS_HOST=redis
  REDIS_PORT=6379
  STRIPE_PUBLIC_KEY=pk_live_...
  STRIPE_SECRET_KEY=sk_live_...
  STRIPE_WEBHOOK_SECRET=whsec_...
  MAIL_MAILER=smtp
  MAIL_HOST=smtp.example.com
  MAIL_PORT=587
  MAIL_USERNAME=user@example.com
  MAIL_PASSWORD=password
  MAIL_FROM_ADDRESS=tickets@example.com
  MAIL_FROM_NAME=My Ticketing Platform
  APP_DISABLE_REGISTRATION=false

### Config paths
- No explicit config files; all configuration via environment variables
- /app/storage/ — uploaded files, logs (mount as volume)

## Docker Compose install

  version: '3'
  services:
    all-in-one:
      image: daveearley/hi.events-all-in-one:latest
      restart: unless-stopped
      ports:
        - "8123:80"
      environment:
        - VITE_FRONTEND_URL=https://tickets.example.com
        - VITE_API_URL_CLIENT=https://tickets.example.com/api
        - VITE_API_URL_SERVER=http://all-in-one/api
        - VITE_APP_NAME=My Events
        - APP_KEY=base64:REPLACE_ME
        - JWT_SECRET=REPLACE_ME
        - DATABASE_URL=postgresql://postgres:secret@postgres:5432/hi-events
        - REDIS_HOST=redis
        - STRIPE_PUBLIC_KEY=pk_live_...
        - STRIPE_SECRET_KEY=sk_live_...
        - STRIPE_WEBHOOK_SECRET=whsec_...
        - MAIL_MAILER=smtp
        - MAIL_HOST=smtp.example.com
        - MAIL_PORT=587
        - MAIL_USERNAME=user@example.com
        - MAIL_PASSWORD=password
        - MAIL_FROM_ADDRESS=tickets@example.com
      depends_on:
        postgres:
          condition: service_healthy
        redis:
          condition: service_healthy
      volumes:
        - storage:/app/storage

    redis:
      image: redis:7-alpine
      restart: unless-stopped
      healthcheck:
        test: ["CMD", "redis-cli", "ping"]
        interval: 10s
        retries: 5
      volumes:
        - redisdata:/data

    postgres:
      image: postgres:17-alpine
      restart: unless-stopped
      healthcheck:
        test: ["CMD-SHELL", "pg_isready -U postgres -d hi-events"]
        interval: 10s
        retries: 5
      environment:
        POSTGRES_DB: hi-events
        POSTGRES_USER: postgres
        POSTGRES_PASSWORD: secret
      volumes:
        - pgdata:/var/lib/postgresql/data

  volumes:
    pgdata:
    redisdata:
    storage:

Full compose: https://github.com/HiEventsDev/hi.events/blob/develop/docker/all-in-one/docker-compose.yml

## Upgrade procedure

1. Backup postgres: docker exec <postgres-container> pg_dump -U postgres hi-events > backup.sql
2. Pull new image: docker pull daveearley/hi.events-all-in-one:latest
3. Restart: docker compose up -d --force-recreate all-in-one
4. Database migrations run automatically on container start
5. Verify event listings and checkout flow

## Gotchas

- Stripe required for paid tickets — free tickets work without Stripe; paid tickets require Stripe keys
- Webhook setup — configure Stripe webhook endpoint at <VITE_FRONTEND_URL>/api/payments/stripe/webhook and add the STRIPE_WEBHOOK_SECRET
- APP_KEY — must be a valid Laravel application key (base64: prefix + 32 random bytes); generate with: head -c 32 /dev/urandom | base64
- VITE_ prefix — frontend URLs baked into the built JS; must be correct before container starts (not changeable at runtime without rebuild)
- AGPL-3.0 — modifications must be open-sourced if distributed; commercial use allowed but check license terms
- Beta releases — currently v1.x.x-beta; API may change between versions; check changelog before upgrading
- Email required — ticket confirmations need working SMTP; test with a service like Mailtrap before going live
- Storage volume — mount /app/storage to persist uploaded files and logs across container restarts

## Links

- Upstream README: https://github.com/HiEventsDev/hi.events/blob/main/README.md
- Documentation: https://hi.events/docs
- Docker Compose: https://github.com/HiEventsDev/hi.events/blob/develop/docker/all-in-one/docker-compose.yml
- Demo: https://app.hi.events/event/2/hievents-conference-2030
- Docker Hub: https://hub.docker.com/r/daveearley/hi.events-all-in-one
