---
name: frappe-erpnext-project
description: Frappe/ERPNext recipe for open-forge. GPL-3.0 full-featured open-source enterprise resource planning system built on the Frappe framework — accounting, inventory, sales, purchasing, manufacturing, CRM, HR/payroll, projects, assets. Self-host is NON-TRIVIAL (12+ service container stack: frontend nginx, backend gunicorn, websocket, scheduler, short/long queue workers, configurator job, MariaDB, Redis cache + queue, site-create job). Upstream ships `compose.yaml` as the base + `overrides/` for DB choice, HTTPS, custom apps. Strongly recommend `frappe_docker` repo's layered overrides approach over hand-crafted compose. Covers `pwd.yml` demo, production compose via overrides, `bench` CLI concepts, and the frappe_docker docs as the canonical source.
---

# Frappe / ERPNext

GPL-3.0 full-featured enterprise resource planning platform. Upstream (ERPNext app): <https://github.com/frappe/erpnext>. Upstream (Docker orchestration): <https://github.com/frappe/frappe_docker>. Docs: <https://frappe.github.io/frappe_docker/>. Product site: <https://erpnext.com>.

**Two projects, one stack:**

- **Frappe** — the web framework ERPNext is built on (Python + Node, forms + reports + workflow engine + REST API)
- **ERPNext** — the ERP application on top of Frappe (accounting, inventory, HR, CRM, etc.)

You install both together via the `frappe_docker` repository, which packages them + all their dependencies (MariaDB/Postgres, Redis, background workers, websocket server, etc.) as a Docker Compose stack.

## Features (ERPNext)

- **Accounting** — GL, AR/AP, multi-currency, tax, budgets, fixed assets
- **Inventory** — warehouses, stock ledger, batch/serial tracking, reorder rules
- **Sales** — quotations, sales orders, delivery notes, customer portal
- **Purchasing** — RFQs, purchase orders, receipts, supplier scorecards
- **Manufacturing** — BOM, production planning, subcontracting, job cards
- **CRM** — leads, opportunities, customers, email integration
- **HR + Payroll** — employees, attendance, leave, payroll (country-specific)
- **Projects + Timesheets**
- **Multi-company, multi-tenant** (single deploy, many companies)
- **REST API** + webhooks + scripting
- **Customization** via DocType builder (no-code) and custom apps (Python)

## ⚠️ Self-host is heavyweight

From `frappe_docker/compose.yaml` (inspected), a production ERPNext deploy runs **all of these containers:**

- `configurator` — one-shot init job
- `backend` — main Frappe app (Gunicorn)
- `frontend` — Nginx serving built assets + reverse-proxying to backend
- `websocket` — Socket.IO for real-time UI updates
- `queue-short`, `queue-long` — background job workers (two queues)
- `scheduler` — cron-style task runner
- `db` — MariaDB 10.6 or Postgres (choose one via override)
- `redis-cache`
- `redis-queue`
- `create-site` — one-shot site provisioning job (per-site)

So: **10-12 containers, ~2GB RAM minimum, ~8GB RAM comfortable**. This is not a "docker-compose up one container" deploy.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| `frappe_docker` Compose (production) | <https://github.com/frappe/frappe_docker> | ✅ Recommended for self-host | Production. Uses base `compose.yaml` + overrides from `overrides/`. |
| `pwd.yml` disposable demo | <https://github.com/frappe/frappe_docker/blob/main/pwd.yml> | ✅ | 5-minute try-it-out. **NOT for production.** Cannot install custom apps. |
| Frappe Cloud | <https://frappecloud.com> | ✅ | Managed hosting from the Frappe team. Free tier available. |
| Helm chart (Kubernetes) | <https://github.com/frappe/helm> | ✅ | K8s deployments. |
| `bench` bare-metal (legacy) | <https://github.com/frappe/bench> | ✅ | Not recommended for new deploys — upstream pushes containers. |
| Community LXC / one-click VPS | Various (DigitalOcean Marketplace, Linode, etc.) | ⚠️ 3rd party | Fine for single-tenant small deploys. |

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Install method?" | `AskUserQuestion`: `compose-production` / `pwd-demo` / `helm-k8s` / `frappe-cloud` | Drives section. |
| preflight | "Is this host ≥ 2 CPU, 4 GB RAM, 40 GB disk?" | Boolean | Minimum viable. 8GB RAM for comfort. |
| db | "Database backend?" | `AskUserQuestion`: `mariadb (default, most tested)` / `postgres` | Both supported; MariaDB is the default and most tested. Postgres is via an override. |
| db | "DB root password?" | Free-text (sensitive) | Set in `.env` as `DB_PASSWORD`. |
| dns | "Public domain(s)?" | Free-text | One domain per site, or use subdomains (`erp.example.com`). Multi-site supported. |
| tls | "HTTPS source?" | `AskUserQuestion`: `traefik-letsencrypt (via overlay)` / `external-reverse-proxy` | `frappe_docker` has a `overrides/compose.https.yaml` that adds Traefik. |
| erpnext | "Install ERPNext or Frappe-only?" | `AskUserQuestion` | The default image `frappe/erpnext` includes both. For Frappe-only (e.g. CRM, Helpdesk, no ERP), use `frappe/frappe-worker`. |
| custom | "Custom apps to build into the image?" | List | Requires building a custom image via `frappe_docker/images/` — documented in `docs/02-setup/02-build-setup.md`. |
| admin | "Admin password for the first site?" | Free-text (sensitive) | Set via `ADMIN_PASSWORD` env for the `create-site` job. |

## Install — Disposable demo (`pwd.yml`)

Fastest way to try ERPNext for 5 minutes:

```bash
git clone https://github.com/frappe/frappe_docker
cd frappe_docker
docker compose -f pwd.yml up -d
# Wait 2-5 minutes for the create-site job to finish
# Watch it:
docker compose -f pwd.yml logs -f create-site
```

Open `http://localhost:8080/`.

- Username: `Administrator`
- Password: `admin`

**Demo caveats (per upstream):**

> **This setup is intended for short-lived evaluation only.** You will not be able to install custom apps to this setup.

Do NOT put `pwd.yml` in production.

## Install — Production Compose (via overrides)

The canonical path is documented at <https://github.com/frappe/frappe_docker/blob/main/docs/01-getting-started/01-choosing-a-deployment-method.md> — summary:

```bash
git clone https://github.com/frappe/frappe_docker
cd frappe_docker

# 1. Create .env from template
cp example.env .env
# Edit .env — set DB_PASSWORD, ERPNEXT_VERSION (pin a version, e.g. v16.16.0), SITES (domain list), etc.

# 2. Compose stack = base + chosen overrides
docker compose \
  --project-name erpnext \
  --env-file .env \
  -f compose.yaml \
  -f overrides/compose.mariadb.yaml \
  -f overrides/compose.redis.yaml \
  -f overrides/compose.https.yaml \
  -f overrides/compose.backup-cron.yaml \
  config > /tmp/docker-compose.yml

# 3. Bring it up
docker compose --project-name erpnext -f /tmp/docker-compose.yml up -d

# 4. Create the first site
docker compose --project-name erpnext exec backend \
  bench new-site --admin-password=<strong-password> \
                 --db-root-password=${DB_PASSWORD} \
                 --install-app erpnext \
                 erp.example.com
```

### Available overrides (from `overrides/`)

- `compose.mariadb.yaml` — bundles MariaDB 10.6
- `compose.postgres.yaml` — bundles Postgres 16
- `compose.redis.yaml` — bundles Redis containers (otherwise use external)
- `compose.https.yaml` — adds Traefik for Let's Encrypt TLS
- `compose.noproxy.yaml` — opposite: expose ports directly, no Traefik
- `compose.multi-bench.yaml` — multiple independent sites
- `compose.backup-cron.yaml` — scheduled backups to object storage
- `compose.erpnext.yaml` — add the ERPNext image variant
- `compose.build.yaml` — build custom image on the fly

See <https://github.com/frappe/frappe_docker/tree/main/overrides> for the current list.

### Bench CLI (inside the `backend` container)

`bench` is Frappe's management CLI — think of it like a combined `manage.py`, `rake`, and `artisan`. Run it via:

```bash
docker compose --project-name erpnext exec backend bench --help
docker compose --project-name erpnext exec backend bench new-site ...
docker compose --project-name erpnext exec backend bench backup --with-files
docker compose --project-name erpnext exec backend bench --site erp.example.com migrate
docker compose --project-name erpnext exec backend bench install-app hrms
```

## Install — Kubernetes (Helm chart)

```bash
helm repo add frappe https://helm.erpnext.com
helm repo update
helm install erpnext frappe/erpnext \
  --set image.tag=v16.16.0 \
  --set mariadb.enabled=true \
  --set persistence.worker.enabled=true \
  ...
# See https://helm.erpnext.com for full values.yaml
```

## Data layout

Docker volumes (per the production compose):

| Volume | Content | Backup? |
|---|---|---|
| `sites` | All site-specific data: `sites/<site>/private/`, `sites/<site>/public/files/`, site config | ✅ Critical |
| `db-data` (if bundled MariaDB) | MySQL/MariaDB files | ✅ Critical (OR use `bench backup` which dumps SQL into sites/) |
| `redis-cache-data` | Ephemeral cache | ❌ |
| `redis-queue-data` | Background job state | ⚠️ May want to preserve in-flight jobs |

**Preferred backup** = `bench backup --with-files` inside the `backend` container. Produces:

- `sites/<site>/private/backups/<timestamp>-<sitename>-database.sql.gz`
- `sites/<site>/private/backups/<timestamp>-<sitename>-files.tar`
- `sites/<site>/private/backups/<timestamp>-<sitename>-private-files.tar`
- `sites/<site>/private/backups/<timestamp>-<sitename>-site_config_backup.json`

Then rsync / rclone / restic those out.

The `compose.backup-cron.yaml` override automates this + pushes to S3.

## Upgrade procedure

**Always back up first.** ERPNext migrations are one-way and can take time.

### Docker

```bash
cd frappe_docker
# 1. Back up
docker compose --project-name erpnext exec backend bench --site all backup --with-files

# 2. Read release notes for the target version: https://github.com/frappe/erpnext/releases
#    Major version bumps (e.g. v14 → v15) have breaking changes; read carefully.

# 3. Bump ERPNEXT_VERSION in .env
sed -i 's/^ERPNEXT_VERSION=.*/ERPNEXT_VERSION=v16.16.0/' .env

# 4. Pull + restart
docker compose --project-name erpnext pull
docker compose --project-name erpnext up -d

# 5. Run migrations
docker compose --project-name erpnext exec backend bench --site all migrate
```

**Version skipping.** Don't jump multiple major versions (e.g. v13 → v15). Go v13 → v14 → v15, running migrations in between.

## Multi-site

One `frappe_docker` stack can host many sites (different domains, different companies, different databases) in a single backend. Each site has its own database schema + files. Create each:

```bash
docker compose exec backend bench new-site client1.example.com --install-app erpnext --admin-password=...
docker compose exec backend bench new-site client2.example.com --install-app erpnext --admin-password=...
```

The `frontend` Nginx routes based on the `Host` header. DNS must point all site domains at your host.

## Gotchas

- **Don't use `pwd.yml` in production.** Seriously. Upstream explicitly warns. It's a single-container disposable demo.
- **The base `compose.yaml` alone is NOT enough.** It requires at least one DB override + one Redis override + one deployment override. Running `docker compose -f compose.yaml up` without overrides will fail with "cannot find db host."
- **`sites` volume is gold.** It contains site configs (including DB credentials) and user-uploaded files (`public/files`, `private/files`). Losing it = losing the ERP.
- **MariaDB 10.6 specifically.** ERPNext has known incompatibilities with MySQL 8 (some utf8mb4 defaults) and MariaDB 10.5. Stick to 10.6 as bundled.
- **`bench migrate` can take hours** on large databases or major version jumps. Run in a screen/tmux session. Don't interrupt mid-migration.
- **Background jobs fail silently if queue workers are down.** Emails, scheduled reports, integrations — all require `queue-short` and `queue-long` healthy. Monitor their logs.
- **`Administrator` user is omnipotent.** Default creation. Set a strong password, enable 2FA, create per-person users for actual use. Don't share the `Administrator` login.
- **Custom apps = rebuild the image.** You can't just `pip install` a custom app at runtime in a container; custom apps need to be baked into a custom image. See `docs/02-setup/02-build-setup.md`. OR use `bench get-app <url>` inside a dev container and commit the resulting state — but that doesn't survive container recreation.
- **Scheduler only fires jobs for enabled sites.** Each site in `sites/currentsite.txt` (or `sites/apps.txt`) needs to be enabled with `bench --site <name> enable-scheduler`.
- **Timezone:** Set in `sites/<site>/site_config.json` or via the UI per company. Wrong TZ = wrong report cut-offs, late timesheets.
- **File uploads default max = 25MB.** For larger files, adjust `CLIENT_MAX_BODY_SIZE` env on the `frontend` container (maps to Nginx's `client_max_body_size`).
- **WebSocket traffic needs the `websocket` container reachable at the same origin.** Reverse proxy config must route `/socket.io/` to `websocket:9000`. The provided `frontend` Nginx handles this; if you replace with your own reverse proxy, replicate the rules.
- **HTTPS redirects are a common footgun.** If Frappe thinks it's being hit over HTTP but the reverse proxy is HTTPS, it generates HTTP URLs in emails/notifications, and some internal redirects become redirect loops. Set `UPSTREAM_REAL_IP_HEADER=X-Forwarded-For` and ensure your reverse proxy sends `X-Forwarded-Proto: https`.
- **Email (SMTP) config is per-site, not global.** Each site has its own Email Domain + Email Account records. Without email, password resets and workflow notifications don't work.
- **Licensing:** GPL-3.0 means any modifications you distribute must also be GPL-3.0. For internal use only, no restrictions. For SaaS with modifications, read the AGPL-like obligations carefully.
- **Country-specific payroll, tax, and compliance features** are maintained by community contributions and quality varies by country. Check <https://github.com/frappe/erpnext/labels/country:> for your country before committing.
- **Support.** GitHub issues + forum (<https://discuss.frappe.io>) — no paid support unless you use Frappe Cloud or a certified partner. Community is active; responses aren't guaranteed.

## Links

- Upstream ERPNext: <https://github.com/frappe/erpnext>
- Upstream Docker orchestration: <https://github.com/frappe/frappe_docker>
- Docker docs site: <https://frappe.github.io/frappe_docker/>
- Choosing a deployment method: <https://github.com/frappe/frappe_docker/blob/main/docs/01-getting-started/01-choosing-a-deployment-method.md>
- Production docs: <https://github.com/frappe/frappe_docker/tree/main/docs/03-production>
- Overrides dir: <https://github.com/frappe/frappe_docker/tree/main/overrides>
- ERPNext docs: <https://docs.erpnext.com>
- Frappe framework: <https://github.com/frappe/frappe>
- Bench CLI: <https://github.com/frappe/bench>
- Helm chart: <https://github.com/frappe/helm>
- Frappe Cloud: <https://frappecloud.com>
- Community forum: <https://discuss.frappe.io>
- Telegram: <https://t.me/frappedevs>
