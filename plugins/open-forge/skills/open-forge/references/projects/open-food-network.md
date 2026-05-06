# Open Food Network

Open Food Network (OFN) is an open-source online marketplace platform for local food systems. It enables food hubs, farmers markets, co-ops, and independent farmers to run their own online food stores, connecting producers directly with consumers and local businesses.

**Website:** https://www.openfoodnetwork.org/
**Source:** https://github.com/openfoodfoundation/openfoodnetwork
**License:** AGPL-3.0
**Stars:** ~1,241

> ⚠️ **Complex Ruby on Rails app**: OFN is a full-featured e-commerce platform. Self-hosting requires Ruby, Rails, PostgreSQL, Redis, Sidekiq, and optional Stripe/payment gateway configuration. Expect significant DevOps overhead.

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Linux VPS (Ubuntu 22.04+) | Ansible provisioning (ofn-install) | Official/recommended |
| Linux VPS | Docker Compose (dev) | Development only; not production-ready |
| Kubernetes | Custom | Advanced; not officially documented |

---

## Inputs to Collect

### Phase 1 — Planning
- Domain name (e.g. `food.example.com`)
- Email/SMTP credentials for transactional emails
- Payment gateway: Stripe (recommended), PayPal, or others
- PostgreSQL host/credentials
- Redis host
- S3-compatible storage for file uploads (optional but recommended)
- Google Maps API key (for producer/shop maps)

### Phase 2 — Deployment
- `OFN_DOMAIN`: public domain
- `POSTGRES_*`: DB connection details
- `REDIS_URL`: Redis connection
- `SMTP_*`: email settings
- `STRIPE_*` or other payment provider keys
- `AWS_*` / S3 credentials for file storage
- `GOOGLE_MAPS_API_KEY`
- `SECRET_KEY_BASE`: Rails secret key

---

## Software-Layer Concerns

### Official Deployment: Ansible (ofn-install)

The Open Food Foundation maintains Ansible playbooks for production deployment:

```bash
# Clone the Ansible deployment repo
git clone https://github.com/openfoodfoundation/ofn-install
cd ofn-install

# Follow the setup guide to configure inventory and vars
# https://github.com/openfoodfoundation/ofn-install

# Run provisioning playbook
ansible-playbook playbooks/provision.yml -i inventory/your_server

# Deploy application
ansible-playbook playbooks/deploy.yml -i inventory/your_server
```

See the [ofn-install repository](https://github.com/openfoodfoundation/ofn-install) for full documentation, inventory setup, and required variables.

### Development Setup (Docker Compose)
```bash
git clone https://github.com/openfoodfoundation/openfoodnetwork
cd openfoodnetwork

# Copy environment template
cp .env.test.default .env

# Start services
docker compose up -d

# Setup database
docker compose run --rm web bin/setup

# Access at http://localhost:3000
```

### Key Services Required
| Service | Purpose |
|---------|---------|
| PostgreSQL 14+ | Primary database |
| Redis | Background job queuing, caching |
| Sidekiq | Background job workers (emails, reports) |
| nginx | Reverse proxy + static assets |
| Puma | Rails application server |
| S3/compatible | File/image uploads (optional but recommended) |

### Environment Variables (Key)
```bash
# Database
DATABASE_URL=postgres://ofn:pass@localhost/ofn_production

# Redis
REDIS_URL=redis://localhost:6379/0

# Email
MAILER_DEFAULT_FROM=noreply@example.com
SMTP_ADDRESS=smtp.example.com
SMTP_PORT=587
SMTP_USERNAME=user
SMTP_PASSWORD=pass

# Rails
SECRET_KEY_BASE=<random 128+ char string>
RAILS_ENV=production

# Stripe (payment)
STRIPE_PUBLISHABLE_KEY=pk_live_...
STRIPE_SECRET_KEY=sk_live_...

# Google Maps
GOOGLE_MAPS_API_KEY=...

# S3 file storage
AWS_ACCESS_KEY_ID=...
AWS_SECRET_ACCESS_KEY=...
AWS_BUCKET=ofn-uploads
AWS_REGION=us-east-1
```

### Database Setup
```bash
bundle exec rails db:create db:migrate db:seed RAILS_ENV=production
```

### Asset Compilation
```bash
bundle exec rails assets:precompile RAILS_ENV=production
```

---

## Upgrade Procedure

For Ansible deployments:
```bash
# Pull latest playbooks
cd ofn-install && git pull

# Deploy new version
ansible-playbook playbooks/deploy.yml -i inventory/your_server
```

Migrations run automatically during deployment. Always back up the database before upgrading.

---

## Gotchas

- **High complexity**: OFN is a full Rails e-commerce platform with dozens of moving parts. Budget significant time for initial setup and ongoing maintenance.
- **Use ofn-install for production**: The Ansible playbooks handle Ruby version management, system packages, nginx config, SSL, and service wiring. Manual setup is error-prone.
- **Payment gateway required for commerce**: Stripe is the most integrated payment option. Configure before going live.
- **Email deliverability**: OFN sends many transactional emails (order confirmations, invoices). Use a transactional email service (SendGrid, Postmark) rather than a raw SMTP server.
- **Background jobs critical**: Sidekiq handles order notifications, reports, and subscriptions. If Redis or Sidekiq stops, these silently fail.
- **File storage**: Default local storage works for development; use S3 or compatible object storage for production to survive deployments.
- **Ruby version pinned**: Check `.ruby-version` in the repo; mismatched Ruby versions cause bundler failures.
- **Multi-enterprise architecture**: OFN is designed for networks of food enterprises (hubs + producers), not single-shop use. There is platform overhead for this model.

---

## Links
- Getting Started: https://github.com/openfoodfoundation/openfoodnetwork/blob/main/GETTING_STARTED.md
- ofn-install (Ansible): https://github.com/openfoodfoundation/ofn-install
- Super Admin Guide: https://ofn-user-guide.gitbook.io/ofn-super-admin-guide
- User Guide: https://guide.openfoodnetwork.org/
- Community Forum: https://community.openfoodnetwork.org
- Slack: https://openfoodnetwork.slack.com
