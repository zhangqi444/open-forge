---
name: vllm-project
description: vLLM recipe for open-forge — production-grade LLM inference server (github.com/vllm-project/vllm, ~30k★). Different niche from Ollama (single-user / hobby) — vLLM is for high-throughput multi-tenant serving with PagedAttention, tensor parallelism, prefix caching, speculative decoding, and OpenAI-compatible API at port 8000. Pairs with the same downstream consumers as Ollama (OpenClaw / Hermes / Open WebUI / LibreChat / Aider / AnythingLLM) but scales further. Covers every upstream-blessed install method documented under `docs/getting_started/installation/*` and `docs/deployment/*` (verified per CLAUDE.md § *Strict doc-verification policy*): NVIDIA CUDA via pip / uv (canonical), AMD ROCm, Intel XPU/Gaudi, CPU variants (x86 / ARM / Apple Silicon / s390x), Docker (`vllm/vllm-openai`), Kubernetes (raw manifests + Helm chart + LeaderWorkerSet for distributed inference), plus upstream-published PaaS cookbooks for SkyPilot / RunPod / Modal / Cerebrium / dstack / Anyscale / Triton. Pairs with `references/runtimes/{native,docker,kubernetes}.md`.
---

# vLLM

A high-throughput, low-latency LLM inference server. Same role as Ollama (run open-weights LLMs locally), different audience: vLLM is the production path. PagedAttention for efficient KV-cache memory, tensor + pipeline parallelism for multi-GPU serving, continuous batching for throughput, OpenAI-compatible API at `http://<host>:8000/v1`. Where Ollama optimizes for "1 model, 1 GPU, 1 user," vLLM optimizes for "1 model, N GPUs, M concurrent users."

`vllm serve <model>` starts the server. `vllm chat` is a CLI client. The HTTP API speaks both vLLM's native protocol and OpenAI-compatible `/v1/chat/completions` + `/v1/completions` + `/v1/embeddings`.

Upstream: <https://github.com/vllm-project/vllm> — docs at <https://docs.vllm.ai>.

## Compatible combos

Verified against the upstream `docs/getting_started/installation/*` index + `docs/deployment/{docker,k8s}.md` + `docs/deployment/frameworks/{helm,lws,...}.md` per strict-doc policy.

vLLM's deploy surface has two axes: **hardware** (NVIDIA / AMD / Intel / CPU) and **packaging** (pip / Docker / Kubernetes / cloud-PaaS cookbook). Pick one of each.

### Hardware install paths

| Platform | Module | Notes |
|---|---|---|
| **NVIDIA CUDA** (canonical) | `runtimes/native.md` + project section below | `gpu.cuda.inc.md`. Pre-compiled wheels for CUDA 12.9; works on compute capability ≥ 7.5 (T4 / RTX 20xx / A100 / L4 / H100 / B200). |
| **AMD ROCm** | `runtimes/native.md` + project section below | `gpu.rocm.inc.md`. ROCm 6+ on supported Radeon / Instinct cards. |
| **Intel XPU / Gaudi** | `runtimes/native.md` + project section below | `gpu.xpu.inc.md`. Intel Arc + Gaudi accelerators. |
| **CPU — x86** | `runtimes/native.md` + project section below | `cpu.x86.inc.md`. Quantization-friendly; impractical for big models. |
| **CPU — ARM** | `runtimes/native.md` + project section below | `cpu.arm.inc.md`. Graviton / Ampere; experimental. |
| **CPU — Apple Silicon** | `runtimes/native.md` + project section below | `cpu.apple.inc.md`. M-series Macs; experimental, low-throughput. |
| **CPU — IBM Z (s390x)** | `runtimes/native.md` (pointer-only) | `cpu.s390x.inc.md`. Niche; pointer-only in this recipe. |

### Packaging / deployment shape

| Method | Module | Notes |
|---|---|---|
| **pip / uv** (the "native" install on any of the hardware paths above) | `runtimes/native.md` + project section below | Canonical. `uv pip install vllm --torch-backend=auto`. |
| **Docker** (image `vllm/vllm-openai`) | `runtimes/docker.md` + project section below | Pre-built CUDA image; per-platform alternatives exist. Mandatory `--ipc=host` (or `--shm-size`) for shared-memory. |
| **Kubernetes — raw manifests** | `runtimes/kubernetes.md` + project section below | `docs/deployment/k8s.md`. Single-node deploy. |
| **Kubernetes — Helm chart** (first-party) | `runtimes/kubernetes.md` + project section below | `docs/deployment/frameworks/helm.md`. Upstream-blessed chart for production. |
| **Kubernetes — LeaderWorkerSet** | `runtimes/kubernetes.md` + project section below | `docs/deployment/frameworks/lws.md`. Multi-node tensor-parallel / pipeline-parallel inference. |
| **NVIDIA Triton** integration | (PaaS cookbook pointer) | `docs/deployment/frameworks/triton.md`. vLLM as a backend inside Triton Inference Server. |
| **PaaS cookbooks** (SkyPilot, RunPod, Modal, Cerebrium, dstack, Anyscale) | (vendor-managed) | `docs/deployment/frameworks/{skypilot,runpod,modal,cerebrium,dstack,anyscale}.md`. Upstream publishes one-shot deploy patterns for each. |

### Where the integrations cookbooks live (not install methods, but worth knowing)

`docs/deployment/frameworks/` also includes integration cookbooks for using vLLM **as a backend** for downstream clients: `anything-llm.md`, `autogen.md`, `chatbox.md`, `dify.md`, `haystack.md`, `hf_inference_endpoints.md`, `litellm.md`, `lobe-chat.md`, `open-webui.md`, `retrieval_augmented_generation.md`, `streamlit.md`, `bentoml.md`. These pair vLLM with the consumer-side recipe — see *Composing with downstream tools* in *Software-layer concerns* below.

## Inputs to collect

| Phase | Prompt | Tool | Notes |
|---|---|---|---|
| preflight | "What do you want to host?" | (inferred from "vLLM" in user's ask) | — |
| preflight | "Hardware?" | `AskUserQuestion`: NVIDIA GPU (CUDA) / AMD GPU (ROCm) / Intel GPU (XPU) / Intel Gaudi / CPU x86 / CPU ARM / CPU Apple Silicon / IBM Z / Other | Drives the install-path choice |
| preflight | "Where?" | `AskUserQuestion`: AWS GPU EC2 (g5/g6/p4/p5) / Azure NC / DO GPU Droplet / Hetzner GEX / GCP GPU / Oracle / SkyPilot / RunPod / Modal / Cerebrium / dstack / Anyscale / BYO Linux GPU host / localhost / Kubernetes (EKS/GKE/AKS/DOKS) | Loads matching infra adapter or PaaS cookbook |
| preflight | "How?" (dynamic from combo) | `AskUserQuestion`: pip/uv native / Docker / Kubernetes (raw / Helm / LWS) / Triton / PaaS cookbook | — |
| preflight | "Which model(s)?" | Free-text + `AskUserQuestion`: Qwen3 / Llama 3.x / Mistral / DeepSeek / Phi / Gemma / Custom HF repo ID | Drives `--model <hf-repo-id>` flag; bake into image / config |
| preflight | "Tensor-parallel size?" | `AskUserQuestion`: 1 (single GPU) / 2 / 4 / 8 / Match GPU count | `--tensor-parallel-size N` |
| preflight | "Quantization?" | `AskUserQuestion`: None (full precision) / AWQ / GPTQ / FP8 / INT4 / INT8 / KV-cache quantization | Drives `--quantization <name>` + model selection |
| provision | "Public domain?" | Free-text or skip | Triggers reverse proxy via `runtimes/native.md` (vLLM doesn't terminate TLS) |
| provision | "Auth?" | `AskUserQuestion`: None (localhost only) / API key (`--api-key <key>`) / Reverse proxy with auth | Default localhost; API key is the simple auth path |
| provision | "HF token for gated models?" | Free-text (sensitive) | `HF_TOKEN` env var; needed for Llama / gated HF models |

Project-conditional outputs:

| Recorded as | Derived from |
|---|---|
| `outputs.api_url` | `http://<host>:8000/v1` (OpenAI-compatible base URL) |
| `outputs.hardware` | `nvidia-cuda` / `amd-rocm` / `intel-xpu` / `intel-gaudi` / `cpu-x86` / `cpu-arm` / `cpu-apple` / `cpu-s390x` |
| `outputs.install_method` | `pip` / `uv` / `docker` / `k8s-manifest` / `k8s-helm` / `k8s-lws` / `triton` / `paas-<vendor>` |
| `outputs.model` | The HF repo ID (e.g. `Qwen/Qwen3-32B`) |
| `outputs.tensor_parallel_size` | 1 / 2 / 4 / 8 |
| `outputs.quantization` | None / awq / gptq / fp8 / int4 / etc. |

## Software-layer concerns (apply to every install method)

### What `vllm serve` actually does

A single Python process that loads a model into GPU memory (or CPU memory for CPU mode) and exposes an HTTP API. Internals:

- **PagedAttention** for KV-cache memory — packs more concurrent sequences per GB of VRAM than naïve KV-cache implementations. The flagship optimization vLLM is known for.
- **Continuous batching** — concurrent user requests are merged into a single GPU forward pass when their context windows align. Throughput-multiplier vs FastAPI-style "one request per pass."
- **Tensor parallelism** — splits a model's weights across multiple GPUs in the same node (`--tensor-parallel-size N`). Necessary for models that don't fit in a single GPU's VRAM.
- **Pipeline parallelism** — splits a model across multiple nodes' GPUs (`--pipeline-parallel-size N`). For very large models (>1 node of memory).
- **Speculative decoding**, **prefix caching**, **disaggregated serving** (separate prefill + decode engines) — advanced production features; out of scope for first-pass deploys.

### Engine versions: V0 vs V1

vLLM has been migrating from the V0 engine to a newer V1 engine (rewritten for cleaner abstractions, async scheduling, better multi-modal support). At recipe-write time, V1 is on by default for most model families; V0 remains available for compatibility.

Set explicitly with `VLLM_USE_V1=0` (force V0) or `VLLM_USE_V1=1` (force V1). For canonical config, leave default unless a specific feature is V0-only or V1-only.

### Default port + API surface

| Endpoint | Purpose |
|---|---|
| `GET /health` | Liveness probe |
| `GET /version` | Version string |
| `POST /v1/chat/completions` | OpenAI-compatible chat |
| `POST /v1/completions` | OpenAI-compatible legacy completions |
| `POST /v1/embeddings` | OpenAI-compatible embeddings (when serving an embedder model) |
| `GET /v1/models` | List currently loaded models |
| `POST /v1/audio/transcriptions` | OpenAI-compatible Whisper-style STT (when serving an audio model) |
| `POST /v1/score` | Reranking / scoring (vLLM-specific) |
| `POST /tokenize` / `/detokenize` | vLLM-specific token-level ops |

Default bind: `0.0.0.0:8000`. Override with `--host` / `--port`.

### Single model per server

Unlike Ollama, vLLM serves **one model per `vllm serve` invocation**. To serve multiple models, run multiple instances on different ports + put a router in front (LiteLLM Router, OpenRouter-style proxy, or upstream's per-model integrations like the Triton example). The Helm chart treats this with one Deployment per model.

### Critical command-line flags

| Flag | Purpose |
|---|---|
| `--model <hf-repo-id>` | The model to load. Required. e.g. `Qwen/Qwen3-32B`. |
| `--tokenizer <hf-repo-id>` | Override tokenizer if different from model. |
| `--trust-remote-code` | Allow custom modeling code from HF. **Security implication** — only for trusted models. |
| `--host 0.0.0.0` / `--port 8000` | Bind. |
| `--api-key <key>` | Require this Bearer token. **The only built-in auth** vLLM ships. |
| `--tensor-parallel-size N` | Number of GPUs to split a model across (single-node). |
| `--pipeline-parallel-size N` | Number of nodes to pipeline across (multi-node). |
| `--quantization <method>` | `awq` / `gptq` / `fp8` / `int4` / `int8`. Drives memory-vs-quality trade. |
| `--kv-cache-dtype` | `fp8` to halve KV-cache memory at minor quality cost. |
| `--max-model-len N` | Override model's default context length. |
| `--gpu-memory-utilization 0.9` | Fraction of GPU memory to use; tighten on shared boxes. |
| `--max-num-seqs N` | Max concurrent sequences. Higher = more throughput, more memory. |
| `--enable-prefix-caching` | Cache shared prompt prefixes across requests. Big win for chat workloads with system prompts. |
| `--enable-chunked-prefill` | Stream prefill in chunks alongside decode. Improves p50 latency under load. |
| `--speculative-model <smaller-model>` | Use a smaller model to speculate tokens. Lowers latency for free if the small model is good enough. |
| `--load-format <name>` | `dummy` / `safetensors` / `pt` / `runai_streamer`. The streaming loader speeds up cold starts. |
| `--download-dir <path>` | HF cache location. Default `~/.cache/huggingface/`. |
| `HF_TOKEN` env var | Hugging Face token; required for gated models (Llama, etc.). |
| `VLLM_USE_V1=0/1` env var | Force V0 or V1 engine. |
| `VLLM_LOGGING_LEVEL=DEBUG` env var | Verbose logging. |

For the full flag matrix, run `vllm serve --help`. There are 100+ flags; this list is the most-used.

### Hardware sizing realities

| Resource | Why it matters |
|---|---|
| **VRAM** | Drives which models fit. SD 1.5 → 4 GB, Llama 3 70B FP16 → ~140 GB (multi-GPU mandatory), Qwen3 32B int4 → ~24 GB single-GPU. |
| **System RAM** | Same order as VRAM for paging in non-pinned tensors + tokenizer state. Recommend RAM ≥ VRAM. |
| **NVIDIA SM count + memory bandwidth** | Throughput. H100 ≫ A100 ≫ L4 at the same VRAM. |
| **PCIe / NVLink** | Tensor-parallel performance. NVLink between GPUs: near-linear scaling. PCIe-only: 50-70% scaling. |
| **Disk** | First model download is large. Llama 3 70B FP16 ≈ 140 GB. Use a fast SSD; consider `/dev/shm` for tokenizer caches on big-batch workloads. |
| **Network** | OpenAI-API workloads are streaming; latency to clients matters. Co-locate consumers in the same VPC for sub-ms RTT. |

### Security model

vLLM's only built-in auth is `--api-key <key>` — a single shared Bearer token that all clients must send as `Authorization: Bearer <key>`. No multi-user, no per-tenant isolation, no rate limiting. For anything beyond single-tenant private use:

1. **Reverse proxy with proper auth** (Caddy + basicauth, nginx + OAuth2 proxy, Cloudflare Access).
2. **VPC-private** — bind to a private network interface only; clients in the same VPC reach it directly.
3. **Per-tenant routing layer** (LiteLLM Router, OpenRouter-style proxy) — handles per-API-key rate limits + spend tracking + key rotation in front of vLLM.

**`--trust-remote-code` is a real risk**: enabling it lets the model's repo execute arbitrary Python at load. Only use for models you trust (or audit the `modeling_*.py` files yourself).

### Composing with downstream tools

vLLM's OpenAI-compatible API at `http://<host>:8000/v1` plugs into every tool that speaks OpenAI:

| Consumer | How |
|---|---|
| **OpenClaw** | `openclaw.json` → `models.providers.openai.baseUrl: http://<vllm>:8000/v1`. |
| **Hermes-Agent** | Custom OpenAI-compatible provider via `hermes config set`; pair with `openai_api_base`. |
| **Open WebUI** | `OPENAI_API_BASE_URL=http://<vllm>:8000/v1` env. |
| **LibreChat** | `librechat.yaml` → `endpoints.custom` entry with `baseURL: http://<vllm>:8000/v1`. |
| **Aider** | `aider --model openai/<model> --openai-api-base http://<vllm>:8000/v1 --openai-api-key <key>`. |
| **AnythingLLM** | Settings UI → Custom OpenAI provider → base URL + key. |

vLLM's upstream `docs/deployment/frameworks/` ships ready-made cookbooks for: AnythingLLM, AutoGen, Chatbox, Dify, Haystack, HuggingFace Inference Endpoints, LiteLLM, Lobe-Chat, Open WebUI, RAG patterns, Streamlit, BentoML. When wiring a downstream tool, check that frameworks/ subdirectory first — upstream may already have a verified pattern.

---

## NVIDIA CUDA install (canonical)

The default path. Pre-built wheels for CUDA 12.9; covers compute capability ≥ 7.5.

Upstream docs: <https://docs.vllm.ai/en/latest/getting_started/installation/gpu/cuda.html> (sourced from `docs/getting_started/installation/gpu.cuda.inc.md`).

### Hardware requirements

- **GPU compute capability ≥ 7.5** — Tesla T4, RTX 20xx / 30xx / 40xx / 50xx, A100, A10, L4, H100, H200, B200.
- **NVIDIA driver supporting CUDA 12.9** — typically driver ≥ 535 for CUDA 12.x. Verify with `nvidia-smi`.
- **VRAM sized for your target model** (see *Hardware sizing realities* in software-layer concerns above).

### Install — `uv` (recommended)

```bash
# If uv isn't installed:
curl -LsSf https://astral.sh/uv/install.sh | sh

# Create + activate a fresh venv (vLLM strongly recommends a fresh venv per their docs)
uv venv --python 3.12 ~/vllm-venv
source ~/vllm-venv/bin/activate

# Install
uv pip install vllm --torch-backend=auto
```

`--torch-backend=auto` lets uv detect the host's CUDA version + pull the matching PyTorch wheel.

### Install — plain pip (alternative)

```bash
python3.12 -m venv ~/vllm-venv
source ~/vllm-venv/bin/activate

# For CUDA 12.9 (the pre-compiled binary's target)
pip install vllm --extra-index-url https://download.pytorch.org/whl/cu129
```

For older CUDA versions (drivers that don't yet support 12.9), pip-install a different PyTorch CUDA build first, then install vllm:

```bash
# CUDA 12.4 example
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124
pip install vllm
```

The vLLM upstream warns: *"PyTorch installed via conda will statically link NCCL, which can cause issues when vLLM tries to use NCCL"* — prefer pip/uv-installed PyTorch over conda.

### First run — serve a model

```bash
# Pick a model that fits your VRAM
vllm serve Qwen/Qwen3-0.6B            # < 2 GB VRAM
vllm serve Qwen/Qwen3-32B-AWQ         # ~24 GB VRAM (AWQ-quantized)
vllm serve meta-llama/Llama-3.3-70B-Instruct --tensor-parallel-size 4   # 4×A100 80GB

# With API key auth
vllm serve Qwen/Qwen3-0.6B --api-key $(openssl rand -hex 32)

# With prefix caching + chunked prefill
vllm serve Qwen/Qwen3-32B-AWQ \
  --enable-prefix-caching \
  --enable-chunked-prefill \
  --gpu-memory-utilization 0.9
```

First run downloads the model from HuggingFace into `~/.cache/huggingface/`. Watch for the `INFO ... Application startup complete.` line and the API at `http://0.0.0.0:8000`.

### Daemon lifecycle (systemd-user, Linux)

```bash
mkdir -p ~/.config/systemd/user

cat > ~/.config/systemd/user/vllm.service <<'EOF'
[Unit]
Description=vLLM inference server
After=network-online.target

[Service]
Type=simple
WorkingDirectory=%h
EnvironmentFile=%h/vllm.env
ExecStart=%h/vllm-venv/bin/vllm serve Qwen/Qwen3-32B-AWQ \
  --host 0.0.0.0 --port 8000 \
  --enable-prefix-caching \
  --enable-chunked-prefill \
  --gpu-memory-utilization 0.9
Restart=on-failure
RestartSec=10

[Install]
WantedBy=default.target
EOF

# Generate API key + HF_TOKEN env file
cat > ~/vllm.env <<EOF
HF_TOKEN=hf_...
VLLM_API_KEY=$(openssl rand -hex 32)
EOF
chmod 600 ~/vllm.env

systemctl --user daemon-reload
systemctl --user enable --now vllm
sudo loginctl enable-linger "$USER"
journalctl --user -u vllm -f
```

### Updating

```bash
source ~/vllm-venv/bin/activate
uv pip install --upgrade vllm                    # or: pip install --upgrade vllm
systemctl --user restart vllm                    # if running as a service
```

Major-version bumps occasionally introduce breaking flags or default-engine changes (V0 → V1). Read the upstream changelog before upgrading production deploys.

### NVIDIA-CUDA-specific gotchas (vLLM-only)

- **Fresh venv mandatory.** vLLM has very specific PyTorch + CUDA version requirements; mixing into a venv with other ML libs (Transformers, sentence-transformers, custom Torch builds) silently breaks at load time. Upstream calls this out in `gpu.cuda.inc.md`.
- **Conda-installed PyTorch breaks NCCL.** The static linkage in conda's PyTorch package conflicts with vLLM's NCCL usage for tensor parallelism. Use pip/uv.
- **`--gpu-memory-utilization` is fraction, not absolute.** Default 0.9 means "use 90% of free GPU memory." On a shared GPU box, this is too greedy — set explicitly to leave room for other processes.
- **`--tensor-parallel-size N` requires NCCL working between GPUs.** PCIe-only systems work but slowly. NVLink/NVSwitch dramatically improves throughput.
- **HF gated models need `HF_TOKEN`.** Llama, Gemma, and other gated models fail at load with `401 Unauthorized` without the token. Set in env or `--download-token <token>`.
- **First model download is slow + huge.** A 70B FP16 model is ~140 GB. Pre-download with `huggingface-cli download` if you don't want a 30-minute first-startup wait.
- **`compute capability < 7.5`** (Tesla P100, V100, K80, etc.) is unsupported. The pre-compiled wheels won't load. Build from source with custom CUDA targets if you must, but expect bugs.
- **B200 / Blackwell** support is recent — verify your vLLM version >= the release that added Blackwell support (check upstream changelog).
- **`Failed to load shared library libcuda.so`** at import = NVIDIA driver mismatch with the CUDA wheel. `nvidia-smi` should show driver ≥ 535 for CUDA 12.9 wheels.

---

## AMD ROCm install

For AMD Instinct (MI200 / MI250 / MI300) and Radeon (RX 7000 series and newer) GPUs.

Upstream docs: <https://docs.vllm.ai/en/latest/getting_started/installation/gpu/rocm.html> (sourced from `docs/getting_started/installation/gpu.rocm.inc.md`).

### Hardware requirements

- **AMD Instinct** (MI300X / MI300A / MI250X / MI250 / MI210) — production-grade, full feature support.
- **AMD Radeon** RX 7000 series and newer — best-effort; ROCm support varies by chip.
- **ROCm 6.0+** on Ubuntu 22.04 / RHEL 8 / SLES 15.

### Install — recommended path: Docker

The recommended ROCm install path per upstream is the pre-built Docker image (built on top of ROCm-enabled PyTorch). Native pip install requires building vLLM from source against ROCm — fragile, version-sensitive.

```bash
# Pre-built image
docker pull rocm/vllm:latest

docker run -it --rm \
  --device=/dev/kfd \
  --device=/dev/dri \
  --group-add=video \
  --ipc=host \
  --shm-size=8g \
  -v ~/.cache/huggingface:/root/.cache/huggingface \
  -p 8000:8000 \
  rocm/vllm:latest \
  vllm serve Qwen/Qwen3-32B-AWQ
```

`--device=/dev/kfd --device=/dev/dri --group-add=video` are the standard ROCm container flags (same pattern as Ollama's ROCm Docker section). On SELinux-enforcing hosts: `sudo setsebool container_use_devices=1`.

### Install — from source (for cutting-edge ROCm features)

```bash
git clone https://github.com/vllm-project/vllm.git
cd vllm

# Install ROCm-flavored PyTorch first
pip install torch==X.Y.Z+rocmA.B --index-url https://download.pytorch.org/whl/rocmA.B

# Build vLLM
pip install --no-build-isolation -e .
```

ROCm versions move fast; check upstream `gpu.rocm.inc.md` for the current PyTorch + ROCm version pairing at the time of install.

### ROCm-specific gotchas

- **Source build is the painful path.** The Docker image is what upstream actively maintains. Source-build users should expect occasional breakage on ROCm version bumps.
- **MI300 vs Radeon performance gap.** MI300X has datacenter-grade tensor cores + HBM3 memory; consumer Radeon has neither. Same `vllm serve` command, very different throughput.
- **`HSA_OVERRIDE_GFX_VERSION`** for unsupported Radeon cards — same pattern as Ollama. Some cards (RX 5xxx / 6xxx) need this to "look like" a supported gfx target. Verify upstream at first deploy.
- **NCCL → RCCL.** AMD's RCCL replaces NCCL for ROCm; tensor parallelism on AMD requires RCCL working between GPUs (xGMI/Infinity Fabric on Instinct, PCIe on Radeon).
- **No FlashAttention 2 on older ROCm.** Some optimization paths in vLLM are NCCL/NVIDIA-specific and silently disabled on AMD; expect lower throughput vs equivalent-VRAM NVIDIA.

---

## Intel XPU / Gaudi install

For Intel Arc (XPU) consumer + datacenter GPUs and Intel Gaudi accelerators (HPU).

Upstream docs: <https://docs.vllm.ai/en/latest/getting_started/installation/gpu/xpu.html> (sourced from `docs/getting_started/installation/gpu.xpu.inc.md`).

### Hardware

- **Intel Arc** A770, A750, B580 (Battlemage); Pro A60, etc. — consumer + workstation GPUs.
- **Intel Data Center GPU Max** (Ponte Vecchio) — datacenter.
- **Intel Gaudi 2 / Gaudi 3** — HPU (separate accelerator family).

XPU uses Intel's `intel_extension_for_pytorch` (IPEX); Gaudi uses Habana's `optimum-habana` + `habana_frameworks.torch`. Both are different from CUDA and require platform-specific setup.

### Install — Intel XPU

```bash
# Install Intel oneAPI Base Toolkit on the host first (per Intel's docs)
# Then a fresh venv:
uv venv --python 3.12 ~/vllm-xpu-venv
source ~/vllm-xpu-venv/bin/activate

# Intel-specific torch + IPEX (verify versions against upstream gpu.xpu.inc.md)
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/xpu
pip install intel-extension-for-pytorch
pip install vllm
```

Then `vllm serve` works the same — vLLM auto-detects XPU via IPEX.

### Install — Intel Gaudi (HPU)

Gaudi has its own SynapseAI runtime + `habana_frameworks.torch`. Install pattern (per upstream):

```bash
# After Habana SynapseAI is installed on the host (per Habana docs):
pip install habana-torch-plugin
pip install vllm

# Run
PT_HPU_LAZY_MODE=1 vllm serve <model> --device hpu
```

### XPU/Gaudi-specific gotchas

- **Intel oneAPI runtime must be installed on the host first.** vLLM XPU wheels assume `libze_loader.so` + Intel runtime libraries. Check `intel-gpu-tools` package on Ubuntu / `intel-i915` driver on RHEL.
- **Gaudi requires SynapseAI matching the vLLM-supported version.** Habana releases SynapseAI on its own cadence; mismatched versions fail at module load.
- **Performance ceiling lower than NVIDIA at equivalent VRAM** — workable for inference, but for highest throughput at any cost, NVIDIA is still the leader.
- **Multi-card tensor parallel on Gaudi** uses HCCL (Habana's collective lib) instead of NCCL/RCCL. Cluster topology matters for performance; see Habana docs.

---

## CPU install paths

For users with no GPU. Realistic only for small models (≤ 8B) and low-throughput workloads. Documented for completeness; production-grade serving needs GPUs.

Upstream docs: <https://docs.vllm.ai/en/latest/getting_started/installation/cpu.html> (sourced from `docs/getting_started/installation/cpu.md` + per-arch include files).

### CPU x86 (Intel / AMD x86_64)

Per `cpu.x86.inc.md`. Recommended path is the Docker image (pre-built with the right OpenMP / oneDNN / etc. libraries):

```bash
docker pull vllm/vllm-openai:latest-cpu
docker run -it --rm --ipc=host --shm-size=4g \
  -v ~/.cache/huggingface:/root/.cache/huggingface \
  -p 8000:8000 \
  vllm/vllm-openai:latest-cpu \
  vllm serve Qwen/Qwen3-0.6B
```

For source / pip install, follow upstream `cpu.x86.inc.md` — requires building from source with appropriate compiler + Intel MKL or oneDNN linkage.

### CPU ARM (AWS Graviton, Ampere, Apple Silicon Linux)

Per `cpu.arm.inc.md`. Experimental; build from source against ARM-optimized PyTorch:

```bash
pip install torch torchvision torchaudio
pip install vllm
```

Performance is typically 2-4× slower than x86 at equivalent core counts. For Graviton 4 + Neoverse V2 cores with NEON / SVE, performance is workable for embedded use.

### CPU Apple Silicon (macOS M-series)

Per `cpu.apple.inc.md`. Experimental; runs on macOS via PyTorch's MPS backend OR plain CPU. MPS path is faster but has correctness gaps for some operators.

```bash
# Standard install on macOS (Apple Silicon)
brew install python@3.12
python3.12 -m venv ~/vllm-venv
source ~/vllm-venv/bin/activate
pip install torch torchvision torchaudio
pip install vllm
```

Treat as "vLLM on a laptop for development" — production deploys belong on actual GPUs.

### CPU IBM Z (s390x)

Per `cpu.s390x.inc.md`. Niche — z/Linux on IBM mainframes. Build from source against IBM's MASS math library. Pointer-only in this recipe; defer to upstream docs if a user actually has this hardware.

### CPU-specific gotchas

- **CPU is impractical for production.** A 7B model at 5-10 tok/s on a 32-core CPU vs 100+ tok/s on a single A100. Use CPU paths for testing the install + small models only.
- **`--enforce-eager`** is recommended on CPU. CPU compilation paths are slow + buggy compared to NVIDIA's; eager mode bypasses the compiled CUDA kernels.
- **OpenMP threading vs vLLM threading** can fight. Set `OMP_NUM_THREADS` to match the physical core count, not hyperthreaded count.
- **Quantization helps a lot on CPU.** Int4 + AWQ models run 3-5× faster than FP16 on CPU. Look for pre-quantized model variants on HF.
- **`--device cpu`** is sometimes needed to force CPU when the host has a GPU but you want CPU-only behavior (debugging).

---

## Docker

Pair with [`references/runtimes/docker.md`](../runtimes/docker.md) for host-level Docker install + NVIDIA Container Toolkit setup.

Upstream docs: <https://docs.vllm.ai/en/latest/deployment/docker.html> (sourced from `docs/deployment/docker.md`). Image: `vllm/vllm-openai` on Docker Hub (with hardware-specific tags + variants).

### NVIDIA — pre-built `vllm/vllm-openai`

The canonical Docker path. Pre-built CUDA image + the OpenAI-compatible API server entrypoint.

```bash
docker pull vllm/vllm-openai:latest

docker run --runtime nvidia --gpus all \
  -v ~/.cache/huggingface:/root/.cache/huggingface \
  --env "HF_TOKEN=$HF_TOKEN" \
  -p 8000:8000 \
  --ipc=host \
  vllm/vllm-openai:latest \
  --model Qwen/Qwen3-0.6B
```

The `vllm/vllm-openai` image's entrypoint **is** `vllm serve` — flags after the image name pass straight through. So `--model Qwen/Qwen3-0.6B` becomes `vllm serve --model Qwen/Qwen3-0.6B`.

### Why `--ipc=host` (or `--shm-size`) is mandatory

Per upstream's docker.md: tensor parallelism uses shared memory between worker processes. The container's default `/dev/shm` is too small (~64 MB on most Docker installs). Either:

- **`--ipc=host`** — share the host's IPC namespace. Simplest; works for single-tenant boxes.
- **`--shm-size=8g`** (or larger) — allocate a bigger `/dev/shm` for just this container. Use when host IPC sharing isn't acceptable.

Forgetting this flag manifests as `RuntimeError: shm size too small` or worker hangs during model load. Calls out the #1 Docker gotcha.

### NVIDIA Container Toolkit prereq

`--runtime nvidia --gpus all` requires NVIDIA Container Toolkit on the host. Per Ollama's recipe (and `runtimes/docker.md`):

```bash
# Debian/Ubuntu
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list \
  | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' \
  | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
sudo apt-get update && sudo apt-get install -y nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
```

### docker-compose for production

```yaml
services:
  vllm:
    image: vllm/vllm-openai:latest
    container_name: vllm
    restart: unless-stopped
    ports:
      - "127.0.0.1:8000:8000"
    ipc: host
    volumes:
      - ~/.cache/huggingface:/root/.cache/huggingface
    environment:
      - HF_TOKEN=${HF_TOKEN}
      - VLLM_API_KEY=${VLLM_API_KEY}
    command:
      - --model
      - Qwen/Qwen3-32B-AWQ
      - --tensor-parallel-size
      - "1"
      - --enable-prefix-caching
      - --enable-chunked-prefill
      - --gpu-memory-utilization
      - "0.9"
      - --api-key
      - ${VLLM_API_KEY}
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all
              capabilities: [gpu]
```

```bash
export VLLM_API_KEY=$(openssl rand -hex 32)
echo -e "HF_TOKEN=hf_...\nVLLM_API_KEY=$VLLM_API_KEY" > .env

docker compose up -d
docker compose logs -f vllm
```

### Build from source (when pre-built doesn't fit)

```bash
git clone https://github.com/vllm-project/vllm.git
cd vllm
docker build --target vllm-openai -t vllm-openai:custom .
```

Useful for: pinning to specific PyTorch versions, custom CUDA targets, applying patches, building for ARM hosts.

### Other pre-built variants

- `vllm/vllm-openai:latest-cpu` — CPU-only image (per *CPU x86* section above).
- `rocm/vllm:latest` — AMD ROCm (per *AMD ROCm install* section above).

### Lifecycle

```bash
docker exec -it vllm /bin/bash                              # shell into container
docker logs -f vllm                                         # tail logs
docker compose restart vllm                                 # restart after .env / command changes
docker pull vllm/vllm-openai:latest && \
  docker compose up -d --force-recreate                     # upgrade
```

State (the HF cache + downloaded models) persists in the bind-mounted `~/.cache/huggingface/` — survives container recreates.

### Docker-specific gotchas (vLLM-only)

- **`--ipc=host` or `--shm-size` is mandatory.** Forgetting it = silent worker hangs at tensor-parallel boot.
- **`--runtime nvidia --gpus all` requires NVIDIA Container Toolkit on the host.** Without it, the container falls back to CPU (silently, in some Docker versions) and refuses to load the model with a confusing error.
- **Image tag `:latest` rotates frequently.** For reproducibility, pin to a specific version tag (e.g. `vllm/vllm-openai:v0.6.4`).
- **HF cache survives bind-mount.** Useful, but means model files are root-owned by default; if the host user wants to read them, `chown -R $(id -u):$(id -g) ~/.cache/huggingface`.
- **API key flag duplication.** `--api-key` in the `command:` section sets vLLM's auth; the `VLLM_API_KEY` env var is a different concept (used by clients). Don't confuse them.
- **B200 / Blackwell support** in the pre-built image lags upstream by some weeks; for cutting-edge GPUs, build from source with the right CUDA architecture flag.
- **First model download in the container is slow.** Pre-stage by mounting a populated HF cache from the host; saves 30+ minutes per fresh container.

---

## Kubernetes

Three upstream-blessed Kubernetes paths: raw manifests, the first-party Helm chart, and LeaderWorkerSet (LWS) for distributed inference. Pair with [`references/runtimes/kubernetes.md`](../runtimes/kubernetes.md).

### Raw manifests

Per `docs/deployment/k8s.md`. Single-node deploy as a `Deployment` + `Service` + a PVC for the HF cache.

Upstream docs: <https://docs.vllm.ai/en/latest/deployment/k8s.html>.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: vllm
  namespace: vllm
spec:
  replicas: 1
  selector: { matchLabels: { app: vllm } }
  template:
    metadata: { labels: { app: vllm } }
    spec:
      containers:
        - name: vllm
          image: vllm/vllm-openai:latest
          args:
            - --model
            - Qwen/Qwen3-32B-AWQ
            - --tensor-parallel-size
            - "1"
            - --enable-prefix-caching
            - --gpu-memory-utilization
            - "0.9"
          ports:
            - containerPort: 8000
          env:
            - name: HF_TOKEN
              valueFrom: { secretKeyRef: { name: vllm-secrets, key: HF_TOKEN } }
          resources:
            limits:
              nvidia.com/gpu: 1
          volumeMounts:
            - { name: hf-cache, mountPath: /root/.cache/huggingface }
            - { name: dshm, mountPath: /dev/shm }
      volumes:
        - name: hf-cache
          persistentVolumeClaim: { claimName: vllm-hf-cache }
        - name: dshm
          emptyDir:
            medium: Memory
            sizeLimit: 8Gi
---
apiVersion: v1
kind: Service
metadata: { name: vllm, namespace: vllm }
spec:
  selector: { app: vllm }
  ports:
    - { port: 8000, targetPort: 8000 }
```

Apply with `kubectl apply -f vllm.yaml`. The `dshm` `emptyDir` with `medium: Memory` is the equivalent of `--shm-size` from Docker — required for tensor parallelism even on single-GPU.

### Helm chart (first-party)

Per `docs/deployment/frameworks/helm.md`. Upstream-maintained chart at the `vllm-project/production-stack` repo (verify URL at install time — packaging may have moved).

Upstream docs: <https://docs.vllm.ai/en/latest/deployment/frameworks/helm.html>.

```bash
helm repo add vllm https://vllm-project.github.io/production-stack
helm repo update

kubectl create namespace vllm

helm show values vllm/vllm-stack > /tmp/vllm-defaults.yaml
# Read the values.yaml, customize for model + GPU + ingress

helm upgrade --install vllm vllm/vllm-stack \
  --namespace vllm --create-namespace \
  --set model.modelURL=Qwen/Qwen3-32B-AWQ \
  --set replicaCount=1 \
  --set resources.limits."nvidia\.com/gpu"=1 \
  --set service.type=ClusterIP \
  --set ingress.enabled=true \
  --set ingress.host=vllm.example.com \
  --set persistence.enabled=true \
  --set persistence.size=200Gi
```

Always `helm show values` before installing — the chart's value schema evolves.

### LeaderWorkerSet (LWS) — distributed inference

Per `docs/deployment/frameworks/lws.md`. For models too big for a single node (e.g. Llama 3.1 405B FP16 needing multiple H100 nodes), LWS runs vLLM across multiple pods with leader/worker coordination.

Upstream docs: <https://docs.vllm.ai/en/latest/deployment/frameworks/lws.html>.

```bash
# Install LeaderWorkerSet operator first (Kubernetes SIG project)
kubectl apply --server-side -f https://github.com/kubernetes-sigs/lws/releases/latest/download/manifests.yaml

# Then apply vLLM LWS manifest (per upstream's example)
kubectl apply -f https://raw.githubusercontent.com/vllm-project/vllm/main/examples/online_serving/lws-vllm.yaml
```

The LWS pattern is: one leader pod orchestrates N worker pods, each with `--tensor-parallel-size <N>` for in-node parallelism + `--pipeline-parallel-size <stages>` across pods. Networking via NCCL over the cluster's pod network (or RDMA on platforms that support it).

### Kubernetes-specific gotchas (vLLM-only)

- **`emptyDir { medium: Memory }` for `/dev/shm`** is mandatory for tensor parallelism. Forgetting it = same `shm size too small` error as Docker.
- **GPU node selectors / tolerations.** Most clusters partition GPU nodes from CPU nodes. Add `nodeSelector: { nvidia.com/gpu.present: "true" }` or appropriate tolerations.
- **HF cache PVC sizing.** A 70B model is ~140 GB; size the PVC accordingly + use a fast StorageClass (SSD-backed, not HDD).
- **Probe timeouts on first start.** `vllm serve` can take 5+ minutes to load a large model (download + GPU upload). Set `livenessProbe.initialDelaySeconds: 600` or it gets killed mid-load.
- **`HF_TOKEN` belongs in a Secret.** Never inline it in env vars on the manifest; use `secretKeyRef`.
- **Helm chart and LWS are different production patterns.** Helm = single-node-per-replica + horizontal scaling. LWS = multi-node-per-instance for models bigger than one node. Pick based on model size, not hype.
- **Production Stack is more than just the chart.** vLLM's production-stack repo also includes routing, monitoring (Prometheus + Grafana), and request-coalescing components. Worth deploying alongside if running > 1 vLLM instance.

---

## PaaS / cloud cookbooks (upstream-published deploy patterns)

vLLM upstream publishes deploy patterns for several PaaS-style platforms under `docs/deployment/frameworks/`. These are upstream-blessed in that they live in the canonical docs tree, but each is still a vendor-managed flow — open-forge can read out the steps but can't drive vendor consoles.

| Platform | Upstream cookbook | Notes |
|---|---|---|
| **NVIDIA Triton** | `docs/deployment/frameworks/triton.md` | Use vLLM as a backend inside NVIDIA Triton Inference Server. Fits when an org standardizes on Triton for all model serving. |
| **SkyPilot** | `docs/deployment/frameworks/skypilot.md` | One-shot deploy across any cloud (AWS / GCP / Azure / Lambda Labs / RunPod) via SkyPilot's YAML spec. Best when you want vendor portability. |
| **RunPod** | `docs/deployment/frameworks/runpod.md` | Cheap GPU-by-the-hour. RunPod's Docker template + SSH-in pattern. |
| **Modal** | `docs/deployment/frameworks/modal.md` | Serverless GPU. Per-second billing; cold-start tradeoffs. Native Python integration via Modal's decorators. |
| **Cerebrium** | `docs/deployment/frameworks/cerebrium.md` | Similar to Modal — serverless GPU, Python-native deploy. |
| **dstack** | `docs/deployment/frameworks/dstack.md` | Open-source orchestrator for cloud GPU dev/serve. Bring-your-own-cloud, with a unified UX. |
| **Anyscale** | `docs/deployment/frameworks/anyscale.md` | Ray-based deploy on Anyscale's managed Ray clusters. For users already using Ray Serve. |

For each: the upstream doc is the source of truth at first use. open-forge's role is "point user at the right cookbook + warn about platform-specific gotchas (cold starts, billing, GPU availability)."

### Picking the right PaaS

| Use case | Recommended |
|---|---|
| "Bursty traffic, pay per second, don't manage infra" | Modal or Cerebrium |
| "Cheap GPU rental for testing / hobby" | RunPod |
| "Multi-cloud portability without vendor lock-in" | SkyPilot |
| "Already operating Ray clusters" | Anyscale |
| "Already standardized on Triton" | Triton integration |
| "On-prem or BYO cloud with consistent dev/serve UX" | dstack |
| "Production fleet with custom orchestration" | (drop the PaaS layer; use Helm or LWS on EKS/GKE/AKS) |

### Cookbook caveats

- **Each cookbook lags upstream vLLM.** Cookbooks pin specific vLLM versions / image tags. Verify against current vLLM at first deploy; for production, pin to a known-good vLLM version + the cookbook's reference template.
- **Cold start times vary wildly.** Modal / Cerebrium have ~30-60 s cold starts for big models. RunPod has 0 s if you're paying per hour. SkyPilot is "however long the cloud takes to boot a GPU VM" (5-10 min on AWS).
- **Pricing models differ.** Per-second (Modal / Cerebrium) can be cheaper for spiky workloads; per-hour (RunPod / SkyPilot) cheaper for sustained.

---

## Per-cloud / per-PaaS pointers

vLLM is GPU-bound for any practical use; the infra adapter is whatever exposes a usable GPU.

| Where | Adapter | Recommended path |
|---|---|---|
| AWS EC2 (g5/g6/p4/p5/p5e) | `infra/aws/ec2.md` | NVIDIA AMI + Docker (`vllm/vllm-openai`) |
| Azure NC-series VMs | `infra/azure/vm.md` | Same; NCv4 / ND H100 v5 for production |
| Hetzner GEX (NVIDIA) | (use byo-vps with their GEX line) | Docker; cost-effective for hobby + small-scale prod |
| DigitalOcean GPU Droplets | `infra/digitalocean/droplet.md` | Docker + `--gpus=all` |
| GCP Compute Engine (a2/a3/g2) | `infra/gcp/compute-engine.md` | NVIDIA driver pre-loaded on GPU images; pip install or Docker |
| Oracle Cloud BM.GPU | `infra/oracle/free-tier-arm.md` (no GPU on free tier — use the Oracle compute UI for paid GPU) | Docker |
| BYO Linux VPS / on-prem | `infra/byo-vps.md` | Whatever GPU the box has; pair with the matching install-method section above |
| Any Kubernetes cluster (EKS / GKE / AKS / DOKS) | (user-provisioned) | Helm chart (single-node) or LWS (multi-node, large models) |
| **PaaS** (SkyPilot / RunPod / Modal / Cerebrium / dstack / Anyscale / Triton) | (vendor-managed) | Per *PaaS / cloud cookbooks* above |
| localhost (NVIDIA desktop with GPU) | `infra/localhost.md` | pip/uv install; for laptops with single small GPU, prefer Ollama instead |

For **multi-tenant production deploys** (multiple consumers, SLA / rate-limiting / per-API-key billing), pair vLLM with a routing layer (LiteLLM Router, OpenRouter-style proxy, or vLLM's Production Stack). Single-tenant deploys (one model, one team) work fine with bare vLLM + the `--api-key` flag.

---

## Verification before marking `provision` done

- Process running: `systemctl --user is-active vllm` (native) / `docker ps | grep vllm` (Docker) / `kubectl -n vllm rollout status deploy/vllm` (Kubernetes).
- HTTP health: `curl -sIo /dev/null -w '%{http_code}\n' http://127.0.0.1:8000/health` returns `200`.
- Model loaded: `curl -s http://127.0.0.1:8000/v1/models` returns valid JSON listing the configured model.
- Single inference round-trip:
  ```bash
  curl http://127.0.0.1:8000/v1/chat/completions \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $VLLM_API_KEY" \
    -d '{
      "model": "Qwen/Qwen3-32B-AWQ",
      "messages": [{"role": "user", "content": "Say hi"}],
      "max_tokens": 50
    }'
  ```
  Expect a JSON response with the model's reply within a few seconds.
- (NVIDIA) `nvidia-smi` shows the GPU loaded with the model — non-zero VRAM, GPU-Util > 0 during inference.
- (Tensor-parallel) All `--tensor-parallel-size` GPUs show as Utilized in `nvidia-smi` during the round-trip.
- (If composing with downstream tool) The downstream's chat round-trip works through vLLM's `/v1` endpoint.

---

## Consolidated gotchas

Universal:

- **Single model per server.** Unlike Ollama, vLLM serves one model per `vllm serve` invocation. Multi-model needs multiple instances + a router.
- **Fresh venv mandatory.** Mixing into a venv with other ML libs breaks vLLM's specific PyTorch + CUDA + NCCL version requirements.
- **Hardware compute capability ≥ 7.5 for NVIDIA pre-built wheels.** Older GPUs need source builds.
- **`--ipc=host` or `--shm-size`** in Docker is mandatory for tensor parallelism. Forgetting = silent worker hang at boot.
- **Conda PyTorch breaks NCCL.** Use pip/uv-installed PyTorch.
- **HF gated models need `HF_TOKEN`.** Set in env or `--download-token`.
- **`--trust-remote-code` is a real security risk.** Only enable for audited / first-party model repos.
- **First model download is slow + huge.** Pre-stage by downloading via `huggingface-cli download` if you don't want a 30-minute first-startup wait.
- **Single shared API key (`--api-key`) is the only built-in auth.** For multi-tenant, put a router in front.
- **Model loading time can exceed Kubernetes liveness-probe defaults** — set `livenessProbe.initialDelaySeconds: 600` for big models.

Per-method gotchas live alongside each section above:

- **NVIDIA CUDA** — see *NVIDIA-CUDA-specific gotchas*.
- **AMD ROCm** — see *ROCm-specific gotchas*.
- **Intel XPU / Gaudi** — see *XPU/Gaudi-specific gotchas*.
- **CPU** — see *CPU-specific gotchas*.
- **Docker** — see *Docker-specific gotchas* + `runtimes/docker.md` § *Common gotchas*.
- **Kubernetes** — see *Kubernetes-specific gotchas* + `runtimes/kubernetes.md` § *Common gotchas*.
- **PaaS** — see *Cookbook caveats*.

---

## TODO — verify on subsequent deployments

- **First end-to-end NVIDIA CUDA install** on a real GPU host (g5.xlarge / Hetzner GEX44 / DO GPU Droplet) — verify uv vs pip install paths, fresh venv hygiene, first model download timing, single inference round-trip.
- **Tensor-parallel across multiple GPUs** — verify `--tensor-parallel-size 2/4` on multi-GPU hosts; verify NCCL communication via NVLink vs PCIe.
- **AMD ROCm Docker path** — never validated. Verify `rocm/vllm:latest` against an Instinct MI300X or Radeon RX 7900 XTX.
- **Intel XPU / Gaudi** — never validated. Verify against an Intel Arc card / Gaudi 2 system.
- **CPU paths** (x86 / ARM / Apple Silicon) — verify the small-model "vLLM on CPU for development" use case.
- **Docker compose with API key auth** — verify the env-var-passing pattern works end-to-end.
- **Kubernetes raw manifests** — verify the `emptyDir { medium: Memory }` shm pattern under load.
- **Helm chart (production-stack)** — verify the chart URL + value schema; deploy a single replica with a small model end-to-end.
- **LeaderWorkerSet (LWS) for distributed inference** — never validated. Test with a model that genuinely needs multi-node (Llama 3.1 405B on 2× 8×H100).
- **HF cache pre-stage** — document the `huggingface-cli download` pattern + the bind-mount-to-Docker pattern.
- **Composing with Open WebUI / LibreChat / OpenClaw / Hermes / AnythingLLM / Aider** — first-run validation of the OpenAI-compatible base-URL + API-key flow per consumer.
- **Speculative decoding + prefix caching + chunked prefill** — verify each optimization actually engages (look for the relevant log lines on startup); benchmark before/after on a real workload.
- **Production Stack monitoring** — Prometheus + Grafana setup per upstream's production-stack repo; verify the metrics are useful for capacity planning.
- **Quantization paths** (AWQ / GPTQ / FP8 / int4) — verify each works on real hardware; document which quants are best for which model families.
- **PaaS cookbooks** (Modal / Cerebrium / RunPod / SkyPilot / dstack / Anyscale / Triton) — never exercised end-to-end. First user to deploy via each should fold gotchas back into the relevant subsection.
- **`VLLM_USE_V1` engine selection** — verify default behavior on current vLLM version; document any V0-only or V1-only feature gaps.
- **Backup + restore** — there's no per-server state to back up (vLLM is stateless beyond the HF cache + downloaded model). Document the "stateless restart" pattern.
