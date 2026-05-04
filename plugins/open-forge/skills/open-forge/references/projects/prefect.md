# Prefect

Python workflow orchestration framework for building, scheduling, and monitoring data pipelines. Decorates existing Python functions with `@flow` and `@task` — no new DSL to learn. Supports retries, caching, scheduling, event-based triggers, and a self-hosted server UI. Apache 2.0. 16K+ GitHub stars. Upstream: <https://github.com/PrefectHQ/prefect>. Docs: <https://docs.prefect.io>.

## Compatible install methods

Verified against upstream README at <https://github.com/PrefectHQ/prefect#getting-started>.

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| `prefect server start` (local) | `pip install prefect && prefect server start` | ✅ | Dev / single-machine. Runs SQLite by default. |
| Docker (standalone) | `docker run -p 4200:4200 prefecthq/prefect:3-latest prefect server start --host 0.0.0.0` | ✅ | Containerized local server. |
| Docker Compose | Community-maintained compose file in docs | ✅ | PostgreSQL backend + self-hosted UI. |
| Prefect Cloud | <https://app.prefect.cloud> | ✅ (hosted) | Free tier; managed server; workers still run locally. |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| db_password | "PostgreSQL password (leave blank for SQLite)?" | Free-text (sensitive) | Production Docker |
| domain | "Domain for Prefect UI (e.g. `prefect.example.com`)?" | Free-text | Production |
| api_url | "Prefect API URL (e.g. `https://prefect.example.com/api`)?" | Free-text | Workers connecting to this server |

## Software-layer concerns

### Local quickstart

```bash
pip install -U prefect          # Python 3.10+ required

prefect server start            # starts UI at http://localhost:4200
```

To connect your workers to this server:

```bash
export PREFECT_API_URL=http://localhost:4200/api
```

### Minimal Docker Compose (SQLite)

```yaml
version: "3"
services:
  prefect:
    image: prefecthq/prefect:3-latest
    command: prefect server start --host 0.0.0.0
    ports:
      - "4200:4200"
    volumes:
      - prefect-data:/root/.prefect
volumes:
  prefect-data:
```

### Docker Compose with PostgreSQL

```yaml
version: "3"
services:
  postgres:
    image: postgres:15
    environment:
      POSTGRES_USER: prefect
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_DB: prefect
    volumes:
      - pgdata:/var/lib/postgresql/data

  prefect:
    image: prefecthq/prefect:3-latest
    command: prefect server start --host 0.0.0.0
    ports:
      - "4200:4200"
    environment:
      PREFECT_API_DATABASE_CONNECTION_URL: "postgresql+asyncpg://prefect:${DB_PASSWORD}@postgres:5432/prefect"
    depends_on:
      - postgres

volumes:
  pgdata:
```

### Key environment variables

| Variable | Purpose |
|---|---|
| `PREFECT_API_URL` | API endpoint for workers/CLI (e.g. `http://localhost:4200/api`) |
| `PREFECT_API_DATABASE_CONNECTION_URL` | DB URL (default: SQLite at `~/.prefect/prefect.db`) |
| `PREFECT_SERVER_API_HOST` | Host to bind server (use `0.0.0.0` for Docker) |
| `PREFECT_SERVER_API_PORT` | Server port (default `4200`) |
| `PREFECT_API_KEY` | API key for authenticating workers to Prefect Cloud |
| `PREFECT_LOGGING_LEVEL` | Log level: `DEBUG`, `INFO`, `WARNING`, `ERROR` |

### Write your first flow

```python
from prefect import flow, task
import httpx

@task(retries=3, retry_delay_seconds=5)
def fetch_data(url: str) -> dict:
    return httpx.get(url).json()

@flow(name="my-etl-pipeline", log_prints=True)
def run_pipeline(url: str = "https://api.example.com/data"):
    data = fetch_data(url)
    print(f"Got {len(data)} records")

if __name__ == "__main__":
    run_pipeline()
```

### Deploy and schedule

```python
# Serve a deployment with a cron schedule
if __name__ == "__main__":
    run_pipeline.serve(
        name="daily-etl",
        cron="0 9 * * *",           # 9 AM daily
        parameters={"url": "https://api.example.com/data"}
    )
```

Or use `prefect.yaml` for infrastructure-defined deployments with workers.

### Workers and work pools

Workers run locally (or in K8s, ECS, etc.) and pull work from the Prefect server:

```bash
prefect worker start --pool "my-work-pool"
```

Work pools define the infrastructure where flows run (local processes, Docker, Kubernetes, ECS, Cloud Run, etc.).

### Ports

| Port | Service |
|---|---|
| `4200` | Prefect server (UI + API) |

## Upgrade procedure

```bash
pip install -U prefect
prefect server database upgrade -y   # apply any DB schema migrations
```

Or for Docker: pull the new image and restart.

## Gotchas

- **SQLite is default but not for production.** The default SQLite backend is fine for a single developer. Switch to PostgreSQL for any multi-user or high-throughput deployment.
- **`PREFECT_API_URL` must be set on workers.** Workers don't auto-discover the server. Set the env var to point to your self-hosted server's API endpoint.
- **Workers are required to run deployments.** The Prefect server only orchestrates; actual code runs in worker processes. Workers must have your flow code available (via `pip`, Docker image, git clone, etc.).
- **Prefect 3.x (current) vs 2.x.** Prefect 3 (current) is not backwards compatible with Prefect 2. Check `pip install prefect==2.*` if you need the old version.
- **Python 3.10+ required** for Prefect 3.x.
- **Prefect Cloud free tier.** If you just want the UI/orchestration managed and run workers yourself, the Prefect Cloud free tier is generous. Self-hosting is for full data residency control.
- **License: Apache 2.0.** Fully open source.

## Links

- Upstream: <https://github.com/PrefectHQ/prefect>
- Docs: <https://docs.prefect.io>
- Self-host guide: <https://docs.prefect.io/latest/manage/self-host>
- Work pools: <https://docs.prefect.io/latest/concepts/work-pools>
- Docker deploy: <https://docs.prefect.io/latest/integrations/prefect-docker>
- Kubernetes: <https://docs.prefect.io/latest/integrations/prefect-kubernetes>
- Prefect Cloud: <https://app.prefect.cloud>
