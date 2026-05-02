# CrossWatch

**What it is:** Media watch-state synchronization engine. Keeps Plex, Jellyfin, Emby, SIMKL, Trakt, AniList, TMDb, MDBList, and Tautulli in sync. Runs locally with a web UI — link accounts, define sync pairs, run on schedule or manually, and review history. Includes a built-in tracker with snapshots, and Profiles for multi-user household management.

**Official site:** https://www.crosswatch.app  
**Wiki / Docs:** https://wiki.crosswatch.app  
**Quick Start:** https://wiki.crosswatch.app/getting-started/first-time-setup  
**GitHub:** https://github.com/cenodude/CrossWatch  
**Docker image:** `ghcr.io/cenodude/crosswatch:latest`

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS/VM | Docker Compose | Recommended; single container |
| Bare metal | Docker Compose | Same |
| Raspberry Pi / ARM | Docker | Multi-arch image |

---

## Inputs to Collect

### Phase: Deploy

| Item | Description |
|------|-------------|
| `TZ` | Timezone string (e.g. `America/New_York`) |
| Host port | Port to expose web UI (default `8787`) |

All service accounts (Plex, Jellyfin, Trakt, etc.) are configured inside the web UI after deployment.

---

## Software-Layer Concerns

- **Single container** — all state stored in `/config` volume
- **Named volume `crosswatch_config`** — persists all settings, sync pairs, and history; back this up
- **Web UI on port 8787** — used for all configuration; no manual config file editing required
- **Supported services:** Plex, Jellyfin, Emby, SIMKL, Trakt, AniList, TMDb, MDBList, Tautulli
- **Profiles:** Manage separate sync setups per user (household members with different servers/accounts)
- **Built-in tracker:** Snapshots of your watch state for data safety and rollback

---

## Example Docker Compose

```yaml
services:
  crosswatch:
    image: ghcr.io/cenodude/crosswatch:latest
    container_name: crosswatch
    ports:
      - "8787:8787"
    environment:
      TZ: America/New_York
    volumes:
      - crosswatch_config:/config
    restart: unless-stopped

volumes:
  crosswatch_config:
```

---

## Upgrade Procedure

1. Pull new image: `docker compose pull`
2. Restart: `docker compose up -d`
3. All config is preserved in the named volume

---

## Gotchas

- **Read the Quick Start guide** before first setup — account linking order matters for some providers
- Each sync is directional — define pairs carefully (source → target); bidirectional sync requires two pairs
- AniList and TMDb syncs may require API key configuration within the web UI
- No built-in authentication on the web UI — use a reverse proxy with auth if exposing beyond localhost
- MDBList integration requires an MDBList account and API key

---

## Links

- Website: https://www.crosswatch.app
- Wiki: https://wiki.crosswatch.app
- Quick Start: https://wiki.crosswatch.app/getting-started/first-time-setup
- GitHub: https://github.com/cenodude/CrossWatch
- Docker Hub: https://hub.docker.com/r/cenodude/crosswatch
