---
name: mylar3-project
description: Automated comic book (CBR/CBZ) downloader and organiser for NZB and torrents. Integrates with SABnzbd, NZBGet, and torrent clients. Upstream: https://github.com/MylarComics/mylar3
---

# Mylar3

Automated comic book (CBR/CBZ) downloader and organiser for NZB and torrents. Creates a watchlist of series, monitors for new issues, grabs/sorts/renames downloads, supports weekly pull lists, story arcs, TPBs, and graphic novels. Community continuity fork of the original mylar3. Upstream: <https://github.com/MylarComics/mylar3>.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker (linuxserver) | [Docker Hub](https://hub.docker.com/r/linuxserver/mylar3) | ✅ | Recommended |
| Git clone | [GitHub](https://github.com/MylarComics/mylar3) | ✅ | Manual / source install |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| config | PUID / PGID | number | Docker |
| config | Timezone (TZ) | string | Docker |
| config | Path for config storage | path | All |
| config | Path for downloads | path | All |
| config | Path for comics library | path | All |
| config | Port to expose (default 8090) | number | Docker |

## Docker Compose install

Source: <https://hub.docker.com/r/linuxserver/mylar3>

```yaml
services:
  mylar3:
    image: lscr.io/linuxserver/mylar3:latest
    container_name: mylar3
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Europe/London
    volumes:
      - /path/to/config:/config
      - /path/to/data:/data
    ports:
      - 8090:8090
    restart: unless-stopped
```

Adjust `/path/to/config` and `/path/to/data` to your host paths.

## Configuration

All configuration is done through the Mylar3 web UI after first launch:
- Connect SABnzbd, NZBGet, or torrent client
- Add newznab/indexer API keys
- Configure file/folder naming templates
- Set up notifications (multiple services supported)

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

## Gotchas

- Runs on multiple OS and architectures (x86_64, ARM including Raspberry Pi).
- Use the `linuxserver/mylar3` image for the best-supported Docker experience.
- Full documentation is at the [Mylar website](https://mylar.nerdfirehurricane.com/).
- GitHub issues should be bugs/enhancement requests only — general discussion on Discord.

## References

- GitHub: <https://github.com/MylarComics/mylar3>
- Documentation: <https://mylar.nerdfirehurricane.com/>
- Docker Hub (linuxserver): <https://hub.docker.com/r/linuxserver/mylar3>
- Discord: <https://discord.gg/6qpyCZRZRB>
