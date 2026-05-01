---
name: Kapowarr
description: "Self-hosted comic book library manager in the *arr suite style. Docker. Python. Casvt/Kapowarr. Add volumes, download issues (DDL/Pixeldrain/Mega), rename, move, convert, import existing library. GPL-3.0."
---

# Kapowarr

**Self-hosted comic book library manager — the *arr for comics.** Add comic volumes, monitor them for new issues, and Kapowarr downloads, renames, moves, and optionally converts them automatically. Familiar UI in the style of Sonarr/Radarr. Import your existing library, run manual or automated searches, handle TPBs, One Shots, Hard Covers, and more.

Built + maintained by **Casvt**. GPL-3.0.

- Upstream repo: <https://github.com/Casvt/Kapowarr>
- Docker Hub: `mrcas/kapowarr`
- Documentation: <https://casvt.github.io/Kapowarr/>

## Architecture in one minute

- **Python** backend + web frontend
- **SQLite** database (stored in `/app/db` volume)
- Port **5656**
- Volumes: database, temp downloads, comics library
- Resource: **low** — Python, SQLite, no heavy services

## Compatible install methods

| Infra      | Runtime              | Notes                                       |
| ---------- | -------------------- | ------------------------------------------- |
| **Docker** | `mrcas/kapowarr`     | **Primary** — single container              |

## Install via Docker

```yaml
services:
  kapowarr:
    container_name: kapowarr
    image: mrcas/kapowarr:latest
    restart: unless-stopped
    environment:
      - PUID=0
      - PGID=0
      - TZ=Etc/UTC
    volumes:
      - kapowarr-db:/app/db
      - /path/to/download_folder:/app/temp_downloads
      - /path/to/comics:/comics
    ports:
      - "5656:5656"

volumes:
  kapowarr-db:
```

Replace `/path/to/download_folder` with a temp downloads path and `/path/to/comics` with your comics library root.

```bash
docker compose up -d
```

Visit `http://localhost:5656`.

## Environment variables

| Variable | Default | Notes |
|----------|---------|-------|
| `PUID` | `0` | User ID for file ownership. Use your host user ID for proper permissions (or leave 0 for root) |
| `PGID` | `0` | Group ID for file ownership |
| `TZ` | `Etc/UTC` | Timezone |

## Volumes

| Container path | Purpose |
|----------------|---------|
| `/app/db` | SQLite database — persist as a named volume |
| `/app/temp_downloads` | Temporary download staging area |
| `/comics` | Your comics library root — can add multiple paths in settings |

## Features overview

| Feature | Details |
|---------|---------|
| Volume management | Add comic volumes; monitor for new issues |
| Search Monitored | Download all monitored volumes with one click |
| Manual Search | Browse and choose specific downloads |
| Automated downloads | DDL, Pixeldrain, Mega, and more download services |
| Auto-rename | Rename downloaded files to your preferred format |
| Auto-move | Move files to the correct library location |
| Archive conversion | Convert archive formats (CBZ/CBR) on download or on demand |
| Archive extraction | Extract archive contents and rename |
| Library import | Import your existing comic library into Kapowarr |
| TPBs / One Shots / HCs | Supports trade paperbacks, one shots, hard covers, and more |
| *arr-style UI | Familiar interface for users of Sonarr/Radarr |

## First run

1. Open `http://localhost:5656`
2. Go to **Settings → Download Clients** → add your download service(s)
3. Go to **Settings → Root Folders** → add `/comics` (or your mapped path)
4. Search for a comic volume, add it, and start downloading

## Gotchas

- **`PUID=0` in example = root.** The example compose uses root (`PUID=0`). For better security, set `PUID`/`PGID` to your host user's IDs (`id -u` / `id -g`) and ensure the comics and temp folders are writable by that user.
- **Multiple comics root folders.** You can configure multiple root folders in Settings. Map each as a separate volume (`/comics2`, `/manga`, etc.) and add them in the UI.
- **Download services require setup.** Kapowarr integrates with DDL hosts, Pixeldrain, and Mega. You need accounts/API keys for the services you want to use — configured in Settings → Download Clients.
- **GPL-3.0 license.** Modifications must be released under GPL-3.0.

## Backup

```sh
# SQLite database in named volume
docker run --rm -v kapowarr-db:/app/db -v $(pwd):/backup alpine \
  cp /app/db/kapowarr.db /backup/kapowarr-$(date +%F).db
```

## Upgrade

```sh
docker compose pull && docker compose up -d
```

## Project health

Active Python development, *arr-style UI, GPL-3.0.

## Comics-management-family comparison

- **Kapowarr** — Python, *arr-style, DDL/Pixeldrain/Mega, rename/move/convert, GPL-3.0
- **Mylar3** — Python, comic book server + downloader (NZB/torrent), more protocols; GPL-3.0
- **Komga** — Kotlin/Spring, comic reader + library server (no downloader); MIT
- **Kavita** — C#/.NET, manga/comic/book reader + library server (no downloader); MIT

**Choose Kapowarr if:** you want a self-hosted *arr-style comic book manager that automatically downloads, renames, and organises issues from DDL and file-hosting services.

## Links

- Repo: <https://github.com/Casvt/Kapowarr>
- Docs: <https://casvt.github.io/Kapowarr/>
- Docker Hub: <https://hub.docker.com/r/mrcas/kapowarr>
