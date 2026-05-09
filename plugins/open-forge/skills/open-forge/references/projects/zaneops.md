---
name: zaneops
description: "Self-hosted, open-source PaaS for deploying static sites, web apps, databases, workers, and CRON jobs. Powered by Docker Swarm + Caddy. Free alternative to Heroku, Railway, and Render. MIT."
---

# ZaneOps

ZaneOps is a **beautiful, self-hosted, open-source platform** for deploying and managing web applications, static sites, databases, services, workers, and CRON jobs on your own infrastructure. It's a free alternative to **Heroku**, **Railway**, and **Render**, built on [Docker Swarm](https://docs.docker.com/engine/swarm/) for scalability and [Caddy](https://caddyserver.com/) for automatic HTTPS.

Whether you're a solo developer, a startup, or an enterprise, ZaneOps gives you a PaaS experience on hardware you control.

- Upstream repo: <https://github.com/zane-ops/zane-ops>
- Docs: <https://zaneops.dev>
- Discord: <https://discord.gg/..>  (see repo for current link)
- Releases: <https://github.com/zane-ops/zane-ops/releases>

## Architecture in one minute

- **Orchestration**: Docker Swarm (single node or multi-node cluster)
- **Reverse proxy + TLS**: Caddy (automatic HTTPS via Let's Encrypt)
- **Backend**: Python/Django API
- **Frontend**: React (Remix framework)
- **Database**: PostgreSQL + Redis
- **Install**: Single `curl | bash` script bootstraps the whole stack

## Compatible install methods

| Method | Notes |
|---|---|
| **Installer script** (recommended) | `curl -fsSL https://cdn.zaneops.dev/install.sh \| sudo bash` — bootstraps Docker Swarm + all services |
| **Manual / from source** | Clone repo + follow contributor docs — for development only |

## Requirements

- A Linux server (Ubuntu 22.04+ recommended)
- Docker Engine installed (the installer script will set up Swarm)
- Ports 80 and 443 open (Caddy handles TLS)
- A domain name pointed at the server's IP (for production deployments)

## Install

```bash
curl -fsSL https://cdn.zaneops.dev/install.sh | sudo bash
```

The script will:
1. Initialize Docker Swarm if not already active
2. Deploy ZaneOps as a Docker Swarm stack
3. Start all services: API, frontend, PostgreSQL, Redis, Caddy proxy
4. Print the initial admin credentials

For detailed steps, see: <https://zaneops.dev/installation/>

## First boot

1. Navigate to the URL printed by the installer (or your configured domain)
2. Complete the **onboarding wizard** — set admin username + password
3. **Create a project** → add services (web apps, databases, workers)
4. Deploy from:
   - **Docker image** — any registry or Docker Hub image
   - **Git repository** — connect GitHub/GitLab, auto-deploy on push
   - **Static site** — serve from a directory or build output
5. ZaneOps automatically provisions HTTPS via Caddy

## Key features

- **One-command install** — no complex Kubernetes setup
- **Automatic HTTPS** — Caddy handles Let's Encrypt certificates
- **Web apps, databases, workers, CRON** — deploy any Docker-based workload
- **Git-based deployments** — connect repos for CI/CD-style deploys
- **Realtime logs** — HTTP request logs and runtime logs in the UI
- **Multi-project organization** — group services into projects
- **Scaling** — Docker Swarm scaling built in
- **Environment variables** — manage secrets and config per service
- **Custom domains** — attach any domain to a service

## Inputs to collect

| Input | Example | Notes |
|---|---|---|
| Server domain | `deploy.example.com` | For the ZaneOps dashboard itself |
| Admin credentials | username + strong password | Set during onboarding |
| App domain | `myapp.example.com` | Per-service custom domains |
| Git credentials | GitHub/GitLab token | For repo-connected deployments |

## Data & config layout

- All state managed by Docker Swarm + named volumes
- PostgreSQL: app + service metadata
- Redis: task queue + caching
- Caddy: auto-managed TLS certs + proxy config

## Backup

```bash
# Backup PostgreSQL
docker exec $(docker ps -qf name=zaneops_db) pg_dump -U postgres zaneops > zaneops-$(date +%F).sql

# Backup all volumes
docker run --rm -v zaneops_postgres:/data -v $(pwd):/backup alpine \
  tar czf /backup/zaneops-volumes-$(date +%F).tgz /data
```

## Upgrade

```bash
# Re-run the installer script to pull latest images and redeploy
curl -fsSL https://cdn.zaneops.dev/install.sh | sudo bash
```

Or follow the upgrade docs at <https://zaneops.dev/>.

## Gotchas

- **Docker Swarm required**: ZaneOps uses Swarm for orchestration. Single-node Swarm is fine for most use cases, but it's a different model than Docker Compose
- **Ports 80 + 443 must be free**: Caddy takes over these ports for HTTPS. You can't run another reverse proxy on the same ports
- **Not Kubernetes**: ZaneOps targets simplicity over Kubernetes-scale complexity. For K8s-native PaaS, look at Coolify (with K8s support) or similar
- **Early-stage project**: ZaneOps is newer than Coolify/Dokploy. Feature set is growing; check the roadmap/milestones for current status
- **MIT license** — fully permissive; commercial use allowed

## Alternatives

| Tool | Notes |
|---|---|
| **Coolify** | More mature; AGPL; broader feature set |
| **Dokploy** | Docker/Traefik-based; MIT; simpler |
| **Caprover** | Older; large community |
| **Portainer** | Container management (not a PaaS) |
| **Railway / Render / Heroku** | Managed hosted PaaS — no self-hosting |

## Links

- Repo: <https://github.com/zane-ops/zane-ops>
- Docs: <https://zaneops.dev>
- Installation guide: <https://zaneops.dev/installation/>
- Screenshots: <https://zaneops.dev/screenshots/>
- Roadmap: <https://github.com/zane-ops/zane-ops/milestones>
- Releases: <https://github.com/zane-ops/zane-ops/releases>
