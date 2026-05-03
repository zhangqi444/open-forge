---
name: Healthchecks
description: Cron-job monitoring / "dead-man's-switch" service. Your jobs ping Healthchecks at expected intervals; if pings stop, you get alerted. 25+ notification integrations, WebAuthn 2FA, teams/projects, public status badges. Python/Django + Postgres/MySQL. BSD-3-Clause.
---

# Healthchecks

Healthchecks is the canonical **cron-job monitoring service**. Your scheduled jobs make an HTTP GET (a "ping") to a unique URL whenever they run successfully. Healthchecks tracks the expected interval (e.g., "every day at 3am ± 15 min"); if a ping doesn't arrive on time, it sends alerts. It's a "dead-man's switch" for your infrastructure.

Why you need this: normal monitoring (Prometheus/Gatus/UptimeKuma) checks "is the service UP?". Healthchecks checks "**did my scheduled thing actually run?**" — which is a different question. Your backup script at 2am can return 0 AND your data can be gone if the script silently skipped. Healthchecks catches the "silently didn't run" case.

Core features:

- **Simple HTTP pings** — `curl https://hc.example.com/ping/<uuid>` in your cron
- **Period + Grace** — expected-interval plus tolerance
- **Cron expressions** — or "every N seconds/minutes/hours"
- **25+ integrations** — Slack, Discord, Telegram, Matrix, PagerDuty, Opsgenie, VictorOps, OhDear, SMS (Twilio, MessageBird, Plivo), Email, Webhook, Signal, Pushover, Shoutrrr, ntfy, Apprise, Teams, Mattermost, Gotify, ntfy.sh, LINE Notify, Pushbullet, Zendesk Trigger, Spike.sh, Zulip, etc.
- **Logging + capture** — send STDOUT/STDERR with the ping (up to 100 KB)
- **Signal-style pings** — `/start` + `/success` + `/fail` to measure job duration + catch failures
- **Teams + projects** — shared checks; RBAC; read-only access for on-call team
- **Public status badges** — embed in READMEs ("our nightly backup: ✅ up")
- **Monthly email reports** — weekly digest of check health
- **WebAuthn 2FA** — hardware security key support
- **API** — create/update/delete checks programmatically (infra-as-code)

Hosted at **<https://healthchecks.io>** (20 checks free; paid tiers for more). Self-host is supported + maintained by the upstream team.

- Upstream repo: <https://github.com/healthchecks/healthchecks>
- Website: <https://healthchecks.io>
- Docs (self-host): <https://github.com/healthchecks/healthchecks#running-with-docker>
- Docker Hub: <https://hub.docker.com/r/healthchecks/healthchecks>

## Architecture in one minute

- **Python 3.12+** + **Django 6.0**
- **PostgreSQL**, MySQL, or MariaDB (SQLite in dev only — not production)
- **Port 8000** (Django default)
- Optional: **Redis** for rate limiting + caching
- **Sender process** — a separate Django management command (`manage.py sendalerts`) that runs continuously to deliver notifications
- Stateless app + DB — horizontal scaling possible

## Compatible install methods

| Infra       | Runtime                                               | Notes                                                            |
| ----------- | ----------------------------------------------------- | ---------------------------------------------------------------- |
| Single VM   | Docker / Compose (`healthchecks/healthchecks`)          | **Recommended**                                                    |
| Single VM   | Native Python venv + Gunicorn + Postgres                   | For systemd-centric deploys                                          |
| Kubernetes  | Community manifests                                         | Stateless; add sendalerts sidecar                                         |
| Managed     | <https://healthchecks.io> (official hosted)                  | Free 20 checks; paid plans for more                                            |

## Inputs to collect

| Input                 | Example                               | Phase     | Notes                                                             |
| --------------------- | ------------------------------------- | --------- | ----------------------------------------------------------------- |
| `SITE_ROOT`           | `https://hc.example.com`               | URL       | Used in emails + ping URLs + badges; **permanent**                    |
| `SITE_NAME`           | `My Healthchecks`                       | Branding  | Shown in UI + emails                                                  |
| `PING_ENDPOINT`       | `https://hc.example.com/ping/`           | URL       | What goes into `curl` commands; usually same domain                      |
| `SECRET_KEY`          | `openssl rand -hex 32`                    | Security  | Django secret; losing = all sessions invalid                                 |
| `DB_*`                | Postgres creds                            | DB        | Postgres preferred; MariaDB OK                                                    |
| `DEFAULT_FROM_EMAIL`  | `healthchecks@example.com`                 | Email     | Sender for alert emails + reports                                                     |
| `EMAIL_HOST` + creds  | SMTP                                        | Email     | Required for email alerts + sign-up verification                                          |
| `REGISTRATION_OPEN`   | `True` / `False`                             | Access    | Private: set False after creating admin                                                           |
| `ALLOWED_HOSTS`       | `hc.example.com`                              | Security  | Django host-header check                                                                                    |
| Admin user            | `manage.py createsuperuser`                    | Bootstrap | Via shell; no web wizard                                                                                            |

## Install via Docker Compose

```yaml
services:
  healthchecks:
    image: healthchecks/healthchecks:4.x     # pin; check Docker Hub
    container_name: healthchecks
    restart: unless-stopped
    depends_on:
      postgres: { condition: service_healthy }
    ports:
      - "8000:8000"
    environment:
      SITE_ROOT: https://hc.example.com
      SITE_NAME: My Healthchecks
      DEFAULT_FROM_EMAIL: healthchecks@example.com
      ALLOWED_HOSTS: hc.example.com
      SECRET_KEY: <openssl rand -hex 32>
      SUPERUSER_EMAIL: admin@example.com
      SUPERUSER_PASSWORD: <strong>
      REGISTRATION_OPEN: "False"
      DB: postgres
      DB_HOST: postgres
      DB_NAME: hc
      DB_USER: hc
      DB_PASSWORD: <strong>
      EMAIL_HOST: smtp.example.com
      EMAIL_PORT: "587"
      EMAIL_HOST_USER: hc@example.com
      EMAIL_HOST_PASSWORD: <smtp-password>
      EMAIL_USE_TLS: "True"
    volumes:
      - hc-static:/opt/healthchecks/static-collected

  sendalerts:
    image: healthchecks/healthchecks:4.x
    container_name: hc-sendalerts
    restart: unless-stopped
    depends_on:
      - healthchecks
    entrypoint: ["/opt/healthchecks/manage.py", "sendalerts"]
    environment:
      # SAME env as healthchecks service
      SITE_ROOT: https://hc.example.com
      DB: postgres
      DB_HOST: postgres
      DB_NAME: hc
      DB_USER: hc
      DB_PASSWORD: <strong>
      SECRET_KEY: <openssl rand -hex 32>
      EMAIL_HOST: smtp.example.com
      EMAIL_PORT: "587"
      EMAIL_HOST_USER: hc@example.com
      EMAIL_HOST_PASSWORD: <smtp-password>
      EMAIL_USE_TLS: "True"

  postgres:
    image: postgres:17-alpine
    container_name: hc-db
    restart: unless-stopped
    environment:
      POSTGRES_USER: hc
      POSTGRES_PASSWORD: <strong>
      POSTGRES_DB: hc
    volumes:
      - hc-pg:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U hc"]
      interval: 10s
      retries: 5

volumes:
  hc-static:
  hc-pg:
```

Browse `https://hc.example.com` → log in with `SUPERUSER_EMAIL` / `SUPERUSER_PASSWORD`.

## First use

1. Create a check: **My Checks → Add Check** → name + schedule (period/grace OR cron)
2. Copy the ping URL (like `https://hc.example.com/ping/abc123-def456-...`)
3. Wire it into your cron:
   ```
   0 3 * * * /usr/local/bin/backup.sh && curl -fsS --retry 3 -o /dev/null https://hc.example.com/ping/abc123-def456-...
   ```
4. Set up notification channel: **Integrations → Add** → pick Discord/Slack/email/etc.
5. Associate the channel with the check
6. Wait for the next expected ping time; on miss, alert fires

## Advanced patterns

### Start + success + fail pings

```sh
# At start
curl -fsS https://hc.example.com/ping/<uuid>/start

# On success
./my_job.sh && curl -fsS https://hc.example.com/ping/<uuid>

# On failure
./my_job.sh || curl -fsS --data-raw "$(tail -100 /var/log/my_job.log)" https://hc.example.com/ping/<uuid>/fail
```

### Bash wrapper

```sh
./runitor --api-url https://hc.example.com -- ./my_job.sh
# runitor sends start + success/fail with STDOUT/STDERR automatically
```

### Infra-as-code

Create checks via API:

```sh
curl -X POST https://hc.example.com/api/v3/checks/ \
  -H "X-Api-Key: $PROJECT_API_KEY" \
  -d '{"name":"Nightly backup","schedule":"0 3 * * *","timezone":"UTC","grace":3600}'
```

## Data & config layout

- PostgreSQL — all checks, pings, integrations, users
- Ping metadata (stdout/stderr) stored in Postgres (capped at 100 KB per ping; older pings are pruned)
- Static assets in `/opt/healthchecks/static-collected`
- No per-user file uploads; zero disk state beyond DB + static

## Backup

```sh
# DB is the ENTIRE state
docker compose exec -T postgres pg_dump -U hc hc | gzip > hc-db-$(date +%F).sql.gz
```

Backup `.env` secrets separately (SECRET_KEY, SMTP creds, integration tokens stored encrypted in DB but `SECRET_KEY` decrypts them).

## Upgrade

1. Releases: <https://github.com/healthchecks/healthchecks/releases>. Active + stable cadence (roughly monthly).
2. `docker compose pull && docker compose up -d` (both `healthchecks` AND `sendalerts`).
3. Migrations run on startup; back up DB first.
4. Read release notes for Django-version-jump caveats (rare but happens).

## Gotchas

- **`sendalerts` must be running** — without it, checks "go red" in the UI but no notifications are sent. It's a separate Django management command; you need a second container / supervisord / systemd service running it continuously.
- **`SITE_ROOT` is baked into ping URLs** — changing it post-deploy breaks any cron jobs already using old URLs. Pick permanently.
- **Grace time tuning** — too short = false alarms; too long = delayed discovery. For a 24h cron, grace of 1-2h is typical.
- **Ping URLs are unguessable** but not secret — they're shareable UUIDs. Treat like API keys but not passwords. Rotate via check editing if exposed.
- **Email delivery matters** — if SMTP is broken, you won't hear about failing checks. Test SMTP once a week via a dummy failing check.
- **`REGISTRATION_OPEN=True`** + public instance = anyone can sign up + create checks on your server. Set `False` for personal/team-only instances.
- **Superuser auto-create** via `SUPERUSER_EMAIL` / `SUPERUSER_PASSWORD` env only works on first boot. After that, use `manage.py createsuperuser` in a shell.
- **Rate limit ping endpoint**: without limits, a broken job calling ping URL in a loop can spam your Postgres (100 pings/sec). Upstream rate-limits per IP; fine-tune if needed.
- **WebAuthn 2FA** is supported — enable for admin accounts. TOTP also works.
- **PagerDuty integration** uses Events API v2 — configure in PagerDuty first, paste integration key into Healthchecks.
- **Slack integration deprecation**: the "Slack Incoming Webhook" integration is legacy. Modern Slack integrations use the OAuth app path. Read upstream docs.
- **Historical ping retention**: configurable via `PING_BODY_LIMIT` + DB pruning policy. Default keeps ~30-100 pings per check.
- **Badges** are public but use hard-to-guess URLs. Safe to embed in public READMEs/dashboards.
- **Cron-expression parsing** uses [cronsim](https://github.com/cuu508/cronsim) (written by the same author as Healthchecks). Supports ranges, `*/N`, named months/days, but NOT Vixie-cron extensions like `@reboot`.
- **Timezone per-check**: each check has a timezone setting — crucial for "run every day at 03:00 local time" semantics.
- **Don't run Healthchecks on the same host as the cron jobs it monitors** — defeats the purpose. A hosted instance or a different VM is wiser.
- **BSD-3-Clause license** — permissive.
- **Alternatives worth knowing:**
  - **Hosted healthchecks.io** — same code; managed; 20 checks free
  - **Cronitor** — commercial SaaS with deeper timeseries
  - **Dead Man's Snitch** — commercial
  - **Oh Dear!** — commercial broader monitoring
  - **Uptime Robot / Better Uptime / Pingdom** — uptime monitors (different angle)
  - **Gatus / Uptime Kuma** — HTTP uptime monitoring; can poll endpoints but don't natively do "dead-man's switch" pattern (separate recipes)
  - **Prometheus Pushgateway** — similar concept; DIY alerting required
  - **Cronicle** — web UI + scheduler + history (runs jobs, not just monitors)
  - **Choose Healthchecks if:** you want simple HTTP-based dead-man's-switch monitoring with rich alert integrations.
  - **Pair with Gatus/Kuma** for complete coverage: Healthchecks for "did my job run?"; Gatus for "is my service up?"

## Links

- Repo: <https://github.com/healthchecks/healthchecks>
- Website: <https://healthchecks.io>
- Docker image: <https://hub.docker.com/r/healthchecks/healthchecks>
- Docker setup docs: <https://github.com/healthchecks/healthchecks/tree/master/docker>
- Self-hosted setup guide: <https://github.com/healthchecks/healthchecks#self-hosted>
- API reference: <https://healthchecks.io/docs/api/>
- Integrations list: <https://healthchecks.io/docs/integrations/>
- Cron syntax helper: <https://healthchecks.io/docs/cron_syntax_cheatsheet/>
- `runitor` (shell wrapper): <https://github.com/bdd/runitor>
- cronsim library: <https://github.com/cuu508/cronsim>
- Releases: <https://github.com/healthchecks/healthchecks/releases>
- Translations: <https://hosted.weblate.org/engage/healthchecks/>
