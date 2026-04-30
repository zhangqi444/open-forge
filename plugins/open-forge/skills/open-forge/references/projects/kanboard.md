---
name: Kanboard
description: Minimal, fast Kanban-focused project management. Swimlanes, subtasks, time tracking, automated actions, plugins, LDAP, REST/JSON-RPC API. PHP + SQLite/MySQL/Postgres. MIT. **In maintenance mode** — only bug fixes + community PRs; no major new features.
---

# Kanboard

Kanboard is a **deliberately minimal** Kanban-focused project management tool. It loads fast, has a tight feature set, and runs on modest hardware (Raspberry Pi, shared PHP hosts, tiny VPS). It's been around since ~2014 and is rock-solid for teams that want a Kanban board without the ClickUp/Jira bloat.

**⚠️ Status: upstream has explicitly put Kanboard in MAINTENANCE MODE.** From the README:

> The author of this application is not actively developing any new major features (only small fixes). New releases are published regularly depending on the contributions made by the community.

This isn't a deal-breaker — Kanboard is feature-complete for what it is, and community PRs keep it current. But if you want active development + modern UX + new integrations, look elsewhere (Plane, Wekan, Focalboard, Leantime).

What you get:

- **Kanban board** with swimlanes, WIP limits, categories
- **Subtasks + time tracking** — drill down on tasks
- **Automatic actions** — "when task moved to X, assign Y" + 20+ built-in triggers
- **Plugins** — calendar, subtask rollup, gitlab/github/gitea webhooks, LDAP, OIDC, 2FA, many more
- **Multi-project + per-project permissions**
- **LDAP auth** + reverse-proxy auth + Google/GitHub OAuth + OIDC (plugin)
- **2FA** (plugin)
- **REST + JSON-RPC API**
- **CSV import/export** for tasks
- **Gantt + dashboard views** in addition to Kanban
- **Markdown comments + descriptions**
- **File attachments** (local or S3 via plugin)

- Upstream repo: <https://github.com/kanboard/kanboard>
- Website: <https://kanboard.org>
- Docs: <https://docs.kanboard.org>
- Forum: <https://kanboard.discourse.group>
- Docker Hub: <https://hub.docker.com/r/kanboard/kanboard>

## Architecture in one minute

- **PHP 7.4+ / 8.x** (classic server-rendered MVC, very fast)
- **Database**: SQLite (default), MySQL/MariaDB, PostgreSQL
- **No Node/build step** — pure PHP + templates
- **Session** — PHP file-based or DB
- **File uploads** — local disk OR S3 (via plugin)
- Small disk + memory footprint (runs well on 256 MB RAM)

## Compatible install methods

| Infra       | Runtime                                      | Notes                                                            |
| ----------- | -------------------------------------------- | ---------------------------------------------------------------- |
| Single VM   | LEMP/LAMP (PHP + DB + web server)               | **Most common** — tiny footprint                                    |
| Single VM   | Docker (`kanboard/kanboard`)                      | Upstream image; Alpine-based                                          |
| Shared host | Upload files to cPanel / shared PHP host           | Works — Kanboard is designed to                                          |
| Raspberry Pi | Runs comfortably on Pi 3/4 with SQLite              | Popular home-server choice                                                   |
| Kubernetes  | Community manifests / charts                           | Stateless + DB + volume                                                          |

## Inputs to collect

| Input              | Example                         | Phase     | Notes                                                             |
| ------------------ | ------------------------------- | --------- | ----------------------------------------------------------------- |
| Port               | `80` / `8080`                    | Network   | Behind reverse proxy with TLS                                          |
| DB                 | SQLite file OR MySQL/Postgres     | Storage   | SQLite default + fine for small teams                                         |
| Data volume        | `/var/www/app/data`                | Storage   | SQLite file + uploaded files + plugins                                                |
| Admin user         | default `admin` / `admin`           | Bootstrap | **CHANGE ON FIRST LOGIN**                                                              |
| LDAP (optional)    | LDAP URL + bind DN                    | Auth      | For enterprise auth                                                                        |
| Reverse proxy      | TLS-terminating                        | Network   | Kanboard is plain HTTP internally                                                               |
| SMTP (optional)    | host + port + creds                     | Email     | For task notifications                                                                                 |

## Install via Docker

```sh
docker run -d --name kanboard \
  --restart unless-stopped \
  -p 8080:80 \
  -v /opt/kanboard/data:/var/www/app/data \
  -v /opt/kanboard/plugins:/var/www/app/plugins \
  -v /opt/kanboard/ssl:/etc/nginx/ssl \
  kanboard/kanboard:v1.2.x    # pin; check Docker Hub
```

Browse `http://<host>:8080` → default creds **`admin` / `admin`**.

## Install via Docker Compose

```yaml
services:
  kanboard:
    image: kanboard/kanboard:v1.2.x
    container_name: kanboard
    restart: unless-stopped
    ports:
      - "8080:80"
    volumes:
      - ./data:/var/www/app/data
      - ./plugins:/var/www/app/plugins
      - ./ssl:/etc/nginx/ssl
    environment:
      # Optional: use MariaDB instead of SQLite
      # DATABASE_URL: mysql://kanboard:<strong>@db/kanboard
      PLUGIN_INSTALLER: "true"    # allow installing plugins via UI
```

For bigger deployments, add a MariaDB service and point `DATABASE_URL` at it.

## Install natively (LAMP)

```sh
# Prereqs: PHP 7.4+ with ext-pdo ext-pdo_sqlite (or mysql/pgsql) ext-gd ext-zip ext-mbstring ext-xml ext-curl ext-openssl
# Download latest release
wget https://github.com/kanboard/kanboard/releases/download/vX.Y.Z/kanboard-X.Y.Z.zip
unzip kanboard-X.Y.Z.zip -d /var/www/
mv /var/www/kanboard-X.Y.Z /var/www/kanboard
chown -R www-data:www-data /var/www/kanboard/data
chown -R www-data:www-data /var/www/kanboard/plugins

# Apache / Nginx docroot → /var/www/kanboard/public
# .htaccess provided for Apache; use fastcgi-pass for Nginx
```

## First boot

1. Browse Kanboard → log in with `admin` / `admin`
2. **Immediately** change admin password + email (top-right user menu)
3. Create project → create columns → add tasks
4. Install plugins you want via Plugin Directory (`/plugin/directory`) if `PLUGIN_INSTALLER=true`, else drop manually into `plugins/`

## Data & config layout

Inside `/var/www/app/data` (Docker) or `data/` (native):

- `db.sqlite` — SQLite DB (if using SQLite)
- `files/` — task attachments
- `backups/` — (if backup plugin installed)
- `cache/` — render cache
- `tmp/` — temporary

`plugins/` — installed plugins (also backed-up as needed)

## Backup

```sh
# SQLite variant
cp /opt/kanboard/data/db.sqlite /opt/backups/kanboard-$(date +%F).sqlite

# MySQL variant
mysqldump -ukanboard -p kanboard | gzip > kanboard-db-$(date +%F).sql.gz

# Files + plugins
tar czf kanboard-files-$(date +%F).tgz /opt/kanboard/data/files /opt/kanboard/plugins
```

## Upgrade

1. Releases: <https://github.com/kanboard/kanboard/releases>. Moderate (maintenance mode).
2. **Always back up `data/` first** — especially `db.sqlite`.
3. Docker: `docker compose pull && docker compose up -d`. Migrations run on startup.
4. Native: download new release zip; preserve `data/` + `plugins/` + `config.php`; overwrite rest.
5. Major version jumps are rare given maintenance mode — 1.x will be the line for the foreseeable future.

## Gotchas

- **MAINTENANCE MODE** — Kanboard is feature-complete in upstream's view. No new major features will be shipped. Small fixes + community PRs continue. If this matters, pick Plane, Wekan, Leantime, or Vikunja instead.
- **Default creds `admin` / `admin`** — CHANGE ON FIRST LOGIN. If you expose Kanboard before changing, assume compromise.
- **PHP is the runtime** — long-term PHP support (7.4, 8.x) matters; check your distro's PHP LTS commitments before deploying.
- **SQLite vs MariaDB/Postgres**: SQLite scales to small teams (< 50 users, < 10k tasks) comfortably. Above that, switch to MariaDB/Postgres.
- **Plugin security**: Kanboard plugins are community-maintained; some are unmaintained. Read the plugin source before installing. `PLUGIN_INSTALLER=true` makes UI-based install available but has the same trust issue.
- **Rate limiting**: Kanboard has no built-in rate limiting. If exposing publicly, put a reverse proxy / fail2ban in front to block brute-force on `/login`.
- **Password policy** is minimal — no complexity rules by default. Use LDAP/OIDC + MFA plugin for production.
- **API keys** — per-user in Settings. JSON-RPC API is very powerful (full read/write access). Rotate API keys on staff turnover.
- **Automated actions** live inside each project — powerful for workflow but NOT auditable (no audit log of rule runs). Good for conventions; bad for compliance-heavy environments.
- **No dark mode built in** — themes available via plugin.
- **Multi-tenancy**: single admin pool; projects are access-controlled but there's no "separate workspaces per team" isolation.
- **Mobile apps** — community-maintained (e.g., Kanboard-mobile by various authors). Not official.
- **i18n** via Gettext; 40+ languages shipped.
- **MIT license** — permissive; commercial use OK.
- **Alternatives worth knowing:**
  - **Leantime** — richer features (goals, canvases, wikis, timesheets); AGPL; actively developed (separate recipe)
  - **Wekan** — Kanban; Meteor.js; moderate activity
  - **Focalboard** — Mattermost-backed; Kanban + other views; active
  - **Plane** — Next.js modern; Jira-like depth; AGPL; active (separate recipe)
  - **OpenProject** — Ruby on Rails; richer PM; heavier
  - **Vikunja** — Go; todo + list + Kanban; modern
  - **Taiga** — Python; agile scrum focus; mature
  - **Trello / Asana / Monday / Linear** — SaaS
  - **Choose Kanboard if:** you want lightweight, proven, PHP-stack Kanban + OK with maintenance mode.
  - **Choose Wekan if:** you want a less-dormant OSS Kanban alternative.
  - **Choose Leantime/Plane if:** you want actively-developed richer PM.

## Links

- Repo: <https://github.com/kanboard/kanboard>
- Website: <https://kanboard.org>
- Docs: <https://docs.kanboard.org>
- Install guide: <https://docs.kanboard.org/v1/admin/installation/>
- Docker docs: <https://docs.kanboard.org/v1/admin/docker/>
- Plugin directory: <https://kanboard.org/plugins.html>
- Requirements: <https://docs.kanboard.org/v1/admin/requirements/>
- Upgrade: <https://docs.kanboard.org/v1/admin/upgrade/>
- Forum: <https://kanboard.discourse.group>
- ChangeLog: <https://github.com/kanboard/kanboard/blob/main/ChangeLog>
- Docker Hub: <https://hub.docker.com/r/kanboard/kanboard>
- Releases: <https://github.com/kanboard/kanboard/releases>
