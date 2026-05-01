---
name: qBit Manage
description: "Python tool to manage qBittorrent — auto-tag, categorize, remove orphaned files, share limits, RecycleBin, scheduler. Docker. StuffAnThings/qbit_manage."
---

# qBit Manage

**Automation tool to manage your qBittorrent instance.** Runs on a schedule (or on-demand) and performs a configurable set of maintenance tasks: tag torrents by tracker URL, apply categories by save path, remove unregistered torrents, recheck + resume paused torrents, remove orphaned files, enforce share limits + cleanup, RecycleBin for safe deletion, and webhook notifications.

Built + maintained by **StuffAnThings / bobokun**. Supported on Notifiarr Discord `#qbit-manage` channel.

- Upstream repo: <https://github.com/StuffAnThings/qbit_manage>
- Wiki (full docs): <https://github.com/StuffAnThings/qbit_manage/wiki>
- Docker Hub: <https://hub.docker.com/r/bobokun/qbit_manage>
- GHCR: `ghcr.io/stuffanthings/qbit_manage`
- Discord: <https://discord.com/invite/AURf8Yz> (Notifiarr Discord → `#qbit-manage`)
- PyPI: <https://pypi.org/project/qbit-manage>
- Unraid Community App: available

## Architecture in one minute

- **Python 3.9+** script / daemon
- Connects to qBittorrent Web API (no direct file access required — except for orphaned files cleanup)
- Config via **`config.yml`** (YAML)
- Runs on schedule (built-in scheduler, configurable interval) or via `--run` for one-shot
- Docker image: `bobokun/qbit_manage` (Docker Hub) or `ghcr.io/stuffanthings/qbit_manage` (GHCR)
- Resource: **tiny** — Python process that wakes periodically

## Compatible install methods

| Infra          | Runtime                       | Notes                                                      |
| -------------- | ----------------------------- | ---------------------------------------------------------- |
| **Docker**     | `bobokun/qbit_manage`         | **Recommended** — Docker Hub + GHCR                        |
| **Python**     | `pip install qbit-manage`     | Local install; Python 3.9+ required                        |
| **Unraid**     | Community App                 | Available in Unraid CA                                     |

## Inputs to collect

| Input                             | Example                          | Phase    | Notes                                                                             |
| --------------------------------- | -------------------------------- | -------- | --------------------------------------------------------------------------------- |
| qBittorrent WebUI URL + creds     | `http://qbittorrent:8080`        | Config   | In `config.yml` → `qbt:` section                                                 |
| Download root dir                 | `/downloads`                     | Storage  | Mount same path as qBittorrent uses — required for orphaned file detection        |
| Config + log dirs                 | `./qbm-config`, `./qbm-logs`     | Storage  | Mount into container                                                              |
| Schedule interval                 | `30` (minutes)                   | Config   | `--schedule 30` or configured in compose                                         |
| Notifiarr / Apprise (optional)    | API key                          | Notify   | For webhook notifications on actions taken                                        |

## Install via Docker Compose

```yaml
services:
  qbit-manage:
    image: bobokun/qbit_manage:latest
    container_name: qbit-manage
    volumes:
      - ./qbm-config:/config         # config.yml lives here
      - ./qbm-logs:/logs
      - /path/to/downloads:/data     # must match qBittorrent's download path
    environment:
      - QBT_SCHEDULE=30              # run every 30 minutes
      - QBT_CONFIG=config.yml        # config file name
      - QBT_LOG_LEVEL=INFO
    restart: unless-stopped
```

> **Path matching is critical.** qBit Manage must see files at the same path as qBittorrent does (or a correctly-mapped equivalent). If qBittorrent saves to `/downloads` and qBit Manage mounts it as `/data`, you must configure `root_dir` in `config.yml` accordingly.

## Configuration

Create `config/config.yml` from the sample: <https://github.com/StuffAnThings/qbit_manage/blob/master/config/config.yml.sample>

Key sections:

```yaml
qbt:
  host: "qbittorrent:8080"
  user: "admin"
  pass: "adminadmin"
  
directory:
  root_dir: /data                # root of download directories (inside container)
  recycle_bin: /data/.RecycleBin # where deleted files go

cat:                             # category → save_path mapping
  movies: /data/movies
  tv: /data/tv

tracker:                         # tracker URL → tag mapping
  - url: "tracker.example.com"
    tag: "example-tracker"
    
share_limits:                    # cleanup rules per tag/category group
  - name: "cleanup-seeded"
    max_ratio: 2.0
    max_seeding_time: 10080      # minutes (7 days)
    cleanup: true
```

Full config reference: <https://github.com/StuffAnThings/qbit_manage/wiki/Config-Setup>

## Commands / features

| Feature | What it does |
|---------|-------------|
| **Tag by tracker** | Reads tracker URLs of each torrent; applies matching tag |
| **Category by path** | Assigns category to uncategorized torrents based on save path |
| **Cat change** | Changes category based on current category rules |
| **Remove unregistered** | Deletes torrents the tracker no longer recognizes (with cross-seed awareness) |
| **Recheck + resume** | Rechecks paused torrents by size (smallest first); resumes completed |
| **Orphaned files** | Finds files in download dir not referenced by any torrent; optional delete |
| **Hard link tags** | Tags torrents with no hard links outside root (useful for single-copy detection) |
| **Share limits** | Per-tag/category ratio + seed time enforcement; optional cleanup |
| **RecycleBin** | Moves deleted torrent files to RecycleBin instead of permanent delete |
| **Scheduler** | Runs all configured tasks every N minutes |
| **Notifications** | Notifiarr + Apprise API webhook integrations |

## Backup

Config is the only stateful piece:

```sh
sudo cp -a qbm-config/ qbm-config-backup-$(date +%F)/
```

## Upgrade

```sh
docker compose pull && docker compose up -d
```

## Gotchas

- **qBittorrent version compatibility lag.** New qBittorrent releases may not be immediately supported — qBit Manage depends on `qbittorrent-api` Python library, which must add support first. Check `SUPPORTED_VERSIONS.json` in the repo for your qBittorrent version before upgrading qBittorrent.
- **Path mapping must be exact.** If qBittorrent and qBit Manage run in separate containers with different volume mounts, set `root_dir` + `remote_dir` in config to translate paths. Getting this wrong causes orphaned-file detection to either miss files or falsely delete legitimate ones.
- **RecycleBin is not infinite.** Configure `RecycleBin.empty_after_x_days` to avoid disk fill. Default retains files indefinitely.
- **`cleanup: true` in share limits permanently deletes torrent + data** (or moves to RecycleBin if configured). Test with `--dry-run` first.
- **`--dry-run` flag.** Always test configuration changes with `--run --dry-run` before enabling the scheduler. qBit Manage will log what it *would* do without making changes.
- **Cross-seed awareness.** When removing unregistered torrents, qBit Manage checks if the same data is used by another torrent (via hard links). If it is, it removes only the torrent, not the data. If it isn't, it removes both. Understand this before enabling removal.
- **Develop branch is ahead of master.** Active feature development happens on `develop`. Docker tag `:develop` tracks it. Use `:latest` or a pinned semver for stable deploys.
- **Notifiarr Discord is the support channel.** Not GitHub Issues for questions — post in `#qbit-manage` on Notifiarr Discord.

## Project health

Active Python development, Docker Hub + GHCR, CI, PyPI, Unraid CA, Notifiarr Discord community, GitHub Sponsors. Maintained by bobokun / StuffAnThings.

## qBittorrent-automation-family comparison

- **qBit Manage** — Python, full maintenance suite (tags/cats/share limits/orphans/RecycleBin/scheduler)
- **autobrr** — Go, IRC/RSS-based auto-downloading; not post-download management
- **cross-seed** — JS, cross-seeding automation; complementary to qBit Manage
- **Sonarr/Radarr** — download orchestrators (search + grab + rename); qBit Manage is post-download maintenance

**Choose qBit Manage if:** you want automated maintenance of an existing qBittorrent instance — tagging, categorizing, share-limit enforcement, and orphaned-file cleanup — without manually babysitting it.

## Links

- Repo: <https://github.com/StuffAnThings/qbit_manage>
- Wiki: <https://github.com/StuffAnThings/qbit_manage/wiki>
- Config sample: <https://github.com/StuffAnThings/qbit_manage/blob/master/config/config.yml.sample>
- Docker Hub: <https://hub.docker.com/r/bobokun/qbit_manage>
- Discord support: <https://discord.com/invite/AURf8Yz> (`#qbit-manage`)
