---
name: Z-Wave JS UI
description: "Full-featured Z-Wave control panel and MQTT gateway. Docker. Node.js/Vue. zwave-js/zwave-js-ui. Manage Z-Wave devices, expose via MQTT, Home Assistant integration, scene management, network graph, Zniffer. MIT."
---

# Z-Wave JS UI

**Full-featured Z-Wave control panel and MQTT gateway.** Manage your entire Z-Wave network through a Vue web UI: add/remove/configure devices, update firmware, manage associations, create scenes, and visualize the mesh network graph. Exposes all Z-Wave devices to an MQTT broker for integration with Home Assistant, Domoticz, OpenHAB, ioBroker, and others.

Built + maintained by **zwave-js team (robertsLando)**. MIT license.

- Upstream repo: <https://github.com/zwave-js/zwave-js-ui>
- Docs: <https://zwave-js.github.io/zwave-js-ui/>
- Docker Hub: <https://hub.docker.com/r/zwavejs/zwave-js-ui>
- Discord: <https://discord.gg/HFqcyFNfWd>
- Snap Store: available

## Architecture in one minute

- **Node.js** backend + **Vue.js / Vuetify** frontend
- **Socket.io** for real-time web UI updates
- **MQTT.js** for publishing Z-Wave device states to an MQTT broker
- **node-zwave-js** library for Z-Wave serial communication
- Requires a **Z-Wave USB stick** (`/dev/serial/by-id/...`)
- Port **8091** (web UI), **3000** (Z-Wave JS WebSocket server — for Home Assistant integration)
- Persistent config in `/usr/src/app/store` volume
- Resource: **low-medium** — Node.js; Z-Wave polling is event-driven

## Compatible install methods

| Infra                | Runtime                         | Notes                                                         |
| -------------------- | ------------------------------- | ------------------------------------------------------------- |
| **Docker**           | `zwavejs/zwave-js-ui`           | **Primary** — Docker Hub; pass USB stick as device            |
| **Snap**             | `snap install zwave-js-ui`      | For Ubuntu/Snap systems                                       |
| **Home Assistant**   | HA Add-on store                 | Official HASSIO add-on: `addon-zwave-js-ui`                   |
| **Node.js (source)** | `npm install` + `npm start`     | Development/bare-metal                                        |

## Inputs to collect

| Input                          | Example                                  | Phase   | Notes                                                                            |
| ------------------------------ | ---------------------------------------- | ------- | -------------------------------------------------------------------------------- |
| Z-Wave USB stick device path   | `/dev/serial/by-id/usb-xxx-if00`         | HW      | **Use `/dev/serial/by-id/` path — not `/dev/ttyUSBX`** (see Gotchas)            |
| `SESSION_SECRET`               | random string                            | Auth    | Signing secret for session cookies                                               |
| MQTT broker (optional)         | `mqtt://mosquitto:1883`                  | MQTT    | For gateway functionality; not required for control panel only                  |
| `TZ`                           | `America/New_York`                       | Config  | Optional timezone for log timestamps                                             |

## Install via Docker Compose

```yaml
services:
  zwave-js-ui:
    container_name: zwave-js-ui
    image: zwavejs/zwave-js-ui:v11.17.0
    restart: always
    tty: true
    stop_signal: SIGINT
    environment:
      - SESSION_SECRET=changeme_random_secret
      # - TZ=America/New_York
    devices:
      # Use /dev/serial/by-id/ path — NOT /dev/ttyUSBX
      - '/dev/serial/by-id/usb-your-stick-reference:/dev/zwave'
    volumes:
      - zwave-config:/usr/src/app/store
    ports:
      - '8091:8091'   # web UI
      - '3000:3000'   # Z-Wave JS WebSocket (for Home Assistant)
    networks:
      - zwave

networks:
  zwave:
volumes:
  zwave-config:
    name: zwave-config
```

Visit `http://localhost:8091`.

## First boot

1. Identify your Z-Wave stick path: `ls /dev/serial/by-id/` — look for your stick's vendor/product ID.
2. Deploy with that path in `devices:`.
3. Visit `http://localhost:8091`.
4. Settings → Z-Wave → set your serial port to `/dev/zwave` → Save + Connect.
5. Include your first Z-Wave device (put it in inclusion mode + click "Add device" in Z-Wave JS UI).
6. (Optional) Configure MQTT gateway: Settings → MQTT → broker address, port, credentials.
7. Home Assistant integration: point the Z-Wave JS integration at `http://your-server:3000`.
8. Put behind TLS.

## Key features

| Feature | Details |
|---------|---------|
| Control panel | Add/remove/configure/rename all Z-Wave nodes |
| Firmware updates | OTA updates using manufacturer-supplied files |
| Group associations | Direct Z-Wave node-to-node associations |
| MQTT gateway | Expose all nodes/values to MQTT; fully configurable topic structure |
| Scene management | Create scenes; trigger via MQTT |
| Network graph | Visual mesh network topology |
| NVM backups | Scheduled backup of the Z-Wave controller NVM + store directory |
| Zniffer | Z-Wave traffic debugger/sniffer mode |
| Debug logs | Real-time logs in the web UI |
| File browser | Access store files from the UI |

## Home Assistant integration

Z-Wave JS UI exposes a WebSocket server on port 3000 that Home Assistant's Z-Wave JS integration connects to. Set the integration URL to `ws://your-server:3000`. This is the recommended approach for Home Assistant + Z-Wave JS UI (instead of using the HA add-on directly, which gives less control).

Official guide: <https://zwave-js.github.io/zwave-js-ui/#/homeassistant/homeassistant-mqtt>

## Supported home automation platforms

Home Assistant, Domoticz, OpenHAB, Jeedom, HomeSeer, Homebridge, ioBroker — all via MQTT or direct WebSocket.

## Gotchas

- **Use `/dev/serial/by-id/` paths, not `/dev/ttyUSBX`.** Serial device mappings (`ttyUSB0`, `ttyUSB1`) can change between reboots and when USB devices are added/removed. The `/dev/serial/by-id/` path is stable — it's based on the device's USB vendor/product ID and won't change. **This is critical** — if the path changes, Z-Wave JS UI can't connect to your stick.
- **Docker `devices:` passthrough.** The USB stick must be passed through as a device (`devices:` in compose). It won't work with volume mounts. The stick also needs to be plugged in before the container starts.
- **NVM backup before network changes.** The compose file can be configured to automatically backup the controller's Non-Volatile Memory (NVM) before every node inclusion/exclusion/replace operation. Enable this for safety — NVM corruption can lose your entire Z-Wave network.
- **Port 3000 is for Home Assistant.** The HA Z-Wave JS integration uses the WebSocket protocol on port 3000 — not the web UI on 8091. Open both ports.
- **Security keys (S2).** For Z-Wave Security 2 (S2) inclusion, Z-Wave JS UI generates security keys on first run, stored in the persistent config volume. Back up the `store` volume — losing these keys means you can't communicate with S2 devices anymore.
- **`SESSION_SECRET` should be set.** Without it, sessions use a default or random value — logins become invalid on restart.
- **Zniffer mode.** Some sticks can be flashed with Zniffer firmware for deep packet inspection. This requires a separate stick (not your main controller) and a specific firmware file. See the wiki.

## Backup

Back up the named `zwave-config` volume:
```sh
docker run --rm -v zwave-config:/data -v $(pwd):/backup alpine tar czf /backup/zwave-config-$(date +%F).tgz /data
```

## Upgrade

```sh
docker compose pull && docker compose up -d
```

## Project health

Very active Node.js development, Docker Hub, Snap, HA add-on, MQTT gateway, network graph, NVM backup, Zniffer. Well-maintained by the zwave-js team. MIT license. Discord community.

## Z-Wave-management-family comparison

- **Z-Wave JS UI** — Node.js+Vue, full control panel + MQTT gateway, HA WebSocket server, network graph, MIT
- **zwavejs2mqtt** — the old name/project; now fully merged into Z-Wave JS UI
- **OpenZWave (OZW)** — C++; older; being replaced by node-zwave-js across the ecosystem
- **Home Assistant Z-Wave integration** — HA-native; good for simple HA setups; Z-Wave JS UI gives more control
- **Domoticz Z-Wave** — built into Domoticz; limited compared to Z-Wave JS UI

**Choose Z-Wave JS UI if:** you have a Z-Wave USB stick and want a dedicated control panel + MQTT gateway that works with any home automation platform.

## Links

- Repo: <https://github.com/zwave-js/zwave-js-ui>
- Docs: <https://zwave-js.github.io/zwave-js-ui/>
- Docker Hub: <https://hub.docker.com/r/zwavejs/zwave-js-ui>
- Discord: <https://discord.gg/HFqcyFNfWd>
