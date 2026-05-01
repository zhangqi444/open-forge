---
name: ZTNet
description: "Self-hosted ZeroTier network controller web UI. Docker. Next.js/TypeScript + PostgreSQL. sinamics/ztnet. Multi-user, organizations, network management, member control, REST API, TOTP 2FA, OIDC SSO."
---

# ZTNet

**Self-hosted web UI for managing ZeroTier networks.** Control your ZeroTier virtual networks from a clean Next.js dashboard — create/delete networks, manage members, control access, invite users, set up organizations for team-based multi-tenancy, configure routes, and more. REST API for automation. 2FA (TOTP) and OIDC SSO.

Built + maintained by **sinamics**. See repo license.

- Upstream repo: <https://github.com/sinamics/ztnet>
- Docs: <https://ztnet.network>
- Docker Hub: <https://hub.docker.com/r/sinamics/ztnet>
- Discord: <https://discord.gg/VafvyXvY58>

## Architecture in one minute

- **Next.js / TypeScript** frontend + backend (tRPC API)
- **PostgreSQL 15** database (Prisma ORM)
- **ZeroTier** daemon: `zyclonite/zerotier` — the actual ZeroTier controller
- Docker Compose: `ztnet` + `zerotier` + `postgres` containers
- Port **3000** (web UI)
- The ZeroTier container needs `NET_ADMIN` + `SYS_ADMIN` capabilities + `/dev/net/tun` device
- Resource: **low-medium** — Next.js + PostgreSQL

## Compatible install methods

| Infra              | Runtime                 | Notes                                                       |
| ------------------ | ----------------------- | ----------------------------------------------------------- |
| **Docker Compose** | `sinamics/ztnet`        | **Primary** — Docker Hub; includes ZeroTier + PostgreSQL    |
| **Kubernetes**     | Helm chart              | See docs for k8s/Helm install                               |
| **OpenMediaVault** | Plugin available        | Community integration                                       |
| **Portainer**      | Stack template          | Available as Portainer stack                                |

## Install via Docker Compose

```yaml
services:
  postgres:
    image: postgres:15.2-alpine
    container_name: postgres
    restart: unless-stopped
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: ztnet
    volumes:
      - postgres-data:/var/lib/postgresql/data
    networks:
      - app-network

  zerotier:
    image: zyclonite/zerotier:1.14.2
    hostname: zerotier
    container_name: zerotier
    restart: unless-stopped
    volumes:
      - zerotier:/var/lib/zerotier-one
    cap_add:
      - NET_ADMIN
      - SYS_ADMIN
    devices:
      - /dev/net/tun:/dev/net/tun
    networks:
      - app-network
    ports:
      - "9993:9993/udp"
    environment:
      - ZT_OVERRIDE_LOCAL_CONF=true
      - ZT_ALLOW_MANAGEMENT_FROM=172.31.255.0/29

  ztnet:
    image: sinamics/ztnet:latest
    container_name: ztnet
    ports:
      - "3000:3000"
    volumes:
      - zerotier:/var/lib/zerotier-one
    restart: unless-stopped
    environment:
      POSTGRES_HOST: postgres
      POSTGRES_PORT: 5432
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: ztnet
    networks:
      - app-network
    depends_on:
      postgres:
        condition: service_healthy
      zerotier:
        condition: service_started

networks:
  app-network:

volumes:
  zerotier:
  postgres-data:
```

Full compose with `healthcheck` and extra options: <https://ztnet.network/installation/docker-compose>

## First boot

1. `docker compose up -d`.
2. Visit `http://localhost:3000`.
3. Register the first user → becomes admin.
4. Create a **network** (ZeroTier virtual network).
5. Copy the **Network ID** (16 hex characters).
6. On devices you want to join: `zerotier-cli join <network-id>`.
7. In ZTNet → network member list → authorize the joining device.
8. Configure routes, tags, rules as needed.
9. Enable **TOTP 2FA** in account settings.
10. Put behind TLS.

## Features overview

| Feature | Details |
|---------|---------|
| Network management | Create, configure, delete ZeroTier networks |
| Member control | Authorize/deauthorize devices; set names, descriptions |
| IP assignment | View assigned IPs; configure IP pools |
| Routes | Configure managed routes for the virtual network |
| Multi-user | Invite users; each user manages their own networks |
| Organizations | Team-based multi-tenancy; share networks across org members |
| TOTP 2FA | Per-account time-based OTP authentication |
| OIDC SSO | Single Sign-On via OIDC providers |
| REST API | Full API for automation (documented at ztnet.network) |
| Webhook | Event-based webhooks for member join/leave events |
| Network rules | Configure ZeroTier network rules (firewall, tagging) |
| Mail invites | Email invite flow for new users |
| Audit log | Track network and member changes |

## What ZeroTier is

ZeroTier creates encrypted virtual networks over the internet — any device anywhere can join a ZeroTier network and communicate as if on the same LAN. ZTNet provides the management UI for the self-hosted ZeroTier **controller** (the component that authorizes devices and defines network topology). ZeroTier's own management tools exist (my.zerotier.com SaaS), but ZTNet is the self-hosted alternative.

## Gotchas

- **`cap_add: NET_ADMIN + SYS_ADMIN` and `/dev/net/tun` are required.** The ZeroTier daemon container needs Linux capabilities to create virtual network interfaces. Without these, ZeroTier can't create the `ztXXXXXX` interface and no devices can join.
- **Port 9993/UDP must be open.** ZeroTier uses UDP port 9993 for peer communication. Open this port in your firewall for ZeroTier to work reliably (without it, ZeroTier falls back to relays which adds latency).
- **ZTNet ≠ ZeroTier planet/moon.** ZTNet manages your local controller networks. It doesn't replace ZeroTier's global planet infrastructure — your devices still use ZeroTier's global roots for peer discovery. ZTNet only controls which devices are authorized on your private networks.
- **ZeroTier volume shared between ZeroTier + ZTNet containers.** Both the `zerotier` container and the `ztnet` container mount the same `zerotier` volume. ZTNet reads ZeroTier's controller state from this shared volume. Don't remove the volume — it contains your controller's identity and network state.
- **First user is admin.** Like bewCloud — the first registered account becomes the server admin.
- **Organizations for teams.** The organizations feature allows multiple users to share and co-manage networks. Each org has its own member roster and shared networks. Admin can assign users to orgs.
- **REST API.** The full API is documented at <https://ztnet.network/Rest%20Api/stats>. Use it for automation, scripting network creation, or integrating ZTNet into infrastructure tooling.
- **Restrict to localhost.** For security, consider changing the port binding from `3000:3000` to `127.0.0.1:3000:3000` in the compose file and put ZTNet behind a TLS reverse proxy.

## Backup

```sh
docker compose stop ztnet
docker compose exec postgres pg_dump -U postgres ztnet > ztnet-$(date +%F).sql
docker run --rm -v ztnet_zerotier:/data -v $(pwd):/backup alpine tar czf /backup/zerotier-$(date +%F).tgz /data
docker compose start ztnet
```

## Upgrade

```sh
docker compose pull && docker compose up -d
```

## Project health

Active Next.js/TypeScript development, Docker Hub, docs site (ztnet.network), organizations + multi-user, REST API, TOTP, OIDC, Discord. Solo/small team by sinamics.

## ZeroTier-controller-family comparison

- **ZTNet** — Next.js, organizations, multi-user, REST API, TOTP, OIDC, Docker, active
- **ZeroUI** — Node.js, simpler; less feature-rich; older
- **my.zerotier.com** — official SaaS; free tier; not self-hosted
- **Netmaker** — Go, ZeroTier alternative stack; more complex; different architecture

**Choose ZTNet if:** you self-host a ZeroTier controller and want a polished web UI with multi-user support, organizations, 2FA, OIDC, and a REST API for automation.

## Links

- Repo: <https://github.com/sinamics/ztnet>
- Docs: <https://ztnet.network>
- Docker Hub: <https://hub.docker.com/r/sinamics/ztnet>
- Discord: <https://discord.gg/VafvyXvY58>
