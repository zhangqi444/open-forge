---
name: headlamp
description: Headlamp recipe for open-forge. Vendor-independent, extensible Kubernetes web UI. Runs in-cluster or as a desktop app. Now a Kubernetes SIG UI project.
---

# Headlamp

Easy-to-use, extensible Kubernetes web UI. Vendor-neutral; works with any conformant K8s cluster. Supports multi-cluster, RBAC-aware UI controls, logs, exec, resource editor, and plugins. Now a [Kubernetes SIG UI](https://github.com/kubernetes-sigs/headlamp) project. Upstream: <https://github.com/kubernetes-sigs/headlamp>. Docs: <https://headlamp.dev/docs/latest/>.

> **Note:** Container images are hosted on GHCR (`ghcr.io/headlamp-k8s/headlamp`), not Docker Hub.

## Compatible install methods

| Method | When to use |
|---|---|
| In-cluster (Helm) | Production; runs as a pod in the cluster |
| Desktop app | Local dev; uses existing kubeconfig |
| Docker (in-cluster mode) | Quick in-cluster eval without Helm |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "In-cluster or desktop?" | Drives install path |
| preflight | "Expose via Ingress or port-forward?" | Ingress for persistent access; port-forward for quick eval |
| preflight | "Domain for Ingress?" | If using Ingress |

## Helm install (in-cluster)

Full guide: <https://headlamp.dev/docs/latest/installation/in-cluster/>

```bash
helm repo add headlamp https://headlamp-k8s.github.io/headlamp/
helm repo update
helm install headlamp headlamp/headlamp \
  --namespace headlamp --create-namespace
```

Access via port-forward:
```bash
kubectl port-forward svc/headlamp 8080:80 -n headlamp
# Open http://localhost:8080
```

Or expose via Ingress — see Helm values: <https://github.com/headlamp-k8s/headlamp/tree/main/charts/headlamp>

## Desktop app

Download from: <https://headlamp.dev/docs/latest/installation/desktop/>
- Available for Linux, macOS, Windows
- Automatically reads `~/.kube/config`; no server-side install needed

## Docker (quick eval)

```bash
docker run -p 4466:4466 --rm \
  -v ~/.kube:/root/.kube \
  ghcr.io/headlamp-k8s/headlamp:latest \
  -in-cluster=false -kubeconfig=/root/.kube/config
```

## Software-layer concerns

- Container image: `ghcr.io/headlamp-k8s/headlamp` (GHCR, not Docker Hub)
- Port: `4466` (container), `80` (Helm service default)
- RBAC-aware: Headlamp reflects the permissions of the authenticated user — no delete button if RBAC doesn't allow it
- Auth: service account token, OIDC, or kubeconfig depending on deployment mode
- Extensible via [plugins](https://github.com/headlamp-k8s/plugins) — add custom UI panels

## Upgrade procedure

1. `helm repo update`
2. `helm upgrade headlamp headlamp/headlamp --namespace headlamp --reuse-values`

## Gotchas

- Image is on **GHCR** (`ghcr.io/headlamp-k8s/headlamp`), not Docker Hub — ensure your cluster can pull from `ghcr.io`
- Project recently moved to `kubernetes-sigs` org; some links/docs may still reference `headlamp-k8s` — both resolve correctly during transition
- In-cluster mode needs a ServiceAccount with appropriate RBAC; Helm chart creates this automatically
- No persistent storage — stateless; all state is in Kubernetes API server

## Links

- GitHub: <https://github.com/kubernetes-sigs/headlamp>
- Docs: <https://headlamp.dev/docs/latest/>
- In-cluster install: <https://headlamp.dev/docs/latest/installation/in-cluster/>
- Desktop install: <https://headlamp.dev/docs/latest/installation/desktop/>
- GHCR packages: <https://github.com/orgs/headlamp-k8s/packages>
