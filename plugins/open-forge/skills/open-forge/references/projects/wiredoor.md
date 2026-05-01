---
name: Wiredoor
description: "Self-hosted ingress-as-a-service via reverse WireGuard VPN + NGINX. Docker + Helm. wiredoor/wiredoor. Expose private services to internet without complex firewall rules."
---

# Wiredoor

**Self-hosted ingress-as-a-service** — expose applications in private/local networks to the internet securely via reverse VPN tunnels. WireGuard for the VPN layer, NGINX for reverse proxying, Let's Encrypt for TLS. Web UI + CLI client (`wiredoor-cli`). OAuth2-proxy integration for per-domain auth. Kubernetes Helm chart available.

Built + maintained by the **Wiredoor team**.

- Upstream repo: <https://github.com/wiredoor/wiredoor>
- Website + docs: <https://www.wiredoor.net/docs>
- CLI repo: <https://github.com/wiredoor/wiredoor-cli>
- Docker setup repo: <https://github.com/wiredoor/docker-setup>
- Helm charts: <https://charts.wiredoor.net>
- Docker Hub: <https://hub.docker.com/r/wiredoor/wiredoor>

## Architecture in one minute

- **Wiredoor Server** runs on a public VPS — receives all inbound traffic
- **WireGuard** reverse VPN: private nodes connect _out_ to the server (no inbound firewall rules needed on the node)
- **NGINX** on the server terminates HTTP/HTTPS and proxies to the correct private service over the tunnel
- **Let's Encrypt** auto-provisions SSL certs for domains pointed at the server
- **wiredoor-cli** runs on private nodes to register services and manage the tunnel
- Supports: HTTP/HTTPS services, TCP port forwarding, subnet gateway (site-to-site style)
- Multi-environment: Docker, Kubernetes, legacy servers, IoT, Raspberry Pi
- Required open ports on server: `80`, `443`, UDP `51820` (WireGuard), optional TCP range for TCP services

## Compatible install methods

| Infra              | Runtime                            | Notes                                                           |
| ------------------ | ---------------------------------- | --------------------------------------------------------------- |
| **Docker Compose** | `wiredoor/wiredoor`                | **Primary** — clone `wiredoor/docker-setup` repo               |
| **Kubernetes**     | Helm chart                         | <https://charts.wiredoor.net>                                   |

## Inputs to collect

| Input                          | Example                             | Phase    | Notes                                                                                     |
| ------------------------------ | ----------------------------------- | -------- | ----------------------------------------------------------------------------------------- |
| Server domain / public IP      | `vpn.example.com`                   | Network  | Must be publicly reachable; DNS A-record → server IP                                      |
| Admin email + password         | `.env` config                       | Auth     | Set in `.env` before first start                                                          |
| WireGuard UDP port             | `51820`                             | Network  | Must be open in firewall / security group                                                 |
| TCP port range (optional)      | `32760-32767`                       | Network  | For TCP service exposure; open these ports too; update `docker-compose.yml` ports section |
| Services to expose             | `http://localhost:3000` on Node A   | Config   | Registered via wiredoor-cli or web UI after setup                                         |
| Domain(s) for services         | `app.example.com`                   | DNS      | DNS A-record → server IP; Wiredoor gets Let's Encrypt cert                                |

## Deploy Wiredoor Server

```bash
# 1. Clone the docker-setup repo
git clone https://github.com/wiredoor/docker-setup.git wiredoor
cd wiredoor

# 2. Configure environment
cp .env.example .env
# Edit .env: set ADMIN_EMAIL, ADMIN_PASSWORD, PUBLIC_HOSTNAME (VPS domain or IP), TCP range

# 3. Start server
docker compose up -d

# 4. Open web UI at https://<your_public_hostname>
# Login with ADMIN_EMAIL + ADMIN_PASSWORD
```

If you changed the TCP port range, also update the `ports:` section in `docker-compose.yml` to match.

## Register a private node and expose a service

On the **private machine** (the one behind the firewall):

```bash
# Install wiredoor-cli (see https://github.com/wiredoor/wiredoor-cli/releases)
curl -sSL https://install.wiredoor.net | bash
# Or: download the binary from the releases page

# Register the node with your Wiredoor server
wiredoor connect --server https://vpn.example.com --token <node-token>
# Node token is generated in the web UI: Nodes → Create Node

# Expose an HTTP service
wiredoor expose http --name my-app --domain app.example.com --port 3000
# Wiredoor server will get a Let's Encrypt cert for app.example.com and start routing
```

## First boot

1. Deploy server (steps above).
2. In web UI: create a **Node** for each private host → copy the node token.
3. On each private host: install wiredoor-cli → `wiredoor connect --server … --token …`
4. Register each service to expose (`wiredoor expose http/tcp …`).
5. Point DNS for service domains → Wiredoor server IP.
6. Verify services are reachable at their public domains over HTTPS.
7. Optionally configure **OAuth2 auth** per domain (admin → Domains → Auth).

## Data & config layout

- Server: Docker volumes for NGINX config, Let's Encrypt certs, WireGuard peers, app DB
- Node: `~/.wiredoor/` — token + peer config (generated by wiredoor-cli)

## Backup

```sh
cd wiredoor && docker compose down
sudo tar czf wiredoor-$(date +%F).tgz data/   # or whatever volume name is in your compose
docker compose up -d
```

Contents: WireGuard peer keys, Let's Encrypt certs, registered services config, admin creds. These are infrastructure credentials — treat accordingly.

## Upgrade

1. Releases: <https://github.com/wiredoor/wiredoor/releases>
2. `cd wiredoor && git pull && docker compose pull && docker compose up -d`
3. Also upgrade wiredoor-cli on nodes: re-download binary from CLI releases.

## Gotchas

- **Server must be publicly reachable.** The whole design requires a VPS with a public IP (or at minimum a host reachable from your clients). If both server and nodes are behind NAT, it won't work.
- **WireGuard UDP 51820 must be open.** Check cloud security groups / `ufw` / `iptables` on the server. Most VPS providers block UDP by default — explicitly open it.
- **TCP port range requires port exposure in both firewall AND docker-compose.** If you set `32760-32767` in `.env` but forget to add them to the `ports:` section in `docker-compose.yml`, TCP services get rejected at the host network layer.
- **DNS must propagate before Let's Encrypt cert issuance.** Point your service domain's A-record → server IP _before_ registering the service in Wiredoor; cert provisioning runs on service registration.
- **wiredoor-cli manages the WireGuard peer config.** The private node doesn't need WireGuard pre-installed — the CLI handles peer setup. But the kernel WireGuard module must be available (standard in Linux 5.6+; `apt install wireguard-tools` for userspace fallback on older kernels).
- **OAuth2 auth is per-domain.** Wiredoor integrates oauth2-proxy — you can protect specific exposed services behind Google/GitHub/etc. SSO. Configured in web UI → Domains → Auth. Not global — each domain opts in separately.
- **Gateway nodes expose full subnets** (site-to-site). If you register a node as a gateway, all traffic to that subnet is routed through Wiredoor. Useful for LAN → internet or office → cloud bridge scenarios.
- **Not a replacement for a full VPN client.** Wiredoor exposes _services_ (HTTP/TCP), not a full network interface on client machines. For full tunnel VPN (client laptop → private LAN), use Tailscale, Netbird, or headscale.
- **Cloudflare Tunnel / Ngrok comparison.** Wiredoor is a self-hosted equivalent — same concept (reverse tunnel → public endpoint), but you own the server and keys. Cloudflare Tunnel is more "set and forget" for public services; Wiredoor is for when you want full control.

## Project health

Active CI, Docker Hub, Helm chart, CLI tool with own release cadence, docs site. Maintained by Wiredoor team.

## Reverse-tunnel / ingress-family comparison

- **Wiredoor** — self-hosted, WireGuard + NGINX, Docker + Helm, OAuth2 per-domain, CLI
- **Cloudflare Tunnel** — SaaS, free tier, easy but requires Cloudflare DNS
- **Ngrok** — SaaS, paid for custom domains + production use
- **frp** — open-source, self-hosted, flexible but lower-level (no web UI)
- **Tailscale Funnel** — Tailscale-based, easy for personal use
- **Netbird** — WireGuard mesh VPN; network-level, not ingress-as-a-service

**Choose Wiredoor if:** you want a self-hosted Cloudflare Tunnel equivalent with WireGuard tunnels, a web UI, Let's Encrypt, and per-service OAuth2 auth — and you have a public VPS to run the server on.

## Links

- Repo: <https://github.com/wiredoor/wiredoor>
- Docs: <https://www.wiredoor.net/docs>
- Docker setup: <https://github.com/wiredoor/docker-setup>
- CLI: <https://github.com/wiredoor/wiredoor-cli>
- Helm charts: <https://charts.wiredoor.net>
- frp (alt): <https://github.com/fatedier/frp>
