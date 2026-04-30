---
name: Uncloud
description: "Lightweight clustering + container orchestration for self-hosters — deploy Docker apps across cloud VMs + bare metal without Swarm or Kubernetes. WireGuard mesh + Caddy ingress + Docker Compose. No control plane. MPL-2.0 (check repo)."
---

# Uncloud

Uncloud is **"Docker across multiple machines without Kubernetes"** — a lightweight clustering + orchestration tool developed by **Pavel Sviderski (psviderski)** that stitches a handful of cloud VMs / bare metal / Raspberry Pis into a **single unified deployment target**. Secure WireGuard mesh between hosts, automatic service discovery, built-in Caddy reverse proxy with Let's Encrypt, and a familiar `docker compose` workflow. **No control plane, no quorum, no etcd** — each node holds a CRDT-synced copy of cluster state via [corrosion](https://github.com/superfly/corrosion) (Fly.io's open-source CRDT SQLite sync).

Positioning: **sweet spot between single-host Docker Compose and full Kubernetes.** If Docker Swarm is "K8s lite" and K3s is "K8s trimmed," Uncloud is "cluster-y Docker with a Caddy baked in."

Features:

- **Multi-host deployment** — cloud VMs + dedicated servers + bare metal + homelab Pi in one cluster
- **Docker Compose** compatible — `compose.yaml` works; no bespoke DSL
- **Zero-downtime rolling deployments** (automatic rollback coming soon)
- **[Unregistry](https://github.com/psviderski/unregistry)** integration — push images directly to machines without external registry (diff-layer transfer)
- **Service discovery** — built-in DNS server resolves service names to container IPs
- **WireGuard mesh** — zero-config private network; containers get unique IPs; NAT traversal
- **No control plane** — decentralized; no SPOF; no quorum to maintain
- **Caddy ingress** — automatic HTTPS via Let's Encrypt
- **Managed DNS** — free `*.xxxxxx.uncld.dev` subdomains via upstream Uncloud DNS
- **Docker-like CLI (`uc`)**
- **SSH-based management** — control via SSH to any cluster member

- Upstream repo: <https://github.com/psviderski/uncloud>
- Docs: <https://uncloud.run/docs>
- Install: <https://uncloud.run/docs/getting-started/install-cli>
- Recipes: <https://github.com/psviderski/uncloud-recipes>
- Uncloud DNS: <https://github.com/psviderski/uncloud-dns>
- Unregistry: <https://github.com/psviderski/unregistry>
- Discord: <https://discord.gg/eR35KQJhPu>

## Architecture in one minute

- **`uc` CLI** — on your laptop; manages cluster via SSH + gRPC
- **`uncloudd`** — per-machine daemon (systemd); runs Docker + WireGuard
- **`uncloud-corrosion`** — CRDT SQLite sync; each machine holds cluster state copy
- **Docker** — the container engine (installed by Uncloud if missing)
- **WireGuard** — mesh network, containers get `10.210.x.x` IPs
- **Caddy** — runs as a cluster service; reverse proxy + TLS
- **NO central API server** — imperative commands over SSH; state reconciled via corrosion CRDT
- **Resource per machine**: small — uncloudd + corrosion are lightweight

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Multi-host cluster | `uc machine init` + `uc machine add` for each node                | **Core use case**                                                                  |
| Single-host        | Works too; can grow later                                                  | Start simple, scale out                                                                    |
| Mixed cloud + on-prem | Hetzner + Oracle + home Pi all in one cluster                                           | Flagship scenario                                                                                      |
| macOS              | `brew install psviderski/tap/uncloud` (CLI)                                                         | CLI only; machines are Linux                                                                                                  |
| Machine OS         | Linux with systemd + SSH access as root or sudo-user                                                            | Ubuntu/Debian/Alpine/etc.                                                                                                                   |
| Kubernetes         | N/A — **Uncloud is an alternative to K8s**                                                                                     |                                                                                                                                                             |

## Inputs to collect

| Input                | Example                                          | Phase        | Notes                                                                    |
| -------------------- | ------------------------------------------------ | ------------ | ------------------------------------------------------------------------ |
| Server SSH access    | `root@vps.example.com` or sudo user + key                | Install      | SSH key in `~/.ssh/config` ideal                                                 |
| Public IPs           | VPS IPs                                                | Install      | For cluster endpoints                                                                    |
| Local CLI            | macOS/Linux laptop                                               | Client       | Install via brew or install.sh                                                           |
| Domain (optional)    | `app.example.com`                                                | Ingress      | Or use managed `*.xxxxxx.uncld.dev`                                                                       |
| DNS records          | A records on your provider (Cloudflare/Namecheap)                          | Ingress      | For your own domains                                                                                                     |
| `compose.yaml`       | your existing one                                                              | Deploy       | Compose spec works                                                                                                                         |

## Install CLI + init first machine

```sh
# On your laptop (macOS/Linux)
curl -fsS https://get.uncloud.run/install.sh | sh

# Initialise first machine (installs uncloudd + corrosion + Docker via SSH)
uc machine init root@your-server-ip

# Add more machines
uc machine add root@another-server-ip

# Deploy an app
uc run -p app.example.com:8000/https image/my-app

# List / remove
uc ls
uc rm my-app-name
```

Point DNS at your cluster, wait for Let's Encrypt cert, done.

## First boot (cluster deploy)

1. Install `uc` CLI on laptop
2. `uc machine init` on a cloud VM → creates cluster "default"
3. `uc machine add` to attach more machines (mix cloud + on-prem freely)
4. `uc ls machines` → verify mesh health
5. Deploy test service from `compose.yaml` or `uc run`
6. Point DNS A record at a cluster member IP (or use provided uncld.dev subdomain)
7. Verify HTTPS auto-provisioned by Caddy
8. Add multiple regions; Uncloud handles failover
9. Back up cluster config: `~/.config/uncloud` on laptop

## Data & config layout

- **Laptop**: `~/.config/uncloud/` — cluster config + SSH targets
- **Each machine**:
  - `/usr/local/bin/uncloudd` — daemon
  - `/usr/local/bin/uncloud-corrosion` — CRDT sync
  - `/etc/systemd/system/uncloud.service` + `uncloud-corrosion.service`
  - Docker + WireGuard state (standard paths)
  - Application data: whatever your services' volumes specify

## Backup

- **Cluster config**: `~/.config/uncloud` on your laptop — **KEEP THIS** (it's your management handle)
- **Application data**: per-service volumes on each machine — your responsibility (volsync, restic, Duplicacy)
- **State (CRDT)**: each machine holds a copy — cluster survives any machine loss; don't panic, just `uc machine rm` + add new

## Upgrade

1. Releases: <https://github.com/psviderski/uncloud/releases>. Active (nightly + stable channels).
2. `uc machine update` (check current docs) — rolling across machines.
3. Services: update via `uc run` / `uc compose up` — rolling.
4. **Pre-1.0** — expect breaking changes; pin + read release notes.

## Gotchas

- **Pre-1.0, actively developing.** Breaking changes possible. Pin to exact version + review release notes. Not yet "set-and-forget enterprise-ready."
- **Single-maintainer project**: primarily Pavel Sviderski. Active + growing community, has donations. **Bus-factor-1 pattern** (same framing as batches 70-73 mox, Duplicacy, TaxHacker). Not a reason to avoid — reason to plan.
- **SSH access is the trust boundary.** `uc` runs installations + daemon management over SSH as root. Protect your SSH keys. Use a dedicated provisioning key + disable after install for hardened stance.
- **No Kubernetes = no K8s ecosystem.** If you need HPA (horizontal pod autoscaler), complex operators, CRDs, service mesh (Istio/Linkerd), or existing Helm charts, Uncloud isn't it. It's deliberately simpler. For features needing K8s, use K3s.
- **Imperative over declarative** (per upstream design): GitOps-style flows (Flux/ArgoCD) don't fit. `uc run` + `uc compose up` are the patterns. You can script them but there's no native reconciliation loop.
- **WireGuard mesh + NAT traversal**: works in most residential + VPS scenarios. Some aggressive corporate firewalls or CGNATs still break. Test before committing a machine to the cluster.
- **Managed Uncloud DNS (`*.uncld.dev`)**: convenient; upstream-hosted. If you rely on it in production + their DNS goes down, your sites go down. For serious deploys, use your own domain + DNS provider.
- **Caddy cluster service**: runs on every machine serving ingress (or subset). Configure placement deliberately for production.
- **Docker version drift**: Uncloud installs Docker if missing but won't rip out yours. If your distro ships old Docker, update first.
- **Corrosion CRDT**: Fly.io's open-source SQLite CRDT sync. Impressive tech. Don't fight it — let CRDT handle eventual consistency; write code assuming eventual consistency at ingress.
- **Unregistry integration**: brilliant — push image directly to machines, only missing layers transferred. No Docker Hub / ECR / GHCR needed for in-cluster pushes.
- **Compose compatibility**: not 100%. Some Compose features (long-form networks, `deploy:` stanzas from Swarm mode) may not have 1:1 Uncloud equivalents yet. Check docs for gaps.
- **Stateful services** (Postgres / MySQL / Redis): you CAN run them, but Uncloud doesn't provide distributed storage. Volumes are per-machine. Pair with Longhorn-style solution or keep stateful services on dedicated "DB host" machines.
- **Uninstall**: clean — `uncloud-uninstall` removes everything per machine. Good citizen.
- **Community + support**: Discord active, docs growing. Expect DIY for edge cases.
- **License**: check repo LICENSE file (typical for this ecosystem: permissive OSS; verify current).
- **Alternatives worth knowing:**
  - **Docker Swarm** — Docker's built-in clustering; simpler than K8s; declining momentum
  - **K3s / k0s** — lightweight Kubernetes for edge + homelab
  - **Nomad** — HashiCorp orchestrator; multi-workload
  - **CapRover / Coolify / Dokploy** — single-host PaaS; Coolify has multi-server
  - **Fly.io** — commercial; similar philosophy (CRDT-sync under the hood via corrosion)
  - **Hashicorp Consul + Nomad** — service mesh + orchestrator combo
  - **Choose Uncloud if:** you want multi-host Docker + automatic HTTPS + WireGuard mesh + simplicity over K8s feature-richness.
  - **Choose K3s if:** you need K8s ecosystem + Helm charts.
  - **Choose Coolify / Dokploy if:** single-host + PaaS UX priority.
  - **Choose Swarm if:** already Docker-native org + declining-but-stable orchestrator is fine.

## Links

- Repo: <https://github.com/psviderski/uncloud>
- Docs: <https://uncloud.run/docs>
- Design doc: <https://github.com/psviderski/uncloud/blob/main/misc/design.md>
- Install CLI: <https://uncloud.run/docs/getting-started/install-cli>
- Releases: <https://github.com/psviderski/uncloud/releases>
- Recipes: <https://github.com/psviderski/uncloud-recipes>
- Unregistry: <https://github.com/psviderski/unregistry>
- Uncloud DNS: <https://github.com/psviderski/uncloud-dns>
- Corrosion (Fly.io CRDT): <https://github.com/superfly/corrosion>
- Discord: <https://discord.gg/eR35KQJhPu>
- Sponsor: <https://github.com/sponsors/psviderski>
- K3s (alt): <https://k3s.io>
- Docker Swarm: <https://docs.docker.com/engine/swarm/>
- Coolify (alt PaaS): <https://coolify.io>
