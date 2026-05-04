# highlight.io

Open-source, full-stack monitoring platform — session replay, error monitoring, logging, and traces in one tool. Self-hostable alternative to FullStory + Sentry + Datadog Logs. 8K+ GitHub stars. Apache 2.0 (community). Upstream: <https://github.com/highlight/highlight>. Docs: <https://www.highlight.io/docs>.

> **Self-hosting is heavy.** Highlight runs 10+ services including ClickHouse, OpenSearch, Redis, Kafka, and MinIO. Minimum 8 GB RAM / 4 CPUs / 64 GB disk for the hobby deployment.

## Compatible install methods

Verified against upstream README at <https://github.com/highlight/highlight#self-hosted>.

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Hobby (Docker Compose) | `git clone --recurse-submodules && cd docker && ./run-hobby.sh` | ✅ | Self-hosted, <10K sessions/month. |
| Enterprise (Docker Compose) | Separate enterprise compose config | ✅ | Production-grade, scalable. Requires enterprise license. |
| highlight.io Cloud | <https://app.highlight.io/sign_up> | ✅ (hosted) | Free tier (500 sessions + 1K errors/month). |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| admin_password | "Admin password (used with any email for first login)?" | Free-text (sensitive) | Self-hosted |
| domain | "Domain for highlight.io (e.g. `highlight.example.com`)? Leave blank for localhost." | Free-text | Production |

## Software-layer concerns

### System requirements

| Resource | Minimum |
|---|---|
| CPU | 4 cores |
| RAM | 8 GB |
| Disk | 64 GB SSD |
| OS | Linux (Docker required) |

### Hobby self-hosted setup

```bash
git clone --recurse-submodules https://github.com/highlight/highlight
# Or on older git:
# git submodule update --init --recursive

cd docker

# Edit .env to set ADMIN_PASSWORD (required)
# Optionally set REACT_APP_FRONTEND_URI and other vars

./run-hobby.sh
```

After startup (can take several minutes), access at `https://localhost`.

- Login with **any valid email** + the password set in `ADMIN_PASSWORD`.

### Key environment variables (`.env` in `docker/`)

| Variable | Purpose |
|---|---|
| `ADMIN_PASSWORD` | **Required.** Password for initial admin login (any email works). |
| `REACT_APP_FRONTEND_URI` | Public URL of the frontend (e.g. `https://highlight.example.com`). Defaults to `https://localhost`. |
| `PRIVATE_GRAPH_URI` | Backend API URI for SDKs to ingest data. |
| `PUBLIC_GRAPH_URI` | Public API URI. |
| `DEPLOYMENT_KEY` | Unique key identifying your deployment instance. |

### Architecture

| Service | Role |
|---|---|
| `frontend` | React app — session replay viewer, dashboards, error explorer |
| `backend` | Go GraphQL API |
| `private-graph` | Internal GraphQL API |
| `public-graph` | SDK ingest API |
| `worker` | Background processing (session symbolication, alerts, etc.) |
| `clickhouse` | Columnar DB — logs, traces, session metadata |
| `opensearch` | Full-text search for errors and sessions |
| `redis` | Cache and pub/sub |
| `kafka` | Event streaming between ingest and processing |
| `minio` | Object storage for session recordings |
| `postgres` | Primary relational data (users, projects, settings) |

### SDK integration

```bash
# JavaScript/React
npm install @highlight-run/react
```

```tsx
import { H } from '@highlight-run/react';

H.init('<YOUR_PROJECT_ID>', {
  serviceName: "my-frontend",
  tracingOrigins: true,
  networkRecording: {
    enabled: true,
    recordHeadersAndBody: true,
  },
  backendUrl: 'https://highlight.example.com',  // self-hosted
});
```

Backend SDKs available for: Node.js, Go, Python, Ruby, Java, Rust, PHP.

### Capacity limits (hobby tier)

Highlight's hobby deployment is documented as suitable for:
- **<10,000 sessions ingested/month**
- **<50,000 errors ingested/month**

Beyond this, the single-node architecture may degrade. The enterprise tier uses a horizontally scaled deployment.

## Upgrade procedure

```bash
cd docker
git pull --recurse-submodules
./run-hobby.sh
```

The script handles pulling updated images and restarting services.

## Gotchas

- **Heavy infrastructure.** Highlight ships Kafka, ClickHouse, OpenSearch, MinIO, Redis, and PostgreSQL — all in one compose stack. Budget at least 8 GB RAM.
- **`ADMIN_PASSWORD` in `.env` is required.** Without it the startup script will error or the admin account won't be accessible.
- **Self-signed cert by default.** Hobby mode uses a self-signed TLS cert on `localhost`. For a custom domain, configure `REACT_APP_FRONTEND_URI` and add a real cert (or reverse proxy with Caddy/Nginx).
- **Submodule required.** Must clone with `--recurse-submodules` or run `git submodule update --init --recursive`. Without it, the frontend build will fail.
- **Cold start is slow.** First startup pulls and initializes Kafka, ClickHouse, OpenSearch — expect 5–10 minutes before the app is accessible.
- **Session recordings stored in MinIO.** For production, replace with an external S3 bucket for durability.
- **License: Apache 2.0** (community). Enterprise features (SSO, SLA support, etc.) require a commercial license.

## Links

- Upstream: <https://github.com/highlight/highlight>
- Docs: <https://www.highlight.io/docs>
- Self-host hobby guide: <https://www.highlight.io/docs/general/company/open-source/hosting/self-host-hobby>
- Self-host enterprise guide: <https://www.highlight.io/docs/general/company/open-source/hosting/self-host-enterprise>
- SDK overview: <https://www.highlight.io/docs/getting-started/overview>
- highlight.io Cloud: <https://app.highlight.io/sign_up>
