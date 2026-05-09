---
name: DeepWiki-Open
description: "Self-hosted AI-powered wiki generator for GitHub, GitLab, and Bitbucket repositories — analyzes code structure, generates comprehensive documentation with Mermaid diagrams, enables RAG-powered Q&A and deep research against any repo. Docker Compose. Requires LLM API key (Google Gemini, OpenAI, OpenRouter, Azure, or local Ollama)."
---

# DeepWiki-Open

DeepWiki-Open automatically generates interactive wikis for any GitHub, GitLab, or Bitbucket repository. Point it at a repo URL and it will:

1. Clone and analyze the code structure
2. Create embeddings for smart retrieval (OpenAI, Google AI, or local Ollama)
3. Generate comprehensive documentation with Mermaid architecture diagrams
4. Organize everything into a navigable wiki
5. Enable RAG-powered chat ("Ask") against the repository
6. Support multi-turn "DeepResearch" for complex topics

Works with public repos out of the box. Private repos require a personal access token.

- Upstream repo: <https://github.com/AsyncFuncAI/deepwiki-open>
- Container image: `ghcr.io/asyncfuncai/deepwiki-open:latest`
- License: MIT

## Architecture in one minute

- **Frontend** — Next.js (port 3000)
- **Backend** — Python FastAPI with Poetry (port 8001)
- **Embeddings** — OpenAI `text-embedding-3-small` (default), Google AI `text-embedding-004`, or local Ollama
- **LLM providers** — Google Gemini, OpenAI, OpenRouter, Azure OpenAI, Ollama
- **Data storage** — `~/.adalflow/` (cloned repos + embedding cache); mounted as a Docker volume
- **Single container** ships both frontend and backend; compose runs one service

## Compatible install methods

| Infra | Runtime | Notes |
|---|---|---|
| Single VM / workstation | **Docker Compose** | Recommended. Single container, two exposed ports. |
| Single VM / workstation | **docker run** | Same image; pass env vars inline. |
| Bare metal | Python (backend) + Node (frontend) | Manual setup; see README Option 2. |
| Kubernetes | Deployment + PVC | Works; overkill for single-user use. |

## Inputs to collect

| Input | Example | Phase | Notes |
|---|---|---|---|
| LLM API key | `AIza...` (Google) or `sk-...` (OpenAI) | preflight | At least one of GOOGLE_API_KEY or OPENAI_API_KEY required. |
| Embedder type | `google` or `openai` (default) or `ollama` | preflight | Match embedder to your primary LLM provider for consistency. |
| OpenRouter API key (opt) | `sk-or-...` | LLM | Access Claude, Llama, Mistral, etc. via one key. |
| Azure OpenAI config (opt) | endpoint + key + version | LLM | For Azure-hosted models. |
| Ollama host (opt) | `http://ollama-server:11434` | LLM | Local model inference; defaults to localhost. |
| Port | 8001 (API), 3000 (UI) | network | Default. Change PORT env var to shift API port. |
| Data volume | `~/.adalflow` | storage | Repo clones + embeddings; persist across restarts. |

## Install via Docker Compose (recommended)

```bash
git clone https://github.com/AsyncFuncAI/deepwiki-open.git
cd deepwiki-open

# Create .env with your API keys
cat > .env << 'EOF'
GOOGLE_API_KEY=your_google_api_key
OPENAI_API_KEY=your_openai_api_key
# Recommended if using Google models for generation:
DEEPWIKI_EMBEDDER_TYPE=google
# Optional: OpenRouter for access to Claude/Llama/Mistral
OPENROUTER_API_KEY=your_openrouter_api_key
# Optional: Ollama (local inference)
OLLAMA_HOST=http://localhost:11434
# Optional: Azure OpenAI
AZURE_OPENAI_API_KEY=your_key
AZURE_OPENAI_ENDPOINT=https://your-resource.openai.azure.com
AZURE_OPENAI_VERSION=2025-01-01-preview
EOF

docker-compose up
```

Open <http://localhost:3000>. Enter a repo URL (e.g. `https://github.com/openai/codex`) and click **Generate Wiki**.

## Install via docker run (no compose)

```bash
docker pull ghcr.io/asyncfuncai/deepwiki-open:latest

docker run -d --name deepwiki \
  -p 8001:8001 \
  -p 3000:3000 \
  -e GOOGLE_API_KEY=your_google_api_key \
  -e OPENAI_API_KEY=your_openai_api_key \
  -e DEEPWIKI_EMBEDDER_TYPE=google \
  -v ~/.adalflow:/root/.adalflow \
  ghcr.io/asyncfuncai/deepwiki-open:latest
```

## Private repositories

Click "+ Add access tokens" in the web UI and enter a GitHub or GitLab personal access token. Tokens are stored in browser session only (not persisted server-side).

## Embedder types

| Type | Env var required | Notes |
|---|---|---|
| `openai` (default) | `OPENAI_API_KEY` | Uses `text-embedding-3-small` |
| `google` | `GOOGLE_API_KEY` | Uses `text-embedding-004`; recommended with Gemini |
| `ollama` | none | Requires Ollama running; set `OLLAMA_HOST` |

Use `google` embeddings when generating with Gemini models for better semantic consistency.

## Data layout

| Path (host) | Container path | Content |
|---|---|---|
| `~/.adalflow/repos/` | `/root/.adalflow/repos/` | Cloned repository source |
| `~/.adalflow/` (other) | `/root/.adalflow/` | Embedding cache, index files |
| `./api/logs/` | `/app/api/logs/` | Application log files |

## Resource limits (compose default)

- Memory limit: 6 GB
- Memory reservation: 2 GB

Adjust in `docker-compose.yml` for your hardware.

## Upgrade

```bash
cd deepwiki-open
git pull
docker-compose pull
docker-compose up -d
```

Embedding cache in `~/.adalflow/` survives upgrades. Re-index only if upstream changes the embedding model.

## Gotchas

- **At least one LLM key required.** DeepWiki won't generate wikis without a working LLM provider. Google Gemini and OpenAI keys are the most-tested paths.
- **Embedder ≠ generator mismatch is subtle.** If you generate with Gemini but embed with OpenAI, retrieval quality drops. Match them: `DEEPWIKI_EMBEDDER_TYPE=google` when using Gemini models.
- **Large repos = slow first generation.** Cloning and embedding a monorepo can take several minutes. Subsequent visits use the cache.
- **Private token security.** Tokens are passed in-browser and never stored server-side, but they are sent to the API backend over localhost. Don't run this instance on a shared/public machine without network isolation.
- **Memory: 2 GB minimum.** The compose file caps at 6 GB; large repos with full embeddings can approach that limit. Reduce if hosting on a small VPS.
- **No built-in auth.** The web UI has no login gate. Expose only on localhost or put it behind an auth proxy (Authelia, Authentik, etc.) if on a shared network.
- **Ollama local inference is slow without GPU.** For CPU-only Ollama, generation will be very slow. Use a cloud LLM key for reasonable performance.
- **Wiki quality depends on LLM.** `gemini-2.5-pro` and `gpt-4o` produce better wikis than small models. Choose your model wisely in the UI provider dropdown.
- **Repo data persists in `~/.adalflow`** across container restarts. Delete this directory to free disk space or force a fresh re-index.
- **Ports 8001 and 3000 must both be open.** The Next.js frontend calls the FastAPI backend directly. If you reverse-proxy only port 3000, the Ask/DeepResearch features will break.

## Links

- Repo: <https://github.com/AsyncFuncAI/deepwiki-open>
- Container image: <https://github.com/AsyncFuncAI/deepwiki-open/pkgs/container/deepwiki-open>
- Ollama integration guide: <https://github.com/AsyncFuncAI/deepwiki-open/blob/main/Ollama-instruction.md>
- Discord: <https://discord.com/invite/VQMBGR8u5v>
