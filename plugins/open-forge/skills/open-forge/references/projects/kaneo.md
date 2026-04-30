---
name: Kaneo
description: "Minimal, open-source project management platform — self-hosted Trello/Linear alternative. Deliberately fewer features than competitors. TypeScript monorepo; MIT-licensed. Free cloud tier at cloud.kaneo.app. Active; sponsor-funded; one-click drim CLI deploy."
---

# Kaneo

Kaneo is **"a project management app that respects your time"** — an intentionally minimal alternative to Trello / Linear / Notion / Jira, built on the philosophy that **less is more**. Clean UI, fast performance, self-hosted, no feature bloat. Targets teams that want task boards, projects, collaboration — without the 200-settings-dashboards of incumbents. MIT-licensed. Offers both self-host and free cloud (`cloud.kaneo.app`) so you can trial before committing to infra.

Built + maintained by **Andrejs** (andrejsshell + contributors). **License: MIT**. Active; Discord community; sponsor-funded via GitHub Sponsors.

Use cases: (a) **small-team task management** — replace Trello / Asana without vendor lock-in (b) **solo / duo / trio developer teams** — track work without Jira weight (c) **family / household project tracking** — rebuilds, trips, chores (d) **replacement for Notion/ClickUp** where only task-tracking matters (e) **agency client-work tracking** — one instance per client or shared (f) **homelab task list** — your running "things to do on servers" board.

Features (from upstream README + docs):

- **Clean minimal interface** — focus on work, not the tool
- **Project + task management** — boards, lists, kanban
- **Self-hosted** — your data stays yours
- **Fast performance** — lightweight React/TypeScript
- **Open source + free forever** — MIT
- **Cloud tier** — free tier at cloud.kaneo.app
- **drim CLI** — one-click deployment tool (curl | sh)
- **Docker / docker-compose** install
- **Monorepo** (TypeScript) — frontend + backend
- **Active Discord** for support
- **Sponsor-funded** — no ads, no upsells

- Upstream repo: <https://github.com/usekaneo/kaneo>
- Homepage: <https://kaneo.app>
- Docs: <https://kaneo.app/docs/core>
- Cloud (free): <https://cloud.kaneo.app>
- Discord: <https://discord.gg/rU4tSyhXXU>
- drim CLI deploy tool: <https://github.com/usekaneo/drim>
- Sponsor: <https://github.com/sponsors/andrejsshell>
- Releases: <https://github.com/usekaneo/kaneo/releases>

## Architecture in one minute

- **TypeScript monorepo** — frontend + backend packages
- **React** frontend
- **Node.js** backend
- **DB**: SQLite / Postgres (check latest docs for current defaults)
- **Resource**: light — ~200-500MB RAM; scales with user count + task count
- **Port**: configurable (defaults per docs)

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **drim CLI**       | **`curl -fsSL https://assets.kaneo.app/install.sh | sh`**       | **Upstream-recommended fastest path**                                              |
| Docker             | `usekaneo/kaneo` (or similar — check docs)                                | Traditional container path                                                                                   |
| Docker compose     | Upstream provides compose file                                                           | Typical homelab                                                                                               |
| Node.js bare-metal | Clone + build + run                                                                                   | For development                                                                                                 |
| Kaneo Cloud        | Hosted tier                                                                                                     | If you don't want to self-host (free tier available)                                                                                                                 |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `tasks.example.com`                                         | URL          | TLS recommended                                                                                    |
| DB                   | SQLite (single-instance) / Postgres (multi-user)            | DB           | Per latest docs                                                                                    |
| Admin creds          | First-boot registration                                                                           | Bootstrap    | Strong password                                                                                    |
| Secret env           | JWT secret / session secret                                                                                  | **CRITICAL** | **IMMUTABLE**                                                                                                            |
| SMTP (optional)      | For email notifications / invites                                                                                                        | Outbound     | Nice-to-have                                                                                                                            |

## Install via drim (upstream-recommended)

```sh
curl -fsSL https://assets.kaneo.app/install.sh | sh
# follow prompts
```

**Or** Docker compose (check latest docs for canonical compose):

```yaml
services:
  kaneo:
    image: ghcr.io/usekaneo/kaneo:latest   # **pin to specific version in prod**
    restart: unless-stopped
    environment:
      - DATABASE_URL=file:./kaneo.db
      - JWT_SECRET=${KANEO_JWT_SECRET}
    volumes:
      - ./kaneo-data:/data
    ports: ["3000:3000"]
```

## First boot

1. Start → browse URL → register first admin
2. Create first workspace + first project + first task board
3. Invite team members
4. Configure SMTP (if using) for invite emails
5. Put behind TLS reverse proxy
6. Back up DB + data volume

## Data & config layout

- DB — tasks, projects, users, comments, attachments
- `/data` or similar — uploaded attachments + user files
- `.env` / env vars — secrets

## Backup

```sh
# If SQLite:
sudo cp kaneo.db kaneo-$(date +%F).db
# If Postgres:
docker compose exec db pg_dump -U kaneo kaneo > kaneo-$(date +%F).sql
```

## Upgrade

1. Releases: <https://github.com/usekaneo/kaneo/releases>. Active.
2. Docker: pull + restart; drim: `drim upgrade`.
3. Back up DB BEFORE upgrades.
4. Early-stage project — expect occasional breaking changes; read release notes.

## Gotchas

- **"LESS IS MORE" PHILOSOPHY**: Kaneo intentionally omits features (time tracking, Gantt, custom fields, integrations) that competitors offer. **This is by design, not a gap.** Evaluate whether your team's workflow FITS the minimal surface:
  - Fits: Kanban + tasks + comments + small team = great
  - Doesn't fit: Agile ceremonies with story points + sprints + burndown = look at Linear / Plane / Leantime / Jira
  - Doesn't fit: Gantt-charts + resource-allocation = look at OpenProject / ProjectLibre
- **EARLY-STAGE PROJECT**: younger than incumbents; smaller user base; less battle-testing. Evaluate risk tolerance:
  - Bus-factor: 1 maintainer + community
  - Break changes: possible in early versions
  - Feature velocity: active, but smaller scope than Linear/Jira
  - Data portability: MIT + self-host + standard DB = escape hatch if project stagnates
- **SOLE-MAINTAINER + small-community sustainability**: 7th tool in sole-maintainer-with-community class. Andrejs + GitHub sponsor funding + Discord. Usual mitigations (OSS-license + forkable + portable-data).
- **HOSTED CLOUD AVAILABLE** (cloud.kaneo.app, free tier): **commercial-tier = "hosted-SaaS-of-OSS-product"** pattern (reinforces Piwigo batch 88, osTicket 89). Free tier suggests monetization via paid tiers in future — if you need reliability guarantees, consider paid tier when available or self-host.
- **HUB-OF-CREDENTIALS LIGHT**: Kaneo stores user accounts + workspace data. **33rd tool in hub-of-credentials family — LIGHT tier.** Moderate privacy surface (project content may contain business-sensitive info).
- **JWT_SECRET IMMUTABILITY**: JWT secret gates session validity. Rotating invalidates all active sessions. **26th tool in immutability-of-secrets family.**
- **`curl | sh` INSTALL PATTERN**: upstream-recommended drim CLI is installed via `curl -fsSL https://assets.kaneo.app/install.sh | sh` — this is the "curl pipe bash" pattern widely debated for security. Defense: pin a specific script commit, audit the script first, or use Docker directly. **Recipe convention: note `curl | sh` as a supply-chain-risk pattern whenever upstream recommends it.** Common in many deploy tools (Nix, rustup, deno-install, bun-install, etc.) — not unique to Kaneo.
- **SELF-HOSTED PROJECT MANAGEMENT = LOW-SENSITIVITY BASELINE UNTIL IT ISN'T**: task lists are often innocuous. But project-management tools also capture:
  - Internal roadmaps (competitive-sensitive)
  - Bug-tracking with vuln details (security-sensitive)
  - Personnel notes (HR-sensitive)
  - Client-work tracking (confidentiality obligations)
  - **Treat as moderate-sensitivity**; apply auth + TLS + backup + access-control. Don't leak internally-critical content via public exposure or leaked instance.
- **DATA PORTABILITY**: MIT + standard DB + active API means portable. Export features may be less mature than incumbents; audit before committing.
- **PRIVACY-FIRST POSITIONING**: upstream's "data stays yours" messaging + no ads/no-upsells + MIT license + clean-codebase culture. **Transparent-maintenance signal** (15th tool).
- **MINIMALISM vs. MARKET REALITY**: Kaneo's minimalism-as-philosophy is admirable. **Users requesting features = feature-pressure.** Watch whether Kaneo holds the line on minimalism or drifts toward feature-bloat as it grows. Early-stage discipline is easy; sustaining it over years is hard.
- **MIT LICENSE**: permissive; commercial-friendly; fork-friendly.
- **ALTERNATIVES WORTH KNOWING:**
  - **Plane** — Next.js; AGPL; feature-rich Linear-alternative
  - **Leantime** — PHP; GPL; goal-oriented PM + ADHD-friendly
  - **Vikunja** — Go+Vue; AGPL; self-hosted to-do + tasks
  - **Focalboard** — TypeScript; MIT; acquired-by-Mattermost-then-maintained-less
  - **OpenProject** — Ruby on Rails; GPL; traditional PM (Gantt, WBS); enterprise-ready
  - **Taiga** — Python+React; Mozilla Public; Scrum-focused
  - **WeKan** — Meteor; MIT; Trello-clone
  - **Kanboard** — PHP; MIT; minimal self-hosted kanban
  - **GitLab Issues / GitHub Projects** — if already in one of those ecosystems
  - **Linear** — commercial SaaS; designer's-darling UX
  - **Notion / ClickUp / monday.com / Jira** — commercial SaaS incumbents
  - **Choose Kaneo if:** you want MINIMAL + MIT + modern-React-stack + small-team + cloud-or-selfhost.
  - **Choose Plane if:** you want MORE FEATURES + Linear-UX + AGPL.
  - **Choose Vikunja if:** you want solid to-do + tasks + self-host + AGPL.
  - **Choose Leantime if:** you want goal-oriented + ADHD-friendly PM.
  - **Choose OpenProject if:** traditional PM + Gantt + enterprise-ready.
- **PROJECT HEALTH**: active + MIT + Discord + sponsor-funded + cloud-tier-available + drim-deploy-tool. Young-but-healthy signals.

## Links

- Repo: <https://github.com/usekaneo/kaneo>
- Homepage: <https://kaneo.app>
- Docs: <https://kaneo.app/docs/core>
- Cloud: <https://cloud.kaneo.app>
- Discord: <https://discord.gg/rU4tSyhXXU>
- drim (deploy): <https://github.com/usekaneo/drim>
- Sponsor: <https://github.com/sponsors/andrejsshell>
- Plane (alt, feature-rich): <https://plane.so>
- Vikunja (alt, tasks): <https://vikunja.io>
- Leantime (alt, goal-oriented): <https://leantime.io>
- Focalboard (alt, Mattermost): <https://www.focalboard.com>
- OpenProject (alt, enterprise): <https://www.openproject.org>
- Linear (commercial alt): <https://linear.app>
