---
name: couchtube
description: Recipe for CouchTube — self-hostable YouTube frontend that simulates a TV channel experience. Schedules YouTube video playback from predefined channel lists based on current time. Go + SQLite, single Docker image.
---

# CouchTube

Self-hostable YouTube frontend that simulates a TV channel experience. Upstream: https://github.com/ozencb/couchtube

Go service with SQLite that dynamically loads YouTube videos from channel lists and schedules playback based on the current time — two users watching the same channel see the same video segment. Users can also submit custom video lists via JSON URL. Inspired by ytch.xyz.

> **Early development** — expect bugs. Report issues on GitHub.

## Compatible combos

| Runtime | Notes |
|---|---|
| Docker Compose | Recommended — single container, SQLite embedded |
| Docker run | Supported |
| Go binary | Build from source with Go 1.22+ |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | Port | Default: 8363 |
| preflight | Database file path | Default: /app/data/couchtube.db inside container |

## Software-layer concerns

**Config:** Environment variables only. Key vars:

| Var | Default | Description |
|---|---|---|
| PORT | 8363 | Listen port |
| DATABASE_FILE_PATH | /app/data/couchtube.db | SQLite DB path inside container |

**Data:** SQLite database at DATABASE_FILE_PATH. Mount a persistent volume to preserve the database (channels, custom lists) across container restarts. On first run, the DB is created and populated with default channels from videos.json.

**Port:** 8363.

**YouTube dependency:** CouchTube loads and plays YouTube videos in an iframe/embed. It does not download or proxy video — playback depends on YouTube being accessible from the user's browser. YouTube embed restrictions (no-embed flagged videos) may affect some content.

**Channel lists:** Default channels are in `videos.json` in the repo. Users can submit custom JSON lists via the UI. Community channel lists can be contributed via pull request.

**Scheduling:** Videos are distributed throughout the day by a scheduler so that different users watching the same channel see the same content at the same time.

## Docker Compose

```yaml
services:
  couchtube:
    image: ghcr.io/ozencb/couchtube:latest
    container_name: couchtube_app
    restart: unless-stopped
    ports:
      - "8363:8363"
    environment:
      - PORT=8363
      - DATABASE_FILE_PATH=/app/data/couchtube.db
    volumes:
      - couchtube_data:/app/data
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8363"]
      interval: 30s
      timeout: 10s
      retries: 3

volumes:
  couchtube_data:
```

## Upgrade procedure

```bash
docker compose pull couchtube
docker compose up -d couchtube
```

SQLite DB is preserved in the named volume. No known migrations — check release notes before upgrading.

## Gotchas

- **Early-stage software** — the project is in early development; APIs and behavior may change.
- **YouTube embed required** — users' browsers must be able to reach YouTube. No video proxying is done by CouchTube.
- **YouTube ToS** — embedding YouTube content is subject to YouTube's Terms of Service; ensure your use case is compliant.
- **Custom video lists** — JSON list format must match the upstream schema (see videos.json in the repo for the structure).

## Links

- Upstream repository: https://github.com/ozencb/couchtube
- GitHub Container Registry: https://ghcr.io/ozencb/couchtube
- Inspired by: https://ytch.xyz
