---
name: autobase
description: Recipe for self-hosting Autobase, an automated platform for deploying and managing highly available PostgreSQL clusters — a self-hosted alternative to cloud-managed DBaaS. Based on upstream documentation at https://github.com/autobase-tech/autobase.
---

# Autobase

Automated internal PostgreSQL platform. Deploy, manage, scale, and upgrade production-ready, highly available PostgreSQL clusters through a web console. Automates failover, backups, restore, and upgrades using Ansible under the hood. Self-hosted alternative to AWS RDS, Google Cloud SQL, and similar DBaaS products. Upstream: <https://github.com/autobase-tech/autobase>. Stars: 4.2k+. License: MIT.

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux host | Docker Compose + Caddy | Recommended; auto SSL via Caddy |
| Any Linux host | Docker Compose (no proxy) | Manual TLS/reverse proxy setup |
| Single-container | `docker run` | Quick start / evaluation only |

Autobase Console manages external PostgreSQL cluster nodes (separate Linux servers). The Console itself runs in Docker; the PostgreSQL clusters it manages run on target servers via SSH + Ansible.

## Service architecture

| Service | Image | Port | Role |
|---|---|---|---|
| autobase-console-api | autobase/console_api | 8080 (internal) | REST API; triggers Ansible automation |
| autobase-console-ui | autobase/console_ui | 80 | Web management UI |
| autobase-console-db | autobase/console_db | 5432 (internal) | Console's own PostgreSQL metadata DB |
| dbdesk-studio | (optional) | 9876 | Database IDE (optional) |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| required | DOMAIN | FQDN for the console (e.g. autobase.example.com) — for Caddy auto-SSL |
| required | EMAIL | Admin email for Caddy Let's Encrypt |
| required | AUTH_TOKEN | Authorization token for the console API |
| target servers | SSH access | Console needs SSH access to target PostgreSQL nodes |

## Docker Compose deployment (with Caddy SSL)

```bash
# 1. Clone repo
git clone https://github.com/autobase-tech/autobase.git
cd autobase/console

# 2. Configure environment
cp .env.example .env
# Edit .env:
#   DOMAIN=autobase.your-domain.com
#   EMAIL=admin@your-domain.com
#   AUTH_TOKEN=your-secret-token

# 3. Deploy with Caddy (auto SSL)
docker compose -f docker-compose.caddy.yml up -d
```

Console UI available at `https://autobase.your-domain.com`.

## Docker Compose deployment (no SSL proxy)

```bash
docker compose up -d
```

Console UI available at `http://your-server-ip:80`. Add your own reverse proxy for TLS.

## Quick evaluation (single docker run)

```bash
docker run -d --name autobase-console \
  --publish 80:80 \
  --env PG_CONSOLE_AUTHORIZATION_TOKEN=secret_token \
  --env PG_CONSOLE_DOCKER_IMAGE=autobase/automation:latest \
  --volume console_postgres:/var/lib/postgresql \
  --volume /var/run/docker.sock:/var/run/docker.sock \
  --volume /tmp/ansible:/tmp/ansible \
  --restart=unless-stopped \
  autobase/console:latest
```

Open `http://localhost:80` and use `secret_token` for authorization.

## .env reference

```bash
# Required
DOMAIN=autobase.your-domain.com    # Console domain (Caddy SSL)
EMAIL=admin@your-domain.com        # Let's Encrypt contact email
AUTH_TOKEN=your-secret-token       # API auth token

# Optional
PG_CONSOLE_LOGGER_LEVEL=INFO       # Log level (DEBUG, INFO, WARN, ERROR)
PG_CONSOLE_DBDESK_STUDIO_PORT=9876 # DBdesk studio port
```

## Data volumes

| Volume | Contents |
|---|---|
| console_postgres | Console's own metadata database |
| /tmp/ansible | Ansible working directory (temporary) |

## Upgrade procedure

```bash
cd autobase/console
git pull
docker compose -f docker-compose.caddy.yml pull
docker compose -f docker-compose.caddy.yml up -d
```

The console DB migrations run automatically on startup.

## Gotchas

- Autobase Console itself runs in Docker, but the **PostgreSQL clusters it manages run on separate target servers** — you need SSH access (with an appropriate user and key) from the console to each target node.
- Run the console on the **same network** as your database servers for proper cluster status monitoring.
- The Docker socket (`/var/run/docker.sock`) is mounted so the console can launch the Automation (Ansible) container to perform cluster operations.
- `AUTH_TOKEN` is the only access control for the console — choose a strong random value and protect it.
- For production, always use the Caddy-based Compose file or configure your own TLS termination — the console API communicates credentials and cluster configs.

## Upstream docs

- README: https://github.com/autobase-tech/autobase/blob/main/README.md
- Console README: https://github.com/autobase-tech/autobase/blob/main/console/README.md
- Full documentation: https://autobase.tech/docs
