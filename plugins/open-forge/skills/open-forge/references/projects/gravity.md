---
name: Gravity
description: "Self-hosted fully-replicated DNS, DHCP, and TFTP server backed by etcd. Docker. Go. BeryJu/gravity. Clustered DNS with etcd replication; Prometheus metrics; web UI; zone management; DHCP leases; Grafana dashboard. MIT."
---

# Gravity

**Self-hosted fully-replicated DNS, DHCP and TFTP server backed by etcd.** Run a clustered, highly-available internal DNS and DHCP service with a web management UI. All data is stored in and replicated via etcd, providing a distributed, fault-tolerant network services infrastructure. Built-in Prometheus metrics and Grafana dashboard support.

Built + maintained by **BeryJu** (Jens Langhammer). MIT.

- Upstream repo: <https://github.com/BeryJu/gravity>
- GHCR: `ghcr.io/beryju/gravity`
- Docs: <https://gravity.beryju.io>

## Architecture in one minute

- **Go** single binary embeds etcd, DNS server, DHCP server, TFTP server, and web UI
- **etcd** — distributed KV store (embedded, or external cluster for HA)
- **`--net=host`** — required to listen on standard DNS (53), DHCP (67/68), TFTP (69) ports
- Port **8008** — web management UI + API
- Port **53** — DNS (UDP/TCP)
- Port **67/68** — DHCP
- Port **69** — TFTP
- Data persisted in a named volume (`/data`)
- Resource: **low** — single Go binary with embedded etcd; minimal RAM/CPU

## Compatible install methods

| Infra      | Runtime                    | Notes                                              |
| ---------- | -------------------------- | -------------------------------------------------- |
| **Docker** | `ghcr.io/beryju/gravity`   | **Primary** — uses `--net=host`; single container  |
| Docker Compose | multi-node compose     | For clustered / HA deployments                     |
| Binary     | Linux                      | Single Go binary; see releases                     |

## Install via Docker Compose

```yaml
services:
  gravity:
    hostname: gravity1        # Must be static, unique, and stable across restarts
    image: ghcr.io/beryju/gravity:stable
    restart: unless-stopped
    network_mode: host
    user: root
    volumes:
      - data:/data
    # DNS/DHCP queries generate a lot of log entries at info level
    # Use log limits to prevent disk fill-up
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "3"

volumes:
  data:
    driver: local
```

```bash
docker compose up -d
```

Web UI: `http://your-server:8008`

## Cluster setup (multi-node)

Each node in a Gravity cluster needs:
1. A unique, static `hostname`
2. Ability to reach other nodes on the etcd peer ports

```yaml
# Node 2 example — join existing cluster
services:
  gravity:
    hostname: gravity2
    image: ghcr.io/beryju/gravity:stable
    restart: unless-stopped
    network_mode: host
    user: root
    environment:
      - BOOTSTRAP_ROLES=dns;dhcp;api;etcd
      - ETCD_JOIN_CLUSTER=gravity1:2380  # IP/hostname of node 1
    volumes:
      - data:/data
```

See the [docs](https://gravity.beryju.io) for full cluster setup.

## Features overview

| Feature | Details |
|---------|---------|
| DNS server | Authoritative + recursive; zone management via web UI |
| DHCP server | DHCPv4 lease management; static assignments |
| TFTP server | PXE boot support |
| etcd replication | Fully replicated across cluster nodes |
| Web UI | Zone management, DNS records, DHCP leases, cluster status |
| Prometheus metrics | Built-in `/metrics` endpoint |
| Grafana dashboard | Pre-built dashboard (see docs) |
| REST API | Manage all resources programmatically |
| HA clustering | Multiple nodes with etcd replication |

## Gotchas

- **`--net=host` is required.** Gravity listens on privileged ports (53, 67, 68, 69) and needs direct host network access. It must also be `user: root` to bind these ports.
- **`hostname` must be static and unique.** The hostname is Gravity's node identity in the etcd cluster. If it changes, the node is treated as a new node. Set a fixed `hostname:` in compose — never rely on Docker's auto-generated hostname.
- **Log volume.** At the default `info` log level, every DNS query and DHCP request is logged. Use log driver limits (`max-size`, `max-file`) to prevent disk fill.
- **Port 53 conflict.** On many Linux systems (Ubuntu especially), `systemd-resolved` listens on port 53. You may need to disable it: `sudo systemctl disable --now systemd-resolved` and update `/etc/resolv.conf`.
- **MIT license.** Free for commercial use.

## Backup

```sh
# All data is in the 'data' volume
docker run --rm -v gravity_data:/data -v $(pwd):/backup alpine \
  tar czf /backup/gravity-data-$(date +%F).tar.gz /data
```

## Upgrade

```sh
docker compose pull && docker compose up -d
```

## Project health

Active Go development, MIT license, Prometheus + Grafana integration.

## DNS-server-family comparison

- **Gravity** — Go, DNS+DHCP+TFTP, etcd replication, web UI, HA clustering; MIT
- **Pi-hole** — DNS sinkhole/ad-blocker, DHCP; web UI; EUPL-1.2
- **AdGuard Home** — DNS ad-blocker, DHCP; web UI; GPL-3.0
- **PowerDNS** — Full-featured DNS server suite; various licenses
- **CoreDNS** — Plugin-based DNS server; Apache-2.0

**Choose Gravity if:** you need a self-hosted clustered DNS + DHCP server with etcd-backed replication for high availability, a web management UI for DNS zones and DHCP leases, and built-in Prometheus monitoring.

## Links

- Repo: <https://github.com/BeryJu/gravity>
- Docs: <https://gravity.beryju.io>
- GHCR: <https://github.com/BeryJu/gravity/pkgs/container/gravity>
