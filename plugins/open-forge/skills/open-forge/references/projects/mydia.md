# Mydia

**Self-hosted media management for movies and TV shows — built with Phoenix LiveView, supports qBittorrent/Transmission/SABnzbd/NZBGet download clients, Prowlarr/Jackett indexers, TMDB/TVDB metadata, and OIDC SSO.**
Official docs: https://docs.mydia.dev
GitHub: https://github.com/getmydia/mydia

> ⚠️ Early development (0.x.x) — expect breaking changes.

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux | Docker Compose | Recommended; SQLite by default, PostgreSQL supported |

---

## Inputs to Collect

### Required
- `SECRET_KEY_BASE` — generate with `openssl rand -base64 48`
- `GUARDIAN_SECRET_KEY` — generate with `openssl rand -base64 48`
- `PHX_HOST` — hostname/domain where Mydia is accessible
- Media paths — host paths for movies and TV libraries

### Optional
- `PUID` / `PGID` — user/group for file permissions
- `TZ` — timezone

---

## Software-Layer Concerns

### Docker Compose
```yaml
services:
  mydia:
    image: ghcr.io/getmydia/mydia:latest
    container_name: mydia
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=America/New_York
      - SECRET_KEY_BASE=your-secret-key-base-here
      - GUARDIAN_SECRET_KEY=your-guardian-secret-key-here
      - PHX_HOST=localhost
      - MOVIES_PATH=/media/library/movies
      - TV_PATH=/media/library/tv
    volumes:
      - ./config:/config
      - /path/to/media:/media
    ports:
      - 4000:4000
    restart: unless-stopped
```

### First run
Visit http://localhost:4000 and create your admin account.

### Ports
- `4000` — web UI

### Key features
- TMDB and TVDB metadata
- Download clients: qBittorrent, Transmission, SABnzbd, NZBGet
- Indexers: Prowlarr, Jackett, built-in Cardigann (experimental)
- Multi-user with admin/guest roles and request workflow
- SSO: local auth + OIDC/OpenID Connect
- Import lists: TMDB watchlists, popular, trending (experimental)
- Real-time UI via Phoenix LiveView

---

## Upgrade Procedure

1. docker compose pull
2. docker compose up -d

---

## Gotchas

- `PHX_HOST` must match the actual hostname used to access Mydia (affects LiveView WebSocket connections)
- Project is 0.x.x — breaking changes between releases; check release notes before upgrading
- PostgreSQL available for larger installs — see https://docs.mydia.dev/latest/advanced/postgresql/
- Full env var reference: https://docs.mydia.dev/latest/reference/environment-variables/

---

## References
- Documentation: https://docs.mydia.dev
- Installation guide: https://docs.mydia.dev/latest/getting-started/installation/
- GitHub: https://github.com/getmydia/mydia#readme
