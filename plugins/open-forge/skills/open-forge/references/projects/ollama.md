---
name: ollama-project
description: Ollama recipe for open-forge — local-LLM inference server (`ollama.com`, github.com/ollama/ollama). Single binary that runs `ollama serve` (HTTP API on port 11434) plus a CLI for pulling models from the Ollama library. Foundation layer for every other AI project that needs a local LLM provider — pairs with OpenClaw, Hermes, Open WebUI, LibreChat, AnythingLLM, Aider, etc. Covers every upstream-blessed install method documented under `docs.ollama.com/install/*`: native installers (Linux / macOS / Windows curl-pipe-bash + .dmg + .exe), Docker (CPU + NVIDIA CUDA + AMD ROCm + Vulkan), Kubernetes via the community Helm chart, plus package-manager installs (Homebrew, Pacman, Nix, Flox, Guix, Gentoo). Pairs with `references/runtimes/{docker,native,kubernetes}.md`, `references/infra/*.md`, and the GPU acceleration section below.
---

# Ollama

Run open-weights LLMs locally with a single command. `ollama serve` is an HTTP API on port `11434` (OpenAI-compatible at `/v1`); `ollama pull <model>` pulls from the public library; `ollama run <model>` is the interactive REPL. State lives at `~/.ollama/` (Linux uses `/usr/share/ollama/.ollama/` when running as a system service).

For open-forge's purposes Ollama is a **provider**, not an end-user agent — it composes with every AI agent / chat UI / coding tool that accepts an OpenAI-compatible base URL.

Upstream: <https://github.com/ollama/ollama> — docs at <https://docs.ollama.com>.

## Compatible combos

Ollama documents a per-platform install matrix; open-forge maps it to the existing 3-layer model. The "where" picks any infra adapter (it runs anywhere Linux / macOS / Windows runs); the "how" picks one of these:

| How (runtime / install) | Module | Notes |
|---|---|---|
| **Native installer** (`curl \| sh` on Linux/macOS, `irm \| iex` on Windows) | `runtimes/native.md` + project section below | Default for localhost + most cloud VMs. Auto-installs systemd unit on Linux. |
| **Native manual** (extract `.tar.zst`, write systemd unit yourself) | `runtimes/native.md` + project section below | When the curl installer's defaults don't fit (custom user, non-standard path, air-gapped). |
| **Docker** (`ollama/ollama` image; CPU / NVIDIA / AMD ROCm / Vulkan tags) | `runtimes/docker.md` + project section below | Recommended for cloud VMs and clean teardown; persistent volume at `/root/.ollama`. |
| **Kubernetes / Helm** (community chart) | `runtimes/kubernetes.md` + project section below | Upstream README lists a Helm chart; verify which chart the user means before trusting. |
| **Homebrew** (macOS / Linux) | project section below | Cleaner uninstall than the curl installer. |
| **Nix / NixOS module** | project section below | Declarative installs; flake-based. |
| **Pacman / Gentoo / Flox / Guix** | project section below | Distro-native packages; pointer-only. |

For the **where** axis, pick any infra adapter under `references/infra/`. Hardware concerns (CPU vs NVIDIA vs AMD ROCm vs Apple Metal vs Vulkan) belong to a separate dimension — see *GPU acceleration* below; not every infra has every GPU option.

## Inputs to collect

After cross-cutting preflight (cloud creds when infra ∈ AWS/Azure/Hetzner/DO/GCP; nothing for localhost; SSH details for byo-vps):

| Phase | Prompt | Tool | Notes |
|---|---|---|---|
| preflight | "What do you want to host?" | (inferred from "Ollama" in user's ask) | — |
| preflight | "Where?" | `AskUserQuestion`: AWS / Azure / Hetzner / DO / GCP / Oracle / Hostinger / Pi / macOS-VM / BYO VPS / localhost / Kubernetes | Loads matching infra adapter |
| preflight | "How?" (dynamic from combo table) | `AskUserQuestion`: native / Docker / Kubernetes-Helm / Homebrew / Nix / other-package-manager | Filtered by infra |
| preflight | "GPU?" | `AskUserQuestion`: None (CPU-only) / NVIDIA CUDA / AMD ROCm / Apple Metal (auto on macOS) / Vulkan (experimental) | Drives Docker tag, install extras, env vars |
| preflight | "Bind address?" | `AskUserQuestion`: `127.0.0.1:11434` (default, localhost-only) / `0.0.0.0:11434` (LAN/Internet — requires firewall + auth) / Custom | Default localhost — anything else is a security trade-off |
| provision | "Which model(s) to pre-pull?" | Free-text + `AskUserQuestion`: `llama3.2` / `qwen2.5` / `mistral` / `gemma2` / `phi3` / `Skip — pull later` | First pull is slow (multi-GB); user may want to start with a small model |
| provision (k8s only) | "Helm chart source?" | Free-text | The "Helm chart" mentioned in the README is community-maintained — verify the chart repo URL before installing |

Project-conditional outputs:

| Recorded as | Derived from |
|---|---|
| `outputs.api_url` | `http://<bind>:11434/v1` (OpenAI-compatible base) |
| `outputs.models_dir` | `~/.ollama/models` (user) or `/usr/share/ollama/.ollama/models` (system) |
| `outputs.gpu_path` | `none` / `nvidia` / `amd-rocm` / `apple-metal` / `vulkan` |

## Software-layer concerns (apply to every deployment)

### One binary, two roles

`ollama` is a single binary that does two things:

- **`ollama serve`** — long-running HTTP API server on `127.0.0.1:11434` (configurable). Speaks Ollama's native API at `/api/*` and an OpenAI-compatible API at `/v1/*`.
- **`ollama <subcommand>`** — short-lived CLI: `pull`, `push`, `run`, `list`, `rm`, `cp`, `show`, `ps`, `create`. The CLI talks to the running `serve` process over the same HTTP API.

Both forms share the same model storage. Native installs auto-start `ollama serve` as a systemd unit (Linux) / launchd plist (macOS) / Scheduled Task (Windows); Docker runs `ollama serve` as the container's main process.

### API surface

| Endpoint | Purpose |
|---|---|
| `GET /` | "Ollama is running" — health probe |
| `POST /api/generate` | Native: streaming completion |
| `POST /api/chat` | Native: streaming chat |
| `POST /api/pull` | Pull a model from the library |
| `POST /api/embed` | Embeddings |
| `GET /api/tags` | List installed models |
| `POST /v1/chat/completions` | OpenAI-compatible chat (use this from OpenClaw / Hermes / Aider / Open WebUI) |
| `POST /v1/embeddings` | OpenAI-compatible embeddings |

For agents and chat UIs, point them at `http://<host>:11434/v1` as the OpenAI base URL. Most clients work without an API key; some demand a non-empty placeholder — pass `ollama` or any string.

### Model storage

| OS / install | Default models dir |
|---|---|
| Linux (system service) | `/usr/share/ollama/.ollama/models` |
| Linux (running as your user) | `~/.ollama/models` |
| macOS | `~/.ollama/models` |
| Windows | `C:\Users\<username>\.ollama\models` |
| Docker | `/root/.ollama/models` (mount `ollama` named volume or bind to `~/.ollama`) |

Override with `OLLAMA_MODELS=/some/other/path` — the user running `ollama serve` needs read+write access to that path. Models are large (Llama 3.2 8B ≈ 4 GB; Qwen 2.5 32B ≈ 18 GB; Llama 3.3 70B ≈ 40 GB) — provision disk accordingly.

### Server configuration env vars

Set on the `ollama serve` process (systemd `Environment=`, Docker `-e`, shell export). Most-used:

| Variable | Default | Purpose |
|---|---|---|
| `OLLAMA_HOST` | `127.0.0.1:11434` | Bind address. `0.0.0.0:11434` exposes to all interfaces. **Don't expose publicly without auth in front.** |
| `OLLAMA_MODELS` | (per-OS path above) | Model storage location |
| `OLLAMA_KEEP_ALIVE` | `5m` | How long an idle model stays in VRAM/RAM. `-1` = forever; `0` = unload immediately after request |
| `OLLAMA_MAX_LOADED_MODELS` | `3 × #GPUs` (or `3` on CPU) | Concurrent loaded models cap |
| `OLLAMA_NUM_PARALLEL` | `1` | Parallel requests per loaded model |
| `OLLAMA_MAX_QUEUE` | `512` | Inbound request queue cap |
| `OLLAMA_CONTEXT_LENGTH` | `4096` | Default context window for models that don't specify one |
| `OLLAMA_FLASH_ATTENTION` | unset | `1` enables FlashAttention (faster on supported GPUs) |
| `OLLAMA_KV_CACHE_TYPE` | `f16` | `f16` / `q8_0` / `q4_0` — quantize KV cache to save VRAM |
| `OLLAMA_ORIGINS` | `127.0.0.1`, `0.0.0.0` | Cross-origin allowlist; required if a browser extension or web UI hits the API directly |
| `OLLAMA_DEBUG` | unset | `1` enables verbose logging |
| `OLLAMA_NO_CLOUD` | unset | `1` disables cloud features |
| `HTTPS_PROXY` | unset | Proxy for model pulls (Ollama uses HTTPS for downloads, **never** HTTP — don't set `HTTP_PROXY`) |

GPU-specific env vars live in their own section below.

### Pulling models + the library

```bash
ollama pull llama3.2          # ~4 GB
ollama pull qwen2.5:32b       # ~18 GB
ollama pull mistral           # ~4 GB
ollama list                    # what's installed
ollama show llama3.2           # metadata + Modelfile
ollama rm llama3.2:1b          # free disk
ollama pull --insecure ...     # only for self-signed-cert mirrors; never on the public library
```

The full library is at <https://ollama.com/library>. Tags follow the pattern `<model>:<size>[-<quant>]`, e.g. `qwen2.5:32b-instruct-q4_K_M`. Default (no tag) pulls a sensible mid-quality quant — usually `q4_K_M`.

### Composing with agents and chat UIs

Ollama is the inference layer; agents/UIs sit on top. Point each at `http://<ollama-host>:11434/v1`:

| Consumer | Where to set the base URL |
|---|---|
| **OpenClaw** | `openclaw.json` → `models.providers.openai.baseUrl` (treat Ollama as an OpenAI-compatible provider) |
| **Hermes-Agent** | `hermes config set` with a custom OpenAI-compatible endpoint; see `integrations/providers.md` |
| **Open WebUI** | `OLLAMA_BASE_URL=http://<host>:11434` env var (native Ollama API, not /v1) |
| **LibreChat** | `librechat.yaml` → `endpoints.custom` with `baseURL: http://<host>:11434/v1` |
| **AnythingLLM** | Settings → LLM Provider → Ollama; supply base URL |
| **Aider** | `aider --model openai/<model> --openai-api-base http://<host>:11434/v1` |
| **Continue.dev** | `config.json` → `models[*].apiBase` |

The 64K-context concerns from Hermes and OpenClaw apply: pick an Ollama model with enough context for the agent (`llama3.2` is 128K, `qwen2.5` is 128K, smaller models can be lower) and set `--ctx-size` / `OLLAMA_CONTEXT_LENGTH` accordingly.

### Security model

Ollama has **no built-in auth**. The only defense the server ships is its default localhost bind. Anything beyond that needs:

1. **Reverse proxy with auth in front** (Caddy + basic auth, nginx + OAuth2 proxy, Cloudflare Access) — recommended for any non-localhost exposure.
2. **VPN-only access** (Tailscale, WireGuard) — `ollama serve` binds to `tailscale0` interface or is behind a Tailscale Funnel.
3. **Cloud firewall + private subnet** — the API is only reachable from same-VPC compute (where the agent / chat UI runs).

`OLLAMA_HOST=0.0.0.0:11434` on a public-IP'd host is **anyone-can-burn-your-GPU-time**. Don't ship that without one of the three above.

---

## Native installer (Linux / macOS / Windows)

When the user picks **localhost / any cloud VM → native**. Pair with [`references/runtimes/native.md`](../runtimes/native.md) for OS prereqs and daemon-lifecycle basics.

Upstream docs: <https://docs.ollama.com/linux>, <https://docs.ollama.com/macos>, <https://docs.ollama.com/windows>.

### Linux (curl-pipe-bash)

```bash
# One-line install — auto-detects amd64 vs arm64, sets up systemd unit + ollama user
curl -fsSL https://ollama.com/install.sh | sh

# Verify
ollama -v
sudo systemctl status ollama
```

What the installer does (per upstream `linux.mdx`):

1. Detects arch (`amd64` / `arm64`) and downloads the matching `ollama-linux-<arch>.tar.zst` from `ollama.com/download/`.
2. Extracts to `/usr/lib/ollama/` and `/usr/bin/ollama`.
3. Creates a system user + group `ollama` with home `/usr/share/ollama` and shell `/bin/false`.
4. Adds the calling user to the `ollama` group.
5. Drops a systemd unit at `/etc/systemd/system/ollama.service` and enables/starts it.
6. (If NVIDIA detected) Installs CUDA libraries automatically.

To install AMD ROCm support (separate package, run after the main install):

```bash
curl -fsSL https://ollama.com/download/ollama-linux-amd64-rocm.tar.zst \
    | sudo tar x -C /usr
sudo systemctl restart ollama
```

To pin a specific version (or pre-release):

```bash
curl -fsSL https://ollama.com/install.sh | OLLAMA_VERSION=0.5.7 sh
```

### Linux (manual install — when the curl installer's defaults don't fit)

```bash
# Remove old libs first if upgrading
sudo rm -rf /usr/lib/ollama

# Download + extract
curl -fsSL https://ollama.com/download/ollama-linux-amd64.tar.zst \
    | sudo tar x -C /usr
# (or ollama-linux-arm64.tar.zst on ARM64)

# Create user + systemd unit yourself (see upstream linux.mdx for the full unit file)
sudo useradd -r -s /bin/false -U -m -d /usr/share/ollama ollama
sudo usermod -a -G ollama "$(whoami)"

sudo tee /etc/systemd/system/ollama.service <<'EOF'
[Unit]
Description=Ollama Service
After=network-online.target

[Service]
ExecStart=/usr/bin/ollama serve
User=ollama
Group=ollama
Restart=always
RestartSec=3
Environment="PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now ollama
sudo systemctl status ollama
```

To customize env vars (bind address, model dir, GPU selection), use a systemd drop-in:

```bash
sudo systemctl edit ollama
# Adds an override at /etc/systemd/system/ollama.service.d/override.conf:
# [Service]
# Environment="OLLAMA_HOST=0.0.0.0:11434"
# Environment="OLLAMA_MODELS=/data/models"
# Environment="OLLAMA_KEEP_ALIVE=24h"
sudo systemctl restart ollama
```

### macOS (curl installer or .dmg)

```bash
# One-line — same script as Linux; it detects macOS
curl -fsSL https://ollama.com/install.sh | sh

# Or download the .dmg from https://ollama.com/download/Ollama.dmg
# (drag to /Applications, then `Ollama.app` runs `ollama serve` in the background)
```

The `.dmg` ships a menu-bar app that handles `serve` lifecycle automatically; the curl installer drops `ollama` on PATH and the user runs `ollama serve` themselves (or makes a launchd plist via `runtimes/native.md`). Both leave `~/.ollama/` as the state dir.

### Windows (PowerShell installer or .exe)

```powershell
# One-line PowerShell installer
irm https://ollama.com/install.ps1 | iex

# Or download the .exe from https://ollama.com/download/OllamaSetup.exe
```

Installs Ollama to `C:\Users\<user>\AppData\Local\Programs\Ollama\` and runs `ollama serve` as a Scheduled Task at user login. Models go to `C:\Users\<user>\.ollama\models`.

### Updating

```bash
# Linux / macOS
curl -fsSL https://ollama.com/install.sh | sh

# Windows
irm https://ollama.com/install.ps1 | iex
```

The installer is idempotent — re-running it pulls the latest version, replaces the binary, and restarts the service. Models survive.

### Uninstalling (Linux)

```bash
sudo systemctl stop ollama && sudo systemctl disable ollama
sudo rm /etc/systemd/system/ollama.service
sudo rm "$(which ollama)"
sudo rm -r "$(which ollama | tr 'bin' 'lib')"   # /usr/lib/ollama or wherever
sudo userdel ollama && sudo groupdel ollama
sudo rm -rf /usr/share/ollama                    # destroys all downloaded models
```

### Native-specific gotchas (Ollama-only)

- **First model pull is slow.** A 4 GB model on a 100 Mbps connection takes ~5 min; bigger models proportionally longer. `ollama pull` shows progress; don't kill it mid-pull (resumes are best-effort).
- **Default bind is localhost-only.** Agents on the same host work; agents on a different host need either `OLLAMA_HOST=0.0.0.0:11434` (with a firewall + auth in front) or a tunnel.
- **Linux: the service runs as user `ollama`, not your user.** Files under `OLLAMA_MODELS` need to be readable+writable by the `ollama` user. If you set `OLLAMA_MODELS=/data/llms`, `chown -R ollama:ollama /data/llms` first.
- **Don't set `HTTP_PROXY`** — Ollama only uses HTTPS for model pulls. Setting `HTTP_PROXY` confuses the downloader; use `HTTPS_PROXY` (and `NO_PROXY` for local addresses).
- **systemd `Environment=` vs `EnvironmentFile=`.** A drop-in with multiple `Environment=` lines is fine; if you want to source from a file, use `EnvironmentFile=/etc/ollama.env` (one `KEY=value` per line, no `export`, no quotes).
- **`sudo systemctl edit ollama` is the right way to customize.** Editing `/etc/systemd/system/ollama.service` directly gets blown away on the next `curl ... | sh` upgrade.
- **macOS menu-bar app vs CLI conflict.** Running both `Ollama.app` and `ollama serve` from a terminal binds-twice and the second fails. Pick one.

---

## Docker (any infra where Docker works)

When the user picks **any cloud → Docker** or **localhost → Docker**. Pair with [`references/runtimes/docker.md`](../runtimes/docker.md) for host-level Docker install + lifecycle.

Upstream docs: <https://docs.ollama.com/docker>. Image: `ollama/ollama` on Docker Hub. Tags: `latest` (CPU + bundled CUDA libs + Vulkan), `rocm` (AMD).

### CPU only

```bash
docker run -d \
  --name ollama \
  --restart unless-stopped \
  -v ollama:/root/.ollama \
  -p 127.0.0.1:11434:11434 \
  ollama/ollama
```

`-v ollama:/root/.ollama` uses a named volume (Docker-managed, opaque). For host-inspectable models, bind-mount instead: `-v ~/.ollama:/root/.ollama`. Either survives container recreate.

### NVIDIA GPU

Install [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html) on the host first:

```bash
# Debian/Ubuntu
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey \
  | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -fsSL https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list \
  | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' \
  | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
sudo apt-get update && sudo apt-get install -y nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker

# RHEL/Fedora — same toolkit, different package step
curl -fsSL https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo \
  | sudo tee /etc/yum.repos.d/nvidia-container-toolkit.repo
sudo yum install -y nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
```

Then run with `--gpus=all`:

```bash
docker run -d \
  --name ollama \
  --gpus=all \
  --restart unless-stopped \
  -v ollama:/root/.ollama \
  -p 127.0.0.1:11434:11434 \
  ollama/ollama
```

For NVIDIA Jetson (JetPack), pass `JETSON_JETPACK=5` or `JETSON_JETPACK=6` — the container can't auto-detect:

```bash
docker run -d --name ollama --gpus=all \
  -e JETSON_JETPACK=6 \
  -v ollama:/root/.ollama -p 127.0.0.1:11434:11434 \
  ollama/ollama
```

### AMD GPU (ROCm)

```bash
docker run -d \
  --name ollama \
  --device /dev/kfd --device /dev/dri \
  --restart unless-stopped \
  -v ollama:/root/.ollama \
  -p 127.0.0.1:11434:11434 \
  ollama/ollama:rocm
```

Note the **`:rocm` tag** — different image. SELinux-enforcing distros (Fedora, RHEL, Amazon Linux) need:

```bash
sudo setsebool container_use_devices=1
```

…otherwise `/dev/kfd` and `/dev/dri` aren't accessible inside the container.

### Vulkan (experimental)

Vulkan is bundled in the default `ollama/ollama` image; enable per-container with `OLLAMA_VULKAN=1`:

```bash
docker run -d --name ollama \
  --device /dev/kfd --device /dev/dri \
  -e OLLAMA_VULKAN=1 \
  -v ollama:/root/.ollama \
  -p 127.0.0.1:11434:11434 \
  ollama/ollama
```

To select specific Vulkan devices: `-e GGML_VK_VISIBLE_DEVICES=0,1`. To force CPU: `-e GGML_VK_VISIBLE_DEVICES=-1`.

### Run a model + verify

```bash
docker exec -it ollama ollama pull llama3.2
docker exec -it ollama ollama run llama3.2 "hello"
# Or hit the API:
curl http://127.0.0.1:11434/api/tags
curl http://127.0.0.1:11434/v1/chat/completions \
  -H 'Content-Type: application/json' \
  -d '{"model":"llama3.2","messages":[{"role":"user","content":"hi"}]}'
```

### docker-compose (the realistic production form)

```yaml
services:
  ollama:
    image: ollama/ollama:latest
    container_name: ollama
    restart: unless-stopped
    ports:
      - "127.0.0.1:11434:11434"
    volumes:
      - ollama:/root/.ollama
    environment:
      - OLLAMA_KEEP_ALIVE=24h
      - OLLAMA_MAX_LOADED_MODELS=2
      - OLLAMA_FLASH_ATTENTION=1
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all
              capabilities: [gpu]
    # For AMD ROCm, swap image to ollama/ollama:rocm and:
    # devices:
    #   - /dev/kfd
    #   - /dev/dri
    # (and remove the `deploy.resources.reservations.devices` block)

volumes:
  ollama:
```

`docker compose up -d` to bring up; `docker compose logs -f ollama` to watch first-pull progress.

### Lifecycle

```bash
docker exec -it ollama ollama list
docker exec -it ollama ollama pull qwen2.5:32b
docker logs -f ollama
docker restart ollama
docker pull ollama/ollama:latest && docker compose up -d --force-recreate   # upgrade
```

The named `ollama` volume survives container deletion; `docker volume rm ollama` is the destructive cleanup.

### Docker-specific gotchas (Ollama-only)

- **`:latest` vs `:rocm`** — different builds, not interchangeable. NVIDIA users pull `latest`; AMD ROCm users pull `:rocm`. There is no `:nvidia` tag.
- **`--gpus=all` requires NVIDIA Container Toolkit on the host.** Without it, the container starts but runs on CPU silently. Verify: `docker exec ollama nvidia-smi` should show your GPU.
- **AMD `/dev/kfd` + `/dev/dri` mounts are mandatory for ROCm.** SELinux + AppArmor can block them. Symptom: container starts but models run on CPU.
- **First-time image pull is ~3-5 GB.** On a fresh VPS expect 10+ minutes; subsequent recreates use the local cache.
- **Models persist in the volume; the image is stateless.** A `docker pull` upgrade keeps every model. Wiping models requires `docker volume rm ollama`.
- **`-p 0.0.0.0:11434:11434` exposes to the LAN.** Default `127.0.0.1:11434:11434` is host-local. For LAN/Internet, use a reverse proxy with auth — see *Security model* above.
- **NVIDIA Jetson devices need `JETSON_JETPACK=N`.** Auto-detection doesn't work; the container falls back to CPU silently.
- **GPU memory caps via env vars.** `OLLAMA_MAX_LOADED_MODELS=1` keeps only one model loaded — useful on small VRAM (12 GB or less) to avoid OOM during model swap.

---

## Kubernetes / Helm (community chart)

When the user picks **any k8s cluster → Helm**. Pair with [`references/runtimes/kubernetes.md`](../runtimes/kubernetes.md) for kubectl + Helm prereqs, namespace + Secret hygiene, and ingress patterns.

> **Verify the chart source first.** Ollama upstream's README mentions a Helm chart, but the project does **not** ship a first-party chart at the time of this writing. The most-used community charts are `otwld/ollama-helm` and `cowboysysop/charts/ollama` — confirm with the user which they intend before installing, and treat the install commands below as a template rather than upstream-blessed instructions.

### Prereqs

- A running Kubernetes cluster with `kubectl` connected.
- Helm v3.
- A default `StorageClass` (the chart provisions a PVC for `~/.ollama/`).
- For GPU clusters: NVIDIA GPU Operator or AMD GPU Operator already installed.

### Install (community chart, `otwld/ollama-helm` flavor)

```bash
helm repo add otwld https://otwld.github.io/ollama-helm/
helm repo update

kubectl create namespace ollama

# Inspect defaults before installing
helm show values otwld/ollama > /tmp/ollama-defaults.yaml

helm upgrade --install ollama otwld/ollama \
  --namespace ollama --create-namespace \
  --set ollama.gpu.enabled=true \
  --set ollama.gpu.type=nvidia \
  --set ollama.gpu.number=1 \
  --set persistentVolume.enabled=true \
  --set persistentVolume.size=100Gi \
  --set ollama.models.pull[0]=llama3.2

# AMD ROCm:
# --set ollama.gpu.type=amd  --set image.tag=rocm
```

### Verify + access

```bash
kubectl -n ollama rollout status deploy/ollama
kubectl -n ollama logs deploy/ollama -f
kubectl -n ollama port-forward svc/ollama 11434:11434
# Then point clients at http://localhost:11434
```

For in-cluster consumers (OpenClaw, Hermes, Open WebUI Helm-deployed in the same cluster), use the in-cluster DNS: `http://ollama.ollama.svc.cluster.local:11434`.

### Public exposure (Ingress)

The chart typically supports `ingress.enabled=true`. Pair with cert-manager + an ingress controller; **never** expose without auth. Either use a `ClusterIssuer` for Let's Encrypt or terminate TLS at a cloud LB. Add an OAuth2 proxy or basic-auth annotation to the Ingress — Ollama itself has no auth.

### Kubernetes-specific gotchas (Ollama-only)

- **No first-party Helm chart.** Community charts have differing value schemas (`gpu` vs `resources` vs `nvidia.com/gpu`). The exact `--set` flags above are illustrative; always `helm show values` before the first install.
- **GPU node scheduling.** If your cluster has mixed CPU/GPU nodes, set `nodeSelector` or tolerations so Ollama lands on a GPU node. Stuck pods with `0/N nodes available, … insufficient nvidia.com/gpu` is the classic symptom.
- **PVC reclaim policy.** Default `Delete` reclaim wipes the model cache on `helm uninstall`. For long-lived clusters, switch the StorageClass to `Retain` or take backups before uninstalling.
- **Loopback bind inside the pod doesn't compose.** The chart should default to `OLLAMA_HOST=0.0.0.0:11434` so Service / Ingress can reach the pod IP — verify in the values file before assuming.

---

## Homebrew, Nix, and other package managers

Pointer-only — these are short paths.

### Homebrew (macOS / Linuxbrew)

```bash
brew install ollama
brew services start ollama
```

`brew services` registers a launchd plist that runs `ollama serve` in the background. Cleaner uninstall than the curl installer (`brew uninstall ollama && brew services stop ollama`). Lags upstream by hours-to-days.

### Nix / NixOS

```bash
# Standalone (any Nix user)
nix profile install nixpkgs#ollama
ollama serve &

# NixOS: declarative module
# /etc/nixos/configuration.nix
services.ollama = {
  enable = true;
  acceleration = "cuda";   # "cuda" | "rocm" | false
  host = "127.0.0.1";
  port = 11434;
};
```

Then `sudo nixos-rebuild switch`. The module wraps `ollama serve` in a hardened systemd unit with declarative env-var management.

### Pacman (Arch Linux)

```bash
sudo pacman -S ollama          # CPU-only build
sudo pacman -S ollama-cuda     # NVIDIA build
sudo pacman -S ollama-rocm     # AMD build
sudo systemctl enable --now ollama
```

### Other distros — pointer-only

| Distro / manager | Source-of-truth |
|---|---|
| Gentoo | `app-misc/ollama` ebuild |
| Flox | `flox install ollama` |
| Guix | `guix install ollama` (community channel) |
| Snap | community-maintained snap |

For all of these, `ollama serve` works the same way once installed; configuration via env vars + the relevant init system (systemd / launchd / service manager).

### Package-manager-specific gotchas

- **Distro packages lag upstream.** Ollama ships fast (often weekly); apt/dnf/Homebrew releases follow. For latest models (especially newly-trained ones), use the curl installer or Docker image.
- **`ollama-cuda` vs `ollama-rocm` vs `ollama` on Arch.** Pick the one matching your hardware; the bare `ollama` package is CPU-only and silently runs on CPU even with a GPU present.
- **NixOS `acceleration = "cuda"`** requires `nvidia-driver` already configured at the system level. Set both in the same generation or the module errors out.

---

## GPU acceleration

The single biggest performance lever. Different per vendor; verify against upstream `<https://docs.ollama.com/gpu>` for your specific card before committing to a setup.

### NVIDIA (CUDA)

- **Compute capability ≥ 5.0** required (RTX 30xx/40xx/50xx, Tesla M-series and newer, GeForce GTX 1050 and newer). Driver version ≥ 531.
- Linux: install CUDA drivers via `nvidia-driver` package + verify with `nvidia-smi`. The Ollama curl installer auto-detects and downloads CUDA libs.
- Multi-GPU subset: `CUDA_VISIBLE_DEVICES=0,1` (use UUIDs from `nvidia-smi -L` for stability — numeric IDs can reorder).
- Force CPU: `CUDA_VISIBLE_DEVICES=-1`.
- Suspend/resume bug: post-resume on Linux can lose the GPU; reload with `sudo rmmod nvidia_uvm && sudo modprobe nvidia_uvm`.

### AMD (ROCm)

- Requires **ROCm v7** on Linux. Install via `amdgpu-install` from AMD's docs.
- Wide support across Radeon RX 5000/6000/7000/9000 series + Ryzen AI APUs + Instinct datacenter cards. Full table at the upstream docs.
- Windows ROCm v6.1 supports a narrower set (mostly RX 6000/7000, no APUs).
- Multi-GPU subset: `ROCR_VISIBLE_DEVICES=0,1`.
- For unsupported AMD GPUs, override the LLVM target: `HSA_OVERRIDE_GFX_VERSION=10.3.0` (closest supported to your card; see AMD docs for the mapping table). `HSA_OVERRIDE_GFX_VERSION_0=...` and `_1=...` for per-GPU overrides.
- SELinux: `sudo setsebool container_use_devices=1` is needed in some distros for Docker access to `/dev/kfd` and `/dev/dri`.

### Apple Metal (macOS)

- Auto-detected on Apple Silicon (M1/M2/M3/M4); no config needed.
- Intel Macs fall back to CPU.
- VRAM is shared with system RAM — large models (70B+) need 64+ GB of unified memory.

### Vulkan (experimental)

- Bundled in `ollama/ollama` Docker image and standard binaries; enable per-server with `OLLAMA_VULKAN=1`.
- Useful for Intel Arc GPUs and AMD GPUs that don't have ROCm support.
- Linux Intel: install Intel GPU drivers per dgpu-docs.intel.com.
- For optimal scheduling, grant the binary perfmon capability: `sudo setcap cap_perfmon+ep /usr/local/bin/ollama` — without it, Ollama uses approximate VRAM sizes and may make suboptimal scheduling choices.
- Device selection: `GGML_VK_VISIBLE_DEVICES=0,1` (or `-1` to disable Vulkan entirely).
- AMD GPUs on some Linux distros need the `ollama` user added to the `render` group.

### Picking the right GPU path

| Hardware | Recommended | Why |
|---|---|---|
| NVIDIA RTX 30xx/40xx/50xx | CUDA | Best perf, broadest model support |
| Apple Silicon | Metal | Auto-detected; no config |
| AMD Radeon RX 6000/7000 | ROCm | Solid; verify card is in the supported table |
| AMD Radeon RX 5000 / older | Vulkan | ROCm doesn't cover; Vulkan fallback works |
| Intel Arc | Vulkan | Only path |
| Datacenter NVIDIA (A100, H100, L40, …) | CUDA | Use vLLM instead if multi-tenant production matters |
| No GPU | CPU | Works for small models (< 8B) at low tps |

---

## Per-cloud / per-PaaS pointers

Ollama runs on any host that meets the hardware/OS prereqs. Pick an infra adapter for the "where":

| Where | Adapter | How (typical) |
|---|---|---|
| AWS Lightsail | `infra/aws/lightsail.md` | Docker (CPU); Lightsail GPUs are limited |
| AWS EC2 (g5/p4/p5) | `infra/aws/ec2.md` | Native Linux + NVIDIA drivers + curl installer; or Docker + `--gpus=all` |
| Azure NC-series VMs | `infra/azure/vm.md` | Same as EC2 GPU |
| Hetzner Cloud GPU | `infra/hetzner/cloud-cx.md` (no GPU CX line — use Hetzner GEX series) | Docker + NVIDIA Container Toolkit |
| DigitalOcean GPU Droplets | `infra/digitalocean/droplet.md` | Docker + NVIDIA |
| GCP Compute Engine | `infra/gcp/compute-engine.md` | Native + curl installer (CUDA pre-loaded on GPU images) |
| Oracle Cloud (free ARM) | `infra/oracle/free-tier-arm.md` | Native ARM64 build (CPU-only — Ampere has no GPU) |
| Hostinger | `infra/hostinger.md` | VPS path; pick a GPU plan |
| Raspberry Pi | `infra/raspberry-pi.md` | CPU only; small models (≤ 3B) only — Pi RAM is tight |
| macOS VM (Lume) | `infra/macos-vm.md` | Native; Metal works in the VM |
| BYO Linux VPS / on-prem | `infra/byo-vps.md` | Whatever runtime fits the host |
| localhost | `infra/localhost.md` | Native (Homebrew on macOS, curl on Linux, .exe on Windows) |
| Any Kubernetes cluster | (user-provided) | Helm chart |

For PaaS targets (Fly.io, Render, Railway, Northflank): Ollama isn't a great fit — these platforms charge by container-second and Ollama benefits from long-running GPU-backed VMs with persistent volumes. If a user really wants Fly, they'll need a Fly GPU machine and a custom `fly.toml` — out of scope here, treat as TODO.

---

## Verification before marking `provision` done

- `ollama -v` returns a version string (CLI is on PATH).
- `ollama serve` is running: `systemctl status ollama` (Linux) / `launchctl list | grep ollama` (macOS) / `Get-ScheduledTask -TaskName Ollama*` (Windows) / `docker ps | grep ollama` (Docker).
- API health: `curl -sI http://127.0.0.1:11434/` returns `200 OK`.
- API tags: `curl -s http://127.0.0.1:11434/api/tags` returns valid JSON (initially `{"models":[]}`).
- After `ollama pull llama3.2`: `curl -s http://127.0.0.1:11434/api/tags` lists the model.
- One test inference round-trips (CLI: `ollama run llama3.2 "say hi"`; or via API: `curl http://127.0.0.1:11434/v1/chat/completions -d '...'`).
- (GPU) `ollama ps` (run while a model is loaded) shows the model loaded into GPU, not CPU. Or check `nvidia-smi` / `rocm-smi` for non-zero VRAM usage.

---

## Consolidated gotchas

Universal:

- **No built-in auth.** Default localhost-only bind is the only ship-time defense. Anything beyond that = reverse proxy with auth, VPN, or private subnet (see *Security model*). `OLLAMA_HOST=0.0.0.0` on a public IP without these = strangers using your GPU.
- **Models are big.** A "small" model is 4 GB; mid-tier is 18 GB; large is 40+ GB. First pull is slow; provision disk and bandwidth.
- **Pick the right GPU build.** `ollama` (no GPU) vs `ollama-cuda` vs `ollama-rocm` (Arch); `ollama/ollama` vs `ollama/ollama:rocm` (Docker). Wrong build runs on CPU silently.
- **`OLLAMA_KEEP_ALIVE` defaults to 5 min.** Long-tail agentic workloads with sparse calls re-load on every request, which is slow. Set `24h` or `-1` (forever) for production agents.
- **Context length is per-model + can be capped.** `OLLAMA_CONTEXT_LENGTH=131072` raises the default to 128K. Per-model: pass `--ctx-size 65536` to the model on `ollama run`, or set in the consumer's request.
- **`HTTP_PROXY` is a trap** — Ollama only uses HTTPS. Use `HTTPS_PROXY` only.

Per-method gotchas:

- **Native** — see *Native-specific gotchas* + `runtimes/native.md` § *Common gotchas*.
- **Docker** — see *Docker-specific gotchas* + `runtimes/docker.md` § *Common gotchas*.
- **Kubernetes** — see *Kubernetes-specific gotchas* + `runtimes/kubernetes.md` § *Common gotchas*.
- **Package managers** — see *Package-manager-specific gotchas*.

---

## TODO — verify on subsequent deployments

- **First end-to-end native install** on Linux (CPU + NVIDIA paths) — verify the curl installer's auto-CUDA-lib detection actually fires when an NVIDIA GPU is present.
- **Docker on a real cloud GPU instance** (g5.xlarge / Hetzner GEX44 / DO GPU Droplet) — verify `--gpus=all` works after NVIDIA Container Toolkit install; surface any toolkit-version gotchas.
- **AMD ROCm path end-to-end** — never exercised. Verify ROCm v7 + `ollama:rocm` image + SELinux `setsebool` on Fedora.
- **Apple Silicon / Metal** — verify `Ollama.app` vs CLI `ollama serve` conflict claim; verify `~/.ollama/models` path on macOS.
- **Windows native install** — verify Scheduled Task lifecycle; verify the `irm | iex` failure-is-non-fatal-to-shell pattern observed with OpenClaw applies here too.
- **Helm chart** — verify which community chart is closest to canonical (`otwld/ollama-helm` vs `cowboysysop/ollama` vs others). Document the chart's required values + the minimum Kubernetes version. Consider whether open-forge should pick one and standardize, or leave it to the user.
- **`OLLAMA_KEEP_ALIVE` interaction with `OLLAMA_MAX_LOADED_MODELS`** — clarify what happens when a 4th model is requested while 3 are loaded with `-1` (forever) keep-alive. Documentation says "queued"; verify under load.
- **Vulkan path** — `OLLAMA_VULKAN=1` + perfmon capability. Untested; needs an Intel Arc or older AMD card to validate.
- **Composing with OpenClaw / Hermes** — first-run validation: spin up Ollama on localhost, point each agent at it, exercise a real chat. Surface any model-name / API-shape mismatches between Ollama's `/v1` endpoint and what the agents send.
- **NVIDIA Jetson path** — `JETSON_JETPACK=N` is documented but never verified by open-forge.
- **PaaS feasibility** — write a Fly.io recipe for GPU machines if there's user demand; deferred until requested.