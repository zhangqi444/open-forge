---
name: lha
description: LHA (Light Home Automation) recipe for open-forge. Extensible home automation app supporting ConBee/ZigBee, Philips Hue, Z-Wave JS, Blockly automation, and Lua scripting. MIT, Lua-based. Source: https://github.com/javalikescript/lha
---

# LHA (Light Home Automation)

A lightweight, fully extensible home automation application built in pure Lua. Bridges incompatible protocols (ZigBee via ConBee, Philips Hue, Z-Wave JS), records historical sensor data, and lets you compose automations using Blockly visual scripting or Lua code. Web-based interface with custom HTML/Vue.js view design. Runs on Raspberry Pi, WD MyCloud, any Linux/Windows machine. MIT licensed. Upstream: <https://github.com/javalikescript/lha>

## Compatible Combos

| Infra | Runtime | Notes |
|---|---|---|
| Raspberry Pi / ARM Linux | Native Lua binary | Primary target; ~5MB, no dependencies |
| Any Linux / Windows | Native Lua binary | Download release for your OS |
| Home server (Linux) | Native binary + systemd | For persistent background operation |

## Inputs to Collect

### Phase 1 — Preflight

| Prompt | Format | Notes |
|---|---|---|
| "What OS/architecture?" | Linux-x64 / Linux-arm / Windows / etc. | Selects the correct release binary |
| "Which smart home protocols/devices?" | ConBee / Hue / Z-Wave JS / other | Determines which extensions to configure |
| "Port for web interface?" | Number | Default port varies; accessible in browser after launch |

### Phase 2 — Deploy

| Prompt | Format | Notes |
|---|---|---|
| "ConBee bridge URL?" | URL | e.g. http://192.168.1.x/api — requires authorised API user |
| "Philips Hue bridge IP + user?" | IP + user token | Hue bridge must already be set up |
| "Z-Wave JS websocket URL?" | URL | If using Z-Wave JS integration |

## Software-Layer Concerns

- **Single-process Lua**: The entire application is a single Lua process — scheduler + HTTP server + extension manager. Very lightweight.
- **No database**: Historical device values stored in dedicated time-based log files (not a SQL database).
- **Web of Things API**: Exposes a Thing Description JSON API compatible with the W3C Web of Things spec.
- **Extensions**: Core extensions bundled; additional extensions can be added. ConBee, Hue, Z-Wave JS, and others available via the extension section in the UI.
- **Blockly automation**: Visual block-based scripting for automations (e.g. "send SMS on intrusion" example in upstream docs).
- **Custom views**: Design custom web dashboards using HTML and Vue.js.
- **Device mapping**: New devices supported by editing extension JSON mapping files — flexible but requires some understanding of the protocol.
- **~5MB**: Entire application including embedded web libraries is about 5MB. No npm, no pip, no apt dependencies.

## Deployment

### Native binary (recommended)

```bash
# Download the release for your OS from:
# https://github.com/javalikescript/lha/releases/latest

# Example: Linux x64
curl -LO https://github.com/javalikescript/lha/releases/latest/download/lha-linux-x64.zip
unzip lha-linux-x64.zip -d /opt/lha
cd /opt/lha

# Run
bin/lua lha.lua -ll info

# Open browser at http://localhost:<port>
# Go to Extensions to add and configure ConBee, Hue, Z-Wave JS, etc.
```

### systemd service (Linux)

```ini
[Unit]
Description=LHA Light Home Automation
After=network.target

[Service]
User=lha
WorkingDirectory=/opt/lha
ExecStart=/opt/lha/bin/lua lha.lua -ll info
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

## Upgrade Procedure

1. Download new release from https://github.com/javalikescript/lha/releases/latest
2. Stop the service.
3. Extract new release over the existing directory (config and log files in the data directory are preserved).
4. Restart the service.

## Gotchas

- **ConBee/Hue authorised user required**: Must generate an authorised API user on your ConBee or Hue bridge before LHA can control devices.
- **Z-Wave JS websocket**: Z-Wave JS must be running separately (e.g. Z-Wave JS UI Docker container) and LHA connects to its websocket.
- **Single process**: No clustering or HA support — one LHA instance per home. Fine for typical home automation.
- **Lua knowledge helpful**: Basic automations use Blockly (visual), but advanced customisation requires Lua scripting.
- **Device mapping**: Adding new Zigbee/Z-Wave device models requires editing JSON extension files — check upstream `devices.md` for already-supported models.
- **Log files grow over time**: Historical sensor data accumulates in log files — monitor disk usage on small devices like Raspberry Pi.

## Links

- Source: https://github.com/javalikescript/lha
- Releases: https://github.com/javalikescript/lha/releases
- Extensions docs: https://github.com/javalikescript/lha/blob/main/extensions.md
- Supported devices: https://github.com/javalikescript/lha/blob/main/devices.md
- luajls (Lua framework): https://github.com/javalikescript/luajls
