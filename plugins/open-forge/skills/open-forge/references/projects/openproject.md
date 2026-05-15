# OpenProject

**OpenProject** is an open-source web-based project management platform — a self-hosted alternative to Jira or Asana. Covers classic, agile, and hybrid project management with Gantt charts, Kanban boards, time tracking, and budgeting.

- **Upstream:** https://github.com/opf/openproject
- **Official site:** https://www.openproject.org
- **Install docs:** https://www.openproject.org/docs/installation-and-operations/installation/
- **License:** GPL-3.0
- **Stars:** ~15k
- **Latest release:** v17.4.0

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS / bare metal | Docker Compose (multi-container) | **Recommended for production** |
| Any Linux VPS / bare metal | deb package | Available for Debian/Ubuntu |
| Any Linux VPS / bare metal | Docker (all-in-one) | Quick start / testing only |
| Kubernetes | Helm chart | Scales well |

---

## Inputs to Collect

| Input | Description |
|-------|-------------|
| `OPENPROJECT_HOST__NAME` | Hostname or domain (e.g. `openproject.example.com`) |
| `OPENPROJECT_HTTPS` | `true` if behind HTTPS, `false` for plain HTTP |
| `SECRET_KEY_BASE` | Random secret (generate: `openssl rand -hex 64`) |
| `POSTGRES_PASSWORD` | PostgreSQL password |
| `OPENPROJECT_ADMIN_USER__PASSWORD` | Admin password for first login |
| Admin email | Configured during install or env var |
| Storage path | Host path for attachments volume |

---

## Install Option A — Docker Compose (Recommended)

Use the official Docker Compose deployment from the `opf/openproject-deploy` repository:

```bash
git clone https://github.com/opf/openproject-deploy --depth=1 --branch=stable/17 openproject
cd openproject/compose
cp .env.example .env
# Edit .env and set at minimum:
# OPENPROJECT_HOST__NAME=openproject.example.com
# OPENPROJECT_HTTPS=true
# SECRET_KEY_BASE=$(openssl rand -hex 64)
docker compose up -d
```

The Compose file runs separate containers for: web, worker, cron, PostgreSQL, and memcached.

---

## Install Option B — All-in-One Container (Testing Only)

```bash
docker run -it -p 8080:80 \
  -e SECRET_KEY_BASE=secret \
  -e OPENPROJECT_HOST__NAME=localhost:8080 \
  -e OPENPROJECT_HTTPS=false \
  -e OPENPROJECT_DEFAULT__LANGUAGE=en \
  -v openproject_data:/var/openproject/assets \
  openproject/openproject:17
```

Access at **http://localhost:8080**. Default login: `admin` / `admin` (change immediately).

---

## Install Option C — deb Package (Debian/Ubuntu)

```bash
wget -qO- https://dl.packager.io/srv/opf/openproject/key | sudo apt-key add -
sudo wget -O /etc/apt/sources.list.d/openproject.list \
  https://dl.packager.io/srv/opf/openproject/stable/17/installer/ubuntu/22.04.repo
sudo apt update
sudo apt install openproject
sudo openproject configure
```

---

## Key Environment Variables

| Variable | Description |
|----------|-------------|
| `OPENPROJECT_HOST__NAME` | Public hostname (double-underscore = `.` in config keys) |
| `OPENPROJECT_HTTPS` | `true` / `false` — enables HTTPS redirect |
| `SECRET_KEY_BASE` | Session signing secret — never change after first run |
| `DATABASE_URL` | PostgreSQL connection string (Docker Compose sets this automatically) |
| `OPENPROJECT_DEFAULT__LANGUAGE` | Default UI language (e.g. `en`) |
| `OPENPROJECT_ADMIN_USER__PASSWORD` | Initial admin password |
| `OPENPROJECT_ADMIN_USER__NAME` | Initial admin display name |

---

## Key Directories

| Path (inside container) | Purpose |
|-------------------------|---------|
| `/var/openproject/assets` | Uploaded files and attachments |
| `/var/openproject/pgdata` | PostgreSQL data (all-in-one container only) |

---

## Features

- Work packages (issues/tasks) with custom fields, types, and workflows
- Gantt charts with automatic and manual scheduling
- Agile Kanban and Scrum boards
- Project portfolio management and roadmaps
- Time tracking, cost reporting, and budgeting
- Wikis, forums, meeting minutes
- GitHub and GitLab PR integration (link PRs to work packages)
- LDAP, SAML SSO, OpenID Connect, and SCIM
- REST API + MCP server integration
- Community edition is free; Enterprise adds SSO, SCIM, advanced reporting

---

## Upgrade Procedure

**Docker Compose:**
```bash
cd openproject/compose
git pull
docker compose pull
docker compose up -d
```

**deb package:**
```bash
sudo apt update && sudo apt install openproject
sudo openproject configure
```

Database migrations run automatically on startup. Always review the [release notes](https://www.openproject.org/docs/release-notes/) before major upgrades.

---

## Gotchas

- **Double underscores** in env var names encode dots: `OPENPROJECT_HOST__NAME` maps to config key `openproject.host_name`. A single underscore maps to a hyphen.
- **`SECRET_KEY_BASE` must not change** after first launch — changing it invalidates all user sessions.
- **All-in-one container** bundles PostgreSQL and memcached internally — not suitable for production (no easy DB backup, harder to upgrade components independently). Use Docker Compose instead.
- **Memory:** OpenProject is memory-hungry. Minimum 2 GB RAM; 4 GB recommended for production.
- **SMTP email** must be configured for notifications, invites, and password resets. Set via env vars (`OPENPROJECT_SMTP_*`) or during `openproject configure`.
- **Repository integration** (SVN/Git browsing within OpenProject) requires the packaged install; not available in Docker.

---

## Links

- Docker Compose install: https://www.openproject.org/docs/installation-and-operations/installation/docker-compose/
- Docker all-in-one: https://www.openproject.org/docs/installation-and-operations/installation/docker/
- deb package install: https://www.openproject.org/docs/installation-and-operations/installation/packaged/
- Environment variables reference: https://www.openproject.org/docs/installation-and-operations/configuration/environment/
- GitHub releases: https://github.com/opf/openproject/releases
- Docker Hub: https://hub.docker.com/r/openproject/openproject
