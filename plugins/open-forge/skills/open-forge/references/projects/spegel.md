# Spegel

Stateless cluster-local OCI registry mirror for Kubernetes. Spegel ("mirror" in Swedish) caches container images from external registries within the cluster so pods pull from a local peer instead of the internet — reducing startup latency, egress costs, and vulnerability to upstream registry outages or rate limits.

**Official site:** https://spegel.dev

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Kubernetes (any) | Helm | Official chart; recommended install method |
| Kubernetes (containerd) | DaemonSet manifest | Must use containerd CRI |
| k3s / k0s / kind | Helm | Tested and supported |

---

## Inputs to Collect

### Phase 1 — Planning
- Kubernetes cluster with **containerd** CRI (required — does not support Docker shim or CRI-O)
- Registries to mirror (e.g. `docker.io`, `ghcr.io`, `quay.io`)
- Node-to-node communication port (default `5001`)

### Phase 2 — Deployment
- Helm values: `spegel.registries` list
- Bootstrap node selector (optional) for initial seed

---

## Software-Layer Concerns

### Helm Install

```bash
helm repo add spegel https://spegel-org.github.io/spegel
helm repo update
helm upgrade --install spegel spegel/spegel \
  --namespace spegel-system \
  --create-namespace
```

### How It Works
1. Spegel runs as a **DaemonSet** on every node.
2. It patches the containerd mirror configuration to point external registries at the local Spegel endpoint.
3. On image pull, containerd first checks the local Spegel peer; if the image is cached on any node, it streams from there — no internet request needed.
4. If no peer has the image, Spegel transparently falls back to the upstream registry.

### Key Helm Values

```yaml
spegel:
  # Registries to mirror (default covers common public registries)
  registries:
    - "https://docker.io"
    - "https://ghcr.io"
    - "https://quay.io"
    - "https://registry.k8s.io"
  # Port for peer-to-peer image distribution
  registryPort: 5001
  # Mirror only already-pulled images vs. also pulling new ones
  mirrorResolveRetries: 3
```

### Data Paths
- Spegel does **not** maintain its own persistent storage — it reads directly from the containerd image store on each node (`/var/lib/containerd`).
- No PVC or external database required.

---

## Upgrade Procedure

```bash
helm repo update
helm upgrade spegel spegel/spegel -n spegel-system
```

Rolling DaemonSet update; no downtime. Review release notes for containerd config changes.

---

## Gotchas

- **Containerd-only** — does not work with Docker daemon or CRI-O.
- **Stateless by design** — images are only available from peers that have already pulled them; the first pull still goes to the upstream registry.
- **Node port 5001** must be reachable between all cluster nodes (not exposed externally).
- **Evolving API** — no stability guarantees yet; breaking changes may occur between versions.
- **Private registries** — pull secrets and credentials are still handled by Kubernetes/containerd; Spegel just mirrors the layer traffic.
- Spegel modifies containerd's hosts config (`/etc/containerd/certs.d/`) — inspect after install to verify correctness.

---

## References
- GitHub: https://github.com/spegel-org/spegel
- Docs / Getting Started: https://spegel.dev/docs/getting-started/
- Helm chart: https://github.com/spegel-org/spegel/tree/main/charts/spegel
