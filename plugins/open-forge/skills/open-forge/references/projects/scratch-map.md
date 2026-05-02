# Scratch Map

An open-source scratch-off style interactive map to track your travels. Supports world map plus country/regional maps (US states, Canada, Australia, France, Mexico, Japan, Spain, Britain, Germany, New Zealand, Brazil, China, India, and more). Built with Node.js/Express.

- **Official site / docs:** https://github.com/ad3m3r5/scratch-map
- **Docker image:** `ad3m3r5/scratch-map:latest` (also `ghcr.io/ad3m3r5/scratch-map`)
- **License:** Open-source

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Docker host | Docker Compose | Single container, Node.js + LowDB |
| Any Docker host | docker run | Simple single-command deploy |

---

## Inputs to Collect

### Deploy Phase
| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `ADDRESS` | No | `0.0.0.0` | Bind address |
| `PORT` | No | `3000` | HTTP port |
| `DATA_DIR` | Recommended | `APP_DIR/data/` | External data directory path |
| `LOG_LEVEL` | No | `INFO` | Log verbosity (`INFO` or `DEBUG`) |
| `ENABLE_SHARE` | No | `false` | Enable view-only `/view` routes for sharing maps |

---

## Software-Layer Concerns

### Config
- All configuration via environment variables
- No config file required

### Data Directories
- `DATA_DIR` — where map scratch data (LowDB JSON) is stored
- Mount to a host path for persistence; default is inside container (lost on recreate)
- Set correct ownership: `chown -R 1000:1000 /opt/containers/scratch-map/data`

### Ports
- `3000` (default, configurable via `PORT`)

---

## Minimal docker-compose.yml

```yaml
services:
  scratch-map:
    container_name: scratch-map
    image: ad3m3r5/scratch-map:latest
    restart: unless-stopped
    ports:
      - "3000:3000"
    environment:
      ADDRESS: "0.0.0.0"
      PORT: 3000
      DATA_DIR: "/data"
      LOG_LEVEL: "INFO"
    volumes:
      - ./data:/data
```

Setup:
```bash
mkdir -p ./data
chown -R 1000:1000 ./data
docker compose up -d
```

---

## Upgrade Procedure

```bash
docker compose pull scratch-map
docker compose up -d scratch-map
```

Data persists in the mounted `DATA_DIR` volume.

---

## Gotchas

- **Data persistence:** Always mount `DATA_DIR` to a host path — default is inside the container and will be lost on recreate
- **Permissions:** The `chown 1000:1000` step is required on Linux before first run
- **Port conflict:** Default port 3000 is commonly used; change the host port if needed
- **Share feature:** Set `ENABLE_SHARE=true` to allow read-only `/view` routes for sharing your map with others
- **Regional maps:** Many country/regional maps included beyond world map — see the MAPS.md doc for the full list

---

## References
- README: https://github.com/ad3m3r5/scratch-map
- Install guide: https://raw.githubusercontent.com/ad3m3r5/scratch-map/HEAD/docs/INSTALL.md
- Docker Hub: https://hub.docker.com/r/ad3m3r5/scratch-map
