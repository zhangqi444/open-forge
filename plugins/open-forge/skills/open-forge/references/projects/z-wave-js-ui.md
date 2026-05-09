---
name: z-wave-js-ui
description: "Full-featured Z-Wave Control Panel UI and MQTT Gateway. Node.js + Vue + Z-Wave JS. Manage Z-Wave networks, expose devices to MQTT, integrates with Home Assistant, Domoticz, OpenHAB, and more. MIT."
---

# Z-Wave JS UI

Z-Wave JS UI is a **full-featured Z-Wave Control Panel and MQTT Gateway** for managing Z-Wave smart-home networks. It runs as a Node.js server with a Vue-based web UI, combining the powerful [node-zwave-js](https://github.com/zwave-js/node-zwave-js) library with a rich configuration interface and MQTT publishing capability.

It bridges Z-Wave hardware (USB stick controllers) to the rest of your smart home stack — most notably **Home Assistant** (via its official HA add-on or plain MQTT), but also Domoticz, OpenHAB, ioBroker, Jeedom, HomeSeer, and Homebridge.

- Upstream repo: <https://github.com/zwave-js/zwave-js-ui>
- Documentation: <https://zwave-js.github.io/zwave-js-ui/>
- Docker Hub: <https://hub.docker.com/r/zwavejs/zwave-js-ui>
- Snap Store: <https://snapcraft.io/zwave-js-ui>
- Discord: <https://discord.gg/HFqcyFNfWd>
- Releases: <https://github.com/zwave-js/zwave-js-ui/releases>

## Architecture in one minute

- **Backend**: Node.js + Express + socket.io + MQTTjs + node-zwave-js + Webpack
- **Frontend**: Vue + Vuetify + socket.io
- **Persistence**: A `store` directory holds network configuration, scenes, node data, and backups
- **Hardware dependency**: A Z-Wave USB controller stick (e.g. Aeotec Z-Stick, HUSBZB-1, Zooz ZAC93) — passed through to the container via `devices:`
- **Optional**: MQTT broker (Mosquitto or other) for gateway mode; not required for standalone control-panel use
- **Ports**: `8091` — web UI; `3000` — Z-Wave JS WebSocket server (used by Home Assistant)

## Compatible install methods

| Method | Notes |
|---|---|
| **Docker Compose** (recommended) | Upstream-blessed. Single container + optional MQTT sidecar. |
| **Docker standalone** (`docker run`) | Documented in upstream docs. |
| **Snap** | `snap install zwave-js-ui` — easiest for Ubuntu/Debian without Docker. |
| **Home Assistant Add-on** | Official hassio-addons repo — simplest path for HA users. |
| **npm / bare-metal** | `npm install` + `npm start` — for contributors or no-Docker setups. |

## Hardware requirements

A physical **Z-Wave USB controller stick** is required. Common choices:
- Aeotec Z-Stick 7 (Gen5+)
- HUSBZB-1 (combo Z-Wave + Zigbee)
- Zooz ZAC93 800-series

Identify the stick's stable device path:
```bash
ls /dev/serial/by-id/
```
Use the `/dev/serial/by-id/…` path (not `/dev/ttyUSBx` — those can change on reboot).

## Inputs to collect

| Input | Example | Notes |
|---|---|---|
| Z-Wave stick device path | `/dev/serial/by-id/usb-0658_0200-if00` | From `ls /dev/serial/by-id/` |
| Session secret | random 32-char string | Set `SESSION_SECRET` env var |
| Timezone | `America/New_York` | Optional; aligns log timestamps |
| MQTT broker URL | `mqtt://mosquitto:1883` | Only if using gateway/MQTT mode |

## Install via Docker Compose

From upstream `docker/docker-compose.yml`:

```yaml
version: '3.7'
services:
  zwave-js-ui:
    container_name: zwave-js-ui
    image: zwavejs/zwave-js-ui:latest   # pin a specific tag in production
    restart: always
    tty: true
    stop_signal: SIGINT
    environment:
      - SESSION_SECRET=CHANGE_TO_RANDOM_STRING
      # - TZ=America/New_York
    networks:
      - zwave
    devices:
      # Use stable /dev/serial/by-id/ path, not /dev/ttyUSBx
      - '/dev/serial/by-id/YOUR_STICK_ID:/dev/zwave'
    volumes:
      - zwave-config:/usr/src/app/store
    ports:
      - '8091:8091'   # Web UI
      - '3000:3000'   # Z-Wave JS WebSocket server

networks:
  zwave:

volumes:
  zwave-config:
    name: zwave-config
```

Optional: add a Mosquitto sidecar if you want MQTT gateway mode:

```yaml
  mosquitto:
    image: eclipse-mosquitto:2
    restart: always
    networks:
      - zwave
    volumes:
      - mosquitto-data:/mosquitto
    ports:
      - '1883:1883'
```

## First boot

1. Navigate to `http://your-server-ip:8091`
2. Complete the **Setup Wizard** — configure Z-Wave controller port, MQTT settings (optional), security keys for S2/S0 inclusion
3. **Include your Z-Wave devices**: Settings → Z-Wave → Inclusion mode
4. For **Home Assistant** integration:
   - Use the official [HA add-on](https://github.com/hassio-addons/addon-zwave-js-ui) — easiest path
   - Or standalone: configure HA's Z-Wave JS integration to point at `ws://your-server:3000`
5. For **MQTT gateway** mode: configure the MQTT broker connection in Settings → MQTT

## Key features

- **Nodes management**: Add, remove, configure all nodes
- **Firmware updates**: OTA updates using manufacturer firmware files
- **Group associations**: Direct node-to-node associations without controller
- **Network graph**: Visual map of node communication paths
- **Scene management**: Create/trigger scenes via MQTT or UI
- **Zniffer support**: Z-Wave traffic analysis and debugging
- **Automatic backups**: Scheduled NVM + store backups
- **Debug logs UI**: View logs directly in browser
- **HTTPS + auth**: Secure the UI with SSL and username/password

## Data & config layout

- All persistent data lives in the `store` volume: `zwave-config:/usr/src/app/store`
- Includes: network settings, node database, scenes, backups, SSL certs
- Back up the entire store volume regularly

## Backup

```bash
# Stop container, tar the volume data, restart
docker stop zwave-js-ui
sudo tar czf zwave-backup-$(date +%F).tgz /var/lib/docker/volumes/zwave-config/_data/
docker start zwave-js-ui

# Or use the built-in UI backup: Settings → Backup & Restore
```

## Upgrade

1. Check releases at <https://github.com/zwave-js/zwave-js-ui/releases>
2. **Back up first** — especially the NVM (network config); a bad upgrade can corrupt the Z-Wave network
3. `docker pull zwavejs/zwave-js-ui:latest && docker compose up -d`
4. Review release notes for breaking changes (security key format changes, API changes)

## Gotchas

- **Device path stability**: Always use `/dev/serial/by-id/…` — `/dev/ttyUSBx` numbers shift when you plug/unplug USB devices
- **S2 security keys**: Generate during initial setup and back them up. Losing them means re-including all S2 devices
- **One controller per instance**: Each Z-Wave JS UI instance manages one Z-Wave controller
- **Home Assistant users**: The HA supervisor add-on is simpler than standalone Docker. Use standalone only if HA is not your primary controller
- **MQTT vs WebSocket**: HA integrates via Z-Wave JS WebSocket (port 3000), not MQTT. MQTT is for exposing devices to other systems (Node-RED, etc.)
- **Zniffer mode**: Requires a second supported Z-Wave stick for traffic capture

## Software integrations

- **Home Assistant**: Official [HA add-on](https://github.com/hassio-addons/addon-zwave-js-ui) or standalone via Z-Wave JS integration
- **Domoticz**: MQTT Discovery — <https://www.domoticz.com/wiki/Zwave-JS-UI>
- **OpenHAB**: MQTT Discovery
- **Jeedom**: Official Z-Wave JS plugin
- **ioBroker**: ioBroker.zwave-ws adapter
- **Homebridge**: homebridge-zwave-usb plugin

## Links

- Repo: <https://github.com/zwave-js/zwave-js-ui>
- Docs: <https://zwave-js.github.io/zwave-js-ui/>
- Docker Hub: <https://hub.docker.com/r/zwavejs/zwave-js-ui>
- HA Add-on: <https://github.com/hassio-addons/addon-zwave-js-ui>
- Releases: <https://github.com/zwave-js/zwave-js-ui/releases>
- Discord: <https://discord.gg/HFqcyFNfWd>
- node-zwave-js: <https://github.com/zwave-js/node-zwave-js>
