---
name: gladys-assistant
description: "Privacy-first, open-source smart home assistant. Node.js + SQLite. Runs locally on Raspberry Pi, NAS, or any server. Integrates Z-Wave, Zigbee, MQTT, Google Home, Alexa, and 30+ protocols. Apache 2.0."
---

# Gladys Assistant

Gladys Assistant is a **privacy-first, open-source smart home platform** that runs entirely on your local network. Node.js + SQLite, it's designed to be lightweight enough for a Raspberry Pi while being powerful enough for a full smart home setup. It supports 30+ protocols and devices via its integration system, including Z-Wave, Zigbee, MQTT, Bluetooth, Google Home, Amazon Alexa, and more.

Unlike cloud-connected platforms, Gladys stores all your data locally and processes automations on-device — no internet connection required after initial setup.

- Upstream repo: <https://github.com/GladysAssistant/Gladys>
- Homepage: <https://gladysassistant.com>
- Docs: <https://gladysassistant.com/docs/>
- Docker Hub: <https://hub.docker.com/r/gladysassistant/gladys>
- Community forum: <https://community.gladysassistant.com>
- Discord: available via gladysassistant.com

## Architecture in one minute

- **Backend**: Node.js (Express + Sequelize)
- **Database**: SQLite — single file, easy to back up
- **Frontend**: Preact
- **Hardware access**: Mounts `/dev` and Docker socket for device access
- **Networking**: Host network mode recommended (enables mDNS/Bluetooth/Zigbee autodiscovery)
- **Port**: `80` (default) or configurable via `SERVER_PORT`

## Compatible install methods

| Method | Notes |
|---|---|
| **Docker (single `docker run`)** | Upstream-primary. One command with host networking. |
| **Docker Compose** | Documented at <https://gladysassistant.com/docs/installation/docker-compose/> |
| **Raspberry Pi OS / DietPi** | First-class support; RPi is the primary target hardware |
| **Synology NAS** | Documented install guide |
| **NAS / QNAP** | Community guides available |

## Install via Docker (upstream-primary)

From the upstream README:

```bash
sudo docker run -d \
  --log-driver json-file \
  --log-opt max-size=10m \
  --cgroupns=host \
  --restart=always \
  --privileged \
  --network=host \
  --name gladys \
  -e NODE_ENV=production \
  -e SERVER_PORT=80 \
  -e TZ=Europe/Paris \
  -e SQLITE_FILE_PATH=/var/lib/gladysassistant/gladys-production.db \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /var/lib/gladysassistant:/var/lib/gladysassistant \
  -v /dev:/dev \
  -v /run/udev:/run/udev:ro \
  gladysassistant/gladys:v4
```

Key parameters:
- `--network=host` — required for local device discovery (mDNS, Bluetooth, etc.)
- `--privileged` — required for accessing USB/serial devices (Z-Wave sticks, Zigbee dongles)
- `-v /dev:/dev` — exposes host devices inside container
- `-e TZ=` — set to your timezone (see [tz database](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones))

For Docker Compose version: <https://gladysassistant.com/docs/installation/docker-compose/>

## Inputs to collect

| Input | Example | Notes |
|---|---|---|
| Timezone | `America/New_York` | Must match your location |
| Server port | `80` or `8080` | Port for the web UI |
| DB path | `/var/lib/gladysassistant/gladys-production.db` | Host path for SQLite persistence |
| Admin email | `admin@example.com` | Set during first-run wizard |
| Admin password | strong password | Set during first-run wizard |

## First boot

1. Navigate to `http://your-server-ip` (or `http://gladys.local` on LAN)
2. Complete the **setup wizard**: create admin account, set timezone, configure house
3. Navigate to **Integrations** to add devices:
   - Z-Wave: requires Z-Wave USB stick + Z-Wave JS integration
   - Zigbee: requires Zigbee USB dongle (ConBee II, SONOFF Zigbee 3.0, etc.)
   - MQTT: connect any MQTT-capable device
   - Philips Hue, Sonos, Google Home, Alexa: via dedicated integrations
4. Create **scenes** and **automations** in the dashboard

## Supported integrations (partial list)

- **Z-Wave** — via Z-Wave JS
- **Zigbee** — via Zigbee2MQTT
- **MQTT** — generic broker-based
- **Philips Hue**
- **Google Home**
- **Amazon Alexa**
- **OpenAI** (AI assistant integration)
- **Bluetooth** (BTLE devices, presence detection)
- **Sonos**
- **Tasmota**
- **Xiaomi** (via Mi Home bridge)
- **Netatmo**
- **eWeLink**
- **Caldav** (calendar integration)
- **Camera** (RTSP/MJPEG streams)
- And 30+ more — see <https://gladysassistant.com/docs/integrations/>

## Data & config layout

- SQLite DB: single file at `SQLITE_FILE_PATH` — typically `/var/lib/gladysassistant/gladys-production.db`
- All scenes, devices, automations, history stored in SQLite
- No external database required

## Backup

```bash
# SQLite is a single file — just copy it
cp /var/lib/gladysassistant/gladys-production.db \
   gladys-backup-$(date +%F).db

# Or tar the entire data directory
tar czf gladys-data-$(date +%F).tgz /var/lib/gladysassistant/
```

Stop Gladys briefly for a consistent point-in-time backup:
```bash
docker stop gladys
cp /var/lib/gladysassistant/gladys-production.db gladys-backup-$(date +%F).db
docker start gladys
```

## Upgrade

```bash
docker stop gladys
docker rm gladys
docker pull gladysassistant/gladys:v4
# Re-run the docker run command above
```

Or if using Docker Compose:
```bash
docker compose pull && docker compose up -d
```

Always back up the SQLite file before upgrading.

## Gotchas

- **`--network=host` is required** for proper local device discovery (mDNS, Bluetooth, Zigbee autodiscovery). Without it, many integrations won't work correctly
- **`--privileged` needed** for USB/serial device access. On tightened systems (AppArmor/SELinux), this grants broad permissions — understand the tradeoff for your setup
- **Single-user design**: Gladys is primarily designed for a single home/household admin. Multi-user setups have limitations
- **SQLite simplicity**: The single-file SQLite design is great for backups and portability, but can be a bottleneck at very high automation throughput
- **Raspberry Pi is the primary target**: Performance is optimized for ARM/RPi; x86 servers also work fine
- **French-origin project**: Pierre-Gilles Leymarie is French; some community content and documentation may be in French alongside English
- **Apache 2.0 license** — permissive; commercial use allowed

## Alternatives

| Tool | Notes |
|---|---|
| **Home Assistant** | Python; largest ecosystem; more complex |
| **Domoticz** | C++; very lightweight; older UI |
| **openHAB** | Java; very extensible; complex setup |
| **ioBroker** | Node.js; strong German community |
| **HomeBridge** | Node.js; HomeKit bridge focus |

**Choose Gladys if:** you want a clean, simple, privacy-first smart home UI without the complexity of Home Assistant, especially on a Raspberry Pi.

## Links

- Repo: <https://github.com/GladysAssistant/Gladys>
- Homepage: <https://gladysassistant.com>
- Docs: <https://gladysassistant.com/docs/>
- Docker Compose install: <https://gladysassistant.com/docs/installation/docker-compose/>
- Integrations: <https://gladysassistant.com/docs/integrations/>
- Community: <https://community.gladysassistant.com>
- Docker Hub: <https://hub.docker.com/r/gladysassistant/gladys>
- Releases: <https://github.com/GladysAssistant/Gladys/releases>
