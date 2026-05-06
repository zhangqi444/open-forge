---
name: nominatim
description: Nominatim recipe for open-forge. OpenStreetMap geocoding and reverse geocoding engine. Self-hosted via Docker or native Python on PostgreSQL + PostGIS. Powers the search box on openstreetmap.org. Source: https://github.com/osm-search/Nominatim. Docs: https://nominatim.org/release-docs/latest.
---

# Nominatim

OpenStreetMap geocoding (address → coordinates) and reverse geocoding (coordinates → address) engine. Powers the search box on openstreetmap.org. A public instance runs at https://nominatim.openstreetmap.org. Self-host to avoid rate limits, keep data private, or use custom map extracts. Upstream: <https://github.com/osm-search/Nominatim>. Docs: <https://nominatim.org/release-docs/latest>.

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| VPS / bare metal (Linux) | Docker (mediagis/nominatim) | Easiest setup; community Docker image handles PostGIS and data import |
| VPS / bare metal (Linux) | Native Python + PostgreSQL + PostGIS | Full control; required for advanced configs |
| High-memory VPS / dedicated | Either | Full planet import needs 64+ GB RAM + 1+ TB disk |

> **Resource warning:** Full planet import is extremely resource-intensive (days of processing, 1+ TB storage, 64 GB RAM recommended). Start with a regional extract (e.g. a single country) from https://download.geofabrik.de.

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| data | "Which OSM extract? (country/region or full planet)" | Download .osm.pbf from https://download.geofabrik.de |
| db | "PostgreSQL password for nominatim user?" | Internal DB credential |
| port | "Port for Nominatim API?" | Default: 8080 (Docker) or configured via web server |
| domain | "Public domain (for HTTPS API)?" | Optional; use NGINX/Caddy in front |

## Software-layer concerns

- Backend: PostgreSQL 14+ with PostGIS extension; data stored in Nominatim-specific schema
- API: HTTP REST endpoints (/search, /reverse, /lookup, /details); returns JSON/XML/GeoJSON
- Data update: import OSM diff updates (minutely/hourly/daily) via nominatim replication
- Import time: country extract = 30 min to a few hours; full planet = 1–3 days
- No authentication by default; rate-limit at reverse proxy layer for public deployments

### Docker (recommended — mediagis/nominatim image)

```bash
docker run -it \
  -e PBF_URL=https://download.geofabrik.de/europe/monaco-latest.osm.pbf \
  -e REPLICATION_URL=https://download.geofabrik.de/europe/monaco-updates/ \
  -p 8080:8080 \
  --name nominatim \
  mediagis/nominatim:4.4
```

For a persistent installation with data volume:

```bash
docker run -it \
  -e PBF_URL=https://download.geofabrik.de/europe/monaco-latest.osm.pbf \
  -e REPLICATION_URL=https://download.geofabrik.de/europe/monaco-updates/ \
  -e UPDATE_MODE=continuous \
  -p 8080:8080 \
  -v nominatim-data:/var/lib/postgresql/14/main \
  --name nominatim \
  mediagis/nominatim:4.4
```

First run downloads the PBF file and imports it (can take minutes to hours depending on extract size). Subsequent starts skip re-import if the volume already has data.

### Test

```bash
curl "http://localhost:8080/search?q=monaco&format=json&limit=1"
curl "http://localhost:8080/reverse?lat=43.7317&lon=7.4197&format=json"
```

### Native install (summary)

```bash
git clone https://github.com/osm-search/Nominatim.git
wget -O Nominatim/data/country_osm_grid.sql.gz https://nominatim.org/data/country_grid.sql.gz
python3 -m venv nominatim-venv
./nominatim-venv/bin/pip install packaging/nominatim-{api,db}
mkdir nominatim-project && cd nominatim-project
../nominatim-venv/bin/nominatim import --osm-file /path/to/extract.osm.pbf
../nominatim-venv/bin/pip install uvicorn falcon
../nominatim-venv/bin/nominatim serve
```

Full native install docs: https://nominatim.org/release-docs/latest/admin/Installation

## Upgrade procedure

1. Docker: pull new image tag, stop container, start with same volume (data is preserved)
2. Native: `git pull`, re-run `pip install`, then `nominatim migrate` (if schema migration needed)
3. Check migration notes: https://nominatim.org/release-docs/latest/admin/Migration/

## Gotchas

- **RAM requirement is real**: PostgreSQL needs enough RAM for index caches during import and query. Under-provisioned hosts cause extremely slow imports and poor query performance. Use `shared_buffers=2GB` and `effective_cache_size=8GB` as starting points.
- **Disk IOPS matter**: Import is I/O bound. SSD or NVMe strongly recommended; spinning disk imports can take 10× longer.
- **Usage policy for public API**: If you use the public nominatim.openstreetmap.org API, you must follow the usage policy (https://operations.osmfoundation.org/policies/nominatim/). Self-host if you need high volume.
- **Data freshness**: Without replication configured, data goes stale. Set REPLICATION_URL to get continuous OSM updates.
- **Country extract vs planet**: Start with a regional extract from Geofabrik. Full planet is only needed if you need global geocoding.
- **Structured vs free-form queries**: /search handles free-form queries (less accurate); use structured parameters (street=, city=, country=) for better results.

## Links

- Upstream repo: https://github.com/osm-search/Nominatim
- Docs: https://nominatim.org/release-docs/latest
- Docker image (mediagis/nominatim): https://github.com/mediagis/nominatim-docker
- OSM extracts (Geofabrik): https://download.geofabrik.de
- Public instance / usage policy: https://nominatim.openstreetmap.org / https://operations.osmfoundation.org/policies/nominatim/
- Release notes: https://github.com/osm-search/Nominatim/releases
