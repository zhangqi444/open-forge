# Fast Music Remover

**Self-hosted media processor that removes background music and noise from video/audio files — web UI, REST API, Docker image, C++ processing core with FFmpeg and ML models.**
GitHub: https://github.com/omeryusufyagci/fast-music-remover
Discord: https://discord.gg/xje3PQTEYp

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux | Docker | Recommended — pre-built image on GHCR |
| Linux / macOS | Bare metal | Python 3.9+ + FFmpeg + CMake + C++ deps |

---

## Inputs to Collect

### Required (bare metal only)
- FFmpeg path — default `/usr/bin/ffmpeg`; on macOS Homebrew: `/opt/homebrew/bin/ffmpeg`

---

## Software-Layer Concerns

### Docker (quickest)
```bash
docker pull ghcr.io/omeryusufyagci/fast-music-remover:latest
docker run -p 8080:8080 ghcr.io/omeryusufyagci/fast-music-remover:latest
```
Access the web UI at http://localhost:8080

### Docker Compose
```yaml
services:
  fast-music-remover:
    image: ghcr.io/omeryusufyagci/fast-music-remover:latest
    ports:
      - "8080:8080"
    restart: unless-stopped
```

### Ports
- `8080` — web UI and REST API

### Bare metal prerequisites
- Python 3.9+
- FFmpeg
- CMake
- nlohmann-json (C++ JSON library)
- libsndfile

Update `config.json` with correct `ffmpeg_path` if not at the default location.

### Current capabilities
- Background music filtering
- Noise removal / audio enhancement
- Web UI for easy access
- REST API for programmatic use

### Roadmap
- Realtime processing (planned)
- Additional ML models
- Cross-platform launcher for local setup

---

## Upgrade Procedure

1. docker pull ghcr.io/omeryusufyagci/fast-music-remover:latest
2. docker compose up -d (or re-run docker run)

---

## Gotchas

- Early-stage project — stable release in progress; expect changes
- macOS users: FFmpeg path via Homebrew is `/opt/homebrew/bin/ffmpeg` — update `config.json`
- Docker is the recommended path; bare metal requires several C++ build dependencies

---

## References
- GitHub: https://github.com/omeryusufyagci/fast-music-remover#readme
- Discord: https://discord.gg/xje3PQTEYp
