# Riven

**Plex/Jellyfin/Emby torrent streaming via Debrid services — automates content discovery, scraping, and library management from Overseerr, Trakt, Mdblist, and more.**
GitHub: https://github.com/rivenmedia/riven
Discord: https://discord.riven.tv

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Linux | Docker Compose | Requires shared bind mount for /mount |

---

## Inputs to Collect

### Required
- Debrid service credentials — Real-Debrid or All-Debrid API key
- Media server — Plex, Jellyfin, or Emby URL + token
- Mount path — host path for RivenVFS virtual filesystem

### Content sources (pick at least one)
- Plex Watchlist, Overseerr URL+key, Mdblist, Listrr, or Trakt

### Scraper sources (pick at least one)
- Comet, Jackett, Torrentio, Orionoid, Mediafusion, Prowlarr, Zilean, or Rarbg

---

## Software-Layer Concerns

### Mount setup (REQUIRED — run once per boot)
The mount directory must be a shared bind mount:
```bash
sudo mkdir -p /path/to/riven/mount
sudo mount --bind /path/to/riven/mount /path/to/riven/mount
sudo mount --make-rshared /path/to/riven/mount
```
To persist across reboots, add a systemd unit or fstab entry (see README).

### Volume mount syntax
When adding /mount to any container in docker-compose, append `:rshared,z`:
```yaml
volumes:
  - /path/to/riven/data:/riven/data
  - /path/to/riven/mount:/mount:rshared,z
```

### Docker Compose
Copy the docker-compose.yml from the repo: https://github.com/rivenmedia/riven/blob/main/docker-compose.yml
Adjust all PATHS to match your environment.

---

## Upgrade Procedure

1. docker compose pull
2. docker compose up -d

---

## Gotchas

- The shared bind mount is mandatory — without it RivenVFS cannot expose virtual files to the media server
- Make the bind mount persistent (systemd unit or fstab) or it will break after reboot
- Plex requires additional configuration — see README Plex section
- All integrations (Debrid, content sources, scrapers) are configured via the Riven web UI after first start
- Project is actively developed; check the project board for upcoming features

---

## References
- Docker Compose: https://github.com/rivenmedia/riven/blob/main/docker-compose.yml
- GitHub: https://github.com/rivenmedia/riven#readme
- Discord: https://discord.riven.tv
