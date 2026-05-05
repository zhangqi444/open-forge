---
name: cosmos
description: Cosmos Server recipe for open-forge. All-in-one self-hosted home server platform combining reverse proxy, app store, container manager, authentication server, VPN, monitoring, identity provider, and SmartShield security. Deployed via a single privileged Docker container using host networking. Based on upstream docs at https://cosmos-cloud.io/doc.
---

# Cosmos Server

All-in-one home server platform that acts as a secure gateway, container manager, reverse proxy, app store, identity provider, and monitoring dashboard. Upstream: <https://github.com/azukaar/cosmos-Server>. Docs: <https://cosmos-cloud.io/doc>.

Cosmos runs as a **single privileged Docker container** on the host network. It proxies requests to your other containers, manages their lifecycle, provides authentication (including MFA and OpenID Connect), runs a built-in VPN, and applies SmartShield anti-bot/anti-DDoS protections to every service it fronts.

**License:** Apache-2.0 + Commons-Clause (source-available; commercial use restrictions apply — see the LICENSE file).

## What Cosmos includes

- **Reverse proxy** with automatic HTTPS (Let's Encrypt) for containers and static sites
- **App store** — one-click install of popular self-hosted apps via the UI
- **Container manager** — start/stop/update Docker containers, import Compose files
- **Authentication server** — single sign-on with MFA (TOTP, WebAuthn), OpenID Connect, forward-auth headers
- **SmartShield** — adaptive rate limiting, IP blocking, geo-blacklisting, bot detection
- **VPN** — built-in WireGuard server for remote access
- **Monitoring** — real-time metrics and alertable dashboards
- **Storage manager** — disk management, MergerFS, parity disks, network mounts (via RClone)
- **Backups** — incremental encrypted backups using Restic

## Compatible deploy methods

| Method | Upstream doc | Notes |
|---|---|---|
| Docker `run` (host networking) | <https://cosmos-cloud.io/doc> · <https://github.com/azukaar/Cosmos-Server#readme> | **Recommended**. Host networking required for port binding to work properly on Linux. |
| Docker on macOS / Windows | README | No host networking available; use `-p 80:80 -p 443:443 -p 4242:4242/udp` instead. |

> **Important:** The upstream README explicitly warns against using Unraid templates, CasaOS, or Portainer stacks to install Cosmos — these wrappers prevent it from functioning properly. Use the `docker run` command directly (or Docker Compose with host networking on Linux).

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | Linux server with Docker installed? | Cosmos requires Docker on the host |
| preflight | Public domain name? | Optional but needed for HTTPS; Cosmos provisions Let's Encrypt certs automatically |
| preflight | Existing services to proxy? | Cosmos can discover and proxy existing containers |
| network | Use host networking (Linux) or port mapping (macOS/Windows)? | Host networking strongly preferred on Linux |

## Deploy: Docker run (Linux, recommended)

Upstream reference: <https://github.com/azukaar/Cosmos-Server#readme>

```bash
sudo docker run -d \
  --network host \
  --privileged \
  --name cosmos-server \
  -h cosmos-server \
  --restart=always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /var/run/dbus/system_bus_socket:/var/run/dbus/system_bus_socket \
  -v /:/mnt/host \
  -v /var/lib/cosmos:/config \
  azukaar/cosmos-server:latest
```

**Volume notes:**
- `/var/run/docker.sock` — required for container management
- `/var/run/dbus/system_bus_socket` — required for storage manager
- `/:/mnt/host` — optional; allows Cosmos to manage host filesystem paths. Remove if you prefer to create bind-mount directories manually.
- `/var/lib/cosmos:/config` — persists Cosmos configuration

After start, open `http://<server-ip>` in your browser to complete the setup wizard.

## Deploy: macOS / Windows (no host networking)

```bash
sudo docker run -d \
  -p 80:80 -p 443:443 -p 4242:4242/udp \
  --privileged \
  --name cosmos-server \
  -h cosmos-server \
  --restart=always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /var/lib/cosmos:/config \
  azukaar/cosmos-server:latest
```

Note: Without host networking, Cosmos cannot automatically bind ports for new containers — you must manually map ports.

## First-run setup

1. Browse to `http://<server-ip>` — you will see the setup wizard
2. Create an admin account
3. Optionally configure a domain name for automatic HTTPS
4. Cosmos will detect existing Docker containers and offer to proxy them

## Ports

| Port | Purpose |
|---|---|
| 80 | HTTP (redirects to HTTPS when domain is configured) |
| 443 | HTTPS reverse proxy |
| 4242/udp | Built-in VPN (WireGuard) |

## Upgrade

```bash
docker pull azukaar/cosmos-server:latest
docker stop cosmos-server && docker rm cosmos-server
# Re-run the same docker run command used during initial deploy
```

Or use Cosmos's own UI: the container manager shows when a new image is available and can pull + restart in one click.

## Gotchas

- **`--privileged` is required** — Cosmos needs elevated capabilities to manage networking, WireGuard, and host mounts.
- **Host networking only on Linux** — `--network host` bypasses Docker's NAT, letting Cosmos bind ports directly. This is unavailable on macOS and Windows where Docker runs in a VM.
- **Commons-Clause license** — the Apache-2.0 + Commons-Clause combination prohibits selling Cosmos as a commercial service. Self-hosting for personal/organizational use is permitted.
- **Do not use Portainer/Unraid/CasaOS templates** — upstream explicitly warns these prevent proper operation.
- **Docker socket security** — mounting `/var/run/docker.sock` grants Cosmos root-equivalent access. Only do this on a trusted private network.
- **Cosmos manages its own NGINX config** — do not run another NGINX or Caddy on ports 80/443 on the same host; Cosmos takes those ports.
- **Existing containers** — Cosmos can proxy and manage containers started outside Cosmos, but for best results start new apps through Cosmos's app store or by importing Compose files through the UI.
