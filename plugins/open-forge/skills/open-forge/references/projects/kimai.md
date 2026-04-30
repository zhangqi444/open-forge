---
name: Kimai
description: "Professional open-source time-tracker — freelance + teams up to hundreds of users. PHP/Symfony + MySQL/MariaDB. Invoicing, exports, multi-timer, tagging, multi-user/timezone/language, SAML/LDAP/2FA, budgets, advanced reporting, plugin marketplace. MIT (core)."
---

# Kimai

Kimai is **the #1 open-source time-tracking application** — used by freelancers all the way up to companies with hundreds of users. Professional-grade; maintained since early 2000s (Kimai 1 → Kimai 2 modern rewrite on Symfony). Self-hostable; commercial cloud at <https://www.kimai.cloud>; **plugin marketplace** with paid + free plugins funds upstream.

Developed + maintained by **Kevin Papst** and team via the **Kimai** project; disciplined release cadence (every few weeks); 30+ language translations via Weblate.

Features (per upstream):

- **Time tracking**: multi-timer, punch-in / punch-out, tagging, timesheets
- **JSON API** — full-featured REST
- **Invoicing** — generate invoices from tracked time
- **Data export** — CSV, Excel, PDF
- **Rates**: user / customer / project-specific
- **Budgets**: money + time budgets with alerts
- **Advanced search + filtering**
- **Reporting**: charts, exports, summaries
- **Auth**: SAML / LDAP / database + **2FA (TOTP)**
- **Multi-user / multi-team** with customizable role + team permissions
- **Multi-timezone + 30+ language translations**
- **Responsive design** — mobile + tablet + desktop
- **Plugins** — paid + free marketplace

Requirements:
- PHP 8.2+ (8.3, 8.4, 8.5 supported)
- MariaDB ≥ 10.6 (LTS) or MySQL ≥ 8.4
- Webserver + **subdomain** (subdirectory NOT supported)
- PHP extensions: `gd`, `intl`, `json`, `mbstring`, `pdo`, `tokenizer`, `xml`, `xsl`, `zip`

- Upstream repo: <https://github.com/kimai/kimai>
- Homepage: <https://www.kimai.org>
- Docs: <https://www.kimai.org/documentation/>
- Blog: <https://www.kimai.org/blog/>
- Newsletter: <https://www.kimai.org/en/newsletter>
- Weblate translations: <https://hosted.weblate.org/engage/kimai/>
- Wall of love: <https://love.kimai.org>
- Plugin marketplace: <https://www.kimai.org/store/>
- Docker Hub: <https://hub.docker.com/r/kimai/kimai2>
- Cloud: <https://www.kimai.cloud/>
- Upgrading guide: <https://github.com/kimai/kimai/blob/main/UPGRADING.md>
- Packagist: <https://packagist.org/packages/kimai/kimai>
- Discussions: <https://github.com/kimai/kimai/discussions>
- Roadmap: <https://github.com/orgs/kimai/projects/2>

## Architecture in one minute

- **PHP 8.2+ / Symfony** monolith
- **MariaDB / MySQL** primary store (no Postgres support)
- **Webserver**: Apache or nginx (or Caddy) + PHP-FPM
- **Resource**: small — typical PHP app; scales to hundreds of users on modest hardware
- **Deployment via subdomain** (not subdirectory — docs are explicit)

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Single VM          | **Caddy + Docker-Compose** (Hetzner/DigitalOcean upstream guides)   | **Upstream-primary**                                                               |
| Classic hosting    | SSH + Git + Composer ("[SSH setup](https://www.kimai.org/documentation/installation.html)") | Traditional PHP deploy                                                                     |
| Docker             | **`kimai/kimai2`** (FPM only or with Apache variants)                                           | Docker Hub                                                                                              |
| Synology NAS       | Docker variant; upstream docs                                                                    | Home office                                                                                                          |
| Managed            | **Kimai Cloud** — commercial; directly supports upstream                                                | Ethical-managed option                                                                                                         |
| Developer          | Symfony dev server setup                                                                                    | For plugin development                                                                                                         |

## Inputs to collect

| Input                | Example                                                        | Phase        | Notes                                                                    |
| -------------------- | -------------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `time.example.com` — **must be a subdomain, not `example.com/time`**    | URL          | Subdirectory is explicitly unsupported                                           |
| PHP 8.2+             | with required extensions                                                | Runtime      | Extensions: gd, intl, json, mbstring, pdo, tokenizer, xml, xsl, zip                                     |
| MariaDB / MySQL      | LTS versions                                                                | DB           | No Postgres                                                                                              |
| SAML IdP (opt)       | Authentik / Keycloak / Okta / ADFS                                                    | Auth         | For org deployments                                                                                                     |
| LDAP (opt)           | OpenLDAP / AD / Kanidm LDAP gateway (batch 76)                                                  | Auth         | Same                                                                                                                     |
| SMTP                 | for invitations + password reset + 2FA recovery                                                           | Email        | Required for real use                                                                                                              |
| Admin user           | bootstrapped via CLI                                                                                     | Bootstrap    | `./bin/console kimai:user:create admin@example.com admin ROLE_SUPER_ADMIN`                                                                                                    |

## Install via Docker Compose (Caddy example)

Follow upstream guide <https://www.kimai.org/documentation/hosting-hetzner-cloud.html>. Shape:

```yaml
services:
  mysql:
    image: mysql:8.4
    environment:
      MYSQL_DATABASE: kimai
      MYSQL_USER: kimai
      MYSQL_PASSWORD: ${DB_PASSWORD}
      MYSQL_ROOT_PASSWORD: ${DB_ROOT}
    volumes:
      - mysql_data:/var/lib/mysql

  kimai:
    image: kimai/kimai2:apache                     # pin version in prod
    environment:
      DATABASE_URL: mysql://kimai:${DB_PASSWORD}@mysql/kimai?serverVersion=8.4.0&charset=utf8mb4
      APP_SECRET: ${APP_SECRET}
      TRUSTED_HOSTS: "localhost,time.example.com"
    depends_on: [mysql]

  caddy:
    image: caddy:2
    ports: ["80:80", "443:443"]
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile
      - caddy_data:/data
      - caddy_config:/config
```

## First boot

1. Bootstrap super-admin via CLI: `docker compose exec kimai bin/console kimai:user:create admin admin@example.com ROLE_SUPER_ADMIN`
2. Log in → change password → enable 2FA for admin
3. Create first customer + project + activity
4. Invite team members; assign roles/teams
5. Configure invoice template + rates
6. Set up SMTP + verify delivery
7. (If multi-org) configure SAML / LDAP
8. Install plugins from marketplace (if needed)
9. Back up DB + `.env` (APP_SECRET)

## Data & config layout

- MariaDB/MySQL — all time entries, customers, projects, users, invoices, reports
- `.env` / `.env.local` — secrets (`APP_SECRET`, `DATABASE_URL`)
- `var/` — compiled Symfony cache, logs
- `public/uploads/` — user-uploaded logos, invoice attachments

## Backup

```sh
mysqldump --single-transaction -u kimai -p kimai | gzip > kimai-$(date +%F).sql.gz
sudo tar czf kimai-files-$(date +%F).tgz public/uploads/ .env.local
```

Encrypt backups — invoicing data + customer details = business-sensitive.

## Upgrade

1. Releases every few weeks — <https://github.com/kimai/kimai/releases>.
2. **Always read `UPGRADING.md`** — version-specific steps often included.
3. Back up DB + files first.
4. Docker: pull new image → `bin/console doctrine:migrations:migrate` (or automatic on container boot).
5. Classic install: `composer install --no-dev --optimize-autoloader` + migrations.

## Gotchas

- **Subdomain REQUIRED — subdirectory NOT supported.** You cannot host Kimai at `https://example.com/kimai/`. Must be `https://kimai.example.com/`. Planning lesson: provision DNS + TLS cert BEFORE install.
- **MySQL/MariaDB only — no Postgres.** Symfony apps often support both; Kimai explicitly doesn't. If you're Postgres-standardized, this is a platform decision.
- **APP_SECRET immutability.** Same class as every-other-framework-secret (Rallly/Kan/Kener/Colanode/Statamic — batches 75-77). Set once; back up; never rotate without session + encrypted-field migration plan.
- **Business + financial data** (invoices, rates, tax info). Treat same as ezBookkeeping (batch 78): TLS mandatory, encrypted backups, retention awareness. Multi-year tax-record retention applies (5-7 years typical).
- **Plugin marketplace = paid-addon revenue for upstream.** Healthy commercial-OSS pattern (matches Statamic batch 77 Pro). Pricing varies per plugin; budget.
- **Permission model complexity**: user/customer/project-specific rates + team permissions + custom roles = rich but audit-worthy. When onboarding new users to an existing org, double-check assigned rates — default + override logic is subtle. Wrong rate = wrong invoice.
- **Invoice template customization** is powerful but template-specific. Test invoice-render thoroughly on sample data before committing to a template for real billing.
- **Time-entry editability**: by default users can edit past entries. For audit-trail / compliance contexts (legal billing, regulated industries), enable lock-previous-periods policy.
- **Budgets don't enforce hard stops** — they alert at thresholds. Over-budget work still tracks. Notification-not-enforcement design.
- **Multi-language Weblate translations** — contribute back if your language has gaps. Community-driven; some languages <100% complete.
- **CI build status + code coverage badges visible**: healthy engineering practice signal.
- **Roadmap public on GitHub Projects**: <https://github.com/orgs/kimai/projects/2>. Feature-request transparency.
- **Comparison to Toggl/Harvest**: Toggl/Harvest = commercial SaaS; polished; pricy per-seat. Kimai = self-hosted; feature-rich; one-time hosting cost. For consulting/agency scale (10+ trackers), Kimai saves significant money long-term.
- **Comparison to Clockify**: Clockify has aggressive free tier. For independents it's hard to beat. Kimai wins for self-host-preferred + privacy + integration-rich orgs.
- **Comparison to TimeCamp / Hubstaff / Time Doctor**: Kimai has fewer automatic-tracking/surveillance features (screenshot monitoring, activity heatmaps). If you want surveillance, these are different category. If you want time-entry-first, Kimai is the good citizen.
- **License**: **MIT** (core). Plugins can have own licenses.
- **Project health**: sustained commercial + community + cloud tier. Excellent long-term bet.
- **Alternatives worth knowing:**
  - **Toggl / Harvest / Clockify** — commercial SaaS
  - **TimeTagger** — Python; simpler scope
  - **actiTIME / Tempo / Timely** — enterprise SaaS
  - **Traggo** — minimal self-host time tracker (low feature set)
  - **Stalwart** (batch earlier) — NO, wrong domain
  - **Choose Kimai if:** full-featured self-hosted time tracker + invoicing + team RBAC + plugin ecosystem.
  - **Choose Clockify if:** free tier + cloud + team.
  - **Choose Toggl if:** polished commercial product + willing to pay per-seat.

## Links

- Repo: <https://github.com/kimai/kimai>
- Homepage: <https://www.kimai.org>
- Docs: <https://www.kimai.org/documentation/>
- Installation: <https://www.kimai.org/documentation/installation.html>
- Docker docs: <https://www.kimai.org/documentation/docker.html>
- Docker Hub: <https://hub.docker.com/r/kimai/kimai2>
- Releases: <https://github.com/kimai/kimai/releases>
- Upgrading guide: <https://github.com/kimai/kimai/blob/main/UPGRADING.md>
- Plugin marketplace: <https://www.kimai.org/store/>
- Developer docs: <https://www.kimai.org/documentation/developers.html>
- Weblate: <https://hosted.weblate.org/engage/kimai/>
- Cloud: <https://www.kimai.cloud/>
- Packagist: <https://packagist.org/packages/kimai/kimai>
- Toggl (alt): <https://toggl.com>
- Clockify (alt, free): <https://clockify.me>
- Harvest (alt): <https://www.getharvest.com>
