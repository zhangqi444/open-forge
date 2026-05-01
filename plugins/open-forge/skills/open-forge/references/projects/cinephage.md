# Cinephage

**Unified self-hosted media management — replaces Radarr, Sonarr, Prowlarr, Bazarr, and Overseerr in a single app with built-in Cloudflare bypass, IPTV/Live TV, usenet streaming, and .strm support.**
GitHub: https://github.com/MoldyTaint/Cinephage
Discord: https://discord.gg/scGCBTSWEt

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux | Docker Compose | Recommended |
| Any Linux | Bare metal (Node.js 22+) | npm + ffmpeg (optional) |

---

## Inputs to Collect

### Required
- `BETTER_AUTH_SECRET` — generate with `openssl rand -base64 32`
- Media paths — host paths for movies and TV show libraries
- Download client credentials — qBittorrent, SABnzbd, etc.
- Indexer API keys — for Prowlarr, Jackett, or direct indexers

### Optional
- `BETTER_AUTH_URL` — set to your public URL if behind a reverse proxy

---

## Software-Layer Concerns

### Docker Compose setup
```bash
mkdir cinephage && cd cinephage
curl -O https://raw.githubusercontent.com/MoldyTaint/Cinephage/main/docker-compose.yaml
curl -O https://raw.githubusercontent.com/MoldyTaint/Cinephage/main/.env.example
cp .env.example .env
# Edit .env — set BETTER_AUTH_SECRET at minimum
# Edit docker-compose.yaml — set your media/download volume paths
docker compose up -d
```

### Image tags
- `latest` — stable
- `dev` — preview builds
- `vX.Y.Z` — pinned versions

### Ports
- `3000` — web UI

### Data persistence
- Config stored in `./config/` (created automatically)
- Never mount `/app` — contains application code

### What it replaces

| App | Cinephage equivalent |
|-----|---------------------|
| Radarr | Movie management |
| Sonarr | TV series management |
| Prowlarr | Indexer management |
| Bazarr | Subtitle management |
| Overseerr | Content discovery + smart lists |
| FlareSolverr | Built-in Camoufox (no extra container) |

### Additional capabilities
- `.strm` file creation — stream without downloading (works with Jellyfin, Emby, Kodi)
- Usenet streaming — stream NZBs without full download
- Live TV / IPTV via Stalker portal discovery
- Smart quality scoring with 50+ factors (codec, HDR, audio, release group)
- Smart lists with auto-add (import from IMDb, Trakt, TMDb)

---

## Upgrade Procedure

1. docker compose pull
2. docker compose up -d

---

## Gotchas

- Set `BETTER_AUTH_URL` to your public URL if accessing behind a reverse proxy or domain
- Do not mount `/app` volume — it contains app code that will be overwritten
- Early-stage project; expect breaking changes between releases

---

## References
- GitHub: https://github.com/MoldyTaint/Cinephage#readme
- Discord: https://discord.gg/scGCBTSWEt
