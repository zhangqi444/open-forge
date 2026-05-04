---
name: flux
description: Recipe for Flux (Flux CD v2) — GitOps continuous delivery toolkit for Kubernetes. CNCF graduated project.
---

# Flux (Flux CD v2)

GitOps continuous delivery toolkit for Kubernetes. Keeps clusters in sync with Git repositories and OCI artifact sources. Built entirely from Kubernetes CRDs and controllers — no separate server process. Supports Helm releases, Kustomize overlays, Git and OCI sources, image automation, and multi-tenancy. CNCF graduated project. Upstream: <https://github.com/fluxcd/flux2>. Docs: <https://fluxcd.io/flux/>. License: Apache-2.0. ~14K stars.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Flux CLI bootstrap | <https://fluxcd.io/flux/installation/> | Yes | Recommended; bootstraps Flux into cluster and a Git repo |
| Helm chart | <https://artifacthub.io/packages/helm/fluxcd-community/flux2> | Community | Helm-managed install (no Git bootstrap) |
| kubectl (plain YAML) | <https://github.com/fluxcd/flux2/releases> | Yes | Air-gapped or manual installs |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| infra | Kubernetes cluster running? | Boolean | Required |
| infra | Git provider? | github / gitlab / gitea / bitbucket | Required for bootstrap |
| software | GitHub/GitLab token? | PAT with repo read/write | Required for bootstrap |
| software | Repository to use as GitOps source? | owner/repo | Required |
| software | Target namespace? | String (default flux-system) | All |

## Software-layer concerns

### Install Flux CLI

```bash
# macOS / Linux
curl -s https://fluxcd.io/install.sh | sudo bash

# Homebrew
brew install fluxcd/tap/flux

# Verify
flux check --pre
```

### Bootstrap (GitHub)

```bash
export GITHUB_TOKEN=ghp_yourtoken

flux bootstrap github \
  --owner=myorg \
  --repository=my-k8s-fleet \
  --branch=main \
  --path=./clusters/production \
  --personal   # omit for org repos
```

Bootstrap:
1. Creates the repo if it doesn't exist
2. Installs Flux controllers into the cluster (namespace: `flux-system`)
3. Commits Flux manifests to the repo
4. Flux reconciles itself from that repo going forward

### Bootstrap (GitLab)

```bash
export GITLAB_TOKEN=glpat_yourtoken

flux bootstrap gitlab \
  --owner=mygroup \
  --repository=my-k8s-fleet \
  --branch=main \
  --path=./clusters/production
```

### Bootstrap (Gitea)

```bash
flux bootstrap gitea \
  --hostname=gitea.example.com \
  --owner=myorg \
  --repository=my-k8s-fleet \
  --path=./clusters/production
```

### Core CRDs / components

| Controller | Purpose |
|---|---|
| source-controller | Fetches artifacts from Git, Helm, OCI repos, S3 buckets |
| kustomize-controller | Applies Kustomize/plain YAML from artifacts |
| helm-controller | Manages HelmRelease resources |
| notification-controller | Sends alerts and receives webhooks |
| image-reflector-controller | Scans container registries for new image tags |
| image-automation-controller | Updates Git with new image tags |

### Deploy an app (GitRepository + Kustomization)

```yaml
# clusters/production/my-app.yaml
---
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
  name: my-app
  namespace: flux-system
spec:
  interval: 1m
  url: https://github.com/myorg/my-app-configs
  ref:
    branch: main
---
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: my-app
  namespace: flux-system
spec:
  interval: 10m
  path: ./deploy
  prune: true
  sourceRef:
    kind: GitRepository
    name: my-app
  targetNamespace: my-app
```

### Deploy a Helm release

```yaml
---
apiVersion: source.toolkit.fluxcd.io/v1
kind: HelmRepository
metadata:
  name: grafana
  namespace: flux-system
spec:
  interval: 1h
  url: https://grafana.github.io/helm-charts
---
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: grafana
  namespace: monitoring
spec:
  interval: 1h
  chart:
    spec:
      chart: grafana
      version: ">=7.0.0"
      sourceRef:
        kind: HelmRepository
        name: grafana
        namespace: flux-system
  values:
    adminPassword: secretpassword
```

## Upgrade procedure

```bash
flux install --version=v2.x.y

# Or re-bootstrap to update
flux bootstrap github --owner=myorg --repository=my-k8s-fleet ...
```

Review the upgrade guide: <https://fluxcd.io/flux/installation/upgrade/>

## Gotchas

- Flux is not a standalone server: it runs as controllers inside Kubernetes. No external deployment needed — just a running cluster.
- Bootstrap creates a deploy key: Flux generates an SSH deploy key and adds it to the Git repository. The key needs write access so Flux can commit image automation updates.
- `prune: true`: enables garbage collection — resources removed from Git are deleted from the cluster. Powerful but can cause surprises; understand before enabling in production.
- Reconciliation loops: Flux polls sources at `interval`. Reduce interval for faster deploys; increase it to reduce API load.
- Secrets management: Flux recommends SOPS (with age or GPG) for encrypting secrets in Git. See <https://fluxcd.io/flux/guides/mozilla-sops/>.
- Flux vs Argo CD: Flux is pull-based and Kubernetes-native (CRDs only, no UI); Argo CD has a full web UI and supports push-based sync. Both are excellent — choice depends on preference.

## Links

- GitHub: <https://github.com/fluxcd/flux2>
- Docs: <https://fluxcd.io/flux/>
- Installation: <https://fluxcd.io/flux/installation/>
- Get started guide: <https://fluxcd.io/flux/get-started/>
- SOPS secrets guide: <https://fluxcd.io/flux/guides/mozilla-sops/>
