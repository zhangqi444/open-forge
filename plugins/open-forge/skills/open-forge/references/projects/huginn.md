---
name: huginn-project
description: Huginn recipe for open-forge. MIT-licensed Ruby-on-Rails platform for building automated agents — think self-hosted IFTTT/Zapier with a directed-graph event model. Agents read web pages / APIs / feeds, emit events, and propagate to downstream agents. Ships as an official single-container Docker image (`ghcr.io/huginn/huginn` / `huginn/huginn`), a multi-container split where each worker runs separately (`huginn/huginn-single-process`), or a bare-metal Ruby + MySQL/Postgres install. Default admin creds are `admin` / `password` — change on first boot.
---

# Huginn

MIT-licensed Ruby on Rails platform for building automated agents. Upstream: <https://github.com/huginn/huginn>. Wiki: <https://github.com/huginn/huginn/wiki>.

Huginn is a "self-hosted IFTTT/Zapier" — you build **agents** that read data (web scrapers, RSS, APIs, weather, etc.), emit **events**, and chain those events into other agents that react (send emails, POST webhooks, aggregate into digests, etc.). Events flow as a directed graph.

Default web UI port: `:3000`. Default DB: MySQL (but PostgreSQL works via `DATABASE_ADAPTER=postgresql`).

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker single-container (`huginn/huginn`) | <https://hub.docker.com/r/huginn/huginn> · <https://github.com/huginn/huginn/blob/master/doc/docker/install.md> | ✅ | Easiest self-host — bundles MySQL + Rails + Sidekiq + all Huginn processes in ONE container. |
| Docker multi-process (`huginn/huginn-single-process`) | <https://hub.docker.com/r/huginn/huginn-single-process> · <https://github.com/huginn/huginn/tree/master/docker/single-process> | ✅ | Split web, worker, scheduler, DB into separate containers for horizontal scaling. |
| Bare-metal (Ruby + MySQL/Postgres) | <https://github.com/huginn/huginn#local-installation> + <https://github.com/huginn/huginn/wiki/Novice-setup-guide> | ✅ | Dev + advanced production. Uses `bundle exec foreman start` for process management. |
| Heroku (one-click) | <https://github.com/huginn/huginn#one-click-heroku-deployment> | ⚠️ Paid tier required for real use | Old-school one-click deploy; free tier no longer available on Heroku. |

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Install method? (docker-all-in-one / docker-multi-process / bare-metal)" | `AskUserQuestion` | Drives section. |
| secrets | "Generate `APP_SECRET_TOKEN` (64+ random hex chars)?" | Boolean (default yes) | **Mandatory** — session cookie signing. `openssl rand -hex 64`. |
| db | "Database: bundled (all-in-one Docker) or external (MySQL / Postgres)?" | `AskUserQuestion` | All-in-one ships MySQL; production usually runs Postgres externally. |
| db | "DB creds?" | Free-text (sensitive) | `HUGINN_DATABASE_*` env vars. |
| domain | "Public domain?" | Free-text | Only if exposing publicly. |
| proxy | "Reverse proxy for TLS?" | `AskUserQuestion` | Huginn does not terminate TLS. |
| smtp | "SMTP for outbound email?" | Free-text | Many Huginn agents send email (Digest, Post, Email Agents). Without SMTP, these silently fail. Set `SMTP_*` env vars or use `SEND_EMAIL_IN_DEVELOPMENT=true` for debug mode. |
| admin | "Change default admin password (default: `admin` / `password`)?" | Boolean (MUST be yes for production) | Set `SEED_USERNAME` / `SEED_PASSWORD` env vars on first boot, OR change via web UI immediately. |
| invitation | "Require invitation code for new accounts?" | `AskUserQuestion` | `INVITATION_CODE` env var. Required for any public-facing install. |

## Install — Docker all-in-one (easiest)

Upstream's quick start from `doc/docker/install.md`:

```bash
# Quickest possible test (ephemeral, loses data on container removal)
docker run -it -p 3000:3000 ghcr.io/huginn/huginn
```

With persistence + a real config (compose shape):

```yaml
# compose.yaml
services:
  huginn:
    image: ghcr.io/huginn/huginn:latest
    container_name: huginn
    restart: unless-stopped
    ports:
      - "3000:3000"
    environment:
      APP_SECRET_TOKEN: ${APP_SECRET_TOKEN}
      DATABASE_ADAPTER: mysql2
      DATABASE_HOST: localhost          # bundled inside container
      DATABASE_NAME: huginn_production
      DATABASE_USERNAME: root
      DATABASE_PASSWORD: ${DB_PASSWORD}
      # Email — required for any agent that sends mail
      SMTP_DOMAIN: example.com
      SMTP_USER_NAME: huginn@example.com
      SMTP_PASSWORD: ${SMTP_PASSWORD}
      SMTP_SERVER: smtp.example.com
      SMTP_PORT: 587
      SMTP_AUTHENTICATION: plain
      SMTP_ENABLE_STARTTLS_AUTO: "true"
      EMAIL_FROM_ADDRESS: huginn@example.com
      # Security
      SEED_USERNAME: myadmin
      SEED_EMAIL: myadmin@example.com
      SEED_PASSWORD: ${ADMIN_PASSWORD}
      INVITATION_CODE: ${INVITATION_CODE}
    volumes:
      - huginn-data:/var/lib/mysql  # persist bundled MySQL

volumes:
  huginn-data:
```

```bash
cat > .env <<EOF
APP_SECRET_TOKEN=$(openssl rand -hex 64)
DB_PASSWORD=$(openssl rand -hex 16)
ADMIN_PASSWORD=$(openssl rand -hex 16)
SMTP_PASSWORD=your-real-smtp-password
INVITATION_CODE=$(openssl rand -hex 8)
EOF
docker compose up -d
docker compose logs -f
```

Visit `http://<host>:3000/`. Log in with `SEED_USERNAME` + `SEED_PASSWORD` (or the default `admin` / `password` if you skipped `SEED_*`).

### Full env-var list

Upstream maintains `.env.example` at <https://github.com/huginn/huginn/blob/master/.env.example>. Notable additions:

| Var | Purpose |
|---|---|
| `RAILS_ENV` | `production` / `development`. Default `production` in Docker image. |
| `DOMAIN` | Canonical URL used in outbound emails + webhook URLs. |
| `ENABLE_INSECURE_AGENTS` | `true` enables the Shell Command and Ruby agents (arbitrary code execution — only for trusted users). Default `false`. |
| `TIMEZONE` | Default `Pacific Time (US & Canada)`. Set per admin's locale. |
| `USE_GRAPHVIZ_DOT` | `true` to render agent flow diagrams (requires graphviz in the image). |

## Install — Docker multi-process

For scaling individual Huginn processes separately (web, Sidekiq-style worker, scheduler). Repo: <https://github.com/huginn/huginn/tree/master/docker/single-process>.

Shape:

```yaml
services:
  mysql:
    image: mysql:8
    environment:
      MYSQL_ROOT_PASSWORD: ${DB_PASSWORD}
    volumes: [ mysql-data:/var/lib/mysql ]

  huginn_web:
    image: huginn/huginn-single-process:latest
    environment:
      <<: *huginn-common
      HUGINN_START_WEB: "true"
    ports: [ "3000:3000" ]
    depends_on: [ mysql ]

  huginn_worker:
    image: huginn/huginn-single-process:latest
    environment:
      <<: *huginn-common
      HUGINN_START_DELAYED_JOB: "true"
    depends_on: [ mysql ]

  huginn_scheduler:
    image: huginn/huginn-single-process:latest
    environment:
      <<: *huginn-common
      HUGINN_START_RAILS_RUNNER: "true"   # scheduler / agent runner
    depends_on: [ mysql ]
```

Scale workers independently: `docker compose up -d --scale huginn_worker=3`.

## Install — Bare-metal (development / advanced)

From upstream's "Local Installation" section:

```bash
# Prereqs: Ruby 3.x, MySQL or PostgreSQL, Node (for asset compilation)
git clone https://github.com/<your-fork>/huginn.git
cd huginn
git remote add upstream https://github.com/huginn/huginn.git

cp .env.example .env
# Edit .env — set APP_SECRET_TOKEN (openssl rand -hex 64), DB creds, SMTP, etc.

bundle install
bundle exec rake db:create
bundle exec rake db:migrate
bundle exec rake db:seed          # creates admin / password

# Run all Huginn processes
bundle exec foreman start

# → web at http://localhost:3000 (admin / password)
```

For production, `bundle exec foreman start` is NOT what you want — run web (Puma), worker (delayed_job), and scheduler as separate systemd services. See the Novice-setup-guide wiki page for a full systemd layout.

## Reverse proxy (Caddy example)

```caddy
huginn.example.com {
    reverse_proxy 127.0.0.1:3000
}
```

Most Huginn endpoints are fine under TLS. Webhook agents expose URLs like `/users/<id>/web_requests/<agent>/<secret>` — clients hitting those from the public internet need the canonical `DOMAIN` env var set.

## Data layout

### Docker all-in-one

| Path inside container | Content |
|---|---|
| `/var/lib/mysql/` | Bundled MySQL data (persist via volume). |
| `/app/` | Rails root. |

### Multi-process / bare-metal

MySQL/Postgres handles the data; nothing stateful on disk in the Rails containers.

**Backup = standard `mysqldump` / `pg_dump`.** Huginn doesn't store media locally by default.

## Upgrade procedure

### Docker all-in-one

```bash
# 1. Back up DB
docker exec huginn mysqldump -uroot -p"$DB_PASSWORD" huginn_production > backup-$(date +%F).sql

# 2. Pull + restart (migrations run automatically on boot)
docker compose pull
docker compose up -d
docker compose logs -f huginn
```

### Bare-metal

```bash
git fetch upstream
git checkout master
git merge upstream/master
bundle install
bundle exec rake db:migrate
bundle exec rake assets:precompile
# Restart whichever process-manager runs Huginn (systemd / foreman / etc.)
sudo systemctl restart huginn-web huginn-worker huginn-scheduler
```

## Key agent types (at a glance)

Huginn has 60+ agent types. Common ones:

- **Website Agent** — polls a URL, extracts via CSS/XPath/regex, emits events on changes.
- **RSS Agent** — consumes RSS/Atom feeds.
- **Post Agent** — sends HTTP POST/PUT/PATCH/DELETE to an URL (webhook output).
- **Webhook Agent** — receives external HTTP calls, emits events.
- **Email / Email Digest Agent** — send emails triggered by events.
- **Trigger Agent** — filter / pattern-match events.
- **Scheduler / Delay Agent** — time-based logic.
- **Shell Command Agent / Ruby Agent** — arbitrary code (DANGEROUS — gated behind `ENABLE_INSECURE_AGENTS=true`).
- **JavaScript Agent** — sandboxed JS evaluation.
- **Twilio Agent, Slack Agent, Telegram Agent, …** — platform integrations.

Full list: <https://github.com/huginn/huginn/wiki/Huginn-Agents>.

## Gotchas

- **Default creds `admin` / `password` are inexcusable on any exposed deploy.** Set `SEED_USERNAME` + `SEED_PASSWORD` on first boot, OR log in and change password IMMEDIATELY before the container is reachable from the internet.
- **`ENABLE_INSECURE_AGENTS=true` = arbitrary code execution.** The Shell Command and Ruby agents run whatever the user types. Keep it `false` on any multi-tenant / public instance.
- **Invitation code is the only signup gate on a public instance.** Without `INVITATION_CODE` set, anyone can register.
- **Email dev-mode intercepts.** In `RAILS_ENV=development`, emails go to `/letter_opener` instead of being sent. Production defaults to `RAILS_ENV=production` — verify before wondering why Email agents don't send.
- **MySQL inside the all-in-one container is ephemeral unless you mount the volume.** The default `docker run -it -p 3000:3000 ghcr.io/huginn/huginn` from upstream's quickstart LOSES all agents on container removal. Add `-v huginn-data:/var/lib/mysql` even for evaluation.
- **No built-in rate limiting on agent schedules.** A Website Agent polling every minute against a rate-limited API will get throttled / IP-banned by the target. Use "every 15 minutes" or longer by default.
- **Agent events accumulate forever.** Huginn keeps event history indefinitely by default. Set `keep_events_for` on each agent (or use the cleanup Rake task `rake huginn:remove_old_events`) or the DB will grow unbounded.
- **Graphviz dependency.** Flow diagrams in the UI need the `dot` binary. All-in-one image includes it; custom bare-metal installs need `apt install graphviz`.
- **Ruby agent = full Ruby access.** Not a sandbox — don't enable on shared instances. Use the JavaScript Agent (V8 sandbox) if you need arbitrary scripting.
- **Session cookies tied to `APP_SECRET_TOKEN`.** Rotating it logs everyone out. Generate once, keep forever (in a secret store).
- **Project is in maintenance mode.** Core development is slow — new agents mostly come from PRs, not core maintainers. For newer shapes (like LLM integrations), n8n / Windmill / Activepieces get more active development.

## Links

- Upstream repo: <https://github.com/huginn/huginn>
- Wiki / docs: <https://github.com/huginn/huginn/wiki>
- Docker install: <https://github.com/huginn/huginn/blob/master/doc/docker/install.md>
- Single-process Docker: <https://github.com/huginn/huginn/tree/master/docker/single-process>
- `.env.example` (all config vars): <https://github.com/huginn/huginn/blob/master/.env.example>
- Agents catalog: <https://github.com/huginn/huginn/wiki/Huginn-Agents>
- Creating a new agent: <https://github.com/huginn/huginn/wiki/Creating-a-new-agent>
- Novice setup (bare-metal walkthrough): <https://github.com/huginn/huginn/wiki/Novice-setup-guide>
- Docker Hub images: <https://hub.docker.com/r/huginn/huginn> · <https://hub.docker.com/r/huginn/huginn-single-process>
- Gitter chat: <https://gitter.im/huginn/huginn>
