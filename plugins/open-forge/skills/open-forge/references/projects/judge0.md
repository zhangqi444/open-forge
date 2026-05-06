---
name: judge0
description: Judge0 CE recipe for open-forge. Robust, sandboxed online code execution system supporting 60+ languages. Self-hosted via Docker Compose (privileged containers required). Source: https://github.com/judge0/judge0. Docs: https://ce.judge0.com.
---

# Judge0 CE

Robust, scalable, sandboxed online code execution system. Accepts code submissions via REST API, compiles and runs them in isolated containers, and returns stdout/stderr/exit code. Supports 60+ languages. Used to build competitive programming platforms, LMS code runners, AI code execution sandboxes, and candidate assessment tools. Upstream: <https://github.com/judge0/judge0>. API docs: <https://ce.judge0.com>.

> **Note on editions:** Judge0 CE (Community Edition) is the open-source version (GPL-3.0). Judge0 Extra CE adds more languages. A managed SaaS is available at judge0.com.

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Linux VPS / bare metal | Docker Compose | Only supported deployment; privileged containers required for isolation |
| Linux server | Docker Compose | Minimum: 4 GB RAM, 2 CPU cores recommended |

> **Linux only:** Judge0 requires Linux with Docker. macOS and Windows are not supported for production (kernel-level isolation needed).

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| security | "Set AUTHN_TOKEN for API auth?" | Random string; required to protect your instance from public abuse |
| security | "Set REDIS_PASSWORD?" | Secure the Redis instance |
| db | "POSTGRES_PASSWORD?" | For Judge0's internal PostgreSQL |
| port | "Port for Judge0 API?" | Default: 2358 |
| limits | "Default CPU/memory limits per submission?" | Configurable in judge0.conf (CPU_TIME_LIMIT, MEMORY_LIMIT) |

## Software-layer concerns

- Config file: judge0.conf (env-var format; mounted read-only into containers)
- Default port: 2358
- Services: server (API), worker(s) (code execution), PostgreSQL (submissions DB), Redis (job queue)
- Privileged containers: required for the worker service (uses Linux namespaces/cgroups for sandboxing)
- Execution isolation: each submission runs in a temporary Docker container with resource limits
- Languages: 60+ out of the box; extra languages available in Judge0 Extra CE image
- Horizontal scaling: add more worker replicas for higher throughput

### Deployment steps (from upstream CHANGELOG)

```bash
# 1. Download docker-compose.yml and judge0.conf
wget https://github.com/judge0/judge0/releases/latest/download/judge0-v1.13.1.zip
unzip judge0-v1.13.1.zip && cd judge0-v1.13.1

# 2. Edit judge0.conf — set REDIS_PASSWORD, POSTGRES_PASSWORD, AUTHN_TOKEN
nano judge0.conf

# 3. Start services
docker compose up -d db redis
sleep 10
docker compose up -d

# 4. Test
curl http://localhost:2358/system_info
```

### Minimal judge0.conf settings to change

```conf
# Security
AUTHN_TOKEN=<your-random-token>
AUTHN_HEADER=X-Auth-Token

# Database
POSTGRES_PASSWORD=<db-password>

# Redis
REDIS_PASSWORD=<redis-password>

# Resource limits (adjust per your needs)
CPU_TIME_LIMIT=5
MEMORY_LIMIT=262144
```

### Docker Compose (structure)

```yaml
services:
  server:
    image: judge0/judge0:latest
    volumes:
      - ./judge0.conf:/judge0.conf:ro
    ports:
      - "2358:2358"
    privileged: true
    restart: always

  worker:
    image: judge0/judge0:latest
    command: ["./scripts/workers"]
    volumes:
      - ./judge0.conf:/judge0.conf:ro
    privileged: true
    restart: always

  db:
    image: postgres:16.2
    env_file: judge0.conf
    volumes:
      - data:/var/lib/postgresql/data/
    restart: always

  redis:
    image: redis:7.2.4
    command: ["bash", "-c", 'docker-entrypoint.sh --requirepass "$$REDIS_PASSWORD"']
    env_file: judge0.conf
    restart: always

volumes:
  data:
```

Always use the official versioned release zip — it contains the matching judge0.conf template.

## Upgrade procedure

1. Download new release zip from https://github.com/judge0/judge0/releases
2. Merge your settings from old judge0.conf into the new one (check for new config keys)
3. `docker compose down`
4. Replace docker-compose.yml and judge0.conf with new versions (keeping your customisations)
5. `docker compose up -d`
6. Verify: `curl http://localhost:2358/system_info`

## Gotchas

- **privileged: true is required**: Worker containers need elevated privileges for code sandboxing (Linux cgroups, namespaces, seccomp). This is a security trade-off — run Judge0 on dedicated isolated infrastructure, not alongside sensitive services.
- **AUTHN_TOKEN is critical**: Without authentication, anyone who can reach your instance can run arbitrary code. Always set AUTHN_TOKEN before exposing Judge0 publicly.
- **Linux host required**: The isolation mechanism is Linux-specific. Docker Desktop on macOS/Windows will not work correctly.
- **Worker scaling**: The default single worker handles ~10 concurrent submissions. Add worker replicas (`docker compose scale worker=N`) for higher throughput.
- **Submission queue**: Redis is the job queue. Size Redis memory appropriately if you expect bursts of submissions.
- **Large image**: The Judge0 image bundles compilers/runtimes for 60+ languages and is large (~5–10 GB). First pull takes time.
- **Telemetry**: Enabled by default. Disable with `JUDGE0_TELEMETRY_ENABLE=false` in judge0.conf.

## Links

- Upstream repo: https://github.com/judge0/judge0
- API docs (Swagger UI): https://ce.judge0.com
- Deployment procedure: https://github.com/judge0/judge0/blob/master/CHANGELOG.md#deployment-procedure
- Docker Hub: https://hub.docker.com/r/judge0/judge0
- Release notes: https://github.com/judge0/judge0/releases
- Judge0 IDE (demo): https://ide.judge0.com
