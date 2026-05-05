---
name: open-source-routing-machine-osrm
description: OSRM recipe for open-forge. High performance routing engine for OpenStreetMap data. Docker-based install with MLD and CH pipeline options. HTTP API for routing, nearest, table, match, trip, and tile services. Upstream: https://github.com/Project-OSRM/osrm-backend
---

# Open Source Routing Machine (OSRM)

High performance routing engine designed to run on OpenStreetMap data. Provides an HTTP API for routing, nearest-road snapping, distance matrices, GPS trace matching, trip planning (TSP), and Mapbox vector tile generation.

7,680 stars · BSD-2-Clause

Upstream: https://github.com/Project-OSRM/osrm-backend
Website: http://project-osrm.org
HTTP API docs: https://github.com/Project-OSRM/osrm-backend/blob/master/docs/http.md
Demo: https://map.project-osrm.org

## What it is

OSRM powers routing for OpenStreetMap-based applications. Key capabilities:

- **Route** — Fastest path between coordinates with turn-by-turn steps
- **Nearest** — Snap coordinates to the road network
- **Table** — Duration or distance matrix between many pairs of coordinates
- **Match** — Snap noisy GPS traces to roads
- **Trip** — Solve Traveling Salesman Problem via greedy heuristic
- **Tile** — Generate Mapbox vector tiles with routing metadata

Typical use: self-hosted map applications, logistics tools, navigation apps, or any service needing offline routing without paying a cloud routing API.

## Compatible install methods

| Method | Upstream | When to use |
|---|---|---|
| Docker (recommended) | https://github.com/Project-OSRM/osrm-backend#quick-start | No C++ build required; pre-built images |
| Build from source | https://github.com/Project-OSRM/osrm-backend/wiki/Building-OSRM | Advanced; needed for custom profiles or patches |

## Inputs to collect

| Phase | Prompt | Applicability |
|---|---|---|
| data | "Which region to route? (e.g. Germany, US Northeast, global)" | All — determines PBF file to download |
| profile | "Vehicle type: car, bicycle, or pedestrian/foot?" | All |
| algorithm | "MLD (general routing, recommended) or CH (large distance matrices)?" | All; MLD is default |
| port | "Which host port to expose the routing API on?" | Docker (default: 5000) |

## Key concept: Pre-processing pipeline

OSRM does not route directly from raw OSM data. You must pre-process an OSM extract (`.osm.pbf` file) before starting the routing server. This is a one-time step (repeated when OSM data is updated).

**Two pipelines available:**

- **MLD (Multi-Level Dijkstra)** — Recommended for most use cases. Steps: extract → partition → customize → route.
- **CH (Contraction Hierarchies)** — Better for large distance matrix computations. Steps: extract → contract → route.

## Docker install — MLD pipeline (recommended)

Upstream: https://github.com/Project-OSRM/osrm-backend#using-docker

OSM data from Geofabrik: http://download.geofabrik.de/

### Step 1: Download OSM data for your region

    # Example: Berlin, Germany (~30 MB)
    wget http://download.geofabrik.de/europe/germany/berlin-latest.osm.pbf

    # Example: full Germany (~4 GB)
    # wget http://download.geofabrik.de/europe/germany-latest.osm.pbf

### Step 2: Extract (build graph representation)

    docker run -t -v "${PWD}:/data" ghcr.io/project-osrm/osrm-backend \
      osrm-extract -p /opt/car.lua /data/berlin-latest.osm.pbf

This step can take minutes to hours depending on region size. A 550 MB Mexico PBF takes ~30 minutes.

Profiles:
- `/opt/car.lua` — car routing
- `/opt/bicycle.lua` — bicycle routing
- `/opt/foot.lua` — pedestrian routing

### Step 3: Partition (MLD step)

    docker run -t -v "${PWD}:/data" ghcr.io/project-osrm/osrm-backend \
      osrm-partition /data/berlin-latest.osrm

### Step 4: Customize (MLD step)

    docker run -t -v "${PWD}:/data" ghcr.io/project-osrm/osrm-backend \
      osrm-customize /data/berlin-latest.osrm

### Step 5: Start routing server

    docker run -d \
      --name osrm \
      --restart unless-stopped \
      -p 5000:5000 \
      -v "${PWD}:/data" \
      ghcr.io/project-osrm/osrm-backend \
      osrm-routed --algorithm mld /data/berlin-latest.osrm

### Test the API

    curl "http://127.0.0.1:5000/route/v1/driving/13.388860,52.517037;13.385983,52.496891?steps=true"

## Docker install — CH pipeline

Replace steps 3 & 4 (partition + customize) with a single contract step:

    docker run -t -v "${PWD}:/data" ghcr.io/project-osrm/osrm-backend \
      osrm-contract /data/berlin-latest.osrm

Then start the server with `--algorithm ch`:

    docker run -d \
      --name osrm \
      -p 5000:5000 \
      -v "${PWD}:/data" \
      ghcr.io/project-osrm/osrm-backend \
      osrm-routed --algorithm ch /data/berlin-latest.osrm

## Optional: Map frontend

Start a user-friendly Leaflet map UI at port 9966:

    docker run -d -p 9966:9966 osrm/osrm-frontend

Open http://127.0.0.1:9966 in a browser.

## HTTP API reference

All endpoints at `http://host:5000/`:

| Service | Path | Description |
|---|---|---|
| Route | `/route/v1/{profile}/{coords}` | Fastest route between coordinates |
| Nearest | `/nearest/v1/{profile}/{coord}` | Snap coordinate to road network |
| Table | `/table/v1/{profile}/{coords}` | Duration/distance matrix |
| Match | `/match/v1/{profile}/{coords}` | GPS trace matching |
| Trip | `/trip/v1/{profile}/{coords}` | TSP solver (greedy) |
| Tile | `/tile/v1/{profile}/tile({x},{y},{z}).mvt` | Mapbox vector tiles |

Full API docs: https://github.com/Project-OSRM/osrm-backend/blob/master/docs/http.md

## Updating OSM data

OSRM does not support incremental updates. When OSM data changes, re-run the full pipeline:

1. Download updated PBF from Geofabrik
2. Re-run extract → partition → customize (MLD) or extract → contract (CH)
3. Restart the routing server

For automated weekly updates, script steps 1–3 and reload the container.

## Gotchas

- **Pre-processing is slow and RAM-intensive**: A 550 MB PBF takes ~30 min and significant CPU. Planet-scale extraction (global, ~70 GB) requires 100 GB+ RAM. Use regional Geofabrik extracts.
- **No incremental updates**: OSM data changes require full re-processing. Plan for periodic re-runs if your data needs to be current.
- **`.osrm` is not a single file**: After processing, `berlin-latest.osrm` is actually a set of files with that base name. Do not try to open or move it as a single file — move the entire directory or all `berlin-latest.osrm.*` files together.
- **Algorithm choice**: MLD for most routing queries; CH for large matrix computations (e.g. fleet logistics where you need 1000x1000 duration tables).
- **Docker `-v "${PWD}:/data"`**: The current working directory is mounted. Run the extract/partition/customize commands from the directory where the PBF file lives.
- **User permissions**: If Docker complains about permissions connecting to the Docker daemon, add yourself to the docker group: `sudo usermod -aG docker $USER` (requires re-login).
- **Image source**: Use `ghcr.io/project-osrm/osrm-backend` (GitHub Container Registry). Older versions are on Docker Hub (`osrm/osrm-backend`) but GHCR is the current home.

## Links

- GitHub: https://github.com/Project-OSRM/osrm-backend
- HTTP API docs: https://github.com/Project-OSRM/osrm-backend/blob/master/docs/http.md
- libosrm API docs: https://github.com/Project-OSRM/osrm-backend/blob/master/docs/libosrm.md
- Website: http://project-osrm.org
- Demo: https://map.project-osrm.org
- Geofabrik OSM downloads: http://download.geofabrik.de/
- Docker images: https://github.com/Project-OSRM/osrm-backend/pkgs/container/osrm-backend
