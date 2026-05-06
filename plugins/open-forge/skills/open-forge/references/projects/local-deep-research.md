---
name: local-deep-research
description: Local Deep Research recipe for open-forge. AI-powered research assistant using local LLMs (Ollama) and multi-source search (web, arXiv, PubMed). Docker Compose deploy with optional SearXNG. Upstream: https://github.com/LearningCircuit/local-deep-research
---

# Local Deep Research

AI-powered deep research assistant that runs locally. Uses multiple LLMs and search engines to produce comprehensive, cited research reports. Supports web search, arXiv, PubMed, PDF text extraction, and an encrypted local knowledge base.

4,502 stars · MIT

Upstream: https://github.com/LearningCircuit/local-deep-research
Docker Hub: https://hub.docker.com/r/localdeepresearch/local-deep-research
Docs: https://github.com/LearningCircuit/local-deep-research/tree/main/docs
Docker Compose guide: https://github.com/LearningCircuit/local-deep-research/blob/main/docs/docker-compose-guide.md

## What it is

Local Deep Research (LDR) is an agentic research tool:

- **Agentic search** — Iteratively searches multiple sources, synthesizes findings, and generates cited reports
- **Multi-source** — Web, arXiv, PubMed, Wikipedia, local files, custom URLs
- **Local LLMs** — Works with Ollama (local models), OpenAI, Anthropic, and other providers
- **Encrypted storage** — Research history stored in SQLCipher-encrypted SQLite database
- **PDF extraction** — Reads and cites PDF documents
- **Web UI** — Clean browser interface for submitting research queries and reading reports
- **Privacy-first** — Runs entirely locally; no data sent to external services when using Ollama

## Compatible install methods

| Method | Upstream | When to use |
|---|---|---|
| Docker Compose (recommended) | https://github.com/LearningCircuit/local-deep-research/blob/main/docker-compose.yml | Most users — includes Ollama + SearXNG |
| Docker run | https://github.com/LearningCircuit/local-deep-research/blob/main/docs/installation.md | Minimal Docker setup |
| pip | `pip install local-deep-research` | Developers, Python integration |

## Inputs to collect

| Phase | Prompt | Applicability |
|---|---|---|
| llm | "Use local Ollama models or a cloud provider (OpenAI, Anthropic)?" | All |
| model | "Which Ollama model? (e.g. llama3, mistral, gpt-oss:20b)" | If using Ollama |
| search | "Use SearXNG for web search (recommended) or direct web search?" | All |
| api_keys | "OpenAI/Anthropic API key?" | If using cloud LLMs |

## Docker Compose install (recommended)

Upstream: https://github.com/LearningCircuit/local-deep-research/blob/main/docs/docker-compose-guide.md

### 1. Download docker-compose.yml

    mkdir -p /opt/ldr && cd /opt/ldr
    curl -O https://raw.githubusercontent.com/LearningCircuit/local-deep-research/main/docker-compose.yml

### 2. Start the stack

    docker compose up -d

This starts:
- `local-deep-research` — Main app on port 5000
- `ollama` — Local LLM server on port 11434
- `searxng` — Private search engine on port 8080

Wait ~30 seconds for startup, then open http://localhost:5000

### 3. Pull an Ollama model

    # Pull a model (examples)
    docker exec ollama ollama pull llama3.2
    docker exec ollama ollama pull mistral
    docker exec ollama ollama pull gpt-oss:20b   # GPT-class open model

### 4. GPU acceleration (NVIDIA, Linux only)

    curl -O https://raw.githubusercontent.com/LearningCircuit/local-deep-research/main/docker-compose.gpu.override.yml
    docker compose -f docker-compose.yml -f docker-compose.gpu.override.yml up -d

NVIDIA Container Toolkit must be installed first: https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html

## Manual Docker run (minimal)

If you already have Ollama and SearXNG running separately:

    docker run -d \
      --name local-deep-research \
      --restart always \
      -p 5000:5000 \
      --network host \
      -v ldr-data:/data \
      -e LDR_DATA_DIR=/data \
      -e OLLAMA_BASE_URL=http://localhost:11434 \
      -e SEARXNG_URL=http://localhost:8080 \
      localdeepresearch/local-deep-research

## Key environment variables

| Variable | Description |
|---|---|
| `LDR_DATA_DIR` | Data directory for encrypted research history |
| `OLLAMA_BASE_URL` | Ollama API endpoint (default: http://ollama:11434) |
| `SEARXNG_URL` | SearXNG instance URL for web search |
| `OPENAI_API_KEY` | OpenAI API key (if using GPT models) |
| `ANTHROPIC_API_KEY` | Anthropic API key (if using Claude) |
| `LDR_BOOTSTRAP_ALLOW_UNENCRYPTED` | Set to `true` to use plain SQLite instead of SQLCipher |

Full environment reference: https://github.com/LearningCircuit/local-deep-research/blob/main/docs/docker-compose-guide.md

## Using the web UI

1. Open http://localhost:5000
2. Enter a research question in the search bar
3. Select depth (quick/standard/deep) and model
4. Submit — LDR iteratively searches, reads sources, and builds a cited report
5. View, download, or save reports

## pip install (alternative)

    pip install local-deep-research

    # Start the server
    ldr-server

Open http://localhost:5000

**Note**: pip install includes pre-built SQLCipher wheels — no manual compilation needed.

## Upgrade

    docker compose pull
    docker compose up -d

## Gotchas

- **Ollama model must be pulled first** — The Docker Compose stack starts Ollama but doesn't automatically pull a model. Run `docker exec ollama ollama pull llama3.2` after startup.
- **SearXNG dramatically improves search quality** — Without SearXNG, LDR falls back to basic web search. The Docker Compose setup includes SearXNG; use it.
- **`--network host` for Docker run** — The standalone `docker run` uses `--network host` so the container can reach local Ollama and SearXNG. Adjust if running in an isolated network.
- **GPU memory** — Large models (20B+) require substantial VRAM (16+ GB). Use smaller models (7B) on consumer hardware.
- **SQLCipher encryption** — Research history is stored encrypted by default. If you see SQLCipher errors, set `LDR_BOOTSTRAP_ALLOW_UNENCRYPTED=true` to use plain SQLite.
- **Startup time** — First start takes time as Ollama initializes and loads the model. Allow 1–2 minutes before querying.

## Links

- GitHub: https://github.com/LearningCircuit/local-deep-research
- Docker Hub: https://hub.docker.com/r/localdeepresearch/local-deep-research
- Docker Compose guide: https://github.com/LearningCircuit/local-deep-research/blob/main/docs/docker-compose-guide.md
- Installation docs: https://github.com/LearningCircuit/local-deep-research/blob/main/docs/installation.md
- Discord: https://discord.gg/ttcqQeFcJ3
