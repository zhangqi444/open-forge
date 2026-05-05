---
name: Tasmota
description: "Open-source alternative firmware for ESP8266 and ESP32 IoT devices — enables local MQTT/HTTP/WebUI control with no cloud dependency. C/C++. GPL-3.0."
---

# Tasmota

Tasmota is open-source alternative firmware for ESP8266 and ESP32-based IoT devices (smart plugs, switches, bulbs, sensors, relays, and more). It replaces the stock cloud-dependent firmware with local-only control via MQTT, HTTP REST API, WebUI, or serial — with zero requirement for external cloud services.

Created by Theo Arends (arendst). One of the most widely-used IoT firmware projects; 24,000+ GitHub stars and a massive device compatibility community.

Use cases: (a) flash commercial smart plugs/switches to remove cloud dependency (b) build custom ESP8266/ESP32 IoT devices (c) integrate home automation (Home Assistant, OpenHAB, Domoticz) via MQTT (d) OTA-update and manage a fleet of ESP devices (e) data logging and local automation without internet.

Features:

- **Local control** — MQTT, HTTP API, WebUI, KNX, Serial; no cloud required
- **OTA updates** — update firmware over-the-air via WebUI or `http://device/ota`
- **Rules engine** — built-in scripting for device-local automation (timers, conditions, actions)
- **MQTT integration** — publishes telemetry + responds to commands; integrates with any MQTT broker
- **Home automation** — first-class Home Assistant, OpenHAB, Domoticz, ioBroker integration
- **Sensors** — DHT11/22, BME280, DS18B20, AHT10, SHT30, and 100+ other sensors
- **Energy monitoring** — power consumption, voltage, current (for compatible devices)
- **Berry scripting** — Lua-like scripting language for advanced automation on ESP32
- **WebUI** — built-in web interface on every device; no app needed
- **Templates** — device configuration templates for thousands of commercial devices
- **Modular builds** — minimal to full builds; trims binary size for flash-constrained devices
- **Platforms** — ESP8266, ESP32, ESP32-S2, ESP32-S3, ESP32-C3, ESP32-C6; PlatformIO-based

- Upstream repo: https://github.com/arendst/Tasmota
- Homepage: https://tasmota.github.io/
- Docs: https://tasmota.github.io/docs/
- Device templates: https://templates.blakadder.com/
- Web installer: https://tasmota.github.io/install/

## Architecture

Tasmota is firmware — it runs *on* the ESP device, not on a server. The "self-hosted" aspect is that:

1. You flash Tasmota to the device (replaces vendor firmware)
2. The device connects to your local MQTT broker and/or responds to HTTP API calls
3. Your home automation platform (Home Assistant, etc.) communicates with the device locally

There is no Tasmota server to run. The only server-side component you need is an MQTT broker (Mosquitto, EMQX, etc.) if you want MQTT-based control.

## Compatible install methods

| Method            | Tool                                 | Notes                                                          |
|-------------------|--------------------------------------|----------------------------------------------------------------|
| Web installer     | https://tasmota.github.io/install/   | Easiest; Chrome-based; flash via USB in browser                |
| Tasmotizer        | GUI app (Windows/Linux/Mac)          | Desktop GUI flasher                                            |
| esptool.py        | CLI (`pip install esptool`)          | Universal; works with any ESP device                           |
| PlatformIO        | Custom build + flash                 | For developers; allows code customization                      |
| OTA (upgrade)     | WebUI → Firmware Upgrade             | Once Tasmota is installed; updates without USB                 |

## Inputs to collect

| Input           | Example                        | Phase      | Notes                                                      |
|-----------------|--------------------------------|------------|------------------------------------------------------------|
| WiFi SSID/pass  | `HomeNet` / `pass123`          | Setup      | Enter in WiFi captive portal on first boot                 |
| MQTT broker     | `192.168.1.10:1883`            | MQTT       | Your local broker; set in WebUI → Configuration → MQTT    |
| MQTT topic      | `tasmota/plug1`                | MQTT       | Customize per device for easy identification               |
| Device template | from templates.blakadder.com   | Config     | Defines GPIO pin assignments for your specific device      |

## Initial setup flow

1. **Flash** — use web installer or esptool to flash `tasmota.bin` (or variant) to device
2. **WiFi setup** — device creates `tasmota-XXXXXX` hotspot; connect and enter your WiFi creds
3. **Find device IP** — check router DHCP leases or use `tasmota-discovery`
4. **Configure** — open `http://<device-ip>/`; set MQTT broker, device name, template
5. **Test** — toggle via WebUI; verify MQTT messages arrive at broker
6. **Integrate** — add to Home Assistant (auto-discovered via MQTT Discovery) or OpenHAB

## WebUI control

Every Tasmota device runs a web server at its IP address:

```
http://192.168.1.xxx/          → main dashboard
http://192.168.1.xxx/cm?cmnd=Power%20on   → HTTP command API
http://192.168.1.xxx/ota       → OTA update
```

## MQTT command examples

```
# Turn on (topic format: cmnd/<topic>/Power)
cmnd/tasmota_plug1/Power ON

# Query state
cmnd/tasmota_plug1/Power

# Device responds on:
stat/tasmota_plug1/POWER  → ON/OFF
tele/tasmota_plug1/STATE  → JSON telemetry
tele/tasmota_plug1/SENSOR → sensor readings
```

## Tasmota build variants

| Variant          | Use case                                              |
|------------------|-------------------------------------------------------|
| `tasmota.bin`    | Standard; most sensors; English                       |
| `tasmota-lite`   | Minimal; for flash-constrained devices                |
| `tasmota32`      | ESP32 standard build                                  |
| `tasmota-sensors`| Extended sensor support                               |
| `tasmota-display`| Display support (SSD1306, etc.)                       |
| `tasmota-ir`     | IR transmitter/receiver                               |
| `tasmota-zbbridge`| Zigbee coordinator                                   |

## Home Assistant integration

Tasmota devices are auto-discovered via MQTT Discovery when:
1. Your MQTT broker is connected to Home Assistant
2. Tasmota's `SetOption19 1` (MQTT discovery) is enabled (default in recent versions)

Then devices appear automatically in HA without manual YAML config.

## Gotchas

- **Safety warning — mains electricity** — many ESP-based smart plugs operate on mains AC. Flashing them requires opening the device. **Never flash while connected to AC power.** This is genuinely dangerous; electrocution risk is real.
- **Not all devices are flashable OTA** — newer Sonoff and Tuya devices have introduced flash protection. Check templates.blakadder.com *before* buying to confirm the device is flashable. Older devices (pre-2021 Tuya) were often easily flashable; newer ones use locked chips.
- **Tuya-Convert is mostly dead** — the OTA exploit that allowed flashing Tuya devices without opening them was patched. Most new Tuya devices require physical serial flashing.
- **Binary size limits on ESP8266** — ESP8266 has 1–4 MB flash. Tasmota full build is ~600 KB; some minimal-flash devices (512 KB) require tasmota-lite with limited features.
- **WiFi 2.4 GHz only** — ESP8266 and most ESP32 variants support only 2.4 GHz WiFi. Ensure your network has a 2.4 GHz band available. Some newer ESP32-S3/C6 support WiFi 6/5 GHz.
- **Upgrade path matters** — read the migration docs before jumping major versions. Some versions have one-way configuration changes. Always OTA to a full build first; never minimal→minimal.
- **MQTT broker required for HA integration** — Tasmota's Home Assistant integration assumes MQTT. While HTTP API works, MQTT is the standard path for HA. Run Mosquitto (or another broker) on your home server.
- **Berry scripting (ESP32 only)** — the Berry scripting engine for local automation rules only runs on ESP32. ESP8266 devices have a simpler Rules engine.
- **Device templates are community-maintained** — templates.blakadder.com has thousands of devices but not all are tested. Verify GPIO assignments against your device's FCC teardown photos if a template behaves unexpectedly.
- **Alternatives:** ESPHome (YAML-configured, deep HA integration, compiles custom firmware per device), Homebridge (non-ESP; bridges non-HomeKit devices to Apple HomeKit), OpenMQTTGateway (for RF/BLE/Zigbee bridging).

## Links

- Repo: https://github.com/arendst/Tasmota
- Homepage: https://tasmota.github.io/
- Documentation: https://tasmota.github.io/docs/
- Web installer: https://tasmota.github.io/install/
- Device templates: https://templates.blakadder.com/
- Getting started: https://tasmota.github.io/docs/Getting-Started/
- MQTT commands: https://tasmota.github.io/docs/Commands/
- Home Assistant integration: https://tasmota.github.io/docs/Home-Assistant/
- Firmware binaries: https://ota.tasmota.com/tasmota/release/
- Releases: https://github.com/arendst/Tasmota/releases
