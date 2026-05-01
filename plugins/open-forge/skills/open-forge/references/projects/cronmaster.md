---
name: CronMaster
description: "Self-hosted cron job management web UI. Docker. Next.js. fccview/cronmaster. View/create/delete cron jobs, script management, live log streaming (SSE), system info, OIDC SSO, REST API. Runs as root with host PID."
---

# CronMaster

**Self-hosted web UI for managing system cron jobs.** View, create, and delete cron jobs through a modern Next.js interface with dark/light mode. Manage bash scripts, stream live job output, view system info (uptime, memory, CPU, network, GPU), and track execution history. REST API with API key auth. OIDC/SSO support.

Built + maintained by **fccview**. See repo license.

- Upstream repo: <https://github.com/fccview/cronmaster>
- GHCR: `ghcr.io/fccview/cronmaster`
- Discord: <http://discord.gg/invite/mMuk2WzVZu>

## Architecture in one minute

- **Next.js** web application (Node.js)
- Runs as **root** with `privileged: true` and `pid: host` — directly reads/writes host crontabs
- Port **40123** → container port **3000**
- Mounts Docker socket for Docker-aware features
- Persistent state: `./data/` + `./scripts/` + `./snippets/` volumes
- Resource: **low** — Node.js; minimal overhead

## Compatible install methods

| Infra      | Runtime                        | Notes                                    |
| ---------- | ------------------------------ | ---------------------------------------- |
| **Docker** | `ghcr.io/fccview/cronmaster`   | **Only supported method** — requires host PID namespace |

## Inputs to collect

| Input              | Example               | Phase  | Notes                                                                    |
| ------------------ | --------------------- | ------ | ------------------------------------------------------------------------ |
| `AUTH_PASSWORD`    | strong password       | Auth   | Admin login password — **change from default**                           |
| `HOST_CRONTAB_USER`| `root`                | Config | The crontab user to read/write (usually `root`)                          |

## Install via Docker Compose

```yaml
services:
  cronmaster:
    image: ghcr.io/fccview/cronmaster:latest
    container_name: cronmaster
    user: "root"
    ports:
      - "40123:3000"
    environment:
      - NODE_ENV=production
      - DOCKER=true
      - NEXT_PUBLIC_CLOCK_UPDATE_INTERVAL=30000
      - AUTH_PASSWORD=very_strong_password
      - HOST_CRONTAB_USER=root
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ./scripts:/app/scripts
      - ./data:/app/data
      - ./snippets:/app/snippets
    pid: "host"
    privileged: true
    restart: always
    init: true
```

Visit `http://localhost:40123`.

## First boot

1. Set `AUTH_PASSWORD` to a strong password before starting.
2. `docker compose up -d`.
3. Visit `http://localhost:40123`.
4. Log in with `AUTH_PASSWORD`.
5. Existing cron jobs on the host appear immediately.
6. Click "+" to add a new cron job — use the quick-preset buttons (hourly, daily, etc.) or type a custom cron expression.
7. Write and save scripts in the Scripts section — reference them from cron jobs.
8. Enable logging for jobs where you want execution history + live output streaming.
9. Put behind TLS.

## Features overview

| Feature | Details |
|---------|---------|
| Cron management | View all cron jobs; create + delete; comment support |
| Quick presets | Common schedule shortcuts (hourly, daily, weekly, etc.) |
| Script manager | Create, edit, delete bash scripts; use in cron jobs |
| Snippet library | Reusable script snippets |
| Execution logging | Optional per-job logging: stdout, stderr, exit code, timestamp |
| Live log streaming | SSE-based real-time output for running jobs (when logging enabled) |
| System info | Uptime, memory, CPU, network, GPU stats |
| REST API | Full API with optional API key authentication |
| OIDC/SSO | Single Sign-On via OpenID Connect |
| Dark/light mode | Responsive UI; works on mobile |

## Gotchas

- **Runs as root + privileged.** CronMaster requires `user: root`, `privileged: true`, and `pid: host` to read and write the host's crontab. This is a significant security footprint — it has full host access. Only run on trusted networks; put behind authentication + TLS.
- **`pid: host`** shares the host's PID namespace with the container. This allows CronMaster to see all host processes and modify host crontabs. Without this, cron job management doesn't work.
- **Docker socket mount.** Mounting `/var/run/docker.sock` gives CronMaster full Docker API access (start/stop containers, etc.). Treat this as equivalent to root on Docker operations.
- **Change `AUTH_PASSWORD` before deploying.** The default placeholder password must be changed. Anyone who can reach port 40123 can log in with it.
- **Logging vs. synchronous execution.** Jobs with logging enabled run in the background with live SSE streaming. Jobs without logging run synchronously with a 5-minute timeout. For long-running jobs, enable logging.
- **`HOST_CRONTAB_USER=root`.** By default, CronMaster manages the root crontab. To manage a different user's crontab (e.g. `ubuntu`), change this variable. The container still needs root access to read other users' crontabs.
- **Scripts are in the container.** Scripts written via the UI are stored in `./scripts` (mounted into the container). When cron runs the scripts, they execute inside the container's PID namespace — not directly on the host, despite `pid: host`. Test your scripts carefully.

## Backup

```sh
sudo tar czf cronmaster-$(date +%F).tgz data/ scripts/ snippets/
```

## Upgrade

```sh
docker compose pull && docker compose up -d
```

## Project health

Active Next.js development, GHCR, OIDC/SSO, REST API, live SSE log streaming, system info, Discord. Solo-maintained by fccview.

## Cron-management-family comparison

- **CronMaster** — Next.js, web UI, scripts, live logs, OIDC, system info, REST API; privileged Docker
- **Ofelia** — Go, Docker-native job scheduler; labels-based; no web UI
- **Supercronic** — Go, crontab-compatible; better error handling; no web UI
- **Cronitor** — SaaS monitoring; not a manager
- **Crontab.guru** — cron expression helper website; not a manager

**Choose CronMaster if:** you want a modern web UI for viewing and managing system cron jobs with script management, live log streaming, and OIDC support — and accept the privileged container requirement.

## Links

- Repo: <https://github.com/fccview/cronmaster>
- GHCR: `ghcr.io/fccview/cronmaster`
- Discord: <http://discord.gg/invite/mMuk2WzVZu>
