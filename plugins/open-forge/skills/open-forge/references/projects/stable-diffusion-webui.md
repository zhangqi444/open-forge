---
name: stable-diffusion-webui-project
description: Stable Diffusion WebUI (Automatic1111 / A1111) recipe for open-forge — the most-popular open-source AI image generator (github.com/AUTOMATIC1111/stable-diffusion-webui, ~140k★). Web UI for Stable Diffusion 1.x / 2.x / SD-XL / SD-3 / Flux models with built-in extension system, ControlNet support, LoRA loading, inpainting, outpainting, X/Y/Z plotting, and a thriving plugin ecosystem. Pairs with Open WebUI as an image-gen backend (`IMAGE_GENERATION_ENGINE=automatic1111`). Covers every upstream-blessed install path documented under the wiki: native installer (Linux `webui.sh` / macOS Apple Silicon / Windows release zip / Windows automatic / Windows manual), AMD ROCm Linux + Windows DirectML community fork, Apple Silicon MPS, plus community-maintained Docker images (AbdBarho / neggles / emsi / camenduru). Pairs with `references/runtimes/{native,docker}.md` and `references/infra/*.md`.
---

# Stable Diffusion WebUI (Automatic1111 / A1111)

The most-popular open-source UI for running Stable Diffusion locally. Python-based (3.10.6 specifically), single-process, default port `7860`. Models go in `stable-diffusion-webui/models/Stable-diffusion/`; outputs in `outputs/`. Extensions (ControlNet, ADetailer, Tiled VAE, etc.) install from URL or zip via the *Extensions* tab.

The upstream README + wiki call it "stable-diffusion-webui"; the community calls it "A1111" (after the maintainer's GitHub handle, AUTOMATIC1111). They mean the same thing.

Upstream: <https://github.com/AUTOMATIC1111/stable-diffusion-webui> — wiki at <https://github.com/AUTOMATIC1111/stable-diffusion-webui/wiki>.

## Compatible combos

A1111's deploy surface is unusual — there is **no first-party Docker image, no Helm chart, no PaaS template**. Upstream's blessed paths are all native (`webui.sh` on Linux/macOS, `webui-user.bat` on Windows, or the Windows release-zip one-click). Container deployments exist as community-maintained projects.

| How (runtime / install) | Module | Notes |
|---|---|---|
| **Native: `webui.sh`** (Linux) | `runtimes/native.md` + project section below | Default for any Linux host. Auto-creates a Python venv, downloads PyTorch + deps, fetches base model on first run. Auto-detects NVIDIA + AMD ROCm. |
| **Native: `webui.sh`** (macOS Apple Silicon) | `runtimes/native.md` + project section below | Same script as Linux. Uses Metal Performance Shaders (MPS) for GPU acceleration on M-series. |
| **Native: Windows release zip** (`sd.webui.zip` + `run.bat`) | project section below | One-click for non-technical Windows users. Self-contained Python; just unzip + double-click. |
| **Native: Windows automatic** (Python 3.10.6 + git + `webui-user.bat`) | project section below | When the release zip is too rigid; same flow as Linux but Windows-native. |
| **AMD on Windows** (community DirectML fork) | project section below | Upstream A1111 has no official Windows + AMD support; `lshqqytiger/stable-diffusion-webui-directml` is the de-facto fork. Training doesn't work; LoRAs + ControlNet do. |
| **Docker / containers** (community-maintained) | `runtimes/docker.md` + project section below | Pick from upstream wiki's container list (AbdBarho is the most-starred). Treat as "verify before trusting" — none are upstream-blessed. |
| **Kubernetes** | (no first-party path) | No upstream Kustomize / Helm. Some community charts wrap AbdBarho's Docker image; verify case-by-case. |

For the **where** axis, A1111 is GPU-bound for any practical use. Pick infra adapters that expose GPU hardware (AWS g5/g6, Azure NC, Hetzner GEX, DigitalOcean GPU Droplets) for cloud; localhost works for users with a desktop GPU or Apple Silicon Mac. CPU-only is documented but impractical (10+ min for a 512×512 image at 20 steps).

## Inputs to collect

| Phase | Prompt | Tool | Notes |
|---|---|---|---|
| preflight | "What do you want to host?" | (inferred from "Stable Diffusion WebUI" / "A1111" / "Automatic1111" in user's ask) | — |
| preflight | "Where?" | `AskUserQuestion`: AWS GPU EC2 / Azure NC / DO GPU Droplet / Hetzner GEX / GCP GPU / RunPod / Vast.ai / BYO Linux GPU host / Apple Silicon laptop / Windows desktop | GPU hardware is the hard constraint; non-GPU options listed only for completeness |
| preflight | "How?" (dynamic from combo table) | `AskUserQuestion`: native script / Windows release zip / Windows automatic / community Docker / Apple Silicon | Filtered by infra |
| preflight | "GPU?" | `AskUserQuestion`: NVIDIA CUDA / AMD ROCm (Linux) / AMD DirectML (Windows fork) / Apple Metal (M-series) / CPU (impractical) | Picks the install variant |
| preflight | "VRAM?" | `AskUserQuestion`: ≥ 12 GB / 6–12 GB / 4–6 GB / 2–4 GB | Drives `--medvram` / `--lowvram` flags + which models are practical |
| provision | "Which base model to start with?" | `AskUserQuestion`: SD 1.5 (default) / SD 2.1 / SD-XL / Flux / I'll add my own / Skip auto-download | First run pulls SD 1.5 (~4 GB) by default; pre-place a `.safetensors` to skip |
| provision | "Public domain?" | Free-text or skip | Triggers Caddy / nginx + cert-manager via runtimes/native.md (A1111 has no built-in TLS) |
| provision | "Auth?" | `AskUserQuestion`: None (localhost-only) / `--gradio-auth user:pass` (built-in basic auth) / Reverse proxy with auth | Default `--listen` exposes 7860 with no auth — pair with reverse proxy |

Project-conditional outputs:

| Recorded as | Derived from |
|---|---|
| `outputs.api_url` | `http://<host>:7860` (or with `/api/v1/...` for the optional API server) |
| `outputs.install_dir` | `~/stable-diffusion-webui/` (Linux/macOS) or `sd.webui\webui\` (Windows zip) |
| `outputs.models_dir` | `<install_dir>/models/Stable-diffusion/` |
| `outputs.gpu_path` | `nvidia-cuda` / `amd-rocm` / `amd-directml-fork` / `apple-mps` / `cpu` |
| `outputs.commandline_args` | The exact `COMMANDLINE_ARGS` line (e.g. `--xformers --medvram --listen --gradio-auth alice:s3cret`) |

## Software-layer concerns (apply to every deployment)

### What you're hosting

A1111 is a single-process Python app (Gradio frontend + custom backend) that loads a Stable Diffusion model into VRAM and serves a web UI. No database, no multi-user — outputs are written to disk, settings persist to JSON files in the install directory. Default bind is `127.0.0.1:7860`; `--listen` exposes on all interfaces; `--port N` overrides.

### Python version is a hard pin: 3.10.6

Upstream installs against Python **3.10.6** (or compatible 3.10.x). 3.11+ frequently breaks dependencies; 3.9 is too old. The wiki's installation pages spend most of their length on "how to install 3.10 on your distro" because it's the #1 source of install failures.

```bash
# Quick check
python3.10 --version       # should print 3.10.x
```

If unavailable from your distro's default repos, use Deadsnakes PPA (Ubuntu), `dnf install python3.10` (Fedora), pyenv (any Linux/macOS), or Homebrew (macOS).

### Disk + VRAM realities

| Resource | Minimum (workable) | Recommended | Notes |
|---|---|---|---|
| **VRAM** | 4 GB | 12+ GB | SD 1.5 fits in 4 GB; SD-XL needs 8+ GB; Flux Dev needs 16+ GB. With `--medvram` / `--lowvram` you can squeeze further but quality + speed suffer. |
| **System RAM** | 8 GB | 16+ GB | Models swap between VRAM and system RAM under memory pressure; OOM kills the process. |
| **Disk (install)** | 10 GB | 30+ GB | Python venv + PyTorch + the upstream repos = ~10 GB before any models. |
| **Disk (models)** | 4 GB | 50+ GB | Each model is 2–7 GB; LoRAs are 50–200 MB each; VAEs are ~300 MB; ControlNet models are ~1.5 GB each. Real users accumulate dozens. |

For cloud deploys, **always** allocate dedicated GPU storage (don't use the default boot disk for the models dir) — see `Change-model-folder-location` in the upstream wiki.

### State + directory layout

```
stable-diffusion-webui/                       # the install dir (cloned from git)
├── webui.sh / webui-user.sh                  # Linux/macOS entry points + user config
├── webui-user.bat / webui.bat                # Windows equivalents
├── launch.py                                 # actual launcher
├── webui.py                                  # main backend
├── venv/                                     # Python virtualenv (auto-created)
├── repositories/                             # auxiliary repos cloned at install
├── models/
│   ├── Stable-diffusion/                     # base SD models (.safetensors / .ckpt)
│   ├── Lora/                                 # LoRA files
│   ├── VAE/                                  # VAE files
│   ├── ControlNet/                           # ControlNet models (via extension)
│   ├── ESRGAN/                               # upscalers
│   └── …                                     # more model categories per extension
├── extensions/                               # installed extensions (one git clone per extension)
├── extensions-builtin/                       # ships with A1111
├── outputs/                                  # generated images (txt2img / img2img / extras / save)
├── log/                                      # per-day log of generations + parameters
├── styles.csv                                # saved prompt styles
├── ui-config.json                            # UI defaults (per-tab values)
└── config.json                               # runtime settings (Settings tab)
```

The whole `stable-diffusion-webui/` directory is the unit of deploy — back it up to back up everything. For container deployments, bind-mount the install dir, the `models/` subtree (often a separate volume), and `outputs/` (often a separate volume too).

### `webui-user.sh` / `webui-user.bat` is where you configure

Don't edit `webui.sh` / `webui.bat` directly — those are the upstream-managed scripts. Edit `webui-user.sh` / `webui-user.bat` to set:

| Variable | Purpose |
|---|---|
| `COMMANDLINE_ARGS` | The big one. Space-separated flags passed to the launcher. Examples: `--xformers --medvram --listen --gradio-auth alice:s3cret --api`. |
| `python_cmd` | Pin a specific Python (e.g. `python3.10`, `~/.pyenv/versions/3.10.6/bin/python3.10`). |
| `venv_dir` | Override venv location (default `venv`). |
| `TORCH_COMMAND` | Override PyTorch install command (used by AMD ROCm setups). |
| `REQS_FILE` | Override requirements file (rarely needed). |
| `STABLE_DIFFUSION_REPO` | Pin the SD repo (the wiki currently recommends `https://github.com/w-e-w/stablediffusion.git` for non-dev branches). |

### `COMMANDLINE_ARGS` — the flags that matter

| Flag | When | Effect |
|---|---|---|
| `--listen` | Any non-localhost deploy | Bind on `0.0.0.0` instead of `127.0.0.1`. Required for cloud / LAN access. |
| `--port 7860` | Multi-tenant or proxied | Override the port. |
| `--gradio-auth user:pass` | Public-ish exposure | Built-in HTTP basic auth. Comma-separate for multiple users (`alice:p1,bob:p2`). |
| `--gradio-auth-path /path/to/file` | Many users | One `user:pass` per line in a file. |
| `--xformers` | Most NVIDIA setups | Faster + lower VRAM. Highly recommended. |
| `--opt-sdp-attention` | Newer PyTorch / newer GPUs | Alternative to `--xformers`; sometimes faster. |
| `--medvram` | 6–8 GB VRAM | Reduces VRAM usage at small speed cost. |
| `--lowvram` | 4–6 GB VRAM | Heavier reduction, bigger speed cost. |
| `--precision full --no-half` | Most AMD GPUs | Avoids NaN errors / black images. Mandatory for many AMD cards. |
| `--upcast-sampling` | AMD GPUs that crash with `--no-half` | Faster than `--no-half`; try this first. |
| `--no-half-vae` | "Black image / NansException" symptoms | Specifically for VAE-stage NaN issues. |
| `--api` | Programmatic clients (Open WebUI, ComfyUI bridge, scripts) | Enables the REST API at `/sdapi/v1/...`. |
| `--api-auth user:pass` | API-server with auth | Adds basic auth to the API specifically. |
| `--cors-allow-origins=https://chat.example.com` | Cross-origin browser clients | Required if Open WebUI from a different origin will hit A1111's API. |
| `--enable-insecure-extension-access` | Want to install extensions on a `--listen` deploy | Off by default for `--listen` to prevent strangers from installing extensions. |
| `--ckpt-dir /external/models` | Models on separate disk | Point at a shared model dir on a fast drive. |
| `--data-dir /external/data` | All user data on separate disk | Moves outputs / extensions / styles / etc. |
| `--autolaunch` | Localhost only | Auto-opens a browser tab. |
| `--update-check` | Long-running | Notifies on new versions. |

For the full flag matrix, see `Command-Line-Arguments-and-Settings` in the upstream wiki.

### API surface (when `--api` is enabled)

```text
POST /sdapi/v1/txt2img             # generate from text
POST /sdapi/v1/img2img             # img2img / inpainting
POST /sdapi/v1/extra-single-image  # upscale / face restore
GET  /sdapi/v1/sd-models           # list installed base models
POST /sdapi/v1/options             # change runtime settings
GET  /sdapi/v1/progress            # current generation progress
GET  /sdapi/v1/queue-status        # queue state
```

Open WebUI's image-gen integration speaks this API directly when you set `IMAGE_GENERATION_ENGINE=automatic1111` and point the URL at A1111.

### Security model

A1111 has **no built-in user auth beyond `--gradio-auth` (HTTP basic)** and no CORS protection by default. Anyone hitting the URL can:

- Generate images (burning your GPU time).
- Install / uninstall extensions (with `--enable-insecure-extension-access` on a `--listen` deploy).
- Read outputs (the `/file=...` URL scheme exposes the install dir to a degree).

For any non-localhost deploy:

1. **Reverse proxy with proper auth** (Caddy + `basicauth` directive, nginx + OAuth2 proxy / Authelia / Authentik) — recommended.
2. **VPN-only access** (Tailscale / WireGuard) — simpler.
3. **Cloud firewall** — limit ingress to specific IPs.
4. At minimum, `--gradio-auth` with a strong password — but it's basic auth over HTTP unless TLS is terminated upstream, so step 1 is still required.

### Composing with Open WebUI as an image-gen backend

Open WebUI integrates A1111's API for in-chat image generation:

```bash
# In Open WebUI's environment:
IMAGE_GENERATION_ENGINE=automatic1111
AUTOMATIC1111_BASE_URL=http://a1111-host:7860
AUTOMATIC1111_API_AUTH=alice:s3cret    # optional, only if A1111 has --api-auth
```

A1111 must be started with `--api` (and `--cors-allow-origins=<Open WebUI's origin>` if Open WebUI is on a different host).

---

## Native install — Linux (`webui.sh`)

When the user picks **any Linux host (cloud GPU VM or localhost) → native**. Pair with [`references/runtimes/native.md`](../runtimes/native.md) for OS prereqs and daemon-lifecycle basics. Pair with the *GPU paths* section below for the vendor-specific flags.

Upstream wiki: <https://github.com/AUTOMATIC1111/stable-diffusion-webui/wiki/Install-and-Run-on-NVidia-GPUs> (NVIDIA), <https://github.com/AUTOMATIC1111/stable-diffusion-webui/wiki/Install-and-Run-on-AMD-GPUs> (AMD).

### Prereqs by distro

```bash
# Ubuntu 24.04 (Python 3.10 not in default repos — use Deadsnakes PPA)
sudo apt install -y git software-properties-common
sudo add-apt-repository ppa:deadsnakes/ppa -y
sudo apt update
sudo apt install -y python3.10 python3.10-venv libgl1 libglib2.0-0 wget

# Ubuntu 22.04 (Python 3.10 IS in default repos)
sudo apt install -y wget git python3 python3-venv libgl1 libglib2.0-0

# Fedora 40
sudo dnf install -y git python3.10 wget gperftools-libs libglvnd-glx

# openSUSE
sudo zypper install -y wget git python3 libtcmalloc4 libglvnd

# Arch Linux
sudo pacman -S --noconfirm wget git
yay -S python310     # or use pyenv — see wiki
```

### Install + first run

```bash
# Clone into a permanent home
git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui ~/stable-diffusion-webui
cd ~/stable-diffusion-webui

# (Optional but recommended) pre-create the venv with the right Python
python3.10 -m venv venv

# (Required for some installs — see Important step in upstream wiki)
# Upstream currently recommends pinning the SD repo URL:
cat >> webui-user.sh <<'EOF'
export STABLE_DIFFUSION_REPO="https://github.com/w-e-w/stablediffusion.git"
export COMMANDLINE_ARGS="--xformers --listen --gradio-auth alice:$(openssl rand -hex 16)"
EOF

# First run — installs PyTorch + deps + downloads SD 1.5 base model (~4 GB)
./webui.sh
```

The first run takes 10–30 minutes (Python deps + PyTorch + base model download) on a fresh VPS. Watch for:

- `Running on local URL: http://127.0.0.1:7860` — success.
- `Couldn't import modules` / `ImportError` — Python version mismatch; pin `python_cmd` in `webui-user.sh`.
- `RuntimeError: CUDA out of memory` — add `--medvram` or `--lowvram` to `COMMANDLINE_ARGS`.

Exit with `Ctrl-C`; subsequent launches skip the dep install and start in 10–30 seconds.

### Pre-place a model to skip auto-download

If you already have an SD model and don't want the auto-pull of SD 1.5:

```bash
# Place .safetensors or .ckpt before first run
mkdir -p ~/stable-diffusion-webui/models/Stable-diffusion
mv ~/Downloads/sd_xl_base_1.0.safetensors ~/stable-diffusion-webui/models/Stable-diffusion/
./webui.sh
```

### Daemon lifecycle (systemd-user)

A1111 doesn't ship a service file — write your own:

```bash
mkdir -p ~/.config/systemd/user

cat > ~/.config/systemd/user/stable-diffusion-webui.service <<'EOF'
[Unit]
Description=Stable Diffusion WebUI (Automatic1111)
After=network-online.target

[Service]
Type=simple
WorkingDirectory=%h/stable-diffusion-webui
ExecStart=%h/stable-diffusion-webui/webui.sh --xformers --listen --port 7860
Restart=on-failure
RestartSec=10

[Install]
WantedBy=default.target
EOF

systemctl --user daemon-reload
systemctl --user enable --now stable-diffusion-webui
sudo loginctl enable-linger "$USER"     # so the service survives logout
journalctl --user -u stable-diffusion-webui -f
```

Note `Type=simple` (not `forking`) and a generous `RestartSec=10` — A1111's first start can take a while; tighter restart loops will spin.

### Updating

```bash
cd ~/stable-diffusion-webui
git pull
./webui.sh    # picks up updated requirements; usually 30–60 s extra on first run after a pull
```

For systemd-managed deploys: `git pull && systemctl --user restart stable-diffusion-webui`.

### Linux native gotchas (A1111-only)

- **Python 3.10 specifically.** `webui.sh` will refuse 3.11+ outright on most installs; older 3.9 fails at runtime. The Deadsnakes PPA / pyenv / `dnf install python3.10` approach is the upstream-recommended path.
- **First run downloads ~4 GB of model.** If you don't want the SD 1.5 vanilla model, pre-place your own under `models/Stable-diffusion/` before `./webui.sh`.
- **`webui.sh` is the entry point — `webui-user.sh` is your config.** Don't edit `webui.sh`; it gets overwritten by `git pull`.
- **`--listen` requires `--enable-insecure-extension-access` to install extensions.** Off by default for safety. Don't enable on a public deploy without auth.
- **NVIDIA 50-series (RTX 5060/5070/5080/5090) requires the `dev` branch + PyTorch 2.7** as of upstream wiki. The `master` branch is 50-series-broken. Either `git checkout dev` or use `switch-branch-toole.bat` on the Windows zip.

---

## Native install — macOS Apple Silicon (`webui.sh`)

When the user picks **localhost on M-series Mac → native**. Apple Silicon uses Metal Performance Shaders (MPS) for GPU acceleration; it works but is slower than NVIDIA + CUDA at equivalent VRAM.

Upstream wiki: <https://github.com/AUTOMATIC1111/stable-diffusion-webui/wiki/Installation-on-Apple-Silicon>.

### Install

```bash
# Homebrew is required
# If not installed: /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

brew install cmake protobuf rust python@3.10 git wget

git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui ~/stable-diffusion-webui
cd ~/stable-diffusion-webui

# Pre-place models if you have them, else first run downloads SD 1.5
# mv ~/Downloads/sd-v1-5-pruned-emaonly.safetensors models/Stable-diffusion/

./webui.sh
```

`./webui.sh` creates the venv, installs PyTorch + deps, and starts the UI. MPS is auto-detected; no extra flags needed for basic use.

### Performance + memory notes

GPU acceleration on Apple Silicon uses *a lot* of system memory (unified memory architecture — VRAM and RAM share the pool). Performance order from upstream wiki, in case of slowness:

1. `./webui.sh --opt-split-attention-v1` — first thing to try.
2. Add `--medvram` if memory pressure is still red in Activity Monitor.
3. Add `--lowvram` if still slow.
4. Last resort: turn off GPU acceleration entirely with `--skip-torch-cuda-test --no-half --use-cpu all`.

### macOS-specific gotchas (A1111-only)

- **CLIP interrogator falls back to CPU on macOS** — slow but works. Training also "works" but is impractically slow + memory-hungry; don't plan on it.
- **PLMS sampler is broken on SD 2.0 on macOS.** Use other samplers; this is documented upstream.
- **Existing-install upgrade quirk:** if you have an install that was originally created with the old `setup_mac.sh` (pre-`webui.sh`), delete `run_webui_mac.sh` and `repositories/` first, then `git pull && ./webui.sh`.
- **Generation on Apple Silicon can be 5–10× slower than equivalent-VRAM NVIDIA.** A 512×512 / 20-step image at ~30 s on M1 Pro vs ~3 s on RTX 4070. Plan accordingly; for serious throughput, prefer cloud NVIDIA.

---

## Native install — Windows

Two paths upstream documents: the **release zip** (one-click, self-contained) for non-technical users, and the **automatic install** (Python + git + clone + run `webui-user.bat`) for everyone else. open-forge's autonomous mode can do automatic; the release zip flow is mostly user-driven (they extract the zip in Windows Explorer; we can't automate Windows GUI clicks).

Upstream wiki: <https://github.com/AUTOMATIC1111/stable-diffusion-webui/wiki/Install-and-Run-on-NVidia-GPUs>.

### Release zip (Windows method 1 — one-click, NVIDIA only)

1. User downloads `sd.webui.zip` from the [v1.0.0-pre release](https://github.com/AUTOMATIC1111/stable-diffusion-webui/releases/tag/v1.0.0-pre).
2. Extract to a permanent location (NOT inside `Program Files` — non-admin user must be able to write).
3. Double-click `update.bat` and wait for it to finish.
4. **For 50-series GPUs only:** double-click `switch-branch-toole.bat` and switch to `dev`.
5. Double-click `run.bat`. First run downloads PyTorch + base model (~5–10 min); subsequent runs start in ~30 s.
6. Browse to `http://127.0.0.1:7860` when the console prints `Running on local URL`.

To configure flags, edit `sd.webui\webui\webui-user.bat`:

```bat
set COMMANDLINE_ARGS=--xformers --autolaunch --update-check
```

### Automatic install (Windows method 2 — Python 3.10.6 + git)

```powershell
# 1. Install Python 3.10.6 (64-bit) — tick "Add to PATH" in the installer
#    Download: https://www.python.org/ftp/python/3.10.6/python-3.10.6-amd64.exe

# 2. Install Git for Windows
#    Download: https://github.com/git-for-windows/git/releases/download/v2.39.2.windows.1/Git-2.39.2-64-bit.exe

# 3. Clone (run in cmd or PowerShell)
git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui

# 4. Edit webui-user.bat — append:
#    set STABLE_DIFFUSION_REPO=https://github.com/w-e-w/stablediffusion.git
#    set COMMANDLINE_ARGS=--xformers --autolaunch

# 5. Double-click webui-user.bat (NOT webui.bat — webui-user.bat is your config wrapper)
```

The first run takes 10–30 minutes (Python deps + PyTorch CUDA + base model).

### Daemon lifecycle on Windows

A1111 doesn't ship a Windows service definition. Realistic options:

- **Run interactively** (just keep the cmd window open) — fine for personal-laptop use.
- **Scheduled Task at logon** — Task Scheduler → Create Task → "When the user logs on" → action `cmd.exe /c webui-user.bat` with the install dir as start-in. Survives reboot if the user logs in.
- **NSSM (Non-Sucking Service Manager)** — wrap `webui-user.bat` as a real Windows Service (`nssm install StableDiffusionWebUI`). Runs without a logged-in user, but doesn't get GPU access on every Windows GPU driver — verify before relying.
- **WSL2 instead** — install in Linux inside WSL2, run via `systemctl --user`. WSL2 + NVIDIA works on Windows 11 with recent drivers. See *Linux native install* above.

### Windows-specific gotchas (A1111-only)

- **`webui-user.bat`, not `webui.bat`.** The `-user` variant is the config wrapper; the bare `webui.bat` is the upstream script that gets overwritten on update.
- **Don't run as administrator.** The install + first run want to be a regular user; running as admin causes pip permission weirdness.
- **Don't extract `sd.webui.zip` to `Program Files` or `OneDrive`.** Path-with-spaces and OneDrive sync break the venv. Use `C:\AI\sd.webui\` or similar.
- **Antivirus / Defender blocks pip downloads** — false positives are common during install. Whitelist the install dir if pip stalls or errors.
- **Windows + AMD = community DirectML fork.** Upstream A1111 has no Windows + AMD path. See the *AMD on Windows* section under *GPU paths* below.
- **PowerShell launch scripts exist in upstream wiki** as an alternative for users who prefer PowerShell over `.bat`. Same flags apply via `[Environment]::SetEnvironmentVariable`.
- **Press Enter if it looks stuck.** Some install steps wait for input that doesn't arrive in non-interactive shells; pressing Enter unsticks them.

---

## GPU paths

The single biggest variable in deploy. Different per vendor; all are documented in the upstream wiki.

### NVIDIA (CUDA) — the default, best-supported path

- **Compute capability ≥ 5.0** (GTX 1050 and newer); driver 531+ for current CUDA build.
- `webui.sh` auto-installs the right PyTorch + CUDA libs on first run.
- **Recommended `COMMANDLINE_ARGS`:** `--xformers` (or `--opt-sdp-attention` on newer hardware).
- **VRAM tiers:**
  - 4 GB: `--lowvram --xformers`; SD 1.5 only; expect 1+ minute per 512×512 image.
  - 6–8 GB: `--medvram --xformers`; SD 1.5 / SDXL with `--medvram`.
  - 12–16 GB: `--xformers`; SDXL natively, Flux Dev with care.
  - 24+ GB: anything; multiple models loaded simultaneously.
- **NVIDIA Blackwell (RTX 50xx)** requires the `dev` branch + PyTorch 2.7 (not yet merged into `master`). `git checkout dev` (or use `switch-branch-toole.bat` on the Windows zip).
- Multi-GPU subset selection: `CUDA_VISIBLE_DEVICES=0,1` env var (use UUIDs from `nvidia-smi -L` for stability — numeric IDs reorder).

### AMD (ROCm) on Linux — supported, slower than NVIDIA

- Linux only. Windows AMD is the DirectML fork (below).
- `webui.sh` auto-installs PyTorch + ROCm on first run as of [PR #6709](https://github.com/AUTOMATIC1111/stable-diffusion-webui/pull/6709).
- **Recommended `COMMANDLINE_ARGS`:** `--upcast-sampling` (faster) OR `--precision full --no-half` (more compatible). Try `--upcast-sampling` first.
- **VRAM black-image / NaN issues** are common on AMD — `--no-half-vae` is the fix when symptoms specifically point at the VAE stage.
- **MIOpen kernel cache warning on first run** is normal; subsequent generations are faster. Optionally pre-compile MIOpen kernels per [ROCmSoftwarePlatform/MIOpen](https://github.com/ROCmSoftwarePlatform/MIOpen#installing-miopen-kernels-package) if the warning bothers you.
- **Cards known to work fp16 fine** (don't need `--no-half`): RX 6000 series, RX 500 series — see [#5468](https://github.com/AUTOMATIC1111/stable-diffusion-webui/issues/5468).
- Multi-GPU: `HIP_VISIBLE_DEVICES=0,1`.

For Arch Linux specifically, upstream wiki recommends `python-pytorch-rocm` (or `python-pytorch-opt-rocm` for AVX2 CPUs) + AUR's `python-torchvision-rocm` + a `--system-site-packages` venv. Detailed steps in the wiki.

For older AMD ROCm versions or unusual setups, the `Running inside Docker` path with `rocm/pytorch` is the upstream-blessed escape hatch — see *Docker / containers* below.

### AMD (DirectML) on Windows — community fork only

Upstream A1111 has **no official Windows + AMD support**. The de-facto path is `lshqqytiger/stable-diffusion-webui-directml`, a community fork that uses Microsoft's DirectML.

```powershell
# Same prereqs as upstream Windows (Python 3.10.6 + git)
git clone https://github.com/lshqqytiger/stable-diffusion-webui-directml
cd stable-diffusion-webui-directml
git submodule init && git submodule update

# Edit webui-user.bat — for 4–6 GB VRAM:
# set COMMANDLINE_ARGS=--opt-sub-quad-attention --lowvram --disable-nan-check

# Run
webui-user.bat
```

**Limitations:** training doesn't work on the DirectML fork; LoRAs and ControlNet do. Issues belong on the fork's tracker, not upstream A1111. As open-forge's job here is "interface, don't invent," we point users at the fork rather than building our own Windows + AMD recipe.

### Apple Silicon (MPS) — works, slow

Covered in the *macOS Apple Silicon* section above. MPS is the only acceleration path on M-series; Intel Macs fall back to CPU.

### Intel GPUs (Arc / iGPU) — external fork

Upstream points at the OpenVINO fork at <https://github.com/openvinotoolkit/stable-diffusion-webui> for Intel hardware. Out of scope for this recipe; pointer-only.

### CPU-only — works, painfully slow

```bash
./webui.sh --skip-torch-cuda-test --no-half --use-cpu all
```

Documented for completeness. A 512×512 / 20-step generation takes 5–15 minutes on a typical CPU. Useful only for testing the install, not for real use.

---

## Docker / containers (community-maintained)

**A1111 ships no first-party Docker image.** The upstream wiki links to four community-maintained containerizations; the most-starred and most-active is **AbdBarho/stable-diffusion-webui-docker**. Treat container deploys as "verify the source first" — none are blessed by upstream.

Upstream wiki: <https://github.com/AUTOMATIC1111/stable-diffusion-webui/wiki/Containers>.

| Repo | Notes |
|---|---|
| [AbdBarho/stable-diffusion-webui-docker](https://github.com/AbdBarho/stable-diffusion-webui-docker) | Most-active community image; ships docker-compose for A1111 + ComfyUI + InvokeAI side-by-side; profile-driven (`--profile auto`). |
| [neggles/sd-webui-docker](https://github.com/neggles/sd-webui-docker) | Alternative; also active. |
| [emsi/stable-diffusion-webui](https://github.com/emsi/stable-diffusion-webui) | Older; PR [#7946](https://github.com/AUTOMATIC1111/stable-diffusion-webui/pull/7946) for context. |
| [camenduru/stable-diffusion-webui-docker](https://github.com/camenduru/stable-diffusion-webui-docker) | Designed for cloud-runner setups (Colab, RunPod). |

### AbdBarho fork — recommended community path

```bash
git clone https://github.com/AbdBarho/stable-diffusion-webui-docker
cd stable-diffusion-webui-docker

# Pre-flight: pull base images, set up GPU runtime
docker compose --profile download up --build

# Run A1111 with NVIDIA GPU
docker compose --profile auto up --build

# Or pick a specific profile:
docker compose --profile auto-cpu up --build      # CPU-only (impractical but documented)
docker compose --profile comfy up --build         # ComfyUI instead
docker compose --profile invoke up --build        # InvokeAI instead
```

The `auto` profile mounts shared `data/` and `output/` directories on the host and runs A1111 on `localhost:7860`. The `data/` directory holds models, extensions, and LoRAs; `output/` holds generated images. Both survive container recreation.

GPU prereqs are the same as Ollama's Docker section: install NVIDIA Container Toolkit on the host before `docker compose up`. See `references/runtimes/docker.md` § *NVIDIA GPU* and the Ollama recipe's *NVIDIA GPU* section for the install steps.

For AMD ROCm via Docker, AbdBarho doesn't have a pre-baked profile — fall back to upstream wiki's *Running inside Docker* approach with `rocm/pytorch`:

```bash
docker run -it \
  --network=host \
  --device=/dev/kfd --device=/dev/dri \
  --group-add=video \
  --ipc=host --cap-add=SYS_PTRACE --security-opt seccomp=unconfined \
  -v "$HOME/dockerx:/dockerx" \
  rocm/pytorch
# Inside the container:
cd /dockerx
git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui
cd stable-diffusion-webui
python -m pip install --upgrade pip wheel
REQS_FILE='requirements.txt' python launch.py --precision full --no-half --listen
```

### Updating

For AbdBarho:

```bash
cd stable-diffusion-webui-docker
git pull
docker compose --profile auto up --build --force-recreate
```

For the rocm/pytorch path: re-attach to the container, `cd stable-diffusion-webui && git pull`, restart.

### Why no first-party image?

Upstream's stance (paraphrased from the wiki) is that A1111 is fundamentally a developer tool that benefits from access to the host filesystem, GPU drivers, and Python tooling — Dockerizing it well requires opinionated choices about model storage, extension loading, and GPU runtime that vary too much across users. Community forks make those choices; pick the one whose opinions match yours.

For open-forge's purposes: when a user asks for "A1111 in Docker," recommend AbdBarho's fork as the most-active community option, with the explicit caveat that we're pointing at a third-party project, not an upstream-blessed deploy path.

### Container-specific gotchas (A1111-only)

- **Community-maintained ≠ upstream-blessed.** Treat the AbdBarho repo's commands as suggestions, not contracts. Verify the README at the version you pull; upstream A1111 changes that affect `requirements.txt` can lag in the community image.
- **Models live on the host.** AbdBarho mounts `data/` from the host into the container; models go there, not in the image. A `docker compose down --rmi all` doesn't wipe models — the host directory does.
- **Profile selection matters.** AbdBarho's compose file ships profiles for A1111 (`auto`), ComfyUI (`comfy`), InvokeAI (`invoke`), and CPU-only variants. Picking the wrong profile starts the wrong tool — read the README.
- **GPU runtime in Docker = NVIDIA Container Toolkit on the host.** Same prereq as Ollama. Without it, `docker compose up` succeeds but A1111 silently falls back to CPU.

---

## Per-cloud / per-PaaS pointers

A1111 is GPU-bound — the infra adapter is whatever exposes a usable GPU. Pair the chosen adapter with the *Native Linux* install path above (or AbdBarho's Docker compose if you prefer containers).

| Where | Adapter | Typical setup |
|---|---|---|
| AWS EC2 (g5.xlarge / g6.xlarge / p4d) | `infra/aws/ec2.md` | NVIDIA AMI + `webui.sh` + `--xformers` |
| Azure NC-series VMs | `infra/azure/vm.md` | NVIDIA driver + `webui.sh` |
| Hetzner GEX (NVIDIA) | (no first-party adapter — use byo-vps with their GEX line) | NVIDIA driver + `webui.sh` |
| DigitalOcean GPU Droplets | `infra/digitalocean/droplet.md` | Same |
| GCP Compute Engine GPU | `infra/gcp/compute-engine.md` | NVIDIA driver pre-loaded on GPU images |
| Oracle Cloud (free ARM) | `infra/oracle/free-tier-arm.md` | **Skip** — Ampere has no GPU; A1111 on CPU is impractical |
| Hostinger | `infra/hostinger.md` | Pick a GPU plan; `webui.sh` |
| Raspberry Pi | `infra/raspberry-pi.md` | **Skip** — no GPU, RAM-bound |
| macOS VM (Lume) | `infra/macos-vm.md` | Apple Silicon host's MPS works inside the VM but is even slower than bare-metal |
| BYO Linux VPS / on-prem | `infra/byo-vps.md` | Whatever GPU the box has; pair with the matching *GPU paths* subsection above |
| localhost (NVIDIA desktop) | `infra/localhost.md` | Native Linux install or Windows release zip |
| localhost (Apple Silicon) | `infra/localhost.md` | Native macOS install |
| Any Kubernetes cluster | (no first-party path) | Community community Helm wrappers exist for AbdBarho's image; verify case-by-case |

**Cloud-GPU specialists** (RunPod, Vast.ai, Lambda Labs, fal.ai, Replicate) often ship pre-baked A1111 images / templates. Cheaper than long-running EC2 GPU for sporadic image-gen workloads. Out of scope for this recipe; recommend if the user has spiky usage rather than always-on.

**PaaS:** Fly.io has GPU machines with persistent volumes and works for A1111 with a custom `fly.toml` (community examples exist; not in upstream). Render / Railway / Northflank don't currently expose GPU machines suitable for SD. Treat PaaS A1111 as TODO if the user asks.

---

## Verification before marking `provision` done

- A1111 process running: `systemctl --user is-active stable-diffusion-webui` (Linux native) or `docker compose ps` (Docker) or visible in Task Manager (Windows).
- HTTP health: `curl -sIo /dev/null -w '%{http_code}\n' http://127.0.0.1:7860/` returns `200`.
- The browser loads the UI and the model dropdown shows at least one model (the auto-pulled SD 1.5, or whatever was pre-placed).
- One generated image round-trips (UI: pick a model, type "a cat", hit Generate, image appears in `outputs/txt2img-images/<date>/`).
- `nvidia-smi` (NVIDIA) or `rocm-smi` (AMD) shows non-zero VRAM usage during generation — confirms GPU is actually in use.
- (If `--api` enabled) `curl -s http://127.0.0.1:7860/sdapi/v1/sd-models` returns valid JSON listing the installed models.

---

## Consolidated gotchas

Universal:

- **Python 3.10.6 specifically.** 3.11+ frequently breaks; 3.9 is too old. Pin via Deadsnakes / pyenv / Homebrew / `dnf install python3.10`. This is the single biggest source of install failures.
- **No first-party Docker image.** Container deploys go through community forks (AbdBarho recommended). Verify the source.
- **No multi-user, no built-in auth.** `--gradio-auth` is HTTP basic auth; for anything real, front with a reverse proxy + auth.
- **First run downloads a 4 GB SD 1.5 base model** unless you pre-place a `.safetensors` under `models/Stable-diffusion/`.
- **GPU is mandatory for practical use.** CPU-only "works" but takes 5–15 min per image. Cloud + VPS without GPU = wrong tool.
- **`webui-user.{sh,bat}` is your config — `webui.{sh,bat}` is upstream's.** Don't edit `webui.sh` directly; `git pull` overwrites it.
- **Outputs dir grows fast.** Generated images accumulate in `outputs/txt2img-images/<date>/`. Plan disk space + lifecycle.
- **Extensions are git clones in `extensions/`.** They install requirements via pip on first load — first-load lag is normal. To remove, delete the directory + restart.

Per-method gotchas live alongside each section above:

- **Linux native** — see *Linux native gotchas*.
- **macOS Apple Silicon** — see *macOS-specific gotchas*.
- **Windows** — see *Windows-specific gotchas*.
- **Containers** — see *Container-specific gotchas* + `runtimes/docker.md` § *Common gotchas*.

---

## TODO — verify on subsequent deployments

- **First end-to-end Linux + NVIDIA install** on a real GPU VM (g5.xlarge or similar). Validate: `webui.sh` first-run timing, `--xformers` actually engages, NVIDIA 50-series `dev`-branch claim, systemd-user lifecycle.
- **AMD ROCm Linux** end-to-end on a real Radeon — never exercised. Validate `--upcast-sampling` vs `--precision full --no-half` decision tree, MIOpen warning behavior on first generation.
- **AMD Windows DirectML community fork** — pointer-only in the recipe; never validated. Confirm the fork URL is still maintained at first-deploy time.
- **Apple Silicon MPS** — verify the upstream wiki's claimed performance ceiling and the Activity-Monitor memory-pressure remediation order.
- **Windows release zip path** end-to-end (`sd.webui.zip` v1.0.0-pre + `update.bat` + `run.bat`). Validate non-admin user works; validate the 50-series `switch-branch-toole.bat` path.
- **Windows 11 + WSL2 + NVIDIA** as an alternative to native Windows — is this actually nicer than the release zip? Compare.
- **AbdBarho Docker compose** — first-run profile selection, NVIDIA Container Toolkit interaction, model directory permissions across container recreates.
- **`rocm/pytorch` Docker path for AMD** — old upstream-wiki pattern, may have drifted from current ROCm. Verify.
- **Composing with Open WebUI as image-gen backend** — first-run validation: A1111 with `--api`, Open WebUI configured with `IMAGE_GENERATION_ENGINE=automatic1111`, exercise an in-chat image generation. Surface API-shape mismatches.
- **Reverse-proxy patterns** — Caddy + `basicauth`, nginx + Authelia, Tailscale Funnel — each needs first-run validation. The recipe documents them generically.
- **`--ckpt-dir` / `--data-dir` for separate model + outputs disks** on cloud GPU instances — verify the path-override actually works without breaking extensions that hardcode `models/`.
- **NVIDIA Blackwell 50-series `dev` branch** — verify `git checkout dev` produces a working install on RTX 5090; verify the `switch-branch-toole.bat` Windows path.
- **PaaS feasibility on Fly.io GPU machines** — write a Hermes-style A1111 `fly.toml` if there's user demand. Deferred until requested.
- **Backup + restore drill** — document the exact procedure for backing up `models/`, `outputs/`, `extensions/`, `config.json`, `ui-config.json`, `styles.csv` and restoring to a fresh box. Critical for any production deploy.
- **Multi-tenant story** — A1111 is single-user by design. Multiple users = multiple instances. Document patterns: `--port` per user, separate venvs vs shared model dir, etc.