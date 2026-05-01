# HandBrake Web

**Web interface for HandBrakeCLI across multiple machines — server/worker architecture lets you queue and manage video encoding jobs from a browser on headless devices, with GPU hardware acceleration support.**
GitHub: https://github.com/TheNickOfTime/handbrake-web

> Note: Not affiliated with the official HandBrake project. Uses HandBrakeCLI under the hood.

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux | Docker Compose | Server + one or more workers |

---

## Inputs to Collect

### Required
- Media path — host path to video files (must be identical on all containers)
- Data path — host path for server config/state
- `user:group` — UID:GID with read/write access to media (avoid running as root)
- `WORKER_ID` — unique name for each worker container

---

## Software-Layer Concerns

### Architecture
- **Server** — coordinator + web UI; low CPU, can run on any device
- **Worker(s)** — does the encoding via HandBrakeCLI; CPU/GPU intensive; run one per machine

### Docker Compose (server + single worker)
```yaml
services:
  handbrake-server:
    image: ghcr.io/thenickoftime/handbrake-web-server:latest
    container_name: handbrake-web-server
    user: "1000:1000"   # set to UID:GID with media access
    ports:
      - 9999:9999
    volumes:
      - /path/to/your/data:/data
      - /path/to/your/media:/video   # must match across all containers

  handbrake-worker:
    image: ghcr.io/thenickoftime/handbrake-web-worker:latest
    container_name: handbrake-web-worker
    user: "1000:1000"
    environment:
      - WORKER_ID=handbrake-worker
      - SERVER_URL=handbrake-server
      - SERVER_PORT=9999
    volumes:
      - /path/to/your/media:/video   # must match server
    depends_on:
      - handbrake-server
```

### Multiple workers
Add additional worker services with unique `WORKER_ID` values. Workers can run on separate machines — set `SERVER_URL=http://<server-host>` in that case.

### Hardware acceleration
Additional configuration required per GPU type:
- Intel QSV — pass through `/dev/dri`
- NVIDIA NVENC — use `nvidia` runtime and pass GPU device
See: https://github.com/TheNickOfTime/handbrake-web/wiki/Hardware-Acceleration

### Presets
HandBrake Web uses presets exported from the HandBrake desktop app (.json). Upload via the web UI under 'Presets'. No built-in preset creator yet.

### Ports
- `9999` — web UI

---

## Upgrade Procedure

1. docker compose pull
2. docker compose up -d

---

## Gotchas

- Media path `/video` **must be identical** across server and all worker containers
- Run one worker per physical machine (CPU bottleneck)
- Presets must be exported from HandBrake desktop and uploaded manually
- No user authentication yet — keep behind a firewall or reverse proxy with auth
- AMD VCN hardware encoding not yet supported (Intel QSV and NVIDIA NVENC work)
- Project is in active development (v0.9.x); use at your own risk

---

## References
- Setup guide: https://github.com/TheNickOfTime/handbrake-web/wiki/Setup-Guide
- Hardware acceleration: https://github.com/TheNickOfTime/handbrake-web/wiki/Hardware-Acceleration
- GitHub: https://github.com/TheNickOfTime/handbrake-web#readme
