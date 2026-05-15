---
name: k3s
description: Recipe for K3s — lightweight, production-ready Kubernetes distribution in a single binary under 100 MB. CNCF sandbox project by Rancher/SUSE.
---

# K3s

Lightweight Kubernetes distribution. Fully conformant Kubernetes packaged as a single binary under 100 MB. Designed for resource-constrained environments: edge, IoT, CI, ARM devices, and single-machine dev setups. Replaces etcd with SQLite by default (etcd, PostgreSQL, MySQL, MariaDB also supported). Bundles containerd, Flannel CNI, CoreDNS, Traefik ingress, Metrics Server, and Helm controller. CNCF project. Upstream: <https://github.com/k3s-io/k3s>. Docs: <https://docs.k3s.io>. License: Apache-2.0. ~29K stars.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Install script | <https://docs.k3s.io/quick-start> | Yes | Recommended for single-node and small clusters |
| Helm chart (k3s itself as a pod) | n/a | Community | Rare — k3s runs on the OS, not inside k8s |
| k3sup (helper tool) | <https://github.com/alexellis/k3sup> | Community | Multi-node cluster bootstrapping via SSH |
| Ansible role | <https://github.com/techno-tim/k3s-ansible> | Community | IaC provisioning of multi-node clusters |
| Docker | Not recommended | — | K3s runs best directly on the OS |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| infra | Single node or multi-node cluster? | single / multi | Drives server vs agent setup |
| infra | Node IP / hostname? | IP or FQDN | Required for TLS SANs |
| infra | External datastore (optional)? | postgres:// / mysql:// | Optional; SQLite is default for single-node |
| software | Disable Traefik ingress? | Boolean | Optional; disable if using Nginx/Caddy ingress |
| software | Cluster token? | String | Required for multi-node; agents use this to join |

## Software-layer concerns

### Quick install (single node, server + agent on same host)

```bash
curl -sfL https://get.k3s.io | sh -
# Wait for node to be ready
sudo k3s kubectl get node
```

K3s starts automatically as a systemd service (`k3s.service`). `kubectl` is available as `k3s kubectl` or symlinked to `/usr/local/bin/kubectl`.

### Multi-node cluster

**Server (control plane):**

```bash
curl -sfL https://get.k3s.io | sh -s - server \
  --cluster-init \
  --token MY_CLUSTER_SECRET \
  --tls-san your-server-ip-or-domain
```

**Agent (worker nodes):**

```bash
curl -sfL https://get.k3s.io | K3S_URL=https://server-ip:6443 K3S_TOKEN=MY_CLUSTER_SECRET sh -
```

### Install options (environment variables)

| Variable | Description |
|---|---|
| INSTALL_K3S_VERSION | Pin a specific version (e.g. v1.31.0+k3s1) |
| INSTALL_K3S_EXEC | Server flags (e.g. `--disable traefik`) |
| K3S_URL | Server URL for agent registration |
| K3S_TOKEN | Cluster secret token |
| K3S_KUBECONFIG_MODE | kubeconfig file permissions (e.g. 644 for non-root kubectl) |

### Disable bundled components

```bash
# Disable Traefik (use your own ingress)
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable traefik" sh -

# Disable servicelb (use MetalLB instead)
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable servicelb" sh -
```

### kubeconfig

K3s writes the kubeconfig to `/etc/rancher/k3s/k3s.yaml` (root-owned by default). To use with regular kubectl:

```bash
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
# or copy to ~/.kube/config
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config && sudo chown $USER ~/.kube/config
```

### Data directory

K3s stores data in `/var/lib/rancher/k3s/`. Back up this directory, especially the etcd/SQLite data and TLS certs.

### Helm support

K3s includes a Helm controller — deploy Helm charts via `HelmChart` CRDs:

```yaml
apiVersion: helm.cattle.io/v1
kind: HelmChart
metadata:
  name: grafana
  namespace: kube-system
spec:
  chart: grafana
  repo: https://grafana.github.io/helm-charts
  targetNamespace: monitoring
```

## Upgrade procedure

```bash
# In-place upgrade (re-run install script with new version)
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=v1.36.0+k3s1 sh -

# Or use system-upgrade-controller for automated cluster upgrades
# https://docs.k3s.io/upgrades/automated
```

## Gotchas

- SQLite is not HA: single-node SQLite is fine for dev/small deployments. For HA, use embedded etcd (`--cluster-init`) or an external datastore.
- Firewall ports: open 6443/TCP (API server), 10250/TCP (kubelet), 51820/UDP (Flannel WireGuard if enabled), and 8472/UDP (Flannel VXLAN) between nodes.
- ARM support: K3s runs on ARM64 and ARMv7 (Raspberry Pi). Use the same install script — it auto-detects architecture.
- SELinux: K3s has SELinux support on RHEL/CentOS — install the `k3s-selinux` RPM package first.
- Traefik v2: K3s bundles Traefik as the default ingress. If you prefer Nginx/ingress-nginx, disable Traefik with `--disable traefik`.
- kubeconfig permissions: the default kubeconfig is root-only. Set `K3S_KUBECONFIG_MODE=644` or adjust permissions for non-root use.

## Links

- GitHub: <https://github.com/k3s-io/k3s>
- Docs: <https://docs.k3s.io>
- Quick start: <https://docs.k3s.io/quick-start>
- k3sup (multi-node bootstrapper): <https://github.com/alexellis/k3sup>
- Releases: <https://github.com/k3s-io/k3s/releases>
- Helm controller: <https://docs.k3s.io/helm>
