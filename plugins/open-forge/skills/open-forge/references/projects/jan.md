---
name: jan
description: Jan recipe for open-forge. Open-source desktop app for running local LLMs. Privacy-first, offline-first. Download and run GGUF models with no telemetry. macOS, Windows, Linux.
---

# Jan

Open-source desktop application for running local LLMs. Privacy-first and offline-first — all data stays on your machine. Download and chat with GGUF (llama.cpp) models, connect to remote APIs, and use an OpenAI-compatible local API server. Available for macOS, Windows, and Linux. Upstream: <https://github.com/janhq/jan>. Docs: <https://jan.ai/docs>.

## Compatible install methods

| Method | When to use |
|---|---|
| Desktop installer (recommended) | macOS, Windows, Linux — GUI + API |
| Microsoft Store | Windows |
| Flatpak | Linux |

## Hardware requirements

| Use case | Minimum |
|---|---|
| CPU inference (GGUF) | 8 GB RAM; any modern CPU |
| GPU inference (CUDA/Metal) | NVIDIA GPU ≥ 4 GB VRAM (CUDA) or Apple Silicon (Metal) |

## Installation

Download the latest release for your OS: <https://jan.ai/download>

| OS | Options |
|---|---|
| macOS | `.dmg` (universal); native Metal acceleration on Apple Silicon |
| Windows | `.exe` installer, Microsoft Store, winget |
| Linux | `.AppImage`, Flatpak (`ai.jan.Jan`) |

## Using Jan

1. Launch Jan → **Hub** tab → browse and download a model (e.g. Llama 3.2, Qwen, Mistral)
2. Select model → **Chat** tab → start chatting
3. Jan downloads the GGUF file and runs inference locally

## Local API server

Jan exposes an OpenAI-compatible API:

1. Go to **Local API Server** tab → click **Start**
2. Default: `http://localhost:1337/v1`

```bash
curl http://localhost:1337/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model": "llama3.2:3b", "messages": [{"role": "user", "content": "Hello!"}]}'
```

Use Jan as a drop-in replacement for OpenAI API in any OpenAI-compatible client (Open WebUI, Continue, etc.)

## Connecting to remote APIs

Jan can also connect to OpenAI, Anthropic, Groq, or any OpenAI-compatible remote API — useful when you want a single chat UI for both local and remote models.

## Software-layer concerns

- All models stored locally at `~/jan/models/`
- No telemetry, no external connections unless you configure remote API providers
- Supported backends: llama.cpp (GGUF), Nitro engine (built-in, optimized llama.cpp wrapper)
- GPU acceleration: CUDA (NVIDIA), Metal (Apple Silicon), Vulkan (AMD/Intel)
- Jan is primarily a **desktop app** — not designed for server/headless deployment; use text-generation-webui or LocalAI for server use

## Upgrade procedure

- Desktop: Jan notifies you of updates in-app; or re-download from jan.ai/download
- Flatpak: `flatpak update ai.jan.Jan`

## Gotchas

- No official Docker image — Jan is a desktop app; headless use requires workarounds
- Model downloads happen through the Hub; you can also manually place GGUF files in `~/jan/models/`
- Large models (70B+) require significant RAM/VRAM — check model card for requirements
- API server starts/stops manually from the UI — it's not always running

## Links

- GitHub: <https://github.com/janhq/jan>
- Docs: <https://jan.ai/docs>
- Download: <https://jan.ai/download>
- Changelog: <https://jan.ai/changelog>
