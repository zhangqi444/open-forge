---
name: coroot
description: Coroot recipe for open-forge. Open-source eBPF-based observability platform providing zero-instrumentation metrics, logs, traces, and profiles with actionable insights.
---

# Coroot

Open-source observability platform that uses eBPF for zero-instrumentation data collection. Automatically gathers metrics, logs, traces, and profiles, then surfaces actionable insights — no manual instrumentation required for most services. Upstream: <https://github.com/coroot/coroot>. Docs: <https://docs.coroot.com/>.

## Compatible install methods

| Method | When to use |
|---|---|
| Docker Compose | Single-node or small environments |
| Helm (Kubernetes) | Production K8s; full eBPF agent deployment |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Docker Compose or Kubernetes/Helm?" | Drives install path |
| preflight | "Domain for Coroot UI?" | For reverse-proxy TLS setup |

## Docker Compose example

```yaml
version: "3.9"
services:
  coroot:
    image: ghcr.io/coroot/coroot:latest
    privileged: true          # required for eBPF
    pid: host                 # required for eBPF process visibility
    network_mode: host        # recommended for full network visibility
    restart: unless-stopped
    volumes:
      - /sys/kernel/debug:/sys/kernel/debug:ro
      - /sys/fs/cgroup:/sys/fs/cgroup:ro
      - coroot-data:/data
    environment:
      LISTEN: 0.0.0.0:8080

volumes:
  coroot-data:
```

- UI: http://localhost:8080

## Kubernetes / Helm

```bash
helm repo add coroot https://coroot.github.io/helm-charts
helm install coroot coroot/coroot-operator -n coroot --create-namespace
```

Full Helm docs: <https://docs.coroot.com/installation/kubernetes/>

## Software-layer concerns

- Port: `8080` (UI)
- eBPF requires Linux kernel ≥ 4.16; privileged container + host PID namespace
- Data stored in `/data` (built-in Prometheus-compatible TSDB); persist this volume
- Supports external Prometheus / Grafana integration
- Community Edition is free; [Coroot Enterprise](https://coroot.com/enterprise/) adds SSO, RBAC, audit logs
- Also collects profiles (CPU, memory down to line of code) via eBPF — no code changes needed

## Upgrade procedure

1. Pull new image: `docker compose pull coroot`
2. Restart: `docker compose up -d coroot`
3. Data volume persists automatically

## Gotchas

- `privileged: true` and `pid: host` are required — deploy only in trusted environments
- `network_mode: host` gives the most complete network visibility; can be omitted with reduced data
- eBPF probes require a compatible kernel; doesn't work on Windows containers or some hardened kernels
- Community Edition stores data locally; no remote write by default — integrate Prometheus remote_write for long-term retention

## Links

- GitHub: <https://github.com/coroot/coroot>
- Docs: <https://docs.coroot.com/>
- Helm charts: <https://github.com/coroot/helm-charts>
