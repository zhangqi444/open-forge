---
name: NPS Enhanced
description: "Self-hosted NAT traversal and reverse proxy server with web management UI. Docker. Go. djylb/nps. Expose services behind NAT/firewalls; TCP/UDP/HTTP/HTTPS/SOCKS5 proxy; P2P mode; multi-client management. Fork of ehang-io/nps with active development. GPL-3.0."
---

# NPS Enhanced

**Self-hosted NAT traversal and reverse proxy system.** Expose services running behind NAT or firewalls to the internet without port forwarding. Supports TCP/UDP forwarding, HTTP/HTTPS reverse proxy, SOCKS5 proxy, P2P mode, and more. Managed via a built-in web UI. Widely used for remote access to home servers, IoT devices, and internal services.

This is an actively-maintained fork of the original [ehang-io/nps](https://github.com/ehang-io/nps) with continuous improvements, stability fixes, and modern deployment enhancements.

Built + maintained by **djylb**. GPL-3.0.

- Upstream repo: <https://github.com/djylb/nps>
- Docker Hub (server): `duan2001/nps` | Docker Hub (client): `duan2001/npc`
- GHCR (server): `ghcr.io/djylb/nps` | GHCR (client): `ghcr.io/djylb/npc`
- Docs: <https://d-jy.net/docs/nps/>
- Telegram community: <https://t.me/npsdev>

## Architecture in one minute

- **NPS Server** (`nps`) — public-facing relay server; receives connections from clients and users
- **NPC Client** (`npc`) — lightweight Go agent running on the machine behind NAT; connects outbound to NPS
- Port **8080** — web management UI (admin panel)
- Port **8024** — default tunnel bridge port (NPC connects here)
- Other ports — opened per proxy/tunnel configuration
- No database required — config stored on disk
- Resource: **very low** — Go binary; minimal RAM/CPU

## Compatible install methods

| Infra      | Runtime              | Notes                                              |
| ---------- | -------------------- | -------------------------------------------------- |
| **Docker** | `duan2001/nps`       | **Primary** — uses `--net=host` for port flexibility |
| GHCR       | `ghcr.io/djylb/nps`  | Alternative registry                               |
| Binary     | Linux / Windows      | Download from releases; systemd/Windows service    |
| OpenWrt    | djylb/nps-openwrt    | OpenWrt package                                    |
| Android    | djylb/npsclient      | Android NPC app                                    |

## Install NPS Server via Docker

```bash
# Pull and run NPS server
docker pull duan2001/nps
docker run -d \
  --restart=always \
  --name nps \
  --net=host \
  -v $(pwd)/conf:/conf \
  -v /etc/localtime:/etc/localtime:ro \
  duan2001/nps
```

> **Note:** After the container creates the default config, edit `./conf/nps.conf` to set your web admin credentials, listening ports, and any custom settings **before** restarting.

```bash
# Restart after editing conf
docker restart nps
```

Web UI: `http://your-server:8080` — default credentials: `admin` / `123` (change immediately).

## Install NPC Client via Docker

```bash
# Run on the machine behind NAT — get server/vkey/type from NPS Web UI
docker pull duan2001/npc
docker run -d \
  --restart=always \
  --name npc \
  --net=host \
  duan2001/npc \
  -server=YOUR_SERVER_IP:8024 \
  -vkey=YOUR_CLIENT_KEY \
  -type=tls \
  -log=off
```

> Copy the exact `-server`, `-vkey`, and `-type` values from the NPS Web UI client page to avoid errors.

## Linux binary install (NPS server)

```bash
# Install NPS server
wget -qO- https://raw.githubusercontent.com/djylb/nps/refs/heads/master/install.sh | sudo sh -s nps
nps install
nps start
# Stop / restart / update
nps stop
nps update && nps restart
```

## Linux binary install (NPC client)

```bash
# Install NPC client
wget -qO- https://raw.githubusercontent.com/djylb/nps/refs/heads/master/install.sh | sudo sh -s npc
/usr/bin/npc install -server=YOUR_SERVER:8024 -vkey=YOUR_KEY -type=tls -log=off
npc start
# Update
npc update && npc restart
```

## Key configuration (nps.conf)

| Setting | Notes |
|---------|-------|
| `web_username` / `web_password` | Admin UI credentials — **change from defaults** |
| `web_port` | Admin UI port (default 8080) |
| `bridge_port` | NPC connection port (default 8024) |
| `bridge_type` | `tcp`, `tls`, or `kcp` |
| `public_vkey` | Global registration key (leave blank to disable open registration) |
| `log_path` | Log file location |

Full config reference: <https://d-jy.net/docs/nps/>

## Proxy types supported

| Type | Use case |
|------|----------|
| TCP forwarding | Expose SSH, databases, any TCP service |
| UDP forwarding | Expose DNS, game servers, any UDP service |
| HTTP/HTTPS reverse proxy | Expose web apps with domain-based routing |
| SOCKS5 proxy | Route arbitrary traffic through NPC host |
| P2P mode | Direct peer-to-peer connection (bypasses server relay) |
| HTTP proxy | HTTP-level proxy via NPC host |
| Proxy Protocol | Pass real client IP to backend services |
| HTTP/3 (QUIC) | Modern QUIC-based transport |

## Gotchas

- **Default credentials are weak.** Web UI default is `admin` / `123`. Change immediately in `nps.conf` before exposing the server.
- **`--net=host` is required** for Docker deployments to allow NPS to listen on arbitrary ports as tunnels are added. This means NPS binds directly to host network — deploy on a dedicated/isolated machine or VPS.
- **Edit `nps.conf` before first start.** The container creates a default config on first run. Stop the container, edit `./conf/nps.conf`, then restart.
- **NPC connects outbound.** The client behind NAT initiates the connection to the server — no inbound firewall rules needed on the client side.
- **Original ehang-io/nps is abandoned.** The original project is no longer maintained. This fork (djylb/nps) is the actively developed successor.
- **GPL-3.0 license.** Commercial use requires compliance with GPL-3.0.
- **mmproxy for real IPs.** To pass real client IPs through TCP tunnels (e.g. for SSH), use [mmproxy](https://github.com/djylb/mmproxy-docker) alongside NPS.

## Backup

```sh
# Config and client keys are in ./conf/
tar czf nps-conf-$(date +%F).tar.gz ./conf/
```

## Upgrade (Docker)

```sh
docker pull duan2001/nps
docker stop nps && docker rm nps
# Re-run the original docker run command with the same -v ./conf:/conf mount
```

## Upgrade (binary)

```sh
nps update && nps restart
npc update && npc restart
```

## Project health

Active Go development (fork of ehang-io/nps), GPL-3.0, Telegram community, Android + OpenWrt clients.

## NAT-traversal-family comparison

- **NPS Enhanced** — Go, server+client model, web UI, TCP/UDP/HTTP/SOCKS5/P2P, GPL-3.0
- **frp** — Go, server+client (frps/frpc), popular alternative, Apache-2.0
- **Ngrok** — Commercial SaaS; self-hosted open-source version available
- **Cloudflare Tunnel** — SaaS, zero-config, free tier, no self-hosted option
- **rathole** — Rust, lightweight NAT traversal, Apache-2.0

**Choose NPS Enhanced if:** you need a self-hosted NAT traversal server with a web management UI, support for multiple clients and proxy types (TCP/UDP/HTTP/SOCKS5/P2P), and want an actively maintained Go-based solution with binary and Docker install options.

## Links

- Repo: <https://github.com/djylb/nps>
- Docs: <https://d-jy.net/docs/nps/>
- Docker Hub (server): <https://hub.docker.com/r/duan2001/nps>
- Docker Hub (client): <https://hub.docker.com/r/duan2001/npc>
- GHCR: <https://github.com/djylb/nps/pkgs/container/nps>
- Telegram: <https://t.me/npsdev>
- Android client: <https://github.com/djylb/npsclient>
- Original (abandoned): <https://github.com/ehang-io/nps>
