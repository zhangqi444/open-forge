# Soulbeet

**What it is:** Self-hosted music downloader, library manager, and discovery engine. Search for music, click download — Soulbeet finds the best Soulseek source, downloads via slskd, tags and organizes with beets, and adds to your Navidrome library. Discovery mode analyzes Last.fm/ListenBrainz history to automatically find and download new music, then pushes playlists to Navidrome.

**GitHub:** https://github.com/terry90/soulbeet  
**Docker Hub:** `docccccc/soulbeet`

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS/VM | Docker Compose | Recommended; multi-container stack |
| Raspberry Pi (ARM64) | Docker | Multi-arch: amd64 + arm64 |

---

## Stack Components

| Container | Image | Role |
|-----------|-------|------|
| `soulbeet` | `docccccc/soulbeet:latest` | Main app — web UI, discovery engine, beets integration |
| `navidrome` | `deluan/navidrome:latest` | Music streaming server |
| `slskd` | `slskd/slskd` | Soulseek download client |

---

## Inputs to Collect

### Phase: Deploy

| Variable | Description |
|----------|-------------|
| `SECRET_KEY` | Encryption key for tokens and credentials |
| `NAVIDROME_URL` | URL of your Navidrome instance |
| `/downloads` path | Shared path where slskd saves files (must match between slskd and soulbeet) |
| `/music` path | Shared music library path (must match between soulbeet and navidrome) |

### Phase: Optional

| Variable | Description |
|----------|-------------|
| `DATABASE_URL` | SQLite connection string (default `sqlite:soulbeet.db`) |
| `DOWNLOAD_PATH` | Path where slskd saves downloads (default `/downloads`) |
| `BEETS_CONFIG` | Path to custom beets config file |
| `BEETS_ALBUM_MODE` | Enable album import mode instead of singleton (default `false`) |

### Post-deploy configuration (web UI)

- Connect slskd: Settings > Config — enter slskd URL and API key
- Add music folders: Settings > Library
- Discovery (optional): add Last.fm API key and/or ListenBrainz token per-user in Settings > Library

---

## Software-Layer Concerns

- **Shared volume contract is critical:**
  - `/downloads` must be the same physical path in both `slskd` and `soulbeet` containers — slskd writes here, soulbeet reads from here
  - `/music` must be the same physical path in both `soulbeet` and `navidrome` containers — soulbeet organizes here, navidrome streams from here
- **Soulseek account required** — configure in slskd after deployment
- **beets** is bundled in the Soulbeet Docker image — no separate installation needed
- **Discovery profiles:** Conservative / Balanced / Adventurous — each generates its own Navidrome playlist
- **Rating system:** 3+ stars in Navidrome promotes a track to permanent library; 1 star deletes it; unrated tracks expire and get replaced

---

## Example Docker Compose

```yaml
services:
  soulbeet:
    image: docker.io/docccccc/soulbeet:latest
    restart: unless-stopped
    ports:
      - "9765:9765"
    volumes:
      - ./data:/data
      - /path/to/slskd/downloads:/downloads
      - /path/to/music:/music
    environment:
      SECRET_KEY: your_secret_key
      NAVIDROME_URL: http://navidrome:4533
    depends_on:
      - slskd
      - navidrome

  navidrome:
    image: deluan/navidrome:latest
    ports:
      - "4533:4533"
    environment:
      ND_MUSICFOLDER: /music
    volumes:
      - ./navidrome-data:/data
      - /path/to/music:/music

  slskd:
    image: slskd/slskd
    environment:
      SLSKD_REMOTE_CONFIGURATION: "true"
    volumes:
      - ./slskd-config:/app/slskd.conf.d
      - /path/to/slskd/downloads:/app/downloads
    ports:
      - "5030:5030"
```

---

## Upgrade Procedure

1. Pull new images: `docker compose pull`
2. Restart: `docker compose up -d`
3. Data persists in `./data` and music/download volumes

---

## Gotchas

- **Volume path alignment is mandatory** — mismatched `/downloads` or `/music` paths between containers will silently break downloading or library sync
- **Soulseek account needed** — slskd requires a Soulseek account; create one at soulseek.com
- **slskd API key** — needed to connect Soulbeet to slskd; generate in slskd's web UI
- `BEETS_ALBUM_MODE=false` (default) uses singleton import — each track imported individually; set `true` for album-based imports
- Navidrome must index the `/music` folder after Soulbeet adds files — trigger a scan in Navidrome if new tracks don't appear

---

## Links

- GitHub: https://github.com/terry90/soulbeet
- Docker Hub: https://hub.docker.com/r/docccccc/soulbeet
- slskd: https://github.com/slskd/slskd
- Navidrome: https://www.navidrome.org
