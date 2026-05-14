---
name: ebook2audiobook
description: Convert ebooks (EPUB/PDF/MOBI/TXT/…) to audiobooks with chapters and metadata using modern TTS engines (XTTSv2, YourTTS, Tacotron2, Bark, etc.) and voice cloning. Gradio web UI + headless CLI.
---

# ebook2audiobook (E2A)

A Python/Gradio pipeline that converts DRM-free ebooks to chaptered M4B/MP3 audiobooks. Supports ~1158 languages and voice cloning from reference audio. CPU-capable but most modern TTS engines only run well with a GPU.

- Upstream repo: <https://github.com/DrewThomasson/ebook2audiobook>
- Images: `athomasson2/ebook2audiobook` on Docker Hub — tagged by accelerator flavor (`cpu`, `cu118`, `cu122`, `cu124`, `cu126`, `cu128`, `rocm6.0`, `rocm6.1`, `rocm6.4`, `xpu`, `jetson51`, `jetson60`, `jetson61`, …)
- Hugging Face demo space: <https://huggingface.co/spaces/drewThomasson/ebook2audiobook>

## Compatible install methods

| Infra                         | Runtime                                    | Notes                                                          |
| ----------------------------- | ------------------------------------------ | -------------------------------------------------------------- |
| Host w/ NVIDIA GPU            | Docker + `--gpus all` / compose `gpu` profile | **Recommended.** Modern TTS is slow on CPU                 |
| Host w/ AMD ROCm GPU          | Docker + `/dev/kfd`+`/dev/dri`             | Use `rocm<ver>` image                                          |
| Host w/ Intel Arc GPU         | Docker + `/dev/dri`                        | Use `xpu` image                                                |
| NVIDIA Jetson                 | Docker + `--runtime nvidia`                | Use `jetson<ver>` image                                        |
| CPU-only VM                   | Docker (`cpu` tag)                         | Works but slow; lower-quality engines (YourTTS/Tacotron2) only practical |
| Remote / free                 | HF Spaces, Google Colab, Kaggle notebook   | Linked from upstream README; good for one-offs                 |

## Inputs to collect

| Input             | Example                          | Phase   | Notes                                                                         |
| ----------------- | -------------------------------- | ------- | ----------------------------------------------------------------------------- |
| Accelerator flavor | `cu128` / `cpu` / `rocm6.4`     | Install | Drives `DEVICE_TAG` + image choice                                            |
| Host port         | `7860`                           | Runtime | Gradio UI                                                                     |
| `ebooks/` dir     | bind mount                       | Runtime | Input ebooks (EPUB, PDF, MOBI, TXT, HTML, RTF, CHM, LIT, PDB, FB2, ODT, CBR, CBZ, PRC, LRF, PML, SNB, CBC, RB, TCR) |
| `audiobooks/` dir | bind mount                       | Runtime | Output M4B/MP3/WAV                                                            |
| `models/` dir     | bind mount                       | Runtime | **Multi-GB** TTS model cache — preserve between runs                          |
| `voices/` dir     | bind mount                       | Runtime | Reference voice samples for voice cloning                                     |
| RAM               | 2 GB min, 8 GB recommended       | Host    |                                                                               |
| VRAM              | 1 GB min, 4 GB recommended       | Host    | XTTSv2 wants 4 GB; YourTTS/Tacotron2 work with less                            |

## Install via Docker run (fastest, CPU)

```sh
mkdir -p ebooks audiobooks models voices tmp
docker run --rm -it -p 7860:7860 \
  -v "$PWD/ebooks:/app/ebooks" \
  -v "$PWD/audiobooks:/app/audiobooks" \
  -v "$PWD/models:/app/models" \
  -v "$PWD/voices:/app/voices" \
  -v "$PWD/tmp:/app/tmp" \
  athomasson2/ebook2audiobook:cpu
```

Browse `http://<host>:7860`. Upload an ebook, optionally upload a reference voice, start the run. Output lands in `./audiobooks/`.

## Install via Docker run (GPU / CUDA)

```sh
docker run --rm -it -p 7860:7860 --gpus all \
  -v "$PWD/ebooks:/app/ebooks" \
  -v "$PWD/audiobooks:/app/audiobooks" \
  -v "$PWD/models:/app/models" \
  -v "$PWD/voices:/app/voices" \
  -v "$PWD/tmp:/app/tmp" \
  athomasson2/ebook2audiobook:cu130      # or cu118 / cu122 / cu124 / cu126 / cu128
```

Host must have NVIDIA driver + `nvidia-container-toolkit` configured. Match the CUDA minor version to your host driver when possible.

## Install via Docker Compose

Upstream's `docker-compose.yml` (at <https://github.com/DrewThomasson/ebook2audiobook/blob/main/docker-compose.yml>) defines two profiles — `cpu` and `gpu`:

```sh
git clone https://github.com/DrewThomasson/ebook2audiobook.git
cd ebook2audiobook

# CPU (interactive GUI):
docker compose --profile cpu up --no-log-prefix

# NVIDIA GPU (CUDA 12.8):
DEVICE_TAG=cu130 docker compose --profile gpu up --no-log-prefix

# Headless single-shot conversion:
DEVICE_TAG=cu130 docker compose --profile gpu run --rm ebook2audiobook-gpu \
  --headless --ebook "/app/ebooks/mybook.epub" \
  --voice /app/voices/eng/adult/female/some_voice.wav
```

Pin `APP_VERSION` in your `.env` (upstream compose uses `APP_VERSION=26.5.10` as the default build arg) and check <https://github.com/DrewThomasson/ebook2audiobook/releases> for newer versions.

## Data & config layout

- `./ebooks/` — input ebooks (read + moved on success)
- `./audiobooks/` — output M4B/M4A/MP4/WEBM/MOV/MP3/FLAC/WAV/OGG/AAC
- `./models/` — downloaded TTS model weights. **Can be 5–15 GB per engine.** Preserve across restarts.
- `./voices/` — reference audio for voice cloning; the image ships a directory tree `voices/<lang>/<age>/<gender>/*.wav` for built-in voices
- `./tmp/` — scratch dir (safe to clear between runs)

## Upgrade

1. Releases: <https://github.com/DrewThomasson/ebook2audiobook/releases>
2. `docker pull athomasson2/ebook2audiobook:<flavor>` — or bump `APP_VERSION` in `.env` and `docker compose build`.
3. `docker compose --profile <cpu|gpu> up -d`.
4. Model weights are re-used from `./models/` across upgrades unless a model URL changed — the container will auto-redownload if so.

## Gotchas

- **Legal scope.** Upstream is explicit: "intended for use with non-DRM, legally acquired eBooks only." This recipe is infrastructure; the legal burden sits with the operator.
- **GPU flavor must match your CUDA major version.** Using `cu128` on a host with driver 11.x silently falls back to CPU (or fails to start). Check `nvidia-smi` driver version → pick the matching image tag.
- **MPS (Apple Silicon GPU) is not exposed in Docker** — on macOS the container runs in CPU mode only. Native install gives MPS acceleration.
- **First run downloads multi-GB models.** The `models/` volume will balloon; plan disk space. A clean XTTSv2 install is ~2 GB; Bark is ~5 GB.
- **Headless/CLI mode needs absolute container paths.** `--ebook /app/ebooks/...` and `--voice /app/voices/...` — not host paths.
- **Chapter detection is format-dependent.** EPUB and MOBI expose real chapter metadata; PDF chapter detection is heuristic and usually fails on scanned/image-based PDFs.
- **EPUBs often contain junk** (copyright notices, TOC, acknowledgments). Strip unwanted sections **before** conversion; there's no "skip the preface" flag.
- **Gradio UI is HTTP, no auth.** Put it behind a TLS + auth-aware reverse proxy or restrict to a private network — reference voice uploads are sensitive.
- **`tty: true` + `stdin_open: true`** in the upstream compose: the CPU/GPU services are foreground-interactive by default. Use `docker compose run --rm` for batch headless runs, not `up -d` in a scripted pipeline.
- **Profile flag is required.** `docker compose up` without `--profile cpu` or `--profile gpu` starts no services (upstream compose uses profiles to avoid pulling both).
- **Voice cloning legality varies.** Consent + jurisdiction matter. Upstream does not enforce; operators should.

## Links

- Repo: <https://github.com/DrewThomasson/ebook2audiobook>
- Docker Hub: <https://hub.docker.com/r/athomasson2/ebook2audiobook>
- Compose file: <https://github.com/DrewThomasson/ebook2audiobook/blob/main/docker-compose.yml>
- GPU troubleshooting wiki: <https://github.com/DrewThomasson/ebook2audiobook/wiki/GPU-ISSUES>
- Releases: <https://github.com/DrewThomasson/ebook2audiobook/releases>
- Fine-tuning guide: <https://github.com/DrewThomasson/finetune_xtts_model_collab>
- SML companion repo: <https://github.com/DrewThomasson/E2A-SML>
