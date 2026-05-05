---
name: firezone
description: Firezone recipe for open-forge. WireGuard-based zero-trust remote access platform. Self-hosted gateways connect to Firezone's hosted control plane (app.firezone.dev). Covers gateway deployment via Docker Compose and Linux install script, client app installation, and resource/policy configuration. Based on upstream docs at https://www.firezone.dev/kb.
---

# Firezone

Open-source, WireGuard-based zero-trust remote access platform. Upstream: <https://github.com/firezone/firezone>. Docs: <https://www.firezone.dev/kb>.

Firezone uses a **split architecture**: the control plane (portal) runs as a managed service at `app.firezone.dev`, while **Gateways** (data plane) run on your own infrastructure. Clients connect to gateways using WireGuard tunnels brokered by the control plane. All traffic flows peer-to-peer through your gateways — packets never transit Firezone's cloud.

> **Self-hosting scope:** You self-host the Gateway(s). The portal (admin UI, identity provider, policy engine) is hosted by Firezone. A fully self-hosted portal is not yet generally available; the open-source repo contains the portal code for transparency and community contributions.

## Architecture overview

| Component | Where it runs | What it does |
|---|---|---|
| Portal | `app.firezone.dev` (Firezone-managed) | Admin UI, policy engine, IdP connector, relay coordination |
| Gateway | Your server / VPC | Data-plane WireGuard relay — handles actual tunnel traffic |
| Relay | Firezone-managed (with option to self-host) | STUN/TURN for NAT traversal / holepunching |
| Client | End-user device | WireGuard client (macOS / Windows / Linux / iOS / Android) |

## Compatible deploy methods

| Method | Upstream doc | When to use |
|---|---|---|
| Docker Compose (gateway) | <https://www.firezone.dev/kb/automate/docker-compose> | Preferred for containerized environments, VMs with Docker |
| systemd install script | <https://www.firezone.dev/kb/deploy/gateways> | Bare-metal Linux, systemd-managed environments |
| Terraform + AWS | <https://www.firezone.dev/kb/automate/terraform/aws> | Automated AWS gateway fleet |
| Terraform + GCP | <https://www.firezone.dev/kb/automate/terraform/gcp> | Automated GCP gateway fleet |
| Terraform + Azure | <https://www.firezone.dev/kb/automate/terraform/azure> | Automated Azure gateway fleet |

## Prerequisites

1. **Firezone account** — sign up at <https://app.firezone.dev> (free Starter tier available)
2. **Site** — create a Site in the portal (Settings → Sites → Add Site). Each gateway belongs to a site; sites group gateways that can reach the same set of resources.
3. **Gateway token** — generated per-site in the portal; used by the gateway to authenticate to the control plane.

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| portal | Firezone account email | Used during sign-up at app.firezone.dev |
| portal | Site name | E.g. `home-lab`, `office-vpc` |
| gateway | Gateway token | Generated in portal: Settings → Sites → <site> → Add Gateway |
| gateway | Server OS / deploy method | Docker Compose vs systemd |
| resources | Resource CIDR or DNS name | E.g. `192.168.1.0/24`, `*.internal.example.com` |
| policies | Which groups can access which resources | Groups can be synced from Google Workspace / Entra / Okta |

## Gateway deployment

### Docker Compose

Upstream reference: <https://www.firezone.dev/kb/automate/docker-compose>

```yaml
# docker-compose.yml
services:
  gateway:
    image: ghcr.io/firezone/gateway:latest
    restart: unless-stopped
    environment:
      FIREZONE_TOKEN: "${FIREZONE_TOKEN}"
      FIREZONE_NAME: "${GATEWAY_NAME:-gateway}"
      LOG_LEVEL: info
    cap_add:
      - NET_ADMIN
    sysctls:
      - net.ipv4.ip_forward=1
      - net.ipv4.conf.all.src_valid_mark=1
      - net.ipv6.conf.all.disable_ipv6=0
      - net.ipv6.conf.all.forwarding=1
```

`.env`:
```
FIREZONE_TOKEN=<token from portal>
GATEWAY_NAME=my-gateway
```

Start: `docker compose up -d`

### systemd install script

Upstream reference: <https://www.firezone.dev/kb/deploy/gateways>

```bash
# Set your gateway token
export FIREZONE_TOKEN="<token from portal>"

# Run the one-line installer
curl -fsSL https://raw.githubusercontent.com/firezone/firezone/main/scripts/gateway/install.sh | bash
```

The script installs the `firezone-gateway` binary to `/usr/local/bin`, creates a systemd unit at `/etc/systemd/system/firezone-gateway.service`, writes the token to `/etc/firezone/gateway.env`, and starts the service.

```bash
# Check status
systemctl status firezone-gateway

# View logs
journalctl -u firezone-gateway -f
```

## Client apps

Upstream reference: <https://www.firezone.dev/kb/client-apps>

| Platform | Install |
|---|---|
| macOS | App Store or direct download |
| Windows | Direct download from <https://www.firezone.dev/kb/client-apps/windows-gui-client> |
| Linux (GUI) | <https://www.firezone.dev/kb/client-apps/linux-gui-client> |
| Linux (headless) | <https://www.firezone.dev/kb/client-apps/linux-headless-client> |
| iOS | App Store |
| Android / ChromeOS | Play Store |

After install, open the client and sign in with your Firezone account. The client downloads your policy and establishes WireGuard tunnels to gateways as needed.

## Resources and policies

Upstream reference: <https://www.firezone.dev/kb/deploy/resources>

- **Resources** define what is accessible: a CIDR block (`192.168.1.0/24`), a DNS name (`db.internal`), or a wildcard DNS pattern (`*.corp.example.com`).
- **Policies** link groups of users to resources. Access is denied by default; a policy must explicitly permit it.
- **Groups** can be local (manually managed) or synced from Google Workspace, Entra ID, or Okta.

## Ports / networking

| Protocol | Port | Purpose |
|---|---|---|
| UDP | 51820 | WireGuard tunnel (gateway <-> client) |
| TCP | 443 | Gateway outbound to control plane |

The gateway needs outbound HTTPS (443) to the Firezone control plane. Inbound WireGuard (UDP 51820) must be reachable by clients if NAT holepunching is not available.

## Upgrade

### Docker Compose
```bash
docker compose pull && docker compose up -d
```

### systemd
```bash
curl -fsSL https://raw.githubusercontent.com/firezone/firezone/main/scripts/gateway/install.sh | bash
systemctl restart firezone-gateway
```

## High availability

Deploy two or more gateways in the same site. Firezone automatically load-balances clients across available gateways and fails over if one becomes unreachable.

## Gotchas

- **`NET_ADMIN` capability required** — the gateway manages WireGuard interfaces. In Docker: `cap_add: [NET_ADMIN]` plus the sysctl entries shown above.
- **NAT/holepunching** — if your gateway is behind strict NAT (symmetric NAT), ensure UDP 51820 is port-forwarded. Firezone's relay handles most NATs automatically.
- **Portal is SaaS** — the GitHub repo contains the full portal source for transparency, but running a fully self-hosted portal is not yet officially supported. Track progress at <https://github.com/firezone/firezone/discussions>.
- **Token rotation** — if a gateway token is compromised, revoke it in the portal (Sites → site → Gateways → Revoke) and redeploy with a new token.
- **IPv6** — enable `net.ipv6.conf.all.forwarding=1` on the host if IPv6 resources must be reachable through the gateway.
- **Host firewall** — ensure iptables/nftables/ufw allows forwarded traffic between WireGuard interfaces and the resource network.
