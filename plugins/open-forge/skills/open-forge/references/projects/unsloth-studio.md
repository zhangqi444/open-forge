---
name: unsloth-studio-project
description: Unsloth Studio recipe for open-forge. Apache-2.0 unified web UI + CLI for running and fine-tuning local AI models (text/audio/embedding/vision). Self-hostable via install.sh (macOS/Linux/WSL), install.ps1 (Windows), or the `unsloth/unsloth` Docker image. Studio exposes a web UI (default port 8888) and an OpenAI-compatible inference endpoint (port 8000). Heavy GPU dependency — NVIDIA RTX 30/40/50 / Blackwell for training; AMD + Intel + macOS support varies by feature.
---

# Unsloth Studio

Apache-2.0 local-AI workbench that "lets you run and train models locally." Upstream: <https://github.com/unslothai/unsloth>. Docs: <https://unsloth.ai/docs>. Studio docs: <https://unsloth.ai/docs/new/studio>.

Two distribution shapes from the same repo:

- **Unsloth Studio** — web UI. Browser-facing app for chat, model download/run, training runs, data recipes. Binds to a port (default `8888` for the UI, `8000` for the OpenAI-compat API, `2222` for SSH in the Docker image). **The self-hostable product.**
- **Unsloth Core** — Python library you import in your own code/notebooks. `pip install unsloth`. Not a service; not in scope for open-forge's "deploy and run" model.

This recipe covers the Studio self-host.

## Hardware matrix (from upstream README)

Unsloth Studio has the loudest "it depends" of anything in the selfh.st directory. Upstream's statement of support:

| Platform | Chat / Inference | Data Recipes | Training |
|---|---|---|---|
| NVIDIA RTX 30/40/50, Blackwell, DGX Spark/Station | ✅ | ✅ | ✅ |
| macOS (Apple Silicon) | ✅ | ✅ | ⏳ "MLX training coming very soon" |
| AMD GPUs | ✅ | ✅ | Use Unsloth Core; Studio training "out soon" |
| Intel GPUs | ✅ | ✅ | Use Unsloth Core; Studio training TBD |
| CPU-only | ✅ (Chat + Data Recipes) | ✅ | ❌ |
| Multi-GPU | ✅ (NVIDIA) | — | ✅ (NVIDIA) |

Translation: anyone without an NVIDIA GPU can *run* models in Studio but may not be able to *train* them. If the user's goal is training, check GPU brand before committing to Studio — recommend Unsloth Core on unsupported-for-training GPUs.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| `install.sh` (macOS/Linux/WSL) | <https://unsloth.ai/install.sh> | ✅ | One-liner blessed install. |
| `install.ps1` (Windows) | <https://unsloth.ai/install.ps1> | ✅ | Windows equivalent. |
| Docker image (`unsloth/unsloth`) | <https://hub.docker.com/r/unsloth/unsloth> | ✅ | Containerized — same image used for Core. Requires NVIDIA Container Toolkit. |
| Git clone + local install (`./install.sh --local`) | Repo root | ✅ | Developer / nightly install. |
| Unsloth Core (pip) | `uv pip install unsloth` | ✅ | Not a service — Python library. |

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "What platform?" | `AskUserQuestion`: `macOS` / `Linux` / `WSL` / `Windows` / `Docker` | Drives the install command. |
| preflight | "GPU vendor?" | `AskUserQuestion`: `NVIDIA` / `AMD` / `Intel` / `Apple Silicon` / `CPU-only` | Determines whether training is possible; gates feature recommendations. |
| preflight | "Training as a goal, or inference only?" | `AskUserQuestion`: `Inference only` / `Fine-tuning / training` | If training + non-NVIDIA GPU, steer to Unsloth Core + the AMD / Intel / Blackwell guides linked in the README. |
| network | "Bind Studio to `0.0.0.0` (LAN / remote access) or `127.0.0.1` (local only)?" | `AskUserQuestion` | Default is `127.0.0.1`; `0.0.0.0` requires reverse-proxy + auth (there is no built-in multi-user auth). |
| port | "Ports: web UI (default 8888), inference API (default 8000)?" | Free-text | Change only if clashing. |
| docker | *if Docker* "Jupyter / notebook password?" | Free-text (sensitive) | `JUPYTER_PASSWORD` env — the image ships with Jupyter. |
| storage | *if Docker* "Workspace bind-mount path?" | Free-text | Host path mounted at `/workspace/work` inside the container; holds notebooks / model outputs. |

## Install — macOS / Linux / WSL (`install.sh`)

```bash
curl -fsSL https://unsloth.ai/install.sh | sh
```

What this does (per the repo's `install.sh`):

1. Verifies Python 3.13 is available; installs via `uv` if not.
2. Creates a virtualenv.
3. `uv pip install unsloth --torch-backend=auto` — auto-detects CUDA / ROCm / MPS / CPU.
4. Registers the `unsloth` CLI globally.

Launch Studio:

```bash
unsloth studio -H 0.0.0.0 -p 8888
```

- `-H 0.0.0.0` = listen on all interfaces (use with reverse proxy + auth).
- `-H 127.0.0.1` = localhost only (default, safest).
- `-p 8888` = web UI port.

Studio also starts an OpenAI-compatible inference server on port `8000` by default (configurable; check `unsloth studio --help`).

### Update

```bash
unsloth studio update   # macOS / Linux / WSL
# Windows: re-run the install.ps1 line
```

Or re-run the `curl | sh` / `irm | iex` install command.

## Install — Windows (`install.ps1`)

```powershell
irm https://unsloth.ai/install.ps1 | iex
```

Then:

```powershell
unsloth studio -H 0.0.0.0 -p 8888
```

Note: on Windows, bare `pip install unsloth` works only if PyTorch is already installed. Upstream's <https://unsloth.ai/docs/get-started/install/windows-installation> is the fallback for non-`install.ps1` paths.

## Install — Docker

The same image serves both Studio and Core. Requires NVIDIA Container Toolkit on the host.

```bash
docker run -d --name unsloth \
  -e JUPYTER_PASSWORD="${JUPYTER_PW}" \
  -p 8888:8888 \
  -p 8000:8000 \
  -p 2222:22 \
  -v "$(pwd)/work:/workspace/work" \
  --gpus all \
  --restart unless-stopped \
  unsloth/unsloth
```

Ports:

- `8888` — Jupyter Notebook (password = `JUPYTER_PASSWORD`). **NOT** Studio's web UI directly; this is the Jupyter environment for Unsloth Core use.
- `8000` — OpenAI-compatible inference server.
- `2222` — SSH (if the image has SSH enabled; check the Dockerfile for current behavior).

For Studio specifically, check the image's README on Docker Hub for Studio-launch flags — the image has been evolving (Studio launched 2026 Q1; the Docker image was originally Core-focused).

### GPU runtime

Without `--gpus all` / NVIDIA Container Toolkit, training won't work (you'll get CPU-only inference). Install NVIDIA Container Toolkit first:

```bash
# Linux
distribution=$(. /etc/os-release; echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/libnvidia-container/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list \
  | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
sudo apt-get update && sudo apt-get install -y nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
```

## Install — Developer / Nightly (git clone)

```bash
git clone https://github.com/unslothai/unsloth
cd unsloth
./install.sh --local   # or on Windows: .\install.ps1 --local
unsloth studio -H 0.0.0.0 -p 8888
```

Nightly: `git checkout nightly` before `./install.sh --local`. Nightly = bleeding edge, expect breakage.

## Reverse proxy

Studio has **no built-in auth**. If exposing beyond `127.0.0.1`, put it behind a proxy that handles auth (basic-auth in nginx, `forward_auth` to Authelia/Authentik in Traefik/Caddy).

### Caddy with basic-auth

```caddy
unsloth.example.com {
    basicauth {
        admin $2a$14$<bcrypt-hash>
    }
    reverse_proxy localhost:8888
}
```

Generate the bcrypt hash:

```bash
caddy hash-password --plaintext "your-password-here"
```

### Nginx with basic-auth

```nginx
server {
    listen 443 ssl http2;
    server_name unsloth.example.com;
    # (TLS config omitted)

    auth_basic "Unsloth Studio";
    auth_basic_user_file /etc/nginx/.htpasswd-unsloth;

    location / {
        proxy_pass http://127.0.0.1:8888;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_read_timeout 3600s;   # training runs can be long
        proxy_send_timeout 3600s;
    }
}
```

## Upgrade

```bash
# install.sh / install.ps1 deploys
unsloth studio update       # does not work on Windows — re-run install.ps1 instead

# Docker
docker pull unsloth/unsloth
docker stop unsloth && docker rm unsloth
# Re-run `docker run`

# Developer clones
cd /path/to/unsloth && git pull && ./install.sh --local
```

Model files, LoRA adapters, datasets, and saved runs live in the studio data dir (for pip installs, typically under `~/.cache/unsloth/` or the configured workspace dir; in Docker, `/workspace/work/`). Back that up before major version bumps.

## Gotchas

- **GPU is the story.** Everything Studio-positive (training speed, VRAM savings, "2x faster / 70% less") assumes NVIDIA. Non-NVIDIA users get inference but limited/no training in Studio. Set expectations before install.
- **No built-in auth.** Bind to `127.0.0.1` and reverse-proxy with auth, or your Studio instance is open to anyone on the network — including running arbitrary code (the Jupyter notebook interface executes Python).
- **Model downloads are HUGE.** A single 20B-param model in FP16 is ~40 GB. Plan disk capacity; Unsloth caches downloads under `~/.cache/huggingface/`. Studio doesn't deduplicate across users.
- **Python 3.13 specifically.** `install.sh` pins 3.13; earlier Pythons don't have all the compatibility shims Unsloth relies on. If the host has Python 3.11 as system default, let `uv` manage a 3.13 env.
- **Docker image + training = NVIDIA Container Toolkit.** Without it, `--gpus all` is a no-op and you'll silently fall back to CPU.
- **Nightly branch is unstable.** README explicitly positions `git checkout nightly` as preview-only. Never run nightly for a user's actual workload.
- **Studio is beta.** Upstream markets it as beta as of this writing. API surface (CLI flags, ports, config) may shift between releases. `--help` is the source of truth.
- **Inference vs training workflows differ.** A user asking to "run gpt-oss-20B locally" just wants inference; directing them through the full training pipeline is overkill. Ask the preflight question.
- **Unsloth Core ≠ Unsloth Studio.** Core is `pip install unsloth` used in your own Python code / notebooks. Studio is the web UI. They share the same underlying library but deploy very differently. Confirm which the user wants.
- **Bandwidth cost for first-run model downloads.** On a metered connection, disable auto-download or prefetch over ethernet. Studio's model catalog eagerly fetches on selection.
- **Training runs are long.** Reverse-proxy `proxy_read_timeout` / `proxy_send_timeout` must be ≥ the longest expected run or the browser tab loses the progress stream mid-training.

## Upstream references

- Repo: <https://github.com/unslothai/unsloth>
- Docs: <https://unsloth.ai/docs>
- Studio docs: <https://unsloth.ai/docs/new/studio>
- Install scripts: <https://unsloth.ai/install.sh> · <https://unsloth.ai/install.ps1>
- Docker image: <https://hub.docker.com/r/unsloth/unsloth>
- Windows install guide: <https://unsloth.ai/docs/get-started/install/windows-installation>
- AMD guide: <https://unsloth.ai/docs/get-started/install/amd>
- Intel guide: <https://unsloth.ai/docs/get-started/install/intel>
- Free Colab notebooks: listed in the README's "Free Notebooks" section
- Discord: <https://discord.gg/unsloth>

## TODO — verify on first deployment

- Confirm `unsloth studio` CLI flag stability across a version bump (upstream is pre-1.0; flags change).
- Verify the Docker image's Studio-launch command (image started as Core-focused, Studio integration is newer).
- Test training on AMD / Intel GPUs if/when Studio supports it — upstream keeps moving this forward.
- Document any built-in auth if/when upstream adds it (currently none).
- Check whether macOS MLX training has shipped (README: "coming very soon").
