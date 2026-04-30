---
name: Dolibarr ERP & CRM
description: "Mature, modular OSS ERP + CRM — contacts, quotes, invoices, orders, inventory, accounting, HR, projects, POS, website builder. PHP + MySQL/MariaDB/Postgres. 1000+ extensions in 'Dolistore'. 20+ years mature. GPL-3.0+."
---

# Dolibarr ERP & CRM

Dolibarr is a **venerable, modular, full-featured ERP + CRM** — contacts/CRM, quotes, proposals, orders, invoices, inventory, purchasing, suppliers, accounting, HR, payroll, projects, CMMS, point-of-sale, website builder, and dozens more modules. 20+ years of development, huge plugin ecosystem, multilingual, multi-currency, widely used by SMBs across Europe + Africa + LATAM.

The "install it once, run your entire small business on it" archetype. Less sleek than Odoo; free of Odoo's commercial licensing; simpler to run.

Module highlights (all toggle-able in admin):

- **CRM** — contacts, companies, leads, opportunities, campaigns
- **Sales** — proposals, orders, invoices, credits, recurring billing
- **Purchasing** — RFQs, supplier orders, supplier invoices
- **Inventory** — warehouses, stock movements, batches/lots, serial
- **Products/Services** — SKUs, variants, pricing rules, BOM, kits
- **Accounting** — chart of accounts, ledger, tax reports, bank reconciliation
- **Projects + Tasks + Time** — time tracking, project billing, Gantt
- **HR** — employees, leave, expenses, payroll
- **POS** — retail checkout (TakePOS)
- **Website** — simple CMS
- **Emailing / Marketing** — bulk mail campaigns
- **Tickets** — helpdesk
- **Member management** — associations, subscriptions
- **Events** — registration
- **EDI / factur-X** — French-standard invoicing
- **Connectors** — Stripe, PayPal, Google Calendar, LDAP, OAuth

- Upstream repo: <https://github.com/Dolibarr/dolibarr>
- Website: <https://www.dolibarr.org>
- Docs: <https://wiki.dolibarr.org>
- Dolistore (marketplace): <https://www.dolistore.com>
- Demo: <https://demo.dolibarr.org>
- Docker Hub: <https://hub.docker.com/r/dolibarr/dolibarr>
- Forum: <https://www.dolibarr.org/forum>

## Architecture in one minute

- **PHP 7.2+** (current: 8.1+)
- **DB**: MySQL 5.7+ / MariaDB 10.3+ / Postgres 10+
- **Web server**: Apache / Nginx + PHP-FPM
- **Stateless-ish**: user data in DB; uploads in `documents/`
- **Monolithic Php codebase** — modules all live in the same app
- **Resource**: tiny (~200 MB RAM); runs on a Pi

## Compatible install methods

| Infra        | Runtime                                          | Notes                                                                |
| ------------ | ------------------------------------------------ | -------------------------------------------------------------------- |
| Single VM    | **Docker (`dolibarr/dolibarr`)**                    | **Simplest**                                                             |
| Single VM    | Native LAMP/LEMP                                       | Drop tarball, run installer wizard                                         |
| Single VM    | Upstream `.deb` / `.rpm` packages                             | Easy for Debian/Ubuntu/RHEL                                                        |
| Shared host  | cPanel PHP hosting                                              | Works in 10 minutes                                                                          |
| Raspberry Pi | Docker or native                                                     | Great for small business                                                                              |
| Kubernetes   | Community manifests                                                         | Works                                                                                               |
| Managed      | **CloudBookz / Dolicloud / official cloud** (paid SaaS)                     | Community + commercial hosts                                                                                          |

## Inputs to collect

| Input              | Example                          | Phase      | Notes                                                            |
| ------------------ | -------------------------------- | ---------- | ---------------------------------------------------------------- |
| Domain             | `dolibarr.example.com`              | URL        | Reverse proxy with TLS                                               |
| DB                 | MySQL/MariaDB/Postgres creds            | DB         | MariaDB most tested                                                           |
| Admin user         | created in installer wizard               | Bootstrap  | Change default on first login                                                         |
| Company settings   | name, address, tax ID, currency                | Config     | Drives invoices + accounting                                                                     |
| Modules            | enable what you need                              | Config     | Disable anything you don't; keeps UI clean                                                               |
| SMTP               | host/port/user/pass                                  | Email      | For sending invoices/quotes/reminders                                                                            |
| File storage       | `documents/` persistent volume                          | Storage    | Uploaded attachments + generated PDFs                                                                                       |

## Install via Docker Compose

```yaml
services:
  dolibarr:
    image: dolibarr/dolibarr:19                  # pin specific major
    container_name: dolibarr
    restart: unless-stopped
    depends_on: [db]
    environment:
      DOLI_DB_HOST: db
      DOLI_DB_USER: dolibarr
      DOLI_DB_PASSWORD: <strong>
      DOLI_DB_NAME: dolibarr
      DOLI_URL_ROOT: https://dolibarr.example.com
      DOLI_ADMIN_LOGIN: admin
      DOLI_ADMIN_PASSWORD: <strong>
      DOLI_INIT_DEMO: "0"                          # 1 = seed sample data
      DOLI_COMPANY_NAME: "ACME Corp"
      DOLI_COMPANY_COUNTRYCODE: "US"
      PHP_INI_DATE_TIMEZONE: America/Los_Angeles
    volumes:
      - ./documents:/var/www/documents
      - ./custom:/var/www/html/custom
    ports:
      - "8088:80"

  db:
    image: mariadb:11
    restart: unless-stopped
    environment:
      MARIADB_ROOT_PASSWORD: <strong>
      MARIADB_DATABASE: dolibarr
      MARIADB_USER: dolibarr
      MARIADB_PASSWORD: <strong>
    volumes:
      - dolibarr-db:/var/lib/mysql

volumes:
  dolibarr-db:
```

## Install natively (Debian)

```sh
sudo apt install dolibarr
# Configure Apache/Nginx docroot to point at /usr/share/dolibarr/htdocs
# Browse https://dolibarr.example.com → install wizard runs
```

Or tarball install:

```sh
cd /var/www
wget https://github.com/Dolibarr/dolibarr/releases/download/19.0.0/dolibarr-19.0.0.tgz
tar xzf dolibarr-19.0.0.tgz
# Set permissions, web server docroot → dolibarr/htdocs
# Browse /install/ → follow wizard
```

## First boot

1. Browse → install wizard detects prereqs, creates DB schema
2. Set admin login + password
3. Post-install: **IMPORTANT** — delete or protect `install/` directory (block access):
   ```sh
   rm -rf /var/www/html/install/
   # Or add a lock file as the wizard instructs
   ```
4. Log in → Home → Setup → Modules — toggle the modules you need (Products, Invoices, CRM, Accounting, etc.)
5. Setup → Company/Organization → fill in legal info (critical for invoices)
6. Setup → Taxes → configure VAT/GST rates
7. Setup → Email → configure SMTP + signature
8. Setup → PDF → pick invoice/quote templates + set logo
9. Create first customer → first quote → convert to invoice → email it

## Data & config layout

- `htdocs/conf/conf.php` — main config file (generated by wizard)
- `documents/` — uploaded attachments + generated PDFs (MUST persist)
- DB — all records (customers, products, invoices, journal entries)
- `custom/` — custom modules (if you develop or buy from Dolistore)

## Backup

```sh
# DB (CRITICAL — financial + customer data)
docker exec dolibarr-db mysqldump -u dolibarr -p dolibarr | gzip > doli-db-$(date +%F).sql.gz

# Documents
tar czf doli-docs-$(date +%F).tgz documents/

# Config
cp htdocs/conf/conf.php doli-conf-$(date +%F).bak
```

Rotate daily, retain N days, offsite. Financial data = high backup priority.

## Upgrade

1. Releases: <https://github.com/Dolibarr/dolibarr/releases>. Active (major per year, many minors).
2. **Back up DB + documents + conf.php.**
3. Docker: bump tag → `docker compose pull && docker compose up -d`. Migration wizard runs on first visit.
4. Native: download new tarball, extract OVER existing (preserving conf.php + documents/ + custom/). Browse `/install/` for migration wizard. Then protect install/ again.
5. Major version bumps: read upgrade notes; some modules rename/deprecate.

## Gotchas

- **Delete or lock `install/` after install/upgrade.** Otherwise anyone hitting `/install/` can potentially reset your DB. Always.
- **Module explosion**: Dolibarr has 100+ built-in modules + Dolistore extensions. Enabling everything makes menus overwhelming + slower. Enable only what you need; you can add more later.
- **Dolistore modules**: mostly paid (~€20-200 each). Community modules free. **Review code before installing** — Dolistore isn't curated for code quality; some modules are old / messy / unsafe.
- **Accounting module depth** varies by country — French + Spanish + German accounting is well-supported; US GAAP coverage weaker. For US, some integrate with QuickBooks or use Dolibarr for CRM + invoices only, with accounting elsewhere.
- **Invoicing legal compliance** — each country has requirements (EU VAT + e-invoicing regulations, French Factur-X, Spanish SII, Mexican CFDI). Check your country's module/plugin.
- **PDF templates** — default templates are functional but basic. Customize logo + layout in Setup → PDF. For heavy branding, custom templates go in `custom/`.
- **Multi-currency** — supported but conversion rates = manual or via a module. Check current state.
- **Multi-company / multi-tenant** — one Dolibarr instance = one company. For multi-company, use the "MultiCompany" module (paid) or run multiple instances.
- **User permissions** are fine-grained (per module, per-action); tuning takes time. Templates help.
- **Performance at scale**: <50 users, 100k invoices = fine on a small VM. >500 users = tune MySQL, use InnoDB, consider dedicated DB server.
- **Email deliverability**: configure SMTP with SPF/DKIM if sending from your domain. Invoices in spam = embarrassing.
- **LDAP/SSO** — supported via modules; enable + configure.
- **API** — REST API with keys; older SOAP also available.
- **Mobile**: responsive web; DoliDroid community Android app (limited features); no official first-party app.
- **Theme**: Eldy (default) and some alternate themes; none particularly modern.
- **CMS module** (website builder) is functional but not a Wordpress replacement — good enough for a simple business landing page.
- **POS (TakePOS)** module works on tablets; great for small retail.
- **Data migration in**: CSV imports per object (customers, products, invoices). Mass-migrate from QuickBooks/SAP/Xero = export-CSV + import-CSV + fixup.
- **Data export**: CSV export per list view; DB dumps are the real fidelity.
- **GPL-3.0+ license** — strong copyleft; modifications hosting for others = source disclosure. Commercial use is fine.
- **Active maintenance** — Dolibarr project is healthy; 20+ years, large community, reliable upgrade path.
- **Alternatives worth knowing:**
  - **Odoo Community** — modern Python ERP; more polished UI; heavier LGPL+proprietary tier
  - **ERPNext / Frappe** — Indian-origin; Python; very feature-rich; cloud-first
  - **Dolibarr vs Odoo Community**: Dolibarr is easier to run; Odoo has better UX + more modern code + broader functionality
  - **InvoicePlane / Invoice Ninja** — billing-only
  - **Ledger SMB / GnuCash** — accounting-focused
  - **Krayin CRM / EspoCRM / Vtiger** — CRM-focused
  - **SuiteCRM** — classic SugarCRM fork
  - **Twenty** — modern CRM (separate recipe likely)
  - **Choose Dolibarr if:** you want a mature, easy-to-run, modular ERP for SMB — especially if in EU/FR/ES/IT markets.
  - **Choose Odoo Community if:** you want the most modern OSS ERP and can manage Python deployment complexity.
  - **Choose ERPNext if:** you want the broadest OSS ERP feature set + don't mind Frappe framework.

## Links

- Repo: <https://github.com/Dolibarr/dolibarr>
- Website: <https://www.dolibarr.org>
- Docs / Wiki: <https://wiki.dolibarr.org>
- Docker Hub: <https://hub.docker.com/r/dolibarr/dolibarr>
- Dolistore (marketplace): <https://www.dolistore.com>
- Demo: <https://demo.dolibarr.org>
- Forum: <https://www.dolibarr.org/forum>
- Releases: <https://github.com/Dolibarr/dolibarr/releases>
- Developer docs: <https://wiki.dolibarr.org/index.php/Developer_documentation>
- API docs: <https://wiki.dolibarr.org/index.php/Module_Web_Services_API_REST_(developer)>
- Odoo comparison: <https://wiki.dolibarr.org/index.php/FAQ-Comparison-Odoo-Dolibarr>
- Hosted (commercial): Dolicloud / third-party providers (listed on dolibarr.org)
