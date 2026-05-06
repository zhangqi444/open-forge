---
name: rapidbay
description: Recipe for Rapidbay — a self-hosted video streaming service that searches torrents via Jackett/Prowlarr, downloads, converts, and streams video to browsers or Chromecast/AppleTV. Python + Docker.
---

# Rapidbay

Self-hosted video streaming service that uses torrent indexers (Jackett or Prowlarr) to search for content, downloads and converts the selected video file (via ffmpeg), and streams it directly to your browser, Chromecast, or AppleTV. No separate torrent client needed — everything is built-in. Upstream: <https://github.com/hauxir/rapidbay>.

License: MIT. Platform: Python, Docker. Port: `5000`. Requires Jackett or Prowlarr as a search backend.

## Compatible install methods

| Method | When to use |
|---|---|
| Docker (single container) | Recommended |
| Docker Compose (with Jackett or Prowlarr) | Recommended for full stack |
| Python native | For development |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| search | "Search backend: Jackett or Prowlarr (or both)?" | Both can be used simultaneously; results are merged |
| search | "Jackett host URL and API key?" | e.g. `http://jackett:9117` |
| search | "Prowlarr host URL and API key?" | e.g. `http://prowlarr:9696` |
| storage | "Host path for downloaded/converted video files?" | Optional persistent volume — files are auto-cleaned |
| network | "Host port for Rapidbay web UI?" | Default `5000` |

## Docker with Jackett (recommended)

```bash
mkdir rapidbay && cd rapidbay
```

`docker-compose.yml`:
```yaml
services:
  jackett:
    image: linuxserver/jackett
    ports:
      - "9117:9117"
    volumes:
      - ./jackett_config:/config
    restart: unless-stopped

  rapidbay:
    image: hauxir/rapidbay:latest
    environment:
      - JACKETT_HOST=http://jackett:9117
      - JACKETT_API_KEY=YOUR_JACKETT_API_KEY
    ports:
      - "5000:5000"
    volumes:
      - ./videos:/tmp/rapidbay       # optional persistent storage
    depends_on:
      - jackett
    restart: unless-stopped
```

```bash
docker compose up -d
```

Web UI at `http://your-host:5000`.

## Docker with Prowlarr

`docker-compose.yml`:
```yaml
services:
  prowlarr:
    image: linuxserver/prowlarr
    ports:
      - "9696:9696"
    volumes:
      - ./prowlarr_config:/config
    restart: unless-stopped

  rapidbay:
    image: hauxir/rapidbay:latest
    environment:
      - PROWLARR_HOST=http://prowlarr:9696
      - PROWLARR_API_KEY=YOUR_PROWLARR_API_KEY
    ports:
      - "5000:5000"
    depends_on:
      - prowlarr
    restart: unless-stopped
```

## Using both Jackett and Prowlarr

Set all four environment variables — Rapidbay will query both and deduplicate results:

```yaml
environment:
  - JACKETT_HOST=http://jackett:9117
  - JACKETT_API_KEY=YOUR_JACKETT_API_KEY
  - PROWLARR_HOST=http://prowlarr:9696
  - PROWLARR_API_KEY=YOUR_PROWLARR_API_KEY
```

## Environment variables

| Variable | Description |
|---|---|
| `JACKETT_HOST` | Jackett base URL (e.g. `http://jackett:9117`) |
| `JACKETT_API_KEY` | Jackett API key |
| `PROWLARR_HOST` | Prowlarr base URL (e.g. `http://prowlarr:9696`) |
| `PROWLARR_API_KEY` | Prowlarr API key |

## Software-layer concerns

| Concern | Detail |
|---|---|
| Default port | `5000` |
| Temp storage | `/tmp/rapidbay` inside the container — auto-cleaned |
| Video conversion | ffmpeg (bundled in the image) converts to browser-compatible format |
| Subtitles | Automatically downloaded and converted (SRT → WebVTT) |
| Kodi support | Rapidbay can act as a Kodi plugin source |
| Magnet links | Can register as the default magnet link handler in the browser |

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

## Gotchas

- **At least one search backend is required**: Rapidbay cannot search without Jackett or Prowlarr. Set up and configure your indexers in Jackett/Prowlarr before expecting search results.
- **Auto disk cleanup**: Rapidbay automatically cleans up downloaded/converted files to prevent disk filling up. If you want persistent storage, mount a volume to `/tmp/rapidbay` but note that files are still auto-managed.
- **Legal considerations**: Rapidbay is a tool for streaming torrents. Ensure you only use it for content you have the right to access. The operators of the upstream project do not endorse copyright infringement.
- **Conversion time**: The first time you play a video, Rapidbay downloads and converts it — this can take minutes depending on file size and CPU speed. Subsequent plays of the same file are instant.
- **Chromecast/AppleTV**: Both are supported for casting directly from the Rapidbay web UI on the same network.
- **No authentication**: Rapidbay has no built-in user authentication. Restrict access via firewall rules or a reverse proxy with HTTP basic auth if exposing beyond localhost.

## Upstream links

- Source: <https://github.com/hauxir/rapidbay>
- Docker Hub: <https://hub.docker.com/r/hauxir/rapidbay>
