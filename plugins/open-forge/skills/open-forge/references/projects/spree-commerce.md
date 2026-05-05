---
name: spree-commerce
description: Spree Commerce recipe for open-forge. Open-source headless eCommerce platform for Ruby on Rails. Covers quickstart via npx create-spree-app (Docker-based), manual Rails install, and API-first deployment. Upstream: https://github.com/spree/spree
---

# Spree Commerce

Open-source headless eCommerce platform built on Ruby on Rails. Complete REST API, TypeScript SDK, and a production-ready Next.js storefront. Supports cross-border, B2B, multi-vendor marketplaces, and multi-tenant SaaS deployments.

15,383 stars · BSD-3-Clause

Upstream: https://github.com/spree/spree
Website: https://spreecommerce.org
Docs: https://spreecommerce.org/docs/
API reference: https://spreecommerce.org/docs/api-reference/
Demo: https://demo.spreecommerce.org/

## What it is

Spree provides a full eCommerce backend and optional frontend:

- **REST API** — Complete JSON API for products, orders, cart, checkout, users, inventory
- **Admin dashboard** — Product catalog, orders, customers, promotions, reports
- **Next.js storefront** — Optional production-ready frontend (separate repo)
- **Multi-store** — Multiple storefronts from one backend
- **Multi-currency & multi-language** — Built-in i18n, exchange rates
- **Multi-vendor** — Marketplace mode with vendor management
- **Payment gateways** — Stripe, Braintree, PayPal, and more via `solidus_payment_*` gems
- **Promotions** — Discount rules, coupon codes, free shipping
- **Inventory & shipping** — Stock management, shipping methods, zones
- **Extensible** — Ruby on Rails engine; extend with gems

## Compatible install methods

| Method | Upstream | When to use |
|---|---|---|
| `npx create-spree-app` (recommended) | https://spreecommerce.org/docs/developer/getting-started/quickstart | Fastest — full stack (backend + admin + Next.js storefront) via Docker |
| Manual Rails engine install | https://spreecommerce.org/docs/developer/getting-started/installation | Existing Rails app, or custom backend only |
| Deploy to Render | https://render.com/deploy?repo=https://github.com/spree/spree-starter | One-click cloud deploy |

## Requirements

### Quickstart method
- Node.js 22+
- Docker Desktop running

### Manual method
- Ruby 3.2+
- Rails 7.1+
- PostgreSQL 12+ (recommended) or MySQL 8+
- Redis (for Sidekiq background jobs)

## Inputs to collect

| Phase | Prompt | Applicability |
|---|---|---|
| app_name | "Application/store name?" | All |
| domain | "Domain for the store?" | Production |
| db | "PostgreSQL or MySQL?" | Manual install |
| admin_email | "Admin email?" | All |
| admin_pass | "Admin password?" | All |

## Quickstart (recommended — Docker-based full stack)

Upstream: https://spreecommerce.org/docs/developer/getting-started/quickstart

Requires Node.js 22+ and Docker running.

    npx create-spree-app@latest my-store
    cd my-store
    bin/start

This sets up:
- Spree backend (Rails API)
- Spree Admin dashboard
- Next.js storefront

Access:
- Storefront: http://localhost:3000
- Admin: http://localhost:3000/admin (default: spree@example.com / spree123)

## Manual Rails install

Upstream: https://spreecommerce.org/docs/developer/getting-started/installation

### 1. Add to Gemfile

    gem 'spree', '~> 4.10'
    gem 'spree_auth_devise', '~> 4.6'
    gem 'spree_gateway', '~> 3.10'

    bundle install

### 2. Run installer

    bundle exec rails g spree:install
    bundle exec rails g spree:auth:install
    bundle exec rails g spree_gateway:install

### 3. Configure database (config/database.yml)

    default: &default
      adapter: postgresql
      encoding: unicode
      pool: 5
      username: spree
      password: <%= ENV['DATABASE_PASSWORD'] %>
      host: localhost

    development:
      <<: *default
      database: spree_development

    production:
      <<: *default
      database: spree_production

### 4. Run migrations and seed

    bundle exec rails db:create db:migrate
    bundle exec rails db:seed

### 5. Start the server

    bundle exec rails s

Access: http://localhost:3000 (storefront), http://localhost:3000/admin (admin)

## Docker Compose (production-style)

    services:
      web:
        build: .
        environment:
          DATABASE_URL: postgresql://spree:password@db/spree_production
          REDIS_URL: redis://redis:6379/0
          SECRET_KEY_BASE: ${SECRET_KEY_BASE}
        depends_on:
          - db
          - redis
        ports:
          - "3000:3000"

      sidekiq:
        build: .
        command: bundle exec sidekiq
        environment:
          DATABASE_URL: postgresql://spree:password@db/spree_production
          REDIS_URL: redis://redis:6379/0

      db:
        image: postgres:16
        environment:
          POSTGRES_DB: spree_production
          POSTGRES_USER: spree
          POSTGRES_PASSWORD: password
        volumes:
          - postgres_data:/var/lib/postgresql/data

      redis:
        image: redis:7-alpine

    volumes:
      postgres_data:

## Key environment variables

| Variable | Description |
|---|---|
| `SECRET_KEY_BASE` | Rails secret key — `bundle exec rails secret` |
| `DATABASE_URL` | Full PostgreSQL/MySQL connection string |
| `REDIS_URL` | Redis connection (required for Sidekiq) |
| `SPREE_IMAGE_HOST` | CDN or host for product images |
| `SMTP_*` | Mail delivery settings |

## Upgrade

    # Update Gemfile version constraint, then:
    bundle update spree
    bundle exec rails spree:install:migrations
    bundle exec rails db:migrate

Always check the [upgrade guides](https://github.com/spree/spree/blob/main/guides/src/content/developer/upgrades/) for breaking changes between minor versions.

## Gotchas

- **Node.js 22+ required for create-spree-app** — The quickstart CLI requires Node 22+. Older Node versions will fail.
- **Docker must be running** — The quickstart method spins up all services via Docker Compose. Docker Desktop must be running.
- **Admin URL is `/admin`** — Not `/spree/admin`. The admin panel is served at the root `/admin` path.
- **Sidekiq for background jobs** — Email delivery, inventory updates, and order processing use Sidekiq. Redis is required.
- **ActiveStorage for images** — Product images use Rails ActiveStorage. Configure S3 or local disk in `config/storage.yml` for production.
- **`SECRET_KEY_BASE` in production** — Never commit this to version control. Generate with `bundle exec rails secret`.
- **Multi-store requires additional config** — Multi-store/multi-tenant features need `Spree::Store` records and subdomain routing configuration.

## Links

- GitHub: https://github.com/spree/spree
- Website: https://spreecommerce.org
- Docs: https://spreecommerce.org/docs/
- Quickstart: https://spreecommerce.org/docs/developer/getting-started/quickstart
- API reference: https://spreecommerce.org/docs/api-reference/
- Next.js storefront: https://github.com/spree/storefront
- Spree starter: https://github.com/spree/spree-starter
- Discord: https://discord.spreecommerce.org
