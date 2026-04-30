---
name: InvenTree
description: "Open-source inventory management — parts, stock levels, suppliers, purchase orders, sales orders, BOMs, assemblies, manufacturing. Python/Django + Postgres + React frontend + Django-Q worker. Popular in electronics workshops, makerspaces, small manufacturers. MIT."
---

# InvenTree

InvenTree is **a stock-control and parts-tracking system** built for electronics workshops, makerspaces, R&D labs, and small manufacturers. It knows about: parts (with parameters, datasheets, supplier catalog), stock locations (shelves, bins, boxes), stock items (per-batch, per-serial), bills of materials (BOMs), builds (assembly with stock consumption tracking), purchase orders (from suppliers), sales orders (to customers), and manufacturing orders.

If you run a small electronics lab and keep running out of 0603 10kΩ resistors because "I thought we had more," InvenTree is what you install.

Features:

- **Parts catalog** — hierarchical categories, parameters (e.g., "Resistance: 10kΩ, Tolerance: 1%"), variants, templates, images
- **Stock locations** — hierarchical, with QR/barcode labels
- **Stock items** — per-batch + per-serial tracking, expiry dates, notes
- **BOMs** — nested, with consumables + variants
- **Build orders** — tracks parts consumed + items produced
- **Purchase orders** — to suppliers with pricing + URLs
- **Sales orders** — to customers
- **Return orders** — RMAs
- **Suppliers + Manufacturers** — multi-supplier per part, price breaks, SKUs
- **Label printing** — ZPL / PDF via configurable label templates
- **Barcode scanning** — built-in camera + serial numbers
- **Reports** — customizable Jinja2-rendered PDFs
- **Notifications** — email + webhooks
- **Plugin system** — Python plugins (pricing, import/export, label printers)
- **REST API** — well-documented; first-party Python + Mobile app bindings
- **Mobile app** — official InvenTree Mobile (iOS + Android)

- Upstream repo: <https://github.com/inventree/InvenTree>
- Website: <https://inventree.org>
- Docs: <https://docs.inventree.org>
- Demo: <https://demo.inventree.org>
- Docker install: <https://docs.inventree.org/en/latest/start/docker/>
- Docker Hub: <https://hub.docker.com/r/inventree/inventree>
- Subreddit: <https://www.reddit.com/r/InvenTree>
- Mastodon: <https://chaos.social/@InvenTree>

## Architecture in one minute

- **Python 3.9+** / Django 4+
- **DB**: Postgres (recommended) / MariaDB / MySQL / SQLite
- **Django-Q**: background worker (reports, notifications, scheduled tasks) — separate container
- **Redis**: optional cache (recommended in prod)
- **Frontend**: React (new "Platform UI") + classic Django templates (legacy)
- **Django-Allauth**: auth (incl. SSO providers)
- **Nginx** frontend for static files + reverse proxy (in Docker setup)
- **Storage**: local filesystem for uploaded images/datasheets/attachments (many GB over time)

## Compatible install methods

| Infra         | Runtime                                              | Notes                                                              |
| ------------- | ---------------------------------------------------- | ------------------------------------------------------------------ |
| Single VM     | **Docker Compose (upstream)**                              | **Recommended**                                                        |
| Single VM     | **Native (Python venv + systemd)**                                | Supported; more ops                                                           |
| DigitalOcean  | One-click marketplace droplet                                         | <https://inventree.org/digitalocean>                                                 |
| Kubernetes    | Community Helm charts; ArtifactHub listings                                   | Works                                                                                        |
| Raspberry Pi  | arm64 Docker; InvenTree runs on Pi                                                        | Fine for small workshops                                                                            |
| Managed       | Commercial hosts exist; no official SaaS                                                            | Check inventree.org                                                                                          |

## Inputs to collect

| Input             | Example                          | Phase      | Notes                                                                  |
| ----------------- | -------------------------------- | ---------- | ---------------------------------------------------------------------- |
| Domain            | `inventree.example.com`              | URL        | Reverse proxy with TLS                                                   |
| Secret key        | random 50+ chars                         | Crypto     | `INVENTREE_SECRET_KEY`                                                                  |
| DB                | Postgres creds                                 | DB         | Postgres preferred                                                                               |
| Admin             | created via `invoke superuser`                        | Bootstrap  | Or first-boot wizard                                                                                      |
| Redis             | host + port (optional)                                     | Cache      | Recommended in prod                                                                                              |
| SMTP              | host/port/user/pass                                             | Email      | For notifications + password resets                                                                                                  |
| Media storage     | persistent volume                                                       | Storage    | Datasheets + images can grow                                                                                                                   |
| Cors/Allowed hosts| `INVENTREE_ALLOWED_HOSTS`                                                           | Security   | Set to your domain                                                                                                                                    |
| Workers           | 1+ Django-Q worker container running                                                          | Ops        | **Required for scheduled + async tasks**                                                                                                                                       |

## Install via Docker (upstream)

```sh
mkdir -p inventree-data && cd inventree-data
# Download example docker-compose and env
curl -sSL https://raw.githubusercontent.com/inventree/InvenTree/master/docker/docker-compose.yml > docker-compose.yml
curl -sSL https://raw.githubusercontent.com/inventree/InvenTree/master/docker/.env > .env
# Edit .env — set passwords + domain + secret_key
docker compose run --rm inventree-server invoke update
docker compose run --rm inventree-server invoke superuser
docker compose up -d
```

See <https://docs.inventree.org/en/latest/start/docker/> for definitive steps — upstream ships a reference `docker-compose.yml`.

## First boot

1. Browse `https://inventree.example.com/`
2. Log in as superuser
3. Admin → Settings → Global Settings → set instance name, timezone, currency, allowed hosts
4. Create a **Part Category** (e.g., "Electronics > Resistors > SMD")
5. Create a **Part** (e.g., "10k 0603 1%") with parameters + supplier links
6. Create a **Stock Location** ("Lab A → Shelf 3 → Bin 12")
7. Add stock to the part + location
8. Print a label → scan barcode → verify round-trip
9. Install mobile app + generate API token for field stock adjustments

## Data & config layout

- `.env` — all secrets + config
- Postgres — relational data
- `media/` volume — uploaded images, datasheets, attachments
- `static/` volume — compiled CSS/JS
- `backup/` volume — scheduled backup output (if enabled)
- Plugins in `plugins/` (if installed)

## Backup

```sh
# Postgres
docker exec inventree-db pg_dump -U pguser inventree | gzip > iv-db-$(date +%F).sql.gz
# Media (datasheets, part images, attachments — can be large)
tar czf iv-media-$(date +%F).tgz media/
# Config
cp .env iv-env-$(date +%F).bak
```

Or use InvenTree's built-in backup task (`invoke export-records` for records; separately for media). Run via cron or Django-Q scheduled task.

## Upgrade

1. Releases: <https://github.com/inventree/InvenTree/releases>. Active (major per year + frequent minors).
2. **Back up DB + media + .env.**
3. Docker: bump `INVENTREE_TAG` in `.env`, `docker compose pull`, `docker compose run --rm inventree-server invoke update` (runs migrations), `docker compose up -d`.
4. Plugin compat — plugins may lag; test on staging first.
5. Read release notes for breaking API/schema changes.

## Gotchas

- **Django-Q worker is required** for scheduled tasks (stock alerts, scheduled reports, notifications, currency-rate updates, email sends). Upstream docker-compose includes it; if you customize, don't drop it.
- **Plugins require enabling** — Admin → Plugins → enable + sometimes restart. After enable, some plugins require DB migrations via `invoke update`.
- **Large media libraries** — datasheets for thousands of parts, component photos, attachment PDFs. Plan for 10s-100s GB over years; consider object storage (S3) via plugin.
- **Custom reports** are Jinja2 templates rendered to PDF via weasyprint — writing custom templates takes CSS/HTML knowledge.
- **Label printing** supports ZPL printers (Zebra) directly via plugin; for others, print the PDF from the app via AirPrint/CUPS.
- **Barcode scanner hardware** — any USB/Bluetooth HID scanner works as keyboard input. Dedicated scanner apps on phones also work.
- **Multi-location** — hierarchical; transfer stock via UI / API. Audit trail per stock item.
- **Pricing history** — supplier prices cached per PO date; current pricing updated via a plugin (e.g., OctoPart, Mouser integration — commercial API keys required).
- **Serial numbers** vs batch — per-part; configure per-part whether tracked.
- **Mobile app** needs the API token you generate in your account settings.
- **Mobile app scan → adjust** workflow is the killer feature for stock-taking.
- **Allauth SSO** — OIDC / SAML via django-allauth config. SAML requires extra packages.
- **InvenTree as a CRM/ERP** — it's not an ERP in the Dolibarr/Odoo sense. No accounting, no HR, no payroll. Pair with Dolibarr or similar for billing/finance; InvenTree for inventory.
- **Python version drift** — InvenTree targets a specific Python range per release. Match Docker base images.
- **Database engine choice** — Postgres is default + best; SQLite works for single-user home lab; MySQL/MariaDB supported but less-tested.
- **Currency conversion** — built-in, uses currency exchange rate service; schedules daily update.
- **Migrations on large DBs** — major-version bumps can run long; plan downtime.
- **API deprecations** — the project is on a migration from classic Django UI to new React "Platform UI" — both available in recent versions; some features first in Platform UI.
- **License**: MIT.
- **Alternatives worth knowing:**
  - **Part-DB** — older electronics parts manager (PHP); still developed
  - **Partkeepr** — popular older electronics inventory; less active
  - **Snipe-IT** — IT asset (not parts) tracker (separate recipe likely)
  - **OpenMES / Odoo Manufacturing / Dolibarr Stock** — ERP-integrated
  - **ERPNext** — generic inventory via full ERP
  - **Google Sheets / Airtable / Notion** — spreadsheet DIY
  - **Sortly** (commercial SaaS) — mobile-first inventory
  - **Choose InvenTree if:** parts + BOMs + stock tracking is the core problem (electronics, maker, labs, small mfg).
  - **Choose Part-DB if:** you want lighter + PHP + electronics-specific.
  - **Choose Snipe-IT if:** tracking laptops/phones/IT assets, not parts.
  - **Choose ERPNext / Odoo if:** need inventory inside a full ERP.

## Links

- Repo: <https://github.com/inventree/InvenTree>
- Website: <https://inventree.org>
- Docs: <https://docs.inventree.org>
- Demo: <https://demo.inventree.org>
- Docker install: <https://docs.inventree.org/en/latest/start/docker/>
- Bare-metal install: <https://docs.inventree.org/en/latest/start/install/>
- Mobile app: <https://docs.inventree.org/en/latest/app/>
- API docs: <https://docs.inventree.org/en/latest/api/>
- Python bindings: <https://docs.inventree.org/en/latest/api/python/>
- Plugin development: <https://docs.inventree.org/en/latest/plugins/>
- Extensions / integrations: <https://inventree.org/extend/integrate/>
- Releases: <https://github.com/inventree/InvenTree/releases>
- DigitalOcean one-click: <https://inventree.org/digitalocean>
- Subreddit: <https://www.reddit.com/r/InvenTree/>
- OpenSSF Best Practices: <https://bestpractices.coreinfrastructure.org/projects/7179>
