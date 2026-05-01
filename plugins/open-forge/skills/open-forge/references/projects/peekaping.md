---
name: Peekaping
description: "Modern self-hosted uptime monitoring with status pages. Docker. Go + React. 0xfurai/peekaping. HTTP/TCP/DNS/ICMP/gRPC/SNMP/DB monitors, 20+ alert channels, SQLite/PostgreSQL/MongoDB, Terraform provider, MFA, status pages, SVG badges. MIT."
---

# Peekaping

**Modern uptime monitoring built for DevOps teams.** Monitor websites, APIs, databases, message brokers, and infrastructure services. API-first architecture for full automation. 17 monitor types (HTTP, TCP, DNS, ICMP, Docker, gRPC, SNMP, PostgreSQL, MySQL, MongoDB, Redis, RabbitMQ, Kafka, MQTT, MSSQL). 20+ notification channels. SQLite/PostgreSQL/MongoDB storage. Terraform provider. Beautiful status pages. Currently in **beta**.

Built + maintained by **0xfurai**. MIT license.

- Upstream repo: <https://github.com/0xfurai/peekaping>
- Website: <https://peekaping.com>
- Docs: <https://docs.peekaping.com>
- Live demo: <https://demo.peekaping.com>
- Docker Hub: `0xfurai/peekaping-bundle-sqlite` / `0xfurai/peekaping-web`
- Terraform provider: <https://registry.terraform.io/providers/tafaust/peekaping>

## Architecture in one minute

- **Go** server (API + monitoring engine)
- **React + TypeScript** frontend
- Storage: **SQLite** (default, zero-config), **PostgreSQL**, or **MongoDB**
- Bundle images: everything in one container (`peekaping-bundle-sqlite`, `peekaping-bundle-postgres`, `peekaping-bundle-mongo`)
- Separate images: `peekaping-web` + `peekaping-server` + DB
- Port **8383** (bundle images)
- Resource: **low** — Go daemon; minimal overhead per monitor

## Compatible install methods

| Infra      | Runtime                                  | Notes                                                        |
| ---------- | ---------------------------------------- | ------------------------------------------------------------ |
| **Docker** | `0xfurai/peekaping-bundle-sqlite`        | **Easiest** — all-in-one with SQLite                         |
| **Docker** | `0xfurai/peekaping-bundle-postgres`      | All-in-one with PostgreSQL                                   |
| **Docker** | `0xfurai/peekaping-bundle-mongo`         | All-in-one with MongoDB                                      |

Full install guides: <https://docs.peekaping.com/self-hosting/>

## Install (SQLite — quickstart)

```bash
docker run -d --restart=always \
  -p 8383:8383 \
  -e DB_NAME=/app/data/peekaping.db \
  -v $(pwd)/.data/sqlite:/app/data \
  --name peekaping \
  0xfurai/peekaping-bundle-sqlite:latest
```

Visit `http://localhost:8383`.

## Install via Docker Compose (PostgreSQL)

See: <https://docs.peekaping.com/self-hosting/docker-with-postgres>

```yaml
services:
  peekaping:
    image: 0xfurai/peekaping-bundle-postgres:latest
    ports:
      - "8383:8383"
    environment:
      - DB_HOST=postgres
      - DB_PORT=5432
      - DB_USER=peekaping
      - DB_PASSWORD=changeme
      - DB_NAME=peekaping
    depends_on:
      - postgres

  postgres:
    image: postgres:17-alpine
    environment:
      POSTGRES_USER: peekaping
      POSTGRES_PASSWORD: changeme
      POSTGRES_DB: peekaping
    volumes:
      - pg_data:/var/lib/postgresql/data

volumes:
  pg_data:
```

## First boot

1. Start the container.
2. Visit `http://localhost:8383`.
3. Register your admin account.
4. Add monitors:
   - **HTTP/HTTPS**: URL + expected status code + optional headers
   - **TCP**: host + port
   - **DNS**: hostname + record type + expected values
   - Others: configure per type
5. Set up notification channels (email, Slack, Discord, Telegram, etc.).
6. Create status pages for public display.
7. Enable **MFA** in account settings.
8. Put behind TLS.

## Monitor types (17)

| Monitor | Details |
|---------|---------|
| HTTP/HTTPS | Status code, response body, SSL cert expiry |
| TCP | Port connectivity |
| Ping (ICMP) | Network reachability |
| DNS | Record resolution + validation |
| Push | Incoming webhook (heartbeat pattern) |
| Docker container | Container status check |
| gRPC | gRPC health check protocol |
| SNMP | Network device monitoring |
| PostgreSQL | Database connectivity + optional query |
| MySQL/MariaDB | Database connectivity |
| Microsoft SQL Server | Database connectivity |
| MongoDB | Database connectivity |
| Redis | Cache connectivity |
| MQTT Broker | Message broker connectivity |
| RabbitMQ | Queue broker connectivity |
| Kafka Producer | Streaming platform connectivity |

## Alert channels (20+)

Email (SMTP), Webhook, Telegram, Slack, Google Chat, Signal, Mattermost, Matrix, Discord, WeCom, WhatsApp (WAHA), PagerDuty, Opsgenie, Grafana OnCall, NTFY, Gotify, Pushover, SendGrid, Twilio, LINE, PagerTree, Pushbullet.

## Status pages

Create public status pages (customizable) showing uptime history and current status for selected monitors. Supports SVG status badges for embedding in READMEs and dashboards.

## Terraform provider

Infrastructure-as-code management via the community Terraform provider:
<https://registry.terraform.io/providers/tafaust/peekaping>

```hcl
resource "peekaping_monitor" "my_site" {
  name     = "My Website"
  url      = "https://example.com"
  type     = "http"
  interval = 60
}
```

## API-first

All Peekaping functionality is accessible via REST API — create monitors, manage notifications, query uptime history, manage status pages. Full API documentation at: <https://docs.peekaping.com/api>

## Gotchas

- **⚠️ Beta status.** Peekaping is actively developed but in beta. Features may change between releases. Test before deploying in production. Report bugs — the author actively responds.
- **Bundle vs separate images.** The bundle images (`-bundle-sqlite/postgres/mongo`) are all-in-one — easiest to start with. Separate `peekaping-web` + `peekaping-server` images give more control for multi-replica deployments.
- **ICMP (ping) needs `NET_ADMIN` or root.** Running ICMP ping monitors in Docker requires either running the container as root or adding `NET_ADMIN` capability. Without it, ping monitors fail. Add `cap_add: [NET_ADMIN]` in compose for ping monitors.
- **Docker monitor needs socket access.** The Docker container monitor type requires mounting the Docker socket (`/var/run/docker.sock`) into the Peekaping container.
- **Push monitors for heartbeats.** For monitoring cron jobs or background processes, use Push monitors — your process calls the Peekaping Push URL on success; if Peekaping doesn't hear from it on schedule, it alerts.
- **Status page is public.** Status pages have a public URL by default. Don't include sensitive internal URLs as monitor names if the status page is publicly shared.

## Backup

```sh
# SQLite
docker stop peekaping
sudo tar czf peekaping-$(date +%F).tgz .data/sqlite/
docker start peekaping

# PostgreSQL
docker compose exec postgres pg_dump -U peekaping peekaping > peekaping-$(date +%F).sql
```

## Upgrade

```sh
docker compose pull && docker compose up -d
```

## Project health

Active Go + React development, Docker Hub (3 DB variants), Terraform provider, 17 monitor types, 20+ alert channels, status pages, SVG badges, MFA. MIT license. ⚠️ Beta.

## Uptime-monitoring-family comparison

- **Peekaping** — Go, API-first, Terraform provider, 17 monitor types, 20+ channels, SQLite+PG+Mongo, MIT, beta
- **Uptime Kuma** — Node.js, very popular, web UI, 90+ alert channels; no Terraform; most mature
- **Gatus** — Go, config-as-code (YAML), no web UI for management; different philosophy
- **Statping-NG** — Go, simple status page focus; less actively developed
- **Healthchecks** — Python/Django, cron-job heartbeat monitoring focus

**Choose Peekaping if:** you want a modern, API-first uptime monitor with Terraform provider support, broad protocol coverage (gRPC, SNMP, databases, message brokers), and 20+ notification channels — and accept beta status.

## Links

- Repo: <https://github.com/0xfurai/peekaping>
- Docs: <https://docs.peekaping.com>
- Demo: <https://demo.peekaping.com>
- Terraform provider: <https://registry.terraform.io/providers/tafaust/peekaping>
