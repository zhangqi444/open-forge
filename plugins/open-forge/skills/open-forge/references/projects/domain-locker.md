---
name: Domain Locker
description: "Self-hosted domain monitoring and management platform. Docker + PostgreSQL. TypeScript/Angular + Node.js. Lissy93/domain-locker. Expiry alerts, WHOIS, SSL, uptime, DNS history, subdomains, tags, Apprise notifications."
---

# Domain Locker

**Domain portfolio monitoring and management platform.** Track all your domains in one place: expiry dates and alerts, WHOIS data, SSL certificate monitoring, uptime/performance metrics, DNS record history, subdomain discovery, cost tracking, tags, notes, and 100+ notification channels (Apprise). Web dashboard, REST API, and a CLI utility. Self-host or use the managed cloud at domain-locker.com.

Built + maintained by **Alicia Sykes (Lissy93)** and contributors. MIT license.

- Upstream repo: <https://github.com/Lissy93/domain-locker>
- Website + docs: <https://domain-locker.com>
- Self-hosting guide: <https://domain-locker.com/about/self-hosting>
- Docker Hub: <https://hub.docker.com/r/lissy93/domain-locker>
- 1-click install: `curl -fsSL https://install.domain-locker.com | bash`
- Umbrel, Proxmox, EasyPanel, Unraid, Portainer templates available

## Architecture in one minute

- **TypeScript / Angular** frontend + **Node.js** backend
- **PostgreSQL 15** database
- Docker Compose: `app` + `postgres` containers
- Port **3000** (app)
- Cron endpoints to call periodically (via external cron or the built-in scheduler):
  - `/api/domain-updater` — daily: refresh WHOIS/SSL/DNS data + trigger notifications
  - `/api/domain-monitor` — every 15 min: uptime + performance check
  - `/api/cleanup-monitor-data` — weekly: aggregate old monitoring data
- Resource: **low-to-medium** — Node.js + PostgreSQL

## Compatible install methods

| Infra              | Runtime                        | Notes                                                               |
| ------------------ | ------------------------------ | ------------------------------------------------------------------- |
| **1-click bash**   | `curl … \| bash`               | **Easiest** — prompts for config, sets up Docker Compose            |
| **Docker Compose** | `lissy93/domain-locker`        | Manual setup; see self-hosting docs                                 |
| **Umbrel**         | Umbrel App Store               | 1-click install on Umbrel                                           |
| **Proxmox VE**     | Community script               | <https://community-scripts.github.io/ProxmoxVE/scripts?id=domain-locker> |
| **Unraid**         | Community App                  | Available in Unraid CA                                              |
| **EasyPanel**      | Template                       | Available as EasyPanel template                                     |
| **Hosted**         | domain-locker.com              | Free starter plan; no setup                                         |

## Install via 1-click script

```bash
curl -fsSL https://install.domain-locker.com | bash
```

Prompts for your domain, admin email, and other config; sets up Docker Compose automatically.

## Install via Docker Compose (manual)

```yaml
services:
  app:
    image: lissy93/domain-locker:latest
    ports:
      - "3000:3000"
    environment:
      - DL_PG_HOST=postgres
      - DL_PG_PORT=5432
      - DL_PG_USER=domainlocker
      - DL_PG_PASSWORD=changeme
      - DL_PG_NAME=domainlocker
    depends_on:
      - postgres
    restart: unless-stopped

  postgres:
    image: postgres:15-alpine
    volumes:
      - postgres_data:/var/lib/postgresql/data
    environment:
      - POSTGRES_USER=domainlocker
      - POSTGRES_PASSWORD=changeme
      - POSTGRES_DB=domainlocker
    restart: unless-stopped

volumes:
  postgres_data:
```

Visit `http://localhost:3000`.

## First boot

1. Deploy containers.
2. Visit the web UI → create admin account.
3. Add your first domain (enter the domain name — WHOIS/SSL/DNS data is fetched automatically).
4. Configure **notification channels** (Settings → Notifications): email, Slack, Discord, Telegram, ntfy, etc. via Apprise.
5. Set **expiry alert thresholds** (e.g. 90/30/7 days before expiry).
6. Configure **cron jobs** to call the three monitoring endpoints:
   ```
   # crontab / external cron / health-check scheduler
   0 8 * * *       curl https://your-domain.com/api/domain-updater
   */15 * * * *    curl https://your-domain.com/api/domain-monitor
   0 8 * * 0       curl https://your-domain.com/api/cleanup-monitor-data
   ```
7. Put behind TLS.

## Monitored data per domain

| Data | Details |
|------|---------|
| WHOIS | Registrar, creation/updated/expiry dates, registrant info |
| Expiry alerts | Configurable days-before-expiry notifications |
| SSL certificate | Issuer, expiry, chain validity; alert on expiry |
| Uptime | HTTP availability + response time (every 15 min) |
| DNS records | A, AAAA, MX, TXT, NS, CNAME history with change tracking |
| Subdomains | Discovery scan for active subdomains |
| Hosting | IP → hosting provider/ASN lookup |
| IP history | Track IP address changes |
| Tags + notes | Custom organization metadata |
| Cost tracking | Record registration/renewal costs |

## Gotchas

- **Cron endpoints are not auto-called.** Domain Locker exposes HTTP cron endpoints but doesn't have a built-in scheduler (in self-hosted mode). You must call them externally — via system cron, a health-check service (Uptime Kuma, Better Stack), or a scheduled task runner. Without `/api/domain-updater` running daily, expiry data won't refresh.
- **PostgreSQL required.** No SQLite option — PostgreSQL is the only supported database. Use PostgreSQL 15.
- **`DL_PG_*` env var prefix.** Not standard `POSTGRES_*` — Domain Locker uses its own prefix. Both sets exist: the app uses `DL_PG_*`; the Postgres container init uses `POSTGRES_*`. Keep them in sync.
- **Free cloud tier at domain-locker.com.** The hosted starter plan is free — good for evaluating features before committing to self-hosting. Self-hosting buys data sovereignty.
- **WHOIS rate limits.** WHOIS queries are throttled by registries. For large portfolios (100+ domains), initial data fetch may take minutes and should be spread out. Don't hammer `/api/domain-updater` repeatedly.
- **SSL check from server perspective.** The SSL monitoring hits your domain from the server running Domain Locker. If your domains are behind Cloudflare proxying, the cert shown will be the Cloudflare edge cert — as expected.
- **Subdomain discovery is active scanning.** The subdomain scan sends DNS queries. It's lightweight but noisy — be aware if scanning domains you don't control.
- **Apprise for 100+ notification channels.** Covers email, Slack, Discord, Telegram, ntfy, Pushover, Gotify, PagerDuty, and many more. Configure the Apprise URL format for your channel.

## Project health

Active TypeScript/Angular development, Docker Hub, 1-click install script, Umbrel + Proxmox + Unraid + EasyPanel templates, docs site, cloud tier. Maintained by Alicia Sykes (also of Dasherr, Web Check, etc.). MIT license.

## Domain-monitoring-family comparison

- **Domain Locker** — TypeScript+Angular+Node, PostgreSQL, WHOIS+SSL+DNS+uptime, Apprise, 100+ channels
- **Netdata Cloud domain monitor** — SaaS; basic domain expiry alerts
- **UptimeRobot** — SaaS, uptime monitoring with SSL/domain expiry; not self-hosted
- **Web Check** (same author, Lissy93) — per-domain deep analysis tool; different scope
- **Whois** — CLI; one-off lookups; no alerting

**Choose Domain Locker if:** you manage a portfolio of domains and want a self-hosted dashboard tracking expiry, SSL, uptime, DNS changes, and subdomains with multi-channel notifications.

## Links

- Repo: <https://github.com/Lissy93/domain-locker>
- Docs: <https://domain-locker.com/about/self-hosting>
- Docker Hub: <https://hub.docker.com/r/lissy93/domain-locker>
- 1-click install: `curl -fsSL https://install.domain-locker.com | bash`
