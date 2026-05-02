# Reaparr

Plex downloader that pulls content from any Plex server to yours.

- **Official site:** https://www.reaparr.rocks/
- **Repo:** https://github.com/Reaparr/Reaparr
- **Docker Hub:** https://hub.docker.com/r/reaparr/reaparr
- **Discord:** https://discord.com/invite/Qa3BtxN77g

---

## What it does

Reaparr lets you browse media on remote Plex servers (friends, family) and automatically download that content to your own Plex library.  
Think of it as a Plex-native sidecar that manages cross-server content acquisition.

> **Note:** The upstream README is minimal. Full documentation is at https://www.reaparr.rocks/ — consult that site for current setup guides and changelogs.

---

## Compatible combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Docker host | Docker / Compose | Primary deployment method |
| Any Docker host | Docker Hub image | `reaparr/reaparr` |

---

## Inputs to collect

Refer to https://www.reaparr.rocks/ for the full list of required environment variables and volume paths, as the upstream README does not document them.

Typical Plex-adjacent apps require:
- Plex token(s) for source and target server authentication
- Download client details (NZB/torrent client)
- Indexer/Prowlarr configuration
- Target library paths

---

## Software-layer concerns

### Compose example (minimal)
```yaml
services:
  reaparr:
    image: reaparr/reaparr:latest
    container_name: reaparr
    restart: unless-stopped
    ports:
      - "7878:7878"   # adjust to actual port; check docs
    volumes:
      - ./config:/config
      - /path/to/media:/media
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=UTC
```

Verify the actual port and volume paths from https://www.reaparr.rocks/ before deploying.

### File paths
- Reaparr and your download client must agree on file paths (same host mount points or shared volumes).

---

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

Config persists in the mounted config volume.

---

## Gotchas

- Upstream README is nearly empty — always check https://www.reaparr.rocks/ for current docs.
- Requires valid Plex authentication tokens; token expiry may interrupt operation.
- Path consistency between Reaparr and download clients is critical for detection.

---

## Further reading

- Official docs: https://www.reaparr.rocks/
- Screenshots: https://www.reaparr.rocks/screenshots
- Discord community: https://discord.com/invite/Qa3BtxN77g
- Docker Hub: https://hub.docker.com/r/reaparr/reaparr
