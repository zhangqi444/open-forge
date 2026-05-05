---
name: gladys
description: Gladys Assistant recipe for open-forge. Privacy-first open-source smart home assistant. Deployed as a single privileged Docker container with host networking for device discovery (Zigbee, Z-Wave, MQTT, etc.). Covers Docker run, Docker Compose, and Raspberry Pi setup. Based on upstream docs at https://gladysassistant.com/docs.
---

# Gladys Assistant

Privacy-first, open-source smart home assistant. Upstream: <https://github.com/GladysAssistant/Gladys>. Docs: <https://gladysassistant.com/docs>.

**License:** Apache-2.0

Gladys runs as a **single Docker container** with privileged + host networking to access local devices (Zigbee dongles, Z-Wave sticks, Bluetooth, MQTT brokers, etc.). It includes a built-in SQLite database and a web UI accessible on the local network.

## Key features

- **Device integration** — Zigbee (via Zigbee2MQTT), Z-Wave, MQTT, Philips Hue, Sonos, Xiaomi, Tuya, and many more
- **Scenes and automations** — time-based, sensor-triggered, and calendar-driven automations
- **Dashboard** — customizable home dashboard with device controls, camera feeds, charts
- **AI chat** — built-in AI assistant for natural language home control
- **Remote access** — optional Gladys Plus subscription for secure remote access (or self-host a reverse proxy)
- **Voice assistants** — integrations with Google Home and Amazon Alexa
- **Privacy-first** — all data stays local by default; no cloud account required

## Compatible deploy methods

| Method | Upstream doc | When to use |
|---|---|---|
| Docker run | README / <https://gladysassistant.com/docs> | Quick start, any Linux machine |
| Docker Compose | <https://gladysassistant.com/docs/installation/docker-compose/> | Preferred for reproducible/managed setups |
| Raspberry Pi | <https://gladysassistant.com/docs> | Most common home automation use case |
| NAS / mini-PC | <https://gladysassistant.com/docs> | Any Linux device with Docker |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | Linux host with Docker? | Gladys requires Docker |
| preflight | Server timezone? | Set in `TZ` env var (e.g. `Europe/Paris`, `America/New_York`) |
| preflight | USB devices to access? | Zigbee/Z-Wave dongles typically at `/dev/ttyUSB0` or `/dev/ttyACM0` |
| optional | Gladys Plus for remote access? | <https://plus.gladysassistant.com> — optional paid subscription |

## Deploy: Docker run

Upstream reference: <https://github.com/GladysAssistant/Gladys#readme>

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

After start, open `http://<server-ip>` in your browser and complete the setup wizard (create admin account, configure your home, add integrations).

**Key parameters:**
- `TZ` — set to your local timezone (IANA format, e.g. `America/Los_Angeles`)
- `SERVER_PORT` — change if port 80 is already in use (e.g. `8080`)
- `-v /dev:/dev` — exposes USB devices (Zigbee/Z-Wave sticks) to the container
- `-v /run/udev:/run/udev:ro` — enables device auto-discovery

## Deploy: Docker Compose

Upstream reference: <https://gladysassistant.com/docs/installation/docker-compose/>

```yaml
# docker-compose.yml
services:
  gladys:
    image: gladysassistant/gladys:v4
    container_name: gladys
    restart: always
    privileged: true
    network_mode: host
    logging:
      driver: json-file
      options:
        max-size: "10m"
    environment:
      NODE_ENV: production
      SERVER_PORT: 80
      TZ: Europe/Paris
      SQLITE_FILE_PATH: /var/lib/gladysassistant/gladys-production.db
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - /var/lib/gladysassistant:/var/lib/gladysassistant
      - /dev:/dev
      - /run/udev:/run/udev:ro
    cgroupns: host
```

```bash
docker compose up -d
```

## Ports

| Port | Purpose |
|---|---|
| 80 (default) | Gladys web UI (configurable via `SERVER_PORT`) |

Gladys uses host networking so it can discover devices and mDNS services on the local network.

## Upgrade

```bash
docker pull gladysassistant/gladys:v4
docker stop gladys && docker rm gladys
# Re-run the original docker run command
```

With Docker Compose:
```bash
docker compose pull && docker compose up -d
```

## Remote access

By default Gladys is local-only. Options for secure remote access:

1. **Gladys Plus** — official paid subscription (<https://plus.gladysassistant.com>) that provides an encrypted tunnel; no port-forwarding required.
2. **Reverse proxy** — put Nginx/Caddy/Traefik in front with TLS. Because Gladys uses host networking, point your proxy to `127.0.0.1:<SERVER_PORT>`.
3. **VPN** — WireGuard/Tailscale/ZeroTier to access the local network remotely.

## Gotchas

- **`--privileged` + `--network=host` required** — needed to access USB devices (Zigbee/Z-Wave), Bluetooth, and perform device discovery via mDNS/UPnP on the local network segment.
- **Raspberry Pi 4/5 recommended** — Gladys is lightweight enough for a Pi. On Pi OS, Docker must be installed first (`curl -fsSL https://get.docker.com | sh`).
- **USB device permissions** — on some systems you need to add the Docker user to the `dialout` group: `sudo usermod -aG dialout $USER`. Log out and back in for it to take effect.
- **Port conflicts** — Gladys defaults to port 80. If another service uses port 80, set `SERVER_PORT=8080` (or another free port).
- **SQLite is the only DB** — Gladys uses SQLite; no PostgreSQL/MySQL option. For most home automation workloads this is fine.
- **Backup** — back up the `/var/lib/gladysassistant/` directory; it contains the SQLite database and all your configuration.
