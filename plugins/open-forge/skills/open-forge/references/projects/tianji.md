---
name: Tianji
description: "All-in-one self-hosted insight hub: website analytics + uptime monitor + server status + telemetry + surveys + lighthouse + utm + webhooks. Node.js + Postgres. Docker-first. License: check repo. Active; msgbyte/moonrailgun; cloud tier available."
---

# Tianji

Tianji is **"Umami + Uptime Kuma + Netdata + PostHog — lite — in one project"** — an all-in-one insight hub that combines website analytics, uptime monitoring, server-status reporting, telemetry collection, surveys, lighthouse reports, utm tracking, and webhooks. One app, one database, one web UI. Built for users who want "lightweight comprehensive monitoring" instead of running three specialized tools.

Built + maintained by **moonrailgun (msgbyte org)** + community. License: check repo. Active; Docker Hub image; hosted-cloud option (tianji.moonrailgun.com) operates on open-core model; Helm chart available.

Use cases: (a) **escape 3-tool stack** (Umami + Uptime Kuma + Netdata/Prometheus) for small teams (b) **OSS developer wanting telemetry** without Amplitude/Mixpanel/PostHog bills (c) **agency/consultant** — give clients one dashboard for their sites (d) **personal SaaS launch** — analytics + uptime + server monitoring for a side project (e) **survey + analytics correlation** — Tianji integrates surveys with traffic data (f) **multi-tenant team collaboration** — built-in team features (g) **lighthouse reporting** for SEO tracking.

Features (from upstream README):

- **Website analytics** (PV/UV/pages — Umami-like)
- **Uptime monitor** with passive reception support
- **Server status** (agent-reported)
- **Problem notifications**
- **Telemetry** collection (for your own OSS projects)
- **OpenAPI**
- **Team collaboration**
- **UTM tracking**
- **Waitlist**
- **Surveys**
- **Lighthouse reports**
- **Hooks / webhooks**
- **Helm install**

- Upstream repo: <https://github.com/msgbyte/tianji>
- Docker Hub: <https://hub.docker.com/r/moonrailgun/tianji>
- Hosted (commercial): <https://tianji.moonrailgun.com>
- Website badge used on project itself (visible in README)

## Architecture in one minute

- **Node.js (likely TypeScript + Prisma)** backend + React frontend
- **PostgreSQL** — DB
- **Resource**: moderate — 500MB-1GB RAM
- **Ports**: web UI (configurable)
- **Reporter agent** (binary) reports server status → Tianji server

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker compose** | **`moonrailgun/tianji` + postgres**                             | **Primary**                                                                        |
| **Helm**           | **Kubernetes chart**                                            | **Supported**                                                                        |
| Hosted SaaS        | tianji.moonrailgun.com                                                                    | Commercial-tier                                                                                   |
| Bare-metal Node    | DIY                                                                                        | DIY                                                                                               |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `tianji.example.com`                                        | URL          | TLS required                                                                                    |
| DB                   | PostgreSQL                                                  | DB           |                                                                                    |
| `JWT_SECRET` / `APP_SECRET` | Auth signing                                          | **CRITICAL** | **IMMUTABLE**                                                                                    |
| Admin creds          | First-boot                                                                           | Bootstrap    | Strong                                                                                    |
| Tracked websites     | Domains to track + tracking snippet                                                                                 | Content      | GDPR-compliance-relevant                                                                                    |
| Server reporter key  | For `tianji-reporter` agent auth                                                                                                      | Agent        | Per-server                                                                                                            |
| Notification channels | Slack / Discord / Email / webhook                                                                                                                                  | Alerting     |                                                                                                                                            |

## Install via Docker

```yaml
services:
  postgres:
    image: postgres:17        # **pin**
    environment:
      POSTGRES_DB: tianji
      POSTGRES_USER: tianji
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes: ["pgdata:/var/lib/postgresql/data"]
    restart: always

  tianji:
    image: moonrailgun/tianji:1.31.25        # **pin version**
    ports: ["12345:12345"]
    restart: always
    environment:
      DATABASE_URL: "postgresql://tianji:${DB_PASSWORD}@postgres:5432/tianji"
      JWT_SECRET: ${JWT_SECRET}
    depends_on: [postgres]

volumes:
  pgdata:
```

## First boot

1. Start → browse `:12345`
2. Register admin
3. Create first website + inject tracking snippet
4. Deploy `tianji-reporter` on servers you want to monitor
5. Configure uptime monitors
6. Set up notification channels
7. Add team members (if multi-user)
8. Create first survey (optional)
9. Put behind TLS reverse proxy
10. Back up DB

## Data & config layout

- Postgres — all analytics events, uptime history, server metrics, telemetry data
- Agent binaries — deployed per-server
- Tracking snippets embedded in your websites

## Backup

```sh
docker compose exec postgres pg_dump -U tianji tianji > tianji-$(date +%F).sql
```

## Upgrade

1. Releases: <https://github.com/msgbyte/tianji/releases>. Active.
2. Docker: pull + restart; migrations auto-run.
3. Helm: upgrade chart.
4. **Back up before breaking releases** (roadmap shows active development).

## Gotchas

- **ANALYTICS TOOL = GDPR-RELEVANT** (network-service-legal-risk):
  - Website analytics collects IP + user-agent + referrer + page-path + potentially cookies
  - Under GDPR: IP is PII → tracking without consent is illegal in EU
  - CNIL (France) mandated specific configuration for analytics-without-consent (IP anonymization, no persistent IDs, no data-export-to-US)
  - **25th tool in network-service-legal-risk family** — "analytics-tool-GDPR-compliance" sub-family — same sub-family as Umami + Plausible + Matomo
  - **Recipe convention: "analytics-GDPR-compliance" sub-family note** — 15th sub-family
  - Tianji's Umami-origin-ancestry: Tianji's analytics-module cites Umami design; verify Tianji implements IP-hash + no-cookie pattern (Umami-style).
- **HUB-OF-CREDENTIALS TIER 2**:
  - Analytics data for all tracked sites
  - Reporter-agent auth keys (for every server reporting to Tianji)
  - Team members + admin creds
  - Notification-channel secrets (Slack/Discord webhooks, SMTP)
  - Uptime monitor secrets (HTTP auth tokens, API keys)
  - Survey responses (may contain PII depending on survey)
  - **55th tool in hub-of-credentials family — Tier 2.**
- **TELEMETRY-FOR-OSS-PROJECTS FEATURE** = interesting design:
  - Tianji lets you embed a telemetry badge/pixel in your OSS project README
  - Tracks who-deployed-your-OSS (country/region-level typically)
  - Dual-edged: useful metric but users of YOUR OSS may resent being tracked by README-pixel
  - **Recipe convention: "OSS-deployment-telemetry-tension"** — deployed OSS users often hostile to maintainer-telemetry (see Home Assistant's analytics opt-out debate)
- **COMMERCIAL-TIER-TAXONOMY**: Tianji has both self-host (free) + hosted cloud tier (paid):
  - **open-core-with-fully-functional-OSS** — all features in OSS; cloud sells the convenience
  - **2nd+ tool in that sub-tier** (many examples exist: Umami, Plausible, Cal.com, Ghost, Chatwoot, etc.)
- **UMAMI-COMPARISON**: Tianji is more-ambitious (adds uptime + server-status + survey); Umami is more-focused (analytics only). For pure-analytics, Umami is cleaner + more-mature. For all-in-one, Tianji is the bet.
- **UPTIME-KUMA-COMPARISON**: Tianji is younger; Uptime Kuma is mature + has stronger community around uptime-specifically. Same trade-off: breadth vs depth.
- **NETDATA/PROMETHEUS-COMPARISON**: Tianji's server-status is lightweight; Prometheus is industrial-strength. Different use cases.
- **"REPORTER BINARY" = AGENT ON YOUR SERVERS**:
  - Signed-binary download from Tianji server
  - Runs on your servers; reports metrics back to Tianji
  - **Trust-chain**: Tianji server compromise → attacker controls all reporter-agents → access to every server?
  - **Verify**: reporter agent privileges (least-privilege design?) + auth mechanism (secret vs mTLS) + network path (outbound-only?)
- **JWT_SECRET IMMUTABILITY**: **38th tool in immutability-of-secrets family.**
- **"ALL-IN-ONE" vs "BEST-IN-CLASS" trade-off**:
  - All-in-one = one-stop-convenience + one-vendor-risk
  - Best-in-class stack = more-surface-area + more-operational-burden
  - For smallish deployments (<50 sites, <10 servers), Tianji's all-in-one wins
  - At scale, best-in-class tools win
- **LICENSE CHECK**: verify LICENSE (LICENSE-file-verification-required convention).
- **TRANSPARENT-MAINTENANCE**: active + CI + Docker metrics + changelog + roadmap + public-telemetry-showing-own-deployment-count + hosted-service. **47th tool in transparent-maintenance family.**
- **INSTITUTIONAL-STEWARDSHIP**: moonrailgun / msgbyte + community + hosted-service funding. **40th tool in institutional-stewardship — founder-with-commercial-tier-funded-development sub-tier.**
- **MILESTONE**: institutional-stewardship now 40 tools (40-tool milestone).
- **CONSUMPTION-OF-OWN-PRODUCT (DOGFOODING)**: Tianji's README embeds a Tianji-hosted tracking badge showing live visitor count. Signals confidence + dogfooding. Positive signal.
- **CATEGORY-OVERLAP RECIPE NOTE**: Tianji overlaps with Umami (batch prior) + Uptime Kuma (batch prior) + Gatus + Statping + Netdata + Prometheus-stack + Grafana. Users should audit overlap before adopting.
- **ALTERNATIVES WORTH KNOWING:**
  - **Umami** — analytics-only; cleaner; mature
  - **Plausible** — analytics-only; open-source-with-paid-SaaS
  - **Matomo** (formerly Piwik) — heavyweight analytics
  - **Uptime Kuma** — uptime-only; mature; no analytics
  - **Gatus** — uptime-only; YAML-config
  - **Statping** — uptime-only; mature
  - **Netdata** — server monitoring; real-time; lightweight
  - **Prometheus+Grafana+Alertmanager** — heavyweight all-purpose observability
  - **PostHog** — product analytics; feature flags; heavier
  - **Choose Tianji if:** you want all-in-one + small-scale + save operational burden.
  - **Choose Umami + Uptime Kuma + Netdata if:** you want best-in-class + willing to run 3 stacks.
  - **Choose Prometheus+Grafana if:** you want industrial-grade.
- **PROJECT HEALTH**: active + CI + Docker + cloud-tier + helm + multi-feature roadmap complete. Strong signals.

## Links

- Repo: <https://github.com/msgbyte/tianji>
- Docker: <https://hub.docker.com/r/moonrailgun/tianji>
- Hosted: <https://tianji.moonrailgun.com>
- Umami (alt analytics-only): <https://umami.is>
- Plausible (alt analytics-only): <https://plausible.io>
- Uptime Kuma (alt uptime-only): <https://github.com/louislam/uptime-kuma>
- Gatus (alt uptime): <https://gatus.io>
- Netdata (alt server-monitor): <https://www.netdata.cloud>
- Prometheus: <https://prometheus.io>
- PostHog (alt product-analytics): <https://posthog.com>
- Matomo (alt analytics): <https://matomo.org>
- CNIL analytics guidance: <https://www.cnil.fr/en/cnil-publishes-guidelines-use-audience-measurement-tools>
