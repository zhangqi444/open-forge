---
name: webthings-gateway
description: WebThings Gateway recipe for open-forge. Covers Docker install (recommended) and Raspberry Pi. WebThings Gateway is an open-source Web of Things gateway for monitoring and controlling IoT devices over a local network or the web, with no cloud dependency.
---

# WebThings Gateway

Self-hosted Web of Things gateway for monitoring and controlling IoT devices. Based on the W3C Web of Things standard — devices expose a JSON-LD Thing Description that the gateway discovers and displays in a unified dashboard. Supports local control without cloud, rules engine for automation, add-ons for Zigbee/Z-Wave/other protocols, and remote access via Wireguard tunnel. Upstream: <https://github.com/WebThingsIO/gateway>. Website: <https://webthings.io/gateway/>.

**License:** MPL-2.0 · **Language:** Node.js (TypeScript) · **Default port:** 8080 / 4443 · **Stars:** ~2,600

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker | <https://hub.docker.com/r/webthingsio/gateway> | ✅ | **Recommended** as of v2.0 — works on any Linux x86/arm64. |
| Raspberry Pi image | <https://github.com/WebThingsIO/gateway/releases> | ✅ | Dedicated Pi appliance with full hardware integration. |
| Snap package | <https://snapcraft.io/webthings-gateway> | ✅ | Experimental — Ubuntu/Snap-enabled systems. |
| Build from source | <https://github.com/WebThingsIO/gateway/blob/master/README.md> | ✅ | Development / custom hardware. |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| preflight | "Install method — Docker, Raspberry Pi image, or source build?" | AskUserQuestion | Determines section. |
| port_http | "HTTP port to expose? (default: 8080)" | Free-text | Docker. |
| port_https | "HTTPS port to expose? (default: 4443)" | Free-text | Docker. |
| data_dir | "Host directory for persistent gateway data? (default: ~/webthings)" | Free-text | Docker. |
| remote_access | "Enable remote access via WebThings tunnel?" | AskUserQuestion: Yes / No | Optional — requires webthings.io account. |

## Install — Docker (recommended)

Reference: <https://hub.docker.com/r/webthingsio/gateway>

```bash
mkdir -p ~/webthings

docker run -d \
  --name webthings-gateway \
  --restart unless-stopped \
  --network host \
  -v ~/webthings:/home/user/.mozilla-iot \
  webthingsio/gateway:latest
```

> **`--network host` is recommended** for device discovery — many IoT protocols (mDNS, Zigbee/Z-Wave USB passthrough) require host networking to reach devices on the local network.

Or with Docker Compose:

```yaml
services:
  webthings:
    image: webthingsio/gateway:latest
    restart: unless-stopped
    network_mode: host
    volumes:
      - ~/webthings:/home/user/.mozilla-iot
    # If not using --network host:
    # ports:
    #   - "8080:8080"
    #   - "4443:4443"
    devices:
      # Uncomment to pass through Zigbee/Z-Wave USB adapter
      # - /dev/ttyUSB0:/dev/ttyUSB0
      # - /dev/ttyACM0:/dev/ttyACM0
```

Access the web UI at: `http://<host-ip>:8080`

On first visit you'll be guided through creating an admin account and configuring the gateway.

## Install — Raspberry Pi image

1. Download the latest Pi image from <https://github.com/WebThingsIO/gateway/releases> (look for `.img.zip` files)
2. Flash to a microSD card with Raspberry Pi Imager or Balena Etcher
3. Boot the Pi — it creates a Wi-Fi hotspot `WebThings Gateway` during setup
4. Connect to the hotspot and navigate to `http://192.168.220.1` to complete setup
5. Configure your Wi-Fi network and the gateway joins your LAN

## USB device passthrough (Zigbee/Z-Wave)

For USB adapters (ConBee, Aeotec Z-Stick, etc.), pass the device to the container:

```bash
# Find device
ls /dev/ttyUSB* /dev/ttyACM*

# Add to docker run
docker run -d \
  --name webthings-gateway \
  --restart unless-stopped \
  --network host \
  --device /dev/ttyUSB0:/dev/ttyUSB0 \
  -v ~/webthings:/home/user/.mozilla-iot \
  webthingsio/gateway:latest
```

Install the Zigbee or Z-Wave add-on from within the gateway UI → Add-ons.

## Software-layer concerns

| Concern | Detail |
|---|---|
| Network mode | `--network host` required for mDNS device discovery and local protocol add-ons. Without it, devices on the LAN may not be discoverable. |
| Data persistence | Gateway config, device definitions, rules, and certificates stored in `~/.mozilla-iot`. Mount as a volume. |
| HTTPS (self-signed) | Gateway generates a self-signed TLS certificate on first boot at port 4443. Browser will warn — add the cert exception or use remote access for a proper cert. |
| Remote access | Optional — creates a Wireguard tunnel to webthings.io servers, giving a `*.webthings.io` HTTPS URL. Requires a (free) webthings.io account. |
| Add-ons | Install protocol adapters (Zigbee, Z-Wave, MQTT, Philips Hue, etc.) from the in-app Add-ons store. Each add-on is a separate process. |
| Rules engine | Visual rules editor: "when [thing] does X, then [thing] does Y". No coding required. |
| Thing Description | Devices expose a W3C WoT Thing Description (JSON-LD). Compatible WoT devices auto-populate properties/events/actions. |
| ARM support | Multi-arch image available (amd64 + arm64/armv7 for Pi). |

## Upgrade procedure

```bash
docker pull webthingsio/gateway:latest
docker compose up -d
```

Configuration and device data are preserved in the mounted volume.

## Gotchas

- **`--network host` for discovery:** Without host networking, mDNS-based discovery (Philips Hue, network devices) and some USB add-ons won't work. Use host mode unless you have a specific reason not to.
- **Self-signed cert browser warning:** Port 4443 uses a self-signed cert. Add a browser exception for local access, or enable remote access for a CA-signed cert via webthings.io.
- **USB device permissions:** On the Pi or bare-metal, the user running the gateway needs to be in the `dialout` group for serial/USB access: `sudo usermod -aG dialout $USER`.
- **Beta/active development:** The 2.x release series has some rough edges. Check <https://github.com/WebThingsIO/gateway/issues> if devices don't appear as expected.
- **Not Mozilla IoT anymore:** The project was originally Mozilla WebThings. It was spun out to the WebThings community after Mozilla discontinued it. Development continues but at a slower pace.
- **Wi-Fi adapter add-on:** On the Pi image, the gateway can create a Wi-Fi hotspot during onboarding — this doesn't apply to Docker installs. Wi-Fi setup for Docker must be done at the host OS level.

## Upstream links

- GitHub: <https://github.com/WebThingsIO/gateway>
- Docker Hub: <https://hub.docker.com/r/webthingsio/gateway>
- Documentation: <https://webthings.io/docs/gateway/>
- Installation guide: <https://webthings.io/docs/gateway/installation/>
- Add-ons: <https://webthings.io/addons/>
- Website: <https://webthings.io/gateway/>
