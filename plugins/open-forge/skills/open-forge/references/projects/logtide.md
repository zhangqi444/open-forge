---
name: logtide-project
description: LogTide recipe for open-forge. Self-hosted observability platform and SIEM with unified logs/traces/metrics, multi-engine storage (TimescaleDB/ClickHouse/MongoDB), Sigma rules threat detection, GDPR-compliant PII masking, and uptime monitoring.
---

# LogTide

Open-source, self-hosted observability platform and SIEM. Provides unified logs, traces, and metrics with built-in security threat detection via Sigma rules. Privacy-first alternative to Datadog and ELK. Upstream: https://github.com/logtide-dev/logtide. Official site: https://logtide.dev.

LogTide v0.9.4. Language: TypeScript (Fastify backend) + SvelteKit frontend. License: AGPL-3.0. Storage options: TimescaleDB (standard), ClickHouse (high scale), MongoDB (flexible).

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux host | Docker Compose (full stack) | PostgreSQL/TimescaleDB + Redis + backend + worker + frontend (5 containers) |
| Low-resource host (Pi, homelab) | Docker Compose (simple/lightweight) | PostgreSQL + backend + frontend only (3 containers, no Redis) |
| Kubernetes | Helm chart | https://github.com/logtide-dev/logtide-helm-chart |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | Storage engine: TimescaleDB (default), ClickHouse (scale), or MongoDB | TimescaleDB is standard; ClickHouse/MongoDB are opt-in Docker profiles |
| preflight | Resource constraints? (Pi/low-RAM) | Use docker-compose.simple.yml for 3-container lightweight mode |
| network | Port for frontend (default: 3000) | |
| network | Port for API (default: 8080) | |
| optional | Docker profiles to enable | logging (Fluent Bit), metrics (system stats), clickhouse, mongodb |

## Software-layer concerns

### Config paths

Configuration via environment variables in .env file (copy from .env.example).

Upstream .env.example:
  https://raw.githubusercontent.com/logtide-dev/logtide/main/docker/.env.example

### Key environment variables

Set in .env file alongside docker-compose.yml. Key vars include database connection strings, Redis URL, JWT secrets, and storage engine selection. See upstream .env.example for the full list.

### Docker Compose setup (standard — 5 containers)

  mkdir logtide && cd logtide
  curl -O https://raw.githubusercontent.com/logtide-dev/logtide/main/docker/docker-compose.yml
  curl -O https://raw.githubusercontent.com/logtide-dev/logtide/main/docker/.env.example
  mv .env.example .env
  # Edit .env as needed
  docker compose up -d

Access:
  Frontend: http://localhost:3000
  API: http://localhost:8080

### Lightweight setup (3 containers — no Redis)

  mkdir logtide && cd logtide
  curl -O https://raw.githubusercontent.com/logtide-dev/logtide/main/docker/docker-compose.simple.yml
  curl -O https://raw.githubusercontent.com/logtide-dev/logtide/main/docker/.env.example
  mv .env.example .env
  docker compose -f docker-compose.simple.yml up -d

Backend automatically uses PostgreSQL-based alternatives for job queues and live tail streaming when Redis is absent.

### Optional Docker profiles

  # Docker log collection (Fluent Bit)
  docker compose --profile logging up -d

  # System metrics (CPU, memory, disk, network)
  docker compose --profile metrics up -d

  # ClickHouse storage engine
  docker compose --profile clickhouse up -d

  # MongoDB storage engine
  docker compose --profile mongodb up -d

  # Combine profiles
  docker compose --profile logging --profile metrics up -d

### Data dirs

Persistent data is managed by Docker named volumes for PostgreSQL, Redis (if used), and optional ClickHouse/MongoDB. Check docker-compose.yml for volume definitions.

### Tech stack

| Layer | Technology |
|---|---|
| Frontend | SvelteKit 5 (Runes) + TailwindCSS + ECharts |
| Backend | Fastify (Node.js) + TypeScript |
| Storage | TimescaleDB / ClickHouse / MongoDB |
| Detection | Sigma YAML rules engine |

### SDKs / integrations

Languages: Browser (JS/TS), Node.js, Python, Go, PHP (Laravel/Symfony/WordPress), Kotlin/Java, C#/.NET.
Platforms: Kubernetes (Helm), Docker (Fluent Bit/Syslog), OpenTelemetry (native OTLP for logs/traces/metrics).
API reference: https://logtide.dev/docs/api

## Upgrade procedure

  docker compose pull
  docker compose up -d

Check upstream release notes at https://github.com/logtide-dev/logtide/releases for migration steps before major upgrades.

## Gotchas

- Status is "stable alpha" (v0.9.x) — production-usable but API may change between minor versions.
- Redis is required for live tail streaming and job queues in the full stack; use docker-compose.simple.yml to eliminate this dependency on low-resource hosts.
- ClickHouse and MongoDB are opt-in via Docker profiles — they do not start unless explicitly enabled; the default storage is TimescaleDB (PostgreSQL extension).
- Cloud version available at logtide.dev — useful for testing before committing to self-hosting.
- GDPR/SOC2 features (PII masking, audit logs) require configuration; they are not auto-enabled.
- Sigma rules for threat detection are YAML-based; custom rules can be added through the UI.

## Links

- Upstream README: https://github.com/logtide-dev/logtide
- Documentation: https://logtide.dev/docs
- Helm chart: https://github.com/logtide-dev/logtide-helm-chart
- Docker Hub: https://hub.docker.com/r/logtide/backend
- Artifact Hub: https://artifacthub.io/packages/helm/logtide/logtide
