# OpenRouteService

OpenRouteService is a highly customizable, performant routing service powered by OpenStreetMap data. It provides directions, isochrones, time-distance matrices, route optimization, and snapping services for multiple transport modes.

**Website:** https://openrouteservice.org/
**Source:** https://github.com/GIScience/openrouteservice
**License:** GPL-3.0
**Stars:** ~1,885

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux/VPS | Docker Compose | Recommended |
| Any Linux/VPS | Java (JAR) | Manual build |
| Kubernetes | Helm | Community chart |

---

## Inputs to Collect

### Phase 1 — Planning
- **OSM data file**: PBF format (e.g. from https://download.geofabrik.de/) — region-specific or planet
- **Transport profiles**: driving-car, driving-hgv, foot-walking, foot-hiking, cycling-regular, cycling-road, cycling-mountain, wheelchair, etc.
- **Memory available**: routing graph build is RAM-intensive; continent-scale needs 16–64 GB RAM

### Phase 2 — Deployment
- `ORS_PORT` (default: 8080)
- `ORS_PROFILES`: comma-separated list of enabled profiles
- OSM file path (mounted into container)
- Elevation cache directory (optional but recommended)

---

## Software-Layer Concerns

### Directory Structure
```
ors-docker/
├── config/         # ors-config.yml overrides
├── elevation_cache/ # cached elevation data (avoid re-download)
├── graphs/          # built routing graphs (large, persist these!)
├── files/           # OSM PBF source files
└── logs/
```

### Quick Start (Docker Compose)
```bash
mkdir -p ors-docker/config ors-docker/elevation_cache ors-docker/graphs ors-docker/files ors-docker/logs

# Download docker-compose.yml from latest release
wget https://github.com/GIScience/openrouteservice/releases/latest/download/docker-compose.yml

# Place your OSM PBF in ors-docker/files/
cp heidelberg.osm.pbf ors-docker/files/

docker compose up -d
docker compose logs -f
```

Service available at `http://localhost:8080/ors/v2/status`.

### Example docker-compose.yml (simplified)
```yaml
services:
  ors-app:
    image: openrouteservice/openrouteservice:latest
    ports:
      - "8080:8082"
    volumes:
      - ./ors-docker/graphs:/home/ors/files/graphs
      - ./ors-docker/elevation_cache:/home/ors/files/elevation_cache
      - ./ors-docker/config:/home/ors/config
      - ./ors-docker/logs:/home/ors/logs
      - ./ors-docker/files:/home/ors/files/osm_file
    environment:
      - CONTAINER_LOG_LEVEL=INFO
```

### Graph Build Time
- First start builds routing graphs from the OSM file — can take minutes to hours depending on region size
- Graphs persist in `ors-docker/graphs/` and survive container restarts
- Check `ors-docker/logs/ors.log` for build progress

### Config Override
Create `ors-docker/config/ors-config.yml` to override settings:
```yaml
ors:
  engine:
    profiles:
      driving-car:
        enabled: true
      foot-walking:
        enabled: true
```

### API Endpoints (all on port 8080)
- Directions: `GET /ors/v2/directions/{profile}?start=lng,lat&end=lng,lat`
- Isochrones: `POST /ors/v2/isochrones/{profile}`
- Matrix: `POST /ors/v2/matrix/{profile}`
- Health: `GET /ors/v2/health`
- Status: `GET /ors/v2/status`

### Data Volumes
| Path | What's stored |
|------|--------------|
| `/home/ors/files/graphs` | Built routing graphs (persist!) |
| `/home/ors/files/elevation_cache` | Elevation tiles cache |
| `/home/ors/files/osm_file` | OSM PBF source |

---

## Upgrade Procedure

```bash
# Pull new image
docker compose pull

# Stop and restart (graphs are preserved in volume)
docker compose down
docker compose up -d

# Watch logs for startup
docker compose logs -f ors-app
```

> **Note:** Major version upgrades may require graph rebuilds (delete `graphs/` dir and restart).

---

## Gotchas

- **RAM requirements**: Building graphs for large regions (e.g. Germany) needs 8–16 GB RAM; planet-scale needs 64+ GB. Start with a small regional extract.
- **Graph rebuild triggers**: Updating the OSM file requires deleting the built graphs and restarting. The rebuild happens automatically on next start.
- **Elevation data**: First run fetches SRTM elevation tiles; this can be slow. The `elevation_cache` volume avoids re-downloading.
- **profiles vs. graph count**: Each enabled profile builds its own graph. Enabling all profiles multiplies storage and build time.
- **API key for public API**: The live API at openrouteservice.org requires a free API key; self-hosted instances do not require keys by default.
- **Port confusion**: Internal container port is 8082 (Java app); map to any external port (typically 8080).

---

## Links
- Docs: https://giscience.github.io/openrouteservice/
- Running with Docker: https://giscience.github.io/openrouteservice/run-instance/running-with-docker
- API Reference: https://giscience.github.io/openrouteservice/api-reference/
- Docker Hub: https://hub.docker.com/r/openrouteservice/openrouteservice
- Geofabrik OSM downloads: https://download.geofabrik.de/
