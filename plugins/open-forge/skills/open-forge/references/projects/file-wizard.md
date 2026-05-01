# File Wizard

**Self-hosted browser-based file conversion, OCR, and audio transcription tool wrapping FFmpeg, LibreOffice, Pandoc, ImageMagick, faster-whisper, and Tesseract.**
GitHub: https://github.com/LoredCast/filewizard

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux | Docker (CPU) | Default — no GPU required |
| Linux with NVIDIA GPU | Docker (CUDA image) | GPU-accelerated Whisper transcription |

---

## Inputs to Collect

### All phases
- `LOCAL_ONLY` — True for local/trusted use (no auth); False to enable OAuth
- `SECRET_KEY` — required when LOCAL_ONLY=False (OAuth mode)
- Upload and processed output paths

---

## Software-Layer Concerns

### Docker Compose
```yaml
version: "3.9"
services:
  web:
    image: loredcast/filewizard:latest
    environment:
      - LOCAL_ONLY=True        # set False to enable OAuth/OIDC
      - SECRET_KEY=            # set when LOCAL_ONLY=False
      - UPLOADS_DIR=/app/uploads
      - PROCESSED_DIR=/app/processed
      - OMP_NUM_THREADS=1
      - DOWNLOAD_KOKORO_ON_STARTUP=true
    ports:
      - "6969:8000"
    volumes:
      - ./config:/app/config   # settings.yml lives here
      - ./uploads_data:/app/uploads
      - ./processed_data:/app/processed
```

### Image variants
- `loredcast/filewizard:latest` — full release (no CUDA)
- `loredcast/filewizard:0.3-small` — smaller image, omits TeX and markitdown
- `loredcast/filewizard:0.3-cuda` — CUDA-enabled for GPU transcription

### Build variants (from source)
```bash
docker build --build-arg BUILD_TYPE=full  -t filewizard:full .
docker build --build-arg BUILD_TYPE=small -t filewizard:small .
docker build --build-arg BUILD_TYPE=cuda  -t filewizard:cuda .
```

### Ports
- `6969` (host) → `8000` (container) — web UI

### Extensibility
- Additional CLI converters can be added via `settings.yml` in the config volume

---

## Upgrade Procedure

1. docker compose pull
2. docker compose up -d

---

## Gotchas

- **Security warning:** exposing this app publicly without OAuth enabled risks arbitrary code execution — intended for local use or behind a properly configured OIDC provider
- LOCAL_ONLY=True disables all authentication — suitable only for trusted networks
- CUDA image requires NVIDIA Container Toolkit on the host
- Whisper transcription models are CPU-only by default; use the cuda image for GPU acceleration
- settings.yml controls which conversion tools are available in the UI

---

## References
- GitHub: https://github.com/LoredCast/filewizard#readme
- Docker Hub: https://hub.docker.com/r/loredcast/filewizard
