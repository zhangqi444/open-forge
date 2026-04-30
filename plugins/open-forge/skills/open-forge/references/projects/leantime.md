---
name: Leantime
description: Open-source goals-and-projects-and-tasks PM system designed with ADHD, dyslexia, and autism in mind. Kanban/Gantt/table/calendar task views; goal tracking; wikis; retrospectives; Lean/Business Model Canvas; OIDC/LDAP. Laravel + Vue. AGPL-3.0.
---

# Leantime

Leantime is an open-source project management system with a deliberate, thoughtful twist: **it's designed with neurodivergent users in mind** — people with ADHD, dyslexia, and autism. That means fewer "lost in the sidebar" moments, more visual cues, forgiving workflows, and a dashboard focused on "what should I do RIGHT NOW." It competes with ClickUp, Monday, Asana, Trello (simpler), and Jira (simpler) — positioning itself as "as simple as Trello, as feature-rich as Jira."

Features (all OSS, no paywall):

- **Task management** — Kanban, Gantt, table, list, calendar views; subtasks; dependencies
- **Project planning** — dashboards, reports, status updates, milestones, sprints
- **Goals** — OKR-style tracking; metrics
- **Strategy canvases** — Lean Canvas, Business Model Canvas, SWOT, Risk Analysis
- **Information/knowledge management** — Wikis, Docs, Idea Boards, Retrospectives
- **Time tracking + timesheets**
- **File storage** — local or S3
- **Screen + webcam recording** (built-in for visual comms)
- **Comments/discussions** on everything
- **Multi-user + per-project permissions**
- **2FA (TOTP)**
- **LDAP + OIDC** integration
- **Plugins + API** extensibility
- **20+ languages**
- **Slack / Mattermost / Discord** integrations

- Upstream repo: <https://github.com/Leantime/leantime>
- Website: <https://leantime.io>
- Docs: <https://leantime.io/documentation/>
- Docker Hub: <https://hub.docker.com/r/leantime/leantime>
- Community Discord: <https://discord.gg/4zMzJtAq9z>

## Architecture in one minute

- **Laravel 11** (PHP 8.2+) + **Vue** frontend
- **MySQL 8+ / MariaDB 10.6+** (Postgres not officially supported per README)
- **Cron** for recurring tasks (notifications, digests, recurring todos)
- **Queue worker** — optional but recommended (email, imports, exports)
- Standard LEMP/LAMP deploy OR Docker

## Compatible install methods

| Infra       | Runtime                                     | Notes                                                             |
| ----------- | ------------------------------------------- | ----------------------------------------------------------------- |
| Single VM   | Native LEMP/LAMP                             | Upstream-documented                                                  |
| Single VM   | **Docker Compose** (`leantime/leantime`)        | **Officially supported**                                                |
| Kubernetes  | Community manifests                             | Stateless + DB                                                              |
| Managed     | Cloudron, Elestio, YunoHost                       | 1-click                                                                           |
| Cloud       | AWS/DO/GCP with managed MySQL                       | Standard Laravel path                                                                 |

## Inputs to collect

| Input              | Example                            | Phase     | Notes                                                             |
| ------------------ | ---------------------------------- | --------- | ----------------------------------------------------------------- |
| `LEAN_APP_URL`     | `https://pm.example.com`           | URL       | Public URL — used in emails                                         |
| `LEAN_APP_KEY`     | `openssl rand -hex 32`              | Security  | Session / CSRF signing                                                    |
| `LEAN_SESSION_PASSWORD` | `openssl rand -hex 32`         | Security  | Session encryption                                                           |
| `LEAN_DB_*`        | MySQL/MariaDB creds                  | DB        | MySQL 8+ or MariaDB 10.6+                                                                  |
| Admin user         | first-run wizard                     | Bootstrap | Race risk if exposed before setup                                                                  |
| SMTP               | host + port + creds                    | Email     | Notifications + invites + password resets                                                              |
| `LEAN_SESSION_NAME` | e.g. `leantime`                      | Cookie    | Unique per instance                                                                                         |
| S3 (optional)      | AWS keys                                | Storage   | For file uploads at scale                                                                                      |
| LDAP / OIDC        | IdP URLs + client creds                 | Auth      | Enterprise SSO                                                                                                   |
| TLS                | Let's Encrypt                            | Security  | For cookies + OIDC redirect URIs                                                                                       |

## Install via Docker Compose

```yaml
services:
  leantime:
    image: leantime/leantime:latest    # pin to specific version tag in prod
    container_name: leantime
    restart: unless-stopped
    depends_on:
      db: { condition: service_healthy }
    ports:
      - "8080:80"
    environment:
      LEAN_APP_URL: https://pm.example.com
      LEAN_APP_KEY: <openssl rand -hex 32>
      LEAN_SESSION_PASSWORD: <openssl rand -hex 32>
      LEAN_SESSION_NAME: leantime
      LEAN_DB_HOST: db
      LEAN_DB_USER: leantime
      LEAN_DB_PASSWORD: <strong>
      LEAN_DB_DATABASE: leantime
      LEAN_EMAIL_RETURN: noreply@example.com
      LEAN_EMAIL_USE_SMTP: "true"
      LEAN_EMAIL_SMTP_HOSTS: smtp.example.com
      LEAN_EMAIL_SMTP_PORT: "587"
      LEAN_EMAIL_SMTP_USERNAME: noreply@example.com
      LEAN_EMAIL_SMTP_PASSWORD: <smtp-pass>
      LEAN_EMAIL_SMTP_AUTH: "true"
      LEAN_EMAIL_SMTP_SECURE: tls
    volumes:
      - leantime-public:/var/www/html/public/userfiles
      - leantime-files:/var/www/html/public/dist/images

  db:
    image: mariadb:11
    container_name: leantime-db
    restart: unless-stopped
    environment:
      MARIADB_ROOT_PASSWORD: <strong-root>
      MARIADB_DATABASE: leantime
      MARIADB_USER: leantime
      MARIADB_PASSWORD: <strong>
    volumes:
      - leantime-db:/var/lib/mysql
    healthcheck:
      test: ["CMD", "healthcheck.sh", "--connect"]
      interval: 10s

volumes:
  leantime-public:
  leantime-files:
  leantime-db:
```

First visit → install wizard prompts for admin account + company info.

## Install via native LEMP

```sh
# Prereqs: PHP 8.2+ with all required extensions (see SYSTEM REQUIREMENTS), Composer 2, Node, MariaDB 10.6+, Apache/Nginx

cd /var/www
# Download release (preferred over git clone for prod)
wget https://github.com/Leantime/leantime/releases/download/vX.Y.Z/Leantime-vX.Y.Z.zip
unzip Leantime-vX.Y.Z.zip
cd leantime
cp config/sample.env config/.env
# Edit config/.env: LEAN_APP_URL, LEAN_DB_*, LEAN_SESSION_PASSWORD, SMTP

# DB schema
mysql -uleantime -p leantime < install/mysql.sql

# File permissions
chown -R www-data:www-data .
chmod -R g+w public/userfiles public/dist/images bootstrap/cache storage

# Cron (required)
* * * * * cd /var/www/leantime && php bin/leantime schedule:run >> /dev/null 2>&1
```

Point nginx/Apache at `/var/www/leantime/public`.

## First boot

1. Browse `https://pm.example.com` → installation wizard if fresh; otherwise login
2. Create admin account → company info → timezone
3. Create first project → add team members → configure notification settings
4. (Optional) Configure OIDC / LDAP in Settings → Auth Providers

## Data & config layout

- `config/.env` — secrets + DB
- `public/userfiles/` — user-uploaded files, project files
- `public/dist/images/` — uploaded logos, avatars
- `storage/` — logs, session files (if file driver), cache
- DB — everything else

## Backup

```sh
# DB (CRITICAL — all tasks, timesheets, goals, wikis, comments)
mysqldump -uleantime -p leantime | gzip > leantime-db-$(date +%F).sql.gz

# User files
tar czf leantime-files-$(date +%F).tgz public/userfiles public/dist/images

# .env
cp config/.env leantime-env-$(date +%F).bak
```

## Upgrade

1. Releases: <https://github.com/Leantime/leantime/releases>. Very active.
2. **Read release notes carefully** — some versions require DB migrations you run manually.
3. Back up DB + files + .env.
4. Docker: `docker compose pull && docker compose up -d`.
5. Native: download new release ZIP; preserve `config/.env` + `public/userfiles/`; run `php bin/leantime db:update` (or equivalent — check release notes).
6. Put in maintenance mode for major version jumps.

## Gotchas

- **Neurodivergent-friendly design** isn't just marketing — it reflects in UX choices (fewer nested menus, clearer "what's next" dashboards, forgiving undo, color consistency, dyslexia-aware fonts on the opt-in theme). If your team has neurodivergent members, this genuinely helps adoption.
- **First-user-is-admin race** — registration wizard is public on a fresh install. Complete setup BEFORE adding DNS/reverse proxy.
- **Cron is required** for recurring tasks, reminders, daily/weekly digests. Missing cron = silent feature failures.
- **Queue worker is optional** but enabling it makes email + import/export async (faster UI, fewer timeouts). Recommended above ~10 users.
- **MySQL/MariaDB only** — Postgres is not supported per the README. Check the docs in case this has changed.
- **`LEAN_APP_KEY` + `LEAN_SESSION_PASSWORD`** — both required; losing either logs all users out. Back up `.env`.
- **File uploads grow** — plan for `public/userfiles/` disk. Consider S3 at scale.
- **Multi-tenancy**: Leantime supports multiple "clients" (companies) within one install — useful for agencies. Permissions scope per project.
- **OIDC/LDAP** — both supported; config in Settings. OIDC config requires precise redirect URIs matching your reverse proxy.
- **PDF exports** use a headless Chromium under the hood for some reports — occasionally flaky. Check logs on failure.
- **Time-tracking** is granular (per-task, per-day); timesheet approval workflow exists but is lightweight (not full payroll territory).
- **Screen/webcam recording** is browser-MediaRecorder-based — uploaded as files to project. Size can balloon.
- **Wiki/Docs** uses a Markdown-ish editor; not as rich as Outline or BookStack but serviceable for project context.
- **Goals module** is OKR-flavored — attach metrics, link to projects, track progress. Not as deep as Ally.io / Gtmhub.
- **Integrations**: Slack/Mattermost/Discord for notifications; Zapier via REST API. Narrower native integration set than Monday/ClickUp but API covers most needs.
- **Plugin ecosystem** is smaller than mature commercial competitors — budget for some feature gaps being unfilled.
- **Company-managed Leantime Cloud** exists — paid hosted option from upstream if you want to support development without self-hosting.
- **AGPL-3.0** — SaaS-as-a-service triggers source-disclosure obligation.
- **Alternatives worth knowing:**
  - **OpenProject** — richer PM for large orgs; GPL; heavier
  - **Taiga** — agile PM; Python; active
  - **Kanboard** — lean Kanban-focused; PHP; fast; smaller scope (separate recipe likely)
  - **Wekan** — Kanban; Meteor.js; simple
  - **Focalboard** — self-host Kanban; Mattermost-maintained
  - **Plane** — newer, Next.js PM; growing fast (separate recipe)
  - **Vikunja** — Todo + list + Kanban; Go; light
  - **Trello / Asana / Monday / ClickUp / Jira / Notion** — SaaS
  - **Choose Leantime if:** you value the neurodivergent-friendly design + want built-in goals/canvases/wikis/timesheets/retros all included.
  - **Choose Kanboard if:** you want minimal Kanban + PHP + simplicity.
  - **Choose Plane if:** you want a modern alternative with Jira-like depth.

## Links

- Repo: <https://github.com/Leantime/leantime>
- Website: <https://leantime.io>
- Docs: <https://leantime.io/documentation/>
- Docker install guide: <https://docs.leantime.io/installation/docker-setup/>
- Release ZIPs: <https://github.com/Leantime/leantime/releases>
- Docker Hub: <https://hub.docker.com/r/leantime/leantime>
- Discord: <https://discord.gg/4zMzJtAq9z>
- Translations (Crowdin): <https://crowdin.com/project/leantime>
- GitHub Sponsors: <https://github.com/sponsors/Leantime>
- Plugins: <https://leantime.io/extensions/>
- Blog: <https://leantime.io/blog/>
- Neurodivergent-design rationale: search "ADHD" on the blog
