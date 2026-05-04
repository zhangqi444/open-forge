# DevPod

Client-only tool for creating reproducible developer environments based on the [devcontainer.json](https://containers.dev/) standard on any backend. DevPod is essentially self-hosted GitHub Codespaces — you define your dev environment in a `devcontainer.json`, and DevPod spins it up on whatever compute you choose: local Docker, a remote VM, Kubernetes, or any cloud provider. No vendor lock-in. Upstream: <https://github.com/loft-sh/devpod>. Docs: <https://devpod.sh/docs>.

> **Note:** DevPod is a **client-only** tool — it runs on your local machine (or in CI) and provisions environments on remote backends. There is no self-hosted DevPod server. The "self-hosted" aspect is that *you* control the backend compute where environments run.

## Compatible install methods

Verified against upstream docs at <https://devpod.sh/docs/getting-started/install>.

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Desktop App (macOS/Windows/Linux) | <https://devpod.sh/docs/getting-started/install> | ✅ | GUI-based workflow. Easiest for individuals. |
| CLI only (devpod) | <https://devpod.sh/docs/getting-started/install#optional-install-cli> | ✅ | Headless / CI / scripting. |
| Homebrew (macOS/Linux) | `brew install devpod` | ✅ | macOS / Linux CLI. |
| DevPod Pro (server) | <https://devpod.sh/pro> | ✅ (commercial) | Shared team infrastructure with central management. Out of scope for open-forge. |

## Inputs to collect

No server to configure. Configure **providers** (backends) after install:

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| provider | "Which backend provider to use?" | `AskUserQuestion`: `docker (local)` / `ssh (remote machine)` / `kubernetes` / `aws` / `gcp` / `azure` | All |
| ssh | "SSH host address?" | Free-text | SSH provider |
| ssh | "SSH user?" | Free-text (default: current user) | SSH provider |

## Software-layer concerns

### How DevPod works

1. You have a project with a `devcontainer.json` (or DevPod generates a default one).
2. Run `devpod up <repo-url>` or point at a local directory.
3. DevPod uses the configured **provider** to spin up a container/VM, inject the devcontainer config, install VS Code Server (or JetBrains Gateway), and connect your IDE.

```
[Your IDE] ←─── SSH/Gateway ───→ [DevPod container on provider]
                                   (Docker / remote VM / K8s pod)
```

### CLI quickstart

```bash
# Install CLI
brew install devpod   # or download from devpod.sh

# Add Docker provider (runs containers locally)
devpod provider add docker

# Start a workspace from a GitHub repo
devpod up github.com/my-org/my-repo

# Start from a local directory
devpod up /path/to/project --ide vscode

# List workspaces
devpod list

# Stop a workspace
devpod stop my-repo

# Delete a workspace
devpod delete my-repo
```

### Providers

| Provider | Command | What it does |
|---|---|---|
| `docker` | `devpod provider add docker` | Local Docker — runs containers on your machine |
| `ssh` | `devpod provider add ssh` | Remote machine via SSH — great for beefy cloud VMs |
| `kubernetes` | `devpod provider add kubernetes` | Runs workspaces as K8s pods |
| `aws` | `devpod provider add aws` | Spins up EC2 instances per workspace |
| `gcp` | `devpod provider add gcp` | Spins up GCE VMs per workspace |

### devcontainer.json (standard)

DevPod uses the same `devcontainer.json` format as GitHub Codespaces and VS Code Dev Containers:

```json
{
  "name": "My App",
  "image": "mcr.microsoft.com/devcontainers/python:3.12",
  "features": {
    "ghcr.io/devcontainers/features/node:1": {}
  },
  "postCreateCommand": "pip install -r requirements.txt",
  "customizations": {
    "vscode": {
      "extensions": ["ms-python.python"]
    }
  }
}
```

### IDE support

| IDE | Support |
|---|---|
| VS Code (local) | ✅ First-class |
| VS Code Browser (code-server) | ✅ |
| JetBrains IDEs (via Gateway) | ✅ |
| Any SSH-capable editor | ✅ (connect via SSH) |

### Data directories

| Path | Contents |
|---|---|
| `~/.devpod/` | Provider config, workspace metadata, SSH keys |
| Provider-specific storage | Container/VM state on the chosen backend |

## Upgrade procedure

- **Desktop app:** Built-in auto-updater.
- **Homebrew:** `brew upgrade devpod`
- **Manual CLI:** Download the latest binary from <https://github.com/loft-sh/devpod/releases>.

## Gotchas

- **Needs Docker on the local machine for `docker` provider.** The local Docker provider requires Docker Desktop or Docker Engine installed.
- **Auto-shutdown for cloud providers.** Cloud providers (AWS, GCP, Azure) will spin up VMs that cost money. DevPod supports inactivity timeout to auto-shutdown — configure it per provider.
- **Port forwarding is automatic.** DevPod automatically forwards ports listed in `devcontainer.json`'s `forwardPorts`. Extra ports can be forwarded manually via `devpod ssh --forward 8080:8080`.
- **Git credentials are synced.** DevPod syncs your local Git config and SSH agent into the container by default.
- **Workspace = one repo.** Each DevPod workspace maps to one project/repo. Monorepos work but sub-project workspaces aren't a native concept.

## Links

- Upstream: <https://github.com/loft-sh/devpod>
- Website: <https://devpod.sh>
- Docs: <https://devpod.sh/docs>
- Providers: <https://devpod.sh/docs/managing-providers/add-provider>
- devcontainer.json spec: <https://containers.dev/>
