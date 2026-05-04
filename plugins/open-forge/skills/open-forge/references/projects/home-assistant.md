# Home Assistant

Open-source home automation platform that puts local control and privacy first. Integrates with 3,000+ devices and services — lights, locks, thermostats, cameras, media players, and more — without cloud dependency. 74K+ GitHub stars. Apache 2.0. Upstream: <https://github.com/home-assistant/core>. Docs: <https://www.home-assistant.io/docs>.

> **Recommended install: Home Assistant OS (HAOS).** Running HA in Docker is supported but loses some features (add-ons, supervisor). For full functionality use HAOS on dedicated hardware (Raspberry Pi, NUC, etc.) or a VM.

## Compatible install methods

Verified against upstream docs at <https://www.home-assistant.io/installation/>.

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| **Home Assistant OS (HAOS)** | Flash image to SD card / USB / VM | ✅ | **Recommended.** Full feature set: add-ons, supervisor, backups. |
| Home Assistant Supervised | Debian install script | ✅ | Full feature set on existing Debian system. Requires strict OS constraints. |
| Home Assistant Container | `docker run homeassistant/home-assistant` | ✅ | Docker-only. No add-ons, no supervisor. Config files managed manually. |
| Home Assistant Core | `pip install homeassistant` + `hass` CLI | ✅ | Advanced: Python virtualenv, bare metal. |
| Proxmox VE helper script | Community: <https://tteck.github.io/Proxmox/> | Community | Popular for Proxmox users. |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| install_method | "Install method: HAOS image, Docker container, or Core?" | `AskUserQuestion`: `HAOS / VM image`, `Docker container`, `Core (Python)` | All |
| hardware | "Target hardware (Raspberry Pi 4/5, NUC, VM, other)?" | Free-text | HAOS |
| port | "Home Assistant port (default: `8123`)?" | Free-text | Docker/Core |

## Software-layer concerns

### Home Assistant OS (recommended)

1. Download the HAOS image for your hardware: <https://www.home-assistant.io/installation/>
2. Flash to SD card or SSD using Balena Etcher or Raspberry Pi Imager
3. Boot and wait 5–10 minutes for first-run setup
4. Visit `http://homeassistant.local:8123` (or `http://<ip>:8123`)

For a VM (Proxmox, VirtualBox, VMware): download the `.ova` or `.qcow2` image and import.

### Docker (Container mode)

```yaml
version: "3"
services:
  homeassistant:
    container_name: homeassistant
    image: ghcr.io/home-assistant/home-assistant:stable
    volumes:
      - ./config:/config
      - /etc/localtime:/etc/localtime:ro
    restart: unless-stopped
    privileged: true
    network_mode: host    # required for device discovery (mDNS, SSDP, etc.)
    environment:
      - TZ=America/New_York
```

```bash
docker compose up -d
# Access at http://localhost:8123
```

> **`network_mode: host` is required** for device auto-discovery (Chromecast, Sonos, Z-Wave, Zigbee, etc.) to work correctly. Bridged networking breaks multicast/broadcast discovery.

### Key environment variables

| Variable | Purpose |
|---|---|
| `TZ` | Container timezone (e.g. `America/New_York`) |

Most configuration is done via the `configuration.yaml` file and the web UI — not environment variables.

### Configuration directory structure

```
config/
├── configuration.yaml      # Main config (integrations, entities, automations)
├── automations.yaml        # Automation rules (managed by UI)
├── scripts.yaml            # Scripts (managed by UI)
├── scenes.yaml             # Scenes (managed by UI)
├── secrets.yaml            # Sensitive values (passwords, API keys)
├── .storage/               # Runtime state (do NOT edit manually)
└── custom_components/      # HACS-installed custom integrations
```

### Key concepts

| Concept | Description |
|---|---|
| **Integration** | Connects HA to a device/service (Philips Hue, Google Cast, etc.) |
| **Entity** | A single controllable thing (light, switch, sensor, etc.) |
| **Automation** | If-this-then-that rules (trigger → condition → action) |
| **Script** | Reusable sequence of actions |
| **Scene** | Snapshot of entity states to restore |
| **Dashboard** | Customizable UI panel with cards |
| **Add-on** (HAOS only) | Supplementary service (Mosquitto MQTT, Zigbee2MQTT, ESPHome, etc.) |
| **HACS** | Home Assistant Community Store — install community integrations |

### Ports

| Port | Service |
|---|---|
| `8123` | Home Assistant web UI + API |
| `5353` | mDNS (discovery) |

### Remote access

Home Assistant offers **Nabu Casa** ($6.50/mo) for zero-config remote access, or self-configure:
- NGINX/Caddy reverse proxy with TLS
- Tailscale (recommended for private remote access)
- DuckDNS + Let's Encrypt

> **Do not expose HA directly to the internet on port 8123.** Always use a reverse proxy with HTTPS.

## Upgrade procedure

- **HAOS:** Settings → System → Updates → click the update notification
- **Docker:** `docker pull ghcr.io/home-assistant/home-assistant:stable && docker compose up -d`
- **Core:** `pip install --upgrade homeassistant`

Always **back up first**: Settings → System → Backups → Create backup.

## Gotchas

- **Network mode host is mandatory for Docker.** Without `network_mode: host`, Chromecast, Sonos, Apple TV, and most LAN device discovery won't work.
- **HAOS vs Container feature gap.** Docker Container mode loses: add-ons, Supervisor, OS-level backups, and one-click updates. For full functionality use HAOS.
- **Supervised requires strict Debian.** Home Assistant Supervised is only officially supported on Debian 12 (no snap, no non-standard Docker). Drift from this causes "Unsupported" warnings in the UI.
- **`secrets.yaml` for sensitive values.** Never put API keys or passwords directly in `configuration.yaml`. Use `!secret my_api_key` referencing `secrets.yaml`.
- **Time zone matters.** Set `TZ` in Docker or `homeassistant: time_zone:` in `configuration.yaml`. Wrong timezone causes automation timing issues.
- **Python version pinned.** HA Core requires a specific Python version (check release notes). Don't use system Python.
- **Z-Wave / Zigbee requires USB passthrough.** Pass USB dongles to the container with `devices: [/dev/ttyUSB0:/dev/ttyUSB0]` or use network-attached controllers.
- **License: Apache 2.0.** Core is fully open source. Nabu Casa cloud remote access is a paid optional service.

## Links

- Upstream: <https://github.com/home-assistant/core>
- Docs: <https://www.home-assistant.io/docs>
- Installation guide: <https://www.home-assistant.io/installation/>
- Docker install: <https://www.home-assistant.io/installation/linux#docker-compose>
- Integrations: <https://www.home-assistant.io/integrations/>
- HACS: <https://hacs.xyz>
- Community forum: <https://community.home-assistant.io>
