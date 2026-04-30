---
name: Zigbee2MQTT
description: Zigbee-to-MQTT bridge. Exposes Zigbee devices (Philips Hue, IKEA Tradfri, Aqara, Sonoff, …) through MQTT, making them usable by Home Assistant, Node-RED, OpenHAB, or any MQTT-speaking automation — without vendor hubs. MIT.
---

# Zigbee2MQTT

Z2M is a Node.js service that connects to a USB/Ethernet Zigbee coordinator radio (Texas Instruments CC2652, Silicon Labs EFR32, Dresden Elektronik ConBee, Sonoff, Tube's) and republishes everything on the Zigbee network as MQTT topics. Home Assistant's MQTT Discovery makes Zigbee devices appear automatically in HA; other consumers (Node-RED, OpenHAB, zigbee2mqtt-frontend, custom scripts) just subscribe to `zigbee2mqtt/#`.

The alternative to Z2M is **ZHA** (Home Assistant's built-in integration) or **deCONZ / Phoscon** (Dresden Elektronik's stack). Z2M supports more devices (3000+) than either, at the cost of running a separate process.

- Upstream repo: <https://github.com/Koenkk/zigbee2mqtt>
- Docs: <https://www.zigbee2mqtt.io/>
- Docker install guide: <https://www.zigbee2mqtt.io/guide/installation/02_docker.html>
- Image: `ghcr.io/koenkk/zigbee2mqtt`

## Architecture in one minute

Two processes + one USB device:

1. **MQTT broker** (Eclipse Mosquitto, EMQX, or HA's built-in) — messages pass through here
2. **Zigbee2MQTT** — connects to coordinator via `/dev/serial/by-id/...` and to broker via `mqtt://broker`
3. **Coordinator hardware** — a USB Zigbee radio; Z2M supports `zstack` (TI CC26x2), `ember` (Silicon Labs), `deconz` (ConBee), `zigate`, and `zboss`

Z2M does NOT include an MQTT broker — you run one separately.

## Compatible install methods

| Infra                     | Runtime                                       | Notes                                                                |
| ------------------------- | --------------------------------------------- | -------------------------------------------------------------------- |
| Single VM / Raspberry Pi  | Docker (`ghcr.io/koenkk/zigbee2mqtt`)         | **Recommended.** Multi-arch (amd64/arm64/armv7/armv6/386/riscv64)    |
| Raspberry Pi              | Native Linux install (systemd)                | Lower overhead; good for dedicated Pi                                |
| Home Assistant OS         | Home Assistant Add-on                         | One-click install via HA UI                                          |
| Windows                   | Native (`npm install && npm run start`)       | For dev / hobbyist                                                    |
| FreeBSD jail              | Ports                                         | Documented in repo                                                    |
| Kubernetes                | Plain manifests                               | USB device passthrough requires a privileged pod or dedicated node   |
| openHABian                | Pre-packaged                                  | Turnkey for OpenHAB users                                            |

## Inputs to collect

| Input                  | Example                                         | Phase      | Notes                                                            |
| ---------------------- | ----------------------------------------------- | ---------- | ---------------------------------------------------------------- |
| Zigbee coordinator path | `/dev/serial/by-id/usb-Silicon_Labs_SlaeSH_CC2652P_...` | Hardware | **Always use `/dev/serial/by-id/`**, never `/dev/ttyACM0` (enumeration order varies) |
| Coordinator adapter type | `zstack` / `ember` / `deconz` / `zigate` / `zboss` | Config | Only required if auto-detect fails                              |
| MQTT broker URL        | `mqtt://192.168.1.10:1883`                      | Runtime    | Cannot be `localhost` inside a container — use host IP or service name |
| MQTT credentials        | user + password                                 | Runtime    | Broker-enforced; Z2M doesn't need open broker                    |
| Frontend port          | `8080:8080`                                     | Network    | Web UI (new-device onboarding, device list, map, OTA updates)    |
| Data volume            | `./data:/app/data`                              | Data       | Persists `configuration.yaml`, device DB, Zigbee network keys    |
| `TZ`                   | `Europe/Amsterdam`                              | Runtime    | Log timestamps                                                   |

## Install via Docker Compose

From <https://www.zigbee2mqtt.io/guide/installation/02_docker.html>:

```yaml
services:
  zigbee2mqtt:
    container_name: zigbee2mqtt
    image: ghcr.io/koenkk/zigbee2mqtt:2.0    # pin major (2.x); never use :latest-dev in prod
    restart: unless-stopped
    ports:
      - 8080:8080
    volumes:
      - ./data:/app/data
      - /run/udev:/run/udev:ro                # required for adapter auto-detection
    environment:
      - TZ=Europe/Amsterdam
    devices:
      # Use /dev/serial/by-id/ path — never /dev/ttyACM0 (moves after reboot)
      - /dev/serial/by-id/usb-Silicon_Labs_SlaeSH_CC2652P_...:/dev/ttyACM0
```

### Rootless variant

Production deployments should run as an unprivileged user:

```yaml
    user: "1000:1000"
    group_add:
      - dialout            # Ubuntu; find with `ls -l /dev/ttyACM0`
```

(On SELinux hosts, append `:z` to the volume mount: `- ./data:/app/data:z`.)

### First boot

`docker compose up -d` starts Z2M in onboarding mode on port 8080. Browse there — the web UI walks you through:

1. Selecting the adapter
2. Configuring the MQTT broker
3. Creating the Zigbee network keys
4. Permit-join → pair your first device

After onboarding, the wizard writes `./data/configuration.yaml` with your choices.

## Sample `configuration.yaml` (rendered after onboarding)

```yaml
version: 5
homeassistant:
  enabled: true                # enables MQTT Discovery → devices auto-appear in HA
frontend:
  enabled: true
  port: 8080
mqtt:
  base_topic: zigbee2mqtt
  server: "mqtt://192.168.1.10:1883"
  user: zigbee2mqtt
  password: REPLACE_WITH_STRONG_PASSWORD
serial:
  port: /dev/ttyACM0                 # path inside container
  adapter: zstack                    # or ember/deconz/zigate/zboss
advanced:
  network_key: GENERATE              # only on first boot; keep the generated value stable!
  pan_id: GENERATE
  ext_pan_id: GENERATE
```

## Adding devices

1. In the frontend, click `Permit join (All)` → 255 second window opens.
2. Put the device in pairing mode (usually a long-press or factory reset).
3. Device appears in the web UI within seconds; friendly-rename it via `Edit`.
4. For Home Assistant: the device auto-appears under `MQTT` integration → Devices (via `homeassistant.enabled: true`).

## Data & config layout

Inside `/app/data`:

- `configuration.yaml` — your config (the file version above)
- `database.db` — per-device state + Zigbee routing table
- `coordinator_backup.json` — coordinator's network keys + IEEE → short-address mappings
- `log/log_*.txt` — Z2M logs (daily-rotated)

## Backup

```sh
# Critical: stop Z2M first so database.db is consistent
docker compose stop zigbee2mqtt
tar czf zigbee2mqtt-$(date +%F).tgz ./data
docker compose start zigbee2mqtt
```

**The `coordinator_backup.json` is your insurance against a dead coordinator.** With it, you can flash the backup onto a new compatible radio and every device re-joins automatically without re-pairing each one. Without it, a dead coordinator = manually re-pair every device.

## Upgrade

1. Major releases: <https://github.com/Koenkk/zigbee2mqtt/releases>.
2. Bump image tag, `docker compose pull && docker compose up -d`. Z2M runs migrations on startup.
3. Z2M 2.0 (current) bumped minimum Node to 20+; if you're still on 1.x, read the 2.0 migration guide: <https://www.zigbee2mqtt.io/guide/installation/02_docker.html>.
4. Device definitions auto-update via the built-in `zigbee-herdsman-converters` library, bundled with the image.
5. OTA firmware updates for supported devices: web UI → device → OTA. Only do these with good backups; bricked devices usually require factory reset + repair.

## Gotchas

- **Always use `/dev/serial/by-id/...`.** `/dev/ttyACM0` can renumber on reboot if you have multiple USB serial devices; Z2M will then talk to the wrong one (could be a printer).
- **Coordinator hardware matters.** TI CC2652P2 (Slaesh's stick, Sonoff ZBDongle-P) and Silicon Labs EFR32 (Sonoff ZBDongle-E) are the widely-recommended modern choices. Older CC2531 sticks are cheap but underpowered (max ~15 devices reliably). Avoid clones.
- **Keep the coordinator away from USB 3.0.** USB 3 emits RF interference in the 2.4 GHz band that kills Zigbee reliability. Use a USB 2.0 port, or a USB extension cable to physically separate it from the host.
- **Never move the coordinator to a different host without a backup.** Re-pairing 30+ devices is painful. Export `coordinator_backup.json` first.
- **Network key must not change.** `network_key: GENERATE` generates on first boot; the generated value ends up in `configuration.yaml`. Never regenerate after devices are paired — they'll all fall off the network.
- **Zigbee range drops through walls.** Add mains-powered Zigbee devices (smart plugs, bulbs) as router nodes. Battery devices (sensors, buttons) are end-devices that can't relay.
- **Permit-join leaves you open.** `permit_join: true` (or the UI button) lets any nearby Zigbee device join for the window. Turn it off when not actively pairing — a neighbor's device can accidentally join yours otherwise.
- **MQTT broker is not included.** Deploy Eclipse Mosquitto, EMQX, or HA's built-in broker separately. Z2M's `server: mqtt://localhost` will NOT work inside a container — use the host IP or compose service name.
- **Home Assistant Add-on vs Docker** — the HA Add-on is the easiest path for HA users but slightly lags upstream Docker image. Heavy users often prefer Docker for more control.
- **MQTT Discovery is auto-magical.** Enabling `homeassistant.enabled: true` makes devices appear in HA with zero configuration — but if you later migrate MQTT brokers or topics, HA may not clean up the old discovery entities automatically.
- **OTA updates can brick devices.** Supported firmware versions are curated by zigbee-herdsman-converters; applying an update to a device with an unsupported firmware path = factory reset or worse.
- **Groups are a Zigbee feature, not an MQTT one.** Z2M supports Zigbee groups (multicast on-off/brightness), crucial for latency-sensitive scenes. Configure via UI → Groups.
- **Frontend has no built-in auth.** Z2M 2.x added optional auth via `frontend.auth_token`, but many setups assume LAN-only access. Put behind reverse proxy + basic auth for remote access.
- **`version: 5` in `configuration.yaml`** is the current schema version. Z2M handles migrations automatically on upgrade; don't hand-bump.
- **Some "Zigbee" devices aren't standards-compliant** — notably Ikea Tradfri before newer firmware. Check the device compatibility list: <https://www.zigbee2mqtt.io/supported-devices/>.

## Links

- Repo: <https://github.com/Koenkk/zigbee2mqtt>
- Docs: <https://www.zigbee2mqtt.io/>
- Docker install: <https://www.zigbee2mqtt.io/guide/installation/02_docker.html>
- Linux install: <https://www.zigbee2mqtt.io/guide/installation/01_linux.html>
- Home Assistant Add-on: <https://www.zigbee2mqtt.io/guide/installation/03_ha_addon.html>
- Supported devices: <https://www.zigbee2mqtt.io/supported-devices/>
- Coordinator hardware guide: <https://www.zigbee2mqtt.io/guide/adapters/>
- Releases: <https://github.com/Koenkk/zigbee2mqtt/releases>
- Container images: <https://github.com/Koenkk/zigbee2mqtt/pkgs/container/zigbee2mqtt>
- zigbee-herdsman-converters (device defs): <https://github.com/Koenkk/zigbee-herdsman-converters>
