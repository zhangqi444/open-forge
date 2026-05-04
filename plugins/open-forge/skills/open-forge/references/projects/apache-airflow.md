---
name: apache-airflow-project
description: Apache Airflow recipe for open-forge. Apache-2.0 workflow scheduling and monitoring platform where pipelines are defined as Python DAGs. Covers the upstream-blessed Docker Compose (CeleryExecutor) path — Postgres 16 + Redis 7 + Airflow apiserver, scheduler, dag-processor, worker, triggerer, flower. Source: https://airflow.apache.org/docs/apache-airflow/stable/howto/docker-compose/index.html
---

# Apache Airflow

Apache-2.0 workflow scheduling and monitoring platform. Pipelines ("DAGs") are defined as Python code, enabling dynamic generation, version control, and testing. Upstream: <https://github.com/apache/airflow/>. Docs: <https://airflow.apache.org/docs/>. Self-host guide: <https://airflow.apache.org/docs/apache-airflow/stable/howto/docker-compose/index.html>.

The canonical self-host path is Docker Compose with CeleryExecutor: Postgres as the metadata DB + result backend, Redis as the Celery message broker, and multiple Airflow containers (API server, scheduler, DAG processor, worker, triggerer) sharing the same image and config. An `airflow-init` one-shot container bootstraps the DB and creates the initial admin user.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose (CeleryExecutor) | <https://airflow.apache.org/docs/apache-airflow/stable/howto/docker-compose/index.html> | Yes | Primary self-host path. Postgres + Redis + all Airflow services. |
| pip install (LocalExecutor) | <https://airflow.apache.org/docs/apache-airflow/stable/installation/> | Yes | Development / minimal single-node — no worker scaling. |
| Helm (Kubernetes) | <https://airflow.apache.org/docs/helm-chart/> | Yes | Production at scale — out of scope for single-node open-forge. |
| Managed (MWAA, Cloud Composer, Astronomer) | Various | No (SaaS) | Out of scope. |

---

## Method — Docker Compose (CeleryExecutor)

> **Source:** <https://airflow.apache.org/docs/apache-airflow/stable/howto/docker-compose/index.html>. Canonical compose file: <https://airflow.apache.org/docs/apache-airflow/stable/docker-compose.yaml>.

### Architecture

| Service | Image | Role |
|---|---|---|
| `postgres` | `postgres:16` | Metadata DB + Celery result backend |
| `redis` | `redis:7.2-bookworm` | Celery message broker |
| `airflow-apiserver` | `apache/airflow:3.2.1` | REST API + web UI (port 8080) |
| `airflow-scheduler` | `apache/airflow:3.2.1` | Parses DAGs, schedules task instances |
| `airflow-dag-processor` | `apache/airflow:3.2.1` | Dedicated DAG file processor (Airflow 3.x) |
| `airflow-worker` | `apache/airflow:3.2.1` | Executes tasks via Celery |
| `airflow-triggerer` | `apache/airflow:3.2.1` | Handles deferrable operators |
| `airflow-init` | `apache/airflow:3.2.1` | One-shot: runs DB migrations + creates admin user |
| `flower` | `apache/airflow:3.2.1` | Celery monitoring UI (port 5555) |

### Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | Host user UID for `AIRFLOW_UID` | Run `id -u`; default 50000. Wrong UID causes volume permission errors. |
| preflight | Install directory | Where to place `docker-compose.yaml`, `.env`, and DAG/log/config dirs. |
| secrets | `FERNET_KEY` | Symmetric key for encrypting connection passwords in the DB. Generate with the Fernet library (`from cryptography.fernet import Fernet; Fernet.generate_key()`). |
| secrets | `AIRFLOW__API_AUTH__JWT_SECRET` | JWT signing secret for the Airflow 3.x API. Any long random string. |
| admin | Admin username / password | Default `airflow`/`airflow` — must be changed before going live. |

### Setup

```bash
# 1. Create project directories
mkdir -p ./dags ./logs ./plugins ./config

# 2. Set AIRFLOW_UID in .env (must match host user UID)
echo "AIRFLOW_UID=$(id -u)" > .env

# 3. Download the official docker-compose.yaml
curl -LfO 'https://airflow.apache.org/docs/apache-airflow/stable/docker-compose.yaml'

# 4. Add required secrets to .env
echo "FERNET_KEY=<your-fernet-key>" >> .env
echo "AIRFLOW__API_AUTH__JWT_SECRET=<your-jwt-secret>" >> .env

# 5. (Optional) Override default admin credentials
echo "_AIRFLOW_WWW_USER_USERNAME=admin" >> .env
echo "_AIRFLOW_WWW_USER_PASSWORD=<secure-password>" >> .env

# 6. Initialize the database + create admin user
docker compose up airflow-init
# Wait for exit code 0: docker compose ps airflow-init

# 7. Start all services
docker compose up -d
```

Web UI: <http://localhost:8080>. Flower (Celery monitoring): <http://localhost:5555>.

### Key environment variables

All `AIRFLOW__SECTION__KEY` variables map directly to `airflow.cfg` sections/keys.

| Variable | Default in compose | Notes |
|---|---|---|
| `AIRFLOW__CORE__EXECUTOR` | `CeleryExecutor` | Don't change without reworking the full stack. |
| `AIRFLOW__DATABASE__SQL_ALCHEMY_CONN` | `postgresql+psycopg2://airflow:airflow@postgres/airflow` | Change DB password if hardening. |
| `AIRFLOW__CELERY__BROKER_URL` | `redis://:@redis:6379/0` | Redis broker. |
| `AIRFLOW__CELERY__RESULT_BACKEND` | `db+postgresql+psycopg2://...` | Must match DB conn string. |
| `AIRFLOW__CORE__FERNET_KEY` | (must be set in .env) | Encrypts stored connection passwords. |
| `AIRFLOW__CORE__LOAD_EXAMPLES` | `true` | Set `false` to hide bundled example DAGs. |
| `AIRFLOW__API_AUTH__JWT_SECRET` | `airflow_jwt_secret` | Change — signs JWTs for the Airflow 3.x API. |
| `AIRFLOW_UID` | `50000` | UID inside containers; must match host UID owning the mounted dirs. |

### Volumes

| Host path | Container path | Content |
|---|---|---|
| `./dags` | `/opt/airflow/dags` | DAG Python files |
| `./logs` | `/opt/airflow/logs` | Task + scheduler logs |
| `./config` | `/opt/airflow/config` | `airflow.cfg` overrides (optional) |
| `./plugins` | `/opt/airflow/plugins` | Custom operators, hooks, sensors |

### Adding DAGs

Drop `.py` files into `./dags/`. The dag-processor picks them up within `dag_dir_list_interval` (default 5 min; override with `AIRFLOW__SCHEDULER__DAG_DIR_LIST_INTERVAL`).

### Upgrade procedure

```bash
# 1. Pull the new official docker-compose.yaml
curl -LfO 'https://airflow.apache.org/docs/apache-airflow/stable/docker-compose.yaml'

# 2. Pull new images
docker compose pull

# 3. Run init to apply DB migrations
docker compose up airflow-init

# 4. Restart services
docker compose up -d
```

Check the [Airflow migration docs](https://airflow.apache.org/docs/apache-airflow/stable/installation/upgrading-from-2-to-3.html) when crossing major versions — 2.x to 3.x is a significant migration with breaking changes.

### Gotchas

- **`AIRFLOW_UID` must match the host user UID.** If the mounted dirs are owned by a different UID, tasks fail with permission errors. Always set this before `airflow-init`.
- **`FERNET_KEY` is write-once.** Changing it after connections are stored breaks decryption of existing credentials. Never rotate without a migration plan.
- **`airflow-init` must exit 0 before starting services.** If it exits non-zero, the DB is in a bad state. Check `docker compose logs airflow-init` and fix before proceeding.
- **Default credentials are `airflow`/`airflow`.** Change via `_AIRFLOW_WWW_USER_*` env vars in `.env` before `airflow-init`, or change in the web UI immediately after first login.
- **Disk usage grows quickly.** Logs under `./logs` are not automatically purged. Use `AIRFLOW__LOG__MAX_LOG_AGE_IN_DAYS` to set retention.
- **Compose file header says "for local development."** For production, harden secrets management, use named volumes, add resource limits. Docker Compose is still the upstream-documented self-host path for single-node deployments.

### Links

- Upstream README: <https://github.com/apache/airflow/blob/main/README.md>
- Docker Compose guide: <https://airflow.apache.org/docs/apache-airflow/stable/howto/docker-compose/index.html>
- Configuration reference: <https://airflow.apache.org/docs/apache-airflow/stable/configurations-ref.html>
- Upgrading 2.x to 3.x: <https://airflow.apache.org/docs/apache-airflow/stable/installation/upgrading-from-2-to-3.html>
