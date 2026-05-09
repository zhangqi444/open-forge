---
name: atlas
description: Atlas recipe for open-forge. Covers Docker (single-container) install for this network infrastructure scanner and visualizer. Source: https://github.com/karam-ajaj/atlas. Latest tag: 3.3.4.
---

# Atlas

Full-stack containerized tool to **scan**, **analyze**, and **visualize** your network infrastructure. Scans Docker containers (IPs, MACs, open ports, networks), discovers neighboring hosts on the subnet via NMAP-style probes, and renders an interactive real-time graph dashboard. Built with Go, FastAPI, NGINX, and React; packaged as a single Docker image. Upstream: <https://github.com/karam-ajaj/atlas>. Live demo: <https://atlasdemo.vnerd.nl/> (admin / change-me).

Atlas is homelab-oriented: it requires `--network=host` and Linux capabilities (`NET_RAW`, `NET_ADMIN`) to perform subnet scanning.

## Compatible install methods

| Method | When to use |
|---|---|
| Docker (single container) | Recommended. All services bundled; host networking for subnet scanning. |

## Inputs to collect

| Phase | Prompt | Applicability |
|---|---|---|
| preflight | "Which subnet(s) should Atlas scan? (e.g. `192.168.1.0/24`)" | Required for `SCAN_SUBNETS`; if omitted Atlas auto-detects |
| preflight | "Set an admin password for the Atlas UI?" | Sets `ATLAS_ADMIN_PASSWORD`; auth is disabled if left unset |
| preflight | "Preferred UI port?" (default: `8884`) | Maps to `ATLAS_UI_PORT` |
| preflight | "Preferred API port?" (default: `8885`) | Maps to `ATLAS_API_PORT` |

---

## Method — Docker (single container)

> **Source:** Atlas README, Deployment section — <https://github.com/karam-ajaj/atlas#-deployment-docker>.

### docker run

```bash
docker run -d \
  --name atlas \
  --restart unless-stopped \
  --network=host \
  --cap-add=NET_RAW \
  --cap-add=NET_ADMIN \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -e ATLAS_UI_PORT='8884' \
  -e ATLAS_API_PORT='8885' \
  -e ATLAS_ADMIN_USER='admin' \
  -e ATLAS_ADMIN_PASSWORD='changeme' \
  -e ATLAS_AUTH_TTL_SECONDS='86400' \
  -e FASTSCAN_INTERVAL='3600' \
  -e DOCKERSCAN_INTERVAL='3600' \
  -e DEEPSCAN_INTERVAL='7200' \
  -e SCAN_SUBNETS="192.168.1.0/24" \
  keinstien/atlas:3.3.4
```

Access the dashboard at `http://<host>:8884`.

### docker-compose.yml

```yaml
services:
  atlas:
    image: keinstien/atlas:3.3.4
    container_name: atlas
    restart: unless-stopped
    network_mode: host
    cap_add:
      - NET_RAW
      - NET_ADMIN
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      ATLAS_UI_PORT: "8884"
      ATLAS_API_PORT: "8885"
      ATLAS_ADMIN_USER: admin
      ATLAS_ADMIN_PASSWORD: changeme      # set a real password
      ATLAS_AUTH_TTL_SECONDS: "86400"
      FASTSCAN_INTERVAL: "3600"
      DOCKERSCAN_INTERVAL: "3600"
      DEEPSCAN_INTERVAL: "7200"
      SCAN_SUBNETS: "192.168.1.0/24"     # comma-separate multiple subnets
```

### Verify

Open `http://<host>:8884` — the graph dashboard should appear within a minute of the first scan completing.

### Lifecycle

```bash
docker pull keinstien/atlas:3.3.4    # upgrade to a new tag
docker restart atlas                  # restart
docker logs -f atlas                  # logs
```

---

## Environment variables reference

| Variable | Default | Purpose |
|---|---|---|
| `ATLAS_UI_PORT` | `8888` | Nginx UI listen port |
| `ATLAS_API_PORT` | `8889` | FastAPI backend listen port |
| `ATLAS_ADMIN_USER` | `admin` | Web UI username |
| `ATLAS_ADMIN_PASSWORD` | (disabled) | Web UI password; auth disabled if not set |
| `ATLAS_AUTH_TTL_SECONDS` | `86400` | Session lifetime in seconds (24 h) |
| `FASTSCAN_INTERVAL` | `3600` | Seconds between fast subnet pings (1 h) |
| `DOCKERSCAN_INTERVAL` | `3600` | Seconds between Docker container scans (1 h) |
| `DEEPSCAN_INTERVAL` | `7200` | Seconds between deep OS-fingerprint scans (2 h) |
| `SCAN_SUBNETS` | auto-detect | Comma-separated CIDRs to scan (e.g. `192.168.1.0/24,10.0.0.0/24`) |

---

## Gotchas

- **Host networking is required.** Atlas uses raw sockets to probe the subnet; bridge networking prevents it from seeing beyond the Docker bridge. `--network=host` (or `network_mode: host` in Compose) is mandatory.
- **Linux capabilities.** `NET_RAW` and `NET_ADMIN` are needed for ICMP pings and ARP scanning. These are privileged capabilities — only run Atlas on a host you control.
- **Docker socket mount.** Needed for the Docker container scan. Mount without `:ro` as the README specifies.
- **No port mapping needed with host networking.** When using `--network=host`, `-p` flags are ignored; the container shares the host's network stack directly.
- **Scan intervals vs. traffic.** On busy networks, frequent deep scans can generate noticeable NMAP-style traffic. Tune `DEEPSCAN_INTERVAL` upward if you see IDS alerts.
- **Multi-subnet scanning.** Set `SCAN_SUBNETS` to a comma-separated list; Atlas auto-detects the local subnet if the variable is omitted.
