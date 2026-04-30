---
name: MySpeed
description: "Self-hosted speed-test analysis. Records internet speed up to 30 days. Cron-scheduled tests; Ookla/LibreSpeed/Cloudflare servers; Prometheus/Grafana; health-check notifications (email/Signal/WhatsApp/Telegram). gnmyt maintainer. Active; MIT."
---

# MySpeed

MySpeed is **"SpeedTest.net — but self-hosted + historical + analytical"** — a speed-test analysis tool that runs scheduled speed tests + stores results up to 30 days. Clear stats on download/upload/ping; cron-scheduled test intervals; choose between **Ookla, LibreSpeed, and Cloudflare** test servers; multi-server support; health-check notifications via **email, Signal, WhatsApp, or Telegram** on downtime/errors; Prometheus/Grafana integration.

Built + maintained by **gnmyt** (solo German developer, Germany-based). License: **MIT**. Active; multiple contributors; GitHub releases; docs at docs.myspeed.dev; commercial-domain myspeed.dev.

Use cases: (a) **ISP SLA-monitoring** — prove you're not getting promised speed (b) **home-lab network health** — detect congestion, peak-hour throttling (c) **WFH connectivity** — alert when internet degrades below threshold (d) **nice Grafana dashboard** for nerds (e) **ISP-support-ticket evidence** — "here's 30 days of data showing downtime" (f) **Prometheus-integration** into existing monitoring stack (g) **multi-ISP compare** — if you have failover or multiple connections (h) **notification-on-downtime** — real-time alerts for outages.

Features (per README):

- **30-day speed history** (Ookla/LibreSpeed/Cloudflare)
- **Cron scheduled tests**
- **Multi-server support** on one instance
- **Health checks** — notify via email/Signal/WhatsApp/Telegram
- **Prometheus + Grafana** export
- **Statistics view**

- Upstream repo: <https://github.com/gnmyt/MySpeed>
- Website: <https://myspeed.dev>
- Docs: <https://docs.myspeed.dev>
- Linux setup: <https://docs.myspeed.dev/setup/linux>

## Architecture in one minute

- **Node.js** (JavaScript/TypeScript stack)
- **SQLite** — history DB
- **Resource**: low — 100-200MB RAM
- **Port 5216** default

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker**         | **Upstream images**                                             | **Primary**                                                                        |
| Linux (systemd)    | Via install script                                                                    | Alternative                                                                                   |
| Windows            | Installer                                                                                                             | Alternative                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Admin password       | First-boot                                                  | Auth         | Strong                                                                                    |
| Cron schedule        | E.g., every 15 minutes                                      | Config       | More frequent = more ISP load                                                                                    |
| Test-server choice   | Ookla / LibreSpeed / Cloudflare                             | Config       |                                                                                    |
| Notification channels | Email / Signal / WhatsApp / Telegram                                                                                       | Notify       | API keys for each channel                                                                                    |
| SMTP                 | For email alerts                                                                                                      | Notify       |                                                                                    |
| Signal/WhatsApp bot creds | Self-hosted bot OR relay service                                                                                                            | Notify       |                                                                                                                                            |
| Telegram bot token   | BotFather-issued                                                                                                            | Notify       |                                                                                                                                            |

## Install via Docker

Follow: <https://docs.myspeed.dev/setup/linux>

```yaml
services:
  myspeed:
    image: germannewsmaker/myspeed:latest        # **pin version in prod**
    ports: ["5216:5216"]
    volumes:
      - myspeed-data:/myspeed/data
    restart: unless-stopped

volumes:
  myspeed-data: {}
```

## First boot

1. Start container → browse `:5216`
2. Set admin password
3. Choose test server (Ookla/LibreSpeed/Cloudflare)
4. Configure cron schedule (start with 15-minute intervals)
5. Configure notifications (at least one channel)
6. Let run for a few hours → verify history populated
7. Export to Prometheus (optional) → Grafana dashboard
8. Put behind TLS reverse proxy

## Data & config layout

- `/myspeed/data/` — SQLite DB + config
- 30-day rolling retention (configurable)

## Backup

```sh
docker compose exec myspeed sqlite3 /myspeed/data/myspeed.db ".backup /myspeed/data/myspeed-backup.db"
sudo tar czf myspeed-$(date +%F).tgz myspeed-data/
```

## Upgrade

1. Releases: <https://github.com/gnmyt/MySpeed/releases>. Active.
2. Docker: pull + restart; migrations auto-run
3. Check CHANGELOG for breaking changes

## Gotchas

- **SPEED-TEST LOAD ON YOUR ISP**:
  - Each test = full-bandwidth burst
  - Every-15-minute tests = ~100+ tests/day
  - Heavy tests may trigger ISP's fair-use / throttling
  - **Recipe convention: "speed-test-frequency-vs-ISP-fair-use" callout** — don't over-test
  - **NEW recipe convention** (MySpeed 1st)
- **DATA COLLECTED IS NOT HIGHLY SENSITIVE**:
  - Download/upload/ping — not PII
  - But: patterns reveal WFH schedule (peak-use hours), outage windows
  - **Recipe convention: "behavioral-pattern-leakage-via-metrics"** — metrics reveal lifestyle
- **74th tool in hub-of-credentials family — Tier 3 (low density)**:
  - Admin password + notification API keys + SMTP creds + (optional) Signal/WhatsApp/Telegram bot tokens
- **NOTIFICATION-CHANNEL PROLIFERATION**:
  - Signal + WhatsApp + Telegram + email = 4 integrations
  - Each = external API surface + secret
  - **Recipe convention: "multi-notification-channel-complexity" callout**
- **OOKLA + CLOUDFLARE SERVERS = EXTERNAL DEPENDENCIES**:
  - Tests rely on public servers
  - If Ookla/Cloudflare go down → MySpeed fails tests
  - **Fallback**: LibreSpeed on your own LAN
  - **Recipe convention: "external-test-server-dependency" callout**
- **HEALTH-CHECK MEANING**:
  - "Health check" = MySpeed monitoring ITS OWN ability to run tests
  - Not "health of MySpeed" = "health of your internet connection"
  - Clear distinction in UI
- **PROMETHEUS INTEGRATION = OBSERVABILITY-STACK-READY**:
  - Export metrics to existing Prometheus
  - Grafana dashboard templates
  - **Recipe convention: "Prometheus-exporter positive-signal"** — fits monitoring stack
  - **NEW positive-signal convention** (MySpeed 1st)
- **SPEED-TEST AS PROXY FOR "INTERNET HEALTH"**:
  - Good for bandwidth-issues
  - Doesn't detect: DNS issues, routing issues, TLS issues, specific-service outages
  - Complement with: Uptime Kuma (uptime), Netdata (system), smokeping (latency variance)
- **INSTITUTIONAL-STEWARDSHIP**: gnmyt solo + multiple contributors + commercial-domain. **60th tool — sole-maintainer-with-community sub-tier (29th tool).**
- **TRANSPARENT-MAINTENANCE**: active + releases + docs-site + multiple-notification-channels + Prometheus-integration + Linux+Windows. **68th tool in transparent-maintenance family.**
- **SPEED-TEST-CATEGORY:**
  - **MySpeed** — 30-day analysis; Node.js; multi-provider
  - **OpenSpeedTest** (batch 91) — stateless one-shot in-browser
  - **LibreSpeed** — self-hosted test-server + analysis
  - **SpeedTest-tracker** — similar analysis scope; PHP/Laravel
  - **Commercial**: Ookla SpeedTest.net, Fast.com, Cloudflare Speed
- **ALTERNATIVES WORTH KNOWING:**
  - **OpenSpeedTest** — if you want stateless + no-history
  - **LibreSpeed** — if you want self-hosted server-side
  - **SpeedTest-tracker** — if you want PHP/Laravel + similar analysis
  - **Choose MySpeed if:** you want Node.js + 30-day + multi-provider + multi-notification.
- **PROJECT HEALTH**: active + multi-contributor + docs + commercial-domain. Good signals.

## Links

- Repo: <https://github.com/gnmyt/MySpeed>
- Website: <https://myspeed.dev>
- Docs: <https://docs.myspeed.dev>
- OpenSpeedTest (batch 91): <https://github.com/openspeedtest/Speed-Test>
- LibreSpeed: <https://github.com/librespeed/speedtest>
- SpeedTest-tracker: <https://github.com/alexjustesen/speedtest-tracker>
