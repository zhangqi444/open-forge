---
name: mkvpriority-project
description: Tool that assigns configurable priority scores to MKV audio and subtitle tracks, automatically setting default/forced flags. Integrates with Radarr/Sonarr. Upstream: https://github.com/kennethsible/mkvpriority
---

# MKVPriority

Assigns configurable priority scores to audio and subtitle tracks in MKV files (similar to custom formats in Radarr/Sonarr) and automatically sets default/forced flags for the highest-priority tracks. Modifies track flags in-place using `mkvpropedit` — no remuxing. Upstream: <https://github.com/kennethsible/mkvpriority>.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker (one-shot) | [GitHub README](https://github.com/kennethsible/mkvpriority#docker-image) | ✅ | Scan a library once |
| Docker Compose (webhook) | [GitHub README](https://github.com/kennethsible/mkvpriority#radarrsonarr-integration) | ✅ | Persistent Radarr/Sonarr integration |
| pip / source | [GitHub](https://github.com/kennethsible/mkvpriority) | ✅ | Direct CLI use |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| preflight | "One-shot scan or persistent Radarr/Sonarr integration?" | options | All |
| config | Path to media directory | path | All |
| config | PUID / PGID | number | Docker |
| config | Sonarr/Radarr URL and API key (for original-language detection) | URL + string | Optional |

## Docker one-shot scan

Source: <https://github.com/kennethsible/mkvpriority>

```bash
docker run --rm \
  -u ${PUID}:${PGID} \
  -v /path/to/media:/media \
  -v /path/to/mkvpriority/config:/config \
  ghcr.io/kennethsible/mkvpriority /media \
  --archive /config/archive.db
```

Pre-create the config folder on the host before running — otherwise Docker creates it as root and Python will raise a `PermissionError`.

## Docker Compose (Radarr/Sonarr webhook)

```yaml
services:
  mkvpriority:
    image: ghcr.io/kennethsible/mkvpriority
    container_name: mkvpriority
    user: ${PUID}:${PGID}
    environment:
      WEBHOOK_PORT: '8080'
      MKVPRIORITY_ARGS: >
        --archive /config/archive.db
    volumes:
      - /path/to/media:/media
      - /path/to/mkvpriority/config:/config
    restart: unless-stopped
```

In Radarr/Sonarr: Settings → Connect → Add Connection → Custom Script → select `mkvpriority.sh`, enable "On File Import" and "On File Upgrade".

## Configuration

| Variable / Flag | Description |
|---|---|
| `--config /config/custom.toml` | Override default track priority config |
| `--archive /config/archive.db` | SQLite archive to avoid reprocessing files |
| `WEBHOOK_PORT` | Port for the Radarr/Sonarr webhook listener |
| `MKVPRIORITY_ARGS` | CLI arguments passed to the tool |
| `SONARR_URL` / `SONARR_API_KEY` | Enable original-language detection via Sonarr |
| `RADARR_URL` / `RADARR_API_KEY` | Enable original-language detection via Radarr |

Multiple tag-based configs are supported for e.g. a separate `anime` profile.

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

## Gotchas

- Pre-create the config folder as your target user before running the container.
- Container name must match the custom script unless updated in `mkvpriority.sh`.
- Media mount path must be identical in MKVPriority and Radarr/Sonarr containers.
- Each movie/show uses only the first tag in alphabetical order — create dedicated tags for MKVPriority to avoid conflicts.

## References

- GitHub: <https://github.com/kennethsible/mkvpriority>
