---
name: Kubetail
description: "Real-time logging dashboard for Kubernetes. CLI + embedded web UI. Go. kubetail-org/kubetail. Tail logs across multi-container workloads; filter by workload, time, node, grep."
---

# Kubetail

**Real-time logging dashboard for Kubernetes.** Tail logs from all containers in a workload (Deployment, DaemonSet, StatefulSet, CronJob) merged into a single chronological timeline — in your browser or terminal. Uses your cluster's Kubernetes API directly; no log forwarding, no external sink.

Built + maintained by **kubetail-org**. Available as a CLI tool that embeds a web dashboard.

- Upstream repo: <https://github.com/kubetail-org/kubetail>
- Website + demo: <https://www.kubetail.com>
- Demo: <https://www.kubetail.com/demo>
- Discord: <https://discord.gg/CmsmWAVkvX>
- Slack: `#kubetail` in Kubernetes Slack

## Architecture in one minute

- **Go CLI** (`kubetail`) — single binary that serves an embedded **Next.js** web UI
- Connects to Kubernetes via **kubeconfig** (local cluster) or **SSH** (remote KVM/cluster)
- Pulls logs directly from the **Kubernetes API** — no agents, no forwarding, no storage
- Port: the CLI spawns a local server (default `:8080`) and opens the browser
- Can also run as an **in-cluster Helm chart** for persistent team access
- Resource: **minimal** — log streaming only; not an indexing solution

## Compatible install methods

| Infra                | Runtime                          | Notes                                                                 |
| -------------------- | -------------------------------- | --------------------------------------------------------------------- |
| **CLI (local)**      | `kubetail` binary                | **Primary** — installs to desktop, connects to any kubeconfig cluster |
| **In-cluster Helm**  | kubetail Helm chart              | Persistent team dashboard; deploys to your K8s cluster                |
| **Docker**           | `kubetail-org/kubetail`          | Run anywhere — Desktop, Docker, Cluster                               |

## Install CLI

Choose the right method for your OS:

```sh
# macOS / Linux (Homebrew)
brew install kubetail

# Kubernetes plugin manager
kubectl krew install kubetail

# Ubuntu/Mint (apt)
sudo add-apt-repository ppa:kubetail/kubetail
sudo apt update && sudo apt install kubetail-cli

# Fedora/RHEL/CentOS (copr)
dnf copr enable kubetail/kubetail && dnf install kubetail

# Alpine
apk add kubetail --repository=https://dl-cdn.alpinelinux.org/alpine/edge/testing

# Arch Linux (AUR)
yay -S kubetail-cli

# Windows (Winget)
winget install kubetail

# Windows (Chocolatey / Scoop)
choco install kubetail
scoop install kubetail

# Nix (Flake)
nix profile add github:kubetail-org/kubetail-nix

# Snap
sudo snap install kubetail
```

## Quickstart

```sh
# Launch web dashboard (opens browser at localhost)
kubetail

# Stream logs directly to terminal
kubetail logs deployment/my-app -n my-namespace

# Connect to a specific context
kubetail --context my-cluster
```

## In-cluster Helm install

```sh
helm repo add kubetail https://kubetail-org.github.io/kubetail
helm repo update
helm install kubetail kubetail/kubetail --namespace kubetail --create-namespace
```

See the [docs](https://www.kubetail.com/docs) for ingress + auth configuration.

## Features

- View logs from **all containers in a workload** merged into one timeline
- **Real-time** streaming via Kubernetes Watch API
- Filter by: workload type, time range (absolute/relative), node properties (AZ, arch, node ID), grep
- Switch between **multiple clusters** (Desktop mode)
- Tracks container **lifecycle events** (start/stop/replace) — log timeline stays coherent as pods restart
- All data fetched from your K8s API — **private by default**, nothing leaves your cluster
- Run anywhere: Desktop, Docker, in-cluster

## Inputs to collect

| Input                | Example                        | Phase   | Notes                                                         |
| -------------------- | ------------------------------ | ------- | ------------------------------------------------------------- |
| Kubeconfig           | `~/.kube/config`               | Auth    | Standard kubeconfig; multi-context supported                  |
| Context              | `prod-cluster`                 | Auth    | `kubetail --context <name>` to pick a specific cluster        |
| Port (optional)      | `8080` (default)               | Config  | Local dashboard port                                          |
| Namespace(s)         | `my-app` or all               | Filter  | Scope to namespace or `-A` for all                            |

## First boot

1. Install `kubetail` (Homebrew or your package manager).
2. Ensure `kubectl` can reach your cluster (`kubectl get pods` works).
3. `kubetail` → browser opens with the dashboard.
4. Select a workload → logs stream in real-time.
5. Done. No config, no DB, no auth setup for local desktop use.

## Backup

Nothing to back up server-side — Kubetail is stateless (no log storage). Logs live in Kubernetes; back up your cluster's log retention policy.

## Upgrade

- CLI: `brew upgrade kubetail` / `kubectl krew upgrade kubetail` / distro package manager
- Helm: `helm repo update && helm upgrade kubetail kubetail/kubetail -n kubetail`

## Gotchas

- **Not a log aggregator.** Kubetail doesn't store logs — it streams from the Kubernetes API. Once a pod is deleted, its logs are gone (unless you have a separate log store like Loki/ELK). For historical log analysis, you need a separate solution.
- **Real-time tail only.** No log search across historical data beyond the container's current buffer (configurable with `kubectl logs --tail`). For indexed historical search: Grafana Loki + Kubetail makes sense as complements.
- **Kubernetes API rate limits.** Streaming logs from many pods simultaneously will fire many Watch requests; large clusters with hundreds of pods may hit API server rate limits. Scope to relevant namespaces.
- **In-cluster Helm chart needs ingress + auth.** The desktop CLI uses your local kubeconfig; the in-cluster chart needs proper ingress and RBAC. Check the Helm chart values for auth options before exposing to your team.
- **Multi-cluster (Desktop-only feature).** Switching between clusters via kubeconfig contexts is a Desktop feature; in-cluster mode is single-cluster.
- **Container log buffer is finite.** Kubernetes retains logs in the node's container runtime buffer (typically last N bytes, configurable). Very high-volume services may have short log history available.
- **No Windows native cluster.** Works on Windows via WSL2 + kubeconfig; `winget install kubetail` installs the binary but your kubeconfig must work in that environment.
- **Krew alternative path.** If you prefer keeping K8s tools under `kubectl krew`, `kubectl krew install kubetail` installs it as a `kubectl` plugin (`kubectl kubetail …`).

## Project health

Active, multi-language README (8 languages), Discord + Slack, Homebrew, Krew, 15+ package managers supported, demo site, Helm chart. Backed by kubetail-org with multiple contributors.

## Kubernetes-log-family

- **Kubetail** — multi-container merged real-time tail, desktop CLI + in-cluster, no storage
- **Stern** — OG K8s multi-pod log tailer, CLI-only, no web UI
- **Grafana Loki + Promtail** — log aggregation + indexing + Grafana UI; heavyweight but historical
- **kubectl logs -f** — single container only; native; simplest
- **Lens** — full IDE-level Kubernetes desktop UI (logs + a lot more)

**Choose Kubetail if:** you want a beautiful real-time log viewer for multi-container workloads with a web UI, without deploying a log aggregation stack.

## Links

- Repo: <https://github.com/kubetail-org/kubetail>
- Docs: <https://www.kubetail.com/docs>
- Demo: <https://www.kubetail.com/demo>
- Stern (alt): <https://github.com/stern/stern>
- Grafana Loki (alt): <https://grafana.com/oss/loki/>
