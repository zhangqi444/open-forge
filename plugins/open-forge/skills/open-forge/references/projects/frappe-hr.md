---
name: frappe-hr
description: Frappe HR recipe for open-forge. Covers Docker Compose dev setup and bench-based production install. Open-source HR and Payroll software built on Frappe Framework; covers employee lifecycle, leave/attendance, payroll, expense claims, and performance management. Sourced from https://github.com/frappe/hrms and https://docs.frappe.io/hr/.
---

# Frappe HR (HRMS)

Open-source HR and Payroll software built on [Frappe Framework](https://github.com/frappe/frappe). Covers 13+ HR modules: employee lifecycle, onboarding, leave and attendance, expense claims, payroll, taxation, performance appraisals, and a mobile app. Originally part of ERPNext, split into a standalone product at v14. Upstream: https://github.com/frappe/hrms. Docs: https://docs.frappe.io/hr/. GPL-3.0.

Frappe HR requires Frappe Framework and can optionally integrate with ERPNext (accounting integration for expense claims).

## Compatible install methods

| Method | Upstream | When to use |
|---|---|---|
| Docker Compose (dev) | https://github.com/frappe/hrms/tree/develop/docker | Local development |
| bench (frappe-bench) | https://docs.frappe.io/hr/installation | Production self-hosted |
| Frappe Cloud | https://frappecloud.com/hrms/signup | Managed hosting; out of scope |

## Inputs to collect

| Phase | Prompt | Applicability |
|---|---|---|
| preflight | "Docker dev or bench production install?" | Drives path |
| domain | "Site name / domain?" | e.g., hr.example.com |
| database | "MariaDB root password?" | bench install requires MariaDB |
| admin | "Administrator password?" | Default: admin (change immediately) |

## Docker Compose (development)

```sh
git clone https://github.com/frappe/hrms
cd hrms/docker
docker-compose up
```

Wait for the setup script to create the site (may take a few minutes). Access at http://localhost:8000.

Default credentials: `Administrator` / `admin`

## bench production install (Ubuntu 22.04)

```sh
# Install bench
pip install frappe-bench

# Init bench with Frappe 15
bench init --frappe-branch version-15 frappe-bench
cd frappe-bench

# Create site
bench new-site hr.example.com --mariadb-root-password <root_pw> --admin-password <admin_pw>

# Install Frappe HR
bench get-app hrms
bench --site hr.example.com install-app hrms

# Production setup
sudo bench setup production frappe
bench --site hr.example.com set-maintenance-mode off
```

## Key ports (bench default)

| Port | Purpose |
|---|---|
| 8000 | Web UI (dev mode) |
| 80/443 | Nginx (production mode, via supervisor) |
| 8002 | Frappe socketio / realtime updates |

## Upgrade procedure

```sh
cd frappe-bench
bench update --pull
bench --site hr.example.com migrate
bench restart
```

For Docker: pull latest image, recreate, then access `/update` from the admin UI or run `bench migrate` inside the container.

## Gotchas

- **Frappe Framework dependency** — Frappe HR runs on Frappe Framework; minimum version is Frappe v15 for HRMS v2+. ERPNext is optional but enables accounting integration.
- **MariaDB only** — Frappe Framework requires MariaDB (not MySQL or PostgreSQL); MySQL may work but is unsupported.
- **Single site vs multi-site** — bench supports multi-tenancy; each site is a separate database with its own domain. Default `docker-compose` creates one site.
- **Supervisor + Redis required** — Production mode uses Supervisor to manage workers and Redis for queue/cache; `bench setup production` configures these.
- **Mobile app** — Frappe HR has a PWA and native mobile apps; they connect to the same bench site via REST API.
- **ERPNext integration** — If ERPNext is installed on the same bench, HR expense claims automatically sync with ERPNext accounts; this is optional.
- **License** — GPL-3.0; Frappe Cloud managed hosting is commercial.

## Links

- GitHub: https://github.com/frappe/hrms
- Documentation: https://docs.frappe.io/hr/introduction
- Frappe Framework: https://github.com/frappe/frappe
- bench tool: https://github.com/frappe/bench
- Docker setup: https://github.com/frappe/hrms/tree/develop/docker
