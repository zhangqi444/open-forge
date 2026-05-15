---
name: overseerr
description: Recipe for Overseerr — media request management for Plex, integrating with Sonarr and Radarr. Note: being superseded by Seerr.
---

# Overseerr

Media request management tool for Plex libraries. Users can browse and request movies/TV shows; requests are routed to Radarr (movies) and Sonarr (TV) for automatic download. Features Plex SSO, granular permissions, and notification agents. Upstream: <https://github.com/sct/overseerr>. Docs: <https://docs.overseerr.dev>. License: MIT.

> **Note:** Overseerr is being superseded by [Seerr](https://github.com/seerr-team/seerr), a unified project merging Overseerr and Jellyseerr (which adds Jellyfin/Emby support). Overseerr no longer receives new features. For new deployments, consider Seerr or Jellyseerr instead. Existing Overseerr installs continue to work; migration guides are available at <https://docs.seerr.dev/migration-guide>.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker | <https://docs.overseerr.dev/getting-started/installation> | Yes | Recommended |
| Docker Compose | <https://docs.overseerr.dev/getting-started/installation> | Yes | Standard arr-stack deployment |
| Unraid | Community app | Community | Unraid NAS |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| infra | Port for Overseerr UI? | Port (default 5055) | All |
| software | Plex server URL? | http://plex:32400 | Required for Plex integration |
| software | Plex authentication token? | String | Required; found in Plex preferences XML |
| software | Radarr URL + API key? | http://radarr:7878 + key | Required for movie requests |
| software | Sonarr URL + API key? | http://sonarr:8989 + key | Required for TV requests |
| software | Timezone? | TZ string | Optional |

## Software-layer concerns

### Docker run

```bash
docker run -d \
  --name overseerr \
  -e LOG_LEVEL=debug \
  -e TZ=America/New_York \
  -e PORT=5055 \
  -p 5055:5055 \
  -v /path/to/appdata/overseerr:/app/config \
  --restart unless-stopped \
  sctx/overseerr
```

### Docker Compose (arr-stack)

```yaml
services:
  overseerr:
    image: sctx/overseerr:1.35.0
    container_name: overseerr
    environment:
      - LOG_LEVEL=debug
      - TZ=America/New_York
      - PORT=5055
    ports:
      - 5055:5055
    volumes:
      - overseerr-config:/app/config
    restart: unless-stopped

volumes:
  overseerr-config:
```

### First-time setup

Visit http://localhost:5055 and complete the setup wizard:
1. Sign in with Plex to authenticate
2. Configure Plex server connection
3. Add Radarr instance(s) with API key and default quality profile
4. Add Sonarr instance(s) with API key and default quality profile
5. Configure notification agents (email, Discord, Telegram, Slack, etc.)

### Key environment variables

| Variable | Description |
|---|---|
| TZ | Timezone |
| PORT | UI port (default 5055) |
| LOG_LEVEL | debug / info / warn / error |

## Upgrade procedure

```bash
docker compose pull && docker compose up -d
```

## Gotchas

- Plex-only: Overseerr authenticates users via Plex and requires a Plex server. For Jellyfin/Emby, use Jellyseerr or the upcoming Seerr instead.
- Maintenance mode: Overseerr no longer receives new features as of 2025. It remains functional but consider migrating to Seerr for continued development.
- Radarr/Sonarr must be reachable: use internal Docker network hostnames if all services are on the same Compose stack.
- Config dir: all settings, users, and request history are stored in `/app/config`. Back it up before upgrades.
- Request approval: by default, all requests require approval. Auto-approve can be configured per-user or globally.

## Migration to Seerr/Jellyseerr

- Seerr (Overseerr + Jellyseerr unified): <https://github.com/seerr-team/seerr>
- Jellyseerr (Jellyfin support): <https://github.com/fallenbagel/jellyseerr>
- Migration guide: <https://docs.seerr.dev/migration-guide>

## Links

- GitHub: <https://github.com/sct/overseerr>
- Docs: <https://docs.overseerr.dev>
- Docker Hub: <https://hub.docker.com/r/sctx/overseerr>
- Seerr (successor): <https://github.com/seerr-team/seerr>
- Jellyseerr (Jellyfin variant): <https://github.com/fallenbagel/jellyseerr>
