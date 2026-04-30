---
name: CheckCle
description: "Real-time full-stack monitoring platform. Multi-language (English/Khmer/Japanese/Chinese). Modern UI; focus on developer-friendly monitoring. operacle/CheckCle; check upstream for feature-surface + license."
---

# CheckCle

CheckCle is **"Uptime Kuma / StatusCake — but with fuller stack monitoring + modern UI + multi-language"** — a real-time full-stack monitoring platform. Monitors services, servers, and applications with a modern dashboard. Multi-language (English + Khmer + Japanese + Chinese — notable inclusion of Khmer).

Built + maintained by **operacle**. License: check LICENSE. README references "CheckCle Platform" — suggests mature-UX intent + team-oriented monitoring.

Use cases: (a) **uptime monitoring for services** (b) **server health monitoring** (c) **multi-language team monitoring** — accessible to non-English teams (d) **alternative to Uptime Kuma with richer feature-surface** (e) **real-time dashboards for service-status** (f) **status-page generation** (g) **SLA tracking**.

Features (per README + project intent):

- Real-time service monitoring
- Server health monitoring
- Multi-language UI (English/Khmer/Japanese/Chinese)
- Modern dashboard
- Check upstream for full feature details

- Upstream repo: <https://github.com/operacle/checkcle>

## Architecture in one minute

- Check upstream repo (language + stack unclear from README snippet)
- Likely: Node/Go/Python + database + agent for server-monitoring
- Web UI for dashboard

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker**         | **Upstream images likely**                                      | Check repo                                                                        |
| Source             | Per upstream                                                                            | Dev                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `monitor.example.com`                                       | URL          | TLS                                                                                    |
| Admin creds          | First-boot                                                  | Bootstrap    | Strong                                                                                    |
| DB                   | Per upstream                                                | DB           |                                                                                    |
| Notification channels | Email / Slack / Telegram / webhook                          | Integrations |                                                                                    |
| Monitored targets    | URLs, servers, services                                                                                               | Config       |                                                                                    |
| Agent tokens (if server-monitoring) | Per-server                                                                                            | **CRITICAL** | **Agents run AS admin on monitored servers**                                                                                    |

## Install

Follow upstream README / docs (not yet fully mapped here — repo access required).

## First boot

1. Start CheckCle → browse web UI
2. Create admin account
3. Add first monitoring target (website / TCP / ICMP)
4. Configure notification channels
5. Add servers (if server-agent supported)
6. Configure alert thresholds
7. Put behind TLS reverse proxy + auth
8. Back up DB

## Data & config layout

- Per upstream; typically DB + config

## Backup

Follow upstream; DB + config required.

## Upgrade

1. Releases: <https://github.com/operacle/checkcle/releases>. Check for cadence.
2. Follow upstream upgrade guide

## Gotchas

- **97th HUB-OF-CREDENTIALS TIER 2**:
  - Holds: monitored-service credentials (HTTP basic-auth for authenticated checks), agent-tokens (server-wide access), notification-channel creds
  - **97th tool in hub-of-credentials family — Tier 2**
- **AGENT-ON-SERVER = PRIVILEGED ACCESS**:
  - Server-monitoring agents typically run as root
  - Compromise of CheckCle master → agent RCE on all monitored servers
  - **Recipe convention: "monitoring-agent-master-compromise risk"** — extended from prior monitoring tools (Uptime Kuma, Netdata, Zabbix, etc.)
- **MONITORING-TOOL-CATEGORY (crowded):**
  - **CheckCle** — multi-language; full-stack
  - **Uptime Kuma** — popular minimal
  - **Healthchecks.io** — cron-check focused
  - **Netdata** — metrics-heavy
  - **Zabbix** — enterprise
  - **Prometheus + Grafana** — modern metrics
  - **Monitoror** — screen-wall focused
  - **Gatus** — YAML-driven
- **MULTI-LANGUAGE INCLUSION (KHMER)**:
  - Khmer language support is uncommon in dev-tools
  - Suggests Cambodia-based maintainer or user-base
  - **Recipe convention: "uncommon-language-support positive-signal"** — inclusive
  - **NEW positive-signal convention** (CheckCle 1st for Khmer)
- **NOTIFICATION CHANNEL CREDS**:
  - Email SMTP, Slack webhook, Telegram bot tokens, webhook URLs
  - Compromise = spam-via-your-channels
- **PROJECT HEALTH UNCERTAIN**:
  - README snippet doesn't reveal much about maturity
  - Check stars-trajectory + release-cadence + docs
  - **Recipe convention: "README-thin-need-upstream-verification" callout**
  - **NEW recipe convention** — flag for operator-verification
- **CHECK UPSTREAM DOCS BEFORE DEPLOY**:
  - Don't deploy based on this recipe alone; verify features + release-cadence + license
- **INSTITUTIONAL-STEWARDSHIP**: operacle org. **83rd tool — org-with-modern-UX sub-tier** (preliminary).
- **TRANSPARENT-MAINTENANCE**: multi-language + screenshots + images. **91st tool in transparent-maintenance family** (preliminary — verify active commits).
- **ALTERNATIVES WORTH KNOWING:**
  - **Uptime Kuma** — if you want simple + popular
  - **Gatus** — if you want YAML-driven + modern
  - **Healthchecks.io** — if you want cron-check
  - **Prometheus + Grafana** — if you want metrics-first
  - **Choose CheckCle if:** you want modern UI + multi-language team + full-stack coverage.
- **NEUTRAL-SIGNAL**: README-in-translation-first ordering (Khmer before Japanese/Chinese) = **unusual + signals regional origin**

## Links

- Repo: <https://github.com/operacle/checkcle>
- Uptime Kuma (alt): <https://github.com/louislam/uptime-kuma>
- Gatus (alt): <https://github.com/TwiN/gatus>
- Healthchecks.io (alt): <https://github.com/healthchecks/healthchecks>
