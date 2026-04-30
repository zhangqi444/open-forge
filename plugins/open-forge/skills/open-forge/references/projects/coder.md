---
name: Coder
description: Self-hosted cloud development environments (remote workspaces on demand). Deploys Terraform-provisioned workspaces (VMs, Kubernetes pods, Docker containers) to your infra; users connect via web IDE (code-server), VS Code remote, JetBrains Gateway, or SSH. AGPL-3.0 (core) / commercial (enterprise).
---

# Coder

Coder is "GitHub Codespaces, but you own the servers". Instead of dev teams spinning up local Docker + dotfiles + SSH keys + VPN, Coder runs a central server that provisions on-demand remote development environments — a workspace is a Terraform template (EC2 instance + IAM, a K8s pod, a Docker container, a Proxmox VM, anything your Terraform can describe). Developers open the Coder web UI, click "Create Workspace", get a running environment they can connect to via:

- **Web IDE** (code-server by default; VS Code in browser)
- **VS Code Desktop** via remote-SSH extension
- **JetBrains Gateway** for IntelliJ / PyCharm / WebStorm / etc.
- **SSH** directly
- **Cursor, Zed, Windsurf** (all support Coder via SSH remotes)

Good fit for: teams with non-trivial dev environment setup (ML + CUDA, monorepos, big DBs), regulated industries (code stays on your infra), remote-first teams, BYO-device policies (all dev happens on the server, laptop just SSHes in).

- Upstream repo: <https://github.com/coder/coder>
- Website: <https://coder.com>
- Docs: <https://coder.com/docs>
- Install: <https://coder.com/docs/install>
- Templates (registry): <https://registry.coder.com>

**Note**: `coder/coder` is the current product (2022+). The older **`cdr/code-server`** (VS Code in browser, single-binary) is maintained by the same team but is a separate product — that's covered by the `code-server` recipe.

## Architecture in one minute

- **Coder Server** — single Go binary + Postgres + optional derpers for WebRTC relay
- **Provisioners** — run Terraform to create/destroy workspaces. Can run embedded in the server or as external provisioner daemons (for scaling + network isolation)
- **Workspaces** — the actual dev environments. Run on "compute hosts" (EC2 / K8s cluster / Docker host / Proxmox / your VPS), each with an **agent** binary Coder injects at provision-time
- **Agent** — runs inside the workspace, connects back to Coder server over WebSocket tunnel, handles IDE connections, port forwards, SSH, file sync

## Compatible install methods

| Infra       | Runtime                                                   | Notes                                                                    |
| ----------- | --------------------------------------------------------- | ------------------------------------------------------------------------ |
| Single VM   | `curl -L https://coder.com/install.sh \| sh` + systemd    | **Simplest** for small teams                                              |
| Single VM   | Docker (`ghcr.io/coder/coder`)                            | Also simple; use an external Postgres for prod                            |
| Kubernetes  | **Official Helm chart**                                   | **Recommended for teams** — see <https://coder.com/docs/install/kubernetes>|
| Managed     | Coder Enterprise / Premium                                 | Paid commercial offering                                                  |

**Where do workspaces run?** That's orthogonal. Pick per-template:

- **Docker containers** — easiest; Coder server schedules them on a Docker host (usually the same host as Coder)
- **Kubernetes pods** — most common at scale; each workspace = a pod in the cluster
- **EC2 / GCE / Azure VMs** — per-workspace VMs via Terraform
- **Proxmox / VMware / libvirt** — self-hosted hypervisors
- **Local Docker** — on the dev's laptop (rare)

## Inputs to collect

| Input                     | Example                                          | Phase     | Notes                                                               |
| ------------------------- | ------------------------------------------------ | --------- | ------------------------------------------------------------------- |
| `CODER_ACCESS_URL`        | `https://coder.example.com`                      | Runtime   | Public URL users connect to                                          |
| `CODER_PG_CONNECTION_URL` | `postgres://coder:...@db:5432/coder?sslmode=disable` | DB    | External Postgres 13+ required for prod                               |
| Wildcard subdomain        | `*.coder.example.com` → same IP                  | DNS       | For port-forwarding via subdomains (workspace apps)                  |
| TLS                       | via reverse proxy or Coder's built-in             | TLS       | Needed for web IDE + agent                                            |
| First admin               | email + password                                  | Bootstrap | Created via web UI on first visit                                    |
| OIDC (optional)            | client_id/secret + issuer                         | Auth      | SSO replaces first-login password flow                                |
| Compute target             | Docker / K8s / cloud / Proxmox                    | Templates | Per-template; can mix                                                 |
| Template variables         | per-template (e.g., AWS instance type)            | Templates | User picks when creating workspace                                    |

## Install via install script + systemd (simplest)

```sh
# 1. Install Coder
curl -L https://coder.com/install.sh | sh

# 2. Provision an external Postgres 13+ (on the same host or elsewhere)
sudo -u postgres createuser --pwprompt coder
sudo -u postgres createdb -O coder coder

# 3. Configure
sudo tee /etc/coder.d/coder.env << 'EOF'
CODER_ACCESS_URL=https://coder.example.com
CODER_WILDCARD_ACCESS_URL=*.coder.example.com
CODER_HTTP_ADDRESS=0.0.0.0:3000
CODER_PG_CONNECTION_URL=postgres://coder:<pw>@localhost:5432/coder?sslmode=disable
EOF

# 4. Start
sudo systemctl enable --now coder
sudo journalctl -f -u coder

# 5. Browse https://coder.example.com → create first admin
```

Behind Caddy / nginx for TLS + the wildcard subdomain.

## Install via Docker

```yaml
services:
  coder:
    image: ghcr.io/coder/coder:v2.26.2    # pin; NOT :latest in prod
    container_name: coder
    restart: unless-stopped
    environment:
      CODER_ACCESS_URL: https://coder.example.com
      CODER_WILDCARD_ACCESS_URL: "*.coder.example.com"
      CODER_HTTP_ADDRESS: 0.0.0.0:7080
      CODER_PG_CONNECTION_URL: postgres://coder:<pw>@db:5432/coder?sslmode=disable
    depends_on:
      db: { condition: service_healthy }
    ports:
      - "7080:7080"
    volumes:
      # For Docker-workspace templates, let Coder manage containers on the host
      - /var/run/docker.sock:/var/run/docker.sock
    group_add: [ "<docker gid on host>" ]

  db:
    image: postgres:17-alpine
    container_name: coder-db
    restart: unless-stopped
    environment:
      POSTGRES_USER: coder
      POSTGRES_PASSWORD: <strong>
      POSTGRES_DB: coder
    volumes:
      - coder-db:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U coder -d coder"]
      interval: 10s
      retries: 5

volumes:
  coder-db:
```

## Install on Kubernetes

```sh
helm repo add coder-v2 https://helm.coder.com/v2
helm repo update

helm install coder coder-v2/coder \
  --namespace coder --create-namespace \
  --values values.yaml \
  --version 2.26.2
```

Minimal `values.yaml`:

```yaml
coder:
  env:
    - name: CODER_PG_CONNECTION_URL
      valueFrom: { secretKeyRef: { name: coder-db-url, key: url } }
    - name: CODER_ACCESS_URL
      value: "https://coder.example.com"
    - name: CODER_WILDCARD_ACCESS_URL
      value: "*.coder.example.com"
  service:
    type: LoadBalancer
  ingress:
    enable: true
    host: coder.example.com
    wildcardHost: "*.coder.example.com"
    tls: { enable: true, secretName: coder-tls }
```

Docs: <https://coder.com/docs/install/kubernetes>.

## Create a template

After first login:

1. **Templates → Create Template**. Pick a starter (Docker, K8s, EC2, …) from the registry: <https://registry.coder.com>
2. Edit the Terraform `main.tf` — the template IS Terraform; Coder just wraps it
3. Publish → Users can now create workspaces from it

Minimal "docker container" template skeleton:

```hcl
terraform {
  required_providers {
    coder  = { source = "coder/coder" }
    docker = { source = "kreuzwerker/docker" }
  }
}

data "coder_workspace" "me" {}
resource "coder_agent" "main" {
  os   = "linux"
  arch = "amd64"
  startup_script = "code-server --bind-addr 0.0.0.0:8080"
}
resource "docker_container" "workspace" {
  name  = "coder-${data.coder_workspace.me.owner}-${data.coder_workspace.me.name}"
  image = "codercom/enterprise-base:ubuntu"
  env   = ["CODER_AGENT_TOKEN=${coder_agent.main.token}"]
  command = ["sh", "-c", coder_agent.main.init_script]
}
```

## Data & config layout

- **Postgres** — all state: users, orgs, templates, workspaces, audit log, provisioning history
- **Workspace state** — Terraform state stored in Postgres, keyed per-workspace
- **Agent tokens** — per-workspace; rotated on workspace restart
- **Derp servers** — optional WebRTC relays (for P2P when direct fails); run embedded or separately
- **No local filesystem state** on Coder server (stateless except for cert/token cache)

## Backup

```sh
# Just Postgres
pg_dump -U coder coder | gzip > coder-db-$(date +%F).sql.gz
```

Templates are in the DB (Terraform source + metadata). Workspace snapshots are in the DB or in the underlying compute (e.g., EBS volumes).

**Separately**, back up:

- **OIDC client secret** (if using SSO)
- **Terraform state encryption** config
- Template Terraform source (version-control it separately; templates can be `file://` or `git` sources)

## Upgrade

1. Releases: <https://github.com/coder/coder/releases>. Monthly-ish.
2. Install-script: rerun it OR `apt upgrade coder`.
3. Docker: `docker compose pull && docker compose up -d`. Migrations on startup.
4. Helm: `helm upgrade coder coder-v2/coder --version <new>`.
5. **Minor version jumps** are safe (within same major). Major bumps (v1 → v2) required data migration + template rewrite.
6. Existing **workspaces continue running** during server upgrades; agents reconnect when server is back.
7. Templates may need updating after major Coder version changes (provider-side API tweaks).

## Gotchas

- **Wildcard DNS is required** for many features. Workspace apps (port forwarding into the workspace, accessible via `http://app--workspace--user.coder.example.com`) need the wildcard. Without, users fall back to the UI's app frame.
- **TLS on the wildcard subdomain**. Let's Encrypt wildcards require DNS-01; easiest via Caddy + a DNS plugin, or Coder's built-in LE with DNS provider.
- **Agent token rotates per workspace restart.** Scripts baked into workspace images should read `CODER_AGENT_TOKEN` from env at startup.
- **Postgres required.** Coder won't run with SQLite in production (you can override for dev, but don't).
- **External provisioner daemons** for separating template deploy from server. Let you run `coder provisionerd start --psk <shared-secret>` on a different host (good for networks where the Coder server can't directly reach compute clouds).
- **First user = Site Owner** (admin). Subsequent users sign up if enabled, or are invited by admins.
- **OIDC integration** supports any OIDC-compliant IdP: Google, Okta, Keycloak, Zitadel, Authelia, Auth0. Configure at startup via env vars.
- **Workspace autostop** policy kills idle workspaces on a schedule to save cloud $. Tune per-template.
- **Workspace cost** is whatever your underlying compute costs — Coder doesn't provision cloud infrastructure pricing, it just uses Terraform.
- **Network from workspace**: workspaces need outbound to Coder server + agent port for tunneling. Coder's networking uses Tailscale-based WireGuard under the hood; handles NAT traversal.
- **Audit log** in Postgres records everything — useful for compliance, grows fast in busy installs.
- **Role-based access**: Site Owner, Site Auditor, User Admin, Template Admin, regular user. Fine-grained per-org and per-template.
- **AGPL-3.0 core + commercial "Premium" features** — Premium adds groups-based policies, audit log export, high availability, template prebuilt workspaces, workspace prebuilds, custom login branding. Check <https://coder.com/pricing>.
- **Terraform-only** — if you want Kubernetes-native CRDs (no Terraform), look at **Gitpod Flex** or **DevPod** or **Okteto**.
- **code-server ≠ Coder.** `cdr/code-server` is the single-binary VS Code web IDE (separate product). `coder/coder` orchestrates full workspaces (which often RUN code-server inside).
- **Prebuilt workspaces (Premium)** — pool of pre-provisioned workspaces so users get instant starts instead of 1-2 min Terraform runs.
- **Template updates** don't auto-apply to existing workspaces; users see "Template updated" banner and can update at next restart.
- **Registry templates** are community-contributed starters. Review before using; they run in your infra.
- **Dotfiles repo** per-user can be auto-cloned into workspaces (`dotfiles` personalization feature).
- **JetBrains Gateway** integration requires the user to install JetBrains Gateway locally; Coder handles the protocol.
- **SSH convenience**: `coder ssh <workspace>` / `coder config-ssh` generates an SSH config file users can paste into `~/.ssh/config`.
- **Alternatives worth knowing:**
  - **GitHub Codespaces** — managed SaaS
  - **Gitpod** (GA flex edition) — similar positioning
  - **DevPod** (Loft) — OSS, more decentralized (no central server required)
  - **Okteto** — Kubernetes-focused
  - **JetBrains Space** — commercial, JetBrains-only IDE focus
  - **code-server** (`cdr/code-server`) — just the VS Code browser IDE, no orchestration

## Links

- Repo: <https://github.com/coder/coder>
- Website: <https://coder.com>
- Docs: <https://coder.com/docs>
- Install: <https://coder.com/docs/install>
- Kubernetes install: <https://coder.com/docs/install/kubernetes>
- Docker install: <https://coder.com/docs/install/docker>
- Templates guide: <https://coder.com/docs/templates>
- Template registry: <https://registry.coder.com>
- Provisioner daemons: <https://coder.com/docs/admin/provisioner-daemons>
- Releases: <https://github.com/coder/coder/releases>
- Helm chart: <https://github.com/coder/coder/tree/main/helm/coder>
- Premium features: <https://coder.com/pricing>
- Discord / community: <https://coder.com/chat>
