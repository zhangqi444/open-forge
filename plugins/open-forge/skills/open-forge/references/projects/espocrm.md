---
name: EspoCRM
description: "Open-source CRM platform. PHP 8.3+ REST API + SPA frontend. Leads, contacts, sales opportunities, marketing, support cases, custom entities. MySQL/MariaDB/PostgreSQL. GPL-3.0. Active; commercial extensions; professional services available."
---

# EspoCRM

EspoCRM is **"Salesforce / Zoho / Pipedrive / HubSpot CRM — open-source + PHP + customizable"** — a self-hosted CRM platform covering leads, contacts, sales opportunities, marketing campaigns, support cases, and custom business entities. Clean minimalist UI; short learning curve. Built for small-medium businesses up to larger organizations needing customization without vendor lock-in. PHPStan level 8 static-typing. Rich customization: custom entities, fields, relationships, workflow automation, REST API, extensions.

Built + maintained by **EspoCRM org (espocrm)** + commercial entity + community. License: **GPL-3.0** (typical). Active; PHPStan level 8 quality-gate; Docker installation; Traefik installation; professional services; extension marketplace.

Use cases: (a) **startup/SMB CRM** — replace $15-75/mo/user Salesforce/Zoho/Pipedrive subscriptions (b) **customer-relationship tracking** — leads → opportunities → accounts → closed-won workflow (c) **support-ticketing hybrid** — cases module (d) **custom business-app platform** — build your own entities on CRM foundation (e) **GDPR-compliant customer DB** — self-host → data sovereignty (f) **agency client-tracking** — all client interactions logged (g) **developer-extensible CRM** — REST API + extensions = custom workflows (h) **on-premise requirement** — government, healthcare, high-compliance verticals.

Features (per README):

- **Leads, contacts, sales opportunities, marketing campaigns, support cases**
- **Custom entities + fields + relationships**
- **SPA frontend** + **REST API backend**
- **Workflow automation**
- **Clean minimalist UI**
- **PHPStan level 8** static-typing quality
- **Docker + Traefik** installation options
- **Manual install** via web wizard

- Upstream repo: <https://github.com/espocrm/espocrm>
- Website: <https://www.espocrm.com>
- Demo: <https://www.espocrm.com/demo/>
- Docs: <https://docs.espocrm.com>
- Docker install: <https://docs.espocrm.com/administration/docker/installation/>
- Traefik install: <https://docs.espocrm.com/administration/docker/traefik/>

## Architecture in one minute

- **PHP 8.3-8.5** backend (REST API)
- **SPA frontend** (vanilla JS, not bloated framework)
- **MySQL 8.0+ / MariaDB 10.3+ / PostgreSQL 15+** — DB
- **Resource**: moderate — 500MB-1GB RAM (PHP-FPM typical)
- **Port 80/443** via nginx/Apache

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker**         | **Upstream images**                                             | **Primary**                                                                        |
| **Traefik**        | **Upstream docker-with-traefik guide**                          | **Modern reverse-proxy**                                                                        |
| Manual             | Upload files to webroot + web install                           | Classic PHP                                                                                   |
| Installation by script | Bash installer                                                                             | Automated                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `crm.example.com`                                           | URL          | TLS MANDATORY                                                                                    |
| DB                   | MySQL / MariaDB / PostgreSQL                                | DB           |                                                                                    |
| Admin creds          | First-boot                                                                           | Bootstrap    | Strong + MFA                                                                                    |
| SMTP                 | Email workflows + notifications                                                                           | Email        | **Required for core workflow**                                                                                    |
| IMAP (optional)      | Email-to-CRM import                                                                                                      | Email        | For logging inbound customer email                                                                                                            |
| OAuth (optional)     | Gmail / Outlook integration                                                                                                            | Integration  |                                                                                                                                            |
| API access           | REST tokens for integrations                                                                                                      | API          |                                                                                                                                            |

## Install via Docker

Follow: <https://docs.espocrm.com/administration/docker/installation/>

```yaml
services:
  mysql:
    image: mysql:8
    environment:
      MYSQL_ROOT_PASSWORD: ${DB_ROOT_PASSWORD}
      MYSQL_DATABASE: espocrm
      MYSQL_USER: espocrm
      MYSQL_PASSWORD: ${DB_PASSWORD}
    volumes: [mysql-data:/var/lib/mysql]

  espocrm:
    image: espocrm/espocrm:latest        # **pin version in prod**
    environment:
      ESPOCRM_DATABASE_HOST: mysql
      ESPOCRM_DATABASE_USER: espocrm
      ESPOCRM_DATABASE_PASSWORD: ${DB_PASSWORD}
      ESPOCRM_ADMIN_USERNAME: admin
      ESPOCRM_ADMIN_PASSWORD: ${ADMIN_PASSWORD}
      ESPOCRM_SITE_URL: https://crm.example.com
    volumes:
      - espocrm-data:/var/www/html
    ports: ["8080:80"]
    depends_on: [mysql]

volumes:
  mysql-data: {}
  espocrm-data: {}
```

## First boot

1. Start → browse `:8080`
2. Complete setup wizard (admin creds already env-set)
3. Configure SMTP for email workflows
4. Configure IMAP for email-to-lead import (optional)
5. Import contacts (CSV or integrate email)
6. Customize entities + fields for your workflow
7. Create workflow automations
8. Enable 2FA for admin + sensitive roles
9. Put behind TLS reverse proxy
10. Back up DB

## Data & config layout

- DB — all CRM data (contacts, leads, opportunities, tickets)
- `/var/www/html/data/` — uploads, logs, cache
- `/var/www/html/config.php` — site config
- Attachments directory

## Backup

```sh
docker compose exec mysql mysqldump -u root -p${DB_ROOT_PASSWORD} espocrm > espocrm-$(date +%F).sql
sudo tar czf espocrm-data-$(date +%F).tgz espocrm-data/
```

## Upgrade

1. Releases: <https://github.com/espocrm/espocrm/releases>. Active + frequent.
2. **Back up BEFORE upgrade.**
3. Upgrade: admin panel wizard OR Docker image pull + migrations
4. Extensions: may need updating; check compatibility matrix

## Gotchas

- **CUSTOMER DATA = GDPR/CCPA-REGULATED**:
  - CRM = database of contact PII
  - EU customers = GDPR applies (lawful basis, DPIA for marketing, DSAR workflow, right-to-erasure)
  - California customers = CCPA applies
  - Marketing campaigns = PECR (EU ePrivacy) for electronic communications
  - **69th tool in hub-of-credentials family — Tier 2 with customer-PII-density + regulatory-obligation**
  - **Sub-family reinforced: "customer-relationship-data-regulatory-risk"** (Peppermint 99 tickets was precedent; EspoCRM is 2nd tool — sub-family now 2 tools named)
  - **NEW sub-family formalized: "customer-relationship-data-regulatory-risk"** — 2 tools; EspoCRM + Peppermint
- **EMAIL INTEGRATION = MULTI-DIRECTIONAL PII FLOW**:
  - IMAP to pull customer emails → into CRM
  - SMTP to send from CRM to customers
  - **Mailing lists = PECR/GDPR lawful-basis required** (opt-in explicit)
  - Unsubscribe handling = mandatory under CAN-SPAM + GDPR
  - **Recipe convention: "bidirectional-email-CRM-integration-GDPR-scope" callout**
- **CUSTOM ENTITIES = PLATFORM CAPABILITY**:
  - EspoCRM is "more than CRM; platform for business apps"
  - Similar pattern: Salesforce Platform, Zoho Creator
  - Build project-tracking, inventory, HR, custom workflows atop CRM foundation
- **PHPSTAN LEVEL 8 = STRONG QUALITY SIGNAL**:
  - Level 8 is the strictest PHPStan level (static typing + strict checks)
  - Indicates serious engineering quality
  - **Recipe convention: "PHPStan-level-8-code-quality" positive-signal**
  - **NEW positive-signal convention** (EspoCRM 1st)
- **PHP 8.3-8.5 REQUIREMENT**:
  - EspoCRM is aggressively modern-PHP
  - PHP 8.1/8.2 not supported per README
  - Hosting providers must offer PHP 8.3+ (many still default to 8.1)
  - **Recipe convention: "aggressive-PHP-version-requirement" callout**
- **POSTGRES 15+ SUPPORT**:
  - Multi-DB support (MySQL + MariaDB + PostgreSQL)
  - PostgreSQL 15+ requirement is recent
- **COMMERCIAL-TIER (EspoCRM Commercial)**:
  - EspoCRM offers commercial support + enterprise features via commercial entity
  - Extension marketplace
  - **Commercial-tier-taxonomy: open-core-with-commercial-extensions** — distinct from "fully-functional-OSS" (most features in OSS; some enterprise-only features sold)
  - **NEW sub-category in commercial-tier-taxonomy: "open-core-with-commercial-extensions"** — 1st tool named (EspoCRM)
- **EXTENSIONS + INTEGRATIONS = ATTACK SURFACE**:
  - Third-party extensions = code in your CRM
  - Vet extensions from trusted authors
  - **Recipe convention: "extension-marketplace-trust-boundary" callout**
- **WORKFLOW AUTOMATION = POWER + RISK**:
  - If-this-then-that workflows can email customers, create records, send webhooks
  - Misconfigured workflow = mass-email mistake / data leak
  - Test workflows carefully in staging
- **HUB-OF-CREDENTIALS TIER 2**:
  - Customer PII (contacts, leads, support cases)
  - Marketing campaign targets
  - Email/IMAP creds (for integrations)
  - OAuth tokens (Gmail/Outlook)
  - REST API tokens
  - Admin account
- **SMTP CREDS + EMAIL SENDING REPUTATION**:
  - Bulk-email from self-hosted CRM = deliverability challenge
  - Use SPF/DKIM/DMARC correctly
  - Consider SMTP relay service (SendGrid/Mailgun/Postmark) for production
  - **Recipe convention: "self-hosted-bulk-email-deliverability" callout**
- **MFA / 2FA** = offered but admin must enable; recommend org-wide enforcement
- **DOCUMENTATION QUALITY**:
  - EspoCRM has extensive docs (admin, user, developer)
  - Docker + Traefik + manual install all documented
  - **Recipe convention: "extensive-docs-covering-admin-user-developer" positive-signal**
- **LONG HISTORY + STABLE**:
  - EspoCRM is ~10+ years old
  - Mature; predictable releases
  - **Recipe convention: "decade-plus-OSS-project" positive-signal** (Gramps 103 is 2-decade precedent; EspoCRM 1-decade)
- **INSTITUTIONAL-STEWARDSHIP**: EspoCRM commercial entity + community + professional services. **55th tool — founder-with-commercial-tier-funded-development sub-tier (4 tools or more now).**
- **TRANSPARENT-MAINTENANCE**: active + PHPStan-level-8 + comprehensive-docs + Docker + Traefik + demo + releases. **63rd tool in transparent-maintenance family.**
- **CRM-CATEGORY (crowded):**
  - **EspoCRM** — PHP; open-source; customizable
  - **SuiteCRM** — PHP; SugarCRM fork
  - **Crater** — Laravel; invoicing + CRM
  - **CiviCRM** — Drupal-integrated; nonprofit-focused
  - **Krayin** — Laravel; clean UI
  - **vTiger** — PHP; mature; commercial tier
  - **ERPNext** — full ERP including CRM; Frappe
  - **Odoo Community** — ERP + CRM; Python
  - **Monica** — personal-CRM; remembers personal relationships
  - **Commercial**: Salesforce, HubSpot, Zoho, Pipedrive, Dynamics 365, Insightly
- **ALTERNATIVES WORTH KNOWING:**
  - **SuiteCRM** — if you want SugarCRM-legacy PHP
  - **CiviCRM** — if you're nonprofit + already on Drupal/WordPress
  - **Odoo / ERPNext** — if you want full ERP with CRM built-in
  - **Krayin** — if you want newer Laravel-based
  - **Monica** — if you want personal-relationships (not business)
  - **Choose EspoCRM if:** you want modern-PHP + clean-UI + customizable + GPL-3.0 + developer-friendly.
- **PROJECT HEALTH**: active + PHPStan-8 + docs + Docker + Traefik + commercial-entity. STRONG signals.

## Links

- Repo: <https://github.com/espocrm/espocrm>
- Website: <https://www.espocrm.com>
- Demo: <https://www.espocrm.com/demo/>
- Docs: <https://docs.espocrm.com>
- Docker install: <https://docs.espocrm.com/administration/docker/installation/>
- SuiteCRM (alt): <https://suitecrm.com>
- CiviCRM (alt nonprofit): <https://civicrm.org>
- Krayin (alt Laravel): <https://krayincrm.com>
- Odoo (alt ERP): <https://www.odoo.com>
- ERPNext (alt ERP): <https://erpnext.com>
- vTiger (alt): <https://www.vtiger.com>
- Monica (alt personal): <https://www.monicahq.com>
- Salesforce (commercial original): <https://www.salesforce.com>
