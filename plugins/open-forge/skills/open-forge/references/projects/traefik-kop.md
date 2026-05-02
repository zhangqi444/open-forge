---
name: traefik-kop-project
description: traefik-kop recipe for open-forge. Docker-to-Redis-to-Traefik discovery agent for multi-host clusters without Swarm/Kubernetes. Runs on remote nodes, reads container labels, publishes routing config to a shared Redis instance that Traefik polls. Upstream: https://github.com/jittering/traefik-kop
---

# traefik-kop

A dynamic Docker → Redis → Traefik discovery agent that solves multi-host routing without Swarm or Kubernetes.

**Problem it solves:** You have one public-facing Traefik instance on `docker1` and additional Docker nodes (`docker2`, `docker3`, …). Traefik's built-in Docker provider only sees containers on its own host. `traefik-kop` runs on each remote node, reads container labels using the same logic as Traefik's Docker provider, and publishes those routing configs to a shared Redis instance. Traefik is configured to use the Redis provider and automatically picks up routes from all nodes.

Upstream: <https://github.com/jittering/traefik-kop>

```
+---------+   :443   +----------+   :8088   +-------------+
|   WAN   |--------->| traefik  |<--------->| svc-nginx   |
+---------+          +----------+           +-------------+
                     |  redis   |<--------->| traefik-kop |
                     | docker1  |           |   docker2   |
```

## Compatible combos

| Infra | Notes |
|---|---|
| Multi-host Docker (no Swarm/K8s) | Primary use case |
| Single-host (testing) | Works but adds complexity — just use the Docker provider directly |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "IP/address of the Redis instance?" | e.g. `192.168.1.50:6379` |
| preflight | "IP address this node should advertise to Traefik?" | `BIND_IP` — the public/LAN IP of the remote node |
| preflight (alternative) | "Or, which network interface to derive the bind IP from?" | `BIND_INTERFACE` — requires `network_mode: host` |
| preflight | "Redis username/password?" | Optional; defaults to user `default`, no password |

## Software-layer concerns

### Image

```
ghcr.io/jittering/traefik-kop:latest
```

### Step 1 — Configure Traefik (on docker1) to use Redis provider

Add the Redis provider to `traefik.yml`:

```yaml
providers:
  providersThrottleDuration: 2s
  docker:
    watch: true
    endpoint: unix:///var/run/docker.sock
    swarmModeRefreshSeconds: 15s
    exposedByDefault: false
  redis:
    endpoints:
      - "redis:6379"   # assumes Redis is linked on the same host as Traefik
```

Redis itself can run on `docker1` (alongside Traefik) or on a separate host — traefik-kop just needs to reach it over the network.

### Step 2 — Run traefik-kop on each remote node

```yaml
services:
  traefik-kop:
    image: ghcr.io/jittering/traefik-kop:latest
    restart: unless-stopped
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      - REDIS_ADDR=192.168.1.50:6379   # Redis address
      - BIND_IP=192.168.1.75            # this node's IP (advertised to Traefik)
```

> Source: upstream README — <https://github.com/jittering/traefik-kop>

### Step 3 — Add standard Traefik labels to target containers

```yaml
services:
  nginx:
    image: nginx:alpine
    restart: unless-stopped
    ports:
      - 8088:80   # host port is auto-detected as the service endpoint
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.nginx.rule=Host(`nginx-on-docker2.example.com`)"
      - "traefik.http.routers.nginx.tls=true"
      - "traefik.http.routers.nginx.tls.certresolver=default"
      # optional: explicitly set service port
      - "traefik.http.services.nginx.loadbalancer.server.port=8088"
```

No traefik-kop–specific labels are required — it uses the same `traefik.*` labels.

### Configuration reference

All options available as CLI flags or environment variables:

| Env var | Default | Purpose |
|---|---|---|
| `REDIS_ADDR` | `127.0.0.1:6379` | Redis address |
| `REDIS_USER` | `default` | Redis username |
| `REDIS_PASS` | — | Redis password |
| `REDIS_DB` | `0` | Redis DB number |
| `REDIS_TTL` | `0` | Redis key TTL (seconds; 0 = no expiry) |
| `BIND_IP` | (auto) | IP address advertised to Traefik for this node's services |
| `BIND_INTERFACE` | — | Interface to derive bind IP from (requires `network_mode: host`) |
| `SKIP_REPLACE` | `false` | Disable custom IP/port auto-detection; rely on Traefik native detection |
| `DOCKER_ADDR` | `unix:///var/run/docker.sock` | Docker endpoint |
| `DOCKER_CONFIG` | — | Docker provider config file (must end in `.yaml`) |
| `DOCKER_PREFIX` | — | Label prefix filter |
| `KOP_POLL_INTERVAL` | `60` | Container list refresh interval (seconds) |
| `NAMESPACE` | — | Only process containers for this namespace |
| `KOP_HOSTNAME` | `server.local` | Hostname for this node in Redis |
| `VERBOSE` / `DEBUG` | `false` | Enable debug logging |

### IP binding precedence (highest → lowest)

1. `kop.<service-name>.bind.ip` label on the container
2. `kop.bind.ip` label on the container
3. Container networking IP (if `traefik.docker.network` label is set)
4. `BIND_IP` env var
5. `BIND_INTERFACE` env var (requires `network_mode: host`)
6. Auto-detected host IP

For most setups, explicitly setting `BIND_IP` is the most reliable option.

### Load balancer merging

If the same service is exposed by multiple containers on the same node, traefik-kop merges them into a single load-balanced upstream — the same as Traefik's native Docker provider behavior.

### Namespaces

Use `NAMESPACE` (or the `--namespace` flag) to make a traefik-kop instance only manage containers tagged with a specific namespace label. Useful on shared hosts with multiple teams or environments.

Namespace via label prefix: set `DOCKER_PREFIX` to use a custom label prefix instead of `traefik.*` (e.g. `myapp.traefik.*`).

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

No persistent state on the remote nodes — all routing config is stored in Redis. Upgrading is safe at any time.

## Gotchas

- **Docker socket access is required** — `traefik-kop` must mount `/var/run/docker.sock` to read container labels. This is full Docker access on the node; run it in a trusted environment.
- **BIND_IP must be reachable from Traefik's network** — set it to the LAN/WAN IP of the remote node, not a Docker-internal IP. Traefik will try to connect to this IP for service traffic.
- **`BIND_INTERFACE` requires `network_mode: host`** — the container must have access to the host network interfaces to derive the IP.
- **`SKIP_REPLACE=1` needed for overlay/CNI networks** — if containers use a network-routable overlay IP and you set `traefik.docker.network`, disable IP replacement so Traefik uses the overlay address directly.
- **Redis TTL of 0** — keys never expire. If a remote node goes down, its routes stay in Redis until traefik-kop is restarted and removes stale entries. Set `REDIS_TTL` to a positive value to auto-expire.
- **Same Traefik label syntax as the Docker provider** — no special labels needed for traefik-kop; use the same `traefik.*` labels you'd use on `docker1`.
- **Polling interval** — default 60 s means new containers on remote nodes appear in Traefik within ~1 minute. Reduce `KOP_POLL_INTERVAL` for faster discovery at the cost of more Docker API calls.

## Links

- Upstream README (full config reference): <https://github.com/jittering/traefik-kop>
