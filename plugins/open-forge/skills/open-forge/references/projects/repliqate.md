---
name: repliqate
description: Recipe for Repliqate — modular Docker backup solution using container/volume labels. Auto-manages container states during backups, supports cron scheduling and retention policies. Single Docker container, no external DB.
---

# Repliqate

Modular backup solution for Docker environments. Upstream: https://github.com/lminlone/repliqate

Label-based backup orchestrator: configure backups by adding Docker labels to your containers/volumes. Repliqate automatically stops/starts containers during backup to ensure data consistency, supports both simple schedules (`@daily 3am`) and full cron expressions, and enforces retention policies. MIT licensed.

Full documentation: https://lminlone.github.io/repliqate/

## Compatible combos

| Runtime | Notes |
|---|---|
| Docker Compose | Recommended — runs alongside your other services |
| Docker run | Supported |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | Backup destination path | Host path where backups will be stored (mounted to /var/repliqate) |
| per-service | Schedule | e.g. @daily 3am or a cron expression |
| per-service | Backup ID | Unique identifier for each backup target |
| per-service | Retention period | e.g. 30d — how long to keep backups |

## Software-layer concerns

**How it works:** Repliqate runs as a container with access to the Docker socket and the Docker volumes directory. It reads labels from other containers to know what to back up, when, and how long to keep backups.

**Required mounts:**
- `/var/run/docker.sock` — Docker API access (reads container labels, stops/starts containers)
- `/path/to/backups:/var/repliqate` — where backup archives are written
- `/var/lib/docker/volumes:/var/lib/docker/volumes` — access to Docker named volumes

**Label configuration on backup targets:**
| Label | Description |
|---|---|
| `repliqate.enabled: 'true'` | Enable backup for this container |
| `repliqate.schedule: "@daily 3am"` | When to run the backup |
| `repliqate.backup_id: my_app_01` | Unique name for this backup |
| `repliqate.retention: "30d"` | How long to keep backup files |

**No persistent config file** — all config is in Docker labels. Adding/removing/changing labels takes effect on the next schedule cycle.

## Docker Compose

Repliqate container:
```yaml
services:
  repliqate:
    image: lminlone/repliqate
    container_name: repliqate
    restart: unless-stopped
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - /path/to/backups:/var/repliqate
      - /var/lib/docker/volumes:/var/lib/docker/volumes
```

Target container (add labels to any service you want backed up):
```yaml
services:
  myapp:
    image: my-app:latest
    labels:
      repliqate.enabled: 'true'
      repliqate.schedule: "@daily 3am"
      repliqate.backup_id: myapp_01
      repliqate.retention: "30d"
    volumes:
      - myapp_data:/data

volumes:
  myapp_data:
```

## Upgrade procedure

```bash
docker compose pull repliqate
docker compose up -d repliqate
```

Backup archives in /var/repliqate are unaffected. No database to migrate.

## Gotchas

- **Docker socket access** — Repliqate needs `/var/run/docker.sock` to stop/start containers. This grants significant host access; run only on trusted infrastructure.
- **Volume path must match** — `/var/lib/docker/volumes` is the default Docker volumes path on Linux; it may differ on non-standard Docker installations (e.g. rootless Docker, Docker Desktop).
- **Container shutdown during backup** — Repliqate stops the target container to ensure consistency. Plan schedules for low-traffic windows.
- **Backup destination is local** — Repliqate writes to the mounted /var/repliqate path. For offsite backup, combine with rclone, rsync, or similar to sync to remote storage.

## Links

- Upstream repository: https://github.com/lminlone/repliqate
- Full documentation: https://lminlone.github.io/repliqate/
- Docker Hub: https://hub.docker.com/r/lminlone/repliqate
