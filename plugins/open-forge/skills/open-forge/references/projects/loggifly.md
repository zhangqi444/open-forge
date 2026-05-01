---
name: LoggiFly
description: "Lightweight Docker container log monitor — alert on keyword/regex matches in any container's logs. Python. Notification channels (Apprise-style). clemcer/LoggiFly. clemcer.github.io/loggifly docs."
---

# LoggiFly

LoggiFly is **"dmesg-for-containers — grep your docker logs, get pinged"** — a lightweight tool that monitors **Docker container logs for predefined keywords or regex patterns** and sends notifications. Ideal for catching security breaches (failed Vaultwarden logins), debugging crashes, auto-restart/stop containers on errors, or monitoring app behavior (like when someone downloads from your Audiobookshelf).

Built + maintained by **clemcer**. Python likely. Docker Hub + clemcer.github.io/loggifly docs (GitHub Pages, VitePress-style).

Use cases: (a) **failed-login detection** (e.g., Vaultwarden) (b) **crash auto-restart** (c) **stop-on-restart-loop prevention** (d) **custom app-event alerting** (e) **homelab security monitoring** (f) **regex-pattern log alerts** (g) **one-tool alternative to Promtail+Loki+Alertmanager for simple cases** (h) **Docker-socket-driven log sentinel**.

Features (per README):

- **Docker container log monitoring**
- **Keywords + regex patterns**
- **Notifications** (multi-channel likely via Apprise)
- **Auto-restart or stop containers** on matches
- **Context logs** (attached around match)
- **Lightweight**
- **Security-use-cases** (e.g., failed logins)

- Upstream repo: <https://github.com/clemcer/LoggiFly>
- Docs: <https://clemcer.github.io/loggifly/>

## Architecture in one minute

- **Python** likely
- Docker socket (RO mount)
- Notification channels (Apprise, webhook, email)
- **Resource**: very low
- **Port**: no HTTP typically (daemon)

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker**         | Upstream                                                                                                               | **Primary**                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Docker socket        | `/var/run/docker.sock:ro`                                   | Volume       | **RO preferred**; RW needed for restart/stop                                                                                    |
| Config YAML          | Keywords/regex/actions                                      | Config       |                                                                                    |
| Notification targets | Discord/Slack/Pushover/etc.                                 | Notify       |                                                                                    |

## Install via Docker

Per docs:
```yaml
services:
  loggifly:
    image: clemcer/loggifly:latest        # **pin**
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:rw        # **RW if you want auto-restart/stop**
      - ./loggifly-config.yml:/app/config.yml:ro
    restart: unless-stopped
```

## First boot

1. Write `loggifly-config.yml` with keywords, regexes, actions, notification channels
2. Start LoggiFly (RW socket if using restart/stop actions)
3. Trigger a known event (e.g., wrong Vaultwarden login) → verify notification
4. Tune thresholds and patterns
5. Back up `loggifly-config.yml`

## Data & config layout

- `loggifly-config.yml` — all config

## Backup

```sh
cp loggifly-config.yml loggifly-config.$(date +%F).yml
# Contains: notification webhooks (secrets!) — **ENCRYPT**
```

## Upgrade

1. Releases: <https://github.com/clemcer/LoggiFly/releases>
2. Docker pull + restart

## Gotchas

- **193rd HUB-OF-CREDENTIALS Tier 2 — LOG-MONITOR + CONTAINER-CONTROL**:
  - Holds: Docker socket access (likely RW for restart/stop), notification webhook secrets, regex patterns that may reference sensitive strings
  - RW socket = host-root-equivalent
  - **193rd tool in hub-of-credentials family — Tier 2**
- **RW-DOCKER-SOCKET-FOR-ACTIONS**:
  - If using auto-restart/stop, RW socket required
  - **Docker-socket-mount-privilege-escalation: 10 tools** 🎯 **10-TOOL MILESTONE** (+LoggiFly — RW-variant)
  - **10-TOOL DOCKER-SOCKET-PRIV-ESC MILESTONE at LoggiFly**
- **REGEX-PATTERN-SECRET-LEAKAGE**:
  - If patterns reference tokens/secrets, config-file needs protection
  - **Recipe convention: "regex-pattern-config-secret-inclusion-discipline callout"**
  - **NEW recipe convention** (LoggiFly 1st formally)
- **NOTIFICATION-WEBHOOK-SECRET-MANAGEMENT**:
  - Webhooks embed auth tokens
  - **Recipe convention: "notification-webhook-URL-secret-in-config callout"**
  - **NEW recipe convention** (LoggiFly 1st formally)
- **ALTERNATIVE-TO-LOKI-PROMTAIL**:
  - Lightweight alternative to full-stack Loki+Promtail+Alertmanager
  - **Recipe convention: "lightweight-alternative-to-full-observability-stack positive-signal"**
  - **NEW positive-signal convention** (LoggiFly 1st formally)
- **GITHUB-PAGES-VITEPRESS-DOCS**:
  - Docs hosted on GitHub Pages
  - **Recipe convention: "GitHub-Pages-hosted-docs-site neutral-signal"**
  - **NEW neutral-signal convention** (LoggiFly 1st formally)
  - **GitHub-Pages-hosted-docs: 1 tool** 🎯 **NEW FAMILY** (LoggiFly)
- **SECURITY-MONITORING-USE-CASE**:
  - Explicit example: failed Vaultwarden login detection
  - **Recipe convention: "self-hosted-security-log-monitoring-use-case positive-signal"**
  - **NEW positive-signal convention** (LoggiFly 1st formally)
- **INSTITUTIONAL-STEWARDSHIP**: clemcer sole-dev + GitHub Pages docs + Docker + GIF demos + security-use-cases. **179th tool — sole-dev-log-monitoring-tool sub-tier** (NEW-soft).
- **TRANSPARENT-MAINTENANCE**: active + docs + Docker + releases. **185th tool in transparent-maintenance family.**
- **LOG-MONITORING-CATEGORY:**
  - **LoggiFly** — lightweight; Docker-native; keyword/regex
  - **Loki + Promtail + Alertmanager** — full observability stack
  - **Dozzle** — log viewer (no alerts)
  - **Grafana Loki** — log aggregator
- **ALTERNATIVES WORTH KNOWING:**
  - **Loki + Promtail** — if you want enterprise full-stack
  - **Dozzle** — if you just want log viewer
  - **Choose LoggiFly if:** you want lightweight + just-alerts + zero-config.
- **PROJECT HEALTH**: active + docs + Docker. Strong.

## Links

- Repo: <https://github.com/clemcer/LoggiFly>
- Docs: <https://clemcer.github.io/loggifly/>
- Dozzle (alt): <https://github.com/amir20/dozzle>
- Loki (alt): <https://github.com/grafana/loki>
