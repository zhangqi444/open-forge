---
name: Kener
description: "Self-hosted status page system — SvelteKit + Node.js + Redis. Public status pages, incident management, multi-check monitoring (API/Ping/TCP/DNS/SSL/SQL/GameDig), notifications (email/webhook/Slack/Discord), branded themes. Lightweight alternative to Statuspage/Instatus. GPL-3.0."
---

# Kener

Kener (from Assamese _"Kene?"_ = "how's it going?") is **a sleek self-hosted status page system** — modern SvelteKit + Node.js UI, Redis for state, built-in multi-protocol monitoring (HTTP/API, Ping, TCP, DNS, SSL expiry, SQL, heartbeat, GameDig). Incidents, maintenance windows, timelines, public branded status pages, email/webhook/Slack/Discord notifications, embeddable widgets + badges.

Developed by **Rajnandan Kumar (rajnandan1)**. Mature + growing (5000★). Commercial-free and GPL-licensed.

Positioning: not trying to replace Datadog/PagerDuty/Statuspage-by-Atlassian. Designed to give you **"a great-looking status page with minimal effort"**.

Features:

- **Check types**: HTTP/API, Ping (ICMP), TCP, DNS, SSL-cert expiry, SQL query, heartbeat (push), GameDig (game-server)
- **Public status pages** — branded (logo, colors, custom CSS, themes)
- **Light/dark mode + i18n + timezone-aware**
- **Incidents** — with updates, acknowledgements, timelines, postmortems
- **Maintenance windows** — scheduled + user-informed
- **Notifications**: Email, Webhook, Slack, Discord
- **Embeddable widgets + badges**
- **Historical uptime data**
- **SEO-friendly** public pages
- **Subpath deployments** (`/status` path option via dedicated image)
- **Deploy buttons**: Railway, Zeabur, Render
- **Docker + non-Docker install paths**

- Upstream repo: <https://github.com/rajnandan1/kener>
- Homepage + live demo: <https://kener.ing>
- Quick-start docs: <https://kener.ing/docs/v4/getting-started/quick-start>
- Docs: <https://kener.ing/docs/v4/getting-started/introduction>
- Docker Hub: <https://hub.docker.com/r/rajnandan1/kener>
- GHCR: `ghcr.io/rajnandan1/kener`
- DeepWiki: <https://deepwiki.com/rajnandan1/kener>

## Architecture in one minute

- **SvelteKit + Node.js 20+** — server + UI
- **Redis** — check results cache + queue (MANDATORY per current docs)
- **SQLite** (typical) in `/app/database/` — config + incidents + history
- **Resource**: small — 200-300 MB RAM + Redis
- **Two image flavors**: root path (`latest`) + subpath (`latest-status`)
- **Alpine variants** available for smaller footprint

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Single VM / NAS    | **Docker Compose (Kener + Redis)**                                 | **Upstream-recommended**                                                           |
| Kubernetes         | Works — deploy as pod + Redis                                              | Community manifests exist                                                                  |
| One-click PaaS     | **Railway / Zeabur / Render** deploy buttons                                          | Fast trial path                                                                                        |
| Bare Node.js       | Node 20+ + Redis + clone + `npm run build && start`                                                   | For custom envs                                                                                                    |
| Raspberry Pi       | arm64 images                                                                                       | Works                                                                                                                    |

## Inputs to collect

| Input                  | Example                                            | Phase        | Notes                                                                    |
| ---------------------- | -------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain                 | `status.example.com`                                    | URL          | Public-facing; TLS required                                                      |
| `ORIGIN`               | `https://status.example.com`                                     | Env          | Full public URL; used in cookies + links                                                 |
| `KENER_SECRET_KEY`     | 32+ random chars                                                | Crypto       | Session + signing                                                                        |
| `REDIS_URL`            | `redis://redis:6379`                                                   | Cache        | Required                                                                                 |
| `KENER_BASE_PATH`      | `/status` (only for subpath image)                                       | URL          | Optional                                                                                                |
| Admin                  | Initial superadmin — via first-run                                                  | Bootstrap    | Strong password                                                                                                         |
| Notification channels  | SMTP / Slack webhook / Discord webhook / generic webhook                                       | Alerts       | Post-install                                                                                                                            |

## Install via Docker Compose (typical)

```yaml
services:
  kener:
    image: docker.io/rajnandan1/kener:latest               # pin a specific version in prod
    container_name: kener
    restart: unless-stopped
    ports:
      - "3000:3000"
    environment:
      KENER_SECRET_KEY: "GENERATE_RANDOM_32_PLUS_CHARS"
      ORIGIN: "https://status.example.com"
      REDIS_URL: "redis://redis:6379"
    volumes:
      - ./database:/app/database
    depends_on:
      - redis

  redis:
    image: redis:7-alpine
    restart: unless-stopped
    volumes:
      - ./redis-data:/data
```

For subpath `/status`: use `:latest-status` image + set `KENER_BASE_PATH=/status`, keep `ORIGIN` as the origin only (NOT `/status` suffix).

## First boot

1. Browse `https://status.example.com/` → first-run admin creation
2. Add first monitor: HTTP check on a known URL → verify status updates within the check interval
3. Customize branding: logo, colors, site title
4. Add notification channel: webhook or SMTP → test alert
5. Create a test incident → verify timeline + notifications
6. Schedule maintenance window → verify display on public page
7. Configure subscribers if you want users to opt-in for notifications
8. Front with TLS reverse proxy

## Data & config layout

- `/app/database/` — SQLite DB + state
- Redis — transient check queue + results cache (recover on restart from DB)
- Logos + custom CSS uploaded via UI

## Backup

```sh
sudo tar czf kener-$(date +%F).tgz database/
```

DB is small; frequent backups cheap. Redis data is ephemeral (don't back up).

## Upgrade

1. Releases: <https://github.com/rajnandan1/kener/releases>. Active. v4 is current track per docs URL.
2. Docker: bump tag → restart → migrations auto.
3. Major version jumps: back up DB; read release notes.
4. Subpath mode: stay on `-status` variant matching your needs.

## Gotchas

- **Set `KENER_SECRET_KEY` + `ORIGIN` BEFORE first run** (per upstream IMPORTANT callout). Changing `KENER_SECRET_KEY` later invalidates all sessions + signed URLs.
- **Redis is required** — no opt-out. Plan Redis persistence strategy (AOF vs RDB) or accept that it's cache-only (Kener recovers from SQLite DB).
- **Subpath deployment nuance**: use `-status` image variant + set `KENER_BASE_PATH=/status` + keep `ORIGIN` as origin-only (NOT with `/status`). Upstream has an explicit note about this — easy mistake.
- **Status page is public by design.** Anyone with URL sees current status. Don't accidentally leak internal service names. Curate what goes on public page vs private dashboards.
- **Monitoring discipline**: it's easy to add 100 checks; harder to maintain them + make alerting signal > noise. Start with critical services only; expand.
- **SSL expiry checks**: genuinely useful — Kener checks cert expiry, alerts before cert rolls. Keep them enabled on any HTTPS service you own.
- **SQL check**: runs arbitrary SELECTs against a DB. Use read-only role. Don't run on production DB from a status page (load + security).
- **GameDig**: game-server protocol check (Minecraft, Source engine, etc.) — niche but well-loved by homelab gaming communities.
- **Heartbeat checks** (push-based): your service calls Kener URL periodically; miss = alert. Great for cron jobs, backups, data pipelines.
- **Notification deliverability**: SMTP must work reliably — status alerts are exactly when you don't want bounced email. Use Postmark/SendGrid/SES with SPF+DKIM+DMARC.
- **Webhook security**: webhooks are one-way by default; Kener doesn't verify signature unless you script it. Rotate webhook URLs + don't share them.
- **Subscribers opt-in**: per-user notification subscriptions. Good for customer-facing status pages. Manage unsubscribe + GDPR.
- **Kubernetes deployment**: possible but not first-party-templated. Community manifests exist.
- **License**: **GPL-3.0** (verify in LICENSE).
- **Commercial vs OSS**: Kener is fully OSS; no paid tier (as of 2026). Author accepts donations + has optional support.
- **Bus factor**: solo project by rajnandan1; very active commits. Mature codebase. Risk mitigated by GPL + fork-ability.
- **Alternatives worth knowing:**
  - **Uptime Kuma** — the homelab favorite; more monitors + notifications, less "status page"-polished
  - **Statping-ng** — Go; status-page focused; less active
  - **Gatus** — YAML-config; minimal UI; great for GitOps
  - **Checkmate** — newer; nice UI
  - **Cachet** — PHP; older; widely-used
  - **Instatus / Statuspage (Atlassian) / Better Uptime** — commercial SaaS
  - **Choose Kener if:** modern UI + branded status pages + rich check types + self-host.
  - **Choose Uptime Kuma if:** pure monitoring-first + simpler.
  - **Choose Gatus if:** GitOps / YAML-config preferred.
  - **Choose Cachet if:** PHP-LAMP stack preferred.

## Links

- Repo: <https://github.com/rajnandan1/kener>
- Homepage: <https://kener.ing>
- Quick-start: <https://kener.ing/docs/v4/getting-started/quick-start>
- Docs: <https://kener.ing/docs/v4/getting-started/introduction>
- Docker Hub: <https://hub.docker.com/r/rajnandan1/kener>
- Releases: <https://github.com/rajnandan1/kener/releases>
- DeepWiki: <https://deepwiki.com/rajnandan1/kener>
- Uptime Kuma (alt): <https://github.com/louislam/uptime-kuma>
- Gatus (alt): <https://github.com/TwiN/gatus>
- Statping-ng (alt): <https://github.com/statping-ng/statping-ng>
- Cachet (alt): <https://cachethq.io>
