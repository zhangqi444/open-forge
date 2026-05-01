---
name: Games on Whales (Wolf)
description: "Streaming server for Moonlight — share one server with multiple remote clients for video games. On-demand virtual desktops. Multi-GPU. C++. games-on-whales/wolf. OpenCollective. Discord."
---

# Games on Whales (Wolf)

Wolf is **"Sunshine / GeForce NOW on your own hardware — but multi-user + Docker-native"** — a Moonlight-protocol streaming server that lets **multiple remote clients** share a single host. On-demand virtual desktops, multi-GPU support (stream-encode on iGPU while gaming on dGPU), low-latency video+audio with full gamepad support. **Linux + Docker first** — games run in low-privilege containers via **Games-On-Whales** base images.

Built + maintained by **games-on-whales** org. OpenCollective funded. Discord community. Apache-2 likely. Active CI.

Use cases: (a) **home-lab cloud-gaming server** (b) **multi-user game-streaming on one GPU host** (c) **remote-play from phone/tablet/weak-laptop** (d) **household gaming from one beefy PC** (e) **Linux desktop-stream to Moonlight clients** (f) **virtual-desktop on-demand via container** (g) **alternative to Sunshine for containerized workflows** (h) **encode-decode GPU partitioning**.

Features (per README):

- **Moonlight-compatible** streaming server
- **Multi-user** on single host
- **On-demand virtual desktops** — no monitor/dummy-plug needed
- **Multi-GPU** simultaneous
- **Low-latency** video+audio
- **Full gamepad** support
- **Games in containers** (low-privilege)
- **Hackable config** — encoding pipelines, GPU settings, Docker/Podman flags

- Upstream repo: <https://github.com/games-on-whales/wolf>
- Base images: <https://github.com/games-on-whales/gow>
- Donate: <https://opencollective.com/games-on-whales>
- Discord: <https://discord.gg/kRGUDHNHt2>

## Architecture in one minute

- **C++** streaming server
- **Moonlight** protocol (Nvidia GameStream compat)
- **Docker/Podman** for game containers
- **GPU passthrough** required
- **Resource**: heavy — needs GPU; RAM for multi-user
- **Port**: Moonlight ports (47989 + UDP)

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker**         | Upstream images                                                                                                        | **Primary**                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| GPU                  | Nvidia/AMD/Intel                                            | Hardware     | **Required — passthrough**                                                                                    |
| GPU drivers          | On host                                                     | Hardware     |                                                                                    |
| User accounts        | Per-user session                                            | Config       | Multi-user pattern                                                                                    |
| Moonlight client     | Per-device (PC/phone/tablet/TV)                             | Client       | Free-app                                                                                    |
| Pairing PIN          | Per-client                                                  | Pairing      | Interactive                                                                                    |
| Network              | LAN-fast; WAN-tweaked                                       | Network      |                                                                                    |
| Game library         | Steam/Epic/etc.                                             | Content      | Per-container                                                                                    |

## Install via Docker

See <https://games-on-whales.github.io>. **Complex** — GPU passthrough + multi-container + udev. Start from the official docker-compose example.

```yaml
services:
  wolf:
    image: games-on-whales/wolf:stable        # **pin**
    privileged: true        # **HIGHEST-severity required for GPU + udev**
    network_mode: host
    volumes:
      - /dev/dri:/dev/dri
      - /dev/uinput:/dev/uinput
      - /tmp/sockets:/tmp/sockets
      - ./wolf-config:/etc/wolf
    environment:
      - WOLF_CFG_FILE=/etc/wolf/config.toml
    devices:
      - /dev/dri
      - /dev/uinput
```

## First boot

1. Set up GPU drivers + passthrough
2. Deploy Wolf
3. Install Moonlight client on a device
4. Discover Wolf; enter pairing PIN
5. Launch virtual-desktop app
6. Test input latency + gamepad
7. Configure additional game-containers
8. Iterate on encoding pipelines

## Data & config layout

- `/etc/wolf/` — config (pairing keys, client list, encoding pipeline)

## Backup

```sh
sudo tar czf wolf-$(date +%F).tgz wolf-config/
# Contains pairing-keys — ENCRYPT
```

## Upgrade

1. Releases: <https://github.com/games-on-whales/wolf/releases>
2. Docker pull + restart
3. Check GPU-driver compatibility

## Gotchas

- **177th HUB-OF-CREDENTIALS Tier 2 — GAMING-STREAM-PAIRING**:
  - Holds: client-pairing-keys, display-server access, GPU passthrough
  - **177th tool in hub-of-credentials family — Tier 2**
- **PRIVILEGED-MODE-REQUIRED**:
  - Needs privileged container + host network for GPU + udev
  - **Privileged-mode-container-host-root-equivalent: 2 tools** (Pelican-Wings+Wolf) 🎯 **2-TOOL MILESTONE — HIGHEST-severity**
  - Reinforces Pelican-Wings pattern (118)
- **GPU-PASSTHROUGH-PREREQ**:
  - Non-trivial host setup
  - NVIDIA Container Toolkit / VAAPI / ROCm
  - **Recipe convention: "GPU-passthrough-prerequisite-expertise-required callout"**
  - **NEW recipe convention** (Wolf 1st formally)
- **HARDWARE-DEPENDENT-TOOL**:
  - **Hardware-dependent-tool: 5 tools** (+Wolf) 🎯 **5-TOOL MILESTONE**
- **MOONLIGHT-PROTOCOL-ECOSYSTEM**:
  - Client apps on every platform (PC, phone, TV)
  - Broad ecosystem dependency
  - **Recipe convention: "standard-protocol-broad-client-ecosystem positive-signal"** — reinforces Movim (120)
- **GAMES-ON-WHALES BASE-IMAGES**:
  - Ecosystem of containerized-game base-images in separate repo
  - **Recipe convention: "ecosystem-base-images-separate-repo positive-signal"**
  - **NEW positive-signal convention** (Wolf 1st formally)
- **MULTI-GPU-ORCHESTRATION**:
  - iGPU + dGPU partitioning
  - Advanced operational pattern
  - **Recipe convention: "multi-GPU-partitioning-advanced-pattern neutral-signal"**
  - **NEW neutral-signal convention** (Wolf 1st formally)
- **LOW-LATENCY-CODEC-TUNING**:
  - Encoding pipeline hackable
  - **Recipe convention: "video-codec-encoding-pipeline-tunable positive-signal"**
  - **NEW positive-signal convention** (Wolf 1st formally)
- **OPENCOLLECTIVE-FUNDING**:
  - **Open-Collective-transparent-finances: 7 tools** (+Wolf) 🎯 **7-TOOL MILESTONE**
- **INSTITUTIONAL-STEWARDSHIP**: games-on-whales org + OpenCollective + Discord + CI + base-images-ecosystem + hackable-config. **163rd tool — community-funded-hardware-tool sub-tier** (NEW-soft).
- **TRANSPARENT-MAINTENANCE**: active + CI + Discord + OpenCollective + stable-branch-discipline. **169th tool in transparent-maintenance family.**
- **GAME-STREAMING-CATEGORY:**
  - **Wolf** — multi-user; Docker-native; containerized games
  - **Sunshine** — single-user; dominant; Windows+Linux
  - **NVIDIA GeForce NOW** — commercial SaaS
  - **Steam Link** — Steam-only
  - **Parsec** — commercial
- **ALTERNATIVES WORTH KNOWING:**
  - **Sunshine** — if you want single-user + Windows support + dominant
  - **Steam Link** — if you want Steam-only + easier
  - **Choose Wolf if:** you want multi-user + Docker-native + GPU-partitioning.
- **PROJECT HEALTH**: active + funded + community + CI + hackable. Strong for niche.

## Links

- Repo: <https://github.com/games-on-whales/wolf>
- Sunshine (alt): <https://github.com/LizardByte/Sunshine>
- Moonlight: <https://moonlight-stream.org/>
