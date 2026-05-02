# Kuvasz

**What it is:** Open-source self-hosted uptime and SSL monitoring service [ˈkuvɒs]. Monitors HTTP(S) endpoints and SSL certificates with 5-second intervals, unlimited monitors, status pages, multiple notification channels (email, Discord, Slack, Telegram, PagerDuty), Prometheus/OpenTelemetry metrics, REST API, YAML-based infrastructure-as-code config, and heartbeat (push) monitoring.

**Official site:** https://kuvasz-uptime.dev  
**Demo:** https://demo.kuvasz-uptime.dev (user: `demo` / pass: `secureDemoPassword`)  
**Docs:** https://kuvasz-uptime.dev/setup/installation/  
**GitHub:** https://github.com/kuvasz-uptime/kuvasz  
**Docker Hub:** `kuvaszmonitoring/kuvasz`

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS/VM | Docker Compose | App + PostgreSQL; recommended |

---

## Stack Components

| Container | Role |
|-----------|------|
| `kuvasz` | Main app (Kotlin/Micronaut) |
| `kuvaszdb` | PostgreSQL database |

---

## Inputs to Collect

### Phase: Deploy

| Variable | Description |
|----------|-------------|
| `POSTGRES_USER` | PostgreSQL username (e.g. `kuvasz`) |
| `POSTGRES_PASSWORD` | PostgreSQL password — **change from default** |
| `DATABASE_HOST` | DB hostname (Docker service name, e.g. `kuvaszdb`) |
| `DATABASE_USER` | App DB user — must match `POSTGRES_USER` |
| `DATABASE_PASSWORD` | App DB password — must match `POSTGRES_PASSWORD` |

### Phase: Optional (YAML config file `kuvasz.yml`)

- Monitor definitions (HTTP checks, SSL checks, heartbeat monitors)
- Notification channels (Discord webhook URL, Slack token, Telegram bot, etc.)
- Data retention settings
- Status page configuration

---

## Software-Layer Concerns

- **PostgreSQL required** — no SQLite option; must run a Postgres container or provide an external DB
- **YAML IaC support** — monitors and config can be defined in `kuvasz.yml` for infrastructure-as-code workflows
- **5-second minimum monitoring interval** — much faster than free UptimeRobot (5 minutes)
- **Unlimited monitors** — no hard cap
- **Prometheus + OpenTelemetry** exporters built-in for integration with existing observability stacks
- **Status pages** — create public or private status pages per monitor group

### Notification channels supported

Email, Discord, Slack, Telegram, PagerDuty ✅  
MS Teams, Webhook, SMS/Voice — planned 📆

---

## Upgrade Procedure

1. Pull new images: `docker compose pull`
2. Restart: `docker compose up -d`
3. Migrations run automatically on startup

---

## Gotchas

- **Change default DB password** before first run — `YourSuperSecretDbPassword` in examples is not secure
- PostgreSQL data volume must be persisted — all monitor history lives in Postgres
- Location-specific monitoring requires deploying multiple Kuvasz instances (not built-in multi-region)
- Port, DNS, and domain expiration monitoring are not yet supported (roadmap items)

---

## Links

- Website: https://kuvasz-uptime.dev
- Docs / Installation: https://kuvasz-uptime.dev/setup/installation/
- Demo: https://demo.kuvasz-uptime.dev
- GitHub: https://github.com/kuvasz-uptime/kuvasz
- Docker Hub: https://hub.docker.com/r/kuvaszmonitoring/kuvasz
