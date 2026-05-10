---
name: cosmos-server
description: Recipe for self-hosting Cosmos Server, an all-in-one secure home server gateway combining reverse proxy, authentication, container manager, app store, VPN, monitoring, and SmartShield anti-bot/anti-DDoS protection. Based on upstream documentation at https://github.com/azukaar/Cosmos-Server.
---

# Cosmos Server

All-in-one secure home server platform. Combines reverse proxy (automatic HTTPS), authentication server (MFA, OpenID), container manager, app store, VPN (Constellation/WireGuard), monitoring, backups (Restic), and SmartShield anti-bot/anti-DDoS — managed from a single web UI. Upstream: <https://github.com/azukaar/Cosmos-Server>. Stars: 5.9k+. License: Apache-2.0.

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Linux host | Docker (host network mode) | Required for full functionality including port binding |
| macOS / Windows | Docker (port-mapped mode) | Limited — host network mode not available; see Gotchas |
| Raspberry Pi / ARM | Docker | Multi-arch supported |

**Important:** Do NOT install via Unraid templates, CasaOS, or Portainer stacks — run the `docker run` command directly per upstream README.

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | Server IP or domain | Used in setup wizard; domain recommended for HTTPS |
| preflight | Admin email | For Let's Encrypt and notifications |
| optional | Domain name | Required for automatic HTTPS/TLS |

## Docker deployment (Linux — recommended)

```bash
docker run -d \
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

Then navigate to `http://your-server-ip` (in an **incognito/private browser window**) and follow the setup wizard.

**Volume notes:**
- `/var/run/docker.sock` — required for container management
- `/var/run/dbus/system_bus_socket` — required for system integration
- `/:/mnt/host` — optional; enables folder management from the UI. Remove if not wanted (you'll need to create container bind-mount paths manually)
- `/var/lib/cosmos:/config` — Cosmos persistent config and data

**`--privileged` note:** Required for AppArmor/SELinux environments and for the Constellation VPN feature. Can be replaced with `--cap-add NET_ADMIN` if you skip Constellation and don't use hardening software.

## macOS / Windows (no host network)

Replace `--network host` with explicit port mappings:

```bash
docker run -d \
  -p 80:80 -p 443:443 -p 4242:4242/udp \
  --privileged \
  --name cosmos-server \
  -h cosmos-server \
  --restart=always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /var/lib/cosmos:/config \
  azukaar/cosmos-server:latest
```

Note: Without host network mode, Cosmos cannot bind arbitrary ports to itself — `ip:port` direct access for apps will not work. Use domain-based routing instead.

## Data directory

All Cosmos config, certificates, and data are stored in `/var/lib/cosmos` on the host (mapped to `/config` in the container). Back up this directory.

## Upgrade procedure

```bash
docker pull azukaar/cosmos-server:latest
docker stop cosmos-server && docker rm cosmos-server
# Re-run the original docker run command with updated image
```

Config in `/var/lib/cosmos` is preserved across container recreations.

## Key features after setup

- **Reverse proxy:** Add URLs/routes pointing to containers or other services; automatic Let's Encrypt TLS
- **App Store:** Install pre-configured apps (Jellyfin, Nextcloud, etc.) with one click
- **Container manager:** View, start/stop, update containers; import docker-compose files
- **SmartShield:** Per-app anti-bot and rate limiting, auto-configured
- **Constellation VPN:** WireGuard-based VPN to access services remotely without opening ports
- **Monitoring:** Real-time CPU/memory/network metrics with alerting

## Gotchas

- **Always use incognito/private mode** for the initial setup wizard to avoid browser cache issues.
- **Do NOT use Unraid templates, CasaOS, or Portainer stacks** — these break Cosmos's port binding behavior. Use the `docker run` command directly.
- Host network mode (`--network host`) is required on Linux for Cosmos to bind ports dynamically to itself. On Mac/Windows, you are limited to the explicitly mapped ports (80, 443, 4242).
- The Docker socket mount (`/var/run/docker.sock`) gives Cosmos full control over all containers on the host — treat it as a high-privilege service.
- `--privileged` grants broad host capabilities. If security-sensitive, use `--cap-add NET_ADMIN` instead and accept that AppArmor/SELinux environments and Constellation VPN won't work.

## Upstream docs

- README: https://github.com/azukaar/Cosmos-Server/blob/master/readme.md
- Official site + docs: https://cosmos-cloud.io/doc
