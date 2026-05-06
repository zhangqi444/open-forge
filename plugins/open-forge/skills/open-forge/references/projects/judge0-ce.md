---
name: judge0-ce
description: Judge0 CE recipe for open-forge. Covers self-hosting the open-source sandboxed code execution system. Upstream: https://github.com/judge0/judge0
---

# Judge0 CE

Robust, fast, scalable, open-source **sandboxed online code execution system**. Execute code in 90+ programming languages via a simple HTTP JSON API. Used to build competitive programming platforms, AI agent sandboxes, e-learning tools, candidate assessment platforms, and online IDEs. Upstream: <https://github.com/judge0/judge0>. API docs: <https://ce.judge0.com>.

**License:** GPL-3.0

> ⚠️ **Linux only.** Judge0 uses kernel-level cgroups/namespaces for sandboxing. It is tested on Ubuntu 22.04 and requires a specific GRUB configuration. Does not run on macOS or Windows hosts.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose (release archive) | https://github.com/judge0/judge0/blob/master/CHANGELOG.md#deployment-procedure | ✅ | Recommended; official deployment method |

## System requirements (Ubuntu 22.04)

Before deploying, update GRUB to use legacy cgroup v1:

```bash
# 1. Edit /etc/default/grub
sudo nano /etc/default/grub
# Add systemd.unified_cgroup_hierarchy=0 to GRUB_CMDLINE_LINUX:
# GRUB_CMDLINE_LINUX="systemd.unified_cgroup_hierarchy=0"

# 2. Apply and reboot
sudo update-grub
sudo reboot
```

Also requires: Docker, Docker Compose.

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| secrets | "PostgreSQL password?" | Random string → `POSTGRES_PASSWORD` in judge0.conf | Required |
| secrets | "Redis password?" | Random string → `REDIS_PASSWORD` in judge0.conf | Required |
| network | "Port to expose Judge0 API on?" | Default: 2358 | Required |

## Installation

```bash
# 1. Download and extract the release archive
wget https://github.com/judge0/judge0/releases/download/v1.13.1/judge0-v1.13.1.zip
unzip judge0-v1.13.1.zip
cd judge0-v1.13.1

# 2. Edit judge0.conf — set POSTGRES_PASSWORD and REDIS_PASSWORD to random strings
nano judge0.conf

# 3. Start the database and cache, then wait for them to initialize
docker compose up -d db redis
sleep 10

# 4. Start all services
docker compose up -d

# 5. Wait ~30 seconds, then test
sleep 30
curl http://localhost:2358/about
```

## Architecture

| Service | Purpose |
|---|---|
| `server` | HTTP API server (port 2358) |
| `worker` | Code execution workers (runs submissions in sandbox) |
| `db` | PostgreSQL — stores submissions and results |
| `redis` | Job queue between server and workers |

Workers run with `--privileged` (required for kernel sandbox features).

## Software-layer concerns

### judge0.conf (key settings)

```ini
# Database
POSTGRES_DB=judge0
POSTGRES_USER=judge0
POSTGRES_PASSWORD=<random>

# Redis
REDIS_PASSWORD=<random>

# Execution limits (optional tuning)
CPU_TIME_LIMIT=5
MAX_CPU_TIME_LIMIT=15
WALL_TIME_LIMIT=10
MAX_WALL_TIME_LIMIT=150
MEMORY_LIMIT=128000
MAX_MEMORY_LIMIT=512000
MAX_PROCESSES_AND_OR_THREADS=60

# Security
ENABLE_WAIT_RESULT=true
ENABLE_COMPILER_OPTIONS=false   # set true if you trust submitters
```

### Ports

| Port | Purpose |
|---|---|
| 2358 | Judge0 API (HTTP) |

Put behind a reverse proxy with TLS for public deployments.

### Scaling workers

Add more worker instances to handle concurrent submissions:

```yaml
worker:
  image: judge0/judge0:latest
  command: ["./scripts/workers"]
  deploy:
    replicas: 3
```

## API example

```bash
# Submit code and get result
curl -X POST http://localhost:2358/submissions?wait=true \
  -H "Content-Type: application/json" \
  -d '{"language_id": 71, "source_code": "print(\"hello\")"}'
```

Language IDs: see `GET /languages` or https://ide.judge0.com.

## Upgrade procedure

```bash
# Download new release archive
wget https://github.com/judge0/judge0/releases/download/<version>/judge0-<version>.zip
unzip judge0-<version>.zip
cd judge0-<version>
# Copy your judge0.conf from the previous version
cp ../judge0-<old-version>/judge0.conf .
docker compose up -d
```

## Gotchas

- **GRUB cgroup v1 required.** Without `systemd.unified_cgroup_hierarchy=0`, the worker sandbox will fail on Ubuntu 22.04+. This is a kernel setting change that requires a reboot.
- **Privileged containers.** Worker containers run `--privileged` for kernel-level sandboxing. Do not expose Judge0 directly to untrusted users without authentication middleware.
- **Linux only.** Not supported on macOS or Windows hosts.
- **Telemetry.** Judge0 collects telemetry by default. See `TELEMETRY.md` in the release for details and opt-out instructions.
- **`ENABLE_COMPILER_OPTIONS=false` default.** Allowing compiler options can be a security risk; only enable for trusted users.

## Upstream docs

- Deployment guide (CHANGELOG): https://github.com/judge0/judge0/blob/master/CHANGELOG.md#deployment-procedure
- API documentation: https://ce.judge0.com
- IDE (live demo): https://ide.judge0.com
- GitHub README: https://github.com/judge0/judge0
- Releases: https://github.com/judge0/judge0/releases
