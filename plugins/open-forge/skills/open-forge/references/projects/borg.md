---
name: BorgBackup
description: Deduplicating, compressing, encrypting CLI backup tool. Chunks source files, hashes chunks, stores only unique chunks in a repository. Works over SSH to a remote Borg server, or to a local filesystem. BSD-3-Clause.
---

# BorgBackup

Borg is **the** workhorse for Linux backups. It takes a source directory, breaks it into content-defined chunks, deduplicates them (so the same file across multiple machines, or 1000 daily snapshots of the same `/home`, costs only one copy on disk), compresses, encrypts client-side with AES-CTR + HMAC-SHA256, and stores to:

- **Local filesystem** (USB disk, NAS mount)
- **Remote Borg server over SSH** (a VPS you own, or a commercial provider)
- **Mounted remote via rclone/FUSE** (not ideal — breaks locking)

Tiny backups (incremental = only changed chunks), strong crypto, time-proven (in use since 2010; fork of Attic). The canonical Linux workstation / server backup tool.

Not a UI tool. If you want a GUI, use **Vorta** (Qt, Linux/macOS) on top of Borg; for web-based dashboards, use **Borgmatic** as a scheduler + **Borg Web UI / borg-web**.

Recommended provider for offsite: **BorgBase** (commercial) or **Hetzner Storage Box** (cheap SSH-accessible) or **rsync.net** (Borg-native plans).

- Upstream repo: <https://github.com/borgbackup/borg>
- Docs: <https://borgbackup.readthedocs.io>
- Quickstart: <https://borgbackup.readthedocs.io/en/stable/quickstart.html>
- Security: <https://borgbackup.readthedocs.io/en/stable/internals/security.html>

## Borg 1.x vs 2.x

Front-loaded context:

- **Borg 1.x** (stable, widely deployed) — what every tutorial and distro package ships
- **Borg 2.x** (beta, as of 2025-2026) — rewrite with a new repository format, better crypto, better performance; **incompatible with 1.x repos**

Stick with 1.x for production unless you have a specific reason to move. 2.x is promising but still stabilizing; repos aren't cross-compatible.

## Architecture in one minute

- **Client**: `borg` CLI (Python package, shipped on nearly every distro)
- **Repository**: a directory on local disk OR on a remote host (SSH'd into, running `borg serve`)
- **Encryption key**: per-repository; stored client-side in `~/.config/borg/keys/`
- **Chunks**: content-defined, ~1-8 MB; deduplicated across all archives in the repo

A single repo holds many "archives" (snapshots). Each archive is a backup run.

## Compatible install methods

| Infra       | Runtime                                              | Notes                                                                      |
| ----------- | ---------------------------------------------------- | -------------------------------------------------------------------------- |
| Any Linux   | Distro package (`apt install borgbackup`)            | **Simplest**; Borg 1.2+                                                     |
| Any Linux   | `pipx install borgbackup` or standalone binary       | For latest version                                                          |
| macOS       | `brew install borgbackup`                            |                                                                            |
| Container   | `ghcr.io/borgmatic-collective/borgmatic`             | With borgmatic scheduler                                                    |
| Remote repo | Hetzner Storage Box / BorgBase / rsync.net / own VPS | Over SSH                                                                    |
| Windows     | WSL2 (Borg doesn't run natively on Windows)          |                                                                            |

## Inputs to collect

| Input                         | Example                                    | Phase     | Notes                                                                  |
| ----------------------------- | ------------------------------------------ | --------- | ---------------------------------------------------------------------- |
| Backup source                 | `/home`, `/etc`, `/var/lib/postgresql`     | Config    | List of dirs to include                                                 |
| Repository location           | `/mnt/backup/borg` or `ssh://user@host/./repo` | Config | Local path OR SSH URL                                                   |
| Encryption mode               | `repokey-blake2` (recommended)             | Security  | Keeps key in repo, encrypted with passphrase; vs `keyfile` (local-only)  |
| Passphrase                    | `openssl rand -base64 32`                  | Security  | **Losing = losing your backups forever**                                  |
| Retention policy              | `--keep-daily 7 --keep-weekly 4 --keep-monthly 12 --keep-yearly 3` | Config | Prune schedule                                               |
| Schedule                      | systemd timer / cron / borgmatic           | Ops       | Daily minimum; more frequent for active servers                           |
| SSH key for remote repo       | per source host                            | Network   | Add public key to remote Borg server's `authorized_keys` with restrictions |

## Install + first backup

### Install

```sh
# Debian / Ubuntu / Fedora — distro package
sudo apt install borgbackup
# OR latest from PyPI
pipx install borgbackup
```

### Initialize a repository

```sh
# Local repo
borg init --encryption=repokey-blake2 /mnt/backup/borg-repo
# Prompts for passphrase. Store it in a password manager.

# Remote repo (SSH)
borg init --encryption=repokey-blake2 ssh://borg@backup.example.com:2222/./repo
```

### First backup

```sh
export BORG_REPO=/mnt/backup/borg-repo
export BORG_PASSPHRASE='your-passphrase-here'

borg create --stats --compression zstd,6 \
  ::"$(hostname)-$(date +%Y-%m-%d_%H%M%S)" \
  /home /etc /var/lib/postgresql/data \
  --exclude '/home/*/.cache' \
  --exclude '/home/*/Downloads' \
  --exclude '*.iso'
```

The `::name` syntax = archive name within `$BORG_REPO`.

### Prune old snapshots

```sh
borg prune --list \
  --keep-daily 7 --keep-weekly 4 --keep-monthly 12 \
  $BORG_REPO
borg compact $BORG_REPO    # actually reclaim space (Borg 1.2+)
```

### Restore

```sh
# List archives
borg list $BORG_REPO

# Mount an archive as FUSE
mkdir /mnt/restore
borg mount "$BORG_REPO::my-hostname-2026-04-30" /mnt/restore
# Browse + copy
umount /mnt/restore

# Or extract
cd /restore-to
borg extract "$BORG_REPO::my-hostname-2026-04-30"
```

## Automation with borgmatic (recommended)

Borgmatic is a YAML-configured wrapper that handles the init/create/prune/check cycle. Reference: <https://torsion.org/borgmatic/>.

```yaml
# /etc/borgmatic/config.yaml
source_directories:
  - /home
  - /etc
  - /var/lib/postgresql

repositories:
  - path: ssh://borg@backup.example.com/./repo
    label: offsite

exclude_patterns:
  - /home/*/.cache

archive_name_format: '{hostname}-{now}'

keep_daily: 7
keep_weekly: 4
keep_monthly: 12
keep_yearly: 3

# Run DB dump BEFORE borg create
postgresql_databases:
  - name: all
    hostname: localhost

checks:
  - name: repository
    frequency: 2 weeks
  - name: archives
    frequency: 4 weeks
```

Then a systemd timer runs `borgmatic` once a day. Handles create + prune + compact + check + DB dumps atomically.

## Data layout (repository internals)

Inside a Borg repo (you should NEVER edit these files directly):

- `data/` — chunk store (binary blobs organized in segments)
- `index.N` — chunk index
- `hints.N` — segment metadata
- `config` — repo config (encryption mode, chunker params)
- `README` — warning to not touch

## Backup the backups

Borg repos themselves: use `rclone sync` or `rsync` to copy the whole repo dir to a second cold storage. Repos are self-contained and can be copied.

**Encryption key**: if you use `repokey`, the key lives in the repo's `config` (encrypted by passphrase). If you use `keyfile`, back up `~/.config/borg/keys/` SEPARATELY + the passphrase.

## Upgrade

1. Releases: <https://github.com/borgbackup/borg/releases>.
2. Distro package: `apt upgrade borgbackup`. Usually safe within 1.x.
3. **Borg 1.2 → 1.4**: repo format is compatible; new features (parallelism, `borg compact`).
4. **Borg 1.x → 2.x**: repo format is **incompatible**; 2.x introduces a new repo layout with better crypto. Migration tool available: `borg transfer`. Plan carefully.
5. Keep client + server (`borg serve` on remote) versions aligned or within 1 minor version.

## Gotchas

- **Lost passphrase = lost backups.** Store in a password manager + a second physical location. Borg cannot recover from this.
- **Lost keyfile (in `keyfile` mode) = lost backups.** Back up `~/.config/borg/keys/` to a second location.
- **Repo encryption modes:**
  - `repokey-blake2` (recommended 1.x) — key in repo, encrypted with passphrase; passphrase loss = game over
  - `keyfile-blake2` — key on client only; loss of both key + passphrase = game over, but repo alone ≠ readable
  - `none` — no encryption; only use for local backups on an already-encrypted disk
- **Single-writer locking.** Only ONE `borg` process can write to a repo at a time. Parallel backups from 10 laptops to the same repo will serialize.
- **Check periodically.** `borg check --verify-data` catches bit rot. It's slow (downloads every chunk); run monthly on archives + weekly on repo.
- **Cache corruption recovery.** If client machine is rebuilt, delete `~/.cache/borg/` and let Borg rebuild from the repo (slower first backup afterward).
- **`borg compact`** is required in 1.2+ to actually reclaim disk after prune. `prune` only deletes archive entries; chunks freed are reclaimed on `compact`.
- **Dedup across clients** works only if they share a repo AND have the same encryption key. Typically you create one repo per-client-group.
- **Default chunker params** (CHUNK_MIN_EXP=19, CHUNK_MAX_EXP=23) suit general files. VM images / large binaries may benefit from different chunker params, set at init time (can't change later without re-creating repo).
- **Compression**: `zstd,6` is a good default balance. `lzma,9` for small backups; `none` for already-compressed sources.
- **`--exclude-from` file** to keep patterns version-controlled.
- **Database backups**: dump DB to a stable file BEFORE `borg create`; never back up live DB data files (Postgres/MySQL).
- **Remote `borg serve` hardening**: restrict via `~/.ssh/authorized_keys` with `command="borg serve --restrict-to-repository /home/borg/repo"` and `no-pty,no-port-forwarding,no-X11-forwarding`.
- **Append-only mode** (`--append-only` in `borg serve`): ransomware-resistant — client can't delete archives. Prune separately from a trusted admin host.
- **1.x vs 2.x repos not compatible.** No in-place upgrade; use `borg transfer` (requires 2.x installed).
- **Retention `--keep-within=3d`** keeps everything within the last 3 days; combine with `--keep-daily/weekly/monthly/yearly` for a proper retention pyramid.
- **Speed**: limited by chunking + hash throughput. Typical 50-200 MB/s to local SSD; 5-30 MB/s over DSL uplink.
- **No concurrent reads** during a prune or compact. Schedule accordingly.
- **Vorta** (GUI) / **Borgmatic** (scheduler) are essential for non-experts.
- **Borg2 status**: 2.0.0b18 as of late 2025. Not production-recommended yet.
- **License**: BSD-3-Clause. No copyleft.
- **Alternatives worth knowing:**
  - **restic** — similar concept, single binary, supports many cloud backends natively (S3, B2, Azure, GCS)
  - **Kopia** — newer, has a web UI + native cloud backends (separate recipe)
  - **Duplicacy** — lock-free, commercial licensing
  - **rclone** — for simple sync, not dedup
  - **rsnapshot** — rsync + hardlinks, no dedup across hosts

## Links

- Repo: <https://github.com/borgbackup/borg>
- Docs: <https://borgbackup.readthedocs.io>
- Quickstart: <https://borgbackup.readthedocs.io/en/stable/quickstart.html>
- Deployment: <https://borgbackup.readthedocs.io/en/stable/deployment/index.html>
- FAQ: <https://borgbackup.readthedocs.io/en/stable/faq.html>
- Security: <https://borgbackup.readthedocs.io/en/stable/internals/security.html>
- Releases: <https://github.com/borgbackup/borg/releases>
- Vorta (GUI): <https://github.com/borgbase/vorta>
- Borgmatic: <https://torsion.org/borgmatic/>
- BorgBase (hosted repo): <https://www.borgbase.com>
- Hetzner Storage Box: <https://www.hetzner.com/storage/storage-box>
- rsync.net: <https://www.rsync.net/products/borg.html>
