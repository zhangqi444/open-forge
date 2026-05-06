---
name: sharetribe
description: Sharetribe (Sharetribe Go) recipe for open-forge. Covers Ruby on Rails source install with MySQL. Note — Sharetribe Go is no longer actively maintained; the upstream team recommends The New Sharetribe SaaS. Recipe documents the last stable open-source release for teams who need a self-hosted peer-to-peer marketplace.
---

# Sharetribe (Sharetribe Go)

Open-source peer-to-peer marketplace platform built with Ruby on Rails. Allows creation of rental, selling, or service marketplaces with listings, payments (Stripe/PayPal), user profiles, admin dashboard, and multi-language support. Upstream: <https://github.com/sharetribe/sharetribe>. Website: <https://www.sharetribe.com>.

**License:** Proprietary (Sharetribe Community Public License — source-available, non-commercial self-hosting permitted) · **Language:** Ruby on Rails · **Default port:** 3000 · **Stars:** ~2,400

> **⚠️ Maintenance status:** Sharetribe Go is **no longer actively maintained**. The upstream team has shifted focus to [The New Sharetribe](https://www.sharetribe.com) SaaS platform. Bug fixes may be slow and security patches are not guaranteed. Evaluate the risk before deploying for production use.

> **License note:** Sharetribe Go is licensed under the Sharetribe Community Public License — not a standard OSI open-source license. Review it at <https://github.com/sharetribe/sharetribe/blob/master/LICENSE> before deploying, especially for commercial use.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Ruby on Rails (source) | <https://github.com/sharetribe/sharetribe#installation> | ✅ | Only supported method — no official Docker image. |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| ruby | "Ruby version available? (3.4.x recommended, matches upstream)" | Free-text | Verify before install. |
| database | "MySQL 8.x host, database name, username, password?" | Free-text (sensitive) | Required. |
| domain | "What domain will the marketplace run on?" | Free-text | All installs. |
| smtp | "SMTP host, port, user, password for transactional email?" | Free-text (sensitive) | Required for user registration/notifications. |
| payments | "Payment provider: Stripe, PayPal, or none?" | AskUserQuestion | Affects env config. |
| stripe | "Stripe publishable and secret keys?" | Free-text (sensitive) | If Stripe selected. |

## Install

Reference: <https://github.com/sharetribe/sharetribe#installation>

### Prerequisites

```bash
# Required packages (Ubuntu/Debian)
sudo apt-get install -y ruby ruby-dev bundler nodejs npm git imagemagick \
  libmysqlclient-dev libxml2-dev libxslt-dev libssl-dev sphinxsearch

# Recommended: manage Ruby versions with rbenv or RVM
# Ruby 3.4.x (or version specified in .ruby-version)
rbenv install $(cat .ruby-version)
rbenv local $(cat .ruby-version)
```

### Setup

```bash
git clone https://github.com/sharetribe/sharetribe.git
cd sharetribe
git checkout latest   # latest stable tag

# Install Ruby gems
bundle install

# Install Node packages (for asset compilation)
npm install

# Copy and configure environment
cp config/config.example.yml config/config.yml
cp config/database.example.yml config/database.yml
```

Edit `config/database.yml` — set MySQL host, database, username, password.

Edit `config/config.yml` — set domain, SMTP, Stripe keys, etc.

```bash
# Create and migrate database
bundle exec rake db:create db:migrate

# Seed initial data
bundle exec rake db:seed

# (Optional) Generate a test marketplace for development
bundle exec rake sharetribe:create_test_marketplace

# Compile assets
bundle exec rake assets:precompile

# Start the server
bundle exec rails server
```

### nginx + Passenger (production)

Install Phusion Passenger:

```bash
gem install passenger
passenger-install-nginx-module
```

nginx vhost:

```nginx
server {
    listen 443 ssl;
    server_name marketplace.example.com;
    root /var/www/sharetribe/public;
    passenger_enabled on;
    passenger_ruby /path/to/rbenv/shims/ruby;
    passenger_env_var RAILS_ENV production;
}
```

### Sphinx (full-text search)

Sphinx is required for listing search:

```bash
bundle exec rake ts:configure
bundle exec rake ts:index
bundle exec rake ts:start
```

Add to cron for re-indexing:
```
*/5 * * * * cd /var/www/sharetribe && bundle exec rake ts:index
```

## Software-layer concerns

| Concern | Detail |
|---|---|
| Ruby version | Requires Ruby 3.4.x (check `.ruby-version` in repo). Use rbenv or RVM to manage versions. |
| Database | MySQL 8.x only — PostgreSQL is not tested/supported upstream. |
| Sphinx | Required for marketplace listing search. Must be running alongside the app. |
| DelayedJob | Background job processor for emails and async tasks: `bundle exec rake jobs:work`. Run as a persistent process (systemd or supervisord). |
| Assets | Run `rake assets:precompile` after each deployment. |
| Image processing | Requires ImageMagick for listing photos. |
| S3 (optional) | Configure AWS S3 in `config.yml` for image/file storage in production. Default stores locally in `public/system/`. |
| Email | SMTP required for user registration confirmation, password reset, and booking notifications. |
| Payments | Stripe and PayPal integrations available. Configure keys in `config.yml`. |

## Upgrade procedure

```bash
cd /var/www/sharetribe
git fetch origin
git checkout <new-version-tag>
bundle install
npm install
bundle exec rake db:migrate
bundle exec rake assets:precompile
# Restart app server (Passenger: touch tmp/restart.txt)
touch tmp/restart.txt
# Re-index Sphinx
bundle exec rake ts:index ts:restart
```

Back up MySQL before every upgrade:

```bash
mysqldump -u sharetribe -p sharetribe_production > sharetribe-$(date +%Y%m%d).sql
```

## Gotchas

- **No longer actively maintained:** Upstream has moved to a SaaS-only model. Security patches and bug fixes are sporadic. Audit dependencies (`bundle audit`) regularly if running in production.
- **MySQL only:** The schema uses MySQL-specific features. PostgreSQL will not work without significant schema changes.
- **Sphinx must be running:** The search feature (listing browse/filter) depends on Sphinx. If Sphinx is down, users see no search results. Monitor it with systemd or supervisord.
- **DelayedJob must be running:** Email notifications, background processing of payments, etc. require the `jobs:work` process. Without it, queued jobs pile up silently.
- **Asset precompile required:** Every deploy needs `rake assets:precompile` or the site will serve stale/broken CSS+JS.
- **License restrictions:** The Sharetribe Community Public License allows non-commercial self-hosting. Commercial use requires a separate agreement. Read the license carefully.

## Upstream links

- GitHub: <https://github.com/sharetribe/sharetribe>
- Installation guide: <https://github.com/sharetribe/sharetribe#installation>
- Changelog: <https://github.com/sharetribe/sharetribe/blob/master/CHANGELOG.md>
- License: <https://github.com/sharetribe/sharetribe/blob/master/LICENSE>
- Migration path (SaaS): <https://www.sharetribe.com/from-go-to-new-sharetribe>
