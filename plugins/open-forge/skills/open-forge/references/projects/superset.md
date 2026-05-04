---
name: superset
description: Apache Superset recipe for open-forge. Covers Docker Compose (development/evaluation), Kubernetes/Helm (production), and key configuration concerns. Based on upstream docs at https://superset.apache.org/docs/installation/docker-compose and the official docker-compose-non-dev.yml.
---

# Apache Superset

Modern data exploration and visualization platform. Connect to any SQL database, build rich interactive dashboards, and explore data without writing SQL. Upstream: <https://github.com/apache/superset>. Docs: <https://superset.apache.org/docs/>.

Superset is a Python (Flask) application running on port `8088`. It requires PostgreSQL (metadata store), Redis (cache/async workers), and Celery workers for async query execution. What varies across deployments is whether you use Docker Compose (dev/eval only) vs Helm (production), and how you manage the `SECRET_KEY` and database connections.

## Compatible install methods

Verified against upstream docs at <https://superset.apache.org/docs/installation/>.

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose (dev/evaluation) | <https://superset.apache.org/docs/installation/docker-compose> | ✅ | Local evaluation and development. **Not production-supported by upstream.** |
| Kubernetes / Helm | <https://superset.apache.org/docs/installation/running-on-kubernetes> | ✅ | Production. Official Helm chart at `apache/superset`. |
| PyPI / pip (bare metal) | <https://superset.apache.org/docs/installation/pypi> | ✅ | Advanced; manage Python env, Celery, and Gunicorn yourself. |

> ⚠️ **Upstream explicitly states:** "We don't support docker compose for production environments." For production, use the Helm chart.

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| preflight | "Install method?" | `AskUserQuestion`: `Docker Compose (dev/eval)` / `Kubernetes/Helm` | All |
| secrets | "SECRET_KEY for Superset?" | Free-text (generate with `openssl rand -base64 42`) | All |
| db | "External PostgreSQL connection string?" | Free-text (sensitive) | Helm/bare-metal |
| db | "External Redis connection string?" | Free-text | Helm/bare-metal |
| admin | "Admin username and password for initial setup?" | Free-text | All |

## Software-layer concerns

### Critical env vars

| Variable | Purpose | Notes |
|---|---|---|
| `SECRET_KEY` | Flask session/security key | **Must be set to a strong random value in production.** Never use the default. |
| `SUPERSET_ENV` | `production` or `development` | Controls debug mode |
| `DATABASE_URL` | Metadata DB connection | Defaults to internal Postgres in docker-compose |
| `REDIS_URL` | Cache + Celery broker | Defaults to internal Redis in docker-compose |
| `SUPERSET_LOG_LEVEL` | Log verbosity | Set in `docker/.env-local` |

Generate SECRET_KEY:
```bash
openssl rand -base64 42
```

### Docker Compose services (from `docker-compose-non-dev.yml`)

| Service | Image | Port | Role |
|---|---|---|---|
| `redis` | `redis:7` | 6379 | Cache + Celery broker |
| `db` | `postgres:17` | 5432 | Metadata database |
| `superset` | Built from source | 8088 | Main web app (Gunicorn) |
| `superset-init` | Built from source | — | One-shot: DB migrations + admin user creation |
| `superset-worker` | Built from source | — | Celery async query worker |
| `superset-worker-beat` | Built from source | — | Celery scheduler |

### Docker Compose setup

```bash
git clone https://github.com/apache/superset.git
cd superset

# Create env file (required)
cp docker/.env docker/.env-local
# Edit docker/.env-local — set SECRET_KEY at minimum

docker compose -f docker-compose-non-dev.yml up -d
```

Superset UI will be available at `http://localhost:8088`. Default admin credentials are set in `docker/pythonpath_docker/superset_config.py` (override via env).

### Data directories (Docker Compose)

| Path | Contents |
|---|---|
| `docker/.env` | Base environment (committed to repo) |
| `docker/.env-local` | Local overrides — set your SECRET_KEY here |
| `docker/pythonpath_docker/` | Python config files loaded into Superset |
| `superset_home` volume | Superset home directory (logs, uploads) |
| `db_home` volume | PostgreSQL data |
| `redis` volume | Redis persistence |

### Helm (Kubernetes production)

```bash
helm repo add superset https://apache.github.io/superset
helm install superset superset/superset \
  --set configOverrides.secret="SECRET_KEY = '<your-secret-key>'"
```

Full Helm values reference: <https://github.com/apache/superset/tree/master/helm/superset>.

## Upgrade procedure

Based on <https://superset.apache.org/docs/installation/upgrading-superset>:

1. Back up the metadata database.
2. Pull the latest code / update Helm chart version.
3. Review the CHANGELOG and migration notes for breaking changes.
4. For Docker Compose: `docker compose pull` then `docker compose up -d`. The `superset-init` container runs DB migrations automatically.
5. For Helm: `helm upgrade superset superset/superset`.
6. Verify the UI loads and dashboards are intact.

## Gotchas

- **SECRET_KEY is not optional.** Superset will start with the default but sessions will be insecure and you'll lose all sessions/cookies on restart. Always set a strong, stable SECRET_KEY.
- **Docker Compose is dev/eval only.** Upstream won't support production issues with docker-compose. Use Helm for production.
- **`superset-init` must complete before the app is usable.** Wait for it to finish (`docker compose logs superset-init -f`) before logging in.
- **Celery workers are required for async queries.** Without `superset-worker`, async chart rendering won't work.
- **Database connections are metadata, not data.** Superset stores connection strings in its metadata DB; connect to your actual data sources via the UI under Data → Databases.
- **Builds from source.** The docker-compose build takes several minutes on first run. Subsequent runs use the build cache.

## Links

- Upstream: <https://github.com/apache/superset>
- Docker Compose install: <https://superset.apache.org/docs/installation/docker-compose>
- Kubernetes/Helm: <https://superset.apache.org/docs/installation/running-on-kubernetes>
- Configuration reference: <https://superset.apache.org/docs/configuration/configuring-superset>
- Upgrading: <https://superset.apache.org/docs/installation/upgrading-superset>
