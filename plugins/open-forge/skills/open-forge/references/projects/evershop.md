---
name: EverShop
description: TypeScript-first, modular eCommerce platform built with Node.js, GraphQL, and React. Developer-focused alternative to WooCommerce/Magento; Postgres-backed; extension + theme architecture. Good for headless or custom-frontend commerce. GPL-3.0.
---

# EverShop

EverShop is a modern Node.js eCommerce platform built for **developers** — TypeScript throughout, GraphQL-first API, React admin + storefront, extension-based architecture. Competes with WooCommerce (PHP), Magento (PHP), Medusa (Node headless), and Saleor (Python/GraphQL headless).

Where EverShop fits:

- Not a plugin to WordPress (unlike WooCommerce)
- Not headless-only (unlike Medusa — though you can use GraphQL directly)
- Full stack with admin + storefront, but easy to swap the storefront
- Modular: turn features on/off via extensions
- Node.js/TypeScript = familiar stack for JS developers

Core features:

- **Product catalog** — variants, categories, attributes
- **Cart + checkout** — built in; themable
- **Order management** — admin UI; email notifications
- **Customer accounts** — registration, addresses, order history
- **Payments** — Stripe, PayPal built in; extension API for more
- **Shipping + taxes** — zones, rates, tax classes
- **Promotions** — coupons, discounts
- **SEO** — meta + sitemaps + structured data
- **GraphQL API** — for custom frontends
- **Multi-language + multi-currency** — via i18n + currency settings
- **PWA / Next.js storefront** — ready to extend or replace

- Upstream repo: <https://github.com/evershopcommerce/evershop>
- Website: <https://evershop.io>
- Docs: <https://evershop.io/docs>
- Demo: <https://demo.evershop.io> (demo user `demo@evershop.io` / `123456`)
- Admin demo: <https://demo.evershop.io/admin>

## Architecture in one minute

- **Node.js** + **TypeScript** + **Express**-like framework
- **React** for admin panel + storefront
- **GraphQL** API (Apollo Server-based)
- **PostgreSQL** (required; no MySQL option)
- **Redis** (optional — caching)
- **Single port** serving both storefront + admin + API
- **Extension model** — folders under `extensions/` with lifecycle hooks; can ship as NPM packages

## Compatible install methods

| Infra       | Runtime                                          | Notes                                                           |
| ----------- | ------------------------------------------------ | --------------------------------------------------------------- |
| Single VM   | Docker Compose (official compose file)             | **Simplest**                                                     |
| Single VM   | Node.js 20+ native + Postgres                       | For dev or custom deploy                                           |
| Kubernetes  | Community manifests / Helm                             | Stateless app + Postgres                                                |
| PaaS        | Fly / Render / Railway (Node PaaS)                       | Works; pair with managed Postgres                                           |

## Inputs to collect

| Input                      | Example                                | Phase     | Notes                                                          |
| -------------------------- | -------------------------------------- | --------- | -------------------------------------------------------------- |
| `DB_*`                     | Postgres host/port/user/db/password       | DB        | Postgres 14+ recommended                                          |
| `COOKIE_SECRET`            | `openssl rand -hex 32`                    | Security  | Signs session cookies                                                |
| Admin user                 | created via first-run wizard              | Bootstrap | Race risk if public during setup                                         |
| Stripe / PayPal API keys   | from your gateway accounts                 | Payments  | Install extension + configure                                                 |
| SMTP                       | host + port + creds                         | Email     | Order confirmations + password resets                                                |
| `SITE_URL`                 | `https://shop.example.com`                 | URL       | Used in emails, canonicals                                                                 |
| Storage                    | local disk OR S3-compatible via extension   | Uploads   | Product images; local is default                                                                   |

## Install via Docker Compose

Upstream provides a ready compose file:

```sh
curl -sSL https://raw.githubusercontent.com/evershopcommerce/evershop/main/docker-compose.yml -o docker-compose.yml
# Review + edit passwords, secrets
docker compose up -d
```

Manual version:

```yaml
services:
  postgres:
    image: postgres:16
    container_name: evershop-db
    restart: unless-stopped
    environment:
      POSTGRES_USER: evershop
      POSTGRES_PASSWORD: <strong>
      POSTGRES_DB: evershop
    volumes:
      - evershop-pg:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U evershop"]
      interval: 10s
      retries: 5

  evershop:
    image: evershop/evershop:latest   # pin a specific tag in prod
    container_name: evershop
    restart: unless-stopped
    depends_on:
      postgres: { condition: service_healthy }
    ports:
      - "3000:3000"
    environment:
      DB_HOST: postgres
      DB_PORT: "5432"
      DB_NAME: evershop
      DB_USER: evershop
      DB_PASSWORD: <strong>
      COOKIE_SECRET: <openssl rand -hex 32>
    volumes:
      - evershop-media:/app/media

volumes:
  evershop-pg:
  evershop-media:
```

First run: browse `http://<host>:3000/install` → installer wizard → create admin account. After install, wizard endpoint is disabled.

## Native install

```sh
# Postgres running separately
git clone https://github.com/evershopcommerce/evershop.git
cd evershop
npm install
# Configure config/default.json or env vars
npm run build
npm start
```

## Creating an extension

EverShop's modularity comes from extensions — folders with `bootstrap.js` lifecycle hooks + React components.

```
extensions/
└── my-extension/
    ├── bootstrap.js           # registers routes, services, event handlers
    ├── graphql/
    │   └── types/             # GraphQL schema extensions
    ├── pages/                 # React components mapped to routes
    ├── api/                   # REST endpoints
    └── migration/             # DB migrations
```

Register in `config/default.json`:

```json
{
  "extensions": [
    { "name": "my-extension", "resolve": "extensions/my-extension", "enabled": true }
  ]
}
```

Full guide: <https://evershop.io/docs/development/module/create-your-first-extension>

## Data & config layout

- `config/default.json` + `config/production.json` — app config (DB, extensions, secrets via env interpolation)
- `media/` — uploaded product images
- `extensions/` — your custom code
- `themes/` — frontend themes
- PostgreSQL — all operational data

## Backup

```sh
# DB
docker compose exec -T postgres pg_dump -U evershop evershop | gzip > evershop-db-$(date +%F).sql.gz

# Uploads
docker run --rm -v evershop-media:/src -v "$PWD":/backup alpine \
  tar czf /backup/evershop-media-$(date +%F).tgz -C /src .

# Extensions + config (if not in VCS)
tar czf evershop-config-$(date +%F).tgz config/ extensions/
```

## Upgrade

1. Releases: <https://github.com/evershopcommerce/evershop/releases>. Active.
2. Back up DB + `media/` + `extensions/`.
3. Docker: `docker compose pull && docker compose up -d`. Migrations run on startup.
4. Native: `git pull && npm install && npm run build && npm start`.
5. Check release notes for breaking extension API changes (1.x → 2.x type jumps).

## Gotchas

- **Postgres only** — no MySQL/MariaDB/SQLite option. Plan accordingly.
- **TypeScript-first stack** — if your team is PHP-shop, EverShop won't feel native. Pick WooCommerce or Magento instead.
- **TLS is mandatory for real payments** — Stripe/PayPal won't accept plain HTTP. Reverse proxy with Let's Encrypt.
- **First-user-is-admin race** — installer endpoint `/install` is publicly reachable before first admin is created. Set up BEFORE exposing to internet.
- **"Install" wizard only runs once** — after first admin is set, the `/install` route is gone. If you need to reinstall, wipe DB first.
- **Smaller ecosystem** than WooCommerce/Magento — fewer themes, fewer payment gateways, fewer extensions. You'll likely build custom integrations.
- **Young project** (compared to WooCommerce) — growing fast but check forums for known issues before committing.
- **GraphQL-first API** is a strength for custom frontends but means REST clients need to adapt.
- **Extension API is evolving** — read release notes for breaking changes if you're maintaining custom extensions.
- **Asset uploads** default to local disk. For production (multi-replica, CDN), use the S3 extension.
- **No built-in multi-store** — one EverShop install = one storefront. For multi-brand, you'd run multiple instances + share Postgres via schemas, or wait for upstream support.
- **Email deliverability**: configure SMTP properly. No SPF/DKIM = order emails spam-binned.
- **Admin URL is `/admin`** by default — change via reverse proxy path or admin config to make brute-force harder (does not replace actual auth).
- **Performance tuning**: enable Redis cache via config; use a CDN for static assets; enable image optimization extension.
- **"EverShop Cloud" is coming** — upstream mentions managed hosting is in development. Self-host is supported long-term; Cloud is an optional offering.
- **GPL-3.0 license** — copyleft. Modified versions you distribute must be GPL-3.0 too. SaaS hosting is not triggered by GPL (unlike AGPL), but check if you plan commercial hosting.
- **Alternatives worth knowing:**
  - **WooCommerce** — WordPress plugin; huge ecosystem; PHP (separate recipe)
  - **Medusa** — Node.js headless-only; great if you're building custom frontend
  - **Saleor** — Python + GraphQL headless; strong for enterprise
  - **Magento / Adobe Commerce** — enterprise PHP; expensive; powerful
  - **PrestaShop / OpenCart** — older PHP; simpler than Magento
  - **Sylius** — Symfony PHP; developer-friendly; B2B-capable
  - **Vendure** — Node.js + TypeScript + GraphQL; similar niche
  - **Shopify** — SaaS; not self-hosted but the benchmark
  - **Choose EverShop if:** you want a Node.js/TypeScript full-stack commerce platform with admin + storefront included.
  - **Choose Medusa if:** you want headless Node.js (bring-your-own frontend).
  - **Choose Vendure if:** you want TypeScript + GraphQL in a more mature/established Node.js commerce framework.
  - **Choose WooCommerce if:** you want the biggest ecosystem + plugin market.

## Links

- Repo: <https://github.com/evershopcommerce/evershop>
- Website: <https://evershop.io>
- Docs: <https://evershop.io/docs>
- Installation guide: <https://evershop.io/docs/development/getting-started/installation-guide>
- Create first extension: <https://evershop.io/docs/development/module/create-your-first-extension>
- Theme development: <https://evershop.io/docs/development/theme/theme-overview>
- Demo (storefront): <https://demo.evershop.io>
- Demo (admin): <https://demo.evershop.io/admin>
- Discord: <https://discord.gg/GSzt7dt7RM>
- Twitter: <https://twitter.com/evershopjs>
- Releases: <https://github.com/evershopcommerce/evershop/releases>
