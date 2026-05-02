# Sonobarr

Music discovery companion for Lidarr power users. Blends Last.fm artist similarity graphs, ListenBrainz Weekly Exploration playlists, and an optional AI assistant (any OpenAI-compatible model) to surface new artists you'll actually like. Sends approved artists directly back to Lidarr with configurable monitor strategies. Real-time UX via Socket.IO, role-based access (admin/user), optional OIDC SSO, and a REST API.

- **GitHub:** https://github.com/Dodelidoo-Labs/sonobarr
- **Docker image:** `ghcr.io/dodelidoo-labs/sonobarr:latest`
- **License:** Open-source

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Docker host | Docker Compose | Single container; config volume mounted |
| Any Docker host | docker run | Same; bind-mount ./config |

---

## Inputs to Collect

### Deploy Phase (.env required fields)
| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| secret_key | Yes | — | Flask session secret — use a long random string |
| lidarr_address | Yes | — | URL of your Lidarr instance (e.g. http://lidarr:8686) |
| lidarr_api_key | Yes | — | Lidarr API key |
| last_fm_api_key | Yes | — | Last.fm API key (get from last.fm/api) |
| last_fm_api_secret | Yes | — | Last.fm API secret |
| root_folder_path | Yes | /data/media/music/ | Lidarr root folder path for new artists |
| quality_profile_id | No | 1 | Lidarr quality profile ID |
| metadata_profile_id | No | 1 | Lidarr metadata profile ID |
| sonobarr_superadmin_username | No | admin | Initial admin username |
| sonobarr_superadmin_password | Yes | change-me | Initial admin password — change this |
| PUID | No | 1000 | UID for container user |
| PGID | No | 1000 | GID for container user |

### Optional integrations
| Variable | Description |
|----------|-------------|
| youtube_api_key | YouTube Data API key for preview links |
| openai_api_key | OpenAI-compatible key for AI artist recommendations |
| openai_model | Model to use (default: gpt-4o-mini) |
| openai_max_seed_artists | Max artists to seed AI sessions (default: 5) |
| OIDC_CLIENT_ID | OIDC client ID for SSO |
| OIDC_CLIENT_SECRET | OIDC client secret |
| OIDC_SERVER_METADATA_URL | OIDC discovery URL |
| OIDC_ADMIN_GROUP | OIDC group that gets admin privileges |
| OIDC_ONLY | Set true to disable local password auth (OIDC only) |

---

## Software-Layer Concerns

### Config
- All configuration via .env file (copy from .sample-env)
- Config and SQLite database stored in ./config volume

### Data Directories
- ./config — SQLite database, Sonobarr config (must be persisted)

### Ports
- 5000 — Web UI

---

## Minimal docker-compose.yml

```yaml
services:
  sonobarr:
    image: ghcr.io/dodelidoo-labs/sonobarr:latest
    container_name: sonobarr
    env_file:
      - .env
    volumes:
      - ./config:/sonobarr/config
      - /etc/localtime:/etc/localtime:ro
    ports:
      - "5000:5000"
    restart: unless-stopped
```

Setup:
```bash
mkdir -p sonobarr && cd sonobarr
sudo chown -R 1000:1000 .
curl -L https://raw.githubusercontent.com/Dodelidoo-Labs/sonobarr/develop/docker-compose.yml -o docker-compose.yml
curl -L https://raw.githubusercontent.com/Dodelidoo-Labs/sonobarr/develop/.sample-env -o .env
# Edit .env with your credentials
docker compose up -d
```

---

## Upgrade Procedure

```bash
docker compose pull sonobarr
docker compose up -d sonobarr
```

The app self-heals schema on startup (backfills missing DB columns); no manual migration needed.

---

## Gotchas

- **Directory ownership:** The working directory must be owned by the PUID/PGID you configure (default 1000:1000) before starting; the container starts as root to fix permissions then drops to PUID/PGID
- **Last.fm API key required:** Get a free key at https://www.last.fm/api — both api_key and api_secret are needed
- **Lidarr root folder must exist:** The root_folder_path must already exist in Lidarr's settings; Sonobarr uses it when adding new artists
- **SQLite (no external DB needed):** Sonobarr uses SQLite stored in the config volume — simple and portable, but not suitable for very large multi-user setups
- **superadmin_reset=true:** Setting sonobarr_superadmin_reset=true in .env resets the admin password to the env value on next startup — useful for recovery
- **AI assistant is optional:** Works without an OpenAI key; the AI seed feature just won't be available without one
- **OIDC optional:** Standard username/password auth works without any OIDC config

---

## References
- README: https://github.com/Dodelidoo-Labs/sonobarr
- .sample-env: https://raw.githubusercontent.com/Dodelidoo-Labs/sonobarr/develop/.sample-env
- docker-compose.yml: https://raw.githubusercontent.com/Dodelidoo-Labs/sonobarr/develop/docker-compose.yml
