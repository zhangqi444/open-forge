---
name: llm-harbor
description: Harbor (LLM Harbor) recipe for open-forge. CLI and companion app to spin up a complete local LLM stack with Ollama, Open WebUI, and supporting services via Docker Compose. Source: https://github.com/av/harbor. Website: https://github.com/av/harbor/wiki.
---

# Harbor (LLM Harbor)

CLI and companion app that spins up a complete local LLM stack using Docker Compose. Orchestrates backends (Ollama, llama.cpp, vLLM, etc.), frontends (Open WebUI), and supporting services (SearXNG for web RAG, Speaches for voice, ComfyUI for image generation) — all pre-wired to work together. Designed for zero-config local AI development and experimentation. License: Apache-2.0. Upstream: <https://github.com/av/harbor>. Docs: <https://github.com/av/harbor/wiki>.

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Local workstation / dev machine | Harbor CLI + Docker Compose | Primary use case |
| VPS / home server | Harbor CLI + Docker Compose | Can run headlessly on a server |
| macOS | Harbor CLI (bash) | Works with Docker Desktop or OrbStack |
| Linux | Harbor CLI (bash) | Works with Docker Engine |
| Windows | WSL2 + Harbor CLI | Via WSL2 bash environment |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| services | "Which services to start? (e.g. ollama open-webui searxng speaches)" | See `harbor ls` for full list |
| model | "Default Ollama model to pull?" | e.g. llama3.2, phi4, mistral |
| open_webui_port | "Port for Open WebUI?" | Default: 33801 |
| ollama_port | "Port for Ollama API?" | Default: 11434 |

## Software-layer concerns

- **Docker Engine (or Docker Desktop)** required — Harbor is a wrapper around Docker Compose
- Harbor itself is a bash script; install via `curl | bash` or clone the repo
- All service configs stored in `~/.harbor/` (or the directory set by `harbor config set home.dir`)
- Each service has its own subdirectory with a `docker-compose.yml` and default config
- Services are composited at runtime — Harbor merges multiple compose files
- Persistent data: model weights, chat history, configs all stored in `~/.harbor/`
- Harbor App: optional Electron-based GUI companion for managing services without CLI

### Install Harbor CLI

```bash
# Option 1: curl installer
curl -sfL https://raw.githubusercontent.com/av/harbor/main/install.sh | bash

# Option 2: clone and link
git clone https://github.com/av/harbor.git ~/harbor
cd ~/harbor
./harbor.sh link   # adds 'harbor' to PATH via symlink
```

### Basic usage

```bash
# Start Ollama + Open WebUI
harbor up

# Start with additional services
harbor up searxng speaches

# Pull a model
harbor ollama pull llama3.2

# Open WebUI in browser
harbor open

# List available services
harbor ls

# Stop everything
harbor down

# View logs
harbor logs open-webui

# Run a quick chat (no UI needed)
harbor run llm "What is the capital of France?"
```

### Common service combos

```bash
# Full local AI stack with web search and voice
harbor up searxng speaches

# Image generation
harbor up comfyui

# Code-focused stack
harbor up open-webui ollama
harbor ollama pull codellama

# Alternative backend (llama.cpp)
harbor up llamacpp open-webui

# vLLM for GPU-accelerated inference
harbor up vllm open-webui
```

### Configuration

```bash
# View current config
harbor config ls

# Set a config value
harbor config set ollama.model llama3.2
harbor config set open_webui.port 8080

# View Harbor home directory
harbor config get home.dir
```

### Docker Compose structure (how Harbor works)

Harbor merges service-specific compose files at runtime:

```
~/.harbor/
  ollama/
    docker-compose.yml
  open-webui/
    docker-compose.yml
  searxng/
    docker-compose.yml
    searxng/settings.yml
  ...
```

Each `harbor up <service>` call resolves and merges the relevant compose files, injecting cross-service networking automatically.

## Upgrade procedure

1. **Harbor CLI**: `harbor self-update` (if installed via installer) or `git pull` in the clone directory
2. **Service images**: `harbor pull` to pull latest images for running services
3. **After update**: `harbor down && harbor up` to restart with new images
4. Check release notes: https://github.com/av/harbor/releases

## Gotchas

- **Docker required**: Harbor is purely a Docker Compose orchestrator. Docker Engine or Docker Desktop must be running before any `harbor up` command.
- **First model pull is slow**: Ollama model downloads range from 2 GB (small models) to 70+ GB (large models). Ensure adequate disk space in `~/.harbor/ollama/` and a fast internet connection.
- **GPU passthrough**: For GPU-accelerated inference with vLLM or llama.cpp, install the NVIDIA Container Toolkit (`nvidia-docker2`) and ensure the Docker runtime is configured to use GPUs. Harbor's `vllm` service config includes GPU passthrough by default.
- **Port conflicts**: Default ports (Ollama: 11434, Open WebUI: 33801) may conflict with other local services. Change them with `harbor config set`.
- **macOS file system performance**: On macOS with Docker Desktop, volume mounts for large model weights can be slow. Consider using a dedicated data volume or VirtioFS mode in Docker Desktop settings.
- **WSL2 memory limit**: On Windows/WSL2, Docker Desktop's default memory limit (2 GB) is too low for most LLMs. Increase it in Docker Desktop → Settings → Resources to at least 8 GB.

## Links

- Upstream repo: https://github.com/av/harbor
- Wiki / documentation: https://github.com/av/harbor/wiki
- Installing Harbor: https://github.com/av/harbor/wiki/1.0.-Installing-Harbor
- Harbor services catalog: https://github.com/av/harbor/wiki/2.-Services
- Harbor CLI reference: https://github.com/av/harbor/wiki/3.-Harbor-CLI-Reference
- Discord: https://discord.gg/8nDRphrhSF
- Release notes: https://github.com/av/harbor/releases
