---
name: kubernetes-runtime
description: Cross-cutting runtime module for Kubernetes deployments. Loaded whenever a project ships upstream-blessed Kubernetes manifests (Kustomize / Helm / plain YAML) and the user has (or wants) a k8s cluster. Owns kubectl + Kustomize/Helm tooling, namespace + secret hygiene, persistent storage, ingress patterns, and common gotchas. Project recipes own which manifests to apply, which env vars matter, and any project-specific onboarding flow.
---

# Kubernetes runtime

Reusable across every infra that exposes a k8s API — managed (EKS, GKE, AKS, DOKS, OKE, Linode LKE, Hetzner managed-k8s), self-hosted (k3s, kubeadm, microk8s), or local (Docker Desktop's bundled k8s, kind, minikube, OrbStack).

The project recipe specifies *what* to deploy (manifests, env vars, persistent paths); this module specifies *how* — install client tools, connect to a cluster, manage namespaces / secrets, troubleshoot the common k8s issues new self-hosts hit.

> **Don't invent.** This module is for projects whose upstream ships manifests (Kustomize bundle, Helm chart, plain YAML, or a `deploy.sh`). If a project has no upstream Kubernetes path, do **not** author one here — pick Docker / native / a vendor PaaS instead. See `CLAUDE.md` § *Don't invent — interface.*

## When this module is loaded

User answered the **how** question with anything Kubernetes-flavored:

- "EKS / GKE / AKS / DOKS / OKE / Linode LKE"
- "k3s on a VM" (BYO VPS + k3s)
- "kind / minikube / Docker Desktop's bundled k8s" (localhost)

Skipped when the runtime is bundled by a vendor blueprint, or when the chosen path is plain Docker / native.

## Client-side prerequisites

Installed on the **user's machine** (not the cluster nodes — managed clusters provision nodes themselves; self-hosted k8s installation is out of scope, see your distro's installer).

| Tool | Why | Install |
|---|---|---|
| `kubectl` | Talk to any k8s cluster | `brew install kubectl` / `sudo apt-get install -y kubectl` (after Google's apt repo) / <https://kubernetes.io/docs/tasks/tools/> |
| `kustomize` (optional, modern kubectl bundles it) | Apply Kustomize overlays | `brew install kustomize` / <https://kubectl.docs.kubernetes.io/installation/kustomize/> |
| `helm` v3 (only if the project ships a chart) | Install upstream Helm charts | `brew install helm` / <https://helm.sh/docs/intro/install/> |

`kubectl` ships with `kustomize` built-in (`kubectl apply -k <path>`), so a separate `kustomize` binary is only needed if the project's `deploy.sh` invokes `kustomize build` directly.

Verify after install:

```bash
kubectl version --client --output=yaml
helm version              # only if the project uses Helm
```

## Connect to the cluster

How `kubectl` reaches a cluster depends on where the cluster lives. Each managed provider has its own one-liner that writes a kubeconfig entry; project recipes assume that's already done.

| Cluster | Set kubeconfig |
|---|---|
| EKS | `aws eks update-kubeconfig --region <r> --name <cluster>` |
| GKE | `gcloud container clusters get-credentials <cluster> --region <r>` |
| AKS | `az aks get-credentials --resource-group <rg> --name <cluster>` |
| DOKS | `doctl kubernetes cluster kubeconfig save <cluster>` |
| k3s on a VM | `scp <user>@<host>:/etc/rancher/k3s/k3s.yaml ~/.kube/k3s.yaml && KUBECONFIG=~/.kube/k3s.yaml` (replace `127.0.0.1` in the file with the VM's public IP) |
| Docker Desktop | Enabled in Docker Desktop settings; context is `docker-desktop` |
| kind | `kind create cluster --name <name>` (auto-writes kubeconfig) |

Confirm before going further:

```bash
kubectl config current-context
kubectl cluster-info
kubectl get nodes
```

## The two install patterns

Most projects ship one of these.

### Pattern A — Kustomize (or plain manifests + a deploy script)

The project's repo contains a folder like `scripts/k8s/`, `deploy/k8s/`, or `manifests/` with:

- `kustomization.yaml` — Kustomize base
- `deployment.yaml`, `service.yaml`, `configmap.yaml`, `secret.yaml`, `pvc.yaml` — individual resources
- `deploy.sh` (optional) — wraps namespace creation, secret seeding, and `kubectl apply -k`

Generic flow (project recipe specifies the exact paths):

```bash
git clone <project-repo>
cd <project-repo>

# Most projects' deploy.sh handles namespace + secret + apply
./scripts/k8s/deploy.sh

# Or raw Kustomize:
kubectl apply -k scripts/k8s/manifests/
```

Customize by editing the manifests in your fork (or via Kustomize overlays in a separate dir that references `scripts/k8s/manifests/` as base). Re-running `deploy.sh` is idempotent.

### Pattern B — Helm chart

The project ships (or community ships) a Helm chart at a `helm repo add` URL.

```bash
helm repo add <name> <url>
helm repo update

# Inspect what'll be installed
helm show values <name>/<chart> > /tmp/<chart>-defaults.yaml

# Install
helm install "$RELEASE_NAME" "<name>/<chart>" \
  --namespace "$DEPLOYMENT_NAME" --create-namespace \
  -f my-values.yaml

# Upgrade (idempotent — works for first install too)
helm upgrade --install "$RELEASE_NAME" "<name>/<chart>" \
  --namespace "$DEPLOYMENT_NAME" --create-namespace \
  -f my-values.yaml

# Roll back / status / uninstall
helm rollback "$RELEASE_NAME" <revision> --namespace "$DEPLOYMENT_NAME"
helm status   "$RELEASE_NAME" --namespace "$DEPLOYMENT_NAME"
helm uninstall "$RELEASE_NAME" --namespace "$DEPLOYMENT_NAME"
```

Project recipes that use Helm specify the repo URL, chart name, required values, and any pre-existing Secret support.

## Namespaces, releases, secrets

Project recipes pick a namespace (often the project name itself). Keep one project per namespace.

```bash
kubectl create namespace "$NAMESPACE"
```

API keys and any other secret values go through `Secret` objects, **never** committed `values.yaml` / `kustomization.yaml`. Two patterns:

### Pattern 1 — Secret created by the project's deploy script

Most projects' `deploy.sh` reads env vars (`ANTHROPIC_API_KEY`, etc.) and creates a `Secret` from them. Convenient; keeps secrets out of repo files.

```bash
export ANTHROPIC_API_KEY="..."
./scripts/k8s/deploy.sh
```

### Pattern 2 — Pre-create the Secret, point manifests at it

Cleaner; the secret is rotatable independently of the manifest apply.

```bash
kubectl create secret generic "$NAMESPACE-keys" \
  --namespace "$NAMESPACE" \
  --from-literal=apiKey='<paste>'
```

Then the project's manifests reference the secret name (project recipe specifies which keys it looks up).

## Pod / service troubleshooting

```bash
# What's running
kubectl -n "$NAMESPACE" get pods,svc,ingress,pvc

# Why won't it start
kubectl -n "$NAMESPACE" describe pod <pod>
kubectl -n "$NAMESPACE" logs <pod>            # add -p for the previous container after a crash
kubectl -n "$NAMESPACE" logs -f <pod>          # tail

# Get a shell
kubectl -n "$NAMESPACE" exec -it <pod> -- sh

# Local probe through a port-forward
kubectl -n "$NAMESPACE" port-forward svc/<svc-name> <local-port>:<svc-port>
# Test: curl -sI http://127.0.0.1:<local-port>/healthz
```

## Reaching the service from outside

Three patterns; project recipes pick:

| Pattern | When | Notes |
|---|---|---|
| `kubectl port-forward` | Local-only access during setup | Not for production — terminates on disconnect. Many projects' default manifests assume this. |
| `Service` of type `LoadBalancer` | Simplest on managed clouds | Provider provisions a real LB and external IP. Charges apply. |
| `Ingress` + ingress controller (nginx, Traefik, AWS ALB) | Standard for cloud k8s | Cluster needs an ingress controller installed. Managed services often pre-install one. |

When a project's default manifests bind to **loopback inside the pod**, `port-forward` works but `Service`/`Ingress` won't reach it. Switching to a non-loopback bind requires both manifest and config changes — read the project recipe before changing.

For TLS via Ingress, pair with cert-manager (most charts assume this is installed):

```bash
helm repo add jetstack https://charts.jetstack.io
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager --create-namespace \
  --set crds.enabled=true
```

Then a `ClusterIssuer` for Let's Encrypt and the project's manifests reference it via annotations. See `references/modules/tls-letsencrypt.md` for the issuer YAML.

## Persistent storage

Most projects with state need a `PersistentVolumeClaim`. Manifests default to either:

- **Default StorageClass** — ✅ on managed clouds (EBS / Persistent Disk / Azure Disk / DO Block Storage). Confirm: `kubectl get sc` shows one marked `(default)`.
- **No default** — common on k3s + minikube; install `local-path-provisioner` (k3s ships it but unprovisioned), `longhorn`, or supply your own.

PVC reclaim policy matters on uninstall:

```bash
kubectl -n "$NAMESPACE" get pvc           # before uninstall
# delete release / kustomization
kubectl -n "$NAMESPACE" get pvc           # PVC may survive — depends on namespace deletion vs targeted uninstall
kubectl -n "$NAMESPACE" delete pvc <name> # explicit, only if you're sure the data should go
```

For Kustomize: deleting the namespace deletes everything in it (including PVCs unless StorageClass reclaim policy is `Retain`). For Helm: `helm uninstall` typically does **not** delete PVCs. Project recipes specify which.

## Common gotchas

- **Wrong context.** `kubectl config current-context` first, every time. Multi-cluster setups silently apply to the wrong place.
- **Default StorageClass missing.** Symptom: PVC stuck in `Pending` forever, `kubectl describe pvc` shows `no persistent volumes available for this claim and no storage class is set`. Fix: install one (`kubectl annotate sc <name> storageclass.kubernetes.io/is-default-class=true`) or set the storage class explicitly in the manifest.
- **Ingress without controller.** An Ingress object with no controller installed is a no-op. Symptom: `kubectl describe ingress` shows no Address. Install nginx-ingress / Traefik / the cloud-native one before the project, or use `LoadBalancer` Service type instead.
- **Pod binds to loopback inside the container.** Default in many self-host projects (security-by-default). `kubectl port-forward` works; `Service`/`Ingress` need a non-loopback bind change in the project's config (not just the Service spec).
- **`Recreate` deployment strategy.** Projects with single-instance state use `strategy: Recreate` so old + new can't run simultaneously. Brief downtime gap during upgrades is by design.
- **Secret values in `kubectl describe`.** They're base64, not encrypted. Anyone with `get secrets` permission sees them. Use Sealed Secrets / External Secrets / SOPS if multiple humans share the cluster.
- **Re-running `deploy.sh` overwrites Secret values?** Most upstream scripts preserve existing keys and only update what you pass via env vars — but verify per project. If unsure, snapshot the Secret first: `kubectl get secret <name> -n <ns> -o yaml > secret-backup.yaml`.
- **`helm upgrade --install` is your friend.** Idempotent — works for both first install and subsequent upgrades. Prefer it over branching on "does the release exist".
- **Local k8s is heavy.** Docker Desktop's k8s, kind, and minikube each consume 2–4 GB RAM at idle. For localhost-only deployments, plain Docker is lighter.
- **`kubectl apply -k` vs `kubectl create -k`.** Use `apply -k` — idempotent. `create -k` errors if anything already exists.

## Reference

- kubectl reference: <https://kubernetes.io/docs/reference/kubectl/>
- Kustomize: <https://kubectl.docs.kubernetes.io/references/kustomize/>
- Helm v3 docs: <https://helm.sh/docs/>
- cert-manager: <https://cert-manager.io/docs/>
