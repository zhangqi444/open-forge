# Prometheus Node Exporter

Prometheus exporter for hardware and OS metrics exposed by \*NIX kernels. Node Exporter collects CPU, memory, disk, network, and kernel metrics from the host system and exposes them as Prometheus scrape targets.

**Official site:** https://prometheus.io/docs/guides/node-exporter/

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux host | Binary (systemd) | Recommended for bare-metal; accesses host metrics natively |
| Any Linux host | Docker Compose | Requires host networking + bind-mount of `/` |
| Kubernetes | DaemonSet | Deploy via kube-prometheus-stack Helm chart |
| Raspberry Pi / ARM | Binary or Docker | ARM64 build available from Quay |

---

## Inputs to Collect

### Phase 1 — Planning
- Deployment method: binary (systemd) or Docker
- Prometheus scrape interval and job name
- Collectors to enable/disable (defaults cover most use cases)

### Phase 2 — Deployment
- Listen port (default `9100`)
- `path.rootfs` (Docker only — bind-mount of host root)

---

## Software-Layer Concerns

### Docker Compose

```yaml
services:
  node_exporter:
    image: quay.io/prometheus/node-exporter:v1.11.1
    container_name: node_exporter
    command:
      - '--path.rootfs=/host'
    network_mode: host
    pid: host
    restart: unless-stopped
    volumes:
      - '/:/host:ro,rslave'
```

> **Note:** `network_mode: host` and `pid: host` are required so the exporter can see host-level metrics (not just container metrics). The `--path.rootfs=/host` flag tells the exporter to read the host filesystem from the bind-mount.

### Binary / systemd Install

```bash
# Download latest release from https://github.com/prometheus/node_exporter/releases
wget https://github.com/prometheus/node_exporter/releases/latest/download/node_exporter-*.linux-amd64.tar.gz
tar xvf node_exporter-*.tar.gz
sudo cp node_exporter-*/node_exporter /usr/local/bin/
```

Systemd unit (`/etc/systemd/system/node_exporter.service`):
```ini
[Unit]
Description=Prometheus Node Exporter
After=network.target

[Service]
User=node_exporter
ExecStart=/usr/local/bin/node_exporter
Restart=always

[Install]
WantedBy=multi-user.target
```

### Prometheus Scrape Config

```yaml
scrape_configs:
  - job_name: 'node'
    static_configs:
      - targets: ['<host>:9100']
```

### Key Collectors (default-enabled)
- `cpu` — CPU time by mode
- `diskstats` — disk I/O stats
- `filesystem` — filesystem space/inodes
- `loadavg` — system load averages
- `meminfo` — memory utilization
- `netdev` — network interface stats
- `uname` — system uname info

### Disable Collector Example
```bash
node_exporter --no-collector.wifi --no-collector.arp
```

---

## Upgrade Procedure

**Docker:** `docker compose pull && docker compose up -d`

**Binary:** Download new release tarball, replace binary, restart systemd unit: `sudo systemctl restart node_exporter`

---

## Gotchas

- **`network_mode: host` is mandatory in Docker** — without it, node_exporter reports container network metrics, not host.
- **`pid: host` required** for process-related collectors (e.g. `processes`, `perf`).
- **`timex` collector** may require `--cap-add=SYS_TIME` in Docker.
- **Non-root mount points** must be explicitly bind-mounted into the container if you want them in filesystem stats.
- **Firewall:** Port 9100 should be blocked externally; only Prometheus needs to reach it.
- Node Exporter is Linux-only; use [windows_exporter](https://github.com/prometheus-community/windows_exporter) for Windows.

---

## References
- GitHub: https://github.com/prometheus/node_exporter
- Guide: https://prometheus.io/docs/guides/node-exporter/
- Quay.io: https://quay.io/repository/prometheus/node-exporter
- Releases: https://github.com/prometheus/node_exporter/releases
