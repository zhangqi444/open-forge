---
name: tududi
description: "Hierarchical task + project + area + notes + tags manager with Telegram integration. Smart recurring tasks. Paid-hosted subscription for managed version + OSS self-host. chrisvel sole + GitHub Sponsors/Patreon/BuyMeACoffee + hosted-tier. Active."
---

# tududi

tududi is **"Todoist / TickTick / OmniFocus — but hierarchical + Telegram-integrated + OSS + funded-via-sponsorships"** — a personal task/project management app with clear hierarchy: **areas → projects → tasks → subtasks + notes + tags**. Smart recurring tasks (daily/weekly/monthly with patterns + parent-child-links + completion-based-recurrence); filters (Today/Upcoming/Someday); Telegram integration for capture + notifications; privacy-focused (your data stays private).

Built + maintained by **Chris Veleris (chrisvel)**. License: check LICENSE. Active; sponsorships via GitHub Sponsors + Patreon + BuyMeACoffee + **hosted subscription tier** for managed; extensive README; Medium philosophy blog-posts.

Use cases: (a) **GTD-style productivity system** — areas/projects/tasks hierarchy matches GTD (b) **replace Todoist subscription** — self-host without paying monthly (c) **Telegram-to-tududi task-capture** — send Telegram msg → new task (d) **habit/routine tracking** — recurring tasks daily/weekly (e) **shared household-list** — (if supported) family task-tracking (f) **privacy-focused** — no cloud + no telemetry (g) **project-decomposition** — subtasks + parent-child tracking (h) **note-taking-adjacent-to-tasks** — notes/tags around tasks.

Features (per README):

- **Task management** — CRUD + filters (Today/Upcoming/Someday) + order-by
- **Subtasks** with progress tracking
- **Recurring tasks** (daily/weekly/monthly/monthly-specific-weekday/monthly-last-day)
- **Completion-based recurrence**
- **Parent-child task linking**
- **Direct parent editing**
- **Custom intervals** (every 2 weeks, etc.)
- **End-date control**
- **Areas + projects + notes + tags**
- **Telegram integration**
- **Self-hostable OR hosted-subscription**

- Upstream repo: <https://github.com/chrisvel/tududi>
- Philosophy blog: <https://medium.com/@chrisveleris/designing-a-life-management-system-that-doesnt-fight-back-2fd58773e857>
- Sponsor: <https://github.com/sponsors/chrisvel>

## Architecture in one minute

- **Ruby on Rails** (likely — confirm by checking repo)
- **PostgreSQL** / SQLite
- **Resource**: low-moderate — 200-500MB RAM
- **Port**: web UI

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker**         | **Upstream images**                                             | **Primary**                                                                        |
| **Source**         | Rails / Node                                                                            | Dev                                                                                   |
| **Hosted subscription** | Commercial-tier alternative                                                                                                             | Pay                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `tasks.example.com`                                         | URL          | TLS                                                                                    |
| Admin creds          | First-boot                                                  | Bootstrap    | Strong                                                                                    |
| DB                   | PostgreSQL / SQLite                                         | DB           |                                                                                    |
| Telegram bot token   | BotFather                                                   | Integration  | For Telegram capture                                                                                    |
| `SECRET_KEY_BASE`    | Rails signing                                               | **CRITICAL** | **IMMUTABLE** if Rails-based                                                                                    |

## Install via Docker

```yaml
services:
  tududi:
    image: chrisvel/tududi:latest        # **pin version**
    environment:
      SECRET_KEY_BASE: ${SECRET_KEY_BASE}
      DATABASE_URL: postgresql://tududi:${DB_PASSWORD}@db:5432/tududi
    volumes:
      - tududi-data:/app/data
    ports: ["3000:3000"]
    depends_on: [db]

  db:
    image: postgres:17
    environment:
      POSTGRES_DB: tududi
      POSTGRES_USER: tududi
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes: [pgdata:/var/lib/postgresql/data]

volumes:
  tududi-data: {}
  pgdata: {}
```

## First boot

1. Start stack → browse web UI
2. Create admin account
3. Set up first area + first project
4. Add first tasks
5. Connect Telegram bot (optional)
6. Test recurring task patterns
7. Back up DB

## Data & config layout

- PostgreSQL — all tasks, projects, areas, notes, tags, recurrence state
- `/app/data/` — uploads / attachments (if any)

## Backup

```sh
docker compose exec db pg_dump -U tududi tududi > tududi-$(date +%F).sql
```

## Upgrade

1. Releases: <https://github.com/chrisvel/tududi/releases>. Active.
2. Docker pull + restart

## Gotchas

- **LIFE-MANAGEMENT DATA = PII + PERSONAL-INSIGHT**:
  - Tasks, projects, areas reveal what you're doing + thinking
  - Personal notes = intimate
  - **88th tool in hub-of-credentials family — Tier 2**
  - **Sub-family: "productivity-life-management-personal-history-risk"** — NEW sub-family
  - **NEW sub-family: "productivity-life-management-personal-history-risk"** — 1st tool named (tududi)
  - Notable because tasks can reveal sensitive context (health appointments, legal deadlines, work projects)
- **TELEGRAM INTEGRATION = ANOTHER CREDENTIAL**:
  - Telegram bot token stored in tududi
  - Bot can DM you tasks + accept captures
  - If bot token leaked → attacker can DM users as the bot
  - **Recipe convention: "Telegram-bot-token-integration" callout**
- **SPONSORSHIPS + HOSTED-TIER = SUSTAINABLE-OSS BUSINESS MODEL**:
  - Chris's funding model: GitHub Sponsors + Patreon + Buy Me A Coffee + hosted subscription
  - Multi-channel monetization typical for solo-maintainers
  - **Recipe convention: "multi-channel-sponsorship + paid-hosted-tier" business-model** — increasingly common sustainable pattern
  - **NEW recipe convention** — sole-maintainer business-model note
- **BLOG-BACKED PHILOSOPHY**:
  - Chris has Medium articles explaining the system-design
  - **Recipe convention: "philosophy-blog-for-design-decisions positive-signal"** — rare + valuable
  - **NEW positive-signal convention** (tududi 1st)
  - Aligns with mtlynch's "public-transparency-blog-for-OSS-project" (PicoShare 103) but more design-philosophy focused
- **COMMERCIAL-TIER-TAXONOMY**:
  - OSS self-host + paid-hosted-subscription
  - **"hosted-OSS-as-service" sub-category** of commercial-tier-taxonomy
  - Distinct from Dittofeed's (106) "open-core-with-licensed-closed-source-extensions" (feature-gated)
  - **NEW sub-category: "hosted-OSS-as-service" (same-features-you-pay-for-hosting)** — tududi 1st named
  - Others in this vein: Plausible, Ghost (both offer identical-features cloud vs self-host)
- **RECURRING TASKS = WORKFLOW COMPLEXITY**:
  - Smart parent-child recurrence is a technical feat
  - Complex state: parent patterns + generated instances + completion-based variants
  - **Recipe convention: "recurring-task-state-management complexity" note**
- **HIERARCHY = COGNITIVE LOAD**:
  - areas → projects → tasks → subtasks = 4 layers
  - Powerful but can be over-engineered for simple users
  - Philosophy blog helps new users understand intent
- **INSTITUTIONAL-STEWARDSHIP**: chrisvel sole + sponsorships + hosted-tier + community. **74th tool — sole-maintainer-with-sustainable-business sub-tier** (**NEW sub-tier** — distinct from "sole-maintainer-with-visible-sponsor-support" because tududi has operational hosted-tier revenue too)
  - **NEW sub-tier: "sole-maintainer-with-multi-stream-monetization"** — 1st tool named (tududi; Chris Veleris)
- **TRANSPARENT-MAINTENANCE**: active + sponsorships + philosophy-blog + Medium articles + releases. **82nd tool in transparent-maintenance family.**
- **TASK-MANAGER-CATEGORY (crowded):**
  - **tududi** — OSS; hierarchical; Telegram-integrated
  - **Vikunja** — OSS; Go + Vue
  - **Planka** — OSS; trello-clone
  - **Focalboard** — OSS; Mattermost; kanban
  - **Super Productivity** — OSS; desktop
  - **ticktick / Todoist / Things / OmniFocus** (commercial)
  - **Taskwarrior** — CLI
- **ALTERNATIVES WORTH KNOWING:**
  - **Vikunja** — if you want Go + mature + kanban-capable
  - **Taskwarrior** — if you want CLI + Git-sync
  - **Planka** — if you want Kanban/Trello-style
  - **Choose tududi if:** you want hierarchy + Telegram + philosophy-driven design.
- **PROJECT HEALTH**: active + sponsorships + hosted-tier + philosophy-blog. Strong for solo-maintainer.

## Links

- Repo: <https://github.com/chrisvel/tududi>
- Sponsor: <https://github.com/sponsors/chrisvel>
- Vikunja (alt): <https://vikunja.io>
- Planka (alt): <https://planka.app>
- Focalboard (alt): <https://www.focalboard.com>
- Taskwarrior (alt CLI): <https://taskwarrior.org>
