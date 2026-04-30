---
name: Canine
description: "Self-hosted Kubernetes deployment platform. Heroku-like PaaS on your own cluster. Git-push deployments + build-in-image-builder + SSL + SSO + multi-tenancy. Apache-2.0. Active; Artifact Hub listed; CanineHQ org."
---

# Canine

Canine is **"Heroku / Render / Railway / Coolify — but on your own Kubernetes cluster"** — a self-hosted Kubernetes deployment platform bringing PaaS simplicity to any K8s infrastructure. Clean web UI for deploying, scaling, managing applications without writing YAML. **Git-driven deployments** from GitHub/GitLab webhooks → automatic Docker builds → K8s deployment. Web services + background workers + cron jobs + SSL + custom-domains + secrets + persistent-volumes + **SAML/OIDC/LDAP enterprise SSO** + multi-tenancy with team RBAC.

Built + maintained by **CanineHQ organization**. License: **Apache-2.0**. Active; CI on GitHub Actions; Artifact Hub listing; Docker Compose install; docs at canine.sh; demo.

Use cases: (a) **Heroku refugee on K8s** — Heroku pricing or features aren't fit; run own K8s (b) **PaaS-layer on enterprise K8s** — give devs a UX on corporate-K8s without kubectl (c) **multi-team shared cluster** — Canine's multi-tenancy + RBAC isolate teams (d) **replace Coolify / Dokploy / CapRover** — if you outgrow Docker-only PaaS (e) **on-prem PaaS** — gov / regulated industry needing own-metal (f) **GitOps-lite** — git-push → deploy without Flux/ArgoCD YAML (g) **built-in-image-builder** — buildpacks or Dockerfile; no CI pipeline (h) **enterprise-SSO** — SAML/OIDC gate access.

Features (per README):

- **Automated deployments** — Git webhook integration (GitHub/GitLab)
- **Built-in image building** — Dockerfile or buildpacks
- **Service management** — web + workers + cron
- **Resource constraints** — CPU/memory/GPU limits
- **Domain + SSL** — custom domain + automatic SSL (Let's Encrypt via K8s)
- **Secrets + Config** — K8s secrets-backed env vars
- **Persistent Storage** — volume management
- **Multi-tenancy** — account-based isolation + team RBAC
- **Custom Pod Templates** — YAML escape-hatch
- **Enterprise SSO** — SAML / OIDC / LDAP

- Upstream repo: <https://github.com/CanineHQ/canine>
- Website: <https://canine.sh>
- Docs: <https://docs.canine.sh>
- Artifact Hub: <https://artifacthub.io/packages/search?repo=canine>

## Architecture in one minute

- **Rails** (Ruby) — backend
- **React/Hotwire** — frontend
- **PostgreSQL** — metadata
- **Redis** — jobs/cache
- **K8s cluster** — target for deployments
- **Docker BuildKit** — image building
- **Resource**: moderate — 1-2GB RAM for Canine itself; K8s cluster separate

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker Compose** | **Upstream one-liner `curl | bash`**                            | **Primary**                                                                        |
| **K8s (self)**     | Artifact Hub Helm chart (typical)                               | **Install Canine on the cluster it manages OR a separate one**                                                                        |
| Source             | Rails typical                                                                    | Dev                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `canine.example.com`                                        | URL          | TLS MANDATORY                                                                                    |
| `SECRET_KEY_BASE`    | 128-hex                                                     | **CRITICAL** | **IMMUTABLE** (Rails; signs sessions + encrypts)                                                                                    |
| DB                   | PostgreSQL                                                  | DB           |                                                                                    |
| Redis                | Cache + jobs                                                | Queue        |                                                                                    |
| **K8s kubeconfig**   | Credentials for target clusters                             | **CRITICAL** | **HIGHEST SENSITIVITY — cluster root**                                                                                    |
| **Container registry creds** | Docker Hub / GHCR / GCR                                                                                 | Registry     | Canine pushes built images                                                                                    |
| **GitHub App / GitLab OAuth** | Webhook + source access                                                                                                | Auth         |                                                                                                                                            |
| SSO (optional)       | SAML IdP / OIDC provider / LDAP server                                                                                                                        | Auth         |                                                                                                                                            |
| Admin creds          | First-boot                                                                                                            | Bootstrap    | Strong                                                                                                            |
| Docker Engine        | 24.0.0+                                                                                                            | Infra        |                                                                                                                                            |
| Docker Compose       | 2.0.0+                                                                                                            | Infra        |                                                                                                                                            |

## Install via Docker Compose (upstream path)

```sh
curl -sSL https://canine.sh/install.sh | bash
# Or manual:
git clone https://github.com/CanineHQ/canine.git
cd canine
echo "SECRET_KEY_BASE=$(openssl rand -hex 64)" > .env
docker compose up -d
# Default: http://localhost:3000
# Custom port:
PORT=3456 docker compose up -d
```

## First boot

1. Deploy Canine
2. Browse `:3000` → create admin account
3. Connect Canine to a K8s cluster (upload kubeconfig OR in-cluster ServiceAccount)
4. Connect GitHub/GitLab (OAuth app)
5. Create project → connect repo → configure build (Dockerfile or buildpack)
6. Push → Canine builds image → deploys to K8s
7. Configure custom domain + SSL
8. Configure SSO (optional; SAML/OIDC/LDAP)
9. Create team + invite members + assign RBAC
10. Put Canine itself behind TLS reverse proxy

## Data & config layout

- Docker compose managed: Canine app + Postgres + Redis
- K8s cluster separate; Canine holds **kubeconfig as the crown-jewel credential**
- Built images stored in configured container registry
- Persistent volumes = K8s PVCs (cluster-side)

## Backup

```sh
docker compose exec db pg_dump -U canine canine > canine-$(date +%F).sql
sudo tar czf canine-volumes-$(date +%F).tgz canine-volumes/
```

## Upgrade

1. Releases: <https://github.com/CanineHQ/canine/releases>. Active.
2. `docker compose pull && docker compose up -d`
3. Rails migrations auto-run

## Gotchas

- **KUBECONFIG = CLUSTER ROOT CREDENTIAL**:
  - Canine holds kubeconfig for target clusters
  - Kubeconfig = equivalent to root on K8s cluster = all workloads, all secrets, all PVCs
  - **76th tool in hub-of-credentials family — Tier 1 CROWN-JEWEL — category: "infra-control-plane" (reinforcing Vito 99 + GoDoxy 102 precedents)**
  - **CROWN-JEWEL Tier 1: 17 tools**
  - **infra-control-plane sub-category now 3 tools**: Vito + GoDoxy-reverse-proxy + Canine-K8s-PaaS
  - Mitigation: least-privilege ServiceAccount (not cluster-admin); namespace-scoped kubeconfig
- **GIT WEBHOOKS + AUTO-BUILDS = CODE EXECUTION ON YOUR INFRA**:
  - Every push → Canine builds + deploys
  - Compromised developer-account → can deploy malicious container
  - Build-on-webhook = Docker-in-Docker typically
  - **Recipe convention: "CI-execution-on-webhook attack-surface" callout**
  - **NEW recipe convention** (Canine 1st)
- **CONTAINER REGISTRY CREDS**:
  - Canine pushes built images; needs registry-write
  - Registry-write creds = ability to push malicious images
  - **Recipe convention: "container-registry-write-credential" callout**
- **BUILT-IN DOCKER BUILDKIT**:
  - Building arbitrary customer Dockerfiles = arbitrary code execution in build
  - Build-isolation (rootless BuildKit, buildkitd sandbox) important
  - **Recipe convention: "build-isolation-trust-boundary" callout**
- **MULTI-TENANCY = ISOLATION BOUNDARY**:
  - Canine's account-isolation relies on K8s namespace-isolation + RBAC
  - Namespace != strong isolation (vs pod-sandbox like gVisor/Kata)
  - Shared-cluster tenancy has known weaknesses (kernel exploits span namespaces)
  - **Recipe convention: "K8s-namespace-multi-tenancy-isolation-limits" callout**
  - **NEW recipe convention**
- **ENTERPRISE SSO (SAML/OIDC/LDAP)**:
  - Provider-trust boundary; if IdP compromised → Canine compromised
  - Admin-SSO-bypass option should be carefully-guarded
  - **Recipe convention: "SSO-admin-bypass-escape-hatch" callout** (standard)
- **SECRET_KEY_BASE IMMUTABILITY**: **48th tool in immutability-of-secrets family.**
- **APACHE-2.0 LICENSE + COMMERCIAL-TIER?**:
  - License file says Apache
  - README doesn't explicitly mention commercial tier; verify on website
  - **Permissive license** = fork-friendly
- **PaaS-FOR-K8s CATEGORY PATTERN**:
  - **Canine** — Apache-2.0; enterprise SSO; SAML/OIDC/LDAP
  - **Coolify** — OSS; single-VPS-or-cluster
  - **Dokploy** — OSS Docker Swarm + K8s
  - **CapRover** — OSS simpler
  - **OpenShift** — RedHat; enterprise
  - **Rancher** — SUSE; K8s-management
  - **Portainer** — Docker + K8s; GUI
  - **Kubero** — OSS Heroku-on-K8s
  - **Commercial**: Render, Railway, Fly.io, Heroku
- **ENTERPRISE-FEATURE-SPOTLIGHT: SAML/OIDC/LDAP**:
  - Canine explicitly calls out enterprise SSO
  - Signals target market: enterprise K8s adopters
  - **Recipe convention: "enterprise-SSO-as-selling-point" signal**
- **HUB-OF-CREDENTIALS TIER 1 DENSITY**:
  - Kubeconfig (cluster root)
  - Container registry creds
  - GitHub/GitLab OAuth tokens
  - SSO IdP trust
  - All user SECRET_KEY_BASE
  - Users' env/secrets managed via Canine
  - **Extraordinarily-high credential-density** — the kubeconfig alone makes this Tier 1
- **INSTITUTIONAL-STEWARDSHIP**: CanineHQ organization. **62nd tool — org-backed-OSS sub-tier**.
- **TRANSPARENT-MAINTENANCE**: active + CI + Artifact-Hub + license-badge + docs + install-script. **70th tool in transparent-maintenance family** 🎯 **70-TOOL MILESTONE.**
- **ALTERNATIVES WORTH KNOWING:**
  - **Coolify** — OSS PaaS simpler; popular
  - **Dokploy** — Docker Swarm + K8s; polished
  - **CapRover** — simpler Docker-based
  - **Rancher** — K8s-management not PaaS UX
  - **Kubero** — similar Heroku-on-K8s
  - **OpenShift** — if enterprise RedHat
  - **Choose Canine if:** you want K8s-specific + enterprise-SSO + Apache-2.0 + multi-tenancy.
  - **Choose Coolify if:** you want OSS + simpler + single-VPS-or-cluster.
  - **Choose Rancher if:** you want K8s-cluster-management (not PaaS UX).
- **PROJECT HEALTH**: active + Apache-2.0 + Artifact Hub + CI + docs + organization. Strong.

## Links

- Repo: <https://github.com/CanineHQ/canine>
- Docs: <https://docs.canine.sh>
- Website: <https://canine.sh>
- Artifact Hub: <https://artifacthub.io/packages/search?repo=canine>
- Coolify (alt): <https://coolify.io>
- Dokploy (alt): <https://dokploy.com>
- CapRover (alt): <https://caprover.com>
- Kubero (alt): <https://www.kubero.dev>
- Rancher (alt K8s mgmt): <https://www.rancher.com>
- Heroku (commercial origin): <https://www.heroku.com>
- Render (alt commercial): <https://render.com>
