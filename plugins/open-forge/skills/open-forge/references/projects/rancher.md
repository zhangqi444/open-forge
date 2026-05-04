---
name: rancher
description: Rancher recipe for open-forge. Open-source Kubernetes management platform for running and operating multiple K8s clusters from a single control plane.
---

# Rancher

Open-source container management platform for organizations running Kubernetes in production. Provides a single pane of glass to deploy, manage, and monitor multiple Kubernetes clusters across on-prem, cloud, and edge. Maintained by SUSE. Upstream: <https://github.com/rancher/rancher>. Docs: <https://ranchermanager.docs.rancher.com/>.

## Compatible install methods

| Method | When to use |
|---|---|
| Single Docker container | Dev / evaluation only — **not production** |
| Helm on K3s/RKE2 (recommended) | Production; HA with 3-node etcd cluster |
| Rancher Desktop | Local dev workstation (macOS/Windows/Linux) |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Single-node eval or HA production?" | HA requires 3 nodes + load balancer |
| preflight | "Domain / hostname for Rancher UI?" | Required for TLS cert provisioning |
| preflight | "TLS method?" | Let's Encrypt, Bring-Your-Own cert, or Rancher self-signed |
| preflight | "Initial admin password?" | Set via `bootstrapPassword` Helm value |

## Single-node Docker (eval only)

```bash
sudo docker run -d --restart=unless-stopped \
  -p 80:80 -p 443:443 \
  --privileged \
  rancher/rancher:stable
```

Open https://localhost — retrieve bootstrap password from logs:
```bash
docker logs <container-id> 2>&1 | grep "Bootstrap Password"
```

> ⚠️ Single-node Docker is for evaluation only. Data is not persisted across container restarts unless volumes are mounted. Use Helm for production.

## Helm install (production, on existing K8s/K3s)

Full guide: <https://ranchermanager.docs.rancher.com/pages-for-subheaders/installation-and-upgrade>

```bash
# Add Rancher Helm repo (stable)
helm repo add rancher-stable https://releases.rancher.com/server-charts/stable
helm repo update

# Install cert-manager first
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.4/cert-manager.crds.yaml
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager --create-namespace \
  --set installCRDs=true

# Install Rancher
helm install rancher rancher-stable/rancher \
  --namespace cattle-system --create-namespace \
  --set hostname=rancher.example.com \
  --set bootstrapPassword=changeme \
  --set ingress.tls.source=letsEncrypt \
  --set letsEncrypt.email=admin@example.com
```

## Software-layer concerns

- Ports: `80` (HTTP redirect), `443` (HTTPS UI + API)
- Rancher manages downstream clusters via Rancher agents deployed in each cluster
- cert-manager is required for automated TLS; install before Rancher
- Data stored in the underlying K8s etcd — back up etcd regularly
- Rancher Desktop is a separate desktop app: <https://rancherdesktop.io/>
- `rancher/rancher:stable` is the recommended production tag; `latest` tracks release candidates

## Supported downstream cluster types

- K3s, RKE, RKE2 (Rancher-provisioned)
- EKS, GKE, AKS (hosted Kubernetes import)
- Any CNCF-conformant Kubernetes cluster (import)

## Upgrade procedure

1. `helm repo update`
2. `helm upgrade rancher rancher-stable/rancher --namespace cattle-system --reuse-values`
3. Monitor upgrade progress: `kubectl -n cattle-system rollout status deploy/rancher`

## Gotchas

- `--privileged` flag is required for the Docker single-node install
- HA install requires 3 nodes to avoid etcd split-brain
- cert-manager must be installed before Rancher, not after
- Rancher creates many CRDs — factor this into cluster sizing
- Single-node Docker install has no upgrade path to Helm/HA — rebuild for production from the start

## Links

- GitHub: <https://github.com/rancher/rancher>
- Install docs: <https://ranchermanager.docs.rancher.com/pages-for-subheaders/installation-and-upgrade>
- Full docs: <https://ranchermanager.docs.rancher.com/>
- Docker Hub: <https://hub.docker.com/r/rancher/rancher>
