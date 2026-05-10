---
name: olares
description: Olares recipe for open-forge. Covers the upstream-blessed install methods documented at https://docs.olares.com/manual/get-started/install-olares — one-line script on Linux (Ubuntu/Debian), Docker Compose on Linux, ISO image (bare-metal / PVE), Windows WSL 2, macOS MiniKube/Docker, and Raspberry Pi ARM. All data anchored to the Olares GitHub repo (beclab/Olares) and its embedded docs tree.
---

# Olares

Open-source personal cloud OS. Run LLMs, media servers, smart-home hubs, and self-hosted SaaS alternatives locally with Kubernetes under the hood, a built-in app market, SSO, and remote access via Tailscale/FRP. Upstream: <https://github.com/beclab/Olares>. Install methods: <https://docs.olares.com/manual/get-started/install-olares>.

Olares wraps a K3s cluster + JuiceFS distributed filesystem + MinIO object storage + Authelia SSO behind a polished desktop-style UI, then installs apps from a curated market — Jellyfin, Ollama, ComfyUI, Mastodon, Ghost, WordPress, etc. You access it from anywhere via the **LarePass** companion app (iOS/Android).

> **Olares ID required.** Every Olares install must be paired to an Olares ID (e.g. alice123@olares.com) created via the LarePass mobile app. This is used for SSO, remote access, and decentralized identity. Activation cannot complete without one.

## Compatible install methods

| Method | Platform | When to use |
|---|---|---|
| One-line script | Linux (Ubuntu 22.04-25.04 / Debian 12-13) | Recommended production path |
| Docker Compose | Linux (Ubuntu 22.04-25.04 / Debian 12-13) | Containerized, same hardware requirements |
| ISO image | Physical machine or PVE VM | Fresh-machine install; auto-configures OS |
| WSL 2 script | Windows 11 (WSL 2) | Dev / testing only |
| macOS MiniKube | macOS | Dev / testing |
| macOS Docker | macOS | Dev / testing |
| PVE one-line script | Proxmox VE node | Install directly on a PVE node |
| PVE LXC | Proxmox VE | Lightweight container |
| Raspberry Pi | ARM64 (Pi 4/5) | Low-power homelab |

## System requirements (Linux script / Docker — production)

- **CPU**: 4+ cores
- **RAM**: 8 GB+ available
- **Storage**: 150 GB+ available **SSD** (install fails on HDD)
- **OS**: Ubuntu 22.04-25.04 LTS or Debian 12-13
- **Optional**: NVIDIA GPU for AI workloads

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | Which install method? | Drives which method section is used |
| preflight | Have you created an Olares ID in LarePass? | Required before activation; walk through LarePass if not |
| preflight | What is your Olares ID? (e.g. alice123@olares.com) | Needed at activation / Wizard URL step |
| deploy (Docker) | What is the host machine's IP address? | Set as OLARES_HOST_IP; run `ip r` to find it |
| deploy (Docker) | Which Olares version to install? (e.g. 1.11.5) | Check https://github.com/beclab/Olares/releases |
| gpu (optional) | Does the machine have an NVIDIA GPU to enable? | Triggers GPU driver + Container Toolkit sub-steps |

---

## Method — One-line script (Linux)

Source: https://docs.olares.com/manual/get-started/install-linux-script.html

Fetches and runs the Olares installer, bootstrapping K3s, pulling system containers, and launching the Wizard UI.

### Install

```bash
curl -fsSL https://olares.sh | bash -
```

Root password may be prompted. The installer needs elevated privileges for K3s, storage drivers, and port binding.

If the install errors partway through, uninstall cleanly and retry:

```bash
olares-cli uninstall --all
curl -fsSL https://olares.sh | bash -
```

### After install — Prepare Wizard URL

At the end of install the CLI prompts for domain name and Olares ID prefix:

```
Domain name: olares.com        # Press Enter for default or type your domain
Olares ID prefix: alice123     # Local part of your Olares ID (before the @)
```

The installer prints a Wizard URL and initial login password:

```
Wizard URL: http://<host-ip>:30180
Initial password: xxxxxxxx
```

Open that URL in a browser and use LarePass to complete activation.

---

## Method — Docker Compose (Linux)

Source: https://docs.olares.com/manual/get-started/install-linux-docker.html

Runs Olares in a privileged Docker container. Requires Docker + Docker Compose plugin pre-installed.

### docker-compose.yaml

```yaml
services:
  olares:
    image: beclab/olares:${VERSION}
    privileged: true
    volumes:
      - oic-data:/var
    ports:
      - "80:80"
      - "443:443"
      - "30180:30180"
      - "18088:18088"
      - "41641:41641/udp"
    environment:
      - OLARES_HOST_IP=${HOST_IP}

  olaresd-proxy:
    image: beclab/olaresd:proxy-v0.1.0
    network_mode: host
    depends_on:
      olares:
        condition: service_started

volumes:
  oic-data:
```

### Start

```bash
mkdir ~/olares-config && cd ~/olares-config
# Save docker-compose.yaml above, then:
VERSION=1.11.5 OLARES_HOST_IP=192.168.1.50 docker compose up -d
```

Verify containers are running:

```bash
docker ps
# Expect: beclab/olares:<version> and beclab/olaresd:proxy-v0.1.0
```

Open http://<host-ip>:30180 to activate via the Wizard.

### GPU support (optional)

Install NVIDIA drivers:

```bash
curl -o /tmp/keyring.deb -L \
  https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb
sudo dpkg -i --force-all /tmp/keyring.deb
sudo apt update && sudo apt install nvidia-kernel-open-590 nvidia-driver-590
```

Install NVIDIA Container Toolkit:

```bash
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | \
  sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
  sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
sudo apt update && sudo apt install -y nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
```

Verify: `sudo docker run --rm --runtime=nvidia --gpus all ubuntu nvidia-smi`

Use the GPU-enabled compose variant from the Olares docs (adds deploy.resources.reservations.devices stanza).

---

## Method — ISO image (bare metal / PVE)

Download from GitHub Releases: https://github.com/beclab/Olares/releases
Look for `olares-<version>-linux-amd64.iso`.

- **Bare metal**: Write to USB (dd / Balena Etcher), boot, follow on-screen installer.
- **PVE VM**: Upload ISO to PVE storage, create VM (4+ vCPU, 8+ GB RAM, 150 GB virtio disk), attach ISO, boot.

After first boot, Wizard URL is at http://<host-ip>:30180.

---

## Method — Raspberry Pi (ARM64)

Same one-line script, ARM64 build:

```bash
curl -fsSL https://olares.sh | bash -
```

Minimum: Raspberry Pi 4 or 5 with 8 GB RAM. **Boot from SSD** (USB 3.0 or M.2 HAT). SD cards are too slow and will corrupt under JuiceFS / MinIO I/O patterns.

---

## Ports

| Port | Service |
|---|---|
| 30180 | Olares Wizard / web UI |
| 80 / 443 | HTTP/HTTPS ingress |
| 18088 | Internal tunnel / olaresd |
| 41641/udp | Tailscale/DERP relay |

## Key paths (script / CLI install)

| Item | Path |
|---|---|
| Olares data root | /olares/ (default) |
| K3s config | /etc/rancher/k3s/k3s.yaml |
| olaresd daemon | systemd unit: olaresd |
| Pod logs | kubectl logs -n <namespace> <pod> |

---

## Activation flow (all methods)

1. Open http://<host-ip>:30180 in a browser.
2. Log in with the initial password printed by the installer.
3. Open LarePass on your phone and follow the pairing instructions.
4. Enter your Olares ID when prompted.
5. LarePass handles remote access — your Olares is reachable from anywhere.

---

## Upgrade

### Script-based

```bash
olares-cli upgrade
```

### Docker Compose

```bash
cd ~/olares-config
VERSION=<new-version> OLARES_HOST_IP=<host-ip> docker compose pull
VERSION=<new-version> OLARES_HOST_IP=<host-ip> docker compose up -d
```

---

## Gotchas

- **Olares ID is mandatory.** No activation without a registered Olares ID via LarePass — there is no local-only mode for standard installs.
- **SSD required.** The installer checks disk speed; HDD installations fail at that stage. USB 3.0 SSDs pass; SD cards and spinning disks do not.
- **`privileged: true` is required (Docker method).** Olares manages its own kernel namespaces inside the container. Running without it breaks K3s.
- **`OLARES_HOST_IP` must be accurate.** LAN peers and LarePass use this address; wrong NIC → broken connectivity.
- **Ports 80/443 must be free.** Competing webservers (NGINX, Apache, Caddy, Traefik) must be stopped before install.
- **`olaresd-proxy` uses `network_mode: host`.** Required for mDNS / LAN service discovery. Cannot be overridden.
- **`olares-cli uninstall --all` is destructive.** Removes all data. Back up content volumes first.
- **Raspberry Pi: SSD is non-negotiable.** JuiceFS + MinIO do heavy random I/O — SD cards will corrupt.
- **China users:** LarePass may assign a `.cn` Olares ID domain based on phone locale. Switch to `.com` via Advanced creation mode for better international routing.
- **`olaresd-proxy` image tag is fixed** in the official compose file at `proxy-v0.1.0` — check releases for updates if deploying a newer Olares version.

---

## Links

- GitHub: https://github.com/beclab/Olares
- Install methods overview: https://docs.olares.com/manual/get-started/install-olares
- Releases: https://github.com/beclab/Olares/releases
- LarePass app: https://www.olares.com/larepass
- Architecture: https://docs.olares.com/developer/concepts/system-architecture.html
- Olares apps: https://github.com/beclab/apps
