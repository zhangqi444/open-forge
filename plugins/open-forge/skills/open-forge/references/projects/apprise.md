---
name: Apprise
description: Push-notification gateway that speaks 100+ notification services (Discord, Slack, Pushover, Matrix, Telegram, email, SMS gateways, ntfy, Home Assistant, webhook, …) through a single URL schema. Apprise-API is the self-hosted HTTP server wrapping the library. MIT.
---

# Apprise

Apprise itself is a Python library + CLI that normalizes notification-service quirks behind a single URL schema (`discord://`, `tgram://`, `mailto://`, `ntfy://`, etc.). **Apprise-API** is the companion Flask+Gunicorn container that exposes a stable HTTP endpoint — your app POSTs to `/notify/<key>` and Apprise fans out to every configured URL.

Use cases:

- Self-hosted apps that lack native notification plumbing (many Sonarr/Radarr/*arr stack integrations)
- Homelab alerting: one URL you can hit from anything, dozens of destinations on the receiving side
- Replacing per-service SDKs with a single abstraction

- Library repo: <https://github.com/caronc/apprise>
- Self-host API repo: <https://github.com/caronc/apprise-api>
- Image: `caronc/apprise` on Docker Hub
- Full service URL schema: <https://github.com/caronc/apprise/wiki>

## Compatible install methods

| Infra     | Runtime                     | Notes                                                                       |
| --------- | --------------------------- | --------------------------------------------------------------------------- |
| Single VM | Docker (Apprise-API)        | **Recommended.** Self-hosted notification API on port 8000                   |
| Bare metal (CLI) | `pip install apprise` | For scripts / cron — no server needed                                       |
| Bare metal (library) | `pip install apprise` in your Python app | Use apprise directly instead of running apprise-api     |
| Kubernetes | Plain manifests             | Stateless (with `APPRISE_STATEFUL_MODE=simple` + a PVC for `/config`)       |

## Inputs to collect

| Input                      | Example                                                 | Phase    | Notes                                                                 |
| -------------------------- | ------------------------------------------------------- | -------- | --------------------------------------------------------------------- |
| Port                       | `8000:8000`                                             | Network  | Behind reverse proxy for TLS                                          |
| `/config` volume           | `./config:/config`                                      | Data     | Stored configuration files (one per "key" in simple mode)             |
| `/plugin` volume           | `./plugin:/plugin` (optional)                           | Data     | Custom Python plugins (your own notification service implementations) |
| `/attach` volume           | `./attach:/attach` (optional)                           | Data     | File attachments sent with notifications                              |
| `APPRISE_STATEFUL_MODE`    | `simple` / `hash` / `disabled`                          | Runtime  | `simple` = human-readable filenames; `hash` = opaque keys; `disabled` = no server-side config |
| `APPRISE_WORKER_COUNT`     | `1`–`4`                                                 | Runtime  | Gunicorn workers; `1` is fine for small installs                      |
| `APPRISE_ADMIN`            | `y` / `n`                                               | Runtime  | Enable the web UI for managing config keys                            |
| UID/GID                    | `$(id -u):$(id -g)`                                     | Runtime  | Run as your user to avoid config-file permission pain                 |
| Tokens per service         | Discord webhook, Telegram bot token, etc.               | Config   | One per destination; paste URLs into Apprise config                   |

## Install via Docker Compose (Apprise-API)

From upstream compose + README:

```yaml
services:
  apprise:
    image: caronc/apprise:1.x   # pin; track releases
    container_name: apprise
    restart: unless-stopped
    user: "1000:1000"           # match host file owner for ./config
    ports:
      - "8000:8000"
    environment:
      APPRISE_STATEFUL_MODE: simple
      APPRISE_WORKER_COUNT: "1"
      APPRISE_ADMIN: "y"
      TZ: UTC
    volumes:
      - ./config:/config
      - ./plugin:/plugin
      - ./attach:/attach
```

`docker compose up -d`, browse `http://<host>:8000`. The admin UI lets you create a "configuration key" (e.g. `homelab`) and paste in Apprise-schema URLs line by line.

### Sending notifications

```sh
# POST to a named config
curl -X POST "http://apprise:8000/notify/homelab" \
  -F "body=Backup completed at $(date)" \
  -F "title=Nightly backup"

# Or send directly without storing config (stateless)
curl -X POST "http://apprise:8000/notify" \
  -F "urls=discord://WEBHOOK_ID/WEBHOOK_TOKEN" \
  -F "body=Hello from curl"
```

Apps that natively support Apprise (most *arr tools, Healthchecks.io, Watchtower, Uptime Kuma, Scrutiny, …) just need the URL `http://apprise:8000/notify/<key>`.

## Install via pip (CLI / library)

For scripts and cron:

```sh
pip install apprise
apprise -t "hello" -b "test body" \
  discord://WEBHOOK_ID/WEBHOOK_TOKEN \
  tgram://BOT_TOKEN/CHAT_ID
```

In Python apps:

```python
import apprise
a = apprise.Apprise()
a.add("slack://TOKEN_A/TOKEN_B/TOKEN_C/#channel")
a.add("mailto://user:pass@example.com")
a.notify(title="Alert", body="Disk 80% full")
```

## `APPRISE_STATEFUL_MODE` — the three choices

- **`simple`** — config stored at `/config/<key>.yaml` (or `.txt`). Human-readable; easy to version-control with `/config` mounted from a git-backed path. Default for self-hosters.
- **`hash`** — Apprise hashes the config key into an opaque filename. Safer if untrusted users can create keys via the API (prevents path-traversal-ish mischief).
- **`disabled`** — Apprise-API refuses to store config server-side. All requests must include `urls=…` inline. Fully stateless; no `/config` persistence.

## Supported notification services

Partial list (100+ total, see full list at <https://github.com/caronc/apprise/wiki>):

- **Chat/Push:** Discord, Slack, Matrix, Mattermost, Rocket.Chat, Microsoft Teams, Telegram, WhatsApp, Signal API, Ntfy, Gotify, Pushover, Pushbullet, Pushcut
- **Email/SMS:** mailto (SMTP), SendGrid, Mailgun, SES, Twilio, Vonage, ClickSend, MSG91, Nexmo, many more SMS gateways
- **Mobile:** APNS, FCM, OneSignal
- **Home automation:** Home Assistant, MQTT, BurstSMS, Kavenegar
- **Ops:** PagerDuty, OpsGenie, Splunk, Dapnet, DAPnet, KumuluzEE
- **Social:** Twitter, Reddit, Mastodon, Bluesky
- **Webhook:** `json://`, `xml://`, `form://` for arbitrary POST targets
- **File/log:** `syslog://`, `windows://` (native toast notifications)

Each service has its own URL format — the wiki documents every one.

## Data & config layout

- `/config/*.yaml` or `/config/*.txt` — per-key notification URL bundles
- `/config/store/*` — internal state (rate-limiters, dedup tracking)
- `/plugin/*.py` — custom notification plugins (drop-in Python modules)
- `/attach/*` — any files you POST as attachments land here

## Backup

```sh
# Config is tiny and version-control-friendly — keep it in git
cd ./config
git init && git add . && git commit -m "apprise config"

# Or tarball
tar czf apprise-config-$(date +%F).tgz ./config ./plugin
```

No database; backup = config directory.

## Upgrade

1. Releases: <https://github.com/caronc/apprise/releases> (library) and <https://github.com/caronc/apprise-api/releases> (API server).
2. Bump image tag, `docker compose pull && docker compose up -d`.
3. Config format is stable across releases — upgrades are low-risk.
4. Config keys are forward-compatible; new service URLs require the matching library version.

## Gotchas

- **Token leakage via logs.** Apprise-API logs full POST bodies at DEBUG level; your Discord/Slack tokens end up in container logs if verbose logging is enabled. Keep log level at `INFO` in production.
- **`APPRISE_STATEFUL_MODE=simple` + public access = config-file enumeration risk.** If the API is publicly reachable, anyone can POST to `/notify/<anything>` and see which keys return 200. Lock behind auth (reverse proxy basic-auth or `APPRISE_DENY_SERVICES` / network isolation).
- **No built-in auth.** Apprise-API trusts anything that can reach port 8000. Never expose it directly to the internet; put behind reverse proxy + auth.
- **User/permissions gotcha.** Default container runs as UID 1000; if your host `./config` is owned by a different UID, writes fail silently. Match with `--user` flag or `user:` key in compose.
- **`APPRISE_WORKER_COUNT` scaling.** One worker handles hundreds of reqs/sec for most services (Apprise is I/O-bound on third-party APIs). Increase only if you're running sync calls to slow services + experiencing queue pile-up.
- **Attachments are multipart-form-data.** Some *arr apps / generic webhook senders can't send multipart — they'll POST JSON only. Apprise-API accepts JSON POSTs too (`Content-Type: application/json`), but attachments then must be URLs, not file uploads.
- **Service-specific gotchas** (documented per-service in the wiki): Discord rate limits 30 req/s per webhook; Slack deprecates incoming-webhooks for new apps; Mailto over TLS sometimes needs `smtp://…?secure=starttls`.
- **Signal via `signal://`** uses an external signal-cli-rest-api container — you run that separately. Apprise itself doesn't know how to talk Signal's protocol.
- **Matrix via `matrix://` vs `matrixs://`.** HTTPS flavor is `matrixs://` — using plain `matrix://` against an HTTPS homeserver silently fails.
- **Telegram bot must be granted permission to write to the target chat.** Apprise sends fine; Telegram drops the message. Invite the bot to the group or start a DM before testing.
- **Custom plugins mounted at `/plugin/`** must be importable Python modules (not packages). Bad imports crash the worker on startup.
- **Don't confuse with Ntfy.** Ntfy is itself a notification service that Apprise can send *to* (via `ntfy://`). Apprise-API is a sender; Ntfy is a receiver. Many people run both: apps → Apprise → Ntfy (public endpoint) → phone.
- **The library is the real thing.** Apprise-API is a thin HTTP wrapper — if you can embed `apprise` directly in Python, do that instead of running another container.
- **YAML vs TXT config.** `/config/<key>.yaml` allows per-URL tags + scheduling; `/config/<key>.txt` is one URL per line. The web admin UI writes YAML; hand-edits work in either format.

## Links

- Apprise library: <https://github.com/caronc/apprise>
- Apprise-API (self-host): <https://github.com/caronc/apprise-api>
- Service URL schema wiki: <https://github.com/caronc/apprise/wiki>
- Releases (library): <https://github.com/caronc/apprise/releases>
- Releases (API): <https://github.com/caronc/apprise-api/releases>
- Docker Hub: <https://hub.docker.com/r/caronc/apprise>
- Env var reference: <https://github.com/caronc/apprise-api/blob/master/README.md>
