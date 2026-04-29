---
name: localai-project
description: LocalAI recipe for open-forge. MIT-licensed drop-in replacement REST API for OpenAI / Anthropic / Elevenlabs — runs LLMs, image gen, TTS/STT, embeddings, rerankers, function calling on your own hardware (CPU, NVIDIA CUDA, AMD ROCm, Intel oneAPI, Vulkan, Apple Silicon). Single self-contained binary packaged as a Docker image. Covers CPU-only install, GPU-accelerated variants (CUDA 12/13, ROCm, Intel, Vulkan), model loading from the gallery / Huggingface / Ollama / OCI, P2P swarm mode, and reverse-proxy + API-key hardening.
---

# LocalAI

MIT-licensed drop-in REST replacement for OpenAI / Anthropic / ElevenLabs APIs — runs models locally on consumer or server hardware. Upstream: <https://github.com/mudler/LocalAI>. Docs: <https://localai.io>.

The core claim: point your existing OpenAI-SDK code at `http://localhost:8080/v1` with any dummy API key and it Just Works — same `/v1/chat/completions`, `/v1/embeddings`, `/v1/audio/speech`, `/v1/images/generations` endpoints. Model backends are pluggable: llama.cpp, Gemma, Phi, Llama, whisper.cpp, stable-diffusion, piper, parler-tts, coqui-tts, bark, etc.

**Not just LLMs.** Does text generation, embeddings, reranking, image generation (Stable Diffusion etc.), TTS, STT (Whisper), audio classification, function calling, vision (multimodal), and agent-style workflows.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker CPU (`localai/localai:latest`) | <https://hub.docker.com/r/localai/localai> | ✅ Recommended | Baseline. CPU inference only — slow for 7B+ models. |
| Docker NVIDIA CUDA 12 (`:latest-gpu-nvidia-cuda-12`) | Same repo | ✅ | Most common GPU shape. Needs `nvidia-container-toolkit` + `--gpus all`. |
| Docker NVIDIA CUDA 13 (`:latest-gpu-nvidia-cuda-13`) | Same repo | ✅ | Newer GPUs / DGX Spark. |
| Docker NVIDIA Jetson (`:latest-nvidia-l4t-arm64*`) | Same repo | ✅ | Jetson AGX Orin / similar edge devices. |
| Docker AMD ROCm (`:latest-gpu-hipblas`) | Same repo | ✅ | AMD consumer + datacenter cards. Needs `/dev/kfd` + `/dev/dri` device access. |
| Docker Intel oneAPI (`:latest-gpu-intel`) | Same repo | ✅ | Intel Arc / Xe GPUs via `/dev/dri/renderD128`. |
| Docker Vulkan (`:latest-gpu-vulkan`) | Same repo | ✅ | Cross-vendor GPU fallback when vendor-specific tags don't fit. |
| macOS DMG (`LocalAI.app`) | <https://github.com/mudler/LocalAI/releases> | ✅ | macOS dev / Apple Silicon with Metal acceleration. **Not Apple-signed** — needs `sudo xattr -d com.apple.quarantine`. |
| `local-ai` CLI binary | GitHub releases (per-arch tarball) | ✅ | Bare-metal install without Docker. |
| Build from source | `go build` + platform backends | ✅ | Custom builds. Non-trivial — llama.cpp linking etc. |
| Kubernetes Helm | <https://github.com/go-skynet/helm-charts> | ✅ | Multi-node / enterprise. |

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Install method?" | `AskUserQuestion` | Drives section. |
| preflight | "Accelerator?" | `AskUserQuestion`: `CPU` / `NVIDIA CUDA 12` / `NVIDIA CUDA 13` / `NVIDIA Jetson` / `AMD ROCm` / `Intel oneAPI` / `Vulkan` / `Apple Silicon (Metal)` | Picks the image tag. |
| preflight | "GPU RAM?" | Free-text (e.g. `8GB`, `24GB`, `80GB`) | Constrains which models will fit. Q4-quantized rule of thumb: model size in GB × 0.6 = VRAM needed. |
| models | "Which models? (LLM / embedding / image / TTS / STT)" | Multi-select | Different backends have different resource profiles. |
| storage | "Model cache directory on host?" | Free-text, default `./models` | Mounted as `/build/models`. Can be 10s of GB per model. |
| api | "API key(s)?" | Free-text (sensitive) | Set `API_KEY` env. Without it, the API is UNAUTHENTICATED and anyone with network access can burn your GPU time. |
| dns | "Public domain?" | Free-text | For reverse-proxy TLS. |

## Install — Docker CPU (baseline)

```bash
docker run -ti --rm \
  --name local-ai \
  -p 8080:8080 \
  -v ./models:/build/models \
  -e API_KEY="$(openssl rand -hex 32)" \
  localai/localai:latest
```

Visit `http://localhost:8080` for the WebUI (chat interface + model gallery). API endpoint: `http://localhost:8080/v1`.

## Install — Docker NVIDIA CUDA 12

Requires [nvidia-container-toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html) on the host. Verify:

```bash
docker run --rm --gpus all nvidia/cuda:12.3.0-base-ubuntu22.04 nvidia-smi
```

Then:

```bash
docker run -ti --rm \
  --name local-ai \
  --gpus all \
  -p 8080:8080 \
  -v ./models:/build/models \
  -e API_KEY="$(openssl rand -hex 32)" \
  localai/localai:latest-gpu-nvidia-cuda-12
```

For CUDA 13: swap the tag to `:latest-gpu-nvidia-cuda-13`.

## Install — Docker AMD ROCm

```bash
docker run -ti --rm \
  --name local-ai \
  --device=/dev/kfd \
  --device=/dev/dri \
  --group-add=video \
  -p 8080:8080 \
  -v ./models:/build/models \
  -e API_KEY="$(openssl rand -hex 32)" \
  localai/localai:latest-gpu-hipblas
```

Host needs ROCm installed. Not all consumer AMD cards are supported — check the ROCm compatibility matrix first.

## Install — Docker Intel oneAPI

```bash
docker run -ti --rm \
  --name local-ai \
  --device=/dev/dri/card1 \
  --device=/dev/dri/renderD128 \
  -p 8080:8080 \
  -v ./models:/build/models \
  -e API_KEY="$(openssl rand -hex 32)" \
  localai/localai:latest-gpu-intel
```

## Install — Docker Compose (production shape)

```yaml
# compose.yaml — GPU variant (NVIDIA CUDA 12)
services:
  localai:
    image: localai/localai:latest-gpu-nvidia-cuda-12
    container_name: local-ai
    restart: unless-stopped
    ports:
      - "8080:8080"
    environment:
      API_KEY: ${API_KEY}
      THREADS: ${THREADS:-4}
      CONTEXT_SIZE: ${CONTEXT_SIZE:-4096}
      DEBUG: "false"
      MODELS_PATH: /build/models
      # P2P mode — optional, lets multiple LocalAI instances federate
      # LOCALAI_P2P: "true"
      # LOCALAI_P2P_TOKEN: ...
    volumes:
      - ./models:/build/models
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all
              capabilities: [gpu]
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--spider", "http://localhost:8080/readyz"]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 60s
```

```bash
echo "API_KEY=$(openssl rand -hex 32)" > .env
docker compose up -d
docker compose logs -f localai
```

## Install — macOS DMG

```bash
# Download from https://github.com/mudler/LocalAI/releases/latest
# Install LocalAI.app to /Applications

# DMG is not Apple-signed — clear quarantine:
sudo xattr -d com.apple.quarantine /Applications/LocalAI.app

open /Applications/LocalAI.app
```

Metal acceleration is auto-enabled on Apple Silicon.

## Loading models

Four supported sources, all via the CLI inside the container (or the WebUI at `:8080`):

```bash
# Inside the container (or via `docker exec`):

# 1. From the built-in gallery (curated upstream)
local-ai run llama-3.2-1b-instruct:q4_k_m
# List available: local-ai models list
# Or browse: https://models.localai.io

# 2. From Huggingface directly
local-ai run huggingface://TheBloke/phi-2-GGUF/phi-2.Q8_0.gguf

# 3. From Ollama's OCI registry
local-ai run ollama://gemma:2b

# 4. From a custom YAML config (most flexible — defines backend, parameters, templates)
local-ai run https://gist.githubusercontent.com/.../phi-2.yaml

# 5. From a generic OCI registry (Docker Hub etc.)
local-ai run oci://localai/phi-2:latest
```

Alternatively drop YAML config files in `./models/` on the host and LocalAI auto-discovers them on startup. Example `models/phi-2.yaml`:

```yaml
name: phi-2
context_size: 4096
parameters:
  model: huggingface://TheBloke/phi-2-GGUF/phi-2.Q4_K_M.gguf
  temperature: 0.7
backend: llama-cpp
```

## Using the API

After a model is loaded, LocalAI exposes OpenAI-compatible endpoints:

```bash
# List loaded models
curl http://localhost:8080/v1/models -H "Authorization: Bearer $API_KEY"

# Chat completion (OpenAI SDK compatible)
curl http://localhost:8080/v1/chat/completions \
  -H "Authorization: Bearer $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "llama-3.2-1b-instruct:q4_k_m",
    "messages": [{"role": "user", "content": "hello"}]
  }'

# Embeddings
curl http://localhost:8080/v1/embeddings \
  -H "Authorization: Bearer $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model": "bert-embeddings", "input": "the quick brown fox"}'

# Image gen
curl http://localhost:8080/v1/images/generations \
  -H "Authorization: Bearer $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model": "stablediffusion", "prompt": "a duck on the moon"}'
```

Point any OpenAI SDK at `http://localhost:8080/v1` with this API key — it'll work.

## Reverse proxy (Caddy example)

```caddy
ai.example.com {
    reverse_proxy 127.0.0.1:8080
}
```

⚠️ Adjust timeouts at the proxy — LLM responses can stream for minutes. For nginx: `proxy_read_timeout 600s; proxy_send_timeout 600s; proxy_buffering off;` (buffering off is required for SSE streaming).

## P2P swarm mode (optional)

LocalAI supports peer-to-peer federation where multiple instances share model inference load:

```bash
docker run -ti -p 8080:8080 \
  -e LOCALAI_P2P=true \
  -e LOCALAI_P2P_TOKEN="<shared-token>" \
  localai/localai:latest-gpu-nvidia-cuda-12
```

Peers discover each other via libp2p DHT. Use when you have multiple GPU hosts and want to pool them for one API endpoint.

## Data layout

| Path | Content |
|---|---|
| `./models/` (host) → `/build/models/` (container) | Model files (`.gguf`, `.bin`, `.safetensors`, …) + per-model YAML configs. Many GB per model. |
| `./models/gallery.yaml` | If present, overrides the upstream model gallery catalog. |

## Upgrade procedure

```bash
# 1. Back up ./models/ if you've added custom YAML configs
cp -a models models.bak.$(date +%F)

# 2. Pull new image
docker compose pull
docker compose up -d

# 3. Check logs + models still load
docker compose logs -f localai
curl http://localhost:8080/readyz
```

Model formats (GGUF, safetensors) are backward-compatible across LocalAI versions. Check release notes for backend changes: <https://github.com/mudler/LocalAI/releases>.

## Gotchas

- **Default = unauthenticated API.** Without `API_KEY`, anyone on the network can burn your GPU/CPU time. ALWAYS set `API_KEY` before exposing port 8080 beyond localhost.
- **Model files are huge.** A 7B Q4 GGUF is ~4GB; a 70B Q4 is ~40GB. Check disk space before `local-ai run` — the gallery will silently fail if disk is full.
- **VRAM overflow = silent fallback to CPU.** If a model exceeds GPU RAM, LocalAI might keep running but on CPU (10-100x slower). Monitor `nvidia-smi` to confirm the model is actually on GPU.
- **CUDA 12 vs 13 mismatch.** If the host driver supports only CUDA 12 but you pull `-cuda-13`, the container runs but doesn't see the GPU. Match tag to driver: `nvidia-smi` → top-right "CUDA Version" is max supported.
- **CPU image is SLOW.** 7B models at ~2-5 tokens/sec on a modern CPU. For interactive use, you want a GPU image.
- **Model loading is lazy.** First request after startup triggers model load, which can take 30s-several-minutes for large models. Subsequent requests are fast. Use the `/readyz` endpoint to check if a model is ready.
- **Context size matters for VRAM.** `CONTEXT_SIZE=32768` on a 7B model roughly doubles VRAM vs. `CONTEXT_SIZE=4096`. Tune based on your hardware.
- **Intel oneAPI needs the correct `renderD*` device.** Run `ls /dev/dri/` on the host — the render node number varies (`renderD128`, `renderD129` etc. for multi-GPU systems).
- **ROCm support is uneven.** Consumer RX cards (e.g., RX 6700 XT) may need `HSA_OVERRIDE_GFX_VERSION=10.3.0` env tweaks. Datacenter cards (MI series) work out-of-the-box.
- **Macbook quarantine flag.** The DMG is not Apple-signed; `xattr -d com.apple.quarantine` is mandatory. Linked upstream issue: <https://github.com/mudler/LocalAI/issues/6268>.
- **Model gallery vs direct load.** Gallery entries (`llama-3.2-1b-instruct:q4_k_m`) resolve to a specific upstream URL + config. Direct loads (`huggingface://...`) skip the gallery and use bare defaults — you might need to pass extra params (chat template, stop tokens) explicitly.
- **Streaming + nginx buffering = broken.** If `/v1/chat/completions` with `"stream": true` hangs, the reverse proxy is buffering. Disable `proxy_buffering` or use Caddy.
- **Backend binaries are large.** The `latest` image is several GB; GPU variants 10+ GB. First pull takes time.

## Links

- Upstream repo: <https://github.com/mudler/LocalAI>
- Docs: <https://localai.io>
- Model gallery: <https://models.localai.io>
- Docker Hub: <https://hub.docker.com/r/localai/localai>
- Releases: <https://github.com/mudler/LocalAI/releases>
- Helm charts: <https://github.com/go-skynet/helm-charts>
- Discord: <https://discord.gg/uJAeKSAGDy>
- OpenAI API reference (for the compatible surface): <https://platform.openai.com/docs/api-reference>
