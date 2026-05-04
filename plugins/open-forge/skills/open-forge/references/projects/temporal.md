# Temporal

Durable execution platform for building scalable, fault-tolerant applications. Workflows run as code and automatically handle failures, retries, and state — no message queues or state machines needed. Originally forked from Uber's Cadence. MIT License. 12K+ GitHub stars. Upstream: <https://github.com/temporalio/temporal>. Docs: <https://docs.temporal.io>.

## Compatible install methods

Verified against upstream README at <https://github.com/temporalio/temporal#getting-started>.

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| `temporal server start-dev` (CLI) | `brew install temporal && temporal server start-dev` | ✅ | Local development only — in-memory, no persistence. |
| Docker Compose | <https://github.com/temporalio/docker-compose> | ✅ | Self-hosted with persistence (PostgreSQL + Elasticsearch). |
| Helm (Kubernetes) | <https://github.com/temporalio/helm-charts> | ✅ | Production K8s deploy. |
| Temporal Cloud | <https://cloud.temporal.io> | ✅ (hosted) | Managed SaaS — usage-based pricing. |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| db_password | "PostgreSQL password for Temporal?" | Free-text (sensitive) | Docker Compose / K8s |
| namespace | "Default Temporal namespace (default: `default`)?" | Free-text | All |
| domain | "Domain for Temporal UI (e.g. `temporal.example.com`)?" | Free-text | Production |

## Software-layer concerns

### Quick dev server (no persistence)

```bash
brew install temporal          # macOS
# or download from https://github.com/temporalio/cli/releases

temporal server start-dev
```

- Temporal UI available at `http://localhost:8233`
- gRPC endpoint at `localhost:7233`
- **Data is lost on restart** — development only.

### Docker Compose (persistent)

```bash
git clone https://github.com/temporalio/docker-compose
cd docker-compose
docker compose up
```

- Temporal server: port `7233` (gRPC)
- Temporal UI: `http://localhost:8080`
- Uses PostgreSQL for persistence + Elasticsearch for visibility queries

### Key services

| Service | Role |
|---|---|
| `temporal` | Core server (history, matching, frontend, worker services) |
| `temporal-ui` | Web UI for browsing workflows and workers |
| `temporal-admin-tools` | CLI container with `tctl` and `temporal` CLI tools |
| `postgresql` | Persistence for workflow state and history |
| `elasticsearch` | Advanced visibility (search, filtering, sorting by custom attributes) |

### Key environment variables

| Variable | Purpose |
|---|---|
| `DB` | Database backend: `postgres12`, `postgres12_mtls`, `cassandra`, `mysql8` |
| `DB_PORT` | Database port (default `5432` for PostgreSQL) |
| `POSTGRES_USER` / `POSTGRES_PWD` / `POSTGRES_SEEDS` | PostgreSQL credentials and host |
| `ENABLE_ES` | Enable Elasticsearch for advanced visibility: `true`/`false` |
| `ES_SEEDS` / `ES_VERSION` | Elasticsearch host and version |
| `DYNAMIC_CONFIG_FILE_PATH` | Path to dynamic config YAML file |
| `TEMPORAL_ADDRESS` | Temporal frontend address used by workers/SDK clients |
| `TEMPORAL_CORS_ORIGINS` | CORS origins for Temporal UI |

### SDK usage example (Go)

```go
// Connect and start a workflow
c, _ := client.Dial(client.Options{
    HostPort: "your-temporal-host:7233",
    Namespace: "default",
})
defer c.Close()

we, _ := c.ExecuteWorkflow(
    context.Background(),
    client.StartWorkflowOptions{ID: "order-1", TaskQueue: "orders"},
    OrderWorkflow,
    OrderInput{CustomerID: "cust-123"},
)
```

SDKs available for: Go, Java, Python, TypeScript/JavaScript, .NET, PHP.

### Architecture concepts

| Concept | Description |
|---|---|
| **Workflow** | Durable function that orchestrates activities; state is preserved across crashes |
| **Activity** | Single unit of work (API call, DB write, etc.) with automatic retry |
| **Worker** | Process that polls for and executes workflow/activity tasks |
| **Task Queue** | Named queue workers poll; routes tasks to the right worker pool |
| **Namespace** | Isolation unit (like a database); separate history, quotas, visibility |

### Ports

| Port | Service |
|---|---|
| `7233` | Temporal frontend gRPC (SDK/client connections) |
| `8080` | Temporal Web UI |
| `7234` | History service (internal) |
| `7235` | Matching service (internal) |
| `7239` | Worker service (internal) |

## Upgrade procedure

```bash
cd docker-compose
git pull
docker compose pull
docker compose up -d
```

Schema migrations run automatically via the `temporal-auto-setup` image on startup.

## Gotchas

- **`start-dev` is in-memory only.** Data is gone on restart. Use Docker Compose or Kubernetes for any persistent deployment.
- **Workers must be running.** The Temporal server does not execute workflow code — it only orchestrates. You must deploy worker processes that host your workflow/activity code.
- **Namespace isolation.** The `default` namespace is created automatically. Create separate namespaces for different teams or environments (`temporal operator namespace create staging`).
- **Elasticsearch is required for advanced visibility.** Without it you can only search by workflow ID and run ID. For production, keep Elasticsearch in the stack.
- **Clock skew can break workflows.** Temporal servers must have synchronized clocks (use NTP). Skew >1 second can cause issues.
- **PostgreSQL schema versioning.** The schema is versioned. Don't skip major versions when upgrading.
- **No built-in auth in OSS.** Authentication and authorization (mTLS, API keys) require Temporal Cloud or a custom frontend interceptor. See docs for TLS config.
- **License: MIT.** Core server is MIT. Temporal Cloud (managed) has separate commercial terms.

## Links

- Upstream: <https://github.com/temporalio/temporal>
- Docker Compose: <https://github.com/temporalio/docker-compose>
- Helm charts: <https://github.com/temporalio/helm-charts>
- Docs: <https://docs.temporal.io>
- SDKs: <https://docs.temporal.io/dev-guide>
- CLI reference: <https://docs.temporal.io/cli>
- Temporal Cloud: <https://cloud.temporal.io>
