---
name: OneUptime
description: "All-in-one open-source observability platform — uptime monitoring, status pages, incident management, on-call/alerts, logs, APM, error tracking, AI copilot. Heavy container stack (~30 services). Apache-2.0 (self-hosted) + commercial cloud."
---

# OneUptime

OneUptime is **an all-in-one SRE / observability platform** aiming to replace a stack of tools with one:

- Pingdom / UptimeRobot → **Uptime Monitoring**
- StatusPage.io / Atlassian Statuspage → **Status Pages**
- PagerDuty / Opsgenie → **On-Call + Alerts**
- Incident.io / FireHydrant → **Incident Management**
- Loggly / Papertrail → **Logs Management**
- New Relic / Datadog → **APM + tracing + metrics**
- Sentry → **Error Tracking**
- GitHub Copilot SRE → **AI Copilot** (anomaly detection + auto-fix PRs)

Available as SaaS (commercial tiers at oneuptime.com) or **self-hosted** via Docker Compose / Helm chart.

Features in detail:

- **Uptime monitoring** — HTTP/TCP/UDP/DNS/Ping/browser/API/SSL cert/port, multi-region probes
- **Status pages** — custom domain, subscribers (email/SMS/Slack), private/public
- **Incident management** — severity, RCA, post-mortems, timelines, manual/auto-declared
- **On-call scheduling** — rotations, escalation policies, overrides
- **Alerts** — email, SMS (via Twilio), push, voice call, Slack, MS Teams, webhooks
- **Logs Management** — ship logs via OpenTelemetry
- **APM / tracing** — OpenTelemetry-based
- **Error tracking** — SDKs for common languages
- **Workflows** — 5000+ third-party integrations (Zapier-esque)
- **Dashboards** — custom
- **Multi-project / multi-team**
- **RBAC** — granular permissions
- **SSO** — SAML, OAuth, SCIM
- **Reliability copilot** — AI that watches logs + traces + metrics + opens PRs with fixes

- Upstream repo: <https://github.com/OneUptime/oneuptime>
- Website: <https://oneuptime.com>
- Docs: <https://oneuptime.com/docs>
- Pricing: <https://oneuptime.com/pricing>
- Slack: <https://join.slack.com/t/oneuptimesupport/shared_invite/zt-2pz5p1uhe-Fpmc7bv5ZE5xRMe7qJnwmA>
- Helm chart: <https://artifacthub.io/packages/helm/oneuptime/oneuptime>

## Architecture in one minute

**OneUptime is not small.** It's a microservice stack with ~20-30 containers:

- **Frontend**: Dashboard, AdminDashboard, AccountsUI, StatusPage (SvelteKit/Next.js-ish)
- **API servers**: Accounts, App/API, Realtime, Workers, Notifications, Probe-API
- **Probes**: Multi-region uptime probes (run separately in each region)
- **Data layer**: **Postgres** (primary), **Redis** (queue, cache), **ClickHouse** (metrics + logs + traces), **MongoDB** (legacy), **Haraka** (outbound SMTP MTA)
- **Workers**: scheduled tasks, notifications, probe dispatchers
- **Copilot**: AI worker (optional, needs LLM API key)
- **Ingest**: OpenTelemetry collector for logs/metrics/traces from your apps
- **Single-node footprint**: budget ~**8-16 GB RAM minimum**, 4+ cores, 100+ GB disk

## Compatible install methods

| Infra          | Runtime                                                  | Notes                                                                          |
| -------------- | -------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Single VM      | **Docker Compose** (upstream repo `docker-compose.yml`)      | **Simplest self-host; sizable VM needed (8-16 GB RAM)**                                |
| Kubernetes     | **Official Helm chart** (`oneuptime/oneuptime`)                      | For production scale                                                                           |
| Managed        | **oneuptime.com** SaaS                                                    | Free tier + paid plans                                                                                  |
| Single VM small | Not recommended (OOM)                                                          |                                                                                                                 |
| Raspberry Pi   | Not supported — too heavy                                                             |                                                                                                                        |

## Inputs to collect

| Input                    | Example                             | Phase      | Notes                                                                          |
| ------------------------ | ----------------------------------- | ---------- | ------------------------------------------------------------------------------ |
| Domain(s)                | `oneuptime.example.com`, `status.example.com` | URL        | Multiple subdomains (dashboard, api, status, probe)                                      |
| DB credentials           | Postgres + ClickHouse + Redis + MongoDB            | DB         | Several DBs; use the bundled ones or external                                                     |
| Admin account            | created on first visit                                     | Bootstrap  | Change immediately                                                                                       |
| SMTP                     | host/port/user/pass                                            | Email      | Required for invites + alerts                                                                                             |
| Twilio (opt)             | Account SID, auth token, from number                                     | SMS/Voice  | For SMS + voice alerts                                                                                                                |
| LLM API key (opt)        | OpenAI / Anthropic / etc.                                                       | Copilot    | For AI copilot feature                                                                                                                           |
| Probes                   | Deploy Probe container in 1+ regions                                                    | Ops        | Probes must run where they monitor from                                                                                                                   |
| TLS                      | Let's Encrypt (supported via env)                                                               | Security   | Or external reverse proxy                                                                                                                                   |

## Install via Docker Compose

```sh
git clone https://github.com/OneUptime/oneuptime.git
cd oneuptime
cp config.example.env config.env
# Edit config.env extensively — ~50+ required vars
npm install              # or follow upstream steps
docker compose -f docker-compose.yml up -d
```

Full setup is more involved than most apps on this list — read upstream "self-hosted install" docs carefully. Expect a solid afternoon for a first deploy.

## Install via Helm (Kubernetes)

```sh
helm repo add oneuptime https://helm.oneuptime.com
helm upgrade --install oneuptime oneuptime/oneuptime \
  --namespace oneuptime --create-namespace \
  -f values.yaml
```

Authoring `values.yaml` is non-trivial — ~hundreds of options. Start from the example.

## First boot

1. Browse `https://oneuptime.example.com` → create root user (first registration = admin)
2. Create a Project → this is your tenancy namespace
3. Add a Monitor → test with a known-up URL
4. Add Status Page → attach monitors → publish
5. Create on-call schedule + escalation policy
6. Integrate: install OpenTelemetry SDK in your apps → ship logs/traces/metrics
7. Deploy probes in regions you want to monitor from

## Data & config layout

- `config.env` — top-level secrets + feature flags
- Postgres volume — relational data (users, projects, monitors, incidents)
- ClickHouse volume — observability data (logs, metrics, traces) — grows fast
- Redis volume — queue + cache
- MongoDB volume — legacy data store
- Haraka queue — outbound SMTP

## Backup

```sh
# Postgres
docker exec postgres pg_dumpall -U oneuptime | gzip > ou-pg-$(date +%F).sql.gz
# ClickHouse (metrics data — can be huge)
docker exec clickhouse clickhouse-client --query "BACKUP DATABASE oneuptime TO Disk('backups', 'ou-$(date +%F).zip')"
# Redis snapshot
docker exec redis redis-cli BGSAVE
# Config
cp config.env ou-config-$(date +%F).bak
```

ClickHouse data grows rapidly with high-volume logs/traces — set retention policies (Settings → Data Retention per project).

## Upgrade

1. Releases: <https://github.com/OneUptime/oneuptime/releases>. Frequent — **daily or near-daily** tagged releases.
2. **Back up EVERYTHING first.** This stack has many moving parts.
3. `git pull && docker compose pull && docker compose up -d` — migrations run automatically.
4. Read release notes — breaking env var changes happen.
5. For Helm: `helm repo update && helm upgrade`.

## Gotchas

- **Stack size** — not a one-VM-friendly tool. Budget 8-16 GB RAM minimum for a single-tenant small instance; 32+ GB for a real production workload with logs + APM at volume.
- **Release cadence** — very fast (often daily). Self-hosted upgrades carry some risk; test in staging or pin tags for stability. The upstream focus is largely on their SaaS; self-hosted gets updates but occasionally lags fixes.
- **Config complexity** — 50-100+ env vars. Document your working `config.env` + back it up + don't let it drift.
- **ClickHouse storage** — logs + traces grow FAST. Set per-project retention; watch disk.
- **OpenTelemetry ingest** — open port + auth carefully; a misconfigured OTel endpoint can DoS your cluster with log floods.
- **Probes**: run in separate regions or they all probe from your single datacenter → no true multi-region monitoring. Probes are separate Docker images you deploy in AWS regions / Fly.io / etc.
- **Twilio costs** — SMS + voice alerts cost money per event. Set rate limits on alerts to avoid bill shock.
- **Public-facing status pages** — require your domain + TLS + CORS config. Verify uptime claims before launching.
- **AI Copilot** — sends code/logs to LLM provider. Review privacy implications; disable if regulated data.
- **SSO/SAML** — available but setup is non-trivial; budget time.
- **Incident management** vs simpler PagerDuty-likes: OneUptime's incident model is rich but complex. For a small team that just needs "page me when thing down," simpler tools win.
- **Multi-project / multi-tenant** — OneUptime is designed multi-tenant from ground up; project = isolation unit.
- **Status page custom domains** — require DNS CNAME + TLS via OneUptime's cert service.
- **Comparison to commercial**: OneUptime Cloud free tier is generous. Self-host makes sense if (a) data sovereignty, (b) large-scale logs where SaaS cost dominates, (c) air-gapped.
- **Email deliverability** — bundled Haraka MTA; set SPF/DKIM on your sending domain or use external SMTP relay. Otherwise your alerts land in spam.
- **License**: Apache-2.0 for the repo; SaaS brand + some trademarks reserved.
- **Alternatives worth knowing:**
  - **Uptime Kuma** — simple self-hosted uptime monitoring (just monitoring + basic status pages); much lighter (separate recipe likely)
  - **Gatus** — YAML-defined health checks; super light (separate recipe)
  - **Cachet** — OSS status page only
  - **Statping-ng** — monitoring + status pages
  - **Grafana + Prometheus + Alertmanager + Loki + Tempo + Mimir** — DIY observability stack; more flexible, similar complexity
  - **Signoz** — OSS Datadog-alternative; OTel-focused, ClickHouse-backed (separate recipe likely)
  - **HyperDX** — OSS APM + logs + tracing; ClickHouse-backed
  - **OpenObserve** — lightweight Elastic-alternative; logs + metrics + traces
  - **Sentry** (self-hosted) — errors + some APM (separate recipe)
  - **Commercial**: Datadog, New Relic, Splunk, Dynatrace, Grafana Cloud, Honeycomb
  - **Choose OneUptime if:** you want one tool across monitoring/status/incidents/on-call/logs/APM and have the VM budget.
  - **Choose Uptime Kuma + Gatus + Grafana if:** simpler / Unix-y philosophy.
  - **Choose Signoz / HyperDX if:** OTel-heavy observability, without the incident+on-call side.

## Links

- Repo: <https://github.com/OneUptime/oneuptime>
- Website: <https://oneuptime.com>
- Docs: <https://oneuptime.com/docs>
- Pricing / Cloud: <https://oneuptime.com/pricing>
- Helm chart: <https://artifacthub.io/packages/helm/oneuptime/oneuptime>
- Self-hosted install: <https://oneuptime.com/docs/self-hosted/introduction>
- Releases: <https://github.com/OneUptime/oneuptime/releases>
- Slack community: <https://join.slack.com/t/oneuptimesupport/shared_invite/zt-2pz5p1uhe-Fpmc7bv5ZE5xRMe7qJnwmA>
- Uptime Kuma alternative: <https://github.com/louislam/uptime-kuma>
- Signoz alternative: <https://github.com/SigNoz/signoz>
