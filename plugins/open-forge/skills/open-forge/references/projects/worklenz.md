---
name: Worklenz
description: "Open-source all-in-one project management platform. Project + task + time + resource + financial + analytics + template + team/client collab. React + Node.js + PostgreSQL. AGPL-3.0. Active + Discord + cloud tier."
---

# Worklenz

Worklenz is **"Asana / Monday.com / ClickUp — open-source + AGPL + self-hostable"** — a project-management platform covering project planning, task management (list/board/Gantt), time-tracking, resource-planning, team+client collaboration, financial-insights/budgeting, analytics+reporting, and project-templates. Cloud SaaS at worklenz.com + self-hostable via Docker.

Built + maintained by **Worklenz org + community**. License: **AGPL-3.0** (explicitly shown in README badge). Active; Discord; docs site; commercial cloud tier; actively-developed.

Use cases: (a) **escape Asana/Monday/ClickUp subscription** ($10-24/mo/user) (b) **agency project management** — client-visible boards + time-tracking + billing-hours (c) **consultancy** — multi-project + financial-insights → invoicing workflow (d) **team coordination** for product-led startups (e) **resource planning** for production/operations teams (f) **AGPL-ethics-aligned shops** — reject Asana's proprietary stack; self-host AGPL (g) **privacy-conscious companies** — no user-data in US-Asana clouds (h) **cost-optimization** — vs $10-24/user/mo SaaS.

Features (from upstream README):

- **Project management** — plan, execute, monitor projects
- **Task management** — list/board/Gantt views; priorities + due dates
- **Resource planning** — allocate people to tasks
- **Team + client collaboration** — shared space
- **Financial insights** — budgets + costs + performance tracking
- **Time tracking** — log time on tasks
- **Analytics + reporting**
- **Resource management** — capacity planning + visual scheduler
- **Project templates**
- **Team collaboration** — comments, files, in-context

- Upstream repo: <https://github.com/Worklenz/worklenz>
- Website: <https://worklenz.com>
- Docs: <https://docs.worklenz.com/en/start/introduction/>
- Discord: <https://discord.com/invite/6Qmm839mgr>
- LICENSE: <https://github.com/Worklenz/worklenz/blob/main/LICENSE>

## Architecture in one minute

- **Node.js / TypeScript** backend + **React** frontend
- **PostgreSQL** — DB
- **Resource**: moderate — 500MB-1GB RAM
- **Ports**: web UI + API (configurable)

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker compose** | **Upstream-primary "Quick Docker Setup"**                       | **Primary**                                                                        |
| Manual (dev)       | Node.js build                                                                     | DIY                                                                                   |
| Hosted cloud       | app.worklenz.com                                                                    | Commercial                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `pm.example.com`                                            | URL          | TLS required                                                                                    |
| DB                   | PostgreSQL                                                  | DB           |                                                                                    |
| `JWT_SECRET`         | Auth signing                                                | **CRITICAL** | **IMMUTABLE**                                                                                    |
| Admin creds          | First-boot                                                                                 | Bootstrap    | Strong                                                                                    |
| SMTP                 | Notifications + invites                                                                                  | Email        |                                                                                    |
| OAuth (optional)     | Google/Microsoft login                                                                                                      | SSO          |                                                                                                            |
| S3/object store (optional) | File uploads                                                                                                                                  | Storage      | Fallback: local filesystem                                                                                                                                            |

## Install via Docker

Follow upstream "Quick Docker Setup" (see docs link). Typical compose shape:

```yaml
services:
  postgres:
    image: postgres:17
    environment:
      POSTGRES_DB: worklenz
      POSTGRES_USER: worklenz
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes: ["pgdata:/var/lib/postgresql/data"]
    restart: always

  worklenz:
    # image from upstream docs; pin version
    ports: ["3000:3000"]
    environment:
      DATABASE_URL: "postgresql://worklenz:${DB_PASSWORD}@postgres:5432/worklenz"
      JWT_SECRET: ${JWT_SECRET}
    depends_on: [postgres]

volumes: {pgdata: {}}
```

## First boot

1. Start → browse `:3000`
2. Register admin account
3. Create organization + first project
4. Configure SMTP for email invites + notifications
5. Invite team members
6. Configure integrations (Slack/webhook/OAuth if needed)
7. Create project template
8. Put behind TLS reverse proxy
9. Back up DB + uploads

## Data & config layout

- PostgreSQL — projects, tasks, comments, users, time entries, financial data
- Uploads — local filesystem or S3 (attachments, avatars, project assets)
- Application config via env vars

## Backup

```sh
docker compose exec postgres pg_dump -U worklenz worklenz > worklenz-$(date +%F).sql
# + uploads directory or S3 snapshot
```

## Upgrade

1. Releases: <https://github.com/Worklenz/worklenz/releases>. Active.
2. Docker: pull + restart; migrations auto-run.
3. Read release notes + back up before major versions.

## Gotchas

- **AGPL-3.0 = NETWORK-SERVICE-DISCLOSURE OBLIGATION**:
  - **Commercial tier / agency-offering Worklenz-as-hosted-SaaS** = must disclose source code modifications to users
  - Internal-only use (your company using Worklenz for your employees) = no AGPL-trigger
  - Client-offering (clients log in to YOUR hosted Worklenz) = AGPL-triggering **if you modify Worklenz** + requires offering source to users
  - Worklenz team offers their own hosted service (app.worklenz.com) — they set the precedent for operating AGPL-licensed commercial SaaS
  - **Recipe convention: "AGPL-network-service-disclosure" callout** (applies to Worklenz, Peppermint 99 maybe, Grafana-pre-2021, Mattermost, many self-hostable tools)
- **HUB-OF-CREDENTIALS TIER 2 + PROJECT-DATA-SENSITIVITY**:
  - Project data (possibly NDA-covered, client-confidential, internal-strategy)
  - Financial data (budgets, rates, billable hours)
  - Time-tracking data (employee productivity — HR-sensitive)
  - File uploads (attached documents, design assets)
  - Client access — external clients can see their projects; internal projects must be isolated
  - Team member PII + communication history
  - **56th tool in hub-of-credentials family — Tier 2 + "client-confidential-project-data" sub-category**
- **AGENCY/MSP USE CASE = MULTI-TENANT CONFIDENTIALITY**:
  - Agency manages multiple clients via Worklenz
  - Client A MUST NOT see Client B's projects
  - **Verify multi-tenancy isolation** + RBAC design
  - Wrong permissions setup = massive client-confidentiality breach
  - **Recipe convention: "multi-tenant-isolation-audit-required" for agency-shaped tools**
- **FINANCIAL DATA = REVENUE-SENSITIVE**:
  - Billable rates = sensitive business intel (competitors knowing your rates)
  - Client budgets = confidential
  - Profitability by project = strategic data
  - **Sub-category of hub-of-credentials**: "agency-financial-intel-risk"
- **TIME TRACKING = HR-SENSITIVE + PRIVACY-CONCERNING**:
  - Employee hours = evidence of underperformance (legally risky to use improperly)
  - GDPR-Article-6: legitimate-interest requires necessity + proportionality
  - EU worker-councils may need involvement (Works-Council in Germany, e.g.)
  - Employee monitoring is legally sensitive — not just IT
- **JWT_SECRET IMMUTABILITY**: **39th tool in immutability-of-secrets family.**
- **COMMERCIAL-TIER-TAXONOMY**: cloud (app.worklenz.com) + self-host. **Open-core-with-fully-functional-OSS** (same sub-tier as Tianji 100). If features end up gated behind Enterprise tier, flag in future recipe updates.
- **TRANSPARENT-MAINTENANCE**: active + AGPL-explicit + docs + Discord + commercial-tier-funded + releases + GitHub-activity-badges visible. **48th tool in transparent-maintenance family.**
- **INSTITUTIONAL-STEWARDSHIP**: Worklenz org + Discord + commercial tier. **41st tool — founder-with-commercial-tier-funded-development sub-tier.**
- **PROJECT-MGMT CATEGORY**:
  - **Planka** (batch prior) — Trello-clone; kanban-focused; OSS
  - **Focalboard** — Mattermost-made; Trello+Notion-shape
  - **WeKan** — oldest open Kanban; Meteor stack
  - **Taiga** — agile-focused; Python; mature
  - **Redmine** — ticket+PM; mature; Ruby
  - **Kanboard** — minimalist kanban; PHP
  - **OpenProject** — heavyweight; Ruby; enterprise-scope
  - **Leantime** — lean-startup-framework; PHP
  - **Kaneo** (batch 93) — new-unified-replacement-for-Jira; modern shape
  - **Worklenz** — all-in-one; AGPL; financial-insights-included
  - **Choose Worklenz if:** you want all-in-one + AGPL + financial-insights + resource-planning.
  - **Choose Kaneo if:** you want Jira-alternative modern-shape.
  - **Choose OpenProject if:** you want enterprise-grade Ruby stack.
  - **Choose Focalboard if:** you want Mattermost-integration.
- **ASANA/MONDAY-COMPARISON**:
  - Asana = polished + expensive; Worklenz = 80% of Asana's features + free + self-host
  - Monday = flexible + expensive; Worklenz = less-flexible but focused
  - ClickUp = everything-platform; Worklenz = focused on project-mgmt
- **SIDEBAR: OPEN-SOURCE-"ALL-IN-ONE"-TOOLS-ARE-GROWING**: Tianji (batch 100) analytics-uptime-all-in-one + Worklenz PM-all-in-one + ERPNext ERP-all-in-one + Cal.com scheduling-focus — a trend. Users should weigh all-in-one simplicity vs best-in-class quality.
- **ALTERNATIVES WORTH KNOWING:**
  - Commercial: Asana, Monday, ClickUp, Jira, Notion, Wrike, Basecamp
  - OSS: OpenProject, Taiga, Redmine, Kaneo, Focalboard, Planka, Leantime
- **PROJECT HEALTH**: active + AGPL + Discord + docs + commercial funding + badge-visible-on-repo. Strong signals.

## Links

- Repo: <https://github.com/Worklenz/worklenz>
- Website: <https://worklenz.com>
- Docs: <https://docs.worklenz.com/en/start/introduction/>
- Discord: <https://discord.com/invite/6Qmm839mgr>
- OpenProject (alt): <https://www.openproject.org>
- Taiga (alt): <https://www.taiga.io>
- Redmine (alt): <https://www.redmine.org>
- Kaneo (alt, batch 93): <https://github.com/usekaneo/kaneo>
- Focalboard (alt): <https://www.focalboard.com>
- Planka (alt kanban): <https://planka.app>
- Leantime (alt): <https://leantime.io>
- Asana (commercial alt): <https://asana.com>
- Monday (commercial alt): <https://monday.com>
- ClickUp (commercial alt): <https://clickup.com>
