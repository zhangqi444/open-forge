# OpenTripPlanner

> Multimodal trip planning software based on OpenStreetMap data and consuming published GTFS-formatted data to suggest routes using local public transit systems.

**URL:** https://www.opentripplanner.org/  
**License:** LGPL-3.0  
**Source:** https://github.com/opentripplanner/OpenTripPlanner  
**Language:** Java, JavaScript

---

## What it is

OpenTripPlanner (OTP) is an open-source multimodal trip planner focusing on travel by scheduled public transportation combined with bicycling, walking, and mobility services such as bike-share and ride-hailing. It builds its network representation from open standard formats — primarily GTFS for transit schedules and OpenStreetMap for street/path data — and exposes GraphQL APIs consumed by web and mobile clients. It has been in production use globally since 2009, powering trip planning for cities and transit agencies worldwide.

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux (≥4 GB RAM) | Docker | Recommended; official image `opentripplanner/opentripplanner` |
| Any Linux (≥4 GB RAM) | Bare metal (JVM) | Requires Java 21+; run shaded JAR directly |

---

## Inputs to Collect

### Phase: Install
| Variable | Description | Example |
|----------|-------------|---------|
| `OTP_PORT` | HTTP port for OTP server | `8080` |
| `GRAPHS_DIR` | Host path for graph data (GTFS + OSM → built graph) | `/srv/otp/graphs` |
| `GTFS_URL` | URL or path to GTFS zip for your transit agency | `https://agency.example.com/gtfs.zip` |
| `OSM_FILE` | OpenStreetMap PBF extract for your region | `region.osm.pbf` |
| `MEMORY` | JVM heap size | `4G` |

---

## Software-Layer Concerns

- **Config:** `otp-config.json` (router settings) and `build-config.json` (graph build settings) placed alongside graph data
- **Data dir:** The `graphs/` directory holds GTFS feeds, OSM PBF files, and the compiled `Graph.obj`; this must persist across restarts
- **Build step:** OTP requires a one-time graph build (`--build --save`) before serving requests; the compiled graph can be reused until data changes
- **Env vars:** JVM options via `JAVA_TOOL_OPTIONS` (e.g., `-Xmx4G`); no application-level env vars — configuration is file-based

---

## Upgrade Procedure

1. Pull new image: `docker pull opentripplanner/opentripplanner:latest`
2. Stop the running container
3. Review release notes at https://github.com/opentripplanner/OpenTripPlanner/releases for graph format changes
4. Re-run graph build if the graph format version changed (breaking graph changes are flagged in release notes)
5. Restart container

---

## Gotchas

- Graph building can be memory-intensive (2–8+ GB RAM depending on region size); ensure adequate heap via `-Xmx`
- GTFS and OSM data must be co-located in the graphs directory before building; OTP will fail to start without a pre-built graph
- No Docker Compose file is provided upstream; the server runs as a single container reading from a mounted volume
- The JavaScript test client is bundled but most production deployments build custom frontends using OTP's GraphQL API
- Real-time GTFS-RT feeds require additional configuration in `router-config.json`

---

## References

- [Upstream README](https://github.com/opentripplanner/OpenTripPlanner#readme)
- [Official docs](https://docs.opentripplanner.org/en/latest/)
- [Basic tutorial](https://docs.opentripplanner.org/en/latest/Basic-Tutorial/)
- [Docker Hub](https://hub.docker.com/r/opentripplanner/opentripplanner)
