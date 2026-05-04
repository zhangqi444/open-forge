---
name: netmaker
description: Netmaker recipe for open-forge. WireGuard-based virtual networking platform. Creates and manages mesh VPNs, remote access gateways, and site-to-site networks with an admin UI and automated key management.
---

# Netmaker

WireGuard-based virtual networking platform for creating and managing mesh VPNs, remote access gateways, and site-to-site networks. Automates WireGuard key distribution and network configuration via a central server. Admin UI, OAuth support, private DNS, and ACLs included. Upstream: <https://github.com/gravitl/netmaker>. Docs: <https://docs.netmaker.io/>.

## Compatible install methods

| Method | When to use |
|---|---|
| Quick install script (recommended) | Single Linux VM with public IP; automated setup |
| Docker Compose | Custom or air-gapped deployments |
| Kubernetes | K8s environments |

## Requirements

- Linux server with public static IP
- Ports: 443 (HTTPS), 51821 (WireGuard) — both TCP and UDP
- Wildcard DNS subdomain pointing to server IP (e.g. `*.netmaker.example.com`)

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Public IP / domain for Netmaker?" | Wildcard DNS required: `*.netmaker.example.com` |
| preflight | "Admin email?" | For Let's Encrypt cert and initial admin account |
| preflight | "Master key / admin password?" | Set during install; used for API auth |

## Quick install (Ubuntu 24.04 recommended)

```bash
# 1. Point wildcard DNS: *.netmaker.example.com → your server IP
# 2. Open firewall: 443 TCP, 51821 TCP+UDP

# 3. Run quick install
curl -sfL https://raw.githubusercontent.com/gravitl/netmaker/master/scripts/nm-quick.sh | sudo bash
```

Follow prompts for domain and email. Traefik + Let's Encrypt are set up automatically.

Full guide: <https://docs.netmaker.io/docs/server-installation/quick-install>

## Docker Compose (manual)

See upstream Compose file: <https://raw.githubusercontent.com/gravitl/netmaker/master/compose/docker-compose.yml>

Key services: `netmaker` (API server), `netmaker-ui` (web dashboard), `mosquitto` (MQTT broker), `coredns` (private DNS), `traefik` (reverse proxy + TLS)

## Software-layer concerns

- Port `443`: admin UI + REST API
- Port `51821/udp`: WireGuard peer communication
- MQTT (Mosquitto) is required for real-time client communication
- Netclient agent must be installed on each node joining the network:
  ```bash
  curl -sfL https://raw.githubusercontent.com/gravitl/netmaker/master/scripts/netclient-install.sh | sudo KEY=<enrollment-key> sh
  ```
- Private DNS: CoreDNS gives each network node a DNS name (e.g. `node1.netmaker`)
- ACLs: control which nodes can communicate within a network

## Upgrade procedure

```bash
cd /root/netmaker   # or wherever compose file lives
docker compose pull
docker compose up -d
```

## Gotchas

- Wildcard DNS is **required** — Netmaker uses subdomains for dashboard, API, broker, and DNS
- Without UDP 51821 open, WireGuard traffic won't route between nodes
- Netclient (the agent) must run on each node — it manages the WireGuard interface automatically
- Egress/ingress gateways require a dedicated node; can't be on the Netmaker server itself
- Netmaker SaaS (managed) available at netmaker.io for teams who don't want to self-host the server

## Links

- GitHub: <https://github.com/gravitl/netmaker>
- Docs: <https://docs.netmaker.io/>
- Quick install: <https://docs.netmaker.io/docs/server-installation/quick-install>
