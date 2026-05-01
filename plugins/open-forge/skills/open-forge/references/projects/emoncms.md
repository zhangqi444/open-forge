---
name: Emoncms
description: "Open-source energy monitoring and visualisation web app. Docker. PHP/Apache + MariaDB + Redis + MQTT. emoncms/emoncms. Input processing, feeds, dashboards, solar/EV/heatpump apps. Part of OpenEnergyMonitor."
---

# Emoncms

**Open-source web application for processing, logging, and visualising energy and environmental data.** Core platform for the OpenEnergyMonitor ecosystem. Accepts data from energy monitors (emonPi, emonBase, emonTx) or any sensor via HTTP/MQTT. Configurable input processing pipelines store data as time-series feeds; visualise via graphs, dashboards, and application modules (MySolar, MyElectric, Octopus Agile, HeatPump, EV).

Built + maintained by **OpenEnergyMonitor** community. AGPL license.

- Upstream repo: <https://github.com/emoncms/emoncms>
- Docs: <https://docs.openenergymonitor.org/emoncms>
- Community: <https://community.openenergymonitor.org>
- All-in-one Docker: `alexjunk/emoncms` (<https://hub.docker.com/r/alexjunk/emoncms>)
- Docker Compose repo: <https://github.com/emoncms/emoncms-docker>

## Architecture in one minute

- **PHP 8 / Apache** backend
- **MariaDB / MySQL** + **Redis** databases
- **Mosquitto** MQTT broker
- **Workers:** `emoncms_mqtt`, `service-runner`, `feedwriter`
- Custom time-series engines: **PHPFina** (fixed interval) + **PHPTimeSeries** (variable interval)
- Docker options:
  1. **All-in-one** (`alexjunk/emoncms`) — MariaDB + Redis + Mosquitto + workers in one container; multi-arch (amd64/arm64/armv7)
  2. **Multi-container** (`emoncms/emoncms-docker`) — separate services via Compose
- Resource: **medium** — PHP + MariaDB + Redis; low-write mode available for SD card hosts

## Compatible install methods

| Infra                   | Runtime                            | Notes                                                           |
| ----------------------- | ---------------------------------- | --------------------------------------------------------------- |
| **Docker (all-in-one)** | `alexjunk/emoncms`                 | **Easiest** — everything in one container; multi-arch           |
| **Docker Compose**      | `openenergymonitor/emoncms`        | Multi-container; see emoncms-docker repo                        |
| **emonSD**              | Pre-built Raspberry Pi image       | Official for emonPi/emonBase hardware                           |
| **Bare metal**          | Ubuntu + Apache + PHP              | Dedicated server; see docs                                      |

## Inputs to collect

| Input                        | Example                     | Phase  | Notes                                                             |
| ---------------------------- | --------------------------- | ------ | ----------------------------------------------------------------- |
| `MYSQL_PASSWORD`             | strong random               | DB     | MariaDB password                                                  |
| Data source                  | emonPi / HTTP API / MQTT    | Data   | How sensors post data                                             |
| API key                      | auto-generated post-install | Auth   | Used by devices to POST data                                      |

## Install via all-in-one Docker

```bash
docker pull alexjunk/emoncms
docker run -d \
  --name emoncms \
  -p 80:80 \
  -v emoncms-data:/var/opt/emoncms \
  -v emoncms-mysql:/var/lib/mysql \
  alexjunk/emoncms:latest
```

Visit `http://localhost`. Full Docker docs: <https://emoncms-docker.github.io>

## Install via Docker Compose

Clone `https://github.com/emoncms/emoncms-docker`, copy `.env.example` to `.env`, set passwords, then `docker compose up -d`.

## First boot

1. Visit UI → register admin account.
2. Copy your **API key** (My Account).
3. Configure data source:
   - **emonPi/emonBase:** auto-posts to Emoncms on LAN
   - **HTTP:** `http://host/input/post?node=1&json={power:500}&apikey=<key>`
   - **MQTT:** topic `emon/<nodeid>/<keyname>`
4. See incoming data under **Inputs**.
5. Create **Feeds** from inputs (PHPFina for fixed-interval energy data).
6. Build **Dashboards** and **Graphs**.
7. Install **App modules**: MySolar, MyElectric, etc.
8. Put behind TLS.

## Core concepts

| Concept | Description |
|---------|-------------|
| **Input** | Real-time data entry point; only last value stored |
| **Feed** | Time-series log of historic input data |
| **Node** | Device/group identifier |
| **Input process** | Function chain: `log_to_feed`, `power_to_kwh`, etc. |
| **Dashboard** | Customizable gauges, graphs, widgets |
| **App module** | Pre-built application dashboards (MySolar, MyElectric, EV, HeatPump) |

## Application modules

- **MySolar** — solar PV + house consumption
- **MyElectric** — electricity consumption
- **EV Divert** — solar EV charging diversion
- **HeatPump** — COP monitoring
- **Octopus Agile** — UK time-of-use tariff
- **DemandShaper** — schedule devices by carbon/cost forecast

## Gotchas

- **Redis is strongly recommended.** Without Redis, every input write hits disk directly — fatal for SD cards on Raspberry Pi. Redis buffers writes; enable low-write mode for SD card longevity.
- **Input process chain is required.** Data arriving at an Input disappears unless an input process (e.g. `log_to_feed`) explicitly stores it to a feed. New users often miss this step.
- **Workers must stay running.** `feedwriter`, `emoncms_mqtt`, `service-runner` are background processes. In Docker they're managed inside the container; on bare metal use systemd.
- **MQTT topic format.** `emon/<nodeid>/<keyname>` — the `emoncms_mqtt` worker subscribes to `emon/#` and auto-creates inputs.
- **PHPFina files are dense binary.** Not human-readable. Use <https://github.com/trystanlea/phpfinaview> to inspect raw feed files or verify backups.
- **Module installation.** Extra modules (Graph, Dashboard, App, DemandShaper) are installed by cloning into `Modules/`. The all-in-one Docker includes core modules; extras need manual install.
- **DB update check after upgrade.** After any upgrade, visit Admin → Check for database updates.

## Backup

```sh
# DB dump
docker exec emoncms mysqldump -u root emoncms > emoncms-$(date +%F).sql
# Feed binary data
docker cp emoncms:/var/opt/emoncms ./emoncms-data-backup/
```

Built-in Backup/Restore module also available in the Modules menu.

## Project health

Active PHP development, Docker Hub (multi-arch), Android app, extensive docs site, large OpenEnergyMonitor community forum. AGPL license.

## Energy-monitoring-family comparison

- **Emoncms** — PHP+MariaDB+Redis, MQTT, PHPFina time-series, energy-specific apps, OpenEnergyMonitor ecosystem
- **Grafana + InfluxDB** — general-purpose metrics; flexible but no energy-specific app modules
- **Home Assistant Energy** — HA built-in energy dashboard; HA-only
- **Volkszähler** — German utility metering platform; similar scope

**Choose Emoncms if:** you have OpenEnergyMonitor hardware (emonPi/emonBase) or want a purpose-built energy monitoring platform with solar, EV, heat pump, and demand-shaping modules.

## Links

- Repo: <https://github.com/emoncms/emoncms>
- Docs: <https://docs.openenergymonitor.org/emoncms>
- All-in-one Docker: <https://hub.docker.com/r/alexjunk/emoncms>
- Docker Compose: <https://github.com/emoncms/emoncms-docker>
- Community: <https://community.openenergymonitor.org>
