---
name: lazytainer
description: Recipe for deploying Lazytainer, a Docker container lazy-loader that stops/pauses containers when idle and starts them on network activity. Based on upstream documentation at https://github.com/vmorganp/Lazytainer.
---

# Lazytainer

Lazytainer monitors network traffic to containers and **stops or pauses them when idle**, then **starts them on incoming traffic**. Acts as a lightweight traffic-aware sidecar proxy for Docker Compose stacks. Upstream: <https://github.com/vmorganp/Lazytainer>. Stars: 744+.

Useful for reducing resource usage on homelab servers where services (e.g. game servers, dev environments) are only needed occasionally.

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Docker host | Docker Compose | Sidecar pattern — Lazytainer proxies traffic to managed containers |
| Homelab / low-power server | Docker Compose | Primary use case: idle containers consume zero CPU |

## How it works

Lazytainer does **not** automatically manage all containers. You must:

1. Add a `lazytainer.group=<groupName>` label to each container you want to manage.
2. Configure group settings (ports, timeout, thresholds) as labels on the Lazytainer container itself.
3. Route traffic to the managed containers **through** the Lazytainer container's exposed ports.

When Lazytainer detects sufficient network packets on a group's ports, it starts all containers in that group. When traffic falls below the threshold for `inactiveTimeout` seconds, it stops/pauses them.

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | Which containers to manage | Must be in same Docker Compose stack |
| preflight | Ports for each group | Internal container ports (not exposed host ports) |
| optional | Inactivity timeout (seconds) | Default: 30s |
| optional | Min packet threshold | Default: 30 packets |
| optional | Sleep method (stop vs pause) | Default: stop |

## Software-layer concerns

### Labels on Lazytainer container (group configuration)

```yaml
lazytainer:
  labels:
    # Group name + ports (required per group)
    - "lazytainer.group.<groupName>.ports=<port>"
    # Optional: inactivity timeout in seconds (default 30)
    - "lazytainer.group.<groupName>.inactiveTimeout=60"
    # Optional: minimum packet count to wake (default 30)
    - "lazytainer.group.<groupName>.minPacketThreshold=10"
    # Optional: sleep method: stop or pause (default stop)
    - "lazytainer.group.<groupName>.sleepMethod=stop"
    # Optional: poll rate in seconds (default 30)
    - "lazytainer.group.<groupName>.pollRate=15"
    # Optional: ignore connected client count, use only packet count
    - "lazytainer.group.<groupName>.ignoreActiveClients=false"
    # Optional: network interface to monitor (default eth0)
    - "lazytainer.group.<groupName>.netInterface=eth0"
```

### Labels on managed containers (group membership)

```yaml
yourManagedService:
  labels:
    - "lazytainer.group=<groupName>"
```

### Verbose logging

```yaml
lazytainer:
  environment:
    - VERBOSE=true
```

### Network interface

Traffic monitoring requires access to the Docker network interface. Lazytainer needs the network namespace of the managed containers. Ensure containers are on the same Docker network.

## Docker Compose example

Two managed containers (web app on ports 81 and 82) behind a single Lazytainer instance:

```yaml
services:
  lazytainer:
    image: ghcr.io/vmorganp/lazytainer:latest
    restart: unless-stopped
    network_mode: service:managedapp   # share network namespace
    ports:
      - "81:81"
      - "82:82"
    labels:
      - "lazytainer.group.mygroup.ports=81,82"
      - "lazytainer.group.mygroup.inactiveTimeout=60"
      - "lazytainer.group.mygroup.minPacketThreshold=10"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock

  managedapp:
    image: yourapp:latest
    labels:
      - "lazytainer.group=mygroup"
    # No ports here -- traffic routes through lazytainer
```

Note: `network_mode: service:<name>` is a common pattern; refer to the upstream [examples/](https://github.com/vmorganp/Lazytainer/tree/master/examples) directory for complete working stacks.

## Upgrade procedure

```bash
docker compose pull lazytainer
docker compose up -d lazytainer
```

No persistent data volumes — configuration is entirely label-based.

## Gotchas

- Lazytainer does NOT manage containers automatically — labels are required on both Lazytainer and each managed container.
- Traffic must be routed **through** Lazytainer's ports; direct access to managed containers bypasses the idle detector.
- The Docker socket (`/var/run/docker.sock`) must be mounted so Lazytainer can start/stop other containers.
- `sleepMethod=pause` freezes the process in memory (faster wake); `stop` terminates it (lower memory but slower cold start).
- Multiple groups can share ports (e.g. port 81 used by group1 and group2 simultaneously).
- `minPacketThreshold` prevents brief network noise (DNS pings, health checks) from waking containers spuriously.

## Upstream docs

- README: https://github.com/vmorganp/Lazytainer/blob/master/README.md
- Examples: https://github.com/vmorganp/Lazytainer/tree/master/examples
