# Jellyswarrm

Reverse proxy that combines multiple Jellyfin servers into a single unified interface.  
**Many servers. Single experience.**

- **Official repo:** https://github.com/LLukas22/Jellyswarrm
- **License:** GPL v2
- **Status:** Early development — core features work; some advanced features in progress

---

## What it does

Presents itself as a standard Jellyfin server so existing clients (apps, tools) connect without modification.  
Merges *Next Up*, *Recently Added*, and libraries from all connected servers.  
Maps user accounts across servers so credentials are consistent.  
Direct playback — content streams from the original server; transcoding happens where the media lives.

### Working features
- Unified library browsing across multiple Jellyfin servers
- Direct playback without extra overhead
- User mapping / account federation
- Jellyfin API compatibility (drop-in for existing clients)

### In-progress / partial
- QuickConnect (device approval sign-in)
- WebSocket / SyncPlay (not fully reliable)
- Audio streaming (partially tested)
- Automatic bitrate adjustment
- Media library management via proxy

---

## Compatible combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Docker host | Docker / Compose | Recommended deployment method |
| Any Docker host | Build from source | Requires Rust + Node.js |

---

## Inputs to collect

| Phase | Variable | Default | Notes |
|-------|----------|---------|-------|
| Deploy | `JELLYSWARRM_USERNAME` | — | Admin username for management UI |
| Deploy | `JELLYSWARRM_PASSWORD` | `jellyswarrm` | **Change this in production** |
| Deploy | Port mapping | `3000:3000` | Adjust host port as needed |

After deploy, add Jellyfin servers and configure user mappings via the web UI.

---

## Software-layer concerns

### Data directory
- App data lives at `/app/data` inside the container.
- Mount a volume: `./data:/app/data`

### Compose example
```yaml
services:
  jellyswarrm:
    image: ghcr.io/llukas22/jellyswarrm:latest
    container_name: jellyswarrm
    restart: unless-stopped
    ports:
      - "3000:3000"
    volumes:
      - ./data:/app/data
    environment:
      - JELLYSWARRM_USERNAME=admin
      - JELLYSWARRM_PASSWORD=change-me
```

### URLs after deploy
- **Management UI:** `http://<host>:3000/ui` — add Jellyfin servers, configure user mappings
- **Bundled Jellyfin web client:** `http://<host>:3000`

### Reverse proxy
Point upstream to port 3000. Jellyfin clients connect to the proxy URL instead of individual server URLs.

---

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

Data persists in the mounted `./data` volume.

---

## Gotchas

- Default password is `jellyswarrm` — change it before exposing to the network.
- Early development: WebSocket-dependent features (SyncPlay, real-time notifications) may not work reliably.
- Not all Jellyfin clients have been tested; report issues at the GitHub issues page.
- Designed for cross-network friend-sharing, not just local multi-server consolidation.

---

## Further reading

- README: https://github.com/LLukas22/Jellyswarrm
- UI docs: https://github.com/LLukas22/Jellyswarrm/blob/main/docs/ui.md
- Config docs: https://github.com/LLukas22/Jellyswarrm/blob/main/docs/config.md
- Docker images: https://github.com/LLukas22?tab=packages&repo_name=Jellyswarrm
