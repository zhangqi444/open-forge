---
name: Semaphore CI/CD
description: "Open-source CI/CD platform. Kubernetes + Helm (production) or Minikube (local). semaphoreio/semaphore. YAML pipelines, parallel execution, multi-cloud, Community + Enterprise editions."
---

# Semaphore CI/CD

**Open-source CI/CD platform** — blazing-fast builds & deployments, YAML-based config, parallel execution, scales from solo developers to large engineering teams. Works with containers, Kubernetes, and multi-cloud environments.

Three editions: **Community** (Apache 2.0, everything outside `ee/`), **Enterprise** (commercial, `ee/` directory), and **Cloud** (SaaS at semaphoreci.com). This recipe covers **Community Edition self-hosting**.

Built + maintained by **Semaphore / Rendered Text**. Active governance, SIGs, roadmap.

- Upstream repo: <https://github.com/semaphoreio/semaphore>
- Docs: <https://docs.semaphoreci.com/CE/getting-started/about-semaphore>
- Install guides: <https://docs.semaphore.io/CE/getting-started/>
- Cloud SaaS: <https://semaphoreci.com>
- Discord: <https://discord.com/invite/FBuUrV24NH>
- Roadmap: <https://github.com/semaphoreio/semaphore/blob/main/ROADMAP.md>

## Architecture in one minute

- **Microservices architecture** — multiple Go/Elixir services coordinated via Kubernetes
- Production deploy: **Kubernetes + Helm** (single machine or cluster)
- Local dev: **Minikube** via Skaffold (≥8 CPU, ≥16 GB RAM — not a lightweight setup)
- Installation time: **10–30 minutes** per README
- Resource: **heavy** — requires a full K8s cluster; Minikube local dev needs 8 CPUs + 16 GB RAM minimum

## Compatible install methods

| Infra                  | Runtime                                 | Notes                                                                           |
| ---------------------- | --------------------------------------- | ------------------------------------------------------------------------------- |
| **Single machine**     | Kubernetes (K3s/MicroK8s/kubeadm) + Helm | Upstream install guide for Ubuntu single-machine                               |
| **Kubernetes cluster** | Helm chart                              | Production multi-node                                                           |
| **Minikube (local)**   | Skaffold + Minikube                     | Dev/testing only; 8 CPU + 16 GB RAM; 30–60 min initial startup                 |
| **Cloud SaaS**         | semaphoreci.com                         | Managed; free plans for small projects                                          |

## Inputs to collect

| Input                     | Example                          | Phase    | Notes                                                                               |
| ------------------------- | -------------------------------- | -------- | ----------------------------------------------------------------------------------- |
| Kubernetes cluster        | single Ubuntu VM or cluster      | Infra    | See Ubuntu single-machine guide                                                     |
| Domain / wildcard cert    | `*.semaphore.example.com`        | Network  | mkcert for local; cert-manager + Let's Encrypt for production                      |
| Helm values               | `values.yaml`                    | Config   | `global.domain.ip` + TLS certs; see install guide                                  |
| Object storage (optional) | S3-compatible                    | Storage  | For artifact storage                                                                |

## Install — Ubuntu single machine

Full guide: <https://docs.semaphore.io/CE/getting-started/install-single-machine>

High-level:

```bash
# 1. Provision Ubuntu VM (≥4 CPUs, ≥8 GB RAM recommended for single-node prod)

# 2. Install K3s (or kubeadm/MicroK8s per your preference)
curl -sfL https://get.k3s.io | sh -

# 3. Add Semaphore Helm repo
helm repo add semaphore https://renderedtext.github.io/helm-charts
helm repo update

# 4. Install with Helm (follow docs for full values.yaml)
helm install semaphore semaphore/semaphore \
  --namespace semaphore --create-namespace \
  -f values.yaml

# 5. Access at configured domain
```

Installation takes ~10–30 minutes. The docs walk through each `values.yaml` field.

## Install — Kubernetes cluster

Guide: <https://docs.semaphore.io/CE/getting-started/install-kubernetes>

```bash
helm repo add semaphore https://renderedtext.github.io/helm-charts
helm install semaphore semaphore/semaphore \
  --namespace semaphore --create-namespace \
  -f values.yaml
```

## Local development (Minikube)

**Requirements: 8 CPUs, 16 GB RAM, mkcert, Minikube, kubectl, helm, Skaffold**

```bash
# TLS
mkcert -install && mkcert '*.semaphore.localhost'

# Start Minikube
minikube start --cpus 8 --memory 16384 --profile semaphore
minikube addons enable ingress
minikube tunnel   # separate terminal

# Helm repos
cd helm-chart && make helm.create && cd ..
helm repo add ambassador https://app.getambassador.io
helm repo add semaphore https://renderedtext.github.io/helm-charts

# Configure skaffold.yaml with minikube IP + mkcert certs
skaffold dev   # first run: 30–60 min
```

## First boot

1. Deploy via chosen method.
2. Access Semaphore web UI.
3. Connect your git provider (GitHub/GitLab/Bitbucket).
4. Create an organization + first project.
5. Add `.semaphore/semaphore.yml` to your repo — define pipelines.
6. Trigger a build; review logs.
7. Configure secrets (Settings → Secrets) for environment variables.
8. Set up deployment targets.

## Backup

- Kubernetes etcd (cluster state + Semaphore DB) — use your K8s backup tooling (Velero, etcd snapshots)
- Any persistent volumes (artifact storage, pipeline logs)
- Helm `values.yaml` — commit to a private repo

## Upgrade

```bash
helm repo update
helm upgrade semaphore semaphore/semaphore \
  --namespace semaphore -f values.yaml
```

Review release notes + migration guides before upgrading across major versions.

## Gotchas

- **This is not a lightweight self-hosted tool.** Semaphore is a full microservices platform. Single-machine K3s requires a real server (not a 1 GB VPS). Local dev with Minikube needs 8 CPU + 16 GB RAM. If you want lightweight self-hosted CI, look at Woodpecker CI, Gitea Actions, or Drone.
- **Community vs Enterprise editions.** Code in `ee/` is Enterprise-only (commercial license). The Community Edition (`apache2.0`) is everything outside `ee/`. Features gated in EE include advanced RBAC, audit logs, SSO, and priority support.
- **SaaS is the easy path.** semaphoreci.com has free plans for small projects; self-hosting is for teams with compliance requirements or air-gapped environments.
- **Kubernetes expertise required.** Helm values, ingress configuration, cert-manager, Minikube tunneling — this is a K8s-native platform. If your team doesn't already operate K8s, the operational overhead is significant.
- **Documentation is still evolving** per upstream README — "🚧 As we open up the project, our documentation and processes are still evolving." Expect gaps; community Discord is the support channel.
- **30–60 minute initial Skaffold startup** for local dev. This is a known, documented reality — microservices build takes time. Plan accordingly before demos.
- **Ambassador/Emissary ingress.** The local dev setup uses Emissary Ingress CRDs — not the standard nginx ingress. Production Helm values may differ; check the docs for your environment.

## Project health

Active (recently open-sourced from SaaS product), Helm chart, CI, Discord, governance/SIGs/roadmap, Go + Elixir microservices. Commercial backing from Rendered Text.

## CI/CD-family comparison

- **Semaphore CE** — K8s-native, microservices, YAML pipelines, Git provider integrations; heavy
- **Woodpecker CI** — Docker-based, lightweight, Gitea/Forgejo-native, Go
- **Gitea Actions** — GitHub Actions-compatible, built into Gitea
- **Drone CI** — Docker-based, YAML pipelines, Go; archived/stagnant
- **Jenkins** — Java, most plugins, mature, heavyweight, self-hosted
- **Concourse CI** — Go, resource-based pipelines, K8s-friendly

**Choose Semaphore CE if:** you need a full-featured enterprise-grade CI/CD platform with K8s-native deployment, have the K8s expertise to run it, and want the same platform as semaphoreci.com on-premises.

## Links

- Repo: <https://github.com/semaphoreio/semaphore>
- Docs: <https://docs.semaphoreci.com/CE/getting-started/about-semaphore>
- Single-machine install: <https://docs.semaphore.io/CE/getting-started/install-single-machine>
- Helm chart: `helm repo add semaphore https://renderedtext.github.io/helm-charts`
- Discord: <https://discord.com/invite/FBuUrV24NH>
- Woodpecker CI (lightweight alt): <https://woodpecker-ci.org>
