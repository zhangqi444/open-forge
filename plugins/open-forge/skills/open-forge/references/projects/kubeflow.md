---
name: kubeflow
description: Kubeflow recipe for open-forge. Covers the official Kubeflow AI reference platform deployment via Kustomize manifests (kubeflow/manifests), plus individual component installation (Pipelines, KServe, Katib, Trainer, Notebooks, Model Registry). Install targets include Kind (local dev/CI), Minikube, Rancher, EKS, AKS, and GKE. Sourced from https://github.com/kubeflow/manifests and https://www.kubeflow.org/docs/started/installing-kubeflow/.
---

# Kubeflow

Kubernetes-native AI platform covering the full ML lifecycle: notebooks, pipelines, distributed training, hyperparameter tuning, model serving, and a model registry. Upstream: <https://github.com/kubeflow/kubeflow>. Manifests repo: <https://github.com/kubeflow/manifests>. Docs: <https://www.kubeflow.org/docs/>.

Kubeflow is **modular**: components (Pipelines, Trainer, KServe, Katib, Notebooks, Model Registry) can be deployed independently or as a unified **Kubeflow AI Reference Platform** via the manifests repo. The unified platform bundles Istio, Knative, Cert Manager, Dex, and OAuth2-Proxy as common services.

> **Note:** The full platform requires significant resources — ~4.4 CPU cores and ~12 GB RAM at minimum; 8+ cores and 16+ GB RAM recommended. For lighter ML workloads consider deploying individual components only.

## Compatible install methods

| Method | Upstream | When to use |
|---|---|---|
| Kustomize (all-in-one) | <https://github.com/kubeflow/manifests#install-with-a-single-command> | Full platform on any Kubernetes cluster |
| Kustomize (per-component) | <https://github.com/kubeflow/manifests#install-individual-components> | Select components only; smaller footprint |
| Kind (local dev) | <https://github.com/kubeflow/manifests#create-kind-cluster> | Local dev/CI using provided Kind setup script |
| Packaged distributions | <https://www.kubeflow.org/docs/started/installing-kubeflow/#packaged-distributions> | Managed/opinionated installs (Charmed Kubeflow, AWS ROSA, etc.) |

## Kubeflow components

| Component | Purpose | Image / chart |
|---|---|---|
| Kubeflow Pipelines | DAG-based ML pipelines with SDK | ghcr.io/kubeflow/pipelines/ images |
| KServe | Model serving (Triton, TorchServe, MLServer, ONNX) | kserve/kserve-controller |
| Katib | Hyperparameter tuning / NAS | docker.io/kubeflow/katib-controller |
| Kubeflow Trainer | Distributed training (PyTorch, TF, MPI, JAX) | docker.io/kubeflow/training-operator |
| Kubeflow Notebooks | JupyterLab / VS Code in-cluster notebooks | docker.io/kubeflow/notebook-controller |
| Model Registry | ML model versioning and metadata store | docker.io/kubeflow/model-registry |
| Central Dashboard | Unified web UI | docker.io/kubeflow/centraldashboard |
| Spark Operator | Run Apache Spark jobs on Kubernetes | ghcr.io/kubeflow/spark-operator |

Common services bundled with the full platform:

| Service | Purpose |
|---|---|
| Istio | Service mesh, mTLS, traffic management |
| Knative Serving + Eventing | Serverless model serving (required by KServe) |
| Cert Manager | TLS certificate provisioning |
| Dex | OIDC identity provider |
| OAuth2-Proxy | Authentication gateway for the dashboard |

## Prerequisites

- Kubernetes cluster (tested: Kind, Minikube, Rancher, EKS, AKS, GKE)
- kubectl and kustomize installed
- For the full platform: 16 GB RAM, 8 CPU cores recommended
- Linux kernel tuning for many pods (run on host before creating Kind cluster):

```sh
sudo sysctl fs.inotify.max_user_instances=2280
sudo sysctl fs.inotify.max_user_watches=1255360
```

## Inputs to collect

| Phase | Prompt | Applicability |
|---|---|---|
| preflight | "Deploy full platform or individual components?" | Drives which kustomization to apply |
| preflight | "Target cluster type: Kind / Minikube / EKS / AKS / GKE / other?" | Determines if node/kernel tuning is needed |
| auth | "Change the default admin password?" (default: 12341234, email: user@example.com) | All installs — required for production |
| storage | "Default StorageClass available?" | Katib needs 10 GB PVC; Pipelines 35 GB; Model Registry 20 GB |
| tls | "Expose dashboard externally with TLS?" | Optional — by default dashboard accessed via kubectl port-forward |

## Software-layer concerns

### Config paths

```
kubeflow/manifests/
├── applications/      # Kubeflow components (maintained by respective WGs)
├── common/            # Istio, Knative, Cert Manager, Dex, OAuth2-Proxy
├── experimental/      # Third-party integrations, Helm charts
└── example/           # Single-command kustomization entrypoint
```

### Key config locations

| Location | Key setting |
|---|---|
| common/dex/base/config-map.yaml | Default user email + bcrypt password hash |
| common/oauth2-proxy/base/ | Session cookie secret |
| applications/pipeline/upstream/ | Pipelines object store (MinIO by default) |
| applications/kserve/kserve/ | KServe inference service defaults |

### Default credentials (MUST change for production)

- Email: user@example.com
- Password: 12341234

To change password, generate a bcrypt hash and update the Dex ConfigMap:

```sh
# Generate new bcrypt hash (requires python3 with bcrypt, or use htpasswd)
htpasswd -bnBC 10 "" NEW_PASSWORD | tr -d ':\n'
# Update common/dex/base/config-map.yaml -> staticPasswords[0].hash
```

### Persistent volume requirements

| Component | PVC size |
|---|---|
| Katib | 10 GB |
| Kubeflow Pipelines | 35 GB |
| Model Registry | 20 GB |
| KServe | 0 GB (model storage via object store) |

## Installation (full platform via Kind)

```sh
# 1. Clone manifests
git clone https://github.com/kubeflow/manifests.git
cd manifests

# 2. Create Kind cluster + install kustomize/kubectl
./tests/install_KinD_create_KinD_cluster_install_kustomize.sh

# 3. Export kubeconfig
kind get kubeconfig --name kubeflow > /tmp/kubeflow-config
export KUBECONFIG=/tmp/kubeflow-config

# 4. Apply all components (retry loop handles CRD timing -- expected to fail on first pass)
while ! kustomize build example | kubectl apply -f -; do
  echo "Retrying in 20s..."; sleep 20
done

# 5. Wait for all pods to be ready (10-20 min on first install)
kubectl wait --for=condition=Ready pods --all --all-namespaces --timeout=600s

# 6. Access dashboard
kubectl port-forward svc/istio-ingressgateway -n istio-system 8080:80
# Open http://localhost:8080 -> login user@example.com / 12341234
```

## Installation (individual components)

Example — Kubeflow Pipelines only:

```sh
# Install Cert Manager first
kustomize build common/cert-manager/cert-manager/overlays/self-signed | kubectl apply -f -

# Install Pipelines
kustomize build applications/pipeline/upstream/env/platform-agnostic-multi-user | kubectl apply -f -
```

See upstream README for exact kustomize paths per component:
https://github.com/kubeflow/manifests#install-individual-components

## Upgrade procedure

Kubeflow releases approximately twice per year (aligned to KubeCon EU and NA). Each WG provides patch releases for 6 months post-release.

```sh
# Pull updated manifests
git pull origin master   # or: git checkout <new-release-tag>

# Re-apply in-place
while ! kustomize build example | kubectl apply -f -; do
  echo "Retrying..."; sleep 20
done
```

> **Warning:** Components marked alpha/beta may include breaking changes in patch releases. Pin to a stable release tag for production: https://github.com/kubeflow/manifests/releases

## Accessing the dashboard

By default the Central Dashboard is only accessible via kubectl port-forward. For external access:

- Point an Ingress or LoadBalancer at istio-ingressgateway (namespace: istio-system)
- Configure Dex with your OIDC provider for SSO
- Terminate TLS at the ingress or via the bundled Cert Manager

## Gotchas

- **kubectl apply fails on first run** — CRDs must exist before CRs can be created. Use the retry loop; this is documented expected behavior, not an error.
- **ARM64 not fully supported** — some component images lack linux/arm64 builds. Track issue: kubeflow/manifests#2745.
- **inotify limits on host** — must increase fs.inotify.max_user_instances and max_user_watches before creating the Kind cluster; Kind containers inherit host kernel limits.
- **Change the default password** — user@example.com / 12341234 must be changed before any network exposure.
- **Knative required by KServe** — even when deploying KServe standalone, Knative Serving must be installed first.
- **Namespace isolation** — Kubeflow uses per-user namespaces managed by the Profile Controller; users only see resources in their own namespace via the dashboard.
- **Docker Hub rate limits** — some images pull from Docker Hub; pre-create an imagePullSecret named regcred if hitting pull limits in CI/CD.
- **Resource headroom** — total idle resource usage is ~4.4 CPU cores / 12.3 GB RAM; ensure nodes have headroom or exclude unused components in example/kustomization.yaml.
- **Single MinIO compactor** — do not run multiple MinIO compactor instances without configuring distributed mode; risk of data corruption.

## Links

- Upstream manifests README: https://github.com/kubeflow/manifests
- Official install docs: https://www.kubeflow.org/docs/started/installing-kubeflow/
- Component docs: https://www.kubeflow.org/docs/components/
- Kubeflow Pipelines: https://github.com/kubeflow/pipelines
- KServe: https://github.com/kserve/kserve
- Release notes: https://github.com/kubeflow/manifests/releases
- Community / Slack (#kubeflow-platform on CNCF Slack): https://www.kubeflow.org/docs/about/community/
