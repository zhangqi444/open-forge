---
name: Backrest
description: "Web UI wrapper around Restic — the mature, feature-rich alternative in the 'Restic with a GUI' category. Schedules, retention, encrypted repos, multi-backend (S3/B2/Azure/GCS/SFTP/rclone), restore browser, hook scripts, Prometheus metrics. Go. GPL-3.0."
---

# Backrest

Backrest is **a web UI + scheduler + orchestrator for [Restic](https://restic.net)** — the mature, actively-developed choice in the "Restic with a GUI" space. It embeds the Restic binary, manages multiple repositories + backup plans, provides a beautiful web interface for configuration + monitoring + restore, runs hook scripts on success/failure, exposes Prometheus metrics, and generally does for Restic what Cron + shell scripts always wanted to do.

Compared to **Zerobyte** (newer, pre-1.0 from nicotsx — see batch 65): Backrest is more mature, production-hardened, broader feature set. Both wrap Restic.

Features:

- **Web UI** — repository + plan management, schedules, history, live logs, browse/restore
- **Schedule types** — cron, intervals, "at most N per period," manual-only
- **Multi-repo + multi-plan** — many sources → many destinations as needed
- **Restic backends**: local, SFTP, REST Server, S3/Minio/R2, Backblaze B2, Azure Blob, Google Cloud Storage, Swift, rclone (which opens everything rclone supports)
- **Encryption + compression** — Restic native
- **Retention** — Restic's `forget --keep-*` semantics; UI-driven
- **Hooks** — run shell commands / HTTP webhooks / Discord/Slack/etc. notifications on each event (backup-start, backup-success, backup-fail, forget, prune, etc.)
- **Tag-based filtering** in UI
- **Live stats** (repo size, snapshot count, dedup savings)
- **Restore browser** — pick a snapshot, browse files, restore selected paths
- **Prometheus metrics**
- **Multi-user** (basic auth)
- **API** — REST + gRPC
- **Runs on Linux / macOS / Windows / Docker**

- Upstream repo: <https://github.com/garethgeorge/backrest>
- Docs: <https://garethgeorge.github.io/backrest/>
- Releases: <https://github.com/garethgeorge/backrest/releases>
- Docker Hub: <https://hub.docker.com/r/garethgeorge/backrest>
- Discord: <https://discord.gg/cukdRSh3UN>

## Architecture in one minute

- **Single Go binary** bundling the Restic CLI + UI + scheduler
- **Internal DB**: BoltDB (embedded)
- **Talks to Restic** as subprocess; parses output
- **Talks to rclone** optionally for mount + remote backends
- **Low resource**: ~100 MB RAM idle, CPU bursts during backup/prune

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                           |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------- |
| Single VM          | **Docker (`garethgeorge/backrest`)**                               | **Most common**                                                                     |
| Single VM          | Native binary (Linux/macOS/Windows)                                         | From releases page                                                                              |
| macOS              | `.pkg` installer + `launchd`                                                            | Native Mac backup workflows                                                                                   |
| Windows            | `.exe` installer                                                                                 | Runs as Windows service                                                                                                      |
| Synology / QNAP    | Docker                                                                                                    | Common NAS use case                                                                                                                      |
| Raspberry Pi       | arm64 Docker / binary                                                                                              | Works fine                                                                                                                                        |
| Kubernetes         | Community manifests                                                                                                            | Works; needs FUSE + privileged for rclone mounts                                                                                                                  |
| Managed            | — (no SaaS)                                                                                                                                |                                                                                                                                                                   |

## Inputs to collect

| Input                | Example                                 | Phase     | Notes                                                                         |
| -------------------- | --------------------------------------- | --------- | ----------------------------------------------------------------------------- |
| Source paths         | `/home`, `/data`                                | Plan      | What to back up                                                                       |
| Restic repo          | S3 URL / SFTP / local                             | Repo      | Destination                                                                                     |
| Repo password        | long random                                             | Security  | **SAVE OFFLINE** — lose it = lose backups                                                                  |
| Schedule             | cron `0 3 * * *`                                              | Plan      | Or interval / manual                                                                                                    |
| Retention            | e.g., keep 7d + 4w + 12m + 5y                                       | Plan      | `forget --keep-*`                                                                                                                    |
| Admin auth           | basic auth user/pass                                                         | Security  | Enable in config                                                                                                                                              |
| Hooks (opt)          | Discord webhook / shell script                                                         | Alerts    | Per-plan                                                                                                                                                                |

## Install via Docker

```yaml
services:
  backrest:
    image: garethgeorge/backrest:v1.13.0                # pin
    container_name: backrest
    hostname: backrest
    restart: unless-stopped
    ports:
      - "127.0.0.1:9898:9898"                             # bind localhost; reverse-proxy for TLS + auth
    environment:
      BACKREST_PORT: 0.0.0.0:9898
      BACKREST_CONFIG: /config/config.json
      BACKREST_DATA: /data
      XDG_CACHE_HOME: /cache
      TZ: America/Los_Angeles
    volumes:
      - ./config:/config
      - ./data:/data
      - ./cache:/cache
      - /mnt/source:/mnt/source:ro                         # source to back up, read-only
      - /mnt/backup:/mnt/backup                            # local-repo destination (if used)
```

Browse `http://<host>:9898/`.

## First boot

1. First-visit → set instance ID + admin creds
2. **Add Repository** → pick backend (local / S3 / SFTP / B2) → enter URL + creds + **repo password**
3. **Add Plan** → paths + schedule + retention + hooks + tags
4. **Run Now** → observe log; verify snapshot appears
5. Try restore: pick a snapshot → browse files → restore to `/tmp/test` → diff
6. Configure Discord/email hook for failure alerts
7. Enable Prometheus scrape if you run Grafana

## Data & config layout

- `/config/config.json` — plans, repos, hooks, auth
- `/data/` — BoltDB (operation log, snapshot cache)
- `/cache/` — Restic caches (speeds up repeated ops)
- Restic repos live at destination (S3/SFTP/etc.)

## Backup (meta)

```sh
# Stop for consistent BoltDB snapshot
docker compose stop backrest
tar czf backrest-$(date +%F).tgz config/ data/
docker compose start backrest
```

And store **Restic repo password offline**. Repeat: **offline.**

## Upgrade

1. Releases: <https://github.com/garethgeorge/backrest/releases>. Very active.
2. Back up config + data.
3. Docker: bump tag; migrations auto.
4. Watch release notes for config schema bumps.

## Gotchas

- **Restic repo password is the kingdom key.** Same as Databasus + Zerobyte precedents — lose it, lose every snapshot. Multi-location offline backup (password manager, paper, safety deposit). **Write this in stone.**
- **Test restores quarterly.** Every backup recipe says this because it keeps being true. Schedule a drill. Document restore steps. Backups you haven't restored are wishful thinking.
- **Don't expose Backrest publicly**: bind to `127.0.0.1` + reverse-proxy with TLS + auth. UI has all your backup creds + encryption keys.
- **Mount sources read-only.** Backrest only reads; `:ro` prevents accidents.
- **Rclone mounts**: if using rclone backends, Backrest needs `/dev/fuse` + elevated caps. Some Docker-hardened setups disallow this.
- **Backup frequency vs retention math**: hourly × 168 weekly snapshots = 168 snapshots held; plus weekly/monthly/yearly = ~200. Understand `forget` semantics before setting aggressive retention.
- **Pruning is disk-intensive**: deep prune operations can take hours on large repos. Schedule in low-traffic windows.
- **Concurrency limits**: Restic doesn't play well with concurrent backups to same repo. Backrest serializes per-repo; but if you manually run `restic backup` simultaneously, locking issues.
- **Network sources**: backing up over SMB/NFS adds latency + can flake. Consider local agents on source machines forwarding to a central repo instead.
- **Large file handling**: Restic chunks files; large files are efficient on incremental. First full backup of multi-TB library is long.
- **Dedup savings**: shared blocks across snapshots. Expect 50-80% dedup on typical data.
- **Hook scripts** — can run arbitrary shell. Useful for "notify-before-sleep" / "wake-NAS-before-backup" flows. Lock down who can edit hooks (admin only).
- **Discord / Slack / Shoutrrr hooks**: built-in; lighter than an external notifier service.
- **Prometheus metrics**: scrape `/v1/health/metrics` (check current path) → Grafana dashboard → alert on backup failure.
- **Multi-plan, multi-repo pattern**: typical setup is 3-2-1 rule — 3 copies / 2 media types / 1 offsite. Backrest supports multi-destination by creating multiple plans with different repos.
- **Docker volume gotcha**: container paths differ from host paths in UI. Remember the `/mnt/source:/mnt/source:ro` mapping.
- **License**: **GPL-3.0**.
- **Alternatives worth knowing:**
  - **Zerobyte** — newer alternative; UI-polished but pre-1.0 (see batch 65 recipe)
  - **Restic + cron** — the original; zero UI
  - **Raw Restic GUI** — none official
  - **Duplicati** — older cross-platform web UI backup tool
  - **Borgbackup + borgmatic** — Borg-based equivalent
  - **Kopia** — own engine (not Restic); native UI
  - **Synology Hyper Backup** / **QNAP HBS** — NAS-vendor commercial
  - **Veeam Community Edition** — Windows-focused; limited free features
  - **Tailscale + Restic REST server** — good pattern for cross-location repos
  - **Choose Backrest if:** you want a mature, production-ready Restic UI with broad features.
  - **Choose Zerobyte if:** you like the UX + OK with pre-1.0.
  - **Choose raw Restic if:** you prefer CLI + cron + scripting.
  - **Choose Kopia if:** you want a native modern backup tool (not Restic-wrapping).

## Links

- Repo: <https://github.com/garethgeorge/backrest>
- Docs: <https://garethgeorge.github.io/backrest/>
- Install guide: <https://garethgeorge.github.io/backrest/install.html>
- Docker Hub: <https://hub.docker.com/r/garethgeorge/backrest>
- Releases: <https://github.com/garethgeorge/backrest/releases>
- Discord: <https://discord.gg/cukdRSh3UN>
- Restic (underlying engine): <https://restic.net>
- Restic backends: <https://restic.readthedocs.io/en/stable/030_preparing_a_new_repo.html>
- Zerobyte (alt): <https://github.com/nicotsx/zerobyte>
- Duplicati (alt): <https://duplicati.com>
- Kopia (alt): <https://kopia.io>
- Borgbackup (alt): <https://www.borgbackup.org>
- Restic REST server (self-hosted backend): <https://github.com/restic/rest-server>
