---
name: openrun
description: "Declarative internal tools deployment platform. Apache-2.0. openrundev. Single-binary. Docker/Podman or Kubernetes. GitOps blue-green deployments, OAuth/OIDC/SAML, RBAC, auto-TLS, scale-to-zero. Open-source alternative to Google Cloud Run / AWS App Runner."
---

# OpenRun

**Declarative web app deployment platform for internal tools.** Deploy containerized web apps with GitOps-style config, auto-TLS (Let's Encrypt), OAuth/OIDC/SAML auth, RBAC, and automatic scale-to-zero — on a single machine with Docker/Podman or on Kubernetes. No build server required. Apache-2.0.

Built + maintained by **openrundev**.

- Upstream repo: <https://github.com/openrundev/openrun>
- Docs: <https://openrun.dev>
- App specs: <https://github.com/openrundev/appspecs>
- CNCF landscape listing
- Latest release: v0.17.2

## Architecture in one minute

- Single Go binary (`openrun`) that acts as API server + request router + container manager
- No external web server (Nginx/Traefik/Caddy) required — OpenRun handles all routing and TLS internally
- Single-node: SQLite + Docker or Podman
- Multi-node / Kubernetes: external Postgres + Helm chart
- Apps deployed from Git repos directly — no Dockerfile required for frameworks with an AppSpec (Streamlit, Gradio, FastHTML, NiceGUI, Shiny, Reflex)
- Apps with a `Dockerfile` or `Containerfile` use the `container` spec
- Scale-to-zero: idle app containers are shut down; OpenRun starts them on first request

## Compatible install methods

| Infra              | Runtime                        | Notes                                              |
| ------------------ | ------------------------------ | -------------------------------------------------- |
| **Linux / macOS**  | `curl install.sh | sh`         | **Primary** — installs `openrun` binary to PATH    |
| **Homebrew (macOS)** | `brew install openrun`       | Also installs `mkcert` for local TLS               |
| **Windows**        | PowerShell install script      | One-liner; starts via `openrun server start`       |
| **Kubernetes**     | Helm chart                     | Multi-node; external Postgres required             |

> **Constraint:** OpenRun deploys single-container web apps only. Multi-container Docker Compose stacks are not supported as deployable apps. OpenRun itself is the only thing that needs Docker/Podman running.

## Inputs to collect

| Input                     | Example                        | Phase    | Notes                                                                      |
| ------------------------- | ------------------------------ | -------- | -------------------------------------------------------------------------- |
| Host OS                   | Ubuntu 22.04 / macOS / Windows | Install  | Determines install method                                                  |
| Container runtime         | Docker or Podman               | Install  | Auto-detected; both must not be running simultaneously                     |
| Domain (production)       | `run.example.com`              | TLS      | For Let's Encrypt certs; DNS must point to the server                      |
| OAuth/OIDC provider (opt) | GitHub / Google / Okta         | Auth     | For restricting app access; optional for dev use                           |
| Postgres URL (K8s only)   | `postgres://...`               | Database | Single-node uses embedded SQLite                                           |

## Install on Linux / macOS

```bash
curl -sSL https://openrun.dev/install.sh | sh
```

Open a new terminal (to pick up the updated `PATH`), then start the server:

```bash
openrun server start
```

OpenRun listens on:
- **HTTPS**: `https://localhost:25223` (or your domain)
- **HTTP**: `http://localhost:25222`

For dev/local, OpenRun uses `mkcert` for locally-trusted TLS certificates (install via `brew install mkcert` or the install script handles it on some platforms). For production, set the public domain and OpenRun provisions Let's Encrypt automatically.

## Install on macOS via Homebrew

```bash
brew tap openrundev/homebrew-openrun
brew install openrun
brew services start openrun
```

Homebrew automatically installs `mkcert` for local TLS.

## Install on Windows

```powershell
powershell -Command "iwr https://openrun.dev/install.ps1 -useb | iex"
```

Open a new command window, then: `openrun server start`

## Deploy an app (declarative / GitOps)

Apply an app spec from a Git repo (one command, no UI required):

```bash
# Deploy a Streamlit app (no Dockerfile needed — AppSpec handles it)
openrun app create --spec python-streamlit --branch master --approve github.com/streamlit/streamlit-example /streamlit

# Deploy an app with a Dockerfile
openrun app create --spec container --approve github.com/myorg/myapp /myapp

# Declarative multi-app deployment from a Starlark config file
openrun apply --approve github.com/openrundev/openrun/examples/utils.star

# Schedule automatic sync (GitOps: re-applies config on every git push)
openrun sync schedule --approve --promote github.com/openrundev/openrun/examples/utils.star
```

Apps are available at `https://localhost:25223/<path>` (e.g. `https://localhost:25223/streamlit`).

## Kubernetes install

```bash
# Install via Helm (Kubernetes)
helm repo add openrun https://openrun.dev/charts
helm install openrun openrun/openrun --set database.url=postgres://<connection-string>
```

See [Kubernetes docs](https://openrun.dev/docs/container/kubernetes/) for full Terraform-based infra setup.

## App management commands

```bash
openrun app list                          # list deployed apps
openrun app status /myapp                 # check app health
openrun app logs /myapp                   # tail app logs
openrun app delete /myapp                 # remove app
openrun server status                     # OpenRun server health
openrun server stop                       # stop OpenRun server
```

## Auth / RBAC

OpenRun supports OAuth/OIDC, SAML, and certificate-based auth for controlling who can access which deployed app. RBAC lets you define which users or groups can access which paths. Configure under:

```bash
openrun config set auth.provider=github
openrun config set auth.clientId=<id>
openrun config set auth.clientSecret=<secret>
```

Full RBAC config: see [openrun.dev/docs/configuration/rbac/](https://openrun.dev/docs/configuration/rbac/).

## Upgrade

```bash
curl -sSL https://openrun.dev/install.sh | sh
# or for Homebrew:
brew upgrade openrun
```

Kubernetes: `helm upgrade openrun openrun/openrun`

## Gotchas

- **Single-container apps only.** OpenRun does not support Docker Compose multi-service stacks as deployable apps. If your internal tool needs a database, connect to an externally-managed database.
- **Docker and Podman must not both be running.** OpenRun auto-detects which is present; if both are active, behavior is undefined. Use one or the other.
- **DNS must point to the server before Let's Encrypt runs.** For production domains, set the A-record before starting OpenRun or deploying the first app — OpenRun obtains TLS certs on first request.
- **`mkcert` required for local TLS (dev).** On macOS, Homebrew install handles this automatically. On Linux, the install script should handle it; verify with `mkcert -install`.
- **AppSpecs handle framework boilerplate.** For Streamlit, Gradio, FastHTML, etc., no Dockerfile is needed — OpenRun's AppSpec injects the right runtime. For anything else, provide a `Dockerfile` or `Containerfile` in the source repo.
- **Scale-to-zero adds cold-start latency.** Idle apps are stopped; the first request after idle wakes the container. For apps that must respond instantly, configure always-on (see docs).
- **Audit logs.** All API calls and app operations are automatically logged. Check `openrun audit` for a full trail.
