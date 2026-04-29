---
name: apache-superset-project
description: Apache Superset recipe for open-forge. Apache-2.0 enterprise-ready BI + data viz web app. Upstream EXPLICITLY states "We don't support docker compose for production environments" — recipe covers the supported paths (official Helm chart, native pip install + gunicorn, Docker image baked for single-use). Covers the SECRET_KEY / admin-user bootstrap and the Postgres + Redis + Celery architecture.
---

# Apache Superset (business intelligence)

Apache-2.0 modern, enterprise-ready BI platform. Connects to ~50 data sources (Postgres, MySQL, BigQuery, Snowflake, ClickHouse, Druid, Presto/Trino, etc.), SQL-based data exploration, rich dashboards, role-based access control.

**Upstream README:** https://github.com/apache/superset/blob/master/README.md
**Docs:** https://superset.apache.org/
**Install guide:** https://superset.apache.org/docs/installation/installing-superset-using-docker-compose/
**Helm chart:** https://github.com/apache/superset/tree/master/helm/superset
**Docker image:** `apache/superset` (official)

> [!WARNING]
> From the upstream `docker-compose-non-dev.yml` header, verbatim:
>
> > "We don't support docker compose for production environments. If you choose to use this type of deployment make sure to create your own docker environment file (docker/.env) with your own unique random secure passwords and SECRET_KEY."
>
> Upstream-supported production paths: **Helm chart** (k8s), **Docker image + your own orchestration**, or **native pip install with gunicorn + supervisord + a real Postgres + a real Redis**. This recipe covers all three.

## Architecture

Superset isn't a single container. A full install has:

1. **Superset web** — Flask + Gunicorn, serves the UI + API
2. **Superset worker(s)** — Celery workers for async tasks (long queries, report generation, cache warm-up)
3. **Superset beat** — Celery beat scheduler (runs scheduled reports)
4. **Postgres** — metadata store (Superset's own DB — dashboards, users, permissions; NOT the data you query)
5. **Redis** — Celery broker + result backend + cache

Plus one or more **data sources** you query from Superset (Postgres, MySQL, Snowflake, etc.) — those aren't part of the Superset install.

## Compatible combos

| Infra | Runtime | Status | Notes |
|---|---|---|---|
| localhost | Docker Compose | ⚠️ | Works but upstream explicitly not prod-supported. OK for trials. |
| byo-vps | Docker Compose | ⚠️ | Same caveat. Many self-hosters do it anyway. |
| byo-vps | native (pip + systemd) | ✅ | Upstream-supported. Heavier lift. |
| kubernetes | official Helm | ✅ | **Upstream's preferred prod path.** |
| aws/ec2 | Helm on EKS | ✅ | |
| aws/ec2 | Compose | ⚠️ | As above |

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| dns | "Domain to host Superset on?" | Free-text | e.g. `superset.example.com` |
| tls | "Email for Let's Encrypt notices?" | Free-text | |
| secrets | "Generate SECRET_KEY (>= 42 chars)?" | Confirm | Critical — used to sign session cookies. Rotate means invalidating all sessions. |
| admin | "Admin username / email / password?" | Free-text (password sensitive) | Bootstrapped via `superset fab create-admin` on first run |
| db | "Postgres for metadata (host/port/user/pass/db)?" | Free-text | Default: local Postgres in compose, or external Postgres for prod |
| cache | "Redis for Celery + cache (host/port)?" | Free-text | |
| smtp | "Outbound email (for alerts, report emails)?" | AskUserQuestion: Resend / SendGrid / Mailgun / Skip | |
| auth | "External auth (OAuth / LDAP / OIDC)?" | AskUserQuestion: Database (default) / Google / OIDC / LDAP / SAML | Set in `superset_config.py` |
| datasources | "Pre-configure any data sources?" | Free-text | Can be added via UI, API, or superset_config.py |

## Install methods

### 1. Docker Compose (upstream — for trials/dev, not prod)

Source: https://superset.apache.org/docs/installation/installing-superset-using-docker-compose/

```bash
git clone --depth 1 https://github.com/apache/superset.git
cd superset

# Create env file (upstream requires it for docker-compose-non-dev.yml)
cat > docker/.env <<'EOF'
COMPOSE_PROJECT_NAME=superset
DATABASE_HOST=db
DATABASE_DB=superset
DATABASE_USER=superset
DATABASE_PASSWORD=<strong-password>
DATABASE_PORT=5432
DATABASE_DIALECT=postgresql
POSTGRES_USER=superset
POSTGRES_PASSWORD=<same-as-DATABASE_PASSWORD>
POSTGRES_DB=superset
REDIS_HOST=redis
REDIS_PORT=6379
SUPERSET_SECRET_KEY=<42+-char-random>
SUPERSET_LOAD_EXAMPLES=no
EOF

docker compose -f docker-compose-non-dev.yml up -d
```

UI at `http://localhost:8088`. Default login after bootstrap: `admin` / `admin` — **change it immediately**.

> Upstream's `docker-compose-non-dev.yml` is described as "non-dev" but still explicitly not production-grade.

### 2. Helm (upstream-supported production path)

Source: https://github.com/apache/superset/tree/master/helm/superset

```bash
helm repo add superset https://apache.github.io/superset
helm install my-superset superset/superset \
  --set configOverrides.secret="SECRET_KEY = 'your-42+-char-random-secret'" \
  --set init.adminUser.username=admin \
  --set init.adminUser.password=<strong-password>
```

The chart's `values.yaml` is the canonical reference for what's configurable. By default it provisions Postgres + Redis as sub-charts; for prod, disable those and point at external managed instances.

### 3. Native (pip + gunicorn + systemd)

Source: https://superset.apache.org/docs/installation/pypi/

```bash
# Python 3.9+ virtualenv
python3 -m venv /opt/superset && source /opt/superset/bin/activate
pip install apache-superset
pip install psycopg2-binary  # + any DB drivers you need

export SUPERSET_SECRET_KEY=<generated>
export SQLALCHEMY_DATABASE_URI=postgresql://superset:<pw>@db-host:5432/superset

# Initialize metadata DB
superset db upgrade

# Create admin user
superset fab create-admin \
  --username admin --firstname A --lastname User \
  --email admin@example.com --password <strong>

# Optional: load example dashboards (skip for prod)
# superset load_examples

# Initialize roles + permissions
superset init

# Run (prod: gunicorn behind nginx + systemd)
gunicorn -w 4 -k gthread -b 0.0.0.0:8088 "superset.app:create_app()"
```

Plus a separate Celery worker:

```bash
celery --app=superset.tasks.celery_app:app worker
# And beat for scheduled tasks:
celery --app=superset.tasks.celery_app:app beat
```

Wire as three systemd services (`superset-web`, `superset-worker`, `superset-beat`).

## Software-layer concerns

### `SECRET_KEY` is critical

Used to sign session cookies and encrypt stored credentials (e.g. data-source passwords). Changing it invalidates sessions AND encrypted passwords — users have to log back in AND you have to re-enter every data source's password.

Generate one: `openssl rand -base64 42`.

### Config file: `superset_config.py`

Python file. Lives at `/app/pythonpath/superset_config.py` in the image, or anywhere on the PYTHONPATH for native installs. Common overrides:

```python
import os

SECRET_KEY = os.environ['SUPERSET_SECRET_KEY']
SQLALCHEMY_DATABASE_URI = os.environ['SQLALCHEMY_DATABASE_URI']

# Feature flags
FEATURE_FLAGS = {
    'DASHBOARD_RBAC': True,
    'EMBEDDED_SUPERSET': True,
    'ALERT_REPORTS': True,
}

# Celery
class CeleryConfig:
    broker_url = os.environ.get('CELERY_BROKER_URL', 'redis://redis:6379/0')
    result_backend = os.environ.get('CELERY_RESULT_BACKEND', 'redis://redis:6379/1')
CELERY_CONFIG = CeleryConfig
```

### Paths

| Thing | Path (container) |
|---|---|
| Config dir | `/app/pythonpath/` (superset_config.py here) |
| Home (uploads, themes, cache) | `/app/superset_home/` |
| Entrypoint scripts | `/app/docker/` |

Volume `superset_home` must persist — it stores user-uploaded files (CSVs, custom viz bundles).

### Ports

- `8088/tcp` — web + API (Gunicorn)

### Reverse proxy

```caddy
superset.example.com {
  reverse_proxy 127.0.0.1:8088
}
```

Superset uses long-lived connections for SQL Lab queries — make sure proxy timeouts are generous (`timeouts 300s` or similar).

### Database drivers

Superset doesn't bundle all drivers. To connect to Snowflake, ClickHouse, BigQuery, etc. you must `pip install` the driver into the image. For Docker, either:

- Extend the upstream image with a custom Dockerfile that `pip install`s extras
- Use the `apache/superset:<tag>-dev` variants that bundle more drivers

See https://superset.apache.org/docs/configuration/databases/ for the per-driver matrix.

## Upgrade procedure

Release notes: https://github.com/apache/superset/blob/master/RELEASING/README.md

**Helm:**

```bash
helm repo update
helm upgrade my-superset superset/superset
```

**Compose (trials):**

```bash
git pull
docker compose -f docker-compose-non-dev.yml pull
docker compose -f docker-compose-non-dev.yml up -d
```

**Native:**

```bash
pip install --upgrade apache-superset
superset db upgrade
superset init  # re-run after role/permission changes
systemctl restart superset-web superset-worker superset-beat
```

**Always back up the metadata DB before upgrades.** Superset rewrites schema frequently between minors.

## Gotchas

- **Upstream explicitly doesn't support Compose in prod.** Use Helm, native install, or build your own prod Compose + ops pipeline. Don't complain to upstream if Compose blows up under load.
- **Default admin/admin.** The bootstrap creates `admin` / `admin` if you don't set env vars. Change it before putting the instance on the internet.
- **`SECRET_KEY` rotation is painful.** Sessions invalidate + every stored DB-connection password must be re-entered. Plan it.
- **Driver installation surprise.** Superset's image doesn't include Snowflake / Redshift / BigQuery drivers. Extend the image. "Why can't I add Snowflake?" is a common gotcha.
- **Celery worker needed for scheduled reports + SQL Lab async.** Without a worker, those features silently fail or block. Compose-non-dev and Helm provide workers; custom deploys need them wired.
- **Metadata DB grows with query history.** `query` and `log` tables can balloon. Periodic VACUUM / archival needed.
- **RBAC is role-based, not row-based by default.** "Row-level security" (RLS) is a separate Superset feature — enable via `FEATURE_FLAGS`.
- **Public dashboards require careful config.** Anonymous / public access is possible but exposes data if mis-configured. See the admin docs.
- **Examples dataset auto-loads.** `SUPERSET_LOAD_EXAMPLES=yes` fills the DB with sample dashboards. Leave `no` for prod.
- **Docker image runs as UID 0 by default.** The compose file explicitly `user: "root"`. Custom deployments should harden this.
- **Compose's bundled Postgres is for trials only.** For prod, use an external managed Postgres (RDS, Cloud SQL, Hetzner dedicated, etc.) with backups + HA.
- **LDAP/OAuth/SAML config goes in `superset_config.py`, not env vars.** Surprising vs Grafana.

## TODO — verify on subsequent deployments

- [ ] Exercise Helm chart on k3s — confirm defaults + disable bundled DB / Redis for prod-like test.
- [ ] Document Snowflake / BigQuery driver install via custom Dockerfile (`FROM apache/superset + pip install ...`).
- [ ] OAuth (Google + OIDC) worked examples in `superset_config.py`.
- [ ] Alerts + scheduled-report email wiring via Celery beat + SMTP.
- [ ] Row-level security (RLS) worked example.
- [ ] Embedded-dashboard feature flag + worked JWT flow for iframe embeds.
