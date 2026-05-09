---
name: audiomuse-ai-project
description: AudioMuse-AI recipe for open-forge. Self-hosted, Dockerized AI-powered music playlist generator using sonic analysis (Librosa + ONNX). Integrates with Jellyfin, Navidrome, LMS/Lyrion, and Emby. No external APIs required.
---

# AudioMuse-AI

Open-source, Dockerized automatic playlist generator for self-hosted music libraries. Uses local sonic analysis (Librosa + ONNX) to cluster songs by sound — not metadata — and generate playlists by mood, tempo, energy, or similarity. No external APIs required. Upstream: https://github.com/NeptuneHub/AudioMuse-AI. License: MIT.

Language: Python (Flask + RQ worker). Database: PostgreSQL + Redis. Images: `ghcr.io/neptunehub/audiomuse-ai:latest`. Multi-arch: amd64, arm64.

AudioMuse-AI runs as two containers sharing one image — a Flask web frontend (port 8000) and an RQ background worker — plus PostgreSQL and Redis. After running an initial library analysis, you unlock clustering, instant playlists, music maps, song-path generation, text search, and sonic fingerprinting.

## Compatible combos

| Infra | Media server | Notes |
|---|---|---|
| Any Linux host (incl. Raspberry Pi 5, Mac Mini M4) | Jellyfin | Primary integration — official plugin available |
| Any Linux host | Navidrome | Navidrome plugin available |
| Any Linux host | LMS / Lyrion | Supported via Subosnic-compatible API |
| Any Linux host | Emby | Supported |
| Kubernetes (amd64, arm64) | Any above | Helm chart: https://github.com/NeptuneHub/AudioMuse-AI-helm |

**CPU requirement**: 4-core Intel with AVX2 (2015+) or ARM. If running in a VM (e.g. Proxmox), pass through the host CPU — QEMU virtual CPU lacks AVX2 and will prevent startup.

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | Which media server to integrate with | Jellyfin, Navidrome, LMS, Emby |
| database | POSTGRES_PASSWORD | Change from default |
| config | Timezone (TZ) | Used for scheduling |
| media-server | Media server URL + API key | Configured via Setup Wizard in the web UI after first start |
| optional | GPU acceleration | See GPU deployment docs for nvidia variant |

## Software-layer concerns

### Docker Compose (recommended)

Based on upstream deployment/docker-compose.yaml at https://github.com/NeptuneHub/AudioMuse-AI/blob/main/deployment/docker-compose.yaml.

  git clone https://github.com/NeptuneHub/AudioMuse-AI.git
  cd AudioMuse-AI
  cp deployment/.env.example deployment/.env
  # Edit deployment/.env: change POSTGRES_PASSWORD, set TZ
  docker compose -f deployment/docker-compose.yaml up -d

AudioMuse-AI web UI is available at http://localhost:8000.

On first start, a Setup Wizard walks through connecting to your media server. Configuration is persisted in the database — no env var changes needed for most settings after v1.0.0.

### Compose service layout

| Service | Image | Role |
|---|---|---|
| audiomuse-ai-flask | ghcr.io/neptunehub/audiomuse-ai:latest | Web frontend (Flask), port 8000 |
| audiomuse-ai-worker | ghcr.io/neptunehub/audiomuse-ai:latest | RQ background worker (sonic analysis) |
| postgres | postgres:15-alpine | Database |
| redis | redis:7-alpine | Task queue |

Both audiomuse-ai services use the same image; the SERVICE_TYPE env var controls which mode runs (flask or worker).

### Key environment variables

| Variable | Purpose | Default |
|---|---|---|
| SERVICE_TYPE | flask or worker | set per service |
| TZ | Timezone | UTC |
| POSTGRES_USER | PostgreSQL username | audiomuse |
| POSTGRES_PASSWORD | PostgreSQL password | audiomusepassword |
| POSTGRES_DB | Database name | audiomusedb |
| POSTGRES_HOST | Host (service name) | postgres |
| REDIS_URL | Redis connection | redis://redis:6379/0 |
| TEMP_DIR | Temp audio files mount path | /app/temp_audio |

### Image tags

| Tag | Description |
|---|---|
| :latest | Stable build from main branch — recommended |
| :devel | Development build — may be unstable |
| :X.Y.Z | Pinned release tag (e.g. :1.0.3) |
| :latest-noavx2 | Experimental — for CPUs without AVX2 (not recommended) |
| :latest-nvidia | GPU-accelerated variant |

### Running the first analysis

1. Open http://localhost:8000
2. Complete the Setup Wizard (connect media server)
3. Navigate to "Analysis and Clustering"
4. Click "Start Analysis" to scan the entire library
5. Wait for completion — duration depends on library size and CPU

After analysis, features like clustering, music map, instant playlists, and song paths become available.

## Upgrade procedure

  docker compose -f deployment/docker-compose.yaml pull
  docker compose -f deployment/docker-compose.yaml up -d

After upgrading to v1.0.3+, run a 1-album analysis to create new search indexes if upgrading from an older version.

## Gotchas

- AVX2 required — standard Intel/AMD CPUs from 2015+ have it, but QEMU virtual CPUs do not. For Proxmox deployments, pass through the host CPU in VM settings.
- RAM minimum 8 GB — sonic analysis is memory-intensive; the worker container can OOM on systems under this threshold with large libraries.
- NVMe SSD strongly recommended — analysis reads many audio files; spinning disks will be extremely slow.
- Setup Wizard on first start — from v1.0.0, media server settings are configured via the web wizard and stored in the DB. Legacy environment variable configs from older versions are imported automatically on first start.
- Multiple workers — for large libraries, run additional worker containers by adding more audiomuse-ai-worker service instances to the Compose file (they all share the same Redis queue).
- v1.0.2 migration — v1.0.2 introduced providers migration and multi-user support. After upgrading from 0.x, the database migration runs automatically on startup.

## Links

- Upstream README: https://github.com/NeptuneHub/AudioMuse-AI
- Architecture docs: https://github.com/NeptuneHub/AudioMuse-AI/blob/main/docs/ARCHITECTURE.md
- Deployment docs: https://github.com/NeptuneHub/AudioMuse-AI/blob/main/docs/DEPLOYMENT.md
- GPU deployment: https://github.com/NeptuneHub/AudioMuse-AI/blob/main/docs/GPU.md
- Helm chart: https://github.com/NeptuneHub/AudioMuse-AI-helm
- Jellyfin plugin: https://github.com/NeptuneHub/audiomuse-ai-plugin
