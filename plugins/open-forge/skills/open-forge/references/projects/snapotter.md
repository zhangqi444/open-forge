---
name: SnapOtter
description: "Self-hosted image manipulation platform with local AI. Docker. Single container. snapotter-hq/SnapOtter. 47 image tools (resize/crop/compress/convert/watermark), AI background removal/upscaling/OCR, pipelines/workflows, REST API, GPU acceleration optional. AGPLv3."
---

# SnapOtter

**Self-hosted image manipulation platform with 47 tools and local AI.** Resize, crop, compress, convert formats, add watermarks, adjust colors, vectorize, create GIFs, find duplicates, generate passport photos — and more. Local AI for background removal, image upscaling, old photo restoration and colorization, face blur, object erasure, OCR text extraction. Chain tools into reusable pipelines with batch processing. Full REST API. Single container, no Redis, no Postgres.

Built + maintained by **snapotter-hq**. AGPLv3 + commercial license.

- Upstream repo: <https://github.com/snapotter-hq/SnapOtter>
- Docker Hub: <https://hub.docker.com/r/snapotter/snapotter>
- GHCR: `ghcr.io/snapotter-hq/snapotter`
- Docs: <https://docs.snapotter.com>
- Discord: <https://discord.gg/hr3s7HPUsr>

> **License note:** SnapOtter is AGPLv3 for personal/OSS use. A commercial license is required for proprietary SaaS products or when AGPLv3 source-disclosure terms are not acceptable. See the repo LICENSE file.

## Architecture in one minute

- **Single container** — all-in-one; no external services required
- Port **1349**
- Data volume: `/data`
- AI models run on-device (CPU by default; GPU optional via NVIDIA Container Toolkit)
- Multi-arch: **AMD64 + ARM64** (Intel, Apple Silicon, Raspberry Pi)
- Resource: **medium-high** for AI tools (upscaling, BG removal); **low** for standard image tools

## Compatible install methods

| Infra      | Runtime                | Notes                                              |
| ---------- | ---------------------- | -------------------------------------------------- |
| **Docker** | `snapotter/snapotter`  | **Primary** — single container, zero dependencies  |

## Install via Docker

```bash
# CPU (default)
docker run -d --name snapotter \
  -p 1349:1349 \
  -v snapotter-data:/data \
  snapotter/snapotter:latest

# NVIDIA GPU (faster AI: BG removal, upscaling, OCR)
docker run -d --name snapotter \
  -p 1349:1349 \
  --gpus all \
  -v snapotter-data:/data \
  snapotter/snapotter:latest
```

**Default credentials:** username `admin` / password `admin` — you'll be prompted to change on first login.

For Docker Compose, see: <https://docs.snapotter.com/guide/getting-started>

## Tools overview (47 total)

| Category | Tools |
|----------|-------|
| Resize & crop | Resize, crop, pad, smart crop |
| Compression | JPEG/WebP/AVIF compression with quality control |
| Format conversion | Convert between JPEG, PNG, WebP, AVIF, TIFF, GIF, ICO, and more |
| Watermarking | Text and image watermarks; position + opacity control |
| Color & filters | Brightness, contrast, saturation, hue, blur, sharpen, grayscale |
| Vectorize | Raster → SVG vectorization |
| GIFs | Create animated GIFs from images |
| Duplicates | Find and remove duplicate images by content hash |
| Passport photos | Generate standardized passport-format photos |
| **AI: Background removal** | Remove background locally; no API key needed |
| **AI: Upscaling** | Super-resolution upscaling (2×, 4×) |
| **AI: Photo restoration** | Restore old/damaged photos |
| **AI: Colorization** | Add color to black-and-white photos |
| **AI: Object eraser** | Erase selected objects from photos |
| **AI: Face blur** | Blur faces for privacy |
| **AI: Face enhancement** | Enhance facial details |
| **AI: OCR** | Extract text from images |

## Pipelines

Chain any tools into a saved, reusable workflow:
1. Create a pipeline: resize → compress → watermark → convert to WebP
2. Run the pipeline on one image or a batch of hundreds
3. Download the results as a ZIP

## REST API

Every tool is accessible via API with API key authentication:

```bash
curl -X POST http://localhost:1349/api/tools/resize \
  -H "X-API-Key: your-api-key" \
  -F "file=@photo.jpg" \
  -F "width=800" \
  -F "height=600" \
  -o resized.jpg
```

Interactive API docs at `http://localhost:1349/api/docs`.

## Gotchas

- **GPU is optional but recommended for AI tools.** CPU AI inference works but is significantly slower. Add `--gpus all` and install [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html) for GPU acceleration. Falls back to CPU gracefully if no GPU found.
- **Change default credentials immediately.** Default `admin`/`admin` is prompted to change on first login, but do it before exposing to any network.
- **AGPLv3 license for source disclosure.** If you modify SnapOtter and offer it as a network service, AGPLv3 requires you to make the modified source available. For proprietary/SaaS use, contact snapotter-hq for commercial licensing.
- **Analytics opt-in prompt.** On first run, SnapOtter asks whether to share anonymous analytics (tool usage, errors — never file data). Set `ANALYTICS_ENABLED=false` to disable entirely without the prompt.
- **AI models download on first use.** Background removal, upscaling, and OCR models are downloaded the first time those tools are used. Subsequent uses are fast (models cached in the data volume). Ensure internet access on first use.
- **No PRs accepted.** The project doesn't accept pull requests. Submit bugs and feature requests via GitHub Issues only.

## Backup

```sh
docker stop snapotter
docker run --rm -v snapotter-data:/data -v $(pwd):/backup alpine \
  tar czf /backup/snapotter-$(date +%F).tgz /data
docker start snapotter
```

## Upgrade

```sh
docker pull snapotter/snapotter:latest
docker stop snapotter && docker rm snapotter
docker run -d --name snapotter -p 1349:1349 -v snapotter-data:/data snapotter/snapotter:latest
```

## Project health

Active single-container development, 47 tools, local AI, pipelines, REST API, multi-arch. AGPLv3 + commercial license.

## Image-tools-family comparison

- **SnapOtter** — single container, 47 tools + local AI, pipelines, REST API, AGPLv3
- **GIMP** — desktop app; not Docker/server-focused
- **Imagor** — Go, image processing server; API-focused; no UI; fewer tools
- **Thumbor** — Python, image CDN/thumbnailer; different use case
- **Pixie** — PHP image editor; web UI; different tool set

**Choose SnapOtter if:** you want a self-hosted image manipulation platform with 47 tools, local AI (background removal/upscaling/OCR/colorization), pipeline batch processing, and a REST API — all in one Docker container.

## Links

- Repo: <https://github.com/snapotter-hq/SnapOtter>
- Docs: <https://docs.snapotter.com>
- Docker Hub: <https://hub.docker.com/r/snapotter/snapotter>
- Discord: <https://discord.gg/hr3s7HPUsr>
