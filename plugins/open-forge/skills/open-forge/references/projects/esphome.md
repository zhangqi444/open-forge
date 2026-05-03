---
name: ESPHome
description: Config-as-code firmware builder for ESP32/ESP8266 devices, tightly integrated with Home Assistant. Write YAML, get a smart-home-ready firmware that auto-discovers into HA. Python (compiles via PlatformIO). MIT.
---

# ESPHome

ESPHome is a tool for creating custom firmware for ESP32, ESP8266, RP2040, and other microcontrollers using **YAML configuration** instead of hand-writing Arduino C++. Point it at a YAML config, hit compile, flash; the device boots up, joins Wi-Fi, and auto-discovers into Home Assistant as fully-functional entities (sensors, switches, lights, etc.).

Target audience: **Home Assistant users** who want to build custom smart-home hardware without writing C++ firmware.

What you can build:

- **Sensors** — temperature, humidity, pressure, air quality, distance, weight, current, voltage, motion, magnetic, light, sound
- **Switches / lights** — relays, LEDs (addressable + basic), dimmers, RGB, fans
- **Displays** — OLED, e-paper, TFT, LCD, LED matrices
- **Climate controllers** — HVAC via IR blasters, mini-splits via CN105, etc.
- **Security devices** — door/window sensors, vibration sensors, sirens
- **Presence detection** — BLE proximity, mmWave radar (very popular)
- **Energy monitors** — CT clamps, smart plugs with power metering
- **Ambient-light-aware** setups — photon counters + auto-dim
- **Protocol bridges** — DALI, RS485/Modbus, Zigbee via ESP32-H2, etc.

Key features:

- **YAML config** → compiled ESP firmware via PlatformIO
- **OTA updates** — flash over Wi-Fi after first cable-flash
- **Home Assistant native API** — no MQTT required (but supported)
- **Auto-discovery** in HA
- **Web server on each device** — fallback UI even without HA
- **Modular** — 300+ integrations (sensors, buses, displays, effects, etc.)
- **LLM-callable via HA Voice Assistant + Assist** — "Turn on the fan" works with ESPHome + Voice Preview Edition
- **ESPHome dashboard** — web UI to manage/compile/flash all your devices from one place

Built by Nabu Casa (Home Assistant's company) since 2023 when `@OttoWinter` joined. Part of the **Open Home Foundation**.

- Upstream repo: <https://github.com/esphome/esphome>
- Website / docs: <https://esphome.io>
- Official Home Assistant add-on: <https://github.com/esphome/home-assistant-addon>
- Dashboard Docker: <https://hub.docker.com/r/esphome/esphome>
- Discord: <https://discord.gg/KhAMKrd>

## Architecture in one minute

Two things to know about:

### ESPHome dashboard (the "server")

- Web UI for creating + compiling YAML configs
- Wraps `esphome` CLI + PlatformIO toolchain
- Runs on your server; your devices are **flashed from here**
- **Port 6052** (HTTP dashboard)

### ESPHome device firmware

- Compiled from your YAML → flashed to ESP chip
- Talks to Home Assistant over the **native API** (port 6053 on the device)
- OR over **MQTT** if you prefer
- Exposes a web UI on the device (port 80 by default) — logs, quick debug, OTA

You interact with the **dashboard** daily; individual devices run autonomously once flashed.

## Compatible install methods

| Install           | Runtime                                          | Notes                                                              |
| ----------------- | ------------------------------------------------ | ------------------------------------------------------------------ |
| **Home Assistant** | ESPHome add-on (one-click)                        | **Most common** — if you run HA OS / Supervised                      |
| Docker            | `esphome/esphome` image                            | Standalone; outside HA                                                |
| pip               | `pip install esphome` (CLI only)                    | For scripting / CI                                                     |
| VS Code           | ESPHome VS Code extension                           | Edit + compile locally; very nice UX                                    |
| Python venv       | `python -m venv venv && pip install esphome`         | Clean local install                                                     |

## Inputs to collect

| Input                | Example                             | Phase     | Notes                                                               |
| -------------------- | ----------------------------------- | --------- | ------------------------------------------------------------------- |
| HA installation      | HA OS / Supervised / Docker            | Decide    | ESPHome is best-integrated with HA OS                                 |
| Hardware device      | ESP32 dev board, Sonoff, Shelly, etc. | Hardware  | <https://esphome.io/devices/>                                          |
| Wi-Fi SSID + PSK     | your Wi-Fi                            | Network   | Stored in device YAML                                                   |
| Device YAML config   | pin assignments, sensors, switches     | Config    | Examples: <https://esphome.io/examples>                                    |
| API encryption key   | 32-byte base64                          | Security  | Shared between device + HA for secure API                                 |
| OTA password         | strong                                 | Security  | Prevents unauthorized firmware updates                                     |
| Fallback AP password | strong                                 | Security  | Device broadcasts AP if Wi-Fi fails; enter password to re-provision         |

## Install as Home Assistant add-on (recommended for HA users)

1. Home Assistant → **Settings** → **Add-ons** → **Add-on Store**
2. Search "ESPHome" → **Install** (two variants: `ESPHome Device Builder` stable + beta)
3. Start the add-on → Open Web UI
4. Click **New Device** → follow wizard

Done. Dashboard integrated into HA; devices auto-register.

## Install via Docker (standalone)

```sh
mkdir -p config
docker run -d --name esphome \
  --restart unless-stopped \
  --net=host \
  -v "$(pwd)/config":/config \
  -e TZ=UTC \
  esphome/esphome:2026.4.3     # pin; check Docker Hub
```

**`--net=host` recommended** for mDNS discovery + ability to flash via USB passthrough when running on same host. Without it, you can still flash over-the-air but won't discover devices on the local subnet automatically.

Browse `http://<host>:6052`.

## Install via Docker Compose

```yaml
services:
  esphome:
    image: esphome/esphome:2026.4.3
    container_name: esphome
    restart: unless-stopped
    network_mode: host          # or bridge + port 6052
    environment:
      TZ: UTC
    volumes:
      - ./config:/config
      - /etc/localtime:/etc/localtime:ro
      # For USB flashing:
      - /dev/ttyUSB0:/dev/ttyUSB0
      - /dev/ttyACM0:/dev/ttyACM0
```

## First device (example YAML)

```yaml
esphome:
  name: kitchen-temp

esp32:
  board: esp32dev
  framework:
    type: esp-idf

wifi:
  ssid: "YOUR_SSID"
  password: "YOUR_PSK"
  ap:     # fallback AP if Wi-Fi fails
    ssid: "KitchenTemp-Fallback"
    password: "fallback-password"

captive_portal:

api:
  encryption:
    key: "base64-encryption-key"

ota:
  platform: esphome
  password: "ota-password"

logger:

web_server:
  port: 80

# Sensor: DHT22 on GPIO14
sensor:
  - platform: dht
    pin: GPIO14
    model: DHT22
    temperature:
      name: "Kitchen Temperature"
    humidity:
      name: "Kitchen Humidity"
    update_interval: 60s
```

Compile + flash via the dashboard, or CLI:

```sh
esphome compile kitchen-temp.yaml
esphome upload kitchen-temp.yaml --device /dev/ttyUSB0    # first time
# Subsequent flashes are OTA — device's IP or mDNS name
```

## Data & config layout

Inside `/config/`:

- `*.yaml` — one file per device
- `secrets.yaml` — shared secrets (Wi-Fi, API keys) referenced with `!secret`
- `.esphome/` — PlatformIO build cache
- `custom_components/` (if using custom C++ extensions)

## Backup

```sh
# Config dir is everything
tar czf esphome-config-$(date +%F).tgz -C /path/to/config .
```

Keep YAML configs under version control (git) — ESPHome configs are the ideal "commit your infra" case.

## Upgrade

1. Releases: <https://github.com/esphome/esphome/releases>. Monthly (stable) + weekly (beta).
2. HA add-on: update via add-on store.
3. Docker: `docker compose pull && docker compose up -d`.
4. **After upgrading the server, devices need to be recompiled + re-flashed** to use new features — OTA push. The dashboard flags outdated device firmware.
5. **Firmware breaking changes are common** (e.g., ESPHome 2023.12 deprecated many SoC-specific integrations). Read release notes + check each device for deprecated options.

## Gotchas

- **Every device needs its own YAML** — no "group configs" for physically-distinct devices. But **substitutions** + **packages** let you template shared blocks across devices.
- **First flash must be via USB cable**; subsequent flashes are OTA. Plan for "device reboot cycle" when OTA updating; devices are offline for ~15-30s during reboot.
- **API encryption key changes** = HA loses the device; re-pair. Store the key in `secrets.yaml` to avoid accidents.
- **OTA password changes** = future OTA flashes fail; need to factory-reset (USB cable flash). Store OTA password in `secrets.yaml`.
- **ESP chip compatibility**: ESP32 (ESP32-S2, -S3, -C3, -C6, -H2) + ESP8266 + RP2040 + LibreTiny (BK7200). Not all integrations work on all chips; check per-integration docs.
- **Memory is tight on ESP8266** — large configs (many sensors + OLED + multiple buses) can exhaust RAM. ESP32 has much more headroom.
- **Precompiled firmware size** matters for OTA updates — keep configs lean if you're short on flash space (ESP8266 has 1MB; ESP32 typically 4MB).
- **BLE proxying** — ESP32 devices can proxy BLE sensors/devices (e.g., Xiaomi sensors, BT trackers) to HA. Extremely popular feature.
- **mmWave radar** (LD2410, LD2420 series) = the modern "presence detection" darling; better than PIR for stationary occupants.
- **Voice Preview / Assist** — ESPHome devices can be wake-word voice assistants for HA's Assist pipelines. Hardware: ESP32-S3 Box, M5Stack Atom Echo, etc.
- **Firmware flashing tools**: ESPHome web flasher (Chrome/Edge, WebSerial) makes USB flashing trivial from the browser.
- **Factory reset**: hold RESET / BOOT buttons on the chip while powering up, then flash via USB.
- **Dashboard is essentially a front-end for the CLI** — you can do everything from CLI too. Dashboard is just convenient.
- **HA-less use (MQTT mode)** works but gives up a lot — no auto-discovery convenience, more manual wiring. ESPHome shines with HA.
- **Sensors-as-sources-of-truth**: ESPHome devices are real HA entities with state, history, templating, automations. Not second-class citizens.
- **MIT license** — permissive.
- **Open Home Foundation** — ESPHome + Home Assistant + Z-Wave JS + Zigbee2MQTT are all under OHF, committed to open smart-home standards.
- **Alternatives worth knowing:**
  - **Tasmota** — similar concept for Sonoff-class devices; no HA native API (MQTT only); less YAML-friendly
  - **WLED** — LED-strip-specific firmware; excellent for that niche; less general-purpose
  - **ESPEasy** — older, simpler, more drag-and-drop
  - **Arduino IDE / PlatformIO raw** — maximum flexibility, zero training wheels
  - **MicroPython / CircuitPython** — Python on the ESP; different paradigm
  - **Zigbee2MQTT / ZHA** — for Zigbee devices (different hardware entirely)

## Links

- Repo: <https://github.com/esphome/esphome>
- Website / docs: <https://esphome.io>
- Getting started: <https://esphome.io/guides/getting_started_hassio>
- Device examples: <https://esphome.io/devices/>
- All integrations: <https://esphome.io/#integrations>
- Web flasher: <https://web.esphome.io>
- Dashboard Docker: <https://hub.docker.com/r/esphome/esphome>
- HA add-on: <https://github.com/esphome/home-assistant-addon>
- Releases: <https://github.com/esphome/esphome/releases>
- Discord: <https://discord.gg/KhAMKrd>
- Open Home Foundation: <https://www.openhomefoundation.org/>
- Voice Preview Edition: <https://www.home-assistant.io/voice-pe/>
