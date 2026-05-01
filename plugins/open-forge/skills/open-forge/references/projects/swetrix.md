---
name: Swetrix
description: "Self-hosted open source, cookieless web analytics platform. Docker. Nest.js + MySQL + ClickHouse + Redis. Swetrix/swetrix. Privacy-first, GDPR-compliant, real-time traffic, sessions, funnels, performance monitoring, error tracking, feature flags. AGPL-3.0."
---

# Swetrix

**Self-hosted open source, cookieless web analytics.** Privacy-first alternative to Google Analytics. No cookies, no cross-device tracking, all data anonymised. Real-time dashboards, session analytics, user flows, funnels, performance monitoring (TTFB/DNS/TLS/render), error tracking, feature flags. Embed a tiny tracking script on your site and monitor everything from one clean dashboard.

Built + maintained by **Swetrix** (UK). Also available as a managed EU cloud service. AGPL-3.0.

- Upstream repo: <https://github.com/Swetrix/swetrix>
- Website: <https://swetrix.com>
- Self-hosting guide: <https://docs.swetrix.com/selfhosting/how-to>
- Docs: <https://docs.swetrix.com>

## Architecture in one minute

- **Nest.js** API backend (TypeScript)
- **MySQL** (TypeORM) — accounts, projects, settings
- **ClickHouse** — analytics event storage (high-volume time-series)
- **Redis** — caching
- Web/UI frontend (Next.js)
- Small JavaScript tracking script embedded in your site (no cookies)
- Port **3000** (UI), **5005** (API)
- Resource: **medium-high** — ClickHouse needs 2+ GB RAM; MySQL + Redis additional overhead

## Compatible install methods

| Infra      | Runtime    | Notes                                                |
| ---------- | ---------- | ---------------------------------------------------- |
| **Docker** | Compose    | **Primary** — see self-hosting guide for compose     |

Full self-hosting guide: <https://docs.swetrix.com/selfhosting/how-to>

## Install

Follow the [official self-hosting guide](https://docs.swetrix.com/selfhosting/how-to) for the full Docker Compose setup. The stack requires:

- Swetrix API container (`ghcr.io/swetrix/swetrix` or similar — check latest release)
- Swetrix UI container
- MySQL or compatible container
- ClickHouse container
- Redis container

## Cloud vs Community Edition

| Feature | Cloud ($19/mo+) | Community Edition (self-hosted) |
|---------|-----------------|--------------------------------|
| Core analytics (traffic, events, sessions, funnels, performance, errors) | ✅ | ✅ |
| Revenue analytics, Experiments (A/B), AI chat | ✅ | ❌ |
| Alerts (Email/Slack/Telegram/Discord/webhook/web push) | ✅ | ❌ |
| Email reports | ✅ | ❌ |
| Premium GeoIP (region/city/ISP/org) | ✅ | ⚠️ DB-IP Lite (country/region/city only) |
| Teams & organisations | ✅ | ⚠️ Project invites + public/password links only |
| Managed infrastructure | ✅ | ❌ (you manage) |

## Features overview (Community Edition)

| Feature | Details |
|---------|---------|
| Cookieless tracking | No cookies; no GDPR consent banner needed |
| GDPR-compliant | Data anonymised; no cross-device tracking |
| Real-time dashboard | Live visitor counts; real-time event stream |
| Page views & traffic | Top pages, referrers, UTM campaigns |
| Geolocation | Country, region, city (DB-IP Lite; upgrade for paid GeoIP) |
| Devices | Browser, OS, device type breakdowns |
| Custom events | Track conversions, button clicks, key actions with custom properties |
| Session analytics | Replay user journeys across your site |
| User flows | Visualise navigation paths and drop-off points |
| Funnels | Conversion funnel visualisation; identify drop-off steps |
| Performance monitoring | Real-user metrics: TTFB, DNS, TLS, render time |
| Error tracking | Capture client-side JS errors with details and aggregated views |
| Feature flags | Manage feature rollouts; safe phased releases |
| Goals | Track specific conversion goals |
| DAU/MAU | Daily and monthly active user tracking |
| Data export | CSV export; developer API access |
| Public dashboards | Share public or password-protected dashboards |
| Project invites | Invite teammates to specific projects |
| Lightweight script | Small JS snippet; no performance impact |
| Self-hostable | Full control of your data |

## Inputs to collect

| Input | Notes |
|-------|-------|
| MySQL credentials | Database for accounts, projects, settings |
| ClickHouse credentials | Analytics event database |
| Redis URL | Caching |
| `JWT_ACCESS_TOKEN_SECRET` | Random string for JWT auth tokens |
| `JWT_REFRESH_TOKEN_SECRET` | Random string for JWT refresh tokens |
| `EMAIL_*` | SMTP settings (optional — for password reset emails) |
| `REDIS_*` | Redis connection details |

## Embedding the tracking script

```html
<!-- Add to your site's <head> -->
<script src="https://your-swetrix-instance.com/api/v1/swetrix.js" defer></script>
<script>
  document.addEventListener('DOMContentLoaded', function() {
    swetrix.init('YOUR_PROJECT_ID')
    swetrix.trackViews()
  })
</script>
```

## Gotchas

- **ClickHouse is heavyweight.** ClickHouse requires at least 2 GB RAM and is resource-hungry compared to the rest of the stack. This is the right tool for high-volume analytics data — but plan hardware accordingly.
- **AGPL-3.0 license.** Network-service usage of modified Swetrix requires publishing changes under AGPL-3.0.
- **GeoIP precision.** The Community Edition uses the free DB-IP City Lite database (country/region/city only). ISP, organisation, usage type, and network intelligence breakdowns require a paid MaxMind or DB-IP database.
- **Cloud-only features.** Revenue analytics, A/B experiments, AI chat, email reports, and alerting are Cloud-only. They are not available in the self-hosted Community Edition.
- **Script must be served from your instance.** The tracking script is served from your Swetrix instance — embed the URL pointing to your self-hosted instance, not `swetrix.com`.

## Backup

```sh
# MySQL
docker compose exec mysql mysqldump -u swetrix -p swetrix > swetrix-mysql-$(date +%F).sql
# ClickHouse
docker compose exec clickhouse clickhouse-client --query "BACKUP DATABASE swetrix TO Disk('backups', 'swetrix-$(date +%F)')"
```

## Upgrade

```sh
docker compose pull && docker compose up -d
```

## Project health

Active Nest.js/ClickHouse development, Cloud + Community Edition, AGPL-3.0.

## Analytics-family comparison

- **Swetrix** — Nest.js, ClickHouse, cookieless, sessions, funnels, performance, error tracking, feature flags, AGPL-3.0
- **Plausible** — Elixir/ClickHouse, cookieless, simpler; less feature-rich CE; AGPL-3.0
- **Matomo** — PHP/MySQL, cookie-based, GDPR tools, comprehensive; older stack; GPL-3.0
- **Umami** — Next.js/PostgreSQL, simple cookieless; no funnels or performance monitoring; MIT
- **PostHog** — Python/ClickHouse, product analytics, feature flags, sessions; broader scope; MIT

**Choose Swetrix if:** you want a self-hosted, cookieless, GDPR-compliant analytics platform with real-time dashboards, sessions, funnels, performance monitoring, error tracking, and feature flags — without needing the full complexity of PostHog.

## Links

- Repo: <https://github.com/Swetrix/swetrix>
- Docs: <https://docs.swetrix.com>
- Self-hosting guide: <https://docs.swetrix.com/selfhosting/how-to>
