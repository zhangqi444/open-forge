---
name: diyHue
description: "Open-source Philips Hue Bridge emulator. ZigBee + MiLight + Neopixel + ESP8266 bulbs. No cloud by design. Python. RPi-friendly. diyhue/diyHue. Discourse + Slack."
---

# diyHue

diyHue is **"Philips Hue Bridge — but open-source + no-cloud + works with cheap bulbs"** — a Hue Bridge emulator. Controls ZigBee lights (Raspbee, real Hue Bridge, IKEA Trådfri gateway), MiLight bulbs (via MiLight Hub), Neopixel strips (WS2812B, SK6812), and cheap ESP8266-based bulbs (by flashing custom firmware). **Two-way sync** with Philips/Trådfri sensors + switches. RPi-friendly. No cloud by design.

Built + maintained by **diyhue** org. Python. Arduino sketches for Hue Dimmer/Tap/Motion switches. Discourse forum + Slack community. Docker Hub multi-arch (arm + amd64). diyhue.org + diyhue.discourse.group. GPL likely.

Use cases: (a) **Hue-app-compatible bridge without Philips hardware** (b) **cheap-ESP8266-bulbs as Hue lights** (c) **Neopixel strip → Hue-controllable** (d) **MiLight integration** (e) **no-cloud smart-home** (f) **RPi always-on light controller** (g) **multi-protocol light hub** (h) **Trådfri + Hue combined**.

Features (per README):

- **Hue Bridge emulator**
- **ZigBee** (Raspbee/Hue Bridge/Trådfri)
- **MiLight** (via MiLight Hub)
- **Neopixel** (WS2812B, SK6812)
- **ESP8266 bulbs** (custom firmware)
- **Two-way sync** with Hue/Trådfri devices
- **No cloud** by design
- **Python**; **RPi-friendly**
- **Multi-arch Docker** (arm + amd64)
- **Arduino sketches** for Hue Dimmer/Tap/Motion

- Upstream repo: <https://github.com/diyhue/diyHue>
- Website: <https://diyhue.org>
- Discourse: <https://diyhue.discourse.group>
- Slack: <https://diyhue.slack.com>
- Docker: <https://hub.docker.com/r/diyhue/core>

## Architecture in one minute

- **Python**
- SSDP discovery (Hue-protocol compat)
- Lightweight — runs on RPi
- **Resource**: very low
- **Ports**: 80, 443, 1900 (SSDP)

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker**         | `diyhue/core` multi-arch                                                                                               | **Primary**                                                                                   |
| **Native**         | Python install                                                                                                         | Alt — RPi                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Radio hardware       | Raspbee/Trådfri Gateway                                     | Hardware     | For ZigBee                                                                                    |
| Network              | L2 broadcast reach                                          | Network      | **Host-network recommended for SSDP**                                                                                    |
| ESP8266 bulbs        | With custom firmware                                        | Hardware     | Optional                                                                                    |
| MiLight hub          | If using MiLight                                            | Hardware     | Optional                                                                                    |

## Install via Docker

Per diyhue.org + README:
```yaml
services:
  diyhue:
    image: diyhue/core:latest        # **pin** — multi-arch
    network_mode: host        # **SSDP needs L2**
    volumes:
      - ./diyhue-config:/opt/hue-emulator/config
    restart: unless-stopped
```

## First boot

1. Host-network mandatory (SSDP)
2. Start container
3. Open Hue app; discover bridge
4. Pair lights (via radio hardware or ESP firmware)
5. Test Hue-app control + switches
6. Back up `/config`

## Data & config layout

- `/opt/hue-emulator/config/` — lights, sensors, rules, scenes

## Backup

```sh
sudo tar czf diyhue-$(date +%F).tgz diyhue-config/
# Contains: light + sensor + rule topology (+ Hue app creds)
```

## Upgrade

1. Releases: <https://github.com/diyhue/diyHue/releases>
2. Docker pull + restart
3. Watch for breaking changes

## Gotchas

- **183rd HUB-OF-CREDENTIALS Tier 2 — SMART-HOME-LIGHT-CONTROL**:
  - Holds: Hue-app credentials, light topology, sensor/motion rules, ESP firmware flashing creds
  - Controls physical devices (lights)
  - **183rd tool in hub-of-credentials family — Tier 2**
- **HOST-NETWORK-MODE-REQUIRED**:
  - SSDP discovery needs L2 broadcast
  - **Recipe convention: "host-network-mode-SSDP-discovery-requirement"** reinforces Home Assistant precedents
- **ESP8266-FIRMWARE-FLASHING**:
  - User flashes custom firmware onto bulbs
  - Cheap bulbs become Hue-compat
  - **Recipe convention: "custom-firmware-flashing-commodity-hardware positive-signal"**
  - **NEW positive-signal convention** (diyHue 1st formally)
- **NO-CLOUD-BY-DESIGN**:
  - Explicit positioning
  - **Recipe convention: "no-cloud-by-design-explicit-positioning positive-signal"**
  - Reinforces Gmail Cleaner (125) "data-never-leaves-machine"
- **MULTI-PROTOCOL-IOT-BRIDGE**:
  - ZigBee + MiLight + Neopixel + ESP8266
  - **Recipe convention: "multi-protocol-IoT-bridge positive-signal"**
  - **NEW positive-signal convention** (diyHue 1st formally)
- **RPI-FRIENDLY-LIGHTWEIGHT**:
  - Runs on RPi 24/7
  - **Resource-lightweight-RPi-friendly: 3 tools** (Pi-hole+AdGuard Home+diyHue) 🎯 **3-TOOL MILESTONE**
  - **NEW family formally tracked** (RPi-specific hardware-target)
- **DISCOURSE-FORUM-COMMUNITY**:
  - Primary community on Discourse
  - **Discourse-community-channel: 1 tool** 🎯 **NEW FAMILY** (diyHue)
  - **Multi-community-channel-presence: 5 tools** (+diyHue w/ Discourse + Slack) 🎯 **5-TOOL MILESTONE**
- **SLACK-COMMUNITY-CHANNEL**:
  - Slack (not Discord)
  - **Slack-community-channel: 1 tool** 🎯 **NEW FAMILY** (diyHue — distinct from Discord/Matrix/IRC)
- **MULTI-ARCH-DOCKER**:
  - arm + amd64
  - **Multi-arch-Docker-image: 3 tools** 🎯 **3-TOOL MILESTONE** (reinforces diverse-arch-supply-chain)
- **DECADE-PLUS-OSS**:
  - Old project (Hue emulation predates this by years)
  - **Decade-plus-OSS: 13 tools** (+diyHue) 🎯 **13-TOOL MILESTONE**
- **INSTITUTIONAL-STEWARDSHIP**: diyhue org + diyhue.org + Discourse + Slack + Docker multi-arch + CI + multi-protocol. **169th tool — IoT-community-funded-tool sub-tier** (NEW-soft).
- **TRANSPARENT-MAINTENANCE**: active + CI + Discourse + Slack + Docker + releases. **175th tool in transparent-maintenance family.**
- **SMART-HOME-LIGHT-BRIDGE-CATEGORY:**
  - **diyHue** — Hue emulator; multi-protocol; no-cloud
  - **deCONZ / Phoscon** — Raspbee vendor
  - **Zigbee2MQTT** — generic ZigBee to MQTT
  - **Home Assistant** — ecosystem (not a bridge per se)
  - **Hubitat** — commercial appliance
- **ALTERNATIVES WORTH KNOWING:**
  - **Zigbee2MQTT** — if you want MQTT-to-HA
  - **Hue Bridge (real)** — if you have Philips ecosystem
  - **Choose diyHue if:** you want Hue-app-compat + cheap-bulbs + multi-protocol + no-cloud.
- **PROJECT HEALTH**: active + forum + Slack + Docker + CI + multi-arch. Strong.

## Links

- Repo: <https://github.com/diyhue/diyHue>
- Website: <https://diyhue.org>
- Zigbee2MQTT (alt): <https://github.com/Koenkk/zigbee2mqtt>
- Home Assistant: <https://github.com/home-assistant/core>
