---
name: ai-homelab-bundle
description: AI homelab bundle for open-forge — pairs Ollama (local LLM inference) + Open WebUI (multi-user chat UI) + AnythingLLM (RAG-focused workspace) + Aider (terminal pair-programming) into a single private AI stack. Recommended for users who want ChatGPT-equivalent capability self-hosted, with no data leaving the host. Designed for single-VPS / GPU laptop / Mac mini / Apple Silicon Studio. Localhost-by-default; reverse proxy / TLS up to the user.
---

# AI homelab bundle

> **Goal:** A private AI homelab — local LLMs, multi-user chat UI, RAG over your own documents, and a terminal pair-programmer — all on one box, no cloud LLM calls.

## What you get

| Service | Port | Role |
|---|---|---|
| **Ollama** | `11434` | LLM inference. Hosts the actual models (Llama / Qwen / Mistral / Gemma / DeepSeek / etc.). Speaks the OpenAI-compatible API. |
| **Open WebUI** | `8080` (or your reverse-proxy hostname) | Multi-user web chat UI. Points at Ollama for inference. Includes built-in RAG, web search, image-gen integration. |
| **AnythingLLM** | `3001` | RAG-focused workspace — drop in PDFs / URLs / GitHub repos / Confluence and ask questions over them. Built-in LanceDB vector store. Points at Ollama for inference + embeddings. |
| **Aider** | (terminal CLI) | AI pair-programmer that runs in your terminal next to a git repo, edits files via diffs, auto-commits. Configured to use Ollama as the LLM provider. |

## When to pick this bundle

- You want ChatGPT-quality chat **without** a cloud-LLM bill or your queries leaving the host.
- You have a machine with reasonable LLM capacity: a GPU-equipped Linux server, a Mac mini M4, an Apple Silicon Studio, an old gaming desktop, or a Linux VPS with at least 16 GB RAM (CPU-only inference is slow but works for smaller models).
- You're comfortable picking your own LLM tradeoffs (model size vs speed vs RAM/VRAM).

## When NOT to pick this bundle

- **You need GPT-5-grade quality.** Local models are very good at what they're good at, but they're not a drop-in replacement for frontier models for hard reasoning / agentic / tool-use tasks. Pair this bundle with API access to a frontier model where it matters.
- **You're on a tiny VPS** (< 8 GB RAM, no GPU). Ollama can technically run, but inference will be glacial — you'll regret it. Either upsize the host or pick smaller models (Qwen2.5-1.5B, Gemma2-2B) and accept the quality drop.
- **You only want one of the four services.** Use the single-recipe path instead: `references/projects/ollama.md`, `references/projects/open-webui.md`, etc.

## Recommended infra / runtime

| Choice | Default | Notes |
|---|---|---|
| **Where** | localhost (your own machine) | The bundle's audience is "I have a machine that's good at this" — homelabs, dev workstations. Cloud GPU VPSs (Hetzner / Lambda / RunPod) work too if that's your shape. |
| **How** | Docker (Compose) | All four services + their data live in one Compose project. Native Ollama install also works (and is simpler on Apple Silicon — pure-binary install). |
| **GPU** | Whichever your host has | Ollama auto-detects: Apple Silicon Metal, NVIDIA CUDA, AMD ROCm. CPU-only fallback works for small models. |

## Constituent recipes (load in this order)

The bundle is the union of these — load each, in this order, and apply the cross-software wiring noted below.

1. **`references/projects/ollama.md`** — foundation; everything else points at it.
2. **`references/projects/open-webui.md`** — depends on Ollama for inference.
3. **`references/projects/anythingllm.md`** — depends on Ollama for inference + embeddings.
4. **`references/projects/aider.md`** — depends on Ollama for inference (or any other OpenAI-compatible).

Each recipe's own gotchas, config knobs, and TODOs apply — the bundle adds cross-software wiring on top, not in place of.

## Cross-software wiring

### Open WebUI ⇄ Ollama

When both run in Docker on the same host:

```yaml
# In your Compose file or Open WebUI's env vars
environment:
  - OLLAMA_BASE_URL=http://ollama:11434      # if both in same Compose network (recommended)
  # OR
  - OLLAMA_BASE_URL=http://host.docker.internal:11434   # if Ollama is on the host (Docker Desktop / OrbStack)
```

When Ollama is native (e.g. Apple Silicon `brew install ollama`) and Open WebUI is in Docker:

```yaml
environment:
  - OLLAMA_BASE_URL=http://host.docker.internal:11434
extra_hosts:
  - "host.docker.internal:host-gateway"   # required on Linux Docker
```

Verify: open Open WebUI → settings → models → confirm the Ollama-hosted models appear without manual config.

### AnythingLLM ⇄ Ollama

In AnythingLLM's settings UI on first login (or pre-staged via env vars):

- **LLM Provider**: Ollama
- **Ollama Base URL**: `http://ollama:11434` (same Compose network) or `http://host.docker.internal:11434`
- **Embedding Engine**: Ollama (or AnythingLLM Native if you prefer the bundled `nomic-embed-text`-equivalent)

### Aider ⇄ Ollama

Aider config (`~/.aider.conf.yml` or `--openai-api-base`):

```yaml
model: ollama/qwen2.5-coder:32b           # pick whichever coder-tuned model you've pulled
openai-api-base: http://localhost:11434/v1
openai-api-key: ollama                     # any non-empty string; Ollama doesn't auth
```

Or shell:

```bash
export OPENAI_API_BASE=http://localhost:11434/v1
export OPENAI_API_KEY=ollama
aider --model ollama/qwen2.5-coder:32b
```

## Combined inputs

Phase order = `preflight → provision (skipped on localhost) → install constituent recipes → bundle wiring → verification`. Inputs to collect across the bundle:

| Phase | Prompt | Source recipe |
|---|---|---|
| preflight | Where? | bundle (default: localhost) |
| preflight | How? | bundle (default: Docker Compose for all four) |
| install (ollama) | Which models to pull on first run? | `ollama.md` — recommend a chat model (Qwen2.5 / Llama 3.x / Gemma 2) + a coder model (Qwen2.5-Coder / DeepSeek-Coder) + an embedding model (`nomic-embed-text`) |
| install (open-webui) | Multi-user mode? Admin email? | `open-webui.md` |
| install (anythingllm) | Vector DB choice? Workspaces to pre-create? | `anythingllm.md` (default LanceDB is fine for the bundle) |
| install (aider) | Pair Aider with which repo(s)? | `aider.md` (this is per-repo config, not bundle-level) |
| wiring | Verify Open WebUI sees Ollama models? | bundle |
| wiring | Verify AnythingLLM sees Ollama models? | bundle |
| wiring | Verify Aider can complete a small edit via Ollama? | bundle |

## Recommended starter Compose

```yaml
# /opt/ai-homelab/compose.yml — adapt paths and image tags to your host
services:
  ollama:
    image: ollama/ollama:latest
    container_name: ollama
    restart: unless-stopped
    ports:
      - "11434:11434"
    volumes:
      - ollama_data:/root/.ollama
    # Uncomment the appropriate GPU stanza for your host:
    # deploy:                  # NVIDIA
    #   resources:
    #     reservations:
    #       devices:
    #         - driver: nvidia
    #           count: all
    #           capabilities: [gpu]

  open-webui:
    image: ghcr.io/open-webui/open-webui:main
    container_name: open-webui
    restart: unless-stopped
    depends_on:
      - ollama
    environment:
      - OLLAMA_BASE_URL=http://ollama:11434
      - WEBUI_SECRET_KEY=${WEBUI_SECRET_KEY:?set in .env}
      - ENABLE_SIGNUP=true            # flip to false after registering admin
    ports:
      - "8080:8080"
    volumes:
      - open_webui_data:/app/backend/data

  anythingllm:
    image: mintplexlabs/anythingllm:latest
    container_name: anythingllm
    restart: unless-stopped
    depends_on:
      - ollama
    cap_add:
      - SYS_ADMIN              # required for AnythingLLM document parsing per upstream
    environment:
      - LLM_PROVIDER=ollama
      - OLLAMA_BASE_PATH=http://ollama:11434
      - EMBEDDING_ENGINE=ollama
      - EMBEDDING_BASE_PATH=http://ollama:11434
      - EMBEDDING_MODEL_PREF=nomic-embed-text
      - STORAGE_DIR=/app/server/storage
    ports:
      - "3001:3001"
    volumes:
      - anythingllm_storage:/app/server/storage

volumes:
  ollama_data:
  open_webui_data:
  anythingllm_storage:
```

After `docker compose up -d`:

```bash
# Pull a chat model + coder model + embedding model into Ollama
docker compose exec ollama ollama pull qwen2.5:14b
docker compose exec ollama ollama pull qwen2.5-coder:14b
docker compose exec ollama ollama pull nomic-embed-text

# Aider config (run on your dev machine — Aider lives where your code lives)
mkdir -p ~/.aider && cat > ~/.aider.conf.yml <<EOF
model: ollama/qwen2.5-coder:14b
openai-api-base: http://localhost:11434/v1
openai-api-key: ollama
EOF
```

## Verification

| Check | Command / browser action | Expected |
|---|---|---|
| Ollama responsive | `curl http://localhost:11434/api/tags` | JSON list of pulled models |
| Open WebUI sees models | Browse to `http://<host>:8080` → log in → model picker | Pulled Ollama models appear |
| AnythingLLM sees models | Browse to `http://<host>:3001` → settings → LLM | Ollama provider connected; model list populates |
| Aider works against Ollama | `cd <some-repo> && aider --message "What does this repo do?"` | Aider responds (slowly on CPU; quickly on GPU) |
| End-to-end RAG | AnythingLLM workspace → drop a PDF → ask a question | Answer references the PDF |

## Bundle gotchas

- **Pick model sizes that actually fit your host.** Ollama will happily try to load a 70B model on 8 GB of RAM and hang the box. Rule of thumb: model size in GB ≈ RAM/VRAM needed. Q4-quantized models are ~half their full-precision size.
- **All four services share the host's Ollama.** Open WebUI doesn't load models — it queries Ollama. Same for AnythingLLM and Aider. Ollama is the only one with model RAM consumption.
- **AnythingLLM needs `SYS_ADMIN` for document parsing** per upstream's Compose example. If you don't grant it, PDF / DOCX uploads silently fail.
- **`WEBUI_SECRET_KEY` must persist across restarts.** Default behavior randomizes per-restart, which logs every Open WebUI user out. Set it explicitly in `.env`.
- **Aider per-repo, not bundle-level.** Aider lives where your code lives — install it on your dev machine pointing at the bundle's Ollama, not on the bundle host.
- **Embedding model must be pulled before AnythingLLM tries to embed.** Pull `nomic-embed-text` (or your chosen embedder) first; otherwise the first document upload errors.
- **First-launch model downloads can take a long time.** A 14B Q4 model is ~8 GB; pull on a fast network before the user is waiting on it.
- **No reverse proxy / TLS shipped in the bundle.** Bundle is localhost-default; if you expose to the internet, front with Caddy / Traefik / Cloudflare Tunnel — see `references/modules/tls-letsencrypt.md` and `references/modules/tunnels.md`.

## Backup

Per `references/modules/backups.md`:

| Service | Backup-relevant paths | Notes |
|---|---|---|
| Ollama | `ollama_data` volume (~/.ollama on host) | Models alone are large but re-pullable; SQLite store of model preferences is small but worth backing up |
| Open WebUI | `open_webui_data` volume | Includes the multi-user DB + uploaded files + RAG indexes |
| AnythingLLM | `anythingllm_storage` volume | LanceDB vectors + workspace metadata + uploaded source docs |
| Aider | (per-repo `.aider.conf.yml` + git history) | Aider state is just git; backed up via your existing repo backups |

restic / borg both work; see backups module.

## Deprovision

```bash
cd /opt/ai-homelab
docker compose down -v       # drops all four services + their data volumes
```

⚠️ `-v` deletes the data volumes (Ollama models, Open WebUI users, AnythingLLM workspaces). Don't run if you want to keep the data.

## TODO — verify on subsequent deployments

- [ ] First end-to-end deploy on Linux + NVIDIA GPU — verify `deploy.resources.reservations.devices` Compose stanza works without manual `nvidia-container-toolkit` install.
- [ ] First end-to-end deploy on Apple Silicon (Mac mini M4) — verify whether Docker for Mac's Metal passthrough is mature enough vs. running Ollama natively + the rest in Docker.
- [ ] Document the WEBUI_SECRET_KEY rotation pattern (today it requires logging users out; needs a graceful migration path).
- [ ] Verify AnythingLLM's `SYS_ADMIN` requirement against current upstream — if they've removed it, drop the `cap_add` from the bundle Compose.
- [ ] Add a "downsize for low-RAM hosts" model-pick table (which models fit in 8 / 16 / 32 / 64 GB RAM).
- [ ] First user feedback on the bundle vs. installing the four recipes one-at-a-time — is the bundle additionally helpful, or just a marketing surface?
