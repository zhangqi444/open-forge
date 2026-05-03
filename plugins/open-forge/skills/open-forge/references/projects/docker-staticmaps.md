# Docker Static Maps API

> Lightweight REST API for generating static map images — render maps with markers, polygons, circles, polylines, and text labels. Supports OpenStreetMap, Esri, Stamen, Carto, and custom tile servers. Includes tile caching and built-in IP-based rate limiting.

**Official URL:** https://github.com/dietrichmax/docker-staticmaps  
**Docs:** https://dietrichmax.github.io/docker-staticmaps  
**Docker Hub:** https://hub.docker.com/r/mxdcodes/docker-staticmaps

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS/VM | Docker | Single container; no database |
| Any Linux VPS/VM | Docker Compose | For multi-service stacks |
| Any Linux | Node.js (manual) | Build from source |

---

## Inputs to Collect

### Phase: Pre-Deploy
No required configuration — the container runs with sensible defaults out of the box.

### Phase: Optional Tuning
| Input | Description | Example |
|-------|-------------|---------|
| `PORT` | Listening port | `3000` |
| Custom tile server URL | Use your own map tile provider instead of public ones | `https://tiles.example.com/{z}/{x}/{y}.png` |

---

## Software-Layer Concerns

### Quick Start
```bash
docker run -p 3000:3000 mxdcodes/docker-staticmaps:latest
```

Access the interactive playground at http://localhost:3000

### Sample API Request
```bash
# Generate a 1000x1000 satellite map centered on coordinates
curl "http://localhost:3000/api/staticmaps?width=1000&height=1000&center=-18.2871,147.6992&zoom=9&basemap=satellite"
```

### API Parameters
| Parameter | Description | Example |
|-----------|-------------|---------|
| `width` / `height` | Output image dimensions in pixels | `800`, `600` |
| `center` | Lat,Lon center point | `-18.2871,147.6992` |
| `zoom` | Zoom level (0–18) | `9` |
| `basemap` | Map style (`osm`, `satellite`, `carto`, etc.) | `osm` |
| `markers` | Pin markers at coordinates | see docs |
| `polylines` | Draw lines | see docs |
| `polygons` | Draw filled areas | see docs |

Full API reference: https://dietrichmax.github.io/docker-staticmaps

### Ports
- Default: `3000`

### Caching
- Tile and generated image caching is built in — reduces load on tile providers and speeds up repeated requests

### Rate Limiting
- Per-IP rate limiting is enabled by default — protects against abuse on public-facing instances

---

## Upgrade Procedure

1. Pull latest: `docker pull mxdcodes/docker-staticmaps:latest`
2. Stop: `docker stop <container>`
3. Run with new image

---

## Gotchas

- **Tile provider ToS** — public tile servers (OpenStreetMap, Esri, etc.) have usage policies; for high-traffic deployments use a self-hosted tile server or a paid provider
- **No authentication** — the API has no built-in auth; for public-facing deployments, put it behind a reverse proxy with auth middleware or restrict to internal network
- **AGPL license** — if you modify and deploy, you must publish your changes
- **Tile caching** — cache is in-memory/ephemeral by default; restart clears it; for persistent caching across restarts, check the docs for volume configuration

---

## Links
- GitHub: https://github.com/dietrichmax/docker-staticmaps
- Docs: https://dietrichmax.github.io/docker-staticmaps
- Docker Hub: https://hub.docker.com/r/mxdcodes/docker-staticmaps
