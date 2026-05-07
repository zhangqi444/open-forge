---
name: sist2
description: Lightning-fast file system indexer and search tool. Extracts text and metadata from common file types, generates thumbnails, and provides a mobile-friendly web search UI. Requires Elasticsearch or SQLite backend. GPL-3.0.
website: https://github.com/sist2app/sist2
source: https://github.com/sist2app/sist2
license: GPL-3.0
stars: 1253
tags:
  - search
  - file-indexer
  - full-text-search
  - elasticsearch
platforms:
  - C
  - Docker
---

# sist2

sist2 (Simple Incremental Search Tool) is a fast, low-memory, multi-threaded file system indexer and search engine. It scans your files, extracts text and metadata from hundreds of formats, generates thumbnails, and serves a mobile-friendly web interface backed by Elasticsearch or SQLite.

Source: https://github.com/sist2app/sist2  
Demo: https://sist2.simon987.net/  
Latest release: 3.3.6 (October 2023)

> **Note**: sist2 is in early development per upstream. Release cadence has slowed significantly (last release Oct 2023); the project is active in its community channel (Discord) but may require manual builds for latest features.

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VM / VPS | Docker + Elasticsearch 7.x | Recommended for full-text search at scale |
| Any Linux VM / VPS | Docker + SQLite | Simpler setup; no Elasticsearch required |
| Linux / WSL | Native binary + Elasticsearch | Lightweight; binary available for x64 Linux |

## Inputs to Collect

**Phase: Planning**
- Path(s) to index (host directories to mount)
- Search backend: Elasticsearch 7.x or SQLite
- Elasticsearch Java heap size (default: `2g`)
- Port for sist2-admin UI (default: `8080`)
- Port for search frontend (default: `4090`) — **do not expose publicly**
- Data volume paths for Elasticsearch data and sist2-admin state

## Software-Layer Concerns

**Docker Compose (with Elasticsearch):**
```yaml
services:
  elasticsearch:
    image: elasticsearch:7.17.9
    restart: unless-stopped
    volumes:
      - sist2_es_data:/usr/share/elasticsearch/data
    environment:
      - discovery.type=single-node
      - ES_JAVA_OPTS=-Xms2g -Xmx2g

  sist2-admin:
    image: sist2app/sist2:x64-linux
    restart: unless-stopped
    volumes:
      - sist2_admin_data:/sist2-admin/
      - /path/to/your/files:/host        # mount files to index here
    ports:
      - 4090:4090
      - 8080:8080    # admin UI — do NOT expose publicly
    working_dir: /root/sist2-admin/
    entrypoint: python3
    command:
      - /root/sist2-admin/sist2_admin/app.py

volumes:
  sist2_es_data:
  sist2_admin_data:
```

**Admin UI:** Navigate to `http://localhost:8080/` to configure scan jobs.  
**Search UI:** Accessible at `http://localhost:4090/` (expose this port to users).

**Elasticsearch data directory permissions:**
```bash
# The ES data directory must have UID:GID 1000:1000 permissions
chown -R 1000:1000 /data/sist2-es-data/
```

**CLI usage (native binary):**
```bash
# Scan and index
sist2 scan /path/to/files --name "My Files" --output /tmp/my_index
sist2 index --es-url http://localhost:9200 /tmp/my_index

# Run search frontend
sist2 web --es-url http://localhost:9200 --bind 0.0.0.0:4090
```

**Supported formats:** PDF, Office documents, images (EXIF), audio/video (metadata), archives (recursive), code files, and many more — see upstream format support table.

## Upgrade Procedure

1. Pull new image: `docker pull sist2app/sist2:x64-linux`
2. `docker-compose down && docker-compose up -d`
3. Re-run scans if index format changed (check release notes)
4. For Elasticsearch upgrades, follow Elasticsearch rolling upgrade procedures

## Gotchas

- **Elasticsearch version**: Requires Elasticsearch 6.8.x or 7.x; **not compatible with Elasticsearch 8.x** without modifications
- **Admin port exposure**: Port 8080 (admin) must NOT be exposed publicly — it has no authentication and allows arbitrary command execution
- **Memory requirements**: Elasticsearch needs significant RAM; the default `-Xms2g -Xmx2g` requires at least 4GB total system RAM
- **Early development warning**: Upstream labels the project "in early development" — expect rough edges and potential breaking changes between versions
- **Slow development**: Last release (3.3.6) was October 2023; check the Discord community for development snapshots if you need newer features
- **SQLite backend**: Faster to set up but lacks some Elasticsearch features (fuzzy search, aggregations); see upstream comparison table
- **OCR support**: Optional Tesseract integration for image text extraction — requires additional setup

## Links

- Upstream README: https://github.com/sist2app/sist2/blob/master/README.md
- Format support: https://github.com/sist2app/sist2#format-support
- Search backends comparison: https://github.com/sist2app/sist2#search-backends
- Discord community: https://discord.gg/2PEjDy3Rfs
