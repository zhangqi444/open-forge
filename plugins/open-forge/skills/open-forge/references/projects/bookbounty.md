---
name: BookBounty
description: Automatically find and download missing Readarr books from Library Genesis. Integrates with Readarr API to identify gaps, searches Libgen, and imports downloads back. MIT licensed.
website: https://github.com/TheWicklowWolf/BookBounty
source: https://github.com/TheWicklowWolf/BookBounty
license: MIT
stars: 277
tags:
  - books
  - readarr
  - downloader
  - automation
platforms:
  - Docker
---

# BookBounty

BookBounty is a self-hosted tool that automatically finds and downloads missing books from your Readarr library. It connects to the Readarr API to identify books marked as missing or wanted, searches Library Genesis (Libgen) for matches, downloads them, and optionally triggers a Readarr library scan to import the files.

Source: https://github.com/TheWicklowWolf/BookBounty
Docker Hub: https://hub.docker.com/r/thewicklowwolf/bookbounty

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VM / VPS | Docker (alongside Readarr) | Single container |

## Inputs to Collect

**Phase: Planning**
- Readarr URL and API key
- Download directory path (should match Readarr's import path)
- Library Genesis URL (default: `http://libgen.is`)
- Search type: fiction or non-fiction
- Preferred file extensions

## Software-Layer Concerns

**Docker Compose:**

```yaml
services:
  bookbounty:
    image: thewicklowwolf/bookbounty:latest
    container_name: bookbounty
    ports:
      - "5000:5000"
    volumes:
      - /path/to/config:/bookbounty/config
      - /path/to/downloads:/bookbounty/downloads
      - /etc/localtime:/etc/localtime:ro
    environment:
      - readarr_address=http://192.168.1.2:8787
      - readarr_api_key=YOUR_READARR_API_KEY
      - libgen_address=http://libgen.is
      - search_type=fiction
      - sync_schedule=3
    restart: unless-stopped
```

**Key environment variables:**

| Variable | Description | Default |
|----------|-------------|---------|
| PUID | User ID | 1000 |
| PGID | Group ID | 1000 |
| readarr_address | Readarr URL | http://192.168.1.2:8787 |
| readarr_api_key | Readarr API key | (required) |
| libgen_address | Library Genesis URL | http://libgen.is |
| sleep_interval | Seconds between downloads | 0 |
| sync_schedule | Hours to run (comma-sep, 24h) | (manual) |
| minimum_match_ratio | Min fuzzy match % for title/author | 90 |
| selected_path_type | Download as `file` or `folder` | file |
| search_type | `fiction` or `non-fiction` | fiction |
| library_scan_on_completion | Trigger Readarr scan after download | True |
| request_timeout | HTTP request timeout (seconds) | 120 |
| thread_limit | Max concurrent downloads | 1 |
| selected_language | Language filter | English |
| preferred_extensions_fiction | Extensions to prefer (comma-sep) | .epub, .mobi, .azw3, .djvu |
| preferred_extensions_non_fiction | Extensions to prefer (comma-sep) | .pdf, .epub, .mobi |
| search_last_name_only | Use only author's last name in search | False |
| search_shortened_title | Shorten title at `:` for search | False |

**Readarr API key:** Found in Readarr → Settings → General → Security.

**Download path:** The `/bookbounty/downloads` mount should correspond to a path Readarr can see for importing — typically inside Readarr's configured download client path or a monitored folder.

**Web UI:** Open `http://your-server:5000` to manually trigger searches, view status, and manage settings.

## Upgrade Procedure

1. `docker pull thewicklowwolf/bookbounty:latest`
2. `docker compose down && docker compose up -d`
3. Check releases: https://github.com/TheWicklowWolf/BookBounty/releases

## Gotchas

- **Legal considerations**: BookBounty downloads from Library Genesis — verify your local laws regarding ebook downloads before use; Libgen hosts many copyrighted works
- **libgen_address**: Only `http://libgen.is` is officially supported; other mirrors may work but are untested
- **match_ratio**: Lower values (e.g. 70) find more results but risk wrong editions; higher values (90+) are safer but may miss some matches
- **fiction vs non-fiction**: Libgen has separate indexes for fiction and non-fiction — set `search_type` to match your library type; run separate instances for mixed libraries
- **No built-in auth**: Web UI on port 5000 has no authentication — protect behind a reverse proxy if exposed
- **Readarr must be running**: BookBounty queries Readarr at runtime — ensure Readarr is accessible from the BookBounty container

## Links

- Upstream README: https://github.com/TheWicklowWolf/BookBounty/blob/main/README.md
- Docker Hub: https://hub.docker.com/r/thewicklowwolf/bookbounty
- Releases: https://github.com/TheWicklowWolf/BookBounty/releases
