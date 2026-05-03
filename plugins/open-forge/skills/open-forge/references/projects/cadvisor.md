---
name: cAdvisor
description: Google's Container Advisor — per-container CPU/memory/network/IO stats daemon. Built-in web UI + Prometheus `/metrics` endpoint. The canonical sidecar for monitoring Docker hosts.
---

# cAdvisor

cAdvisor runs as a single container (or binary) that reads `/sys`, `/proc`, `/var/run/docker.sock`, and cgroups to produce per-container resource-usage stats. It ships a minimal web UI on port 8080 and — more importantly — exposes Prometheus metrics at `/metrics` that virtually every Docker-host dashboard (Grafana Node Exporter Full, Docker Dashboard, etc.) consumes.

- Upstream repo: <https://github.com/google/cadvisor>
- Running instructions: <https://github.com/google/cadvisor/blob/master/docs/running.md>
- Runtime options: <https://github.com/google/cadvisor/blob/master/docs/runtime_options.md>
- Kubernetes DaemonSet: <https://github.com/google/cadvisor/tree/master/deploy/kubernetes>
- Image: `ghcr.io/google/cadvisor` (post-v0.53.0; before that, `gcr.io/cadvisor/cadvisor`)

## Compatible install methods

| Infra              | Runtime                          | Notes                                                               |
| ------------------ | -------------------------------- | ------------------------------------------------------------------- |
| Single Docker host | Docker / Compose                 | Recommended for host-level monitoring                               |
| Kubernetes         | DaemonSet (per node)             | Kubernetes already ships its own embedded cAdvisor in kubelet       |
| Bare metal         | Go binary + systemd              | Fully supported; see [running.md](https://github.com/google/cadvisor/blob/master/docs/running.md) |
| Swarm / multi-host | Deploy one per node              | cAdvisor is strictly per-host                                       |

## Inputs to collect

| Input              | Example                            | Phase     | Notes                                                                     |
| ------------------ | ---------------------------------- | --------- | ------------------------------------------------------------------------- |
| Host port          | `8080`                             | Runtime   | Collides with other Docker web UIs; consider `8088` or `9101`             |
| Privileged mode    | yes                                | Security  | cAdvisor needs privileged/device access for some metrics                  |
| `/dev/kmsg` device | mapped                             | Runtime   | Needed for OOM event metrics                                              |
| Prometheus scrape  | job config                         | Observability | Prometheus scrapes `http://cadvisor:8080/metrics`                     |
| Version            | `v0.56.2` (latest at time of writing) | Install | Pin; releases: <https://github.com/google/cadvisor/releases>             |

## Install via `docker run` (upstream's quick-start)

Upstream's canonical invocation (adapted; check the latest at <https://github.com/google/cadvisor/releases>):

```sh
VERSION=v0.56.2
docker run -d \
  --name=cadvisor \
  --restart=unless-stopped \
  --publish=8080:8080 \
  --volume=/:/rootfs:ro \
  --volume=/var/run:/var/run:ro \
  --volume=/sys:/sys:ro \
  --volume=/var/lib/docker/:/var/lib/docker:ro \
  --volume=/dev/disk/:/dev/disk:ro \
  --privileged \
  --device=/dev/kmsg \
  ghcr.io/google/cadvisor:$VERSION
```

Browse `http://<host>:8080/` for the UI or `http://<host>:8080/metrics` for Prometheus scrape.

## Install via Docker Compose (typical pairing with Prometheus + Grafana)

```yaml
services:
  cadvisor:
    image: ghcr.io/google/cadvisor:v0.56.2
    container_name: cadvisor
    restart: unless-stopped
    ports:
      - "8080:8080"
    privileged: true
    devices:
      - /dev/kmsg
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:ro
      - /sys:/sys:ro
      - /var/lib/docker/:/var/lib/docker:ro
      - /dev/disk/:/dev/disk:ro

  prometheus:
    image: prom/prometheus:v2.55.1
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml:ro
    ports:
      - "9090:9090"
```

With a minimal `prometheus.yml` scrape job:

```yaml
scrape_configs:
  - job_name: cadvisor
    static_configs:
      - targets: ['cadvisor:8080']
```

Then point Grafana at Prometheus and import the "Docker and System monitoring" dashboard (Grafana ID 893) or "cAdvisor Exporter" (Grafana ID 14282).

## Install on RHEL / CentOS / Fedora / LXC

Additional flags needed — see the running-instructions doc for the full list, notably:

- Add `--volume=/cgroup:/cgroup:ro` on older cgroup v1 systems
- On LXC / unprivileged containers: more involved; the doc has the recipe

## Install on Kubernetes

Kubelet already embeds a cAdvisor subset — check `/metrics/cadvisor` on each node's kubelet before deploying a separate DaemonSet. If you need the standalone version (for extra metrics or a different version), the DaemonSet is at <https://github.com/google/cadvisor/tree/master/deploy/kubernetes>. Customize via kustomize.

## Configuration flags (common)

Pass as container args, not env vars:

- `--docker_only` — ignore non-Docker cgroups (tighter metric set)
- `--housekeeping_interval=10s` — default 1s, reduce CPU usage by increasing
- `--disable_metrics=disk,diskIO,network,tcp,udp,percpu,sched,process,hugetlb,referenced_memory,cpu_topology,resctrl` — dramatic CPU reduction if you only need CPU+memory
- `--store_container_labels=false --whitelisted_container_labels=com.docker.compose.service` — trims label cardinality (critical for Prometheus)
- `--enable_metrics=cpu,memory,network` — alternative: explicit allowlist

Full reference: <https://github.com/google/cadvisor/blob/master/docs/runtime_options.md>.

## Data & config layout

- **No persistent state.** cAdvisor is a stateless read-only observer.
- All state (historical samples) lives in Prometheus, not cAdvisor.
- Config: command-line flags only (no config file).

## Upgrade

1. Check releases: <https://github.com/google/cadvisor/releases>.
2. Bump the image tag; `docker compose pull && docker compose up -d`.
3. Metric names/labels are stable across minor versions but occasionally change on majors — verify your Grafana panels after major upgrades. The release notes call out metric renames.

## Gotchas

- **High cardinality by default.** cAdvisor's default label set (container labels, namespaces, image hashes) can explode Prometheus TSDB size on hosts with many containers. Use `--store_container_labels=false` and `--whitelisted_container_labels=` to trim. This is the #1 cause of cAdvisor-induced Prometheus pain.
- **CPU usage at default `--housekeeping_interval=1s`** is noticeable on large hosts. Bump to `10s` or `15s` if you don't need sub-minute granularity; your Prometheus scrape interval is likely 15-30s anyway.
- **Privileged mode** is effectively required. Running non-privileged drops several metrics (notably disk IO) silently — check the UI / logs for warnings.
- **Image registry moved.** `gcr.io/cadvisor/cadvisor` was deprecated with v0.53.0; use `ghcr.io/google/cadvisor` going forward. Old tutorials pointing at the gcr.io path will silently fetch stale versions.
- **Not for multi-host aggregation.** cAdvisor per-host reports per-host data. Roll up in Prometheus, not in cAdvisor.
- **K8s double-counting.** Kubelet embeds cAdvisor; running both the kubelet scraper AND a standalone DaemonSet produces duplicate series (different `job` labels but same underlying cgroup). Usually you want one or the other.
- **`/dev/kmsg` device mapping** is needed for OOM event metrics. Some platforms (Docker Desktop on macOS, containerd-only hosts without kmsg access) don't expose it; the metrics silently go missing.
- **Port 8080 collides** with Traefik's default dashboard, some dev servers, and many other containers. Move cAdvisor to 9101 or 8088 in shared environments.
- **Metrics endpoint is unauthenticated.** If you expose port 8080 beyond `localhost`, anyone can read your host's container-level telemetry. Put it behind your reverse proxy + auth, or bind to a private interface / overlay.
- **cgroup v2 support** was added in v0.46.0. Pin at or above that on modern distros (Ubuntu 22.04+, Fedora 34+, RHEL 9).
- **Read-only rootfs mount** (`-v /:/rootfs:ro`) is mandatory — cAdvisor walks it to resolve container paths. Don't use `:ro,delegated` or other flags that silently drop access.

## Links

- Running guide: <https://github.com/google/cadvisor/blob/master/docs/running.md>
- Runtime options: <https://github.com/google/cadvisor/blob/master/docs/runtime_options.md>
- Deploy / Kubernetes: <https://github.com/google/cadvisor/tree/master/deploy/kubernetes>
- Web UI docs: <https://github.com/google/cadvisor/blob/master/docs/web.md>
- REST API: <https://github.com/google/cadvisor/blob/master/docs/api.md>
- Storage plugins: <https://github.com/google/cadvisor/blob/master/docs/storage/README.md>
- Releases: <https://github.com/google/cadvisor/releases>
