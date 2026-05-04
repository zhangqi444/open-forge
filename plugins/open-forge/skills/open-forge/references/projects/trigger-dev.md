# Trigger.dev

Open-source platform for building and running background jobs, scheduled tasks, and AI workflows in TypeScript. Tasks run with no timeouts, have built-in retries, queues, observability, and human-in-the-loop support. Acts as a durable execution engine for long-running AI agents and background processing. Upstream: <https://github.com/triggerdotdev/trigger.dev>. Docs: <https://trigger.dev/docs>.

The Trigger.dev stack has two components:
- **Webapp** — the dashboard, API, and orchestration engine (port `8030`)
- **Supervisor / Worker** — executes tasks in Docker containers

Both can run on the same machine for small workloads, or on separate machines for scale-out. Requires PostgreSQL and Redis.

## Compatible install methods

Verified against upstream docs at <https://trigger.dev/docs/self-hosting/overview>.

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose (webapp + supervisor) | <https://trigger.dev/docs/self-hosting/docker> | ✅ | Recommended self-hosted method. Clone repo, use `hosting/docker/`. |
| Kubernetes | <https://trigger.dev/docs/self-hosting/kubernetes> | ✅ | Production Kubernetes deployments. |
| Trigger.dev Cloud | <https://cloud.trigger.dev> | ✅ | Managed SaaS — out of scope for open-forge. |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| domain | "External URL for the webapp (e.g. `http://trigger.example.com`)?" | Free-text | All |
| secrets | "SECRET_KEY for session encryption?" | Free-text (generate random) | All |
| db | "PostgreSQL connection string?" | Free-text (sensitive) | All |
| redis | "Redis connection string?" | Free-text | All |
| auth | "Magic link email provider (Postmark, Resend, etc.)?" | Free-text (SMTP/API details) | All |

## Software-layer concerns

### Setup (Docker Compose)

Based on upstream self-hosting docs at <https://trigger.dev/docs/self-hosting/docker>:

```bash
git clone --depth=1 https://github.com/triggerdotdev/trigger.dev
cd trigger.dev/hosting/docker

# Create .env from example
cp .env.example .env
# Edit .env — set SESSION_SECRET, DATABASE_URL, REDIS_URL, TRIGGER_PROTOCOL, TRIGGER_DOMAIN, etc.

# Start webapp services
cd webapp
docker compose up -d

# Check logs for magic login link (no password — email magic links)
docker compose logs -f webapp
```

Access the webapp at `http://localhost:8030` (or your configured domain).

### Key environment variables (`.env`)

| Variable | Purpose | Notes |
|---|---|---|
| `SESSION_SECRET` | Session encryption secret | Required. Generate: `openssl rand -hex 32` |
| `DATABASE_URL` | PostgreSQL connection | e.g. `postgresql://user:pass@localhost:5432/triggerdb` |
| `REDIS_URL` | Redis connection | e.g. `redis://localhost:6379` |
| `TRIGGER_PROTOCOL` | HTTP or HTTPS | `http` or `https` |
| `TRIGGER_DOMAIN` | External domain | e.g. `trigger.example.com` |
| `FROM_EMAIL` | Sender email for magic links | e.g. `noreply@example.com` |
| `RESEND_API_KEY` or SMTP vars | Email delivery for magic links | Magic links are the primary auth method |
| `TRIGGER_TELEMETRY_DISABLED` | Disable telemetry | Set to `1` to opt out |

### Architecture

```
[Developer machine]
  → npx trigger.dev@latest deploy   (builds task image)
  → pushes to built-in registry (or external)

[Trigger.dev webapp]
  ← SDK calls from your app code (trigger tasks)
  → schedules runs, stores results, shows dashboard

[Supervisor/Worker]
  → pulls task images, runs them in Docker containers
  → reports results back to webapp
```

Tasks are Docker containers — each deployed version of your tasks creates a new image. The supervisor manages pulling and running these containers.

### Starting a worker (supervisor)

The supervisor runs alongside the webapp or on separate machines:

```bash
cd trigger.dev/hosting/docker/worker
# Edit .env — set TRIGGER_API_URL pointing at your webapp
docker compose up -d
```

### Using the CLI against your self-hosted instance

```bash
# Login to your self-hosted instance
npx trigger.dev@latest login -a http://trigger.example.com

# Develop locally (tasks run against your instance)
npx trigger.dev@latest dev

# Deploy tasks
npx trigger.dev@latest deploy
```

### Services in the webapp compose

| Service | Role |
|---|---|
| `webapp` | Main Trigger.dev application |
| `postgres` | PostgreSQL database |
| `redis` | Queue and cache |
| `registry` | Built-in Docker registry for task images |
| `electric` | ElectricSQL sync layer |
| `docker-socket-proxy` | Secure Docker socket proxy (restricts socket access) |

### Data directories

| Path | Contents |
|---|---|
| PostgreSQL volume | Runs, tasks, projects, users, logs |
| Redis volume | Job queues, pub/sub |
| Registry volume | Deployed task Docker images |

## Upgrade procedure

Based on <https://trigger.dev/docs/self-hosting/upgrading>:

1. Pull latest code: `git pull` in the `trigger.dev/` directory.
2. `docker compose pull` in `hosting/docker/webapp/`.
3. `docker compose up -d` — migrations run automatically.
4. Upgrade the worker separately: `docker compose pull && docker compose up -d` in `hosting/docker/worker/`.
5. Re-deploy your tasks: `npx trigger.dev@latest deploy`.

## Gotchas

- **Magic links for auth (no passwords).** Trigger.dev uses email magic links as the primary auth method. You **must** configure an email provider (Resend, Postmark, SMTP) before you can log in.
- **Tasks are Docker images.** Every task deployment builds and pushes a Docker image to the built-in (or external) registry. The worker pulls and runs these images. Disk space fills up with old image versions — prune regularly.
- **v4 is a major architecture change from v3.** If upgrading from v3, read the migration guide — the provider and coordinator services are replaced by a single supervisor in v4.
- **Worker requires Docker socket access.** The supervisor needs to start Docker containers. The compose file includes `docker-socket-proxy` to limit exposure.
- **Resource requirements are significant.** Webapp needs 3+ vCPU / 6+ GB RAM. Worker needs 4+ vCPU / 8+ GB RAM for meaningful concurrency.
- **No checkpoint support in self-hosted.** Checkpointing (pause/resume long tasks) is not supported when self-hosting.

## Links

- Upstream: <https://github.com/triggerdotdev/trigger.dev>
- Docs: <https://trigger.dev/docs>
- Self-hosting overview: <https://trigger.dev/docs/self-hosting/overview>
- Docker setup guide: <https://trigger.dev/docs/self-hosting/docker>
- Environment variables: <https://trigger.dev/docs/self-hosting/env/webapp>
- Kubernetes guide: <https://trigger.dev/docs/self-hosting/kubernetes>
