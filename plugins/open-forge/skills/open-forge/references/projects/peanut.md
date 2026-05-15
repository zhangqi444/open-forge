---
name: PeaNUT
description: "Tiny dashboard for Network UPS Tools (NUT). Docker. Next.js. Brandawg93/PeaNUT. Real-time UPS monitoring, InfluxDB/Prometheus/Grafana integration, Homepage widgets, multi-UPS."
---

# PeaNUT

**A tiny dashboard for Network UPS Tools (NUT).** Monitor UPS devices connected to your network via NUT, view real-time status and statistics, execute UPS commands, configure via UI or YAML, access NUT terminal, and integrate with InfluxDB v2, Prometheus, or Grafana. Homepage widget support. Multi-UPS.

Built + maintained by **Brandawg93**.

- Upstream repo: <https://github.com/Brandawg93/PeaNUT>
- Docker Hub: <https://hub.docker.com/r/brandawg93/peanut>
- Wiki: <https://github.com/Brandawg93/PeaNUT/wiki>

## Architecture in one minute

- **Next.js** web app (frontend + API)
- Port **8080** (configurable via `WEB_PORT`)
- Connects to a **NUT server** (Network UPS Tools daemon, typically `upsd`) via the NUT protocol
- **No database** — all data fetched live from NUT; InfluxDB optional for historical metrics
- Multi-arch: `linux/amd64`, `linux/arm64` (Pi 4+)
- Resource: **tiny** — Next.js app; stateless (no local DB)

## Prerequisites

- A running **NUT server** (`upsd`) with at least one configured UPS
- NUT client access from the PeaNUT container to the NUT server (host + port + credentials)
- **Note:** PeaNUT is a dashboard only — it does not replace or install NUT itself

## Compatible install methods

| Infra        | Runtime                    | Notes                                        |
| ------------ | -------------------------- | -------------------------------------------- |
| **Docker**   | `brandawg93/peanut`        | **Primary** — Docker Hub                     |
| **Source**   | pnpm build + start         | For development; see wiki                    |

## Inputs to collect

| Input                    | Example                          | Phase    | Notes                                                                                            |
| ------------------------ | -------------------------------- | -------- | ------------------------------------------------------------------------------------------------ |
| NUT server host          | `192.168.1.10` or `nut-server`   | Config   | IP/hostname of your NUT server; `localhost` won't work inside a container unless host networking |
| NUT server port          | `3493`                           | Config   | NUT default port                                                                                 |
| NUT username + password  | `upsmon` / `secret`              | Config   | From your NUT `upsd.users` config                                                                |
| UPS name(s)              | `ups`                            | Config   | As defined in NUT's `ups.conf`                                                                   |
| Domain                   | `ups.example.com`                | URL      | Optional reverse proxy + TLS                                                                     |
| InfluxDB URL + token (optional) | `http://influxdb:8086`  | Monitor  | For historical metrics via Grafana                                                               |

## Install via Docker

```bash
docker run \
  -v ${PWD}/config:/config \
  -p 8080:8080 \
  --restart unless-stopped \
  --env WEB_PORT=8080 \
  brandawg93/peanut
```

## Install via Docker Compose

```yaml
services:
  peanut:
    image: brandawg93/peanut:6.0.0
    container_name: PeaNUT
    restart: unless-stopped
    volumes:
      - /path/to/config:/config    # persistent config; must be writable by UID 1000
    ports:
      - 8080:8080
    environment:
      - WEB_PORT=8080
```

> ⚠️ **Volume permissions**: PeaNUT container runs as UID/GID 1000. The host `/config` directory must be writable by that user. If you see `EACCES: permission denied, access '/config'`, run `chown -R 1000:1000 /path/to/config` on the host. `PUID`/`PGID` env vars are **not supported**.

## First boot

1. Deploy container.
2. Visit `http://localhost:8080`.
3. Configure NUT server connection (Settings → NUT Config): host, port, username, password, UPS name(s).
4. Dashboard appears with live UPS status.
5. Optionally configure InfluxDB connection for metrics history + Grafana dashboards.
6. Optionally set up Homepage widget (docs in wiki).
7. Set `WEB_USERNAME` + `WEB_PASSWORD` for web UI authentication (or `AUTH_DISABLED=true` for LAN-only).

## Environment variables

| Variable            | Default   | Description |
| ------------------- | --------- | ----------- |
| `WEB_PORT`          | `8080`    | Listen port |
| `WEB_HOST`          | `localhost` | Bind host |
| `WEB_USERNAME`      | —         | Initial web UI username (auto-creates on first start) |
| `WEB_PASSWORD`      | —         | Initial web UI password |
| `AUTH_DISABLED`     | `false`   | `true` to disable login (trusted LAN only) |
| `BASE_PATH`         | —         | Reverse proxy base path (e.g. `/ups`) |
| `SSL_CERT_PATH`     | —         | Path to TLS cert (if serving HTTPS directly) |
| `SSL_KEY_PATH`      | —         | Path to TLS key |

## Data & config layout

- `/config/` — NUT connection settings + dashboard customization (YAML-configurable)

## Backup

```sh
sudo cp -r /path/to/config/ peanut-config-backup-$(date +%F)/
```

Contents: NUT server credentials (minimal sensitivity). No UPS data stored locally — fetched live.

## Upgrade

1. Releases: <https://github.com/Brandawg93/PeaNUT/releases>
2. **Note:** From v5.17.0, Raspberry Pi 3 and older (arm/v7) are no longer supported. Use arm64 (Pi 4+).
3. `docker compose pull && docker compose up -d`

## Gotchas

- **PeaNUT doesn't include NUT.** It's a dashboard for an existing NUT server. You must have NUT installed and configured (`upsd`, `ups.conf`, `upsd.users`) separately on the machine connected to your UPS hardware.
- **Container-to-NUT networking.** If NUT runs on the same machine as PeaNUT, use `host.docker.internal` (macOS/Windows) or the host's LAN IP — not `localhost`, which resolves to the container itself. Or use `network_mode: host`.
- **UID 1000 permission requirement.** The container hardcodes UID 1000. `PUID`/`PGID` env vars do nothing. Fix the host directory permissions with `chown`.
- **`AUTH_DISABLED=true` for trusted LAN only.** Without authentication, anyone on your network can view UPS status and issue commands. Enable auth for any public-facing deploy.
- **Raspberry Pi 3 dropped in v5.17.0.** arm/v7 support removed — upgrade to Pi 4+ or use an older pinned tag.
- **InfluxDB v2 only.** If you use InfluxDB v1, you need to migrate or stick with v1-compatible alternatives (or skip InfluxDB integration).
- **NUT terminal access.** PeaNUT provides a browser-accessible terminal to the NUT server — useful for `upscmd` / `upsrw` commands. Be aware this gives direct control over UPS commands (load off, beeper, etc.).

## Project health

Active Next.js development, Docker Hub CI, multi-arch (amd64/arm64), InfluxDB + Prometheus + Grafana + Homepage integrations, SonarCloud quality gate. Solo-maintained by Brandawg93.

## UPS-monitoring-family comparison

- **PeaNUT** — Next.js, NUT client, real-time dashboard, InfluxDB/Prometheus/Grafana, Homepage widgets
- **NUT's built-in web interface** — minimal; rarely deployed
- **Uptime Kuma** — monitors services; has a UPS-style monitor but not NUT-specific
- **Grafana + NUT exporter** — full metrics stack; more complex setup; no dedicated dashboard UI
- **Network UPS Tools (NUT)** — the backend these all depend on; see <https://networkupstools.org>

**Choose PeaNUT if:** you run NUT for UPS monitoring and want a clean, modern web dashboard with InfluxDB/Prometheus export and Homepage widget support.

## Links

- Repo: <https://github.com/Brandawg93/PeaNUT>
- Docker Hub: <https://hub.docker.com/r/brandawg93/peanut>
- Wiki: <https://github.com/Brandawg93/PeaNUT/wiki>
- NUT (Network UPS Tools): <https://networkupstools.org>
