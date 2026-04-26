---
name: kubernetes-runtime
description: Cross-cutting runtime module for Kubernetes deployments. Loaded whenever a project ships an upstream-blessed Helm chart or Kustomize bundle and the user has (or wants) a k8s cluster. Owns kubectl + Helm install / lifecycle / values handling / namespace + secret hygiene. Project recipes own which chart to use, which values matter, and any project-specific pairing/onboarding flow.
---

# Kubernetes runtime

Reusable across every infra that exposes a k8s API — managed (EKS, GKE, AKS, DOKS, OKE, Linode LKE, Hetzner managed-k8s), self-hosted (k3s, kubeadm, microk8s), or local (Docker Desktop's bundled k8s, kind, minikube, OrbStack).

The project recipe specifies *what* to deploy (chart name, repo URL, the values that matter); this module specifies *how* — install client tools, manage namespaces / secrets / releases, troubleshoot the common k8s issues new self-hosts hit.

> **Don't invent.** This module is for projects whose upstream ships a chart or manifests. If a project has no upstream chart, do **not** author one here — pick Docker or native instead. See `CLAUDE.md` § *Don't invent — interface.*

## When this module is loaded

User answered the **how** question with anything Kubernetes-flavored:

- "EKS / GKE / AKS / DOKS"
- "k3s on a VM" (BYO VPS + k3s)
- "Docker Desktop with Kubernetes enabled" (localhost)

Skipped when the runtime is bundled by a vendor blueprint (the blueprint's k8s wrapper handles itself), or when the chosen path is plain Docker / native.

## Client-side prerequisites

Installed on the **user's machine** (not the cluster nodes — managed clusters provision nodes themselves; self-hosted runtimes are out of this module's scope, see your cluster installer).

| Tool | Why | Install |
|---|---|---|
| `kubectl` | Talk to any k8s cluster | `brew install kubectl` / `sudo apt-get install -y kubectl` (after Google's apt repo) / <https://kubernetes.io/docs/tasks/tools/> |
| `helm` v3 | Install the project's chart | `brew install helm` / <https://helm.sh/docs/intro/install/> |
| `kubectx` / `kubens` (optional) | Switch context + namespace quickly | `brew install kubectx` |

Verify after install:

```bash
kubectl version --client --output=yaml
helm version
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

Confirm before going further:

```bash
kubectl config current-context
kubectl cluster-info
kubectl get nodes
```

## Namespaces, releases, secrets

Project recipes pick a namespace (default: the deployment name). Keep one project per namespace.

```bash
kubectl create namespace "$DEPLOYMENT_NAME"
```

API keys and any other secret values go through `Secret` objects, **never** committed `values.yaml`. Two patterns:

### Pattern 1 — let the chart create the secret from --set / values

Most charts have `existingSecret` and inline-value paths. Inline is convenient but the value ends up in the Helm release manifest (stored in-cluster). Acceptable for hobby; not for shared clusters.

```bash
helm install "$RELEASE_NAME" "$CHART" \
  --namespace "$DEPLOYMENT_NAME" \
  --set someApiKey="<paste>" \
  --create-namespace
```

### Pattern 2 — pre-create the Secret, point the chart at it

Cleaner; the secret is rotatable independently of the chart release.

```bash
kubectl create secret generic "$DEPLOYMENT_NAME-keys" \
  --namespace "$DEPLOYMENT_NAME" \
  --from-literal=apiKey='<paste>'

helm install "$RELEASE_NAME" "$CHART" \
  --namespace "$DEPLOYMENT_NAME" \
  --set existingSecret="$DEPLOYMENT_NAME-keys"
```

Project recipes specify which keys the chart looks up.

## Helm lifecycle

```bash
# Add the upstream repo + refresh
helm repo add <name> <url>
helm repo update

# Inspect what'll be installed
helm show values <name>/<chart> > /tmp/<chart>-defaults.yaml
helm template "$RELEASE_NAME" "<name>/<chart>" --namespace "$DEPLOYMENT_NAME" -f my-values.yaml | kubectl diff -f -

# Install
helm install "$RELEASE_NAME" "<name>/<chart>" \
  --namespace "$DEPLOYMENT_NAME" --create-namespace \
  -f my-values.yaml

# Upgrade
helm upgrade "$RELEASE_NAME" "<name>/<chart>" \
  --namespace "$DEPLOYMENT_NAME" \
  -f my-values.yaml

# Roll back
helm rollback "$RELEASE_NAME" <revision> --namespace "$DEPLOYMENT_NAME"

# Status / history
helm status   "$RELEASE_NAME" --namespace "$DEPLOYMENT_NAME"
helm history  "$RELEASE_NAME" --namespace "$DEPLOYMENT_NAME"

# Uninstall (PVCs may persist — see Gotchas)
helm uninstall "$RELEASE_NAME" --namespace "$DEPLOYMENT_NAME"
```

## Pod / service troubleshooting

```bash
# What's running
kubectl -n "$DEPLOYMENT_NAME" get pods,svc,ingress,pvc

# Why won't it start
kubectl -n "$DEPLOYMENT_NAME" describe pod <pod>
kubectl -n "$DEPLOYMENT_NAME" logs <pod>            # add -p for the previous container after a crash
kubectl -n "$DEPLOYMENT_NAME" logs -f <pod>          # tail

# Get a shell
kubectl -n "$DEPLOYMENT_NAME" exec -it <pod> -- sh

# Local probe through a port-forward
kubectl -n "$DEPLOYMENT_NAME" port-forward svc/<svc-name> <local-port>:<svc-port>
# Test: curl -sI http://127.0.0.1:<local-port>/healthz
```

## Reaching the service from outside

Three patterns; project recipes pick:

| Pattern | When | Notes |
|---|---|---|
| `Ingress` + ingress controller (nginx, Traefik, AWS ALB) | Standard for cloud k8s | Cluster needs an ingress controller installed. Managed services often pre-install one. |
| `Service` of type `LoadBalancer` | Simplest on managed clouds | Provider provisions a real LB and external IP. Charges apply. |
| `port-forward` | Local-only access during setup | Not for production — terminates on disconnect. |

For TLS via Ingress, pair with cert-manager (most charts assume this is installed):

```bash
helm repo add jetstack https://charts.jetstack.io
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager --create-namespace \
  --set crds.enabled=true
```

Then a `ClusterIssuer` for Let's Encrypt and the project's chart references it via annotations. See `references/modules/tls-letsencrypt.md` for the issuer YAML.

## Persistent storage

Most projects with state (databases, file storage) need a `PersistentVolumeClaim`. Charts default to either:

- **Default StorageClass** — ✅ on managed clouds (EBS / Persistent Disk / Azure Disk / DO Block Storage). Confirm: `kubectl get sc` shows one marked `(default)`.
- **No default** — common on k3s + minikube; install `local-path-provisioner` (k3s ships it but unprovisioned), `longhorn`, or supply your own.

PVC reclaim policy matters on uninstall:

```bash
kubectl -n "$DEPLOYMENT_NAME" get pvc           # before uninstall
helm uninstall "$RELEASE_NAME" --namespace "$DEPLOYMENT_NAME"
kubectl -n "$DEPLOYMENT_NAME" get pvc           # PVCs usually survive — Helm does not delete them
kubectl -n "$DEPLOYMENT_NAME" delete pvc <name> # explicit, only if you're sure the data should go
```

This is intentional in Helm — it protects against accidental data loss. Reinstalling the same release in the same namespace re-binds to the surviving PVC.

## Common gotchas

- **Wrong context.** `kubectl config current-context` first, every time. Multi-cluster setups silently apply to the wrong place.
- **Default StorageClass missing.** Symptom: PVC stuck in `Pending` forever, `kubectl describe pvc` shows `no persistent volumes available for this claim and no storage class is set`. Fix: install one (`kubectl annotate sc <name> storageclass.kubernetes.io/is-default-class=true`) or set `persistence.storageClass` in values.
- **Ingress without controller.** An Ingress object with no controller installed is a no-op. Symptom: `kubectl describe ingress` shows no Address. Install nginx-ingress / Traefik / the cloud-native one before the chart, or use `LoadBalancer` Service type instead.
- **`helm uninstall` leaves PVCs (and Secrets created outside the chart).** Plan for cleanup; document in the project recipe.
- **`Recreate` deployment strategy.** Some charts (single-instance apps that hold local state) set `strategy: Recreate` so old + new can't run simultaneously. During upgrades there's a brief downtime gap. Don't switch to `RollingUpdate` without checking the chart README.
- **Chart version vs app version.** `helm install --version 1.2.3` pins the **chart** version, not the app's container tag. Pin both: chart version via `--version`, app version via `image.tag` in values.
- **Resource requests / limits.** Charts often default to "small" or unset. On a tight cluster (3-node k3s, 2-node DOKS), unset limits can starve other workloads. Set explicitly during first install.
- **Secret values in `kubectl describe`.** They're base64, not encrypted. Anyone with `get secrets` permission sees them. Use Sealed Secrets / External Secrets / SOPS if multiple humans share the cluster.
- **`helm upgrade --install` is your friend.** Idempotent — works for both first install and subsequent upgrades. Prefer it over branching on "does the release exist".
- **Local k8s is heavy.** Docker Desktop's k8s, kind, and minikube each consume 2–4 GB RAM at idle. For localhost openclaw / ghost, plain Docker is lighter.

## Reference

- kubectl reference: <https://kubernetes.io/docs/reference/kubectl/>
- Helm v3 docs: <https://helm.sh/docs/>
- cert-manager: <https://cert-manager.io/docs/>
- Kustomize (alternative to Helm for projects shipping plain manifests): <https://kustomize.io/>
