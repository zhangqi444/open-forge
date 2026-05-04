---
name: argocd
description: Recipe for Argo CD — declarative GitOps continuous delivery for Kubernetes. CNCF graduated project.
---

# Argo CD

Declarative, GitOps-based continuous delivery tool for Kubernetes. Monitors Git repositories for changes to Kubernetes manifests (YAML, Helm charts, Kustomize, Jsonnet) and automatically syncs cluster state to match. Features a web UI, CLI, multi-cluster support, RBAC, SSO integration, and application health visualization. CNCF graduated project. Upstream: <https://github.com/argoproj/argo-cd>. Docs: <https://argo-cd.readthedocs.io/>. License: Apache-2.0. ~18K stars.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| kubectl (plain YAML) | <https://argo-cd.readthedocs.io/en/stable/getting_started/> | Yes | Quickstart and simple installs |
| Helm chart | <https://artifacthub.io/packages/helm/argo/argo-cd> | Community | Production Kubernetes installs |
| Autopilot (opinionated GitOps bootstrap) | <https://argocd-autopilot.readthedocs.io/> | Yes | Full GitOps from day 1 |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| infra | Kubernetes cluster already running? | Boolean | Required; Argo CD installs into k8s |
| infra | Namespace for Argo CD? | String (default argocd) | All |
| software | Admin password? | String | Set after first login (default is auto-generated) |
| software | SSO provider? | OIDC URL / GitHub / GitLab / LDAP | Optional |
| software | Git repository URL? | https:// or git@ | Required for applications |

## Software-layer concerns

### Install (kubectl)

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f \
  https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

Wait for all pods to be ready:
```bash
kubectl wait --for=condition=Ready pod --all -n argocd --timeout=300s
```

### Access the UI

```bash
# Port-forward (local access)
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Get initial admin password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d
```

Visit https://localhost:8080, login with `admin` + the retrieved password.

### Install Argo CD CLI

```bash
# macOS
brew install argocd

# Linux
curl -sSL -o argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
chmod +x argocd && sudo mv argocd /usr/local/bin/
```

### Deploy an application (CLI)

```bash
argocd login localhost:8080 --username admin --password <password> --insecure

argocd app create my-app \
  --repo https://github.com/myorg/my-k8s-configs.git \
  --path apps/my-app \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace my-app \
  --sync-policy automated \
  --auto-prune \
  --self-heal
```

### Application manifest (declarative)

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/myorg/my-k8s-configs.git
    targetRevision: main
    path: apps/my-app
  destination:
    server: https://kubernetes.default.svc
    namespace: my-app
  syncPolicy:
    automated:
      prune: true       # delete resources removed from git
      selfHeal: true    # revert manual changes in cluster
    syncOptions:
      - CreateNamespace=true
```

### Helm chart install (production)

```bash
helm repo add argo https://argoproj.github.io/argo-helm
helm install argocd argo/argo-cd \
  --namespace argocd \
  --create-namespace \
  -f values.yaml
```

### Expose via ingress (Nginx)

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: argocd-server-ingress
  namespace: argocd
  annotations:
    nginx.ingress.kubernetes.io/ssl-passthrough: "true"
    nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
spec:
  ingressClassName: nginx
  rules:
    - host: argocd.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: argocd-server
                port:
                  number: 443
```

## Upgrade procedure

```bash
# kubectl
kubectl apply -n argocd -f \
  https://raw.githubusercontent.com/argoproj/argo-cd/v<new-version>/manifests/install.yaml

# Helm
helm upgrade argocd argo/argo-cd --namespace argocd -f values.yaml
```

Do not skip major versions. Review the upgrade notes: <https://argo-cd.readthedocs.io/en/stable/operator-manual/upgrading/overview/>

## Gotchas

- Argo CD runs inside Kubernetes: it is not a standalone binary. You need a working Kubernetes cluster first (K3s, K8s, EKS, GKE, etc.).
- TLS passthrough: the argocd-server speaks HTTPS natively. Nginx ingress requires `ssl-passthrough` annotation. Alternatively, set `--insecure` to disable internal TLS and terminate at the ingress.
- `argocd-initial-admin-secret`: delete this secret after setting a new admin password — it's a security risk to leave it around.
- `selfHeal: true`: automatically reverts manual `kubectl apply` or `kubectl edit` changes. Useful for enforcing GitOps but surprising if you're used to ad-hoc changes.
- Multi-cluster: register additional clusters with `argocd cluster add`. Each cluster needs its own service account.
- App of Apps pattern: manage many applications declaratively by creating one Argo CD Application that points to a directory of other Application manifests.

## Links

- GitHub: <https://github.com/argoproj/argo-cd>
- Docs: <https://argo-cd.readthedocs.io/>
- Getting started: <https://argo-cd.readthedocs.io/en/stable/getting_started/>
- Helm chart: <https://artifacthub.io/packages/helm/argo/argo-cd>
- Live demo: <https://cd.apps.argoproj.io/>
