---
name: Scrutiny
description: "Web UI for S.M.A.R.T. hard drive monitoring — dashboards over smartd/smartctl. Customized thresholds from real-world failure rates (Backblaze), historical trends, temperature tracking, webhook alerts. Hub/spoke architecture (Collector agents → Hub). Go + InfluxDB. MIT."
---

# Scrutiny

Scrutiny is a **web dashboard + alerting on top of S.M.A.R.T. data** — the hard-drive self-health metrics that `smartd`/`smartctl` already expose. What Scrutiny adds: pretty dashboards, historical trends, thresholds informed by **real-world failure rate data** (Backblaze's public drive stats), temperature tracking, and webhook/notification alerts when drives start misbehaving.

Problems Scrutiny solves:

- `smartd` is CLI only — not friendly for headless servers / homelabs
- Vendor-set S.M.A.R.T. thresholds are often "only fails when already broken"
- No history — you can't see a slow degradation without external logging
- No differentiation between critical vs informational attributes

Features:

- **Web UI dashboard** — all drives, status summary, drill-down
- **Smart-ass thresholds** from Backblaze failure-rate data (not just manufacturer defaults)
- **Historical trends** — attribute values over time
- **Temperature tracking**
- **All-in-one Docker image** (bundled hub + collector)
- **Distributed mode** — Collector agents on many hosts → central Hub
- **Alerts** via webhook / Shoutrrr (Slack, Discord, Telegram, Pushover, Email, Matrix, generic webhook)
- **Auto-detect all connected drives**
- **Scheduled SMART tests** — short + long
- **Multiple filesystems supported** — iSCSI, NVMe, SATA, SAS, USB-connected (with caveats)

- Upstream repo: <https://github.com/AnalogJ/scrutiny>
- Docker Hub: <https://hub.docker.com/r/analogj/scrutiny>
- Docs: <https://github.com/AnalogJ/scrutiny/blob/master/README.md>
- Wiki: <https://github.com/AnalogJ/scrutiny/wiki>

## Architecture in one minute

- **Hub** (Go binary): web UI + API + InfluxDB store
- **Collector** (Go binary): runs `smartctl` on each monitored host; pushes to Hub
- **InfluxDB** (v2): time-series storage for SMART attributes
- **Deployment**:
  - **Omnibus / all-in-one image** — Hub + Collector + InfluxDB in one container on one host (simplest; monitors that host only)
  - **Split architecture** — Hub container on a central server + Collector containers on each monitored host pushing to Hub
- Runs on Linux (Docker or bare binary); collector needs privileged access to smartctl

## Compatible install methods

| Infra           | Runtime                                          | Notes                                                           |
| --------------- | ------------------------------------------------ | --------------------------------------------------------------- |
| Single host     | **Docker all-in-one (`analogj/scrutiny:omnibus`)**   | **Simplest** — monitors drives on same host                           |
| Multi-host      | **Hub + multiple Collectors**                           | Central dashboard for all your servers                                     |
| Bare metal      | Binaries from releases                                       | systemd service; for minimal-Docker environments                                 |
| Kubernetes      | Hub on cluster + Collector DaemonSet on each node                    | Monitor the physical nodes' drives                                                       |
| Raspberry Pi    | arm64 Docker                                                              | Works; great for NAS-on-Pi                                                                      |

## Inputs to collect

| Input           | Example                           | Phase      | Notes                                                            |
| --------------- | --------------------------------- | ---------- | ---------------------------------------------------------------- |
| Domain          | `drives.example.com`                | URL        | Reverse proxy with TLS; internal-only ideally                        |
| Privileged mode | required for collector                    | Container  | Collector needs `--privileged` or `/dev` + capabilities                  |
| `/run/udev`     | host-mount into collector                     | Host       | Helps detect drives                                                                  |
| SMART schedule  | `0 0 * * * *` (cron)                            | Schedule   | Collector cron inside container                                                           |
| API endpoint    | `http://hub:8080/api`                             | Distributed| For remote collectors                                                                               |
| Notifications   | webhook URL(s) (Shoutrrr format)                      | Alerts     | See Shoutrrr docs for format                                                                              |
| InfluxDB        | bundled in omnibus; or external                            | Storage    | Retention defaults to 2 weeks raw + 52 weeks aggregated                                                                   |

## Install — Omnibus (all-in-one, single host)

```sh
docker run -d --name scrutiny \
  --cap-add SYS_RAWIO \
  --cap-add SYS_ADMIN \
  -p 8080:8080 \
  -v /run/udev:/run/udev:ro \
  -v /opt/scrutiny/config:/opt/scrutiny/config \
  -v /opt/scrutiny/influxdb:/opt/scrutiny/influxdb \
  -v /dev/disk:/dev/disk \
  --device=/dev/sda \
  --device=/dev/sdb \
  analogj/scrutiny:master-omnibus   # pin in prod
```

Add `--device=/dev/sdX` for each drive; or use `--privileged` to simplify (less secure).

## Install — Docker Compose (omnibus)

```yaml
services:
  scrutiny:
    image: ghcr.io/analogj/scrutiny:master-omnibus    # pin specific version
    container_name: scrutiny
    restart: unless-stopped
    cap_add:
      - SYS_RAWIO
      - SYS_ADMIN
    ports:
      - "8080:8080"
    volumes:
      - /run/udev:/run/udev:ro
      - ./config:/opt/scrutiny/config
      - ./influxdb:/opt/scrutiny/influxdb
      - /dev/disk:/dev/disk
    devices:
      - /dev/sda
      - /dev/sdb
      - /dev/nvme0
```

## Install — Hub + Collector (multi-host)

```yaml
# On central monitoring host:
services:
  hub:
    image: ghcr.io/analogj/scrutiny:master-web
    restart: unless-stopped
    ports:
      - "8080:8080"
    volumes:
      - ./config:/opt/scrutiny/config
      - ./influxdb:/opt/scrutiny/influxdb
```

```yaml
# On each host with drives to monitor:
services:
  collector:
    image: ghcr.io/analogj/scrutiny:master-collector
    restart: unless-stopped
    cap_add: [SYS_RAWIO, SYS_ADMIN]
    volumes:
      - /run/udev:/run/udev:ro
    devices:
      - /dev/sda
      - /dev/sdb
    environment:
      COLLECTOR_API_ENDPOINT: http://<hub-host>:8080
      COLLECTOR_CRON_SCHEDULE: "0 0 * * * *"
```

## First boot

1. Browse `http://<host>:8080/`
2. Collector runs on first start (or schedule) → drives appear on dashboard
3. Click a drive → attributes, graphs, test history
4. **Settings → Notifications** → add Shoutrrr URL(s)  
   Examples:
   - `discord://<token>@<channel>`
   - `telegram://<bot-token>@telegram?chats=<chat-id>`
   - `pushover://shoutrrr:<api-token>@<user-key>`
   - `smtp://user:pass@smtp.example.com:587/?from=alerts@example.com&to=you@example.com`
   - `generic+https://hook.example.com/path`
5. Run a manual short/long SMART test from the UI
6. (Optional) Tune thresholds per drive in Settings

## Data & config layout

- `config/` — Scrutiny config (`scrutiny.yaml`)
- `influxdb/` — time-series DB (biggest volume over time)
- Drives themselves are read-only (Scrutiny only reads SMART; doesn't write to drives)

## Backup

```sh
# Config + InfluxDB (SMART history)
tar czf scrutiny-$(date +%F).tgz config/ influxdb/
```

Losing InfluxDB = losing historical trends (current status still re-reads on next scan).

## Upgrade

1. Releases: <https://github.com/AnalogJ/scrutiny/releases>.
2. **Hub + Collectors should match major versions.** Mixing versions can cause API incompatibilities.
3. Docker: bump tags, `docker compose pull && docker compose up -d`.
4. Breaking InfluxDB schema changes have happened around v1.x bumps — read release notes.

## Gotchas

- **"Work in Progress" upstream note** — Scrutiny is functional and widely deployed, but the README calls out rough edges. Expect occasional quirks + active development.
- **Privileged access required** — the collector needs `SYS_RAWIO` + `SYS_ADMIN` (or `--privileged`) to run `smartctl`. This is a real privilege; scope it tightly if multi-tenant host.
- **USB-connected drives** often report bogus SMART or nothing at all. USB-to-SATA adapters may need `-d sat` or specific `-d` type hints. Edit `scrutiny.yaml` with per-device overrides if auto-detect fails.
- **NVMe drives** — supported; use `--device=/dev/nvme0` (not `/dev/nvme0n1`). Some NVMe SMART attributes are NVMe-specific and shown differently.
- **RAID cards / HBAs** — drives behind LSI / 3ware / Adaptec / Areca / cciss may need special smartctl flags. See smartctl manpage + Scrutiny device config overrides.
- **Temperature alerts** — default thresholds are reasonable but drive-family dependent. Enterprise drives often run hotter than consumer. Tune per drive.
- **Real-world failure rates** — Scrutiny's better-than-vendor thresholds come from Backblaze's public drive stats. Great idea; but if you run drive models Backblaze doesn't use (enterprise SAS, some NAS models), fallback thresholds are vendor defaults.
- **Retention**: InfluxDB stores raw for ~2 weeks + downsampled for 1 year by default. Tune in config for longer retention.
- **Alerts require Shoutrrr URL format** — not raw webhook URLs (for most channels). Learn Shoutrrr: <https://containrrr.dev/shoutrrr/>.
- **Alert noise**: first deployment will often fire for drives with "old" non-critical SMART attribute values. Tune thresholds, mute known-benign attributes.
- **Temperature history is surprisingly useful** — early indicator of cooling issues long before any SMART failure.
- **Scrutiny ≠ filesystem scrub**: SMART tells you about the DRIVE; ZFS scrub/btrfs scrub tells you about the DATA. Run both.
- **Schedule SMART tests** — short self-test weekly, long self-test monthly. Configured in Scrutiny + passed to smartctl.
- **License**: MIT.
- **Alternatives worth knowing:**
  - **smartd + email alerts** (native) — no UI, but rock-solid
  - **OpenMediaVault SMART plugin** — built-in if you're already on OMV
  - **unRAID disk health** — built-in if on unRAID
  - **TrueNAS disk health** — built-in
  - **Netdata** — broader monitoring with SMART as one module (separate recipe)
  - **Prometheus + smartmon textfile collector** — DIY metrics
  - **GSmartControl** (desktop GUI) — for one-off checks
  - **Choose Scrutiny if:** you want a polished web dashboard + history + alerts specifically for drive health.
  - **Choose smartd + email if:** you're CLI-only and don't want a web UI.
  - **Choose Netdata/Prometheus if:** you want SMART as part of a broader observability stack.

## Links

- Repo: <https://github.com/AnalogJ/scrutiny>
- Docker Hub: <https://hub.docker.com/r/analogj/scrutiny>
- Wiki: <https://github.com/AnalogJ/scrutiny/wiki>
- Install guide: <https://github.com/AnalogJ/scrutiny#getting-started>
- Hub + Collector docs: <https://github.com/AnalogJ/scrutiny/blob/master/docs/INSTALL_HUB_SPOKE.md>
- Config reference: <https://github.com/AnalogJ/scrutiny/blob/master/example.scrutiny.yaml>
- Releases: <https://github.com/AnalogJ/scrutiny/releases>
- Shoutrrr: <https://containrrr.dev/shoutrrr/>
- Backblaze drive stats: <https://www.backblaze.com/b2/hard-drive-test-data.html>
- smartmontools: <https://www.smartmontools.org>
- Dashboard screenshot: <https://imgur.com/a/5k8qMzS>
