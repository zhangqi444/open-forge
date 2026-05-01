# AudioBookRequest

**Audiobook request manager for Plex, Audiobookshelf, and Jellyfin — like Overseerr/Ombi but for audiobooks. Users search Audible and request titles; admins approve and auto-download via Prowlarr.**
GitHub: https://github.com/markbeep/AudioBookRequest
Wiki: https://github.com/markbeep/AudioBookRequest/wiki
Discord: https://discord.gg/SsFRXWMg7s

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux | Docker | Single-image deployment |
| Kubernetes | Helm/manifest | See wiki |

---

## Inputs to Collect

### Required
- Volume mount for `/config` (persistent data)

### Optional
- Prowlarr URL + API key — for automatic downloading
- Audiobookshelf URL + API key — for library integration
- OIDC credentials — for SSO
- Notification service details (Apprise/Gotify/Discord/ntfy) — for alerts

See full environment variables: https://github.com/markbeep/AudioBookRequest/wiki/Environment-Variables

---

## Software-Layer Concerns

### Docker run
```bash
docker run -p 8000:8000 -v $(pwd)/config:/config markbeep/audiobookrequest:1
```
Access at http://localhost:8000

### Docker Compose
```yaml
services:
  audiobookrequest:
    image: markbeep/audiobookrequest:1
    ports:
      - "8000:8000"
    volumes:
      - ./config:/config
    restart: unless-stopped
```

> For PostgreSQL instead of SQLite, add a `postgres` service and set `DATABASE_URL` env var — see wiki.

### Ports
- `8000` — web UI

### Storage
- `/config` — stores SQLite database and app config (mount persistently)

### Key features
- Audible API search for audiobooks
- Manual request entry for non-Audible titles
- Three user groups (admin, manager, user) — minimal user management
- Automatic downloading via Prowlarr + existing download clients
- Notifications via Apprise, Gotify, Discord, ntfy, and more
- Audiobookshelf integration (library status)
- OpenID Connect (OIDC) / SSO support
- SQLite (default) or PostgreSQL
- Mobile-friendly, lightweight (no heavy JS)

---

## Upgrade Procedure

1. docker compose pull
2. docker compose up -d

---

## Gotchas

- ABR does **not** handle moving, renaming, or editing metadata after download — pair with a post-processing script or tool
- Not a replacement for Readarr/Chaptarr — intended to complement them as the request frontend
- First login requires configuring login type and root admin account
- Full environment variable reference: https://github.com/markbeep/AudioBookRequest/wiki/Environment-Variables

---

## References
- Wiki: https://github.com/markbeep/AudioBookRequest/wiki
- GitHub: https://github.com/markbeep/AudioBookRequest#readme
