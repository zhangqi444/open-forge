# 8mb.local

**Self-hosted GPU-accelerated video compressor. Drop a file, choose a target size, get a compressed output via AV1/HEVC/H.264 with NVIDIA NVENC or CPU fallback.**
GitHub: https://github.com/JMS1717/8mb.local

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Linux with NVIDIA GPU | Docker | NVENC hardware encoding (recommended) |
| Any Linux | Docker | CPU-only software encoding fallback |

---

## Inputs to Collect

### All phases
- `UPLOADS_DIR` — host path for uploaded input files
- `OUTPUTS_DIR` — host path for compressed outputs
- GPU availability — NVIDIA NVENC (optional, falls back to CPU automatically)

---

## Software-Layer Concerns

### Docker (GPU)
```
docker run -d \
  --name 8mblocal \
  --gpus all \
  -e NVIDIA_DRIVER_CAPABILITIES=compute,video,utility \
  -p 8001:8001 \
  -v ./uploads:/app/uploads \
  -v ./outputs:/app/outputs \
  jms1717/8mblocal:latest
```
Note: NVIDIA_DRIVER_CAPABILITIES=compute,video,utility is REQUIRED for NVENC — it mounts the encoding libraries into the container.

### Docker Compose (GPU)
```yaml
services:
  8mblocal:
    image: jms1717/8mblocal:latest
    container_name: 8mblocal
    ports:
      - "8001:8001"
    volumes:
      - ./uploads:/app/uploads
      - ./outputs:/app/outputs
      - ./.env:/app/.env  # optional config override
    gpus: all
    environment:
      - NVIDIA_DRIVER_CAPABILITIES=compute,video,utility
    restart: unless-stopped
```

### Docker (CPU-only — no GPU flags)
```
docker run -d --name 8mblocal -p 8001:8001 \
  -v ./uploads:/app/uploads -v ./outputs:/app/outputs \
  jms1717/8mblocal:latest
```

### Ports
- `8001` — web UI

### Architecture
SvelteKit UI + FastAPI backend + Celery worker + Redis broker + Server-Sent Events for real-time progress

---

## Upgrade Procedure

1. docker pull jms1717/8mblocal:latest
2. docker compose up -d (or docker stop/run)

---

## Gotchas

- NVIDIA_DRIVER_CAPABILITIES env var is mandatory for GPU — forgetting it silently disables NVENC
- Startup validates encoder availability — check logs if GPU encoding appears unavailable
- Output re-encodes automatically if result exceeds target by more than 2%
- Supported codecs: AV1, HEVC (H.265), H.264; output containers: MP4 or MKV
- Job history and auto-download are enabled by default
- Batch compression (multiple files) supported

---

## References
- GitHub: https://github.com/JMS1717/8mb.local#readme
