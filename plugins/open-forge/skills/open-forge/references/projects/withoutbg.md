---
name: Withoutbg
description: "Self-hosted background removal API server. Docker. Python. withoutbg/withoutbg. REST API compatible with remove.bg, runs local AI model (rembg/BRIA), multiple model options, simple HTTP POST API, batch processing."
---

# Withoutbg

**Self-hosted background removal API server.** Drop-in replacement for the remove.bg API — send an image, get back the image with background removed. Runs entirely locally using AI models (rembg, BRIA RMBG 2.0). Same HTTP interface as remove.bg so tools that support remove.bg work out of the box. Multiple model options.

Built + maintained by **withoutbg**. See repo license.

- Upstream repo: <https://github.com/withoutbg/withoutbg>
- Docker Hub: check GHCR for image

## Architecture in one minute

- **Python** server (Flask/FastAPI-based REST API)
- AI models: **rembg** (U2Net family) + **BRIA RMBG 2.0** (state-of-the-art)
- Models downloaded on first run (cached in volume)
- REST API: `POST /api/removebg` with image → returns PNG with transparent background
- Compatible with remove.bg API format
- CPU inference (GPU optional)
- Resource: **medium** — Python + AI model; first inference is slower (model load); subsequent calls faster

## Compatible install methods

| Infra      | Runtime           | Notes                                                          |
| ---------- | ----------------- | -------------------------------------------------------------- |
| **Docker** | GHCR/Docker image | **Primary** — model weights download automatically on start    |

## Install via Docker

```bash
docker run -d \
  -p 5000:5000 \
  -v ./models:/app/models \
  --name withoutbg \
  ghcr.io/withoutbg/withoutbg:latest
```

Or from the repo's compose file:
```bash
git clone https://github.com/withoutbg/withoutbg.git
cd withoutbg
docker compose up -d
```

## API usage

**Remove background from an image:**

```bash
# Using form data (binary file)
curl -X POST http://localhost:5000/api/removebg \
  -F "image_file=@photo.jpg" \
  -o output.png

# Using base64 (like remove.bg API)
curl -X POST http://localhost:5000/api/removebg \
  -F "image_file_b64=$(base64 -w0 photo.jpg)" \
  -o output.png

# From a URL
curl -X POST http://localhost:5000/api/removebg \
  -F "image_url=https://example.com/photo.jpg" \
  -o output.png
```

The response is a PNG with transparent background.

## Model options

| Model | Notes |
|-------|-------|
| rembg (U2Net) | Fast, good general-purpose BG removal |
| rembg (isnet-general-use) | Higher quality; slower |
| BRIA RMBG 2.0 | State-of-the-art quality; larger model |

Select model via environment variable or API parameter. Models are downloaded once and cached in the mounted volume.

## remove.bg API compatibility

Withoutbg's API is designed to match remove.bg's API format. Tools/scripts that call `https://api.remove.bg/v1.0/removebg` can often be redirected to `http://localhost:5000/api/removebg` with minimal or no code changes.

This means: Photoshop plugins, CLI tools, and web apps that support remove.bg as a backend can be pointed to your self-hosted Withoutbg instance.

## Gotchas

- **First run downloads models.** AI model weights download automatically on first startup — this can take minutes depending on your internet connection and selected model. The models are cached in the mounted volume for subsequent runs.
- **CPU inference is slow for large batches.** Processing a single image takes 1–5 seconds on CPU depending on the model and image size. For high-volume use, GPU inference is significantly faster (configure CUDA if available).
- **BRIA RMBG 2.0 requires ~2 GB VRAM / RAM.** The highest-quality model is larger. On CPU, it's slower but functional.
- **Output is always PNG with transparency.** The background is replaced with transparent alpha — not white or a specific color. Further compositing is left to the caller.
- **remove.bg API key not needed.** That's the point — you're running the model locally. No API costs, no usage limits, no data leaving your server.
- **Not all remove.bg API parameters are supported.** Withoutbg implements the core background removal endpoint. Advanced remove.bg parameters (crop, size, bg_color, add_shadow, etc.) may not be fully implemented. Test your use case.

## Backup

Model weights are cached in the mounted volume — they can be redownloaded if lost. No user data to back up.

## Upgrade

```sh
docker compose pull && docker compose up -d
```

## Project health

Active Python development, remove.bg API compatibility, multiple rembg + BRIA models. See repo for current status.

## Background-removal-family comparison

- **Withoutbg** — Python, local AI, remove.bg API compatible, rembg+BRIA, self-hosted
- **remove.bg** — SaaS; the commercial reference; paid after free tier
- **rembg** — Python CLI/library; the underlying model Withoutbg uses; no HTTP API server
- **BackgroundRemoval.js** — browser/client-side; no server

**Choose Withoutbg if:** you want a self-hosted, remove.bg-compatible API server for background removal — no API costs, no data leaving your server, with multiple AI model options.

## Links

- Repo: <https://github.com/withoutbg/withoutbg>
- rembg (underlying model): <https://github.com/danielgatis/rembg>
