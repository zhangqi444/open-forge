---
name: GraphHopper
description: "Fast open-source routing engine and map-matching service — calculate routes, turn-by-turn navigation, isochrones, and snap GPS traces to roads using OpenStreetMap data. Java. Apache-2.0."
---

# GraphHopper

GraphHopper is a fast, memory-efficient open-source routing engine built on OpenStreetMap (and optionally GTFS) data. It exposes a REST web service for turn-by-turn routing, isochrone analysis, map matching (GPS trace → road network), and matrix calculations. It can also be embedded as a Java library.

Maintained by GraphHopper GmbH (Germany). Commercial SaaS available at graphhopper.com; self-host the open-source engine for free.

Use cases: route planning in logistics/delivery apps; outdoor/cycling/hiking navigation; isochrone maps ("what can I reach in 30 min?"); GPS track correction; replacing Google Directions API.

- Upstream repo: https://github.com/graphhopper/graphhopper
- Homepage: https://www.graphhopper.com/
- Docs: https://github.com/graphhopper/graphhopper/blob/master/docs/index.md
- Forum: https://discuss.graphhopper.com/

## Architecture

- **Java 17+** (single JAR — "web service jar")
- **OpenStreetMap PBF data** — import once, builds in-memory + on-disk graph
- **No external DB required** — graph stored on disk as binary files
- **Memory**: depends on map size — a country-sized OSM file uses 2–16 GB RAM after graph build
- **Build time**: graph build (one-time per data update) takes minutes to hours depending on region size
- **REST API** on configurable port (default 8989)

## Compatible install methods

| Infra       | Runtime                                | Notes                                           |
|-------------|----------------------------------------|-------------------------------------------------|
| VPS/Server  | Java JAR (recommended)                 | Download JAR + config + OSM data → run          |
| Docker      | `israelhikingmap/graphhopper`          | Community image; convenient for containers      |
| Kubernetes  | Docker image in pod                    | Scale read-replicas; graph build as init job    |
| Embedded    | Java library (Maven/Gradle)            | Add as dependency; no web server overhead       |

## Inputs to collect

| Input           | Example                              | Phase   | Notes                                                        |
|-----------------|--------------------------------------|---------|--------------------------------------------------------------|
| OSM data file   | `germany-latest.osm.pbf`             | Data    | Download from download.geofabrik.de                          |
| Vehicle profiles| `car`, `bike`, `foot`, custom        | Config  | Define which profiles to build CH/LM graphs for              |
| JVM memory      | `-Xmx8g` for country-sized graph     | JVM     | Set based on region size; see docs for estimates             |
| Port            | `8989`                               | Config  | Default REST API port                                        |
| GTFS data (opt) | `.zip` from transit agency           | Transit | Optional; enables public transit routing                     |

## Install (JAR path)

```sh
# Download latest release JAR (check https://github.com/graphhopper/graphhopper/releases)
wget https://repo1.maven.org/maven2/com/graphhopper/graphhopper-web/11.0/graphhopper-web-11.0.jar

# Download OSM data (example: small region for testing)
wget https://download.geofabrik.de/europe/germany/baden-wuerttemberg-latest.osm.pbf

# Download example config
wget https://raw.githubusercontent.com/graphhopper/graphhopper/master/config-example.yml

# Run (first run builds the graph — takes time proportional to region size)
java -Xmx4g -Xms1g \
  -jar graphhopper-web-11.0.jar \
  server config-example.yml
```

Visit `http://localhost:8989` for the GraphHopper Maps UI.

See https://github.com/graphhopper/graphhopper/blob/master/docs/quickstart.md for authoritative setup.

## Key API endpoints

```
GET /route?point=52.5,13.4&point=48.1,11.6&profile=car
# → turn-by-turn route with instructions

GET /isochrone?point=52.5,13.4&time_limit=1800&profile=bike
# → reachable area in 30 minutes by bike

POST /match
# → map matching: snap GPS trace to road network

GET /matrix?from_point=52.5,13.4&to_point=48.1,11.6&profile=car
# → distance + time matrix
```

## Config essentials (config.yml)

```yaml
graphhopper:
  datareader.file: /data/region-latest.osm.pbf
  graph.location: /data/graph-cache
  profiles:
    - name: car
      vehicle: car
      weighting: fastest
    - name: bike
      vehicle: bike
      weighting: fastest
    - name: foot
      vehicle: foot
      weighting: shortest
  ch.profiles: car, bike
  lm.profiles: foot

server:
  application_connectors:
    - type: http
      port: 8989
```

## Data & config layout

- **OSM PBF file** — source data (download + update periodically from Geofabrik)
- **Graph cache dir** — binary graph files built from OSM; can be 2–10× size of PBF
- **`config.yml`** — all routing config, profile definitions, server settings
- No database; no persistent state beyond graph files

## Update OSM data

```sh
# Stop service, delete graph cache (stale graph won't auto-update)
rm -rf /data/graph-cache/
# Download fresh OSM extract
wget -O /data/region-latest.osm.pbf https://download.geofabrik.de/europe/germany-latest.osm.pbf
# Restart → rebuilds graph from fresh data
```

Automate with weekly cron for frequently-edited areas; monthly is usually fine for rural regions.

## Gotchas

- **Graph build time is significant** — Germany-level OSM with 2 CH profiles: 30–60 min build, 8–16 GB RAM. Small regions (city/state): minutes, 1–4 GB. Budget server RAM accordingly.
- **Memory sizing** — rule of thumb: ~1.5× OSM PBF file size for RAM after graph is loaded. A 700 MB PBF → ~2 GB JVM heap needed. A 3.5 GB Germany PBF → 8–12 GB heap.
- **CH/LM pre-computation required for speed** — Contraction Hierarchies (CH) must be built per profile at graph-build time. Without CH, routing falls back to slow Dijkstra. Configure `ch.profiles` for all fast-routing profiles.
- **Custom profiles are powerful but complex** — Lua-based custom models allow encoding any OSM tags into routing weights. Learning curve; read the custom models docs.
- **OSM data quality matters** — routing quality directly reflects OSM completeness. Rural areas in some countries have poor road coverage.
- **No real-time traffic** — GraphHopper routes on static OSM data. For live traffic-aware routing, use the commercial GraphHopper Directions API.
- **Multiple regions** — you can import multiple OSM extracts but they must be merged before import (use osmium-tool). GraphHopper imports a single PBF.
- **GTFS transit routing** is separate config — needs transit agency GTFS feeds and separate profile config. Not plug-and-play; read the GTFS docs.
- **Alternatives:** OSRM (C++, extremely fast, less flexible), Valhalla (C++, flexible costing, good isochrones), OpenRouteService (GraphHopper-based with more built-in features), Google Directions API / Mapbox Directions (commercial, real-time traffic).

## Links

- Repo: https://github.com/graphhopper/graphhopper
- Homepage: https://www.graphhopper.com/
- Docs index: https://github.com/graphhopper/graphhopper/blob/master/docs/index.md
- Quickstart: https://github.com/graphhopper/graphhopper/blob/master/docs/quickstart.md
- Releases (JAR downloads): https://github.com/graphhopper/graphhopper/releases
- OSM data (Geofabrik): https://download.geofabrik.de/
- Forum: https://discuss.graphhopper.com/
- Commercial API: https://www.graphhopper.com/products/
