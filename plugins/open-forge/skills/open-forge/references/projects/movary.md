# Movary

**Self-hosted movie watch history tracker — track, rate, and explore your movie watching habits with statistics, Trakt/Letterboxd/Netflix import, Plex/Jellyfin/Emby/Kodi scrobbling, and Mastodon cross-posting.**
Official site: https://movary.org
Docs: https://docs.movary.org
Demo: https://demo.movary.org (user: testUser@movary.org / pass: testUser)
GitHub: https://github.com/leepeuker/movary

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux | Docker Compose + MySQL | Recommended |
| Any Linux | Docker Compose + SQLite | Lighter setup |

---

## Inputs to Collect

### Required
- Database credentials (MySQL or SQLite path)
- App secret key

### Optional
- Plex/Jellyfin/Emby/Kodi token — for automatic scrobbling
- Trakt / Letterboxd / Netflix credentials — for history import
- Mastodon credentials — for cross-posting

---

## Software-Layer Concerns

### Docker Compose
Full compose examples (MySQL and MySQL+secrets variants) in the official docs:
https://docs.movary.org/install/docker/

### Ports
- `80` / `443` — web UI (served via PHP-FPM + nginx in the container)

### Key features
- Movie watch history with ratings
- Statistics: most watched actors/directors/genres/languages/years
- Import from Trakt, Letterboxd, Netflix
- Auto-scrobbling from Plex, Jellyfin, Emby, Kodi
- Cross-post activity to Mastodon (Fediverse)
- Locally stored TMDB/IMDb metadata
- Privacy controls — users control who can see their data
- PWA installable as smartphone app
- Multi-user support

---

## Upgrade Procedure

1. Check release notes for breaking changes (pre-1.0 project)
2. docker compose pull
3. docker compose up -d

---

## Gotchas

- Pre-1.0 project — breaking changes may occur; always read release notes before upgrading
- MySQL is the recommended database for full feature support
- Scrobbling requires a webhook or API token configured in your media server
- Full compose files are in the docs (not the repo root): https://docs.movary.org/install/docker/

---

## References
- Installation guide: https://docs.movary.org/install/docker/
- Documentation: https://docs.movary.org
- GitHub: https://github.com/leepeuker/movary#readme
