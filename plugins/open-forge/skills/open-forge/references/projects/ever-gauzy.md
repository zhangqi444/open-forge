---
name: ever-gauzy
description: Ever Gauzy recipe for open-forge. Open business management platform combining ERP, CRM, HRM, ATS, and project management. Deployed via Docker Compose. Covers demo (quick-start) and production configuration, environment variables, default credentials, and database options. Based on upstream docs at https://docs.gauzy.co and the GitHub README.
---

# Ever Gauzy

Open business management platform for collaborative, on-demand, and sharing economies. Combines ERP, CRM, HRM, ATS, and project/task management in a single platform. Upstream: <https://github.com/ever-co/ever-gauzy>. Docs: <https://docs.gauzy.co>.

**License:** AGPL-3.0

## What it includes

- **HRM** — employee management, onboarding, time tracking, activity monitoring, timesheets
- **CRM** — contacts, leads, clients, vendors, sales pipelines
- **ERP** — invoicing, accounting, billing, income/expense tracking, inventory
- **ATS** — applicant tracking, candidate interviews
- **Project Management** — tasks, goals, KPIs, OKRs
- **Reporting** — insights, analytics, dashboards
- **Integrations** — Upwork, HubStaff, GitHub, and more
- **Multi-tenancy** — multiple organizations, departments, teams, currencies, and languages

## Compatible deploy methods

| Method | Upstream reference | When to use |
|---|---|---|
| Docker Compose demo | README Quick Start → Demo | Try the platform / explore features |
| Docker Compose production | README Quick Start → Production | Self-hosted production deployment |
| Kubernetes | README (recommended for production) | Scalable production workloads |
| Docker Compose build | README Quick Start → Build | Local development / custom builds |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | Docker Compose v2.20+ installed? | Minimum required version |
| config | Database type (SQLite, PostgreSQL, MySQL, MariaDB)? | Set in `.env.compose`; SQLite is default/demo |
| config | API base URL | `http://localhost:3000` by default |
| config | Client base URL | `http://localhost:4200` by default |
| email | SMTP credentials (optional) | For email notifications and password reset |

## Quick start: Demo

Upstream reference: <https://github.com/ever-co/ever-gauzy#readme>

```bash
git clone https://github.com/ever-co/ever-gauzy.git
cd ever-gauzy

# Run demo with prebuilt images (API + Web UI + SQLite DB)
docker compose -f docker-compose.demo.yml up
```

Open <http://localhost:4200> in your browser.

**Default credentials:**
- Super Admin: `admin@ever.co` / `admin`
- Employee: `employee@ever.co` / `12345678`

> Note: On first run the API seeds seed data into the DB. This may take a few minutes.

## Production deployment

Upstream reference: <https://github.com/ever-co/ever-gauzy#readme>

```bash
git clone https://github.com/ever-co/ever-gauzy.git
cd ever-gauzy

# (Optional) Edit .env.compose to set your DB type, URLs, SMTP, etc.
# Then start in detached mode:
docker compose up -d
```

The production Compose file (`docker-compose.yml`) includes infrastructure dependencies (PostgreSQL, Redis, etc.) in addition to the API and UI containers.

**Core services:**
- `api` — NestJS REST API, listens on port 3000
- `webapp` — Angular frontend, listens on port 4200
- `db` — PostgreSQL (default for production Compose)

**Key `.env.compose` settings:**

```env
# Database
DB_TYPE=postgres         # sqlite | postgres | mysql | mariadb
DB_HOST=db
DB_PORT=5432
DB_NAME=gauzy
DB_USER=postgres
DB_PASS=root

# App URLs
API_BASE_URL=http://localhost:3000
CLIENT_BASE_URL=http://localhost:4200

# SMTP (optional)
MAIL_HOST=smtp.example.com
MAIL_PORT=587
MAIL_USERNAME=your@email.com
MAIL_PASSWORD=yourpassword
MAIL_FROM_ADDRESS=noreply@example.com
```

## Ports

| Port | Service |
|---|---|
| 3000 | API (REST + WebSocket) |
| 4200 | Web UI (Angular) |
| 5432 | PostgreSQL (internal) |

## Upgrade

```bash
docker compose pull
docker compose up -d
```

## Desktop apps

Ever Gauzy also ships desktop applications (Windows/macOS/Linux):
- **Gauzy Desktop App** — bundles the full platform (UI + API + SQLite) for local use. Download from <https://web.gauzy.co/downloads>.
- **Gauzy Desktop Timer App** — lightweight time-tracking client that connects to a Gauzy Server API.

## Gotchas

- **Docker Compose v2.20+ required** — the Compose files use `include:` directives not available in older versions.
- **First-run seed time** — the API seeds fake/demo data into the database on first start. Allow a few minutes before the UI is responsive.
- **SQLite is demo-only** — use PostgreSQL for production. SQLite is convenient for demos but not suitable for concurrent users.
- **Kubernetes recommended for production** — the upstream README notes that Docker Compose is provided for convenience but Kubernetes is the recommended production deployment.
- **Memory requirements** — the full stack (API + UI + DB + Redis + other infra) is resource-intensive. Allow at least 4 GB RAM for comfortable operation.
- **Admin user is not an employee** — the `admin@ever.co` user cannot track time. Use the `employee@ever.co` user or create a new employee user for time-tracking workflows.
