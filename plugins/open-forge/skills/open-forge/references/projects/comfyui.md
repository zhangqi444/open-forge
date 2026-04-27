---
name: comfyui-project
description: ComfyUI recipe for open-forge — node-based AI image / video generation with the most flexible workflow system in the open-source space (github.com/comfyanonymous/ComfyUI, ~80k★). Power-user alternative to Automatic1111 — same models, different UX (drag-and-drop graph of nodes vs A1111's tabbed forms). Default port 8188; share models with A1111 via `extra_model_paths.yaml`. Covers every upstream-blessed install method: Desktop App (Windows/macOS, easiest), Windows portable 7z (NVIDIA / AMD / Intel / NVIDIA-cu126 variants), `comfy-cli` (`pip install comfy-cli && comfy install`), manual install (git clone + pip), plus per-vendor GPU wheels (NVIDIA CUDA, AMD ROCm Linux + Windows nightly for RDNA 3/3.5/4, Intel Arc XPU, Apple Silicon MPS, plus pointers for Ascend / Cambricon / Iluvatar). Pairs with `references/runtimes/{native,docker}.md`.
---

# ComfyUI

Node-based interface for Stable Diffusion / SDXL / SD-3 / Flux / video models. Every operation (text encoding, sampling, VAE decode, upscaling, ControlNet conditioning) is a node; users wire them into graphs and reuse / share them as JSON workflows. The same model files A1111 uses work in ComfyUI; many users symlink `models/` between the two installs.

Defaults: Python 3.13 (current), HTTP API at `8188`, models in `models/checkpoints/` (NOT `models/Stable-diffusion/` like A1111), workflows shareable as JSON. Workflows can be loaded by dragging a generated PNG into the UI — ComfyUI embeds the full graph in the image's metadata.

Upstream: <https://github.com/comfyanonymous/ComfyUI>. Desktop app + Cloud at <https://www.comfy.org/>.

## Compatible combos

ComfyUI's deploy surface is similar to A1111: native installs across all platforms, no first-party Docker, but unlike A1111 there's a polished **Desktop App** (Windows + macOS) and a **Windows portable** (.7z extract → run) for non-technical users.

| How (runtime / install) | Module | Notes |
|---|---|---|
| **Desktop App** (Windows + macOS only) | project section below | Easiest. Download the installer from comfy.org/download; everything is bundled. |
| **Windows portable** (`.7z` extract, no install) | project section below | One-click for Windows users who want CLI but not Python prereqs. Per-GPU variants: `_nvidia` / `_amd` / `_intel` / `_nvidia_cu126` (legacy 12.6 / Python 3.12). |
| **`comfy-cli`** (Python wrapper) | `runtimes/native.md` + project section below | `pip install comfy-cli && comfy install`. Manages install, model downloads, custom nodes via CLI. Good for cloud VMs. |
| **Manual install** (git clone + pip) | `runtimes/native.md` + project section below | Most control. Required for non-default Python versions, custom GPU wheels, mixed setups. Same flow on Linux / macOS / Windows. |
| **Docker / containers** (community-maintained) | `runtimes/docker.md` + project section below | No first-party image. AbdBarho's docker-compose includes a `comfy` profile; standalone community images on Docker Hub. |
| **Comfy Cloud** (paid hosted) | (out of scope) | comfy.org/cloud — pointer-only; open-forge is for self-hosting. |

For the **where** axis, ComfyUI is GPU-bound for any practical use (same as A1111). Pick infra adapters that expose GPU hardware. CPU-only works for testing (`python main.py --cpu`) but is impractical.

## Inputs to collect

| Phase | Prompt | Tool | Notes |
|---|---|---|---|
| preflight | "What do you want to host?" | (inferred from "ComfyUI" in user's ask) | — |
| preflight | "Where?" | `AskUserQuestion`: AWS GPU EC2 / Azure NC / DO GPU Droplet / Hetzner GEX / GCP GPU / RunPod / Vast.ai / BYO Linux GPU host / Apple Silicon laptop / Windows desktop | GPU is the hard constraint |
| preflight | "How?" (dynamic from combo table) | `AskUserQuestion`: Desktop App / Windows portable / comfy-cli / manual / community Docker | Filtered by infra (Desktop App is Windows/macOS-only) |
| preflight | "GPU?" | `AskUserQuestion`: NVIDIA CUDA / AMD ROCm Linux / AMD ROCm Windows nightly / Intel Arc / Apple Silicon MPS / Other (Ascend / Cambricon / Iluvatar) / CPU | Picks the PyTorch wheel index |
| preflight | "VRAM?" | `AskUserQuestion`: ≥ 16 GB / 8–16 GB / 4–8 GB / < 4 GB | Drives `--lowvram` / `--novram` / `--gpu-only` flags + which models are practical |
| provision | "Share models with an A1111 install?" | `AskUserQuestion`: Yes (set up `extra_model_paths.yaml`) / No | If yes, link models / LoRAs / VAEs / etc. via the upstream-shipped `extra_model_paths.yaml.example` template |
| provision | "Which base model to start with?" | `AskUserQuestion`: SD 1.5 / SDXL / SD-3 / Flux Dev / Flux Schnell / I'll add my own / Skip | ComfyUI does NOT auto-download a base model — you must place one or it boots empty |
| provision | "Install ComfyUI Manager?" | `AskUserQuestion`: Yes (recommended — handles custom-node updates) / No | The de-facto extension manager; not first-party but near-universal |
| provision | "Public domain?" | Free-text or skip | Triggers Caddy / nginx + cert-manager via runtimes/native.md |
| provision | "Auth?" | `AskUserQuestion`: None (localhost-only) / Reverse proxy with auth / Tailscale | ComfyUI has NO built-in auth at all — `--listen` exposes everything to anyone on the network |

Project-conditional outputs:

| Recorded as | Derived from |
|---|---|
| `outputs.api_url` | `http://<host>:8188` |
| `outputs.install_dir` | `~/ComfyUI/` (manual) / `%LOCALAPPDATA%\ComfyUI\` (Desktop App on Windows) / wherever the user extracted the portable |
| `outputs.models_dir` | `<install_dir>/models/checkpoints/` (and `loras/`, `vae/`, `controlnet/`, etc.) |
| `outputs.gpu_path` | `nvidia-cuda` / `amd-rocm-linux` / `amd-rocm-windows-nightly` / `intel-xpu` / `apple-mps` / `cpu` |
| `outputs.shared_with_a1111` | Path to A1111 install if `extra_model_paths.yaml` is linked, else null |

## Software-layer concerns (apply to every deployment)

### What you're hosting

ComfyUI is a single-process Python app: HTTP server (port 8188), WebSocket for live progress, an in-browser graph editor (custom JS), and a queue manager that runs prompts. State is mostly on disk — no database. Default bind is `127.0.0.1:8188`; `--listen` binds on all interfaces; `--port N` overrides.

### Python version

Upstream **recommends Python 3.13** as of late 2025; 3.12 also works; 3.14 is documented as possibly-broken-with-some-custom-nodes. This is much more flexible than A1111's hard pin on 3.10.6.

### Disk + VRAM realities

| Resource | Minimum (workable) | Recommended | Notes |
|---|---|---|---|
| **VRAM** | 4 GB | 12+ GB | SD 1.5 fits in 4 GB; SDXL needs 8+ GB; Flux Dev needs 16+ GB; SD-3 Medium ~10 GB. ComfyUI's memory management is more aggressive than A1111's — `--lowvram` / `--novram` / `--gpu-only` flags trade VRAM for speed and offload to system RAM. |
| **System RAM** | 8 GB | 16+ GB | When `--lowvram` swaps to RAM, you need the headroom. |
| **Disk (install)** | 5 GB | 20+ GB | Python venv + PyTorch + nodes. Smaller than A1111 since ComfyUI doesn't auto-download a base model. |
| **Disk (models)** | 4 GB | 50+ GB | Same model classes as A1111. Sharing via `extra_model_paths.yaml` is the right call when both are installed. |

### State + directory layout

```
ComfyUI/                                  # the install dir
├── main.py                               # entry point
├── server.py
├── extra_model_paths.yaml.example        # symlink/share models with A1111 etc.
├── models/
│   ├── checkpoints/                      # base SD models (.safetensors / .ckpt)
│   ├── loras/                            # LoRA files
│   ├── vae/                              # VAE files
│   ├── clip/                             # CLIP encoders
│   ├── controlnet/                       # ControlNet models
│   ├── embeddings/                       # textual inversion
│   ├── upscale_models/                   # ESRGAN / RealESRGAN / etc.
│   └── …                                 # one folder per node category
├── custom_nodes/                         # extensions — one git clone per extension
├── input/                                # uploaded images for img2img / etc.
├── output/                               # generated images
├── temp/                                 # working dir
├── user/                                 # per-user UI settings + workflow library
└── web/                                  # bundled frontend assets
```

`extra_model_paths.yaml` (copy from `extra_model_paths.yaml.example`) is the magic that lets ComfyUI read models from another directory — most commonly an A1111 install:

```yaml
a111:
    base_path: /home/user/stable-diffusion-webui/
    checkpoints: models/Stable-diffusion
    vae: models/VAE
    loras: models/Lora
    upscale_models: |
                     models/ESRGAN
                     models/RealESRGAN
                     models/SwinIR
    embeddings: embeddings
    controlnet: models/ControlNet
```

This avoids duplicating tens of GB of model files when a user has both A1111 and ComfyUI on the same machine.

### Custom nodes — the extension system

Each "node type" is a Python class. Custom nodes (extensions) live as git clones under `custom_nodes/`. They auto-load on startup. Common ones:

| Custom node | Purpose |
|---|---|
| **ComfyUI-Manager** (`ltdrdata/ComfyUI-Manager`) | The de-facto extension installer/updater. **Strongly recommended** — install this first, then use it to install everything else. |
| **ComfyUI_IPAdapter_plus** | IPAdapter (image-to-image conditioning) |
| **ComfyUI_Comfyroll_CustomNodes** | Wide collection of utility nodes |
| **comfyui_controlnet_aux** | ControlNet preprocessors (canny, depth, openpose, etc.) |
| **ComfyUI_essentials** | Quality-of-life essentials |
| **was-node-suite-comfyui** | Large general-purpose suite |
| **rgthree-comfy** | UI improvements (group muter, bookmarks, etc.) |

To install ComfyUI Manager (do this once, immediately after first ComfyUI start):

```bash
cd ComfyUI/custom_nodes
git clone https://github.com/ltdrdata/ComfyUI-Manager
# Restart ComfyUI; "Manager" button now appears in the sidebar
```

**Custom nodes can install Python dependencies on first load** (via their own `requirements.txt`) — first launch after adding a new node is often slow as pip installs deps into the same venv.

**Custom nodes are arbitrary Python code.** Treat as supply-chain risk: pin to versions you've audited, prefer well-known maintainers, don't blindly install whatever a workflow JSON references. ComfyUI Manager has a "trust" tier system that helps but isn't a substitute for review.

### Workflows — JSON, embedded in PNGs

Workflows are graphs serialized as JSON. They can be:

- Saved/loaded via the UI's `Save` / `Load` buttons.
- **Embedded in generated PNGs** — drag a PNG ComfyUI generated into the UI and the original workflow loads. This is the killer feature for sharing.
- Run via the API (`POST /api/prompt` with the workflow JSON as the request body).

Workflows reference custom-node types by name. Loading someone else's workflow may require installing the custom nodes they used; ComfyUI Manager has a "Install Missing Custom Nodes" button that scans the loaded workflow and offers to install what's missing.

### API surface

```text
POST /api/prompt              # queue a prompt (workflow + params)
GET  /api/history             # past prompts + outputs
GET  /api/history/<prompt_id> # specific run
GET  /api/queue               # current queue state
POST /api/interrupt           # cancel current generation
POST /api/upload/image        # upload an input image
GET  /api/object_info         # node-type registry (used by frontend)
GET  /view                     # download a generated file
WebSocket /ws                 # live progress updates
```

For programmatic clients (Open WebUI's image-gen integration, scripts, n8n flows), the upstream `script_examples/` directory has minimal Python clients showing the prompt-submit flow. Open WebUI's ComfyUI integration speaks this API directly — set `IMAGE_GENERATION_ENGINE=comfyui` and `COMFYUI_BASE_URL=http://comfy-host:8188` in Open WebUI.

### Critical command-line arguments

| Flag | When | Effect |
|---|---|---|
| `--listen [<ip>]` | Any non-localhost deploy | Bind on `0.0.0.0` (default when flag is bare) or specific IP. |
| `--port 8188` | Multi-tenant or proxied | Override the port. |
| `--lowvram` | 6–8 GB VRAM | Aggressive offloading; slow but works on small GPUs. |
| `--novram` | <4 GB VRAM | Even more aggressive — most weights stay on CPU. |
| `--gpu-only` | Plenty of VRAM | Keep everything on GPU; no offloading. Faster when you can afford it. |
| `--cpu` | No GPU | CPU-only fallback. Impractical for real use; useful for dev. |
| `--use-pytorch-cross-attention` / `--use-quad-cross-attention` / `--use-split-cross-attention` | Per-GPU optimization | Try in this order; each can dramatically change perf. Default (auto) is usually fine. |
| `--directml` | Windows + AMD via DirectML | Skip the ROCm wheels; use the Windows-supported DirectML PyTorch backend. |
| `--preview-method auto` | Custom node compatibility | Render in-progress previews; some custom nodes break without this. |
| `--disable-xformers` | xformers misbehaves | Force off if your install hits xformers-related crashes. |
| `--enable-cors-header [<origin>]` | Cross-origin browser clients | Required if Open WebUI from a different origin will hit ComfyUI's API. |
| `--input-directory /external/input` / `--output-directory /external/output` / `--user-directory /external/user` | Separate disks | Move I/O off the install volume. |
| `--extra-model-paths-config /path/to/yaml` | Multi-instance setups | Override the default `extra_model_paths.yaml` location. |
| `--multi-user` | (Multi-user dev preview) | Per-user directories under `user/`. Treat as preview; no auth. |
| `--front-end-version <git-rev>` | Frontend pinning | Pin a specific version of the React frontend. Useful for reproducibility. |
| `--verbose` | Debugging | DEBUG-level logging. |

For the full flag matrix, run `python main.py --help`.

### Security model

ComfyUI has **no built-in auth at all** — no `--gradio-auth` equivalent. `--listen` exposes everything (including the workflow editor and the file-download endpoints) to anyone on the network. For any non-localhost deploy:

1. **Reverse proxy with auth** (Caddy + `basicauth`, nginx + Authelia / Authentik / oauth2-proxy) — required.
2. **VPN-only access** (Tailscale / WireGuard) — simpler.
3. **Cloud firewall** — limit ingress to specific IPs.

The `/view` endpoint returns arbitrary files from the input/output directories. The `POST /api/prompt` endpoint accepts arbitrary workflow JSON, which can include node types that read/write files via custom-node-defined I/O. **Treat exposed ComfyUI as full filesystem write access** — never expose without auth.

### Composing with Open WebUI

```bash
# In Open WebUI's environment:
IMAGE_GENERATION_ENGINE=comfyui
COMFYUI_BASE_URL=http://comfyui-host:8188
COMFYUI_API_KEY=                   # ComfyUI has no native API key; leave blank or use proxy auth
COMFYUI_WORKFLOW=<json>            # optional default workflow; otherwise uses Open WebUI's built-in
```

ComfyUI must be started with `--listen` (and `--enable-cors-header https://chat.example.com` if Open WebUI is on a different origin).

---

## Desktop App (Windows + macOS)

When the user picks **localhost on Windows or macOS → easiest path**. The Desktop App is the only first-party install method that bundles everything (Python runtime, PyTorch, frontend) into a one-click installer. This is the path open-forge should recommend for non-technical users on supported OSes.

Upstream: <https://www.comfy.org/download>.

### Install

1. User downloads the installer from comfy.org/download (Windows: `.exe`; macOS: `.dmg`). open-forge can fetch the URL via `curl` but the install itself is a GUI wizard — Claude can't drive Windows / macOS GUI installers autonomously, so this step is user-driven.
2. Run the installer; accept defaults.
3. First launch:
   - Windows: Desktop App ships with bundled Python; no extra prereqs.
   - macOS: Apple Silicon required (Intel Macs aren't supported by the Desktop App).
   - On first run, the app prompts for a model directory (default: `~/Documents/ComfyUI/models/`) and offers to download a starting model.

### Configuration

Settings are managed via the app's preferences panel (no `webui-user.bat` equivalent). Key knobs:

- **Models directory** — change this to point at an existing A1111 install's `models/Stable-diffusion/` if you want to share.
- **Server settings** — port, listen address (default localhost-only).
- **Custom nodes** — managed via the integrated ComfyUI Manager.

### Updates

Auto-update on launch (when checked in preferences) or manual via the help menu. Updates the Python runtime + dependencies in-place; doesn't touch the models directory.

### Desktop-App-specific gotchas

- **Windows / macOS only.** No Linux Desktop App. Linux users go through manual install or a community AppImage.
- **Apple Silicon required on macOS.** No Intel Mac support.
- **Bundled Python is isolated from system Python.** Custom nodes that depend on system-wide packages (rare) will fail. Stick with custom nodes that declare requirements in their own `requirements.txt`.
- **Models dir is `~/Documents/ComfyUI/models/` by default**, not the manual-install convention `~/ComfyUI/models/`. Pre-existing model collections need either a directory move or a symlink.
- **Cloud tier of comfy.org/cloud is paid** and out of scope for self-hosting. The Desktop App and Cloud share the same UI but the Cloud option doesn't run on your hardware.

---

## Windows portable (`.7z` extract — no install)

When the user is on Windows, wants something CLI-driven, but doesn't want to install Python / PyTorch / git globally. The portable is a zipped pre-built environment — just extract and run.

Upstream releases: <https://github.com/comfyanonymous/ComfyUI/releases/latest>.

### Variants

| File | When |
|---|---|
| `ComfyUI_windows_portable_nvidia.7z` | NVIDIA GPU on Windows. Default choice for ~80% of Windows users. |
| `ComfyUI_windows_portable_amd.7z` | AMD GPU on Windows (uses DirectML). |
| `ComfyUI_windows_portable_intel.7z` | Intel Arc GPU (experimental). |
| `ComfyUI_windows_portable_nvidia_cu126.7z` | NVIDIA legacy: CUDA 12.6 + Python 3.12. Use only if your GPU driver doesn't support CUDA 13+. |

### Install + run

1. Download the matching `.7z` from the latest release.
2. Extract with [7-Zip](https://www.7-zip.org/) (Windows' built-in zip can't open `.7z`). Place the resulting folder somewhere with write permission — **NOT inside `Program Files` or OneDrive**.
3. Place at least one `.safetensors` model in `ComfyUI_windows_portable\ComfyUI\models\checkpoints\`. Without a model, ComfyUI starts but can't generate.
4. Double-click `run_nvidia_gpu.bat` (or the matching `_cpu.bat` / `_amd.bat` / `_intel.bat`) — these are the launchers.
5. Browser opens to `http://127.0.0.1:8188`.

### Configuration

Edit the `.bat` launcher to add command-line args:

```bat
@echo off
.\python_embeded\python.exe -s ComfyUI\main.py --listen --port 8188 --preview-method auto
pause
```

The portable's `python_embeded\` directory is its self-contained Python; don't install packages into it via system pip.

### Updating

Run `update\update_comfyui.bat` (ships with the portable) — pulls latest ComfyUI source. To update Python deps too: `update\update_comfyui_and_python_dependencies.bat`. Models in `ComfyUI\models\` survive updates.

### Custom nodes via the portable

```cmd
cd ComfyUI_windows_portable\ComfyUI\custom_nodes
git clone https://github.com/ltdrdata/ComfyUI-Manager
```

Then re-run the launcher. ComfyUI Manager handles further node installs from inside the UI.

### Portable-specific gotchas

- **Extract somewhere with write access.** `Program Files`, `OneDrive`, or any path with spaces / non-ASCII characters causes problems.
- **Use 7-Zip** to extract; Windows' built-in zip may silently fail on `.7z`.
- **Pick the right variant for your GPU.** Mixing (e.g. running `_amd.bat` on an NVIDIA install) silently falls back to CPU.
- **No `webui-user.bat` equivalent** — config goes into the launcher `.bat` directly. Make a backup before editing if you're not comfortable with batch syntax.
- **Model directory is `ComfyUI_windows_portable\ComfyUI\models\`.** Symlinks to A1111's `models/Stable-diffusion/` work via `extra_model_paths.yaml` — same pattern as manual install.
- **Update scripts pull from `master`.** If you want a specific tag, use manual install.

---

## `comfy-cli` (Python wrapper)

When the user wants the simplicity of "one command" without the Desktop App's Windows/macOS limitation. `comfy-cli` is an upstream-maintained Python CLI that wraps install + model downloads + custom-node management.

### Install + first run

```bash
# Prereq: Python 3.13 (or 3.12) with pip
python3.13 --version

# Install the CLI itself (in a venv ideally)
python3.13 -m venv ~/comfy/venv
source ~/comfy/venv/bin/activate
pip install --upgrade pip
pip install comfy-cli

# Install ComfyUI itself (downloads source + creates a separate venv for ComfyUI)
comfy install --workspace ~/comfy/ComfyUI

# Launch
comfy launch
```

`comfy install` clones ComfyUI to `~/comfy/ComfyUI/`, sets up a Python venv, installs PyTorch + deps, and registers the install with the CLI. `comfy launch` runs it.

### Common comfy-cli commands

```bash
comfy launch                           # start ComfyUI in foreground
comfy launch -- --listen --port 8188   # pass flags through to main.py
comfy stop                              # stop running instance
comfy update                            # update ComfyUI itself
comfy node install <node-name>          # install a custom node by name
comfy node update all                   # update all custom nodes
comfy model download --url <hf-url>     # download a model into the right models/ subdir
comfy which                             # show install path
```

### Daemon lifecycle (systemd-user, Linux)

```bash
mkdir -p ~/.config/systemd/user
cat > ~/.config/systemd/user/comfyui.service <<'EOF'
[Unit]
Description=ComfyUI
After=network-online.target

[Service]
Type=simple
WorkingDirectory=%h/comfy/ComfyUI
ExecStart=%h/comfy/venv/bin/comfy launch -- --listen --port 8188
Restart=on-failure
RestartSec=10

[Install]
WantedBy=default.target
EOF

systemctl --user daemon-reload
systemctl --user enable --now comfyui
sudo loginctl enable-linger "$USER"
journalctl --user -u comfyui -f
```

### comfy-cli-specific gotchas

- **Two venvs.** `comfy-cli`'s own venv (where you `pip install comfy-cli`) is separate from ComfyUI's venv (managed by `comfy install`). Don't conflate them.
- **`comfy launch` blocks the terminal.** Use systemd-user / `tmux` / `nohup` to background it.
- **`comfy update` updates ComfyUI to master HEAD.** No tag/version pin; for reproducible installs, fall back to manual.
- **Custom-node installs touch ComfyUI's venv** (not the comfy-cli venv). First-load slowness on fresh nodes is normal.

---

## Manual install (Linux / macOS / Windows)

When the user wants full control: specific Python versions, custom GPU wheels, mixed setups, dev installs, or non-default paths. Pair with [`references/runtimes/native.md`](../runtimes/native.md) for OS prereqs and daemon-lifecycle basics. Pair with the *GPU paths* section below for the vendor-specific PyTorch wheel index.

Upstream README: <https://github.com/comfyanonymous/ComfyUI#manual-install-windows-linux>.

### Prereqs by distro (Linux)

```bash
# Ubuntu 24.04 / Debian 12 (Python 3.13 not in default repos — Deadsnakes PPA)
sudo apt install -y git software-properties-common
sudo add-apt-repository ppa:deadsnakes/ppa -y
sudo apt update
sudo apt install -y python3.13 python3.13-venv

# Fedora 40+ / RHEL 9 (3.12 widely available; 3.13 in newer)
sudo dnf install -y git python3.12

# Arch Linux
sudo pacman -S --noconfirm git python   # python = current 3.x
```

### macOS prereqs

```bash
brew install python@3.13 git
# For PyTorch nightly with MPS, see GPU paths below
```

### Install + first run

```bash
git clone https://github.com/comfyanonymous/ComfyUI ~/ComfyUI
cd ~/ComfyUI

# Use the right Python; 3.13 recommended
python3.13 -m venv venv
source venv/bin/activate

# (Pick GPU-specific PyTorch — see GPU paths section below)
# NVIDIA CUDA 13.0 example:
pip install torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu130

# ComfyUI's other deps
pip install -r requirements.txt

# Place at least one .safetensors in models/checkpoints/ before first run
# (ComfyUI does NOT auto-download a base model — it starts empty)

# Run
python main.py
# Add --listen for non-localhost access; --port 8188 to override port
```

The first run takes 30–90 s to load the Python + import PyTorch. Subsequent restarts are faster. UI opens at `http://127.0.0.1:8188`.

### Pre-place a model (or symlink from A1111)

```bash
# Option A: copy a base model into ComfyUI's checkpoints dir
mv ~/Downloads/sd_xl_base_1.0.safetensors ~/ComfyUI/models/checkpoints/

# Option B: share with A1111 via extra_model_paths.yaml
cp ~/ComfyUI/extra_model_paths.yaml.example ~/ComfyUI/extra_model_paths.yaml
# Edit to point at the A1111 install (see Software-layer concerns above for the schema)
```

### Install ComfyUI Manager (recommended)

```bash
cd ~/ComfyUI/custom_nodes
git clone https://github.com/ltdrdata/ComfyUI-Manager
cd .. && python main.py    # restart; "Manager" button now appears
```

### Daemon lifecycle (systemd-user, Linux)

```bash
mkdir -p ~/.config/systemd/user
cat > ~/.config/systemd/user/comfyui.service <<'EOF'
[Unit]
Description=ComfyUI
After=network-online.target

[Service]
Type=simple
WorkingDirectory=%h/ComfyUI
ExecStart=%h/ComfyUI/venv/bin/python %h/ComfyUI/main.py --listen --port 8188
Restart=on-failure
RestartSec=10

[Install]
WantedBy=default.target
EOF

systemctl --user daemon-reload
systemctl --user enable --now comfyui
sudo loginctl enable-linger "$USER"
journalctl --user -u comfyui -f
```

### Updating

```bash
cd ~/ComfyUI
git pull
source venv/bin/activate
pip install -r requirements.txt   # pick up new deps
systemctl --user restart comfyui  # if running as a service
```

For pinned versions: `git checkout v0.x.x` instead of `git pull`.

### Manual-install gotchas (ComfyUI-only)

- **`models/checkpoints/` (NOT `models/Stable-diffusion/`)** is where base models go. A1111 users frequently get this wrong on first ComfyUI install.
- **No base model = empty model dropdown.** ComfyUI doesn't auto-download anything; you must place a `.safetensors` before first generation. For users coming from A1111, the upstream-shipped `extra_model_paths.yaml.example` is the easiest path.
- **Custom nodes break across PyTorch upgrades.** A `pip install -r requirements.txt` after `git pull` often updates PyTorch; some custom nodes (especially older ones) pin specific Torch versions and break. ComfyUI Manager's "Update All" handles most cases; broken ones need manual reinstall or removal.
- **`pip install -r requirements.txt` doesn't install custom-node deps.** Each custom node has its own `requirements.txt` under `custom_nodes/<name>/`. ComfyUI auto-runs them on first load; if a node fails to load with `ModuleNotFoundError`, run pip install on its requirements manually inside the venv.
- **Apple Silicon needs PyTorch nightly** as of late 2025 for MPS support of latest models — see GPU paths.
- **`python main.py` blocks** until killed. Use systemd-user / tmux for background.

---

## GPU paths

ComfyUI's GPU support is broader than A1111's — same NVIDIA / AMD / Apple paths, plus first-class Intel Arc XPU support and pointers for exotic accelerators (Ascend NPUs, Cambricon MLUs, Iluvatar Corex). The right install command is "the right `pip install torch ...` line for your GPU."

### NVIDIA (CUDA) — default

Current PyTorch wheel index for ComfyUI's recommended stack (Python 3.13 + CUDA 13):

```bash
pip install torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu130
```

For older drivers that can't run CUDA 13, use the cu126 portable variant on Windows or pin Torch to a CUDA 12.x wheel:

```bash
pip install torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu126
```

`--use-pytorch-cross-attention` is usually the right attention mode on recent NVIDIA hardware. Multi-GPU subset: `CUDA_VISIBLE_DEVICES=0,1` env var (use UUIDs from `nvidia-smi -L` for stability).

### AMD (ROCm) — Linux

```bash
# Stable (current):
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/rocm7.2

# RDNA 3 (gfx110X — RX 7600 / 7700 / 7800 / 7900):
pip install torch torchvision torchaudio --index-url https://rocm.nightlies.amd.com/v2/gfx110X-all/

# RDNA 3.5 (gfx1151 — Ryzen AI 9 HX series APUs):
pip install torch torchvision torchaudio --index-url https://rocm.nightlies.amd.com/v2/gfx1151/

# RDNA 4 (gfx120X — RX 9060 / 9070 series):
pip install torch torchvision torchaudio --index-url https://rocm.nightlies.amd.com/v2/gfx120X-all/
```

The RDNA 3 / 3.5 / 4 indices are nightly builds — install fresh, don't expect ABI stability across upgrades. Once Torch is in, ComfyUI starts as normal:

```bash
python main.py --listen
```

For ROCm-specific issues (NaN, black images), try `--disable-xformers` first, then attention-mode flags (`--use-quad-cross-attention` / `--use-split-cross-attention`).

### AMD (ROCm or DirectML) — Windows

ComfyUI ships first-class Windows + AMD support — the official Windows portable has an `_amd` variant that uses DirectML out of the box:

- **Windows portable** (`ComfyUI_windows_portable_amd.7z`) — no install required.
- **Manual** with DirectML: `pip install torch-directml` then `python main.py --directml`.
- **Manual** with ROCm Windows nightly (RDNA 3+ only): use the same `gfx110X-all` / `gfx1151` / `gfx120X-all` indices as Linux. Treat as experimental on Windows.

### Intel Arc (XPU)

```bash
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/xpu
```

Then `python main.py` — ComfyUI auto-detects XPU. Or use the portable: `ComfyUI_windows_portable_intel.7z`.

Performance on Intel Arc is workable but lags NVIDIA at equivalent VRAM. Treat as "works for hobby use" rather than production.

### Apple Silicon (MPS)

Upstream README points at Apple's PyTorch-nightly install guide; the current pattern is:

```bash
# Apple Silicon ONLY — Intel Macs fall back to CPU
brew install python@3.13 git
git clone https://github.com/comfyanonymous/ComfyUI ~/ComfyUI
cd ~/ComfyUI
python3.13 -m venv venv
source venv/bin/activate

# PyTorch nightly with MPS support
pip install --pre torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/nightly/cpu

pip install -r requirements.txt
python main.py
```

Performance is similar to A1111 on Apple Silicon: workable but slower than NVIDIA. ComfyUI's memory management is generally friendlier on MPS than A1111's.

### Other accelerators (pointer)

Upstream documents three more:

- **Ascend NPUs** (Huawei datacenter accelerators) — see [PR #5436](https://github.com/comfyanonymous/ComfyUI/pull/5436) and the `torch_npu` PyTorch backend.
- **Cambricon MLUs** (datacenter accelerators) — see the `torch_mlu` backend.
- **Iluvatar Corex** (datacenter accelerators) — see [PR #6907](https://github.com/comfyanonymous/ComfyUI/pull/6907).

These are out of scope for typical open-forge users; pointer-only.

### CPU-only

```bash
python main.py --cpu
```

Documented for completeness; impractical for production. SD 1.5 generation on CPU takes 5–15 minutes per image.

---

## Docker / containers (community-maintained)

Like A1111, **ComfyUI ships no first-party Docker image**. The most-active community options:

| Repo | Notes |
|---|---|
| [AbdBarho/stable-diffusion-webui-docker](https://github.com/AbdBarho/stable-diffusion-webui-docker) | Same compose project as the A1111 community Docker; ships a `comfy` profile. |
| [yanwk/comfyui-boot](https://github.com/YanWenKun/ComfyUI-Docker) | Full-featured ComfyUI Docker images with multiple GPU variants. |
| [ai-dock/comfyui](https://github.com/ai-dock/comfyui) | Cloud-runner-friendly (RunPod, Vast.ai compatible). |

### AbdBarho `comfy` profile

```bash
git clone https://github.com/AbdBarho/stable-diffusion-webui-docker
cd stable-diffusion-webui-docker

# Pull base + download starter assets
docker compose --profile download up --build

# Start ComfyUI (NVIDIA)
docker compose --profile comfy up --build
# CPU-only:
docker compose --profile comfy-cpu up --build
```

Default ports: 7860 for A1111-related profiles, 7862 for the `comfy` profile (verify against the repo's compose file at the version you pull). Mounts the host's `data/` and `output/` directories so models + outputs persist.

NVIDIA Container Toolkit is required on the host — same prereq as Ollama / A1111. See `references/runtimes/docker.md` § *NVIDIA GPU* for install steps.

### yanwk/comfyui-boot

Standalone images with explicit GPU variants:

```bash
docker run -d --name comfyui \
  --gpus=all \
  -p 127.0.0.1:8188:8188 \
  -v ~/comfyui-data:/root/ComfyUI \
  ghcr.io/yanwk/comfyui-boot:cu130-megapak
```

Tag matrix (verify current tags against the upstream README):

- `cu130-*` — CUDA 13 builds (current)
- `rocm-*` — AMD ROCm Linux
- `cpu-*` — CPU-only
- `*-megapak` — pre-installed with popular custom nodes
- `*-slim` — minimal base

Pre-baked images reduce first-run install time; downside is upstream-drift risk (the bundled custom-node versions may lag).

### Updating

```bash
# AbdBarho:
cd stable-diffusion-webui-docker
git pull
docker compose --profile comfy up --build --force-recreate

# yanwk image:
docker pull ghcr.io/yanwk/comfyui-boot:cu130-megapak
docker stop comfyui && docker rm comfyui
docker run -d --name comfyui ... (same args as before)
```

### Why no first-party image?

Same reasoning as A1111 — ComfyUI's deploy is opinionated about Python version, GPU runtime, and custom-node management; community forks bake their own opinions. open-forge's stance: when a user asks for "ComfyUI in Docker," recommend either AbdBarho (if they already have it for A1111) or yanwk (if standalone), with the explicit caveat that we're pointing at third-party projects.

### Container-specific gotchas (ComfyUI-only)

- **Community-maintained ≠ upstream-blessed.** Verify the README at the version you pull.
- **Custom nodes inside the container** persist via the mounted volume. A `docker compose down --rmi all` doesn't wipe them; the host volume does.
- **GPU runtime needs NVIDIA Container Toolkit** for `--gpus=all`. AMD ROCm via Docker uses the same `--device /dev/kfd --device /dev/dri` pattern as A1111's rocm/pytorch path.
- **Pre-baked "megapak" images can be 20+ GB.** First pull is slow on residential ISPs.
- **Port collisions with A1111** if both run on the same host. AbdBarho's compose splits them (7860 vs 7862); standalone Docker runs need explicit `-p` overrides.

---

## Comfy Cloud (paid hosted — out of scope)

`https://www.comfy.org/cloud` is the official paid-hosted ComfyUI service. Out of scope for open-forge (we self-host); pointer-only for users asking "is there a managed version." Comfy Cloud + open-forge don't compose — pick one.

For self-hosted "ComfyUI on a cloud GPU you rent by the hour," see RunPod / Vast.ai / Lambda Labs / fal.ai under *Per-cloud / per-PaaS pointers* below.

---

## Per-cloud / per-PaaS pointers

Same shape as A1111 — GPU is the hard constraint; pick infra adapters that expose suitable GPUs. Prefer manual install on Linux GPU VMs; Desktop App or Windows portable for desktop users.

| Where | Adapter | Typical setup |
|---|---|---|
| AWS EC2 (g5/g6/p4/p5) | `infra/aws/ec2.md` | NVIDIA AMI + manual install or comfy-cli + `--xformers` cross-attention |
| Azure NC-series | `infra/azure/vm.md` | NVIDIA driver + manual install |
| Hetzner GEX | (no first-party adapter — use `byo-vps`) | NVIDIA driver + manual install |
| DigitalOcean GPU Droplets | `infra/digitalocean/droplet.md` | Same |
| GCP Compute Engine GPU | `infra/gcp/compute-engine.md` | NVIDIA driver pre-loaded; manual install |
| Oracle Cloud (free ARM) | `infra/oracle/free-tier-arm.md` | **Skip** — Ampere has no GPU |
| Hostinger | `infra/hostinger.md` | Pick a GPU plan; manual install |
| Raspberry Pi | `infra/raspberry-pi.md` | **Skip** — no GPU |
| macOS VM (Lume) | `infra/macos-vm.md` | Apple Silicon host + MPS works inside the VM but is slow |
| BYO Linux VPS / on-prem | `infra/byo-vps.md` | Manual install + matching GPU path |
| localhost (NVIDIA desktop) | `infra/localhost.md` | Desktop App or Windows portable on Windows; manual install elsewhere |
| localhost (Apple Silicon) | `infra/localhost.md` | Desktop App (easiest) or manual install with MPS PyTorch nightly |
| Any Kubernetes cluster | (no first-party path) | Community Helm charts wrap yanwk/comfyui-boot or AbdBarho's image; verify case-by-case |

**Cloud-GPU specialists** (RunPod, Vast.ai, Lambda Labs, fal.ai, Replicate) frequently ship pre-baked ComfyUI templates. Cheaper than long-running EC2 GPU for sporadic image-gen workloads. ai-dock/comfyui (above) is designed for these platforms. Out of scope for this recipe but pointer-worthy for spiky usage.

**PaaS:** Fly.io has GPU machines; ComfyUI works there with a custom `fly.toml` + persistent volume for `models/`. Render / Railway / Northflank don't currently expose GPU machines suitable for ComfyUI. Treat PaaS ComfyUI as TODO unless requested.

---

## Verification before marking `provision` done

- Process running: `systemctl --user is-active comfyui` (Linux native) / Desktop App in tray / `docker compose ps` (Docker) / Windows Task Manager.
- HTTP health: `curl -sIo /dev/null -w '%{http_code}\n' http://127.0.0.1:8188/` returns `200`.
- API: `curl -s http://127.0.0.1:8188/api/object_info` returns valid JSON listing the loaded node-type registry.
- The browser loads the UI; default workflow appears (or empty graph + model dropdown).
- Model dropdown shows at least one installed model (or a clear "place a model in `models/checkpoints/`" indicator).
- One generated image round-trips: load default workflow / draw `KSampler -> VAE Decode -> Save Image` / hit Queue Prompt / image appears in `output/`.
- `nvidia-smi` (NVIDIA) / `rocm-smi` (AMD) shows non-zero VRAM during generation.
- (Optional) Drag the generated PNG back into the UI — workflow loads from metadata. Confirms the metadata-roundtrip feature works.

---

## Consolidated gotchas

Universal:

- **`models/checkpoints/`, NOT `models/Stable-diffusion/`.** A1111 users get this wrong on first install.
- **No auto-download of base model.** ComfyUI starts empty. Place a `.safetensors` or set up `extra_model_paths.yaml` before first generation.
- **No built-in auth.** `--listen` exposes the workflow editor (which has filesystem access via custom nodes). Always front with reverse proxy + auth or VPN for any non-localhost deploy.
- **Custom nodes are arbitrary Python code.** Treat as supply-chain risk. ComfyUI Manager helps but doesn't audit.
- **Custom-node deps install on first load.** Slow first launch after adding a new node is normal.
- **Workflow JSON references custom-node types by name.** Loading someone else's workflow may require installing their custom nodes; ComfyUI Manager's "Install Missing" handles most cases.
- **Python 3.13 recommended** but 3.12 works; 3.14 is documented as possibly-broken with some custom nodes. Much more flexible than A1111.
- **`extra_model_paths.yaml`** is the right way to share models with A1111. Copy the example, edit, restart.
- **No `webui-user.bat` / `webui-user.sh` equivalent.** Config is `python main.py <flags>` directly. Edit launcher scripts (Windows portable's `.bat`s) or systemd unit ExecStart.
- **GPU memory flags differ from A1111.** ComfyUI uses `--lowvram` / `--novram` / `--gpu-only`; not `--medvram` etc.

Per-method gotchas live alongside each section above:

- **Desktop App** — see *Desktop-App-specific gotchas*.
- **Windows portable** — see *Portable-specific gotchas*.
- **comfy-cli** — see *comfy-cli-specific gotchas*.
- **Manual install** — see *Manual-install gotchas*.
- **Containers** — see *Container-specific gotchas* + `runtimes/docker.md` § *Common gotchas*.

---

## TODO — verify on subsequent deployments

- **First end-to-end Linux + NVIDIA install** on a real GPU VM. Validate: PyTorch wheel install for cu130, default workflow runs, ComfyUI Manager bootstraps, custom-node first-load behavior.
- **Desktop App** install on Windows + macOS — verify the bundled-Python isolation claim, settings layout, model-dir override for sharing with A1111.
- **Windows portable** all four variants (`_nvidia` / `_amd` / `_intel` / `_nvidia_cu126`) — validate update scripts (`update_comfyui.bat`, `update_comfyui_and_python_dependencies.bat`).
- **comfy-cli** end-to-end — `comfy install` workspace location, `comfy node install` flow, `comfy model download` against a Hugging Face URL.
- **AMD ROCm Linux** (stable index + RDNA 3 / 3.5 / 4 nightly indices) — never validated. Verify NaN-free generation per-card.
- **AMD on Windows** via DirectML AND nightly ROCm — pick one as recommended; verify the portable's `_amd` variant works.
- **Intel Arc XPU** path — completely unvalidated.
- **Apple Silicon MPS** with PyTorch nightly — verify the install flow against the current Apple PyTorch nightly URL (URLs drift).
- **`extra_model_paths.yaml`** sharing with A1111 — first-run validation that models / LoRAs / VAEs / ControlNet all show up correctly under both UIs.
- **ComfyUI Manager** end-to-end — install missing custom nodes from a foreign workflow, confirm dep auto-install, surface the "broken after PyTorch upgrade" symptom and fix.
- **Composing with Open WebUI** as image-gen backend — first-run validation: ComfyUI with `--listen --enable-cors-header https://chat.example.com`, Open WebUI configured with `IMAGE_GENERATION_ENGINE=comfyui`, image generation in chat. Compare to A1111 backend.
- **AbdBarho `comfy` profile** — verify port (7862 vs 8188), volume layout, model-dir overlap with the `auto` (A1111) profile.
- **yanwk/comfyui-boot** image — verify current tag matrix (cu130 / rocm / cpu / megapak / slim) against the upstream README.
- **Reverse-proxy patterns** — Caddy + basicauth, nginx + Authelia, Tailscale Funnel — never validated. Document them in `runtimes/native.md` and link.
- **PaaS feasibility on Fly.io GPU machines** — write a `fly.toml` if requested.
- **`--multi-user` mode** — currently a preview; verify per-user dir layout + interaction with shared models. Worth an explicit "preview, no auth" caveat in the recipe.
- **Backup + restore drill** — `models/`, `custom_nodes/`, `output/`, `user/`, `extra_model_paths.yaml`. Critical for production.