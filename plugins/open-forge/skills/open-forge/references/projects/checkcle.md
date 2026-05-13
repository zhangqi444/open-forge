---
name: CheckCle
description: "Real-time full-stack monitoring platform. Uptime, server metrics (CPU/RAM/disk), SSL/domain monitoring, status pages, incidents, notifications. Multi-language (English/Khmer/Japanese/Chinese). Single Docker container backed by PocketBase. MIT. operacle/checkcle."
---

# CheckCle

CheckCle is an open-source full-stack monitoring platform — monitoring HTTP, DNS, Ping, TCP, SSL/domain, and infrastructure servers (CPU/RAM/disk/network). Features status pages, incident management, maintenance scheduling, reports, and notifications via email, Telegram, Discord, Slack, Matrix and more. Multi-language UI (English, Khmer, Japanese, Chinese). **MIT licensed.** Single-container Docker deployment using PocketBase as the backend.

Built + maintained by **operacle** (tolaleng@checkcle.io). Sponsored by Cloudflare, DigitalOcean, JetBrains.

Use cases: (a) **uptime monitoring** (HTTP/DNS/Ping/TCP) (b) **server health monitoring** (CPU/RAM/disk/network) (c) **SSL & domain expiry tracking** (d) **public status pages** (e) **incident & maintenance management** (f) **multi-language team monitoring** — accessible to non-English teams.

- Upstream repo: <https://github.com/operacle/checkcle>
- Docs: <https://docs.checkcle.io>
- Live demo: <https://demo.checkcle.io> (user: `admin@example.com` / password: `Admin123456`)
- Discord: <https://discord.gg/xs9gbubGwX>
- Website: <https://checkcle.io>

## Architecture in one minute

- **Single container** — `operacle/checkcle` bundles the app and PocketBase backend
- **Port 8090** — web UI and API
- **Volume `/mnt/pb_data`** — all monitoring data, config, users
- **Architectures**: amd64, arm64 (Raspberry Pi 3/4/5, Apple Silicon)

## Compatible install methods

| Infra              | Runtime                          | Notes                                              |
| ------------------ | -------------------------------- | -------------------------------------------------- |
| **Docker Compose** | `operacle/checkcle:latest`        | **Recommended** — single container                 |
| **Docker run**     | `operacle/checkcle:latest`        | Quick start                                        |

## Inputs to collect

| Input                     | Example                          | Phase        | Notes                                             |
| ------------------------- | -------------------------------- | ------------ | ------------------------------------------------- |
| Domain                    | `monitor.example.com`            | URL          | TLS via reverse proxy                             |
| Admin creds               | `admin@example.com` / `Admin123456` | Bootstrap | Change on first login                             |
| Notification channels     | Email / Slack / Telegram / Discord | Integrations |                                                  |
| Monitored targets         | URLs, servers, services          | Config       |                                                   |
| Agent tokens (server-monitoring) | Per-server                | **CRITICAL** | Agents run with elevated access on monitored hosts |

## Install via Docker Compose

```yaml
version: '3.9'

services:
  checkcle:
    image: operacle/checkcle:latest
    container_name: checkcle
    restart: unless-stopped
    ports:
      - "8090:8090"
    volumes:
      - /opt/pb_data:/mnt/pb_data
    ulimits:
      nofile:
        soft: 4096
        hard: 8192
```

## Install via Docker run

```bash
docker run -d \
  --name checkcle \
  --restart unless-stopped \
  -p 8090:8090 \
  -v /opt/pb_data:/mnt/pb_data \
  --ulimit nofile=4096:8192 \
  operacle/checkcle:latest
```

## First boot

1. Browse `http://your-server:8090`
2. Log in with default credentials: `admin@example.com` / `Admin123456` — **change immediately**
3. Add monitoring targets (HTTP / DNS / Ping / TCP / SSL)
4. Configure notification channels (email, Telegram, Discord, Slack, Matrix)
5. Set up server-monitoring agents (one-line install script from the UI)
6. Create a public status page
7. Put behind TLS reverse proxy
8. Back up `/opt/pb_data`

## Data & config layout

- `/opt/pb_data` (host) -> `/mnt/pb_data` (container) — all data: monitors, incidents, users, config

## Backup

```sh
# Stop container, archive data directory, restart
docker stop checkcle
sudo tar czf checkcle-$(date +%F).tgz /opt/pb_data
docker start checkcle
```

## Upgrade

```sh
docker pull operacle/checkcle:latest
docker stop checkcle && docker rm checkcle
# Re-run with same flags (data persists in /opt/pb_data)
docker run -d --name checkcle --restart unless-stopped \
  -p 8090:8090 -v /opt/pb_data:/mnt/pb_data \
  --ulimit nofile=4096:8192 operacle/checkcle:latest
```

Or with compose: `docker compose pull && docker compose up -d`

## Gotchas

- **Default credentials** — change `Admin123456` immediately after first login.
- **Agent on server = privileged access** — server-monitoring agents run with elevated access. Compromise of CheckCle master -> potential agent RCE on all monitored hosts. Keep CheckCle network-isolated.
- **PocketBase backend** — all data is in `/mnt/pb_data`. Back it up regularly.
- **`nofile` ulimit** — required to avoid `too many open files` errors under load; the compose/run examples set it correctly.
- **Notification channel creds** — email SMTP, Slack webhook, Telegram bot tokens, webhook URLs stored in CheckCle DB; protect with TLS + auth.
- **MONITORING-TOOL-CATEGORY (crowded):**
  - **CheckCle** — multi-language; full-stack; single container
  - **Uptime Kuma** — popular; minimal; SQLite
  - **Checkmate** — uptime + infrastructure; Node.js + MongoDB
  - **Gatus** — YAML-driven; minimal storage
  - **Prometheus + Grafana** — metrics-first
- **ALTERNATIVES WORTH KNOWING:**
  - **Uptime Kuma** — if you want simple + popular
  - **Checkmate** — if you want built-in infrastructure monitoring + Node.js stack
  - **Gatus** — if you want YAML-driven + config-as-code
  - **Choose CheckCle if:** you want modern UI + multi-language team + full-stack coverage in a single container.

## Links

- Repo: <https://github.com/operacle/checkcle>
- Docs: <https://docs.checkcle.io>
- Demo: <https://demo.checkcle.io>
- Discord: <https://discord.gg/xs9gbubGwX>
- Uptime Kuma (alt): <https://github.com/louislam/uptime-kuma>
- Gatus (alt): <https://github.com/TwiN/gatus>
- Checkmate (alt): <https://github.com/bluewave-labs/checkmate>
