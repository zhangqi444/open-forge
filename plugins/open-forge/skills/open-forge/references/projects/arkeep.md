---
name: Arkeep
description: "Self-hosted backup management platform with server/agent architecture. Centralized web dashboard to schedule, monitor, and manage Restic+Rclone backups across many servers. Agents connect outbound (gRPC); no inbound firewall holes needed. SQLite or PostgreSQL. Auto-PKI (mTLS). Early access — working but not yet production-recommended per upstream."
---

# Arkeep

Arkeep is an **open-source backup management platform** that wraps [Restic](https://restic.net/) + [Rclone](https://rclone.org/) behind a centralised web dashboard with a **server/agent architecture**. Deploy the server once; install a lightweight agent on every machine you want to back up. Agents connect **outbound over gRPC** (persistent connection, never listens on any port), so NAT traversal is effortless. The server stores state in SQLite (default) or PostgreSQL.

> Early access: core features work; upstream says "not yet recommended for production use" as of 2026-05.

- Upstream repo: <https://github.com/arkeep-io/arkeep>
- Docker Hub: <https://hub.docker.com/repositories/arkeepio>
- GitHub Packages: <https://github.com/orgs/arkeep-io/packages?repo_name=arkeep>
- Releases: <https://github.com/arkeep-io/arkeep/releases>

## Architecture

Server exposes REST API for GUI (port 8080) and gRPC for agents (port 9090). It handles scheduling, notifications, and stores all state in SQLite (default) or PostgreSQL.

Agent runs on each machine to be backed up. Initiates outbound gRPC — never listens on any port. Docker-aware: auto-discovers containers and volumes.

GUI is a Vue 3 PWA served directly by the server as embedded static files.

Auto-PKI: server generates a private CA and server cert on first startup. Agents auto-enroll via HTTP on first run and use mTLS from that point on.

## Compatible install methods

| Infra | Runtime | Notes |
|---|---|---|
| Docker Compose | ghcr.io/arkeep-io/arkeep-server:latest | Primary — server-only |
| Docker Compose | all-in-one | Server + agent on same host |
| Binary | Linux/macOS/Windows releases | systemd unit file provided for agent |
| Helm | Helm chart (see repo) | Kubernetes |

## Inputs to collect

| Input | Example | Phase | Notes |
|---|---|---|---|
| Domain | backup.example.com | dns | Expose :8080 (GUI) and :9090 (gRPC) or use reverse proxy |
| ARKEEP_SECRET_KEY | openssl rand -hex 32 | preflight | AES-256-GCM credential encryption key — never change after first start |
| ARKEEP_AGENT_SECRET | openssl rand -hex 24 | preflight | Shared secret for agent authentication |
| Database driver | sqlite or postgres | preflight | SQLite default; PostgreSQL for HA |
| PostgreSQL DSN | postgres://arkeep:pass@postgres:5432/arkeep?sslmode=disable | db | If using postgres |
| Data dir | /var/lib/arkeep/data | storage | RSA JWT keys and server state |
| SMTP (optional) | Settings in UI | integration | Email alerts on backup failure |
| Webhook (optional) | Any HTTP POST endpoint | integration | Slack, Discord, PagerDuty |
| Agent server addr | backup.example.com:9090 | agent | gRPC address agents connect to |
| ARKEEP_SERVER_HTTP_ADDR | https://backup.example.com | agent | Only if server is behind TLS-terminating reverse proxy |

## Install via Docker Compose

From upstream: https://raw.githubusercontent.com/arkeep-io/arkeep/main/deploy/docker/docker-compose.yml

```bash
curl -O https://raw.githubusercontent.com/arkeep-io/arkeep/main/deploy/docker/docker-compose.yml
curl -O https://raw.githubusercontent.com/arkeep-io/arkeep/main/deploy/docker/.env.example
cp .env.example .env
# Edit .env: set ARKEEP_SECRET_KEY and ARKEEP_AGENT_SECRET at minimum
docker compose up -d
```

Minimal compose (server-only):

```yaml
services:
  server:
    image: ghcr.io/arkeep-io/arkeep-server:latest
    container_name: arkeep-server
    restart: unless-stopped
    ports:
      - "${ARKEEP_HTTP_PORT:-8080}:8080"
      - "${ARKEEP_GRPC_PORT:-9090}:9090"
    environment:
      ARKEEP_SECRET_KEY: "${ARKEEP_SECRET_KEY}"
      ARKEEP_AGENT_SECRET: "${ARKEEP_AGENT_SECRET}"
      ARKEEP_DATA_DIR: "/var/lib/arkeep/data"
      ARKEEP_DB_DRIVER: "sqlite"
      ARKEEP_DB_DSN: "/var/lib/arkeep/arkeep.db"
      ARKEEP_HTTP_ADDR: ":8080"
      ARKEEP_GRPC_ADDR: ":9090"
      TZ: "UTC"
    volumes:
      - arkeep-data:/var/lib/arkeep
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:8080/health/ready"]
      interval: 30s
      timeout: 10s
      retries: 3

volumes:
  arkeep-data:
```

### PostgreSQL backend (optional)

Uncomment postgres service in upstream compose, then in .env:

```
ARKEEP_DB_DRIVER=postgres
ARKEEP_DB_DSN=postgres://arkeep:${POSTGRES_PASSWORD}@postgres:5432/arkeep?sslmode=disable
```

## Install agent

### Docker agent

```bash
curl -O https://raw.githubusercontent.com/arkeep-io/arkeep/main/deploy/docker/docker-compose.agent.yml
# Set ARKEEP_SERVER_ADDR and ARKEEP_AGENT_SECRET in environment or .env
docker compose -f docker-compose.agent.yml up -d
```

For local filesystem destinations in Docker, add to agent volumes:

```yaml
volumes:
  - /:/hostfs:ro   # :rw to also restore
```

### Binary + systemd agent

```bash
curl -L https://github.com/arkeep-io/arkeep/releases/latest/download/arkeep-agent_linux_amd64.tar.gz | tar xz
sudo cp arkeep-agent /usr/local/bin/arkeep-agent && sudo chmod +x /usr/local/bin/arkeep-agent

sudo mkdir -p /etc/arkeep
sudo tee /etc/arkeep/agent.env > /dev/null <<EOF
ARKEEP_SERVER_ADDR=backup.example.com:9090
ARKEEP_AGENT_SECRET=your-agent-secret
# ARKEEP_SERVER_HTTP_ADDR=https://backup.example.com  # if behind reverse proxy
EOF
sudo chmod 600 /etc/arkeep/agent.env

# Unit file from upstream deploy/systemd/arkeep-agent.service
sudo cp deploy/systemd/arkeep-agent.service /etc/systemd/system/
sudo systemctl daemon-reload && sudo systemctl enable --now arkeep-agent
```

## Server configuration reference

| Env var | Default | Notes |
|---|---|---|
| ARKEEP_SECRET_KEY | — | Required. AES-256 key — never change after first start |
| ARKEEP_AGENT_SECRET | — | Shared secret for gRPC auth |
| ARKEEP_HTTP_ADDR | :8080 | REST API + GUI |
| ARKEEP_GRPC_ADDR | :9090 | gRPC for agents |
| ARKEEP_DB_DRIVER | sqlite | sqlite or postgres |
| ARKEEP_DB_DSN | ./arkeep.db | SQLite path or PostgreSQL DSN |
| ARKEEP_DATA_DIR | ./data | RSA JWT keys and state |
| ARKEEP_GRPC_INSECURE | false | Disable TLS — same-machine only |
| ARKEEP_SECURE_COOKIES | false | Set Secure flag on cookies — enable in production over HTTPS |
| ARKEEP_TELEMETRY | true | Anonymous usage stats — set false to opt-out |
| ARKEEP_LOG_LEVEL | info | debug / info / warn / error |

## Backup destinations

| Type | Notes |
|---|---|
| Local filesystem | Direct path on agent host or via hostfs mount in Docker |
| S3-compatible | AWS S3, MinIO, Backblaze B2, Cloudflare R2 |
| SFTP | Any SSH server |
| Restic REST Server | Self-hosted rest-server |
| Rclone | 40+ backends (Google Drive, OneDrive, Azure Blob, etc.) |

## Health and observability

| Endpoint | Purpose |
|---|---|
| GET /health/live | Liveness — always 200 ok |
| GET /health/ready | Readiness — 200 or 503 + JSON (checks DB + scheduler) |
| GET /metrics | Prometheus metrics (unauthenticated — restrict at proxy) |

Key Prometheus metrics: arkeep_jobs_total, arkeep_job_duration_seconds, arkeep_agents_connected.

## Notifications

Configure under Settings > Notifications in the web UI:

- SMTP — email on backup events
- Webhook — HTTP POST with JSON; Slack/Discord compatible (text field)

Both retry with exponential backoff: immediately, +5 min, +30 min.

## Upgrade procedure

### Docker Compose

```bash
docker compose pull
docker compose up -d
```

Check upstream CHANGELOG for breaking changes before upgrading across major versions. Database migrations run automatically on startup.

### Binary

```bash
systemctl stop arkeep-server
# Replace binary with new release
systemctl start arkeep-server
```

### Helm

```bash
helm repo update
helm upgrade arkeep arkeep/arkeep
```

## Gotchas

- ARKEEP_SECRET_KEY is permanent — changing it after first start invalidates all stored credentials; back this up separately
- gRPC port :9090 must be reachable by agents; if behind reverse proxy, set ARKEEP_SERVER_HTTP_ADDR on agents for enrollment
- Same-machine (no TLS) — add ARKEEP_GRPC_INSECURE=true to both server and agent
- Docker local destinations — mount /:/hostfs:ro (:rw to restore); agent auto-detects Docker and translates paths; Windows needs per-drive mounts (C:/:/hostfs/c:ro)
- In-place restore of Docker volumes — requires :rw mount AND containers stopped; running containers are skipped with a log warning
- /metrics is unauthenticated — restrict at reverse proxy level
- Early access — pin image tags; check upstream releases before upgrading
- max gRPC message size — 16 MB per RPC call (fixed in binary)

## TODO — verify on subsequent deployments

- Confirm exact Restic/Rclone version bundled in each agent release
- Validate OIDC integration when feature lands stable
- Test Helm chart end-to-end
