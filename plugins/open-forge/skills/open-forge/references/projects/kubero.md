---
name: Kubero
description: "Self-hosted PaaS on top of Kubernetes — Heroku-like DX for deploying apps from source or containers, 160+ app templates, CI/CD pipelines, review apps, add-ons (Postgres/Redis/MongoDB/etc.). Runs on any K8s cluster. Node.js operator. GPL-3.0."
---

# Kubero

Kubero (pronounced "Kube Hero") is **"Heroku/Netlify/Render DX on top of your own Kubernetes"** — a self-hosted PaaS that gives developers a web UI + CLI for deploying apps without writing Helm charts. Push to Git → Kubero builds, deploys, wires up add-ons (Postgres, Redis, MongoDB, etc.), manages review apps on PRs, exposes logs + metrics + web console from the browser. Follows **12-factor app principles**.

Built + maintained by **kubero-dev** (Swiss-led open source team). Two components: **kubero-ui** (web UI) + **Kubero Operator** (Kubernetes operator CRDs). **No external database** — everything stored in K8s etcd via Custom Resources (nice architectural choice; see Gotchas for implications).

Use cases: (a) self-host a Heroku-alternative for yourself/small team (b) give internal devs a "just deploy my branch" button without them learning Kubernetes (c) run review apps per PR automatically (d) replace a mix of Heroku + Vercel + Render with your own cluster.

Features:

- **Docker + source-code deployments** — buildpacks for source-to-container
- **App templates (160+)** — WordPress, Grafana, Bitwarden, Trilium, Uptime Kuma, etc.
- **CI/CD pipelines** — up to 4 staging environments per pipeline
- **GitOps Review Apps** — auto-build + clean-up per PR
- **Auto-redeployments** on push to branch/tag
- **Add-ons**: MySQL, Postgres (CloudNativePG, Crunchy, Percona), Redis, MongoDB, Elasticsearch, Kafka, RabbitMQ, CouchDB, Haraka mail, Minio, ClickHouse, CockroachDB, Cloudflare Tunnels
- **API + CLI** — kubero-cli for terminal workflows
- **Metrics + logs + vulnerability scans** — integrated UI
- **Notifications**: Discord, Slack, webhooks
- **Web console** — exec into running container from browser
- **Scheduled cronjobs**, **safe restarts**, **multi-tenancy**, **SSO (GitHub, OAuth2)**, **Basic Auth**

- Upstream repo: <https://github.com/kubero-dev/kubero>
- Kubero CLI: <https://github.com/kubero-dev/kubero-cli>
- Operator: <https://github.com/kubero-dev/kubero-operator>
- Homepage: <https://www.kubero.dev>
- Docs: <https://www.kubero.dev/docs/>
- Demo: <https://demo.kubero.dev>
- Discord: <https://discord.gg/tafRPMWS4r>
- Templates: <https://www.kubero.dev/templates/>
- Screenshots: <https://www.kubero.dev/docs/screenshots>

## Architecture in one minute

- **Kubernetes-native**: everything is a CRD (`Kubero Operator`)
- **Two containers**: kubero-ui + operator
- **No external DB**: state stored in etcd via CRDs
- **Requires K8s ingress controller** (Nginx, Traefik, etc.) + cert-manager for TLS
- **Resource**: operator + UI are tiny (~200MB); your apps consume the rest

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Kubernetes         | **Kubero CLI installer** (`kubero install`)                        | **Upstream-primary** — bootstraps CLI → K8s → Kubero                               |
| Kubernetes         | Helm chart (manual install)                                               | For existing cluster automation                                                            |
| K3s / MicroK8s     | Small single-node K8s for homelab                                                   | Fully supported                                                                                        |
| Managed K8s        | EKS / GKE / AKS / DigitalOcean K8s / Linode LKE                                                    | Any conformant K8s works                                                                                          |
| **NOT suitable**   | Non-K8s infra (bare Docker, Swarm, Nomad)                                                                                     | K8s-native by design                                                                                                 |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| K8s cluster          | v1.24+ with ingress controller + cert-manager                           | Prereq       | **Hard requirement**                                                                             |
| Ingress controller   | NGINX / Traefik / others                                                | Network      | Kubero creates Ingress resources                                                                          |
| cert-manager         | For automatic TLS certs                                                       | TLS          | Required for HTTPS on deployed apps                                                                          |
| Domain               | `apps.example.com` wildcard                                                          | DNS          | `*.apps.example.com` → cluster ingress IP                                                                               |
| Git provider         | GitHub / GitLab / Bitbucket / Gitea / Forgejo                                                | Source       | OAuth + webhooks for review apps                                                                                      |
| Storage class        | For persistent volumes (add-on databases, app data)                                                          | Storage      | SSD-backed strongly recommended                                                                                                      |
| Kubero admin auth    | GitHub SSO / OAuth2 / local                                                                                       | Auth         | Configure before opening to team                                                                                                                |

## Install via CLI

```sh
# 1. Download kubero-cli
curl -L https://github.com/kubero-dev/kubero-cli/releases/latest/download/kubero-cli_linux_x86_64.tar.gz | tar xz
sudo mv kubero /usr/local/bin/

# 2. Install to existing K8s cluster
kubero install

# CLI will prompt for:
# - Kubernetes context
# - Install dependencies (ingress-nginx, cert-manager)?
# - Install Kubero Operator + UI
# - Admin credentials
```

See <https://www.kubero.dev/docs/installation/> for authoritative values.

## First boot

1. Install via CLI
2. Browse to Kubero UI, login with admin
3. Create a Pipeline (logical grouping of an app's environments)
4. Connect Git repo via OAuth (GitHub/GitLab/Bitbucket/Gitea)
5. Deploy first app — use a template or point at your repo
6. Configure add-on (Postgres) if needed → wire into app env via UI
7. Enable review-app setting on the pipeline
8. Test: open a PR → Kubero creates review-app → close PR → Kubero cleans up
9. Set up notifications (Discord/Slack)
10. Configure backups for etcd + persistent volumes

## Data & config layout

- **etcd** — Kubero's state (pipelines, apps, config) as K8s CRDs
- **Persistent Volumes** — app data + add-on DB data (per storage class)
- **ConfigMaps + Secrets** — app configuration + add-on credentials
- **No Kubero-owned database** — everything is K8s-native

## Backup

```sh
# Back up K8s CRDs (Kubero state):
kubectl get pipelines.application.kubero.dev -A -o yaml > kubero-pipelines.yaml
kubectl get kuberoapps.application.kubero.dev -A -o yaml > kubero-apps.yaml

# Back up etcd itself (cluster-level; covers CRDs):
#   varies by K8s distro — K3s: sqlite backup; full K8s: etcdctl snapshot save

# Back up persistent volumes via Velero or your cloud-provider snapshot mechanism
```

Add-on DB backups: use each add-on's native backup (CloudNativePG scheduled backups, etc.).

## Upgrade

1. Releases: <https://github.com/kubero-dev/kubero/releases>. Active.
2. CLI install handles operator + UI upgrades: `kubero upgrade`.
3. **K8s version skew** — keep Kubero versions aligned with supported K8s versions (read release notes).
4. **Bitnami add-ons are deprecated** (per upstream) due to Broadcom removing the Bitnami image repository. Migrate to groundhog2k/CloudNativePG/Crunchy/Percona alternatives. See <https://github.com/bitnami/charts/issues/35164>.
5. Back up before major version bumps.

## Gotchas

- **Kubernetes is a HARD prerequisite.** Kubero is not a "let me give you K8s easily" — it assumes you have a running cluster. If you don't have K8s experience, the PaaS UX won't save you when the cluster itself has issues (etcd corruption, node failures, storage class bugs). Match your team's operational capacity.
- **etcd-as-database is elegant but has limits.** Kubero stores all state as K8s CRDs → no separate DB to back up. But: etcd is sensitive (defaults to 2GB max; fsync-heavy; kapacity for many small writes). Large-scale Kubero deployments (100+ apps) may strain etcd. Monitor etcd health.
- **Bitnami deprecation is IMPORTANT.** Broadcom (VMware) removed the Bitnami image repository in 2024-2025. Any Kubero deployment using Bitnami-backed add-ons (old default) will break image pulls. Migrate to groundhog2k/CloudNativePG/Crunchy/Percona alternatives NOW. Upstream has flagged this; don't ignore.
- **App templates = one-click convenience = supply-chain responsibility.** 160+ templates let you deploy WordPress / Bitwarden / Grafana in one click. But: pin template versions + review before deploying to production. Template updates can introduce breaking changes; template images can be compromised upstream (supply-chain).
- **Review apps = cost explosion risk.** Each PR spawns an ephemeral environment with compute + DB. Very active repos = many concurrent environments. Budget + resource limits + aggressive cleanup thresholds are essential. Set `PR_CLOSED_TTL` short.
- **Haraka mail add-on** — bundled for sending transactional email from apps. Useful but: self-hosted SMTP + deliverability are hard (see AnonAddy batch 79). For production transactional email, prefer a commercial SMTP relay over self-hosted.
- **GitHub/GitLab OAuth scope caution** — Kubero requests repo access + webhook rights. For enterprise GitHub, use a dedicated "machine user" account or GitHub App with scoped permissions.
- **Multi-tenancy is "supported"** but do audit before giving untrusted users tenant access — PaaS surface area is broad; tenant escape via misconfigured ClusterRoles is the classic K8s failure mode. Review RBAC.
- **Web console exposes shell into running pods** — same hub-of-credentials concern as Nexterm (batch 81). Enforce 2FA + short-lived SSO tokens.
- **Vulnerability scans** scan running apps for CVEs — great feature. Pair with notification delivery so you actually see alerts.
- **12-factor compliance** is a philosophy — Kubero nudges you toward stateless apps + config-via-env + disposable pods. Apps that violate 12-factor (writing to container filesystem, in-process caching, etc.) will have deployment surprises.
- **SSO options (GitHub + OAuth2)** — fine for small teams. For larger orgs, consider Keycloak/Authentik in front.
- **Heroku buildpacks** — source-to-container via buildpacks. Works but can be slower + more opaque than plain Dockerfile deploys. Dockerfile route is the less-surprising path.
- **Alternatives to K8s-native PaaS with different tradeoffs:**
  - **Dokku** — single-VM PaaS; Docker-based; Heroku-like; NOT K8s-dependent; much simpler if you don't need K8s
  - **Coolify** — single-VM or multi-node; Docker-based; modern UI; growing community
  - **CapRover** — single-VM PaaS on Docker Swarm
  - **Porter** — K8s PaaS (commercial + OSS core)
  - **Cloud Foundry** — enterprise PaaS; heavy
  - **Deis / Flynn / Tsuru** — older PaaS options
  - **Choose Kubero if:** you already use K8s or plan to; want Heroku-DX for your team; comfortable operating K8s.
  - **Choose Dokku/Coolify/CapRover if:** you don't need K8s + want simpler ops.
- **License**: **GPL-3.0**.
- **Project health**: kubero-dev team + Discord community + active releases. Growing. Not commercially-backed at enterprise scale — smaller than Coolify in commercial scope.

## Links

- Repo: <https://github.com/kubero-dev/kubero>
- CLI: <https://github.com/kubero-dev/kubero-cli>
- Operator: <https://github.com/kubero-dev/kubero-operator>
- Docs: <https://www.kubero.dev/docs/>
- Homepage: <https://www.kubero.dev>
- Demo: <https://demo.kubero.dev>
- Discord: <https://discord.gg/tafRPMWS4r>
- Templates: <https://www.kubero.dev/templates/>
- Releases: <https://github.com/kubero-dev/kubero/releases>
- Bitnami EOL issue: <https://github.com/bitnami/charts/issues/35164>
- Dokku (alt): <https://dokku.com>
- Coolify (alt): <https://coolify.io>
- CapRover (alt): <https://caprover.com>
- Porter (alt): <https://porter.run>
