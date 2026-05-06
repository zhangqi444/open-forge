---
name: middleware
description: Middleware recipe for open-forge. Open-source engineering management tool that measures and analyzes team effectiveness using DORA metrics. Source: https://github.com/middlewarehq/middleware
---

# Middleware

Open-source engineering management tool designed to help engineering leaders measure and analyze the effectiveness of their teams using the DORA metrics (Deployment Frequency, Lead Time for Changes, Mean Time to Restore, Change Failure Rate). Upstream: <https://github.com/middlewarehq/middleware>. Website: <https://middlewarehq.com/>.

Middleware connects to your CI/CD tools, version control, and project management platforms to automatically collect and visualize DORA metrics. It includes a Python analytics backend, a Node.js sync server, and a React frontend — all bundled into a single Docker image for easy self-hosting.

## Compatible install methods

| Method | Platform | Notes |
|---|---|---|
| Docker (single container) | Any Linux with Docker | Recommended. All services bundled in `middlewareeng/middleware:latest`. |
| Docker Compose (dev) | Linux / macOS | Development mode with live reload. |
| Manual setup | Linux | Python + Node.js; for development only. |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| network | "Port to expose the web UI on?" | Default: `3333` |
| integrations | "Which CI/CD / VCS tools to connect?" | GitHub, GitLab, Jira, etc. |
| auth | "GitHub/GitLab OAuth app credentials?" | Client ID + secret for OAuth login |

## Software-layer concerns

- **Image:** `middlewareeng/middleware:latest`
- **Ports:**
  - `3333` — Web UI / frontend
  - `9696` — Analytics server (Python)
  - `9697` — Sync server (Node.js)
- **Volumes:**
  - `middleware_postgres_data` → `/var/lib/postgresql/data` (PostgreSQL)
  - `middleware_keys` → `/app/keys` (encryption keys)
- **Database:** PostgreSQL (bundled inside the container)
- **Config:** Environment variables; see `.env.example` in the repo

### Quick start

```bash
docker volume create middleware_postgres_data
docker volume create middleware_keys

docker run --name middleware \
  -p 3333:3333 \
  -p 9696:9696 \
  -p 9697:9697 \
  -v middleware_postgres_data:/var/lib/postgresql/data \
  -v middleware_keys:/app/keys \
  -d middlewareeng/middleware:latest

docker logs -f middleware
```

Wait for all services to initialize (watch the logs). The app is available at `http://localhost:3333`.

### Docker Compose (production-like)

```yaml
services:
  middleware:
    image: middlewareeng/middleware:latest
    ports:
      - "3333:3333"
      - "9696:9696"
      - "9697:9697"
    volumes:
      - middleware_postgres_data:/var/lib/postgresql/data
      - middleware_keys:/app/keys
    restart: unless-stopped

volumes:
  middleware_postgres_data:
  middleware_keys:
```

## Upgrade procedure

1. Pull the new image: `docker pull middlewareeng/middleware:latest`
2. Stop the container: `docker stop middleware && docker rm middleware`
3. Re-run with the same `docker run` command (volumes preserve data)
4. Check the [releases page](https://github.com/middlewarehq/middleware/releases) for migration notes

## Gotchas

- **Startup time**: all three services (Postgres, Python backend, Node sync, React frontend) start inside the container; allow 60-90 seconds before the UI is responsive.
- **Port conflicts**: ports `9696` and `9697` may conflict with other services. Remap with `-p <host>:<container>` if needed.
- **Volume persistence**: always use named volumes (not bind mounts) for `middleware_postgres_data` to avoid permission issues.
- **Integration tokens**: OAuth tokens for GitHub/GitLab are stored in the database. Back up the volume before upgrades.
- **Low commit activity**: as of 2026, commit activity has slowed — verify the project is still actively maintained before adopting.

## References

- [Upstream README](https://github.com/middlewarehq/middleware#readme)
- [Website](https://middlewarehq.com/)
- [Docker Hub](https://hub.docker.com/r/middlewareeng/middleware)
- [DORA metrics explained](https://dora.dev/guides/dora-metrics-four-keys/)
