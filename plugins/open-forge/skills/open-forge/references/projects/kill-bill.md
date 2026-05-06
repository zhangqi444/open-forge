---
name: kill-bill
description: Kill Bill recipe for open-forge. Open-source subscription billing and payments platform — recurring billing, invoicing, payment plugins, analytics. Docker Compose install. Upstream: https://github.com/killbill/killbill
---

# Kill Bill

Open-source subscription billing and payments platform. Handles recurring billing, invoicing, payment processing, refunds, credits, dunning, and revenue analytics. Battle-tested alternative to Stripe Billing / Chargebee for self-hosted deployments.

5,452 stars · Apache-2.0

Upstream: https://github.com/killbill/killbill
Website: https://killbill.io/
Docs: https://docs.killbill.io/
Docker Hub: https://hub.docker.com/r/killbill/killbill

## What it is

Kill Bill provides a complete billing and subscription management stack:

- **Subscription management** — Create plans, add-ons, trial periods, upgrades/downgrades
- **Invoicing** — Automatic invoice generation, prorations, credits, adjustments
- **Payment processing** — Plugin-based: Stripe, PayPal, Braintree, Adyen, Square, and more
- **Dunning** — Automatic retry logic for failed payments
- **Multi-currency** — Handle payments in multiple currencies
- **Taxation** — Tax calculation hooks and integrations
- **REST API** — Full programmatic control over all billing operations
- **KAUI admin UI** — Kill Bill Admin UI — web interface for managing accounts, subscriptions, invoices, payments
- **Reporting** — Real-time analytics and financial reports
- **Multi-tenancy** — Multiple tenants on a single instance (API key/secret per tenant)
- **Plugin system** — Extend with Java plugins for payment gateways, notifications, custom logic

## Compatible combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Docker Compose | killbill + kaui + mariadb | Official stack; simplest deploy |
| Kubernetes | Helm | community Helm charts available |
| Bare metal | Java 11+ + Tomcat + MySQL | Advanced; see upstream install guide |

## Inputs to collect

### Phase 1 — Pre-install
- Database password (for MariaDB root and killbill user)
- Admin UI URL (KAUI)
- Kill Bill API URL
- Tenant API key and secret (default: bob / lazar for dev)
- Payment gateway credentials (Stripe secret key, PayPal credentials, etc.)

### Phase 2 — Runtime config
- KILLBILL_DAO_URL — JDBC connection to database
- KILLBILL_DAO_USER / KILLBILL_DAO_PASSWORD
- KAUI_KILLBILL_URL — URL for KAUI to reach Kill Bill API
- KAUI_KILLBILL_API_KEY / KAUI_KILLBILL_API_SECRET — tenant credentials

## Software-layer concerns

### Services and ports
- Kill Bill API: 8080 (HTTP), 8000 (healthcheck), 12345 (JMX/debug)
- KAUI admin UI: 9090 (mapped to internal 8080)
- MariaDB: 3306 (internal)

### Database
Uses killbill/mariadb Docker image which includes pre-initialized Kill Bill schema.
Separate databases: killbill (API data) and kaui (admin UI data).

### Key environment variables
Kill Bill:
  KILLBILL_DAO_URL=jdbc:mysql://db:3306/killbill
  KILLBILL_DAO_USER=root
  KILLBILL_DAO_PASSWORD=killbill
  KILLBILL_METRICS_INFLUXDB=false

KAUI:
  KAUI_CONFIG_DAO_URL=jdbc:mysql://db:3306/kaui
  KAUI_CONFIG_DAO_USER=root
  KAUI_CONFIG_DAO_PASSWORD=killbill
  KAUI_KILLBILL_URL=http://killbill:8080
  KAUI_KILLBILL_API_KEY=bob
  KAUI_KILLBILL_API_SECRET=lazar

### Config paths
- Kill Bill config: /var/lib/killbill/config/ (inside container)
- Plugins directory: /var/lib/killbill/osgi/bundles/platform/ (mount for custom plugins)

## Docker Compose install

  version: '3.2'
  volumes:
    db:
  services:
    killbill:
      image: killbill/killbill:latest
      ports:
        - "8080:8080"
        - "8000:8000"
      environment:
        - KILLBILL_DAO_URL=jdbc:mysql://db:3306/killbill
        - KILLBILL_DAO_USER=root
        - KILLBILL_DAO_PASSWORD=killbill
        - KILLBILL_METRICS_INFLUXDB=false
      depends_on:
        - db

    kaui:
      image: killbill/kaui:latest
      ports:
        - "9090:8080"
      environment:
        - KAUI_CONFIG_DAO_URL=jdbc:mysql://db:3306/kaui
        - KAUI_CONFIG_DAO_USER=root
        - KAUI_CONFIG_DAO_PASSWORD=killbill
        - KAUI_KILLBILL_URL=http://killbill:8080
        - KAUI_KILLBILL_API_KEY=bob
        - KAUI_KILLBILL_API_SECRET=lazar
      depends_on:
        - killbill

    db:
      image: killbill/mariadb:0.24
      volumes:
        - db:/var/lib/mysql
      expose:
        - "3306"
      environment:
        - MYSQL_ROOT_PASSWORD=killbill

Access KAUI at http://<host>:9090 (admin@example.com / password for first login)
Kill Bill API at http://<host>:8080

Full compose: https://github.com/killbill/killbill-cloud/blob/master/docker/compose/docker-compose.kb.yml

## Upgrade procedure

1. Backup database: docker exec -t <db-container> mysqldump -u root -pkillbill killbill > backup.sql
2. Check upgrade notes at https://docs.killbill.io/latest/upgrade_guide.html
3. Stop services: docker compose stop killbill kaui
4. Update image tags in docker-compose.yml
5. Pull images: docker compose pull
6. Start: docker compose up -d
7. Kill Bill runs DDL migrations automatically on startup
8. Verify in KAUI: check account, subscription, and payment pages load correctly

## Gotchas

- Slow startup — Kill Bill can take 2-5 minutes to fully initialize on first start; wait for /healthcheck to return 200
- Default credentials — change default API key (bob/lazar) and KAUI admin password immediately in production
- Java heap — Kill Bill is memory-hungry; default container may need 2-4GB RAM; set JAVA_OPTS=-Xmx2g
- Plugin install — payment gateway plugins (Stripe, PayPal) must be installed separately via KAUI or API; not bundled
- MariaDB version pinning — killbill/mariadb image has pre-seeded schema; do not replace with vanilla MariaDB without running schema migrations
- Multi-tenancy — each tenant needs its own API key/secret pair; configure in KAUI > Tenants
- PCI compliance — if handling card data directly, review PCI DSS requirements; use tokenization (Stripe/Braintree) to reduce scope
- Timezone — ensure database and Kill Bill container use the same timezone to avoid invoice date discrepancies

## Links

- Upstream README: https://github.com/killbill/killbill/blob/master/README.md
- Documentation: https://docs.killbill.io/
- Docker Compose file: https://github.com/killbill/killbill-cloud/blob/master/docker/compose/docker-compose.kb.yml
- Payment plugins: https://github.com/killbill?q=killbill-plugin
- KAUI: https://github.com/killbill/killbill-admin-ui
