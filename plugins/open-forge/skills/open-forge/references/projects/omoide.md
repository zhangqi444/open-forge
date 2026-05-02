---
name: omoide
description: Recipe for Omoide — offline-first self-hosted photo/video library with local AI. Face recognition, semantic search, auto-tagging, duplicate detection, map view. Python/FastAPI + React + SQLite. PolyForm Noncommercial license.
---

# Omoide

Offline-first, self-hosted photo and video library with local AI organization. Upstream: https://github.com/EinAeffchen/Omoide

Python/FastAPI backend + React/MUI frontend + SQLite with sqlite-vec for vector search. All AI runs locally: face recognition (InsightFace/ONNX), semantic search (OpenCLIP), auto-tagging, duplicate detection (perceptual hashing), and scene detection for videos. No cloud, no subscriptions. Also available as a desktop binary for Windows/Linux/macOS.

> **License: PolyForm Noncommercial 1.0.0** — free for personal, non-commercial use only. See LICENSE.md.

## Compatible combos

| Runtime | Notes |
|---|---|
| Docker Compose | Recommended for NAS/server deployment |
| Desktop binary | Download from releases — Windows/Linux/macOS |
| Python (dev) | FastAPI + uvicorn direct, requires Python 3.12+, FFmpeg, Node 18+ |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | Media directory (HOST_MEDIA_DIR) | Host path containing your photos/videos |
| preflight | Data directory (HOST_DATA_DIR) | Fast SSD path for database, thumbnails, AI index |
| preflight | Port (PORT) | Default: 8123 |
| config (opt) | ENV_FILE path | Points to omoide.env for app-level settings |

## Software-layer concerns

**Two config files:**
- `.env` — infrastructure settings (ports, host directories, env file path)
- `omoide.env` — app-level settings (AI features, scan intervals, etc.)

Copy templates on first setup:
```bash
cp .env.template .env
cp omoide.env.example omoide.env
```

**Key `.env` vars:**
| Var | Description |
|---|---|
| PORT | Web UI port (default: 8123) |
| HOST_MEDIA_DIR | Host path to your media files |
| HOST_DATA_DIR | Host path for DB, thumbnails, AI embeddings |
| ENV_FILE | Path to omoide.env |

**Key `omoide.env` vars (all optional — defaults shown):**
| Var | Default | Description |
|---|---|---|
| OMOIDE_GENERAL__ENABLE_PEOPLE | true | Enable face recognition features |
| OMOIDE_GENERAL__PRESENTATION_MODE | false | Read-only mode for sharing |
| OMOIDE_SCAN__AUTO_SCAN | false | Enable automatic background scans |
| OMOIDE_SCAN__SCAN_INTERVAL_MINUTES | 15 | Minutes between auto scans |
| OMOIDE_SCAN__AUTO_ROTATE | true | Respect EXIF rotation |

**AI model downloads:** On first run, Omoide downloads AI models (OpenCLIP, InsightFace). Ensure internet access on first launch; subsequent runs work offline.

**arm64 note:** Use the Docker Hub image (as referenced in docker-compose.yml) or build with `docker buildx`/`make build-image-arm64`. Ensure `sqlite-vec` platform matches.

**Data path:** HOST_DATA_DIR should be an SSD path for acceptable performance with large libraries.

## Docker Compose

Follow the upstream quick-start — copy and edit the provided templates:

```bash
git clone https://github.com/EinAeffchen/Omoide.git
cd Omoide
cp .env.template .env
cp omoide.env.example omoide.env
# Edit .env: set HOST_MEDIA_DIR, HOST_DATA_DIR, PORT
docker compose up -d
```

Open http://localhost:8123

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

Back up HOST_DATA_DIR (database + embeddings) before upgrading major versions.

## Gotchas

- **PolyForm Noncommercial license** — personal use only. Commercial use requires a separate license from the author.
- **First-run model download** — AI models are downloaded on first launch; requires internet access. Subsequent launches are fully offline.
- **HOST_DATA_DIR on SSD recommended** — the AI embedding index and thumbnail cache benefit significantly from fast storage.
- **arm64 sqlite-vec** — the default amd64 sqlite-vec binary won't work on ARM hosts; use the pre-built Docker Hub image or rebuild for your platform.
- **Ensure directories exist** — Omoide may fail with permission errors if HOST_MEDIA_DIR or HOST_DATA_DIR don't already exist on the host.

## Links

- Upstream repository: https://github.com/EinAeffchen/Omoide
- Releases (desktop binaries): https://github.com/EinAeffchen/Omoide/releases/latest
- License: https://github.com/EinAeffchen/Omoide/blob/main/LICENSE.md
