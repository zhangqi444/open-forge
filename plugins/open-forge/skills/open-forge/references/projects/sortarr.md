# Sortarr

> Read-only analytics and organisation dashboard for *arr-stack and media server libraries. Surfaces missing media, mismatches, and optimisation opportunities using live data from Sonarr, Radarr, Plex, Jellyfin, Emby, Tautulli, Jellystat, and Streamystats. Never modifies, moves, or deletes files.

**Official URL:** https://github.com/Jaredharper1/Sortarr

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS/VM | Docker | Primary deployment method; container on GHCR |
| Unraid | Docker Compose (Compose Manager) | Paste compose YAML into Compose Manager |
| Any | Docker Compose | Standard compose file from repo |

---

## Inputs to Collect

### Phase: Pre-Deploy
| Input | Description | Example |
|-------|-------------|---------|
| Auth mode | `basic`, `basic_local_bypass`, or `external` | `basic` |
| Admin username | Sortarr Basic Auth username | `admin` |
| Admin password | Sortarr Basic Auth password | strong password |

### Phase: Media Source Integration (at least one required)
| Integration | Required Info |
|-------------|---------------|
| Sonarr | Base URL + API key (supports multiple instances) |
| Radarr | Base URL + API key (supports multiple instances) |
| Plex | Base URL + Plex token |
| Jellyfin | Base URL + API key |
| Emby | Base URL + API key |

### Phase: History/Playback Enrichment (optional)
| Integration | Required Info |
|-------------|---------------|
| Tautulli | Base URL + API key |
| Jellystat | Base URL + API key |
| Streamystats | Base URL + API key |
| Tracearr | Base URL + API key |

---

## Software-Layer Concerns

### Config & Environment
- Configuration is done through environment variables passed to the container
- Auth mode controls whether Sortarr handles authentication (`basic`) or delegates to a reverse proxy (`external`)
- `basic_local_bypass`: allows direct local peers to skip the Basic Auth browser prompt; remote clients still challenged

### Authentication Modes
| Mode | Behaviour |
|------|-----------|
| `basic` | Sortarr challenges every client with its own Basic Auth |
| `basic_local_bypass` | Local peers bypass prompt; remote clients see Basic Auth |
| `external` | Trusted reverse proxy handles auth; Sortarr reads upstream header |

### Ports
- Default HTTP port: `3000` — proxy with Nginx/Caddy for TLS

### Docker Compose (minimal)
```yaml
services:
  sortarr:
    image: ghcr.io/jaredharper1/sortarr:latest
    container_name: sortarr
    restart: unless-stopped
    ports:
      - "3000:3000"
    environment:
      - AUTH_MODE=basic
      - ADMIN_USERNAME=admin
      - ADMIN_PASSWORD=changeme
      # Add provider URLs and API keys here
```
> Refer to the project wiki for full environment variable reference.

### Read-Only Guarantee
Sortarr will **never**:
- Modify or rename media files
- Delete media
- Change Sonarr/Radarr configuration
- Trigger downloads

---

## Upgrade Procedure

1. Pull the latest image: `docker compose pull`
2. Recreate the container: `docker compose up -d`
3. Check logs: `docker compose logs -f sortarr`

---

## Gotchas

- **External auth mode** requires a correctly configured reverse proxy that passes the expected header; misconfiguration leaves Sortarr open
- **Multiple Sonarr/Radarr instances** are supported — configure each with a unique prefix/variable set per the wiki
- **Large libraries are slow on first load** — Sortarr fetches live data from providers; no local database cache means initial page renders can be slow
- **Plex token required** (not username/password) — see [Plex docs](https://support.plex.tv/articles/204059436-finding-an-authentication-token-x-plex-token/) to retrieve it
- **Project is feature-complete / looking for maintainer** — security patches may be slow; do not expose directly to the internet without a reverse proxy + auth

---

## Links
- GitHub: https://github.com/Jaredharper1/Sortarr
- Wiki (setup, deployment, provider guides): https://github.com/Jaredharper1/Sortarr/wiki
