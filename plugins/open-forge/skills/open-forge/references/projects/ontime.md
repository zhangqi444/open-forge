# Ontime

**Browser-based event rundown and show-calling tool for live productions.**
Official site: https://getontime.no
GitHub: https://github.com/cpvalente/ontime

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux | Docker Compose | Primary self-hosted method |
| Any Linux | npm CLI (`@getontime/cli`) | Alternative install |
| macOS / Windows / Linux | Native app | Desktop installer available |

---

## Inputs to Collect

### All phases
- `DOMAIN` — public hostname if exposing externally (e.g. `ontime.example.com`)
- `DATA_DIR` — host path for persistent show data (e.g. `/opt/ontime/data`)
- `TZ` — timezone string (e.g. `America/New_York`)

---

## Software-Layer Concerns

### Config
- No separate config file; all configuration done via the web UI
- Timezone set via `TZ` environment variable

### Data
- All show data stored in `/data/` inside container
- Mount to host volume for persistence

### Ports
- `4001/tcp` — main web UI and HTTP API
- `8888/udp` — OSC input
- `9999/udp` — OSC output

### Docker Compose
```yaml
services:
  ontime:
    container_name: ontime
    image: getontime/ontime:v4.8.0
    ports:
      - '4001:4001/tcp'
      - '8888:8888/udp'
      - '9999:9999/udp'
    volumes:
      - './ontime-data:/data/'
    environment:
      - TZ=America/New_York
    restart: unless-stopped
```

---

## Upgrade Procedure

1. `docker compose pull`
2. `docker compose up -d`
3. Check logs: `docker compose logs -f ontime`

---

## Gotchas

- OSC UDP ports are needed for integration with vMix, Qlab, disguise, and Bitfocus Companion
- Ontime is designed for live environments — no persistent database, show files are JSON
- Cloud-hosted version available at getontime.no if self-hosting is not needed
- Available as native desktop app (Windows, macOS, Linux AppImage) if Docker is unavailable

---

## References
- [Documentation](https://docs.getontime.no)
- [Docker Hub](https://hub.docker.com/r/getontime/ontime)
- [GitHub README](https://github.com/cpvalente/ontime#readme)
