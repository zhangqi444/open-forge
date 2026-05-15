---
name: tileserver-gl
description: TileServer GL recipe for open-forge. Covers Docker (recommended) and Node.js (npm) install methods. Serves vector and raster map tiles from MBTiles files with GL styles, compatible with MapLibre GL JS, Leaflet, OpenLayers, and WMTS clients.
---

# TileServer GL

Vector and raster map tile server with server-side rendering powered by MapLibre GL Native. Serves `.mbtiles` files and GL styles over HTTP/WMTS. Compatible with MapLibre GL JS, Leaflet, OpenLayers, and any GIS client that speaks WMTS or XYZ tiles. Upstream: <https://github.com/maptiler/tileserver-gl>. Docs: <https://maptiler-tileserver.readthedocs.io/>.

**License:** BSD-2-Clause · **Language:** Node.js · **Default port:** 8080 · **Stars:** ~2,800

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker | <https://hub.docker.com/r/maptiler/tileserver-gl> | ✅ | Recommended for servers — includes native MapLibre GL Native rendering dependencies. |
| npm (`tileserver-gl`) | <https://github.com/maptiler/tileserver-gl#getting-started-with-node> | ✅ | When you want to manage Node.js yourself; requires native build deps (see docs). |
| npm (`tileserver-gl-light`) | <https://github.com/maptiler/tileserver-gl#tileserver-gl-light> | ✅ | Pure JS, zero native deps, runs anywhere; no server-side raster rendering. |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| preflight | "Which install method — Docker or npm?" | AskUserQuestion | Determines section below. |
| data | "Path to your .mbtiles file(s)?" | Free-text (local directory path) | All methods. |
| config | "Use a config.json for multiple tilesets / GL styles, or single-file mode?" | AskUserQuestion: config.json / single file | All methods. |
| network | "External port to expose TileServer GL on?" | Free-text (default 8080) | Docker/npm. |
| proxy | "Are you placing a reverse proxy (nginx/Caddy) in front?" | AskUserQuestion: Yes / No | Optional. |

## Install — Docker (recommended)

Reference: <https://github.com/maptiler/tileserver-gl#getting-started-with-docker>

### Single MBTiles file

```bash
wget https://github.com/maptiler/tileserver-gl/releases/download/v1.3.0/zurich_switzerland.mbtiles

docker run --rm -it \
  -v "$(pwd)":/data \
  -p 8080:8080 \
  maptiler/tileserver-gl:v5.6.0 \
  --file zurich_switzerland.mbtiles
```

### Docker Compose (multi-tileset with config.json)

```yaml
services:
  tileserver:
    image: maptiler/tileserver-gl:v5.6.0
    restart: unless-stopped
    ports:
      - "8080:8080"
    volumes:
      - ./data:/data
    command: --config /data/config.json
```

Minimal `data/config.json`:

```json
{
  "options": {
    "paths": {
      "root": "/usr/src/app",
      "fonts": "node_modules/fonts",
      "styles": "styles",
      "mbtiles": "/data"
    }
  },
  "data": {
    "my-tiles": {
      "mbtiles": "my-map.mbtiles"
    }
  }
}
```

Start: `docker compose up -d`

### Acquire tile data

Download planet or regional extracts from OpenMapTiles / MapTiler Data: <https://data.maptiler.com/downloads/planet/>

```bash
mkdir data
# Place downloaded .mbtiles file(s) in data/
```

## Install — npm

```bash
# Install system native deps first — see:
# https://maptiler-tileserver.readthedocs.io/en/latest/installation.html#npm
npm install -g tileserver-gl

tileserver-gl --file zurich_switzerland.mbtiles
```

For `tileserver-gl-light` (no native deps, no server-side raster rendering):

```bash
npm install -g tileserver-gl-light
tileserver-gl-light --file zurich_switzerland.mbtiles
```

## Software-layer concerns

| Concern | Detail |
|---|---|
| Data directory | Mount local directory containing .mbtiles files to /data in the container. |
| config.json | Controls datasets, GL styles, served domains, and rendering options. Optional for single-file mode. |
| baseUrls | Set in config.json when behind a reverse proxy so tile URLs are generated correctly. |
| Port | Default 8080; change with -p <host>:8080 or --port CLI flag. |
| Auth | None built-in — use a reverse proxy with basic auth or token validation if needed. |
| Raster rendering | Requires maptiler/tileserver-gl Docker image (has native MapLibre GL Native); tileserver-gl-light won't rasterize. |
| ARM support | Docker image supports arm64 via multi-arch manifest. |
| Fonts / sprites | Custom GL styles require fonts and sprite directories — mount alongside config.json. |

## Upgrade procedure

```bash
docker pull maptiler/tileserver-gl:v5.6.0
docker compose pull && docker compose up -d
```

TileServer GL is stateless beyond the tile data files — upgrades are safe without data migration.

## Gotchas

- **Native deps for npm install:** The full tileserver-gl package requires libGL, libgbm, and other native libraries. Use Docker to avoid this entirely.
- **tileserver-gl-light limitations:** No server-side raster rendering of vector tiles. Clients must render GL styles themselves.
- **baseUrls behind a proxy:** If served behind a load balancer, set options.domains or options.baseUrls in config.json so generated tile URLs are correct.
- **MBTiles path in Docker:** The container expects data at /data; map your host directory with -v "$(pwd)":/data.
- **Tile data size:** Planet-scale .mbtiles files can be 50-100 GB; ensure sufficient disk before downloading.
- **No hot reload:** Restart the container to pick up new .mbtiles files or config.json changes.

## Upstream links

- GitHub: <https://github.com/maptiler/tileserver-gl>
- Docs: <https://maptiler-tileserver.readthedocs.io/>
- Docker Hub: <https://hub.docker.com/r/maptiler/tileserver-gl>
- OpenMapTiles data: <https://data.maptiler.com/downloads/planet/>
