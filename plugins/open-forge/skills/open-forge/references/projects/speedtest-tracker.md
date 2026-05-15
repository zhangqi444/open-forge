---
name: Speedtest Tracker
description: "Self-hosted Internet performance tracker — scheduled speedtests (Ookla + LibreSpeed), historical dashboards, threshold alerts, notifications via many channels. PHP/Laravel (Filament admin). Built by LinuxServer.io. MIT."
---

# Speedtest Tracker

Speedtest Tracker is **the homelab staple for "is my ISP actually giving me the speed I pay for?"** — schedules regular speedtests (Ookla and/or LibreSpeed), stores results, plots history, and fires notifications when performance drops below thresholds. Ships as a **LinuxServer.io Docker image** (well-maintained; security-patched baseline); PHP/Laravel under the hood with a Filament admin UI.

Community-driven + actively maintained by **Alex Justesen** and contributors.

Features:

- **Automated scheduled tests** — configurable cron
- **Ookla + LibreSpeed** — your choice of engine (Ookla = the iconic "speedtest.net", LibreSpeed = open-source alternative)
- **Detailed metrics** — download, upload, ping/latency, jitter, packet loss, server, ISP, external IP
- **Historical data** — dashboards + trends + CSV/JSON export
- **Threshold alerts** — "notify if download <500 Mbps"
- **Notifications via many channels** — Slack, Discord, Telegram, Gotify, Pushover, ntfy, Teams, generic webhooks, email
- **Healthchecks.io integration** — ensure tests are actually running
- **Multi-language** via Crowdin
- **User management** + API tokens
- **REST API** — query results programmatically
- **Filament admin UI** — clean, modern

- Upstream repo: <https://github.com/alexjustesen/speedtest-tracker>
- Docs: <https://docs.speedtest-tracker.dev>
- Installation: <https://docs.speedtest-tracker.dev/getting-started/installation>
- Env vars: <https://docs.speedtest-tracker.dev/getting-started/environment-variables>
- Notifications: <https://docs.speedtest-tracker.dev/settings/notifications>
- FAQ: <https://docs.speedtest-tracker.dev/help/faqs>
- Docker (LinuxServer.io): <https://fleet.linuxserver.io/image?name=linuxserver/speedtest-tracker>
- Crowdin (translations): <https://crowdin.com/project/speedtest-tracker>

## Architecture in one minute

- **PHP 8.x + Laravel + Filament** web UI
- **SQLite** (default, simple) or **MariaDB/MySQL** or **Postgres** for larger history
- **Runs speedtest CLI** — Ookla's `speedtest` binary (bundled in LSIO image) or LibreSpeed CLI
- **Laravel scheduler** handles cron
- **Resource**: small — ~300 MB RAM idle; spikes during tests
- **Outbound traffic** during tests — speedtest picks geographically close servers

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                         |
| ------------------ | -------------------------------------------------------------- | ----------------------------------------------------------------------------- |
| Single VM/NAS      | **Docker (`lscr.io/linuxserver/speedtest-tracker`)**               | **Upstream-recommended**                                                          |
| Synology / QNAP / Unraid | Docker package                                                        | Popular homelab deployment                                                                              |
| Raspberry Pi       | arm64 supported; works fine                                                                 | Natural home-router speedtester                                                                                         |
| Kubernetes         | Community Helm + manifests                                                                                | Supported                                                                                                                     |
| Bare-metal PHP     | Native Laravel install — possible but container is the path of least resistance                                                  |                                                                                                                                                               |

## Inputs to collect

| Input              | Example                              | Phase       | Notes                                                                 |
| ------------------ | ------------------------------------ | ----------- | --------------------------------------------------------------------- |
| Domain             | `speedtest.home.lan`                     | URL         | Behind reverse proxy + TLS                                                    |
| Admin creds        | `APP_NAME=...` + setup wizard                    | Bootstrap   | Strong password                                                                           |
| APP_KEY            | Laravel secret                                                | Security    | Auto-generated or provide via env                                                                                  |
| DB                 | SQLite (default) or MariaDB                                        | DB          | SQLite fine for most                                                                                                         |
| Schedule           | Cron expression, e.g., `0 */6 * * *` every 6h                              | Policy      | Don't over-test — eats bandwidth                                                                                                            |
| Notification channels | Slack/Discord/Telegram webhooks / SMTP                                        | Alerts      | Per docs                                                                                                                                          |

## Install via Docker (LinuxServer.io image)

```yaml
services:
  speedtest-tracker:
    image: lscr.io/linuxserver/speedtest-tracker:v1.14.1-ls150     # pin in prod
    container_name: speedtest-tracker
    restart: unless-stopped
    environment:
      PUID: 1000
      PGID: 1000
      TZ: America/Los_Angeles
      APP_KEY: "base64:..."                              # generate one; see docs
      APP_URL: "https://speedtest.home.lan"
      DB_CONNECTION: sqlite
    volumes:
      - ./config:/config
    ports:
      - "8080:80"
      - "8443:443"
```

Browse `https://<host>:8443/` → log in with default creds (`admin@example.com` / `password` — **change immediately**).

## First boot

1. Browse → log in → **change default admin password NOW**
2. `Settings → Speedtest` → choose engine (Ookla / LibreSpeed) + preferred servers (optional)
3. Set schedule — every 1-4 hours is typical; every 10 min is excessive for ISP monitoring
4. `Settings → Notifications` → add channels (Slack/Discord/Telegram/ntfy/...)
5. Set thresholds — alert if download < X Mbps or ping > Y ms
6. Run manual test → verify metrics land + notifications fire
7. (Optional) configure Healthchecks.io ping to ensure scheduler runs

## Data & config layout

- `/config/` (container) — SQLite DB, app config, results cache, logs
- `/config/.env` — Laravel env vars including `APP_KEY` (**do not lose** — encrypted fields become unreadable)
- Single-directory backup model

## Backup

```sh
sudo tar czf speedtest-tracker-$(date +%F).tgz config/
```

Small DB; backup is trivial. **Preserve `.env` (APP_KEY)** — encrypted fields in DB depend on it.

## Upgrade

1. Releases: <https://github.com/alexjustesen/speedtest-tracker/releases>. Active.
2. Docker: bump tag → restart → Laravel migrations auto.
3. **Back up `config/` first.**
4. LSIO image releases periodically integrate upstream updates.

## Gotchas

- **Default creds**: `admin@example.com` / `password` — change on first login, always. (Batches 68-70: same pattern as Zabbix/GLPI.)
- **Test frequency vs bandwidth cost**: each Ookla test consumes ~500 MB-2 GB of bandwidth. **Tests every 10 min = 100-400 GB/month of "monitoring traffic" alone.** For metered/capped connections (cellular, satellite), this is prohibitive. Default to hourly or less often.
- **ISPs throttle speedtest servers sometimes** — ISP-owned Ookla servers can show artificially high speeds. Prefer third-party Ookla servers or pin specific ones in config.
- **LibreSpeed vs Ookla**: Ookla is the industry standard ISP comparison; LibreSpeed is open-source + privacy-friendlier + self-hostable (can run a LibreSpeed server + test against it for LAN-vs-WAN comparison).
- **APP_KEY loss = decryption loss**: Laravel encrypts sensitive DB fields with `APP_KEY`. **Losing it** (e.g., container recreated without preserved `.env`) **= re-login + re-configure notifications**. Always preserve the config volume.
- **Reverse proxy**: standard Nginx/Caddy/Traefik setup; the container exposes :80 + :443. Set `APP_URL` to match your external URL for correct link generation in notifications.
- **Healthchecks.io ping**: if your speedtests stop running (scheduler died, container wedged), you won't know unless you're actively watching the dashboard. Ping Healthchecks.io from each successful run + alert on missed pings.
- **LinuxServer.io base image**: well-maintained, PUID/PGID mapping is idiomatic for NAS users. Updates to upstream are reflected within days.
- **Server selection**: Ookla picks a "best server" automatically (low latency). You can pin specific servers in admin — helpful if "best" varies week-to-week and skews graphs.
- **Historical comparison**: use the built-in charts; for longer-term analysis, export CSV and chart externally (Grafana + InfluxDB pattern if you're already running that stack).
- **Packet loss**: reported when present; useful for diagnosing VoIP / gaming issues.
- **No Wi-Fi-specific test**: speedtests measure ISP pipe, not Wi-Fi. If Wi-Fi is the bottleneck, wired-connected host to the modem/router is needed to separate concerns.
- **IPv6 vs IPv4**: test both if your ISP offers dual-stack; speedtest may default to one.
- **Notifications noise**: threshold-based alerts are great but can spam during ISP outages. Configure "recovery" notifications too.
- **API rate**: the REST API allows programmatic access — useful for custom dashboards.
- **License**: **MIT**.
- **Alternatives worth knowing:**
  - **Prometheus speedtest exporter + Grafana** — DIY pipeline, more flexible for ops stacks
  - **Netdata** — broader system monitoring, has speedtest plugin
  - **Ookla speedtest CLI + cron + CSV + scripts** — DIY minimal
  - **LibreSpeed standalone** — self-hosted speedtest server; pair with Speedtest Tracker or cron
  - **InfluxDB telegraf plugin** (`internet_speed`) — time-series native
  - **OpenSpeedTest Server** — self-host a speedtest server (different scope)
  - **Home Assistant + Speedtest.net integration** — broader home automation
  - **Choose Speedtest Tracker if:** you want a polished, out-of-the-box ISP monitoring dashboard + notifications.
  - **Choose Prometheus + Grafana if:** you already run that stack + want one place for all metrics.
  - **Choose Home Assistant if:** one of many automations.

## Links

- Repo: <https://github.com/alexjustesen/speedtest-tracker>
- Docs: <https://docs.speedtest-tracker.dev>
- Installation: <https://docs.speedtest-tracker.dev/getting-started/installation>
- Env vars: <https://docs.speedtest-tracker.dev/getting-started/environment-variables>
- Notifications: <https://docs.speedtest-tracker.dev/settings/notifications>
- FAQ: <https://docs.speedtest-tracker.dev/help/faqs>
- Docker (LSIO): <https://fleet.linuxserver.io/image?name=linuxserver/speedtest-tracker>
- Releases: <https://github.com/alexjustesen/speedtest-tracker/releases>
- LibreSpeed: <https://github.com/librespeed/speedtest>
- Ookla CLI: <https://www.speedtest.net/apps/cli>
- Healthchecks.io: <https://healthchecks.io>
- OpenSpeedTest: <https://github.com/openspeedtest/Speed-Test>
