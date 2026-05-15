# ERPNext

100% open-source, full-featured ERP system covering accounting, inventory, manufacturing, HR, payroll, CRM, project management, and more. Built on the Frappe Framework (Python + JavaScript). 33K+ GitHub stars. Upstream: <https://github.com/frappe/erpnext>. Docs: <https://docs.frappe.io/erpnext>.

> **Architecture note:** ERPNext runs on the **Frappe Bench** framework — a multi-app, multi-site platform. The canonical self-hosted install method is via `frappe_docker`. ERPNext + Frappe Framework are separate repos that run together.

## Compatible install methods

Verified against upstream README and <https://github.com/frappe/frappe_docker>.

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose (frappe_docker) | `git clone https://github.com/frappe/frappe_docker` | ✅ | **Recommended.** Production-grade, maintained by Frappe. |
| Quick eval (pwd.yml) | `docker compose -f pwd.yml up -d` | ✅ | Throwaway demo. Not for production. |
| Bench (bare metal) | `https://github.com/frappe/bench` | ✅ | Advanced users. Full control. |
| Frappe Cloud | <https://frappecloud.com> | ✅ (hosted) | Managed hosting by Frappe team. |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| domain | "Domain name for ERPNext (e.g. `erp.example.com`)?" | Free-text | Production |
| admin_password | "Initial Administrator password?" | Free-text (sensitive) | All |
| db_password | "MariaDB root password?" | Free-text (sensitive) | All |

## Software-layer concerns

### Quick demo (disposable — not for production)

```bash
git clone https://github.com/frappe/frappe_docker
cd frappe_docker
docker compose -f pwd.yml up -d
```

Wait ~3 minutes for site creation. Visit `http://localhost:8080`.
- Username: `Administrator`
- Password: `admin`

### Production setup (frappe_docker)

The frappe_docker repo has comprehensive documentation for production deployments with:
- Traefik reverse proxy + auto-TLS
- MariaDB (separate container)
- Redis (cache + queue)
- Nginx (static assets)
- Background workers (Frappe queue)

Follow the official guide: <https://github.com/frappe/frappe_docker/blob/main/docs/production.md>

Key steps:
1. Clone `frappe_docker`
2. Copy and configure `.env` (set `FRAPPE_VERSION`, `DB_PASSWORD`, `ADMIN_PASSWORD`, domain)
3. Create `docker-compose.override.yml` for Traefik/custom config
4. `docker compose --project-name frappe up -d`
5. Run site creation: `docker compose exec backend bench new-site mysite.example.com --admin-password admin --db-root-password dbpassword`
6. Install ERPNext: `docker compose exec backend bench --site mysite.example.com install-app erpnext`

### Architecture

ERPNext runs as multiple services:

| Service | Role |
|---|---|
| `backend` | Frappe/ERPNext Python app (gunicorn) |
| `frontend` | Nginx serving static assets + reverse proxy to backend |
| `worker-*` | Background job workers (short/long/default queues) |
| `scheduler` | Cron-like job scheduler |
| `redis-*` | Cache, queue, and socketio Redis instances |
| `db` | MariaDB 10.6+ |
| `traefik` | TLS termination and reverse proxy (production) |

### Key environment variables

| Variable | Purpose |
|---|---|
| `FRAPPE_VERSION` | Frappe framework version tag (e.g. `v16.x.x`) |
| `ERPNEXT_VERSION` | ERPNext app version tag |
| `DB_PASSWORD` | MariaDB root password |
| `ADMIN_PASSWORD` | ERPNext Administrator password |
| `LETSENCRYPT_EMAIL` | Email for Let's Encrypt TLS certs (Traefik) |
| `SITES` | Comma-separated site names managed by nginx |

### Bench CLI basics

```bash
# Get shell in backend container
docker compose exec backend bash

# Common bench commands
bench --site mysite.example.com migrate          # Apply DB migrations
bench --site mysite.example.com install-app erpnext
bench --site mysite.example.com set-admin-password newpass
bench --site mysite.example.com backup
bench restart                                     # Restart services
```

### Data directories

| Path | Contents |
|---|---|
| `sites/` volume | Site data — databases (as MariaDB dumps), files, private files |
| `logs/` volume | Frappe/ERPNext logs |
| MariaDB data volume | Database files |

Backup creates `.sql.gz` + `files.tar` per site. Official backup: `bench --site mysite backup`.

## Upgrade procedure

1. Update `FRAPPE_VERSION` and `ERPNEXT_VERSION` in `.env`
2. `docker compose pull`
3. `docker compose up -d`
4. `docker compose exec backend bench --site all migrate`

Check the ERPNext upgrade notes before each major version: <https://github.com/frappe/erpnext/wiki/Upgrade-Guides>.

## Gotchas

- **Not a simple single-container app.** ERPNext requires 7+ services (backend, workers, scheduler, redis ×2, MariaDB, nginx). Plan accordingly.
- **Version pinning is important.** Always pin `FRAPPE_VERSION` and `ERPNEXT_VERSION` together — they must be compatible. Check the ERPNext release notes for the matching Frappe version.
- **`pwd.yml` is for demos only.** It uses a single container and is not suitable for production. Data may be lost on restart.
- **MariaDB, not MySQL.** ERPNext officially supports MariaDB 10.6+. MySQL is not supported.
- **Site ≠ instance.** Frappe supports multiple "sites" (tenants) in one Bench instance. Each site has its own database but shares the app code.
- **Custom apps.** ERPNext supports a rich ecosystem of custom Frappe apps. Install via `bench get-app <app> && bench --site mysite install-app <app>`.
- **License: GPL v3.** Fully open-source.

## Links

- Upstream: <https://github.com/frappe/erpnext>
- Docs: <https://docs.frappe.io/erpnext>
- frappe_docker: <https://github.com/frappe/frappe_docker>
- Production guide: <https://github.com/frappe/frappe_docker/blob/main/docs/production.md>
- Bench CLI: <https://github.com/frappe/bench>
- Frappe Cloud (managed): <https://frappecloud.com>
