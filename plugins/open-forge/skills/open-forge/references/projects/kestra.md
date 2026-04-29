---
name: kestra-project
description: Kestra recipe for open-forge. Apache 2.0 event-driven declarative workflow orchestration platform — YAML-as-code workflows with built-in UI editor, scheduled AND event-driven triggers (Kafka/Redis/Pulsar/AMQP/MQTT/NATS/SQS/Pub-Sub/Event Hubs/files), hundreds of plugins (run Python/Node/R/Go/Shell, SQL against databases, cloud integrations for AWS/GCP/Azure, Spark, BigQuery), Git version-control integration, task runners (local/SSH/Docker/Kubernetes/serverless), namespaces + labels + subflows + retries + timeouts + error-handling + dynamic/parallel tasks. Stack = Kestra JVM server + Postgres (can also use MySQL/H2). Covers the official `server local` docker run quickstart, `server standalone` docker-compose w/ Postgres, KESTRA_CONFIGURATION YAML env, basic-auth hard-gate (email+uppercase+number), and the Kubernetes/Podman/AWS/GCP/Azure install paths.
---

# Kestra

Apache 2.0 event-driven declarative workflow orchestration platform. Upstream: <https://github.com/kestra-io/kestra>. Docs: <https://kestra.io/docs>. Website: <https://kestra.io>. Slack: <https://kestra.io/slack>.

Positioning: Airflow / Prefect / Dagster alternative — but YAML-first + UI-first + event-driven as a native concept (not just cron). Bring Infrastructure-as-Code best practices to data pipelines, microservice orchestration, and general task automation.

## What you build with it

- **Scheduled workflows** (cron-like) — ETL jobs, reports, cleanup.
- **Event-driven workflows** — react to files landing in S3, messages in Kafka/SQS/MQTT, webhooks, git pushes, etc.
- **Complex pipelines** with parallel tasks, conditional branching, retries, timeouts, error handling, dynamic task fan-out.
- **Multi-language steps** — Python, Node, R, Go, Shell, any CLI — via task runners.
- **Run anywhere** — local process, SSH remote, Docker container, Kubernetes job, serverless (AWS Lambda / GCP Cloud Run).

## Architecture (at a glance)

| Mode | Command | Components in one process | Use case |
|---|---|---|---|
| `server local` | Single `docker run` | Embedded H2 DB + memory queue + all services | Laptop / eval only. |
| `server standalone` | Docker Compose | Postgres/MySQL queue + repository + all services in one JVM | Small prod (single-node). |
| Distributed | Kubernetes / multi-node | Split into `executor`, `scheduler`, `worker`, `webserver` services | Prod at scale. |

Queue + repository backends: Postgres (recommended) / MySQL / H2 (embedded, dev only). Distributed mode can also use Kafka as the event queue + Elasticsearch as the search backend (enterprise tier).

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker run (`server local`) | <https://github.com/kestra-io/kestra> | ✅ | 5-minute eval. |
| Docker Compose (`server standalone` + Postgres) | <https://github.com/kestra-io/kestra/blob/develop/docker-compose.yml> | ✅ Recommended | Most self-hosters. |
| Podman Compose | <https://kestra.io/docs/installation/podman-compose> | ✅ | Rootless. |
| Kubernetes (Helm) | <https://github.com/kestra-io/helm-charts> | ✅ | Clusters. |
| AWS (CloudFormation: EC2 + RDS + S3) | <https://kestra-deployment-templates.s3.eu-west-3.amazonaws.com/aws/cloudformation/ec2-rds-s3/kestra-oss.yaml> | ✅ | AWS users. |
| Google Cloud (Terraform: VM + Cloud SQL + GCS) | <https://github.com/kestra-io/deployment-templates/tree/main/gcp/terraform/infrastructure-manager/vm-sql-gcs> | ✅ | GCP users. |
| Azure | <https://kestra.io/docs/installation/azure-vm> | ✅ | Azure users. |
| Kestra Cloud (hosted) | <https://kestra.io> | Paid | Don't self-host. |

Image: `kestra/kestra:latest` or `kestra/kestra:v0.21` (pin the minor in prod).

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Install method?" | `AskUserQuestion`: `docker-run-server-local` / `docker-compose-standalone` / `kubernetes-helm` / `cloud-template` | Drives section. |
| preflight | "Docker-in-Docker needed?" | Boolean | Required if you want Kestra workflows to run Docker task runners — mount `/var/run/docker.sock`. |
| db | "Repository/queue backend?" | `AskUserQuestion`: `postgres (recommended)` / `mysql` / `h2-embedded (dev only)` | Compose ships Postgres. |
| storage | "Internal storage?" | `AskUserQuestion`: `local-filesystem` / `s3` / `gcs` / `azure-blob` / `minio` | Artifact/output storage. |
| ports | "HTTP port?" | Default `8080` | Web UI. |
| ports | "Management port?" | Default `8081` | Health/metrics. |
| auth | "Basic auth?" | Boolean | OSS ships with optional basic-auth; full auth (OIDC/SAML/SSO) is Enterprise-only. |
| auth | "Admin email + password?" | Valid email; password ≥8 chars w/ uppercase + number | HARD validation — rejected startup if weak. |
| workingdir | "Host /tmp mount?" | Default `/tmp/kestra-wd` | Workflow working dirs. |

## Install — 5-minute Docker (`server local`)

```bash
docker run --pull=always -it -p 8080:8080 --user=root \
  --name kestra --restart=always \
  -v kestra_data:/app/storage \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /tmp:/tmp \
  kestra/kestra:latest server local
```

Open <http://localhost:8080> — no login by default in `server local` mode. `server local` uses embedded H2 DB — fine for eval, NOT for prod.

## Install — Docker Compose (`server standalone` + Postgres)

Upstream `docker-compose.yml` (verbatim):

```yaml
volumes:
  postgres-data:
    driver: local
  kestra-data:
    driver: local

services:
  postgres:
    image: postgres:18
    volumes:
      - postgres-data:/var/lib/postgresql
    environment:
      POSTGRES_DB: kestra
      POSTGRES_USER: kestra
      POSTGRES_PASSWORD: k3str4              # CHANGE THIS
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -d $${POSTGRES_DB} -U $${POSTGRES_USER}"]
      interval: 30s
      timeout: 10s
      retries: 10

  kestra:
    image: kestra/kestra:latest              # pin a version in prod e.g. :v0.21
    pull_policy: always
    stop_grace_period: 6m                    # 5m Kestra termination + buffer for active tasks
    user: "root"                             # required to access /var/run/docker.sock
    command: server standalone
    volumes:
      - kestra-data:/app/storage
      - /var/run/docker.sock:/var/run/docker.sock
      - /tmp/kestra-wd:/tmp/kestra-wd
    environment:
      KESTRA_CONFIGURATION: |
        datasources:
          postgres:
            url: jdbc:postgresql://postgres:5432/kestra
            driverClassName: org.postgresql.Driver
            username: kestra
            password: k3str4
        kestra:
          # server:
          #   basic-auth:
          #     username: admin@kestra.io   # must be valid email
          #     password: Admin1234!         # ≥8 chars, uppercase + number
          repository:
            type: postgres
          storage:
            type: local
            local:
              base-path: "/app/storage"
          queue:
            type: postgres
          tasks:
            tmp-dir:
              path: /tmp/kestra-wd/tmp
          url: http://localhost:8080/
    ports:
      - "8080:8080"
      - "8081:8081"
    depends_on:
      postgres:
        condition: service_started
```

Bring up:

```bash
mkdir ~/kestra && cd ~/kestra
curl -fsSLO https://raw.githubusercontent.com/kestra-io/kestra/develop/docker-compose.yml
# Edit password in POSTGRES_PASSWORD + datasources.postgres.password
docker compose up -d
# → http://<host>:8080/
```

## Enable basic auth

Uncomment + edit in `KESTRA_CONFIGURATION`:

```yaml
kestra:
  server:
    basic-auth:
      username: admin@example.com
      password: Admin1234!
```

Hard validation: `username` must be a valid email format; `password` must be ≥8 chars with at least one uppercase letter and one number. **Kestra refuses to start** if the password doesn't meet the policy.

⚠️ **OIDC / SAML / SSO / role-based access / audit logs are Enterprise-tier only.** OSS has only basic-auth. If you need SSO, put Kestra behind Authelia / Authentik in a reverse proxy with ForwardAuth.

## First-run Hello World

Once the UI is up:

1. Click **Create new flow**.
2. Paste this YAML:
   ```yaml
   id: hello_world
   namespace: dev
   tasks:
     - id: say_hello
       type: io.kestra.plugin.core.log.Log
       message: "Hello, World!"
   ```
3. Save → click **Execute** → see the log output.

## Storage backends

`kestra.storage.type` can be:

- `local` — filesystem `/app/storage` (default in compose).
- `s3` — AWS S3 or S3-compatible (MinIO).
- `gcs` — Google Cloud Storage.
- `azure` — Azure Blob.

For prod with distributed workers, use object storage. Example S3 config:

```yaml
kestra:
  storage:
    type: s3
    s3:
      access-key: <aws-key>
      secret-key: <aws-secret>
      region: us-east-1
      bucket: my-kestra-storage
      endpoint: ""  # blank for AWS; set to MinIO URL otherwise
```

## Task runners (where workflow tasks execute)

- `io.kestra.plugin.scripts.runner.process.Process` — on the Kestra host (same container).
- `io.kestra.plugin.scripts.runner.docker.Docker` — spin up containers per task (requires `/var/run/docker.sock` mounted).
- `io.kestra.plugin.scripts.runner.kubernetes.Kubernetes` — Kubernetes jobs.
- Enterprise runners: AWS Batch, AWS ECS, AWS Lambda, GCP Cloud Run, GCP Batch, Azure Container Instances.

Example Docker runner in a flow:

```yaml
tasks:
  - id: python_task
    type: io.kestra.plugin.scripts.python.Script
    taskRunner:
      type: io.kestra.plugin.scripts.runner.docker.Docker
    containerImage: python:3.12-slim
    script: |
      import pandas as pd
      print(pd.__version__)
```

## Git integration

Workflows as code — sync to Git:

```yaml
# In Kestra UI → Namespaces → dev → Git
# Or via a SyncFlows task triggered on schedule
id: sync_git
namespace: system
triggers:
  - id: every_minute
    type: io.kestra.plugin.core.trigger.Schedule
    cron: "* * * * *"
tasks:
  - id: git_sync
    type: io.kestra.plugin.git.SyncFlows
    url: https://github.com/you/kestra-flows
    branch: main
    targetNamespace: dev
    dryRun: false
```

Changes made via UI are pushed back to Git on save (configurable).

## Data layout

| Path / volume | Content |
|---|---|
| `postgres-data:/var/lib/postgresql` | All flow metadata, execution history, logs, triggers, variables, secrets, users |
| `kestra-data:/app/storage` | Internal storage — task outputs, artifacts, uploads |
| `/tmp/kestra-wd:/tmp/kestra-wd` | Task working directories (transient) |
| `/var/run/docker.sock` | Docker socket (if using Docker task runner) |

**Backup priority:**

1. **Postgres** (`pg_dump`) — flows, executions, history, users. Full lifecycle state.
2. **Internal storage** — artifacts referenced by executions (reports, outputs). If using S3/GCS, their native backup.
3. Working dirs (`/tmp/kestra-wd`) — transient, don't bother.

Flows themselves should ALSO live in Git (via `SyncFlows`) — gives you disaster-recovery independent of DB backups.

## Upgrade procedure

```bash
# Pin the version in compose first — avoid :latest surprises
docker compose pull
docker compose up -d
docker compose logs -f kestra
```

Kestra runs DB migrations on startup. Release notes + migration guides at <https://github.com/kestra-io/kestra/releases>.

Minor versions (`v0.21.x`) are safe. Major (`v0.20 → v0.21`) read release notes — plugin API changes may require flow updates.

## Gotchas

- **`server local` uses embedded H2** — all data in-container, wiped on delete. Only for eval.
- **`server standalone` is single-node** — all Kestra components in one JVM. Fine for most self-hosters. For HA / large scale, split into `executor` + `scheduler` + `worker` + `webserver` per upstream docs.
- **`user: "root"` + `/var/run/docker.sock` mount** is in the dev compose because it's the simplest way to let Kestra spawn Docker task containers. For prod: create a dedicated user in the `docker` group; avoid root in container.
- **Docker socket mount = container breakout risk.** Anyone who can submit a flow can execute `docker` commands as root on the host. Lock down flow submission permissions OR use Kubernetes task runner with proper RBAC instead.
- **Postgres default password `k3str4`** in upstream compose — CHANGE IT for any deploy beyond eval.
- **Basic-auth password policy is STRICT** (≥8 chars, uppercase, number). Kestra refuses to start with a weak password. Error message is clear.
- **No OIDC/SAML in OSS.** If your team needs SSO, either pay for Enterprise OR use a reverse-proxy-forward-auth setup (Authelia / Authentik / oauth2-proxy) + basic-auth disabled.
- **Namespaces are critical for organization.** Use `company.team.environment` dotted namespaces. Default `dev` namespace gets messy fast.
- **Storage retention** — artifacts pile up. Set `kestra.storage.retention` or run periodic cleanup flows. Otherwise disk fills quietly.
- **Execution logs are stored in Postgres by default** — Postgres DB size grows with executions. Configure log retention via `kestra.retention.logs` or offload to Loki / Elasticsearch.
- **`stop_grace_period: 6m`** matters — Kestra's default termination grace is 5 minutes (waits for in-flight tasks). If Docker's kill timeout is shorter, you lose in-flight tasks' state.
- **Secrets**: in OSS, secrets live in Postgres (encrypted with the Kestra encryption key). Rotating the encryption key = all secrets unreadable. Use a secret backend (AWS Secrets Manager / GCP Secret Manager / Vault) in Enterprise for better hygiene.
- **Plugins are JARs** — Kestra loads plugins at startup from the plugin dir. Adding a new plugin = restart. Find plugins at <https://kestra.io/plugins>.
- **Workers run tasks in parallel.** Set `kestra.worker.thread-count` to control concurrency. Default is low (CPU count); ramp up for IO-bound workloads.
- **Schedule triggers run in UTC unless specified** — `timezone: "Europe/Paris"` on the trigger fixes this. Common gotcha for crons.
- **Event-driven triggers** (Kafka, S3-file-arrived, etc.) need network access + credentials to the source. Permissions that surprise you.
- **Dynamic tasks** (`Each`, `ForEach`, `EachSequential`) can explode — a 10K-item list = 10K subtasks = 10K queue messages = load on Postgres. Batch where possible.
- **Kubernetes Helm chart** is the right path for clusters — has Postgres subchart + ingress + separate deployments for each component. See <https://github.com/kestra-io/helm-charts>.
- **Podman Compose** works but the `/var/run/docker.sock` path needs to be `/run/user/$UID/podman/podman.sock` or similar. See upstream Podman doc.
- **Memory footprint** — JVM-based; give at least 2 GB, preferably 4 GB for `server standalone`.
- **Kestra UI is slow on big executions** (10K+ items) — use search/filters, don't try to scroll.
- **Terraform provider** (<https://registry.terraform.io/providers/kestra-io/kestra>) lets you manage flows via IaC if you prefer that over Git-sync.

## Links

- Upstream repo: <https://github.com/kestra-io/kestra>
- Docs: <https://kestra.io/docs>
- Installation docs: <https://kestra.io/docs/installation>
- Docker compose: <https://github.com/kestra-io/kestra/blob/develop/docker-compose.yml>
- Configuration reference: <https://kestra.io/docs/configuration-guide>
- Helm charts: <https://github.com/kestra-io/helm-charts>
- Deployment templates (AWS/GCP/Azure): <https://github.com/kestra-io/deployment-templates>
- Plugins directory: <https://kestra.io/plugins>
- Plugin developer guide: <https://kestra.io/docs/plugin-developer-guide>
- Task runners: <https://kestra.io/docs/task-runners>
- Releases: <https://github.com/kestra-io/kestra/releases>
- Slack: <https://kestra.io/slack>
- Docker Hub: <https://hub.docker.com/r/kestra/kestra>
- Terraform provider: <https://registry.terraform.io/providers/kestra-io/kestra>
- vs Airflow/Prefect/Dagster comparison: <https://kestra.io/vs>
