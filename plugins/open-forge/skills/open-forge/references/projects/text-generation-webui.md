---
name: text-generation-webui
description: Text Generation WebUI (TextGen) recipe for open-forge. Open-source desktop app and web UI for running local LLMs. Supports llama.cpp (GGUF), Transformers, ExLlamaV3. OpenAI-compatible API. No telemetry.
---

# Text Generation WebUI (TextGen)

Open-source desktop app and web UI for running local LLMs. 100% offline and private, zero telemetry. Supports GGUF (llama.cpp), Transformers, ExLlamaV3, TensorRT-LLM backends. OpenAI/Anthropic-compatible API, tool-calling, vision, LoRA training, and image generation. Upstream: <https://github.com/oobabooga/text-generation-webui>. Docs: <https://github.com/oobabooga/text-generation-webui/wiki>.

> **Note:** The project was recently rebranded to "TextGen" and repository may move to `oobabooga/textgen`. Check upstream for latest repo URL.

## Compatible install methods

| Method | When to use |
|---|---|
| Portable builds (recommended) | Windows, Linux, macOS; one-click install with all deps |
| Manual Python install | Custom setups, GPU configs, extensions |
| Docker | Server deployment; community-maintained images |

## Hardware requirements

| Use case | Minimum |
|---|---|
| GGUF CPU inference | 8 GB RAM; no GPU needed |
| GGUF GPU (CUDA) | NVIDIA GPU with ≥ 4 GB VRAM |
| Full Transformers | 16 GB RAM + GPU recommended |

## Portable install (recommended)

1. Download the latest release from: <https://github.com/oobabooga/textgen/releases>
2. Choose the build matching your hardware (CUDA, ROCm, Vulkan, or CPU-only)
3. Unzip and double-click `textgen` (or `start_linux.sh` / `start_windows.bat`)

## Manual install

```bash
git clone https://github.com/oobabooga/text-generation-webui
cd text-generation-webui
pip install -r requirements.txt
python server.py --listen
```

With GPU (CUDA):
```bash
python server.py --listen --n-gpu-layers 35
```

## Docker (community image)

```bash
docker run -d \
  -p 7860:7860 \
  -v ./models:/app/user_data/models \
  -v ./loras:/app/user_data/loras \
  atinoda/text-generation-webui:default-nightly
```

Note: No official Docker image from upstream — use community images or run manually.

## Adding models

1. Download a GGUF model file from [Hugging Face](https://huggingface.co/models?pipeline_tag=text-generation&sort=downloads&search=gguf)
2. Place it in `user_data/models/`
3. The UI detects it automatically — select from the **Model** tab

Or download directly from the UI: **Model tab → Download model or LoRA → enter HuggingFace repo/file**

## OpenAI-compatible API

Start with `--api`:
```bash
python server.py --listen --api
```

API available at: `http://localhost:5000/v1/` (OpenAI format)

```bash
curl http://localhost:5000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model": "loaded-model", "messages": [{"role": "user", "content": "Hello"}]}'
```

## Software-layer concerns

- Default port: `7860` (Gradio web UI), `5000` (API when `--api` flag used)
- Backends: llama.cpp (GGUF, recommended), Transformers (HuggingFace), ExLlamaV3 (EXL3), TensorRT-LLM
- Extensions: TTS, voice input, translation — install from **Session tab**
- LoRA training: **Training tab**; supports resuming interrupted runs
- Image generation: built-in **Image Generation tab** using diffusers models
- All data stored locally; no external connections unless you explicitly configure them

## Upgrade procedure

- Portable: re-download latest release and replace files
- Manual: `git pull && pip install -r requirements.txt`

## Gotchas

- Project rebranded from "text-generation-webui" to "TextGen" — check for new repo URL if links break
- `--listen` flag is required to access the UI from non-localhost (e.g., in Docker or remote)
- llama.cpp backend (`--loader llama.cpp`) is fastest for GGUF; use `--n-gpu-layers` to offload layers to GPU
- No official Docker image — community images may lag releases

## Links

- GitHub: <https://github.com/oobabooga/text-generation-webui>
- Releases: <https://github.com/oobabooga/textgen/releases>
- Wiki: <https://github.com/oobabooga/text-generation-webui/wiki>
