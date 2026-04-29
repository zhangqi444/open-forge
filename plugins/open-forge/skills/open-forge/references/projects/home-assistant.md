---
name: home-assistant-project
description: Home Assistant recipe for open-forge. Privacy-focused home automation platform (Apache-2.0). Upstream supports 4 install methods; this recipe covers Home Assistant Container (Docker) as the open-forge-compatible path. Mentions but does not deploy Home Assistant OS / Supervised / Core (those are tied to physical hardware / full-OS installs outside the cloud-VPS scope).
---

# Home Assistant (home automation)

Apache-2.0 self-hosted home automation platform. 3000+ integrations. Local-first, privacy-focused. Upstream supports four installation methods with different tradeoffs.

**Upstream README (core):** https://github.com/home-assistant/core (README is minimal by design — points to the docs site)
**Docker repo:** https://github.com/home-assistant/docker
**Install docs (all methods):** https://www.home-assistant.io/installation/
**Container install:** https://www.home-assistant.io/installation/alternative/

> [!NOTE]
> Home Assistant's *primary* recommended install is **Home Assistant OS** — a full Linux distribution that takes over a whole device (Raspberry Pi, Intel NUC, etc.) and gives you the Add-on Store and Supervisor. That method is out of open-forge's scope (it's not a Docker-on-cloud path; it's an ISO-flash-the-whole-disk path). This recipe covers **Home Assistant Container** (Docker image), which is the upstream-blessed way to run HA as a Docker container on any OS you already manage.

## Upstream-documented install methods

Source: https://www.home-assistant.io/installation/

| # | Method | Self-manageability | open-forge scope? |
|---|---|---|---|
| 1 | **Home Assistant OS (HAOS)** | Easiest. Vendor-managed OS + Supervisor + Add-ons. | ❌ — whole-device install, not a Docker container on a VPS |
| 2 | **Home Assistant Supervised** | Debian + HA's Supervisor. Unsupported on anything but their Debian recipe. | ❌ — out of scope |
| 3 | **Home Assistant Container** | Official Docker image. No Supervisor, no Add-on Store. | ✅ — this recipe |
| 4 | **Home Assistant Core** | Python venv, manual. | ⚠️ — possible but harder than Container; not recommended by upstream |

Self-hosting on a cloud VPS / home server where you already manage the OS → use **Container** (this recipe). Self-hosting on a dedicated board → use **HAOS** (flash an image to SD/eMMC, not covered here).

## Compatible combos (Container path)

| Infra | Runtime | Status | Notes |
|---|---|---|---|
| localhost | Docker | ✅ default | `docker run` per README |
| localhost | Docker Compose | ✅ | Upstream ships a canonical compose snippet |
| byo-vps | Docker | ✅ | Works, but Z-Wave/Zigbee USB integrations need local hardware — cloud VPS loses that |
| raspberry-pi | Docker | ✅ | Excellent fit — local hardware + USB dongles |
| home-server | Docker | ✅ | Preferred — HA is fundamentally LAN-oriented |
| aws/ec2 | Docker | ⚠️ | Technically runs, but most integrations (Zigbee, Z-Wave, local mDNS discovery) don't work remotely. Cloud VPS is a poor fit for HA. Consider **Nabu Casa** cloud-tunnel or Tailscale + home-server instead. |
| kubernetes | community Helm | ⚠️ | Exists (`pajikos/home-assistant`); most HA installs are single-node by nature. Flag as community-maintained. |

## Key constraint: HA is designed for your LAN

Home Assistant's core value is talking to Zigbee bulbs, Z-Wave locks, mDNS-discovered devices, Bluetooth presence sensors — **things on your LAN**. Running it in `aws-us-east-1` breaks most integrations. For "I want to access my HA from outside the house":

- Run HA on a home-server / Pi
- Tunnel with Tailscale / Nabu Casa / Cloudflare Tunnel

If the user asks for cloud HA, clarify that's unusual. See `references/modules/tunnels.md`.

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| infra | "Where are you running this — a local box / Pi, or a cloud VPS?" | AskUserQuestion | If cloud, warn that Zigbee/Z-Wave/mDNS don't work remotely |
| config | "Config directory path on host?" | Free-text | e.g. `/srv/home-assistant/config`. Gets mapped to `/config` in the container. |
| tz | "Timezone?" | Free-text | tz database name, e.g. `America/Los_Angeles` |
| network | "Use host networking (needed for discovery)?" | AskUserQuestion: host (default) / bridge | Host required for mDNS/SSDP discovery of Chromecasts, Sonos, HomeKit, etc. |
| hw | "Pass through USB devices (Zigbee stick, Z-Wave stick)?" | Free-text | List `--device=/dev/ttyUSB0`-style flags |
| dns | "Domain for remote access?" | Free-text | Optional — only if setting up a reverse proxy |

## Install method — Docker CLI (upstream canonical)

Source: https://www.home-assistant.io/installation/alternative/ (Container path)

Requirements: **Docker Engine 23.0.0+**. Docker *Desktop* will **not** work — upstream is explicit.

```bash
docker run -d \
  --name homeassistant \
  --privileged \
  --restart=unless-stopped \
  -e TZ=America/Los_Angeles \
  -v /srv/home-assistant/config:/config \
  -v /run/dbus:/run/dbus:ro \
  --network=host \
  ghcr.io/home-assistant/home-assistant:stable
```

Access: `http://<host>:8123/`. First visit runs the onboarding wizard (admin user, location, units).

### Why `--privileged` + `--network=host`

- `--privileged` — HA needs raw USB access (Zigbee/Z-Wave) and Bluetooth
- `--network=host` — mDNS / SSDP / DHCP-reflection discovery fails over Docker's default bridge network. Host networking is required, not optional, for most integrations.
- `/run/dbus:ro` — Bluetooth integration

On a cloud VPS (no USB hardware), you can drop `--privileged` and skip the dbus mount; use `-p 8123:8123` instead of `--network=host` if you want.

## Install method — Docker Compose

Source: same

```yaml
services:
  homeassistant:
    container_name: homeassistant
    image: ghcr.io/home-assistant/home-assistant:stable
    volumes:
      - /srv/home-assistant/config:/config
      - /etc/localtime:/etc/localtime:ro
      - /run/dbus:/run/dbus:ro
    restart: unless-stopped
    privileged: true
    network_mode: host
    environment:
      TZ: America/Los_Angeles
```

`docker compose up -d`.

## Software-layer concerns

### Config dir is everything

Everything HA does — integrations, automations, scripts, add-ons (if any) — lives under `/config/` in the container, which maps to your host path. **Back up this directory** (`/srv/home-assistant/config`). That's your entire HA state.

Subdirs of note:
- `/config/configuration.yaml` — root config
- `/config/.storage/` — UI-managed integrations + auth (binary blobs; do not hand-edit)
- `/config/automations.yaml`, `scripts.yaml`, `scenes.yaml` — UI-manageable
- `/config/secrets.yaml` — referenced via `!secret` YAML tag; keep out of git

### Env vars (minimal)

HA Container doesn't take many env vars — most config is YAML in `/config/`.

| Var | Purpose |
|---|---|
| `TZ` | Timezone |

### Reverse proxy

If exposing HA remotely, put it behind Caddy/Traefik/Nginx for TLS. HA has built-in TLS support via `http:` YAML, but a reverse proxy is more flexible.

Caddy:

```caddy
home.example.com {
  reverse_proxy 127.0.0.1:8123
}
```

Plus in `configuration.yaml`:

```yaml
http:
  use_x_forwarded_for: true
  trusted_proxies:
    - 127.0.0.1
    - ::1
```

Without `trusted_proxies`, HA rejects forwarded requests as a security measure and you'll see "HTTPS is not enabled" errors.

### Image tags

- `stable` — latest stable (default)
- `beta`, `dev` — pre-release tracks
- `X.Y.Z` — pinned version (recommended for reproducibility)

Image: `ghcr.io/home-assistant/home-assistant` (also mirrored on Docker Hub as `homeassistant/home-assistant`).

## Upgrade procedure

```bash
docker pull ghcr.io/home-assistant/home-assistant:stable
docker stop homeassistant
docker rm homeassistant
docker run -d ... (same command as install)
```

Or with compose:

```bash
docker compose pull
docker compose up -d
```

HA runs DB migrations on boot. First boot after a major upgrade can take 5+ minutes — **don't panic if `:8123` is slow to respond**. Tail logs: `docker logs -f homeassistant`.

Release notes: https://www.home-assistant.io/blog/categories/release-notes/

**Always back up `/config` before upgrading.** Rollback = restore config + use older image tag.

## Gotchas

- **Docker Desktop does not work.** Upstream is explicit: Docker *Engine* only. Desktop's VM handles networking differently enough that HA discovery breaks.
- **Without `--network=host`, most integrations silently fail.** No mDNS → no Chromecast / Sonos / HomeKit / AirPlay autodiscovery. You can work around by specifying IPs manually, but it's painful.
- **No Add-on Store in Container install.** Add-ons (Mosquitto broker, Z-Wave JS UI, ESPHome dashboard) are a Supervisor feature. In Container, you run those as *separate* Docker containers. This is fine, just different.
- **Container is not the same as HAOS.** Users who install Container, then Google "how to install HACS" or "how to install an add-on" and try to use the HAOS path — it won't work. Community integrations (HACS) do work in Container; official "Add-ons" do not.
- **Z-Wave/Zigbee USB passthrough.** Needs `--device=/dev/serial/by-id/usb-...` (by-id is stable across reboots; by-path isn't). Get the ID via `ls -la /dev/serial/by-id/` on the host.
- **`trusted_proxies` is required behind a reverse proxy.** Without it HA rejects the forwarded request and complains about HTTPS/HTTP mismatches.
- **DB is SQLite by default — OK up to a few hundred entities.** For large installs (500+ entities, high-frequency sensors), switch the `recorder:` integration to MariaDB or Postgres. Add the DB as a sibling container.
- **Cloud VPS is a bad fit.** HA on AWS/DigitalOcean loses ~80% of its value because there's no LAN to discover. Unless the user explicitly wants a cloud bastion + Tailscale tunnel to a home LAN, redirect them to a home-server or Pi.
- **HA Core (Python venv) is not recommended by upstream.** If a user asks for it, steer them toward Container.
- **Nabu Casa is the upstream-blessed remote-access tunnel.** $6.50/mo, funds the project, zero-config remote access + Alexa/Google integration. Mention it when a user asks "how do I access HA from away from home?"

## TODO — verify on subsequent deployments

- [ ] Test Container install on Hetzner CX22 with Tailscale-only access (cloud-HA "bastion" pattern).
- [ ] Zigbee USB passthrough via `--device=/dev/serial/by-id/...` — verify stable across reboots.
- [ ] MariaDB recorder swap for large installs.
- [ ] Recommended community Helm chart — confirm `pajikos/home-assistant` is current.
- [ ] Tunnel integration — Tailscale / Nabu Casa / Cloudflare Tunnel comparison in `references/modules/tunnels.md`.
- [ ] Backup strategy: `/config` snapshots + recorder DB dumps.
