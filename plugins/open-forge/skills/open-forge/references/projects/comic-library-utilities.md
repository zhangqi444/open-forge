# Comic Library Utilities (CLU)

> Self-hosted web app for managing large comic book libraries — bulk convert, rename, move, and enhance CBZ/CBR files; download comics from GetComics.org; update metadata via Metron and ComicVine; folder monitoring with auto-processing; reading insights and timeline. Designed as a standalone companion to Komga (or as a standalone tool).

**Official URL:** https://github.com/allaboutduncan/clu-comics  
**Docs:** https://clucomics.org

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS/VM/NAS | Docker | Primary supported method |
| Any Linux VPS/VM/NAS | Docker Compose | Recommended for production |
| Unraid | Docker | PUID=99 / PGID=100 typical |
| Windows/WSL | Docker | Set PUID/PGID to match Windows user |

---

## Inputs to Collect

### Phase: Pre-Deploy
| Input | Description | Example |
|-------|-------------|---------|
| `LIBRARY_PATH` | Host path to your primary comic library | `/e/Comics` |
| `CONFIG_PATH` | Host path for persistent config storage | `./config` |
| `CACHE_PATH` | Host path for DB and thumbnail cache | `./cache` |
| `PUID` | User ID for file permissions | `99` (Unraid) or your UID |
| `PGID` | Group ID for file permissions | `100` (Unraid) or your GID |
| `UMASK` | File creation mask | `022` |
| `MONITOR` | Enable folder monitoring | `yes` or `no` |

### Phase: Optional Auth
| Input | Description | Example |
|-------|-------------|---------|
| `CLU_USERNAME` | Basic auth username | `admin` |
| `CLU_PASSWORD` | Basic auth password | strong password |

### Phase: Additional Libraries (optional)
| Input | Description | Example |
|-------|-------------|---------|
| `MANGA_PATH` | Host path to manga library | `/e/Manga` |
| `DOWNLOADS_PATH` | Host path for folder monitoring downloads | `/f/Downloads` |

---

## Software-Layer Concerns

### Config & Data Directories
| Path (container) | Purpose |
|------------------|---------|
| `/config` | Persistent app settings — **must be mounted** |
| `/cache` | SQLite database + thumbnail cache |
| `/data` | Primary comic library (map your main library here) |
| `/downloads` | Folder monitoring watch directory (optional) |

> **First install:** After starting, visit the Config page, verify settings, then click **Restart App**.

### Key Environment Variables
```
FLASK_ENV=production
PUID=99
PGID=100
UMASK=022
MONITOR=yes
# Optional basic auth:
CLU_USERNAME=admin
CLU_PASSWORD=changeme
```

### Ports
| Container | Purpose |
|-----------|---------|
| `5577` | Web UI |

### Multiple Libraries
- Map your primary library to `/data`
- Map additional libraries to custom paths (e.g., `/manga`, `/magazines`)
- Configure additional library paths inside the app Settings

---

## Docker Compose Example

```yaml
services:
  clu:
    image: allaboutduncan/comic-utils-web:latest
    container_name: clu
    restart: always
    ports:
      - "5577:5577"
    volumes:
      - ./config:/config
      - ./cache:/cache
      - /path/to/Comics:/data
      - /path/to/Manga:/manga
      - /path/to/Downloads:/downloads
    environment:
      - FLASK_ENV=production
      - MONITOR=yes
      - PUID=99
      - PGID=100
      - UMASK=022
    logging:
      driver: "json-file"
      options:
        max-size: "20m"
        max-file: "3"
```

---

## Upgrade Procedure

1. Pull the latest image: `docker pull allaboutduncan/comic-utils-web:latest`
2. Stop and remove the container: `docker compose down`
3. Start with new image: `docker compose up -d`
4. Verify logs: `docker compose logs -f`

---

## Gotchas

- **`/config` volume is required** — without it, settings are lost on container restarts/updates
- **PUID/PGID must match the owner of your library files** — mismatched IDs cause permission errors when the app tries to rename or modify comics
- **Folder monitoring** requires the `/downloads` volume mount and `MONITOR=yes`; auto-converts and moves files based on configured rules
- **GetComics.org downloads** are a built-in feature — check legality for your jurisdiction before use
- **No built-in HTTPS** — proxy with Nginx/Caddy/Traefik for remote access
- **Optional local GCD database** — adds offline metadata lookups; see docs for setup

---

## Links
- GitHub: https://github.com/allaboutduncan/clu-comics
- Full docs: https://clucomics.org
- Discord: https://discord.gg/ndDhpvrgBa
