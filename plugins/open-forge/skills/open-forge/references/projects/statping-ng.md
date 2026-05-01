---
name: Statping-ng
description: "Status page + monitoring server. Drop-in replacement for discontinued Statping. Go + Vue. SQLite/MySQL/Postgres. Multi-OS binaries + Docker. statping-ng org. GitHub Pages site + wiki."
---

# Statping-ng

Statping-ng is **"Cachet / Upptime — with more monitoring + combined status-page-generator"** — a status page + monitoring server. Fetches apps, renders a status page, supports MySQL/Postgres/SQLite, multi-OS. **Drop-in replacement** for the discontinued original Statping fork.

Built + maintained by **statping-ng** org (community fork continuing after original stopped). Multi-branch build pipeline (dev/unstable/stable). License: AGPL / similar.

Use cases: (a) **public status page** for your services (b) **internal monitoring** dashboard (c) **incident-page for customers** (d) **Uptime-monitor + status-page combined** (e) **low-cost Cachet alternative** (f) **cross-platform monitoring** (Linux/Win/Mac/Docker) (g) **SQLite-simple deploy** (h) **fork-after-original-discontinued success story**.

Features (per README):

- **Status page** auto-rendered from monitored services
- **MySQL / Postgres / SQLite** backends
- **Multi-OS** — Linux, Windows, Mac, Docker
- **Dev/unstable/stable** branch pipeline
- **Drop-in for original Statping**

- Upstream repo: <https://github.com/statping-ng/statping-ng>
- Website: <https://statping-ng.github.io>
- Wiki: <https://github.com/statping-ng/statping-ng/wiki>

## Architecture in one minute

- **Go** backend
- **Vue** frontend
- Pluggable DB (SQLite default)
- **Resource**: low — single binary
- **Port**: HTTP

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker**         | Stable branch                                                                                                          | Primary                                                                                    |
| **Binary**         | Multi-OS releases                                                                                                      | Alt                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `status.example.com`                                        | URL          | **Public-facing**                                                                                    |
| DB                   | SQLite default; MySQL/Postgres for scale                    | DB           |                                                                                    |
| Services to monitor  | URLs + ports + types                                        | Config       |                                                                                    |
| Notification         | Webhook/email on incident                                   | Integration  |                                                                                    |

## Install via Docker

See <https://github.com/statping-ng/statping-ng/wiki/Docker>. Typical:
```yaml
services:
  statping:
    image: adamboutcher/statping-ng:stable-latest        # **pin**
    ports: ["8080:8080"]
    volumes:
      - ./statping-data:/app
    restart: unless-stopped
```

## First boot

1. Start; browse UI
2. Create admin; set strong password
3. Add first service; watch monitoring
4. Configure public-vs-authenticated page
5. Configure notifications (Slack/Discord/email)
6. Put behind TLS
7. Back up SQLite

## Data & config layout

- `/app/` — SQLite + config

## Backup

```sh
sudo tar czf statping-$(date +%F).tgz statping-data/
```

## Upgrade

1. Releases: <https://github.com/statping-ng/statping-ng/releases>
2. Multi-branch — pick **stable** for production
3. Docker pull + restart

## Gotchas

- **162nd HUB-OF-CREDENTIALS Tier 2 — MONITORING + NOTIFICATION-CREDS**:
  - Holds: monitored service URLs (internal topology), notification creds (Slack/Discord webhooks, email)
  - Public status-page = revealing service-existence
  - Admin-auth for config
  - **162nd tool in hub-of-credentials family — Tier 2**
- **PUBLIC-STATUS-PAGE-DISCLOSURE**:
  - Status page leaks service existence
  - OK for public services
  - Discipline for internal ones
  - **Recipe convention: "public-status-page-service-existence-disclosure callout"**
  - **NEW recipe convention** (Statping-ng 1st formally)
- **MULTI-BRANCH-QUALITY-GATES (dev/unstable/stable)**:
  - Explicit quality tiers
  - Stable for prod
  - **Recipe convention: "multi-branch-quality-gate-convention positive-signal"**
  - **NEW positive-signal convention** (Statping-ng 1st formally)
- **FORK-AFTER-DISCONTINUATION POSITIVE-SIGNAL**:
  - Statping original stopped; community picked up with -ng
  - **Community-fork-after-discontinuation: 1 tool** 🎯 **NEW FAMILY** (Statping-ng; distinct from Pelican which is a re-fork of different OSS lineage)
  - **Recipe convention: "community-fork-after-original-discontinuation positive-signal"**
  - **NEW positive-signal convention** (Statping-ng 1st formally)
- **NAMING-CONVENTION (-ng SUFFIX)**:
  - "-ng" = next-generation; common for forks
  - **Recipe convention: "naming-convention-ng-suffix-fork-indicator neutral-signal"**
  - **NEW neutral-signal convention** (Statping-ng 1st formally)
- **MONITORING-TOOL-CLASSIC**:
  - Decade-plus-ish Status-Page-tool history
- **INSTITUTIONAL-STEWARDSHIP**: statping-ng community + wiki + website + multi-branch + CI. **148th tool — community-fork-post-discontinuation sub-tier** (NEW-soft).
- **TRANSPARENT-MAINTENANCE**: active + CI + multi-branch + wiki + website. **154th tool in transparent-maintenance family.**
- **STATUS-PAGE-CATEGORY:**
  - **Statping-ng** — combined status-page + monitoring; multi-OS
  - **Uptime Kuma** — dominant; richer UX
  - **Cachet** — mature OSS
  - **Gatus** — Go; YAML-configured
  - **Upptime** — GitHub Actions + static
- **ALTERNATIVES WORTH KNOWING:**
  - **Uptime Kuma** — dominant; rich UX; Node
  - **Cachet** — if you want mature PHP
  - **Gatus** — if you want YAML-config
  - **Choose Statping-ng if:** you want Go + SQLite-simple + multi-OS + Statping-continuity.
- **PROJECT HEALTH**: active + community-fork + multi-branch + wiki. Good ongoing stewardship of a rescued project.

## Links

- Repo: <https://github.com/statping-ng/statping-ng>
- Website: <https://statping-ng.github.io>
- Wiki: <https://github.com/statping-ng/statping-ng/wiki>
- Uptime Kuma (alt): <https://github.com/louislam/uptime-kuma>
- Gatus (alt): <https://github.com/TwiN/gatus>
