# GoCron

**What it is:** Self-hosted task scheduler with a web UI. Define recurring jobs via a YAML config file using cron expressions, with per-job environment variables and sequential commands. Built with Go and Vue.js. Includes a built-in terminal (with allowlist), job run history, dark/light mode UI, API, and optional pre-installed backup tools (restic, borgbackup, rclone, etc.).

**GitHub:** https://github.com/flohoss/gocron  
**Docker image:** `ghcr.io/flohoss/gocron:latest`

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS/VM | Docker Compose | Recommended; single container |
| Bare metal | Binary | Go binary |

---

## Inputs to Collect

### Phase: Deploy

| Item | Description |
|------|-------------|
| `config/config.yaml` | Main config — jobs, timezone, software, terminal settings |
| Host port | Default `8156` |

---

## Software-Layer Concerns

- **All configuration is YAML-based** — edit `config.yaml` and restart to apply; no web UI config editor
- **Config directory** at `./config/` → `/app/config/` — mount this volume
- **Job run history** stored in SQLite; configurable retention (`delete_runs_after_days`, default 7 days, `0` = never delete)
- **Pre-installed software packages** — specify in `config.yaml`; installed at container build/start time. Available: `apprise`, `borgbackup`, `docker`, `git`, `podman`, `rclone`, `rdiff-backup`, `restic`, `rsync`, `logrotate`, `sqlite3`, `kopia`. Recreate container after changing software list.
- **Terminal** — built-in terminal with command allowlist; `allow_all_commands: false` by default for safety
- **Healthcheck** — configurable endpoint with auth header

### YAML config structure

```yaml
time_zone: 'America/New_York'
log_level: 'info'           # debug, info, warn, error, off
delete_runs_after_days: 7

software:
  - name: 'restic'
  - name: 'rclone'

terminal:
  allow_all_commands: false
  allowed_commands:
    docker:
      args: [ps, version]

server:
  address: '0.0.0.0'
  port: 8156

jobs:
  defaults:
    cron: '0 2 * * *'   # 2 AM daily
  items:
    - name: 'backup'
      cron: '0 3 * * *'
      environment:
        RESTIC_REPOSITORY: /backups/myrepo
        RESTIC_PASSWORD: mysecret
      commands:
        - restic backup /data
        - restic forget --keep-daily 7 --prune
```

---

## Example Docker Compose

```yaml
services:
  gocron:
    image: ghcr.io/flohoss/gocron:latest
    restart: always
    container_name: gocron
    hostname: gocron
    volumes:
      - ./config/:/app/config/
    ports:
      - '8156:8156'
```

---

## Upgrade Procedure

1. Pull new image: `docker compose pull`
2. Restart: `docker compose up -d`
3. If software packages changed in config, recreate the container: `docker compose up -d --force-recreate`

---

## Gotchas

- **Config changes require restart** — no hot-reload
- **Software package changes require container recreation** — `docker compose up -d` alone won't reinstall packages; use `--force-recreate`
- **Terminal allowlist is critical for security** — `allow_all_commands: true` grants arbitrary command execution to anyone with web UI access; keep it off unless behind strong auth
- No built-in authentication on the web UI — restrict access via reverse proxy auth (Authelia, Caddy basic auth)
- `apprise` version format differs from apt packages — use plain version like `1.2.0` (installed via pipx)

---

## Links

- GitHub: https://github.com/flohoss/gocron
- Docker image: https://github.com/flohoss/gocron/pkgs/container/gocron
