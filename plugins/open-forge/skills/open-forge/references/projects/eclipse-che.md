---
name: eclipse-che-project
description: Eclipse Che recipe for open-forge. Kubernetes-native cloud IDE and development environment platform. Upstream: https://github.com/eclipse-che/che
---

# Eclipse Che

Kubernetes-native platform for cloud development environments. Runs developer workspaces as containers in Kubernetes pods — browser-accessible IDE (VS Code, IntelliJ, etc.) with all dependencies, runtimes, and code in containers. Designed for enterprise teams that need reproducible, portable, secure development environments. Upstream: https://github.com/eclipse-che/che. Docs: https://eclipse.dev/che/docs

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Kubernetes cluster (any) | Operator (CheCluster CRD) + Helm | Primary install method via Eclipse Che Operator |
| OpenShift cluster | Operator (OperatorHub) | Red Hat-supported; operator available in OperatorHub |
| Minikube / kind | Operator + Helm | For local/dev installs; not production |

Note: Eclipse Che is Kubernetes-native and requires a Kubernetes or OpenShift cluster. It cannot be run on a plain Docker host or Docker Compose — it deploys workspaces as pods.

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | Kubernetes cluster type (K8s / OpenShift / Minikube) | Determines install method |
| preflight | Ingress domain (e.g. che.yourdomain.com) | Used as CheCluster spec.networking.domain |
| preflight | TLS strategy (cert-manager / manual cert / none) | Required for production |
| preflight | Identity provider (OpenShift OAuth / Keycloak / DEX) | Keycloak bundled by default |
| storage | Default storage class | For workspace PVCs |
| advanced | Workspace container image limits (CPU/memory) | Optional; set in CheCluster CRD |

## Software-layer concerns

### Prerequisites

- Running Kubernetes cluster (v1.19+) or OpenShift 4.x
- `kubectl` or `oc` CLI
- `helm` CLI (v3+)
- cert-manager (recommended for TLS)

### Install via chectl (CLI tool)

```bash
# Install chectl CLI
bash <(curl -sL https://www.eclipse.org/che/chectl/)

# Deploy Eclipse Che on Kubernetes
chectl server:deploy --platform=k8s --domain=che.yourdomain.com

# Deploy on OpenShift
chectl server:deploy --platform=openshift
```

chectl docs: https://eclipse.dev/che/docs/stable/administration-guide/using-the-chectl-management-tool/

### Install via Helm

```bash
# Add Che Helm repo
helm repo add eclipse-che https://eclipse-che.github.io/che-operator/pkg/deploy/helm/

# Install the operator
helm install eclipse-che eclipse-che/eclipse-che \
  --namespace eclipse-che \
  --create-namespace \
  --set networking.domain=che.yourdomain.com
```

### CheCluster custom resource

After installing the operator, create a CheCluster resource:

```yaml
apiVersion: org.eclipse.che/v2
kind: CheCluster
metadata:
  name: eclipse-che
  namespace: eclipse-che
spec:
  networking:
    domain: che.yourdomain.com
    tlsSecretName: che-tls
  components:
    cheServer:
      extraProperties: {}
```

Full CheCluster field reference: https://eclipse.dev/che/docs/stable/administration-guide/checluster-custom-resource-fields-reference/

### Data persistence

Workspace data is stored in PersistentVolumeClaims (one PVC per workspace). Configure the default storageClass in the CheCluster CR.

### Devfiles — workspace configuration

Each project defines its workspace environment via a `devfile.yaml`. Developers open a workspace directly from a Git repo URL: `https://your-che-instance/#https://github.com/org/repo`

Devfile spec: https://devfile.io/

## Upgrade procedure

```bash
# With chectl
chectl server:update

# Or update the Helm release
helm repo update eclipse-che
helm upgrade eclipse-che eclipse-che/eclipse-che --namespace eclipse-che
```

Check release notes: https://github.com/eclipse-che/che/releases

## Gotchas

- Kubernetes required — Eclipse Che cannot run on plain Docker. A Kubernetes cluster is mandatory. Minimum resource requirements are significant (4+ CPU, 8+ GB RAM for cluster + workspaces).
- TLS is required for production — browser-based IDEs need HTTPS/WSS; configure cert-manager or provide certificates.
- Identity provider needed — Che bundles Keycloak by default; on OpenShift it integrates with OpenShift OAuth. Plan IAM integration before deploying.
- Workspace startup time — workspaces take 30–90s to start as containers/pods are scheduled and images pulled.
- Resource requests — each developer workspace runs as a separate pod with CPU/memory requests; plan cluster capacity for concurrent users.
- Plugin registry — Che has its own VS Code extension registry (Open VSX) embedded; extensions from Microsoft Marketplace are not available by default.

## Links

- Upstream repo: https://github.com/eclipse-che/che
- Website: https://eclipse.dev/che/
- Documentation: https://eclipse.dev/che/docs
- Administration guide: https://eclipse.dev/che/docs/stable/administration-guide/preparing-the-installation/
- CheCluster CRD reference: https://doc.crds.dev/github.com/eclipse-che/che-operator
- chectl CLI: https://eclipse.dev/che/docs/stable/administration-guide/using-the-chectl-management-tool/
