---
name: Gatus
description: Developer-oriented health dashboard + alerting. Config-as-code (YAML) monitors for HTTP/ICMP/TCP/DNS/SSH/WebSocket; rich condition DSL (status, body, response time, certificate expiry, DNS record); alerts to 40+ providers. Single Go binary. Apache-2.0.
---

# Gatus

Gatus is an opinionated "status page and alerter" built the way a developer would: your monitor definitions live in **YAML**, not a database-backed UI. Check a file in git, deploy, done. No click-ops.

What makes Gatus distinctive:

- **Rich condition DSL** — not just "is this URL 200?" but `[STATUS] == 200 && [RESPONSE_TIME] < 300 && [BODY].version == "1.2.3" && [CERTIFICATE_EXPIRATION] > 240h`
- **Protocol breadth** — HTTP(S), ICMP, TCP, DNS, SSH, WebSocket, STARTTLS. With any of them: assert arbitrary conditions on the response.
- **40+ alert providers** — Discord, Slack, Teams, PagerDuty, Gotify, ntfy, Twilio, email (SMTP/SES), Matrix, Mattermost, Pushover, Telegram, Google Chat, Home Assistant, Opsgenie, Zulip, Datadog, GitHub, GitLab, Gitea, ClickUp, Jira, incident.io, n8n, Line, Messagebird, New Relic, and more
- **Failure thresholds + resolve thresholds** per-endpoint — reduce alert flapping
- **Maintenance windows** — suppress alerts during known work
- **Config reload** on SIGHUP without losing history
- **Cleaner than Uptime Kuma** for infra teams; less friendly for non-devs (no web-based monitor creation)

- Upstream repo: <https://github.com/TwiN/gatus>
- Website: <https://gatus.io> (also a commercial managed offering)
- Docker Hub: <https://hub.docker.com/r/twinproduction/gatus>
- Demo / author's own status: <https://status.twin.sh>

## Architecture in one minute

- **Single Go binary** (also available as `ghcr.io/twin/gatus` or `twinproduction/gatus`)
- Reads **`config.yaml`** (or a directory of YAML files) at startup + on SIGHUP
- Runs each endpoint's health checks on its configured interval
- Evaluates conditions; triggers alerts when `failure-threshold` consecutive failures occur
- Serves a dashboard on **`:8080`**
- **Storage** options:
  - `memory` (default, lost on restart)
  - `sqlite` (single-file, recommended for small-to-mid)
  - `postgres` (prod at scale)

## Compatible install methods

| Infra       | Runtime                                             | Notes                                                              |
| ----------- | --------------------------------------------------- | ------------------------------------------------------------------ |
| Single VM   | Docker / Compose                                      | **Most common**                                                     |
| Kubernetes  | Helm chart (community) OR raw manifests                | Great fit — pairs with `ConfigMap` for config                        |
| Single VM   | Native Go binary (from releases)                        | For embedded / bare VPS                                                |
| Systemd     | Binary + unit file                                      | Lightweight + standard                                                  |

## Inputs to collect

| Input            | Example                                  | Phase     | Notes                                                                |
| ---------------- | ---------------------------------------- | --------- | -------------------------------------------------------------------- |
| Config file      | `config.yaml` OR `/config/*.yaml`          | Config    | Mount at `/config` in container                                         |
| Storage          | `memory` / `sqlite` / `postgres`           | Persistence | History for graphs; memory = reset on restart                             |
| Alerting secrets | per-provider tokens                        | Alerting  | Discord/Slack webhook URLs, SMTP creds, etc.                             |
| UI title/colors  | dashboard branding                         | Branding  | In `config.yaml`                                                         |
| Auth (optional)  | OIDC or basic auth                          | Security  | Dashboard is public by default                                            |
| Port             | `8080`                                     | Network   | Default dashboard port                                                    |

## Install via Docker (quickstart)

Create `/opt/gatus/config/config.yaml`:

```yaml
# config.yaml
storage:
  type: sqlite
  path: /data/gatus.db

endpoints:
  - name: my-website
    url: https://example.com
    interval: 30s
    conditions:
      - "[STATUS] == 200"
      - "[RESPONSE_TIME] < 1000"
      - "[CERTIFICATE_EXPIRATION] > 240h"
    alerts:
      - type: discord
        failure-threshold: 3
        success-threshold: 2

alerting:
  discord:
    webhook-url: "https://discord.com/api/webhooks/..."
    default-alert:
      description: "site down"
      send-on-resolved: true
```

Run:

```sh
docker run -d --name gatus \
  --restart unless-stopped \
  -p 8080:8080 \
  -v /opt/gatus/config:/config \
  -v /opt/gatus/data:/data \
  ghcr.io/twin/gatus:stable    # or pin a specific tag; check GHCR tags
```

## Install via Docker Compose

```yaml
services:
  gatus:
    image: ghcr.io/twin/gatus:stable
    container_name: gatus
    restart: unless-stopped
    ports:
      - "8080:8080"
    volumes:
      - ./config:/config
      - ./data:/data
    environment:
      GATUS_CONFIG_PATH: /config
    # Optional: send SIGHUP to reload without restart:
    # docker compose kill --signal=SIGHUP gatus
```

## Condition DSL cheatsheet

Every endpoint has `conditions:` — all must pass for the endpoint to be considered "up."

```yaml
conditions:
  - "[STATUS] == 200"
  - "[STATUS] < 300"
  - "[RESPONSE_TIME] < 500"                      # ms
  - "[BODY] == pat(*\"version\":\"1.2.3\"*)"      # substring / pattern
  - "[BODY].users[0].id == 1"                    # JSON path
  - "[CERTIFICATE_EXPIRATION] > 168h"             # hours
  - "[DNS_RCODE] == NOERROR"                      # DNS responses
  - "[IP] == 1.1.1.1"                             # ping responses
  - "len([BODY].items) > 0"                       # arrays
  - "[CONNECTED] == true"                         # TCP/STARTTLS connection success
```

Full reference: [Conditions section in upstream README](https://github.com/TwiN/gatus#conditions).

## Endpoint type shortcuts

```yaml
endpoints:
  # HTTP GET
  - name: api
    url: https://api.example.com/health
    conditions: ["[STATUS] == 200"]

  # HTTP POST with body
  - name: api-write
    url: https://api.example.com/echo
    method: POST
    headers:
      Content-Type: application/json
    body: '{"test":"data"}'
    conditions: ["[STATUS] == 200", "[BODY].echo == \"data\""]

  # ICMP ping
  - name: home-server
    url: icmp://192.168.1.1
    conditions: ["[CONNECTED] == true"]

  # TCP socket
  - name: postgres
    url: tcp://db.example.com:5432
    conditions: ["[CONNECTED] == true"]

  # DNS lookup
  - name: dns-record
    url: 1.1.1.1
    dns:
      query-name: example.com
      query-type: A
    conditions: ["[DNS_RCODE] == NOERROR", "[BODY] == 93.184.216.34"]

  # STARTTLS (checks mail server)
  - name: mail-tls
    url: starttls://mail.example.com:25
    conditions: ["[CERTIFICATE_EXPIRATION] > 240h"]
```

## Alert provider examples

```yaml
alerting:
  slack:
    webhook-url: https://hooks.slack.com/services/...
  discord:
    webhook-url: https://discord.com/api/webhooks/...
  ntfy:
    url: https://ntfy.sh
    topic: my-alerts
  email:
    from: gatus@example.com
    username: alerts@example.com
    password: "${SMTP_PASS}"
    host: smtp.example.com
    port: 587
    to: ops@example.com
  pagerduty:
    integration-key: ...
```

## Data & config layout

- `/config/*.yaml` — monitor definitions (split files OK)
- `/data/gatus.db` — SQLite history + state
- No plugin system; everything is in-binary

## Backup

```sh
# Config (version-control it; ideally git)
tar czf gatus-config-$(date +%F).tgz -C /opt/gatus/config .

# SQLite history
sqlite3 /opt/gatus/data/gatus.db ".backup /opt/gatus/data/gatus-$(date +%F).db"
```

**Version-control the config in git.** Gatus is a config-as-code tool — its superpower is reproducibility.

## Upgrade

1. Releases: <https://github.com/TwiN/gatus/releases>. Active.
2. `docker compose pull && docker compose up -d`.
3. Config format is backward-compatible across most minor versions; read release notes for 5.x → 6.x type jumps.
4. SQLite migrations run on startup; back up `.db` first.

## Gotchas

- **`memory` storage loses history on restart.** The dashboard shows "up / down" but no historical graphs after restart. Switch to `sqlite` (small footprint) as soon as you care about graphs.
- **No built-in auth on the dashboard.** Use a reverse proxy with basic auth, Authelia, or OIDC proxy. Gatus does NOT implement auth itself (deliberately — keeps the binary simple).
- **Polling interval × number of endpoints × check cost** adds up. Don't set `interval: 5s` on 200 endpoints unless you've measured.
- **`failure-threshold` and `success-threshold`** are in "number of consecutive checks" — so `failure-threshold: 3` + `interval: 30s` = alert after 90s of failure. Tune per endpoint based on tolerance.
- **Maintenance windows**: `maintenance:` key defines times to suppress alerts. Make sure timezone is set (`TZ=...`).
- **Status page is PUBLIC by default** — if you put monitor details (internal URLs, API paths) in your config, they're exposed. Use `ui.hide-hostname: true` + redact sensitive endpoints, or gate the whole dashboard behind auth.
- **`client:` options** (timeouts, insecure TLS, DNS resolver override) can be set per-endpoint OR globally.
- **Alert grouping** — Gatus doesn't auto-group related alerts. Each endpoint's failure is its own alert. For grouping / routing logic, pair with Alertmanager or a notifier like ntfy that supports deduplication.
- **External endpoints** (NEW in recent versions) let you push status from a script (e.g., a cron job that checks something non-HTTP) to Gatus, which stores + alerts on them.
- **Suites (ALPHA)** group checks that must all pass together — useful for multi-step user journeys (login → fetch profile → logout).
- **Tunnels** via Ngrok, Cloudflare Tunnel, Tailscale Funnel — make your self-hosted Gatus reachable publicly for a friendly status page.
- **Announcements** — banner-style messages you can push via config or API without editing monitors.
- **Not a full incident management** tool — Gatus alerts; it doesn't track "who's on-call" or run incident reviews. Pair with PagerDuty / Opsgenie / incident.io for those.
- **Gatus.io managed service** — the author's hosted Gatus. Useful if you want alerts from an independent host when your own infra is down.
- **Apache 2.0 license** — permissive.
- **Alternatives worth knowing:**
  - **Uptime Kuma** — more popular; web-UI driven; SQLite-backed; "click to add monitor"; less config-as-code
  - **Statping-ng** / **Statping** — PHP/Go status pages; less feature-rich
  - **Upptime** (GitHub Actions-driven) — runs checks in Actions; no server; free via GitHub
  - **Cabot** — older, Django, still in use
  - **Healthchecks.io** (hosted) / **selfhosted Healthchecks** — complementary: "Did my cron run?" dead-man's switch pattern
  - **Prometheus + Blackbox Exporter + Grafana + Alertmanager** — enterprise-grade; more pieces
  - **Zabbix / Nagios / Icinga** — traditional infra monitoring; much heavier
  - **UptimeRobot / Better Uptime / Pingdom** — commercial SaaS
  - **Pick Gatus if you want:** config-as-code, rich condition DSL, breadth of protocols + alert providers, single binary.
  - **Pick Uptime Kuma if you want:** web-UI editing, "non-devs can manage monitors," prettier graphs.

## Links

- Repo: <https://github.com/TwiN/gatus>
- Website: <https://gatus.io>
- Configuration reference: <https://github.com/TwiN/gatus#configuration>
- Conditions reference: <https://github.com/TwiN/gatus#conditions>
- Alerting providers: <https://github.com/TwiN/gatus#alerting>
- Docker Hub: <https://hub.docker.com/r/twinproduction/gatus>
- GHCR: <https://github.com/TwiN/gatus/pkgs/container/gatus>
- Releases: <https://github.com/TwiN/gatus/releases>
- Demo / author's status: <https://status.twin.sh>
- Discussions: <https://github.com/TwiN/gatus/discussions>
- Author's Patreon/Sponsors: <https://github.com/sponsors/TwiN>
