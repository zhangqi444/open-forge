---
name: opik
description: Opik recipe for open-forge. Covers self-hosted Docker Compose install (local/dev) and Kubernetes/Helm (production). LLM observability, evaluation, and optimization platform by Comet. Upstream docs: https://www.comet.com/docs/opik/
---

# Opik

Open-source LLM observability, evaluation, and optimization platform. Trace LLM calls, evaluate with LLM-as-a-judge, run experiments, and monitor production workloads. Built by [Comet](https://www.comet.com). Upstream: <https://github.com/comet-ml/opik>. Docs: <https://www.comet.com/docs/opik/>.

19,161 stars · Apache-2.0

## What it is

Opik helps you build, test, and optimize generative AI applications. Key capabilities:

- **Tracing** — Track all LLM calls, agent steps, and conversation context in development and production
- **Evaluation** — LLM-as-a-judge metrics (hallucination detection, moderation, RAG assessment), experiment management, dataset management
- **Production monitoring** — Dashboards for feedback scores, trace counts, and token usage; online evaluation rules
- **Agent Optimizer** — SDK-level prompt and agent optimization
- **Integrations** — OpenAI, LangChain, LlamaIndex, Google ADK, Autogen, Flowise AI, and more

## Compatible install methods

| Method | Upstream | When to use |
|---|---|---|
| Docker Compose via `./opik.sh` | https://www.comet.com/docs/opik/self-host/local/ | Local dev and testing. Simplest self-hosted option. |
| Kubernetes via Helm chart | https://www.comet.com/docs/opik/self-host/kubernetes/ | Production or team deployments at scale. |
| Comet.com Cloud | https://www.comet.com/signup | Out of scope — managed SaaS, no self-host. |

## Inputs to collect

| Phase | Prompt | Applicability |
|---|---|---|
| preflight | "Docker Compose (local) or Kubernetes (production)?" | All |
| network | "What hostname/domain will Opik be reached at?" | Production Helm deploys |
| auth | "Configure OIDC/Okta authentication?" | Optional, production |

## Docker Compose install (local / dev)

Upstream: https://www.comet.com/docs/opik/self-host/local/

    git clone https://github.com/comet-ml/opik.git
    cd opik
    ./opik.sh

`./opik.sh` is a wrapper around Docker Compose. It pulls all required images and starts the stack.

UI is accessible at http://localhost:5173 after startup.

### Services started

| Service | Role |
|---|---|
| frontend | Web UI (port 5173) |
| backend / api | REST API and trace ingestion |
| ClickHouse | Analytics and trace storage (large image, ~1 GB first pull) |
| Redis | Caching and queuing |
| MySQL | Metadata, experiments, datasets |

### Python SDK (point at self-hosted instance)

    pip install opik

    # Configure to talk to your local instance
    opik configure

When prompted, set the Opik server URL to http://localhost:5173.

Or in code:

    import opik
    opik.configure(use_local=True)

### Stopping / restarting

    # From the opik repo directory
    ./opik.sh stop
    ./opik.sh start

## Kubernetes / Helm install (production)

Upstream: https://www.comet.com/docs/opik/self-host/kubernetes/

    helm repo add comet https://comet-ml.github.io/opik
    helm repo update
    helm install opik comet/opik --namespace opik --create-namespace

Refer to upstream Helm values docs for ingress, storage class, and resource customization.

## Upgrade

Docker Compose:

    cd opik
    git pull
    ./opik.sh

Kubernetes:

    helm repo update
    helm upgrade opik comet/opik --namespace opik

Check the changelog before upgrading — v1.7.0 introduced breaking changes:
https://github.com/comet-ml/opik/blob/main/CHANGELOG.md

## Gotchas

- `./opik.sh` is the correct entry point, not `docker compose up` directly.
- First run downloads the ClickHouse image (~1 GB) — allow extra time.
- `depends_3rdparty: true` in awesome-selfhosted — ClickHouse is a required bundled dependency, not optional.
- Docker Compose deploy is for **local development and testing** only per upstream; use Kubernetes for production.
- SDK `opik configure` prompts interactively — use `opik.configure(use_local=True)` for non-interactive scripting.
- Version 2.0.x is current as of April 2026; check GitHub releases for the latest tag.

## Links

- GitHub: https://github.com/comet-ml/opik
- Docs: https://www.comet.com/docs/opik/
- Self-host (Docker): https://www.comet.com/docs/opik/self-host/local/
- Self-host (Kubernetes): https://www.comet.com/docs/opik/self-host/kubernetes/
- Changelog: https://github.com/comet-ml/opik/blob/main/CHANGELOG.md
