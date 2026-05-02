# Music Service

**What it is:** A self-hosted service that monitors your YouTube playlists (and other supported sources) and automatically downloads new music as high-quality MP3s, then uploads them to your WebDAV-compatible cloud storage (Nextcloud, ownCloud, pCloud, STACK, etc.). Handles format conversion, cover art embedding, and deduplication so previously-downloaded songs are never re-fetched.

**Official URL:** https://github.com/thijstakken/MusicService
**Docker Hub:** `thijstakken/musicservice`
**License:** MIT
**Stack:** Python + MySQL + Redis + Celery; uses yt-dlp/youtube-dl under the hood

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS / bare metal | Docker Compose | Recommended; full stack with MySQL + Redis |
| Homelab (24/7 server) | Docker Compose | Best experience on always-on machine |

---

## Inputs to Collect

### Pre-deployment
- WebDAV credentials — URL, username, password for your cloud storage (Nextcloud, etc.)
- YouTube playlist URLs to monitor
- MySQL password (change from default in compose file)

### Environment variables
- `DATABASE_URL` — MySQL connection string (e.g. `mysql+pymysql://musicservice:musicservice@database/musicservice`)
- `REDIS_URL` — Redis connection (e.g. `redis://redis:6379/0`)
- WebDAV and playlist config — entered via the web UI at `http://localhost:5678`

---

## Software-Layer Concerns

**Docker Compose:**
```yaml
services:
  musicservice:
    image: thijstakken/musicservice:latest
    container_name: musicservice
    restart: always
    ports:
      - 5678:5678
    volumes:
      - music:/music
    depends_on:
      - database
      - redis
    environment:
      - REDIS_URL=redis://redis:6379/0
      - DATABASE_URL=mysql+pymysql://musicservice:musicservice@database/musicservice

  database:
    image: mysql:latest
    container_name: mysql
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: root
      MYSQL_DATABASE: musicservice
      MYSQL_USER: musicservice
      MYSQL_PASSWORD: musicservice   # Change this!
    volumes:
      - db:/var/lib/mysql

  redis:
    image: redis:latest
    container_name: redis
    restart: always
    volumes:
      - redis_data:/data

volumes:
  music:
  db:
  redis_data:
```

**Default port:** `5678` → web UI for configuration

**Supported sources:** YouTube, SoundCloud, and [all yt-dlp/youtube-dl supported sites](http://ytdl-org.github.io/youtube-dl/supportedsites.html)

**Supported WebDAV targets:** Nextcloud, ownCloud, pCloud, STACK, and any WebDAV-compatible storage

**Deduplication:** Tracks downloaded songs in MySQL; won't re-download if already present in the music volume.

**Cover art:** Automatically embedded into MP3s during conversion.

**Upgrade procedure:**
1. `docker compose pull`
2. `docker compose up -d`

---

## Gotchas

- **Best on 24/7 hardware** — playlist monitoring is continuous; running on a machine that sleeps will miss new tracks until it wakes
- **YouTube bot detection** — yt-dlp may be blocked by YouTube periodically; update the container image to get the latest yt-dlp fixes
- **Change MySQL default passwords** — the compose file uses `musicservice`/`root` by default; change before exposing to any network
- **WebDAV required for cloud sync** — if you only want local storage, music lands in the `music` volume; WebDAV upload is optional
- **Legal reminder** — consider supporting artists directly (Bandcamp, Beatport) when possible

---

## Links
- GitHub: https://github.com/thijstakken/MusicService
- Docker Hub: https://hub.docker.com/r/thijstakken/musicservice
- Supported sites: http://ytdl-org.github.io/youtube-dl/supportedsites.html
- WebDAV providers: https://community.cryptomator.org/t/webdav-urls-of-common-cloud-storage-services/75
