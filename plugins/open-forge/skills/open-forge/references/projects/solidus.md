---
name: solidus
description: Solidus recipe for open-forge. Free, open-source eCommerce platform for Ruby on Rails — fork of Spree. Covers gem install into a Rails app and Docker Compose for development. Upstream: https://github.com/solidusio/solidus
---

# Solidus

Free, open-source eCommerce platform built with Ruby on Rails. A community-maintained fork of Spree with a focus on stability and extensibility for established businesses. Complete storefront, admin, order management, inventory, and payment processing.

5,291 stars · BSD-3-Clause

Upstream: https://github.com/solidusio/solidus
Website: https://solidus.io/
Guides: https://guides.solidus.io/
API docs: https://docs.solidus.io/

## What it is

Solidus provides a full eCommerce backend as a Rails engine:

- **Product catalog** — Products, variants, taxons, properties, prototypes
- **Order management** — Cart, checkout flow, order state machine, order adjustments
- **Inventory** — Stock management, multiple stock locations, backorders
- **Shipping** — Shipping methods, calculators, zones
- **Payments** — Payment methods via solidus_gateway; Stripe, Braintree, PayPal via extensions
- **Promotions** — Discount rules, coupon codes, free shipping
- **User accounts** — Customers, addresses, order history
- **Admin panel** — Full-featured backend for store management
- **REST API** — JSON API for headless/hybrid commerce
- **Extension ecosystem** — Hundreds of community extensions at https://extensions.solidus.io/

## Relationship with Spree

Solidus is a fork of Spree (also in this catalog). Key differences:
- Solidus focuses on stability for established production stores
- More conservative API — fewer breaking changes
- Strong backward compatibility
- Popular with larger, more customized stores

## Compatible install methods

| Method | Upstream | When to use |
|---|---|---|
| Gem (recommended) | https://guides.solidus.io/getting-started/installation-options | Install into existing or new Rails app |
| solidus_starter_frontend | https://github.com/solidusio/solidus_starter_frontend | New storefront from scratch |

## Requirements

- Ruby 3.1+
- Rails 7.0+
- PostgreSQL 10+ (recommended) or MySQL 8+ or SQLite (dev only)
- Redis (for Sidekiq background jobs — optional but recommended)
- ImageMagick (for product image processing): `apt install -y imagemagick`

## Inputs to collect

| Phase | Prompt | Applicability |
|---|---|---|
| app_name | "Your store/app name?" | All |
| db | "PostgreSQL or MySQL?" | All |
| payment | "Payment gateway: Stripe, Braintree, or other?" | All |

## Install into a new Rails app

Guides: https://guides.solidus.io/getting-started/installation-options

### 1. Create a new Rails app

    gem install rails
    rails new mystore --database=postgresql
    cd mystore

### 2. Add Solidus to Gemfile

    # Gemfile
    gem 'solidus', '~> 4.4'
    gem 'solidus_auth_devise'      # authentication
    gem 'solidus_gateway'          # payment gateways (Stripe, Braintree, etc.)
    gem 'solidus_starter_frontend' # modern starter storefront

    bundle install

### 3. Run the install generator

    bundle exec rails g solidus:install
    bundle exec rails g solidus:auth:install
    bundle exec rails g solidus_gateway:install
    bundle exec rails g solidus_starter_frontend:install

This runs migrations, seeds sample data, and installs the storefront.

### 4. Configure database (config/database.yml)

    default: &default
      adapter: postgresql
      encoding: unicode
      pool: 5
      username: <%= ENV['DATABASE_USER'] %>
      password: <%= ENV['DATABASE_PASSWORD'] %>
      host: <%= ENV['DATABASE_HOST'] || 'localhost' %>

    development:
      <<: *default
      database: mystore_development

    production:
      <<: *default
      database: mystore_production

### 5. Create database and run migrations

    bundle exec rails db:create db:migrate db:seed

### 6. Start the server

    bundle exec rails s

Storefront: http://localhost:3000
Admin: http://localhost:3000/admin
Default admin: admin@example.com / test123 (change immediately)

## Adding a payment gateway (Stripe example)

    # Gemfile
    gem 'solidus_stripe'
    bundle install
    bundle exec rails g solidus_stripe:install

Configure in Admin → Configuration → Payment Methods.

## Docker Compose for development

    services:
      web:
        build: .
        environment:
          DATABASE_URL: postgresql://solidus:password@db/solidus_development
          REDIS_URL: redis://redis:6379/0
        depends_on:
          - db
          - redis
        ports:
          - "3000:3000"
        volumes:
          - .:/app
        command: bundle exec rails s -b 0.0.0.0

      db:
        image: postgres:16
        environment:
          POSTGRES_DB: solidus_development
          POSTGRES_USER: solidus
          POSTGRES_PASSWORD: password
        volumes:
          - postgres_data:/var/lib/postgresql/data

      redis:
        image: redis:7-alpine

    volumes:
      postgres_data:

## Upgrade

    # Update version constraint in Gemfile, then:
    bundle update solidus
    bundle exec rails solidus:migrations:copy
    bundle exec rails db:migrate

Check the [CHANGELOG](https://github.com/solidusio/solidus/blob/main/CHANGELOG.md) and upgrade guides before each version jump.

## Gotchas

- **Rails engine** — Solidus is a Rails engine, not a standalone app. It runs inside your Rails application. You must have a Rails app to host it.
- **solidus_starter_frontend vs Solidus Classic** — The original storefront (Solidus Classic) is deprecated. Use `solidus_starter_frontend` for new projects.
- **ImageMagick required** — Product images are processed with MiniMagick gem, which requires ImageMagick on the host: `apt install -y imagemagick`.
- **Admin URL is `/admin`** — The admin panel is at `/admin`. Set a strong password immediately; the default seed admin/test123 is public knowledge.
- **Sidekiq for background jobs** — Email notifications, promotions recalculation use ActiveJob. Configure Sidekiq with Redis for reliable job processing in production.
- **Extensions must be vetted** — Not all community extensions are maintained or compatible with recent Solidus versions. Check `solidusio` org extensions first, then community ones.

## Links

- GitHub: https://github.com/solidusio/solidus
- Website: https://solidus.io/
- Guides: https://guides.solidus.io/
- API docs: https://docs.solidus.io/
- Extensions: https://extensions.solidus.io/
- solidus_starter_frontend: https://github.com/solidusio/solidus_starter_frontend
- Slack: http://slack.solidus.io/
