---
name: Squirrel Servers Manager (SSM)
description: "Self-hosted server configuration and container management platform. Docker. Node.js + MongoDB + Prometheus + Ansible. SquirrelCorporation/SquirrelServersManager. Manage multiple servers, run Ansible playbooks, monitor containers, automate tasks. Apache-2.0."
---

# Squirrel Servers Manager (SSM)

**Self-hosted all-in-one server configuration and container management tool.** Manage multiple Linux servers from a unified web UI — monitor CPU/RAM metrics via Prometheus, run Ansible playbooks, manage Docker containers across servers, automate tasks with trigger-based automations, and deploy open-source services from a one-click collection. Built on Ansible + Docker + Prometheus.

Built + maintained by **SquirrelCorporation**. Apache-2.0 license.

- Upstream repo: <https://github.com/SquirrelCorporation/SquirrelServersManager>
- Website: <https://squirrelserversmanager.io>
- Docs: <https://squirrelserversmanager.io/docs>
- Demo: <https://demo.squirrelserversmanager.io>

## Architecture in one minute

- **Node.js** server + API
- **React** client (frontend)
- **MongoDB** database
- **Redis** cache
- **Prometheus** for metrics collection
- **Nginx** proxy (bundled in compose)
- Port **8000** (via Nginx proxy)
- GHCR: `ghcr.io/squirrelcorporation/squirrelserversmanager-*`
- Resource: **medium** — Node.js + MongoDB + Prometheus stack

## Compatible install methods

| Infra              | Runtime                      | Notes                                          |
| ------------------ | ---------------------------- | ---------------------------------------------- |
| **Docker Compose** | GHCR images                  | **Primary** — official compose in repo         |
| **Quick install**  | One-liner shell script       | `curl ... | bash` — auto-configures .env       |

## Quick install (fastest)

```bash
curl https://raw.githubusercontent.com/SquirrelCorporation/SquirrelServersManager/refs/heads/master/getSSM.sh | bash
```

Automatically downloads, configures `.env`, and starts the stack.

## Manual install

```bash
git clone https://github.com/SquirrelCorporation/SquirrelServersManager.git
cd SquirrelServersManager
# Edit .env (see docs: https://squirrelserversmanager.io/docs/getting-started/installation#step-2-create-env-file)
cp .env.example .env
nano .env
docker compose up -d
```

Visit `http://localhost:8000`.

## Inputs to collect

| Input | Notes |
|-------|-------|
| `MONGO_URI` | MongoDB connection string (auto-configured by compose) |
| `REDIS_URL` | Redis connection (auto-configured) |
| `JWT_SECRET` | Secret for JWT signing |
| `VAULT_PWD` | Ansible Vault encryption password for secrets |
| `TELEMETRY_ENABLED` | Set `false` to disable anonymous telemetry |

See full `.env` reference: <https://squirrelserversmanager.io/docs/getting-started/installation#step-2-create-env-file>

## Features overview

| Feature | Details |
|---------|---------|
| Multi-server management | Add, view, and manage multiple Linux servers from one dashboard |
| Metrics & monitoring | CPU, RAM, disk, network via Prometheus; anomaly detection |
| Container management | View running containers across servers; stats; update alerts |
| Ansible playbooks | Manage + run playbooks (local or from Git repos) on your servers |
| Automations | Trigger actions (playbooks, container ops) on events |
| Collections / App store | One-click deploy of open-source services on your servers |
| Security | Secrets encrypted via Ansible Vault; passwords hashed with bcrypt |
| Advanced configuration | Fine-grained options for complex setups |
| Integrations | (Coming soon) Trigger from external tools, call external services |

## Adding your first server

1. Go to **Devices** → **Add Device**.
2. Enter the server IP, SSH username, and authentication method (password or SSH key).
3. SSM connects via SSH and sets up the Ansible connection.
4. The server appears on the dashboard with live metrics.
5. Run playbooks, manage containers, or set up automations from the device view.

## Gotchas

- **Ansible is required on target servers.** SSM uses Ansible under the hood for playbook execution. The managed server must have Python installed (Ansible requirement). SSM may handle this automatically — check the docs for target server requirements.
- **SSH access required.** Each managed server needs SSH access from your SSM host. Configure SSH keys (recommended over password auth) before adding devices.
- **Vault password must be set.** `VAULT_PWD` is used to encrypt secrets in Ansible Vault. Don't lose it — rotating it requires re-encrypting all stored secrets.
- **Telemetry is on by default.** SSM collects anonymized usage statistics. Set `TELEMETRY_ENABLED=false` in `.env` to disable.
- **Demo available.** Before deploying, try the live demo at <https://demo.squirrelserversmanager.io>.

## Backup

```sh
docker compose exec mongo mongodump --out /data/backup
# Back up .data.prod/db (MongoDB), .data.prod/cache (Redis), .data.prod/prometheus
```

## Upgrade

```sh
docker compose pull && docker compose up -d
```

## Project health

Active Node.js + Ansible + Prometheus development, multi-server, container management, one-click app collections. Apache-2.0 license.

## Server-management-family comparison

- **SSM** — Node.js, Ansible-based, multi-server, containers, metrics, automations, Apache-2.0
- **Ansible AWX / Tower** — heavy enterprise Ansible platform; much more complex
- **Cockpit** — RPM-based server cockpit; local to each server; no cross-server aggregation
- **Portainer** — Docker-focused; excellent container UI; no Ansible playbooks or multi-server metrics
- **Webmin** — Perl, per-server admin panel; older architecture; no cross-server management

**Choose SSM if:** you want a modern, Docker-deployed platform to manage multiple Linux servers — running Ansible playbooks, monitoring metrics, managing containers, and automating tasks from one web UI.

## Links

- Repo: <https://github.com/SquirrelCorporation/SquirrelServersManager>
- Docs: <https://squirrelserversmanager.io/docs>
- Demo: <https://demo.squirrelserversmanager.io>
