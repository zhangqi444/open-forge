# PlanarAlly

**What it is:** Self-hosted virtual tabletop (VTT) web tool for TTRPGs and D&D. Provides virtual battlemaps with dynamic lighting, player vision (fog of war), infinite canvas, layered scenes, floors, initiative tracker, and full offline support. Free and open source.

**Official site:** https://www.planarally.io  
**Docs:** https://planarally.io/docs/  
**GitHub:** https://github.com/Kruptein/PlanarAlly  
**Managed hosting:** https://www.planarally.io/server/setup/managed/

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS/VM | Docker | Official Docker image available |
| Any Linux | Binary | Pre-built releases on GitHub |
| Local machine | Binary or Docker | Full offline support |

---

## Inputs to Collect

### Phase: Deploy

| Item | Description |
|------|-------------|
| Host port | Port to expose PlanarAlly web UI |
| Data directory | Persistent storage for maps, assets, campaign data |

---

## Software-Layer Concerns

- **Single-server model** — typically one person hosts; players connect via browser to the host's server
- **Full offline support** — runs without internet connectivity; ideal for in-person D&D sessions
- **Data directory** — contains all campaign data, uploaded assets, and maps; back up regularly
- **No external database** — uses SQLite internally

### Feature summary

| Feature | Notes |
|---------|-------|
| Virtual battlemaps | Grid-based; infinite canvas |
| Dynamic lighting | Light sources and shadows |
| Player vision (fog of war) | Limit sight to token's line of sight |
| Layers | Organize scenes (tokens, map, lighting, etc.) |
| Floors | Multi-floor maps with balcony view-down |
| Initiative tracker | Simple tracker built in |
| Asset management | Upload and manage map images and tokens |
| Offline support | Fully functional without internet |

---

## Example Docker Compose

```yaml
services:
  planarally:
    image: kruptein/planarally:v2026.1.2
    container_name: planarally
    ports:
      - "8000:8000"
    volumes:
      - ./data:/planarally/data
    restart: unless-stopped
```

---

## Upgrade Procedure

1. Pull new image: `docker compose pull`
2. Restart: `docker compose up -d`
3. Campaign data persists in `./data` volume

---

## Gotchas

- Typically only the DM/GM needs to install and run the server — players connect via browser
- For internet-accessible instances, use a reverse proxy with TLS — the built-in server does not handle HTTPS
- Asset uploads (map images, token art) are stored on the server — ensure sufficient disk space for large campaigns
- Check release notes before upgrading — save file format may change between versions

---

## Links

- Website: https://www.planarally.io
- Docs: https://planarally.io/docs/
- GitHub: https://github.com/Kruptein/PlanarAlly
- Releases: https://github.com/Kruptein/PlanarAlly/releases
- Managed hosting: https://www.planarally.io/server/setup/managed/
