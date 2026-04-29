---
name: restic-project
description: restic recipe for open-forge. BSD-2-Clause fast, secure, efficient backup program — deduplicated, encrypted, incremental backups to many backends (local dir, SFTP, REST server, S3, Backblaze B2, Azure, GCS, or anything rclone supports). Single Go binary CLI — NOT a daemon, NOT a web UI. Covers binary install, repo init, first backup, scheduled backups via cron/systemd, REST-server backend for self-hosted central-backup server, and the critical "back up your repo password or lose everything" lesson. This is the gold-standard FOSS backup tool.
---

# restic

BSD-2-Clause fast, secure, efficient, deduplicated, encrypted backup CLI. Upstream: <https://github.com/restic/restic>. Docs: <https://restic.readthedocs.io>. Forum: <https://forum.restic.net>.

Not a server. Not a web app. Just a single Go binary you run from a shell or cron — the industry standard open-source backup tool. Often paired with a **REST server** (`restic/rest-server`) when you want a centralized backup endpoint for many clients.

## Features

- **Deduplication** (content-defined chunking) — a file present in 10 snapshots costs disk for 1 copy.
- **Encryption** (AES-256-CTR + Poly1305) — repos are encrypted at rest; the server never sees plaintext.
- **Incremental** — only new / changed chunks are uploaded per backup.
- **Cross-platform** — Linux, macOS, Windows, BSDs.
- **Snapshot mount** (`restic mount`) — browse any snapshot via FUSE like a filesystem.
- **Verification** (`restic check`) — integrity + consistency of the repository.
- **Pruning / retention policies** (`restic forget` + `restic prune`) — e.g. "keep 7 daily, 4 weekly, 12 monthly."
- **Many backends** — see below.

## Supported backends (native)

- Local directory (good for initial testing)
- SFTP (backup to any SSH-accessible server)
- **REST server** (`restic/rest-server`) — HTTP(S) backend you self-host. Most common self-host pattern.
- Amazon S3 + S3-compatible (MinIO, Wasabi, Backblaze B2 S3, etc.)
- Backblaze B2 native API
- Microsoft Azure Blob Storage
- Google Cloud Storage
- OpenStack Swift
- Anything rclone supports via the rclone backend (Dropbox, Google Drive, OneDrive, pCloud, SFTP, WebDAV, hundreds more)

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Precompiled binary | <https://github.com/restic/restic/releases/latest> | ✅ Recommended | Any OS. Drop into `/usr/local/bin/` and done. |
| Distro package (`apt`, `dnf`, `pacman`, `brew`) | Various | Mixed | Fine but often outdated — check the packaged version vs. latest release. |
| `restic self-update` | Built-in | ✅ | After first install, run `sudo restic self-update` to always get latest. |
| Docker image (`restic/restic`) | Docker Hub | ✅ | Running inside containers, or to avoid a host install. |
| Build from source (Go) | `go install github.com/restic/restic/cmd/restic@latest` | ✅ | Custom builds. |
| REST server (for centralized backups) | <https://github.com/restic/rest-server> | ✅ | Self-host a backup destination for many clients. |

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Install method?" | `AskUserQuestion`: `binary` / `distro-pkg` / `docker` | Drives section. |
| backend | "Backup destination?" | `AskUserQuestion`: `local-dir` / `sftp` / `rest-server` / `s3` / `b2` / `azure` / `gcs` / `rclone-*` | Sets `RESTIC_REPOSITORY`. |
| backend | "Backend credentials?" | Free-text (sensitive) | Per-backend env vars (see below). |
| repo | "Repository password?" | Free-text (sensitive) | **`RESTIC_PASSWORD`** — **losing this = losing all backups** (encrypted, no recovery). Print + store offline. |
| source | "What paths to back up?" | List | `/home`, `/etc`, `/var/lib/docker/volumes`, specific project dirs, etc. |
| source | "Excludes?" | List | `/proc`, `/sys`, `/dev`, `node_modules`, `.cache`, tmp files, etc. Use `--exclude-file`. |
| schedule | "Frequency?" | `AskUserQuestion`: `hourly` / `6h` / `daily` / `custom-cron` | Drives cron / systemd timer. |
| retention | "Retention policy?" | Free-text, e.g. `--keep-daily 7 --keep-weekly 4 --keep-monthly 12 --keep-yearly 3` | Controls `restic forget` + `restic prune`. |

## Install — binary

```bash
# 1. Grab the right binary for your arch
VERSION=$(curl -s https://api.github.com/repos/restic/restic/releases/latest | grep tag_name | cut -d'"' -f4 | sed 's/^v//')
ARCH=$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/')
curl -L -o /tmp/restic.bz2 "https://github.com/restic/restic/releases/download/v${VERSION}/restic_${VERSION}_linux_${ARCH}.bz2"
bunzip2 /tmp/restic.bz2
sudo install -m 0755 /tmp/restic /usr/local/bin/restic
restic version

# 2. Set up bash completion (optional)
restic generate --bash-completion /etc/bash_completion.d/restic
```

Or via distro package:

```bash
# Debian / Ubuntu
sudo apt install restic

# Fedora / RHEL
sudo dnf install restic

# Arch
sudo pacman -S restic

# macOS
brew install restic
```

Then: `sudo restic self-update` to get latest (if the distro is behind).

## Init a repository + first backup

```bash
# 1. Export backend config as env vars (recommended — keeps secrets out of shell history)
export RESTIC_REPOSITORY=/srv/backups/home            # local dir
export RESTIC_PASSWORD_FILE=/root/.restic-password    # file with the password
echo 'correct-horse-battery-staple-that-is-long-and-strong' | sudo tee /root/.restic-password
sudo chmod 600 /root/.restic-password

# 2. Initialize the repo
sudo -E restic init

# 3. First backup
sudo -E restic backup /home /etc

# 4. List snapshots
sudo -E restic snapshots
```

### Example: S3 backend

```bash
export RESTIC_REPOSITORY='s3:s3.amazonaws.com/my-backup-bucket/hostname'
export AWS_ACCESS_KEY_ID='AKIA...'
export AWS_SECRET_ACCESS_KEY='...'
export RESTIC_PASSWORD_FILE=/root/.restic-password

sudo -E restic init
sudo -E restic backup /home /etc
```

### Example: REST server (self-hosted backup target)

```bash
# On the backup target host:
docker run -d \
  --name rest-server \
  --restart unless-stopped \
  -p 8000:8000 \
  -v /srv/backups:/data \
  -e OPTIONS='--no-auth --prometheus'  # for LAN use; set up auth + TLS for anything internet-facing
  restic/rest-server:latest

# On the client:
export RESTIC_REPOSITORY='rest:http://backup.example.com:8000/client1'
export RESTIC_PASSWORD_FILE=/root/.restic-password
restic init
restic backup /home
```

**For internet-facing REST server**: use `--private-repos` mode, per-user basic auth via htpasswd, reverse-proxy with TLS:

```bash
htpasswd -B -c /etc/rest-server/.htpasswd client1
# Then run rest-server with --private-repos + htpasswd mount
docker run -d \
  --name rest-server \
  -p 127.0.0.1:8000:8000 \
  -v /srv/backups:/data \
  -v /etc/rest-server/.htpasswd:/data/.htpasswd:ro \
  -e OPTIONS='--private-repos' \
  restic/rest-server:latest
# + Caddy/nginx in front with TLS
```

## Scheduled backups

### systemd timer (preferred)

```ini
# /etc/systemd/system/restic-backup.service
[Unit]
Description=Restic backup
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
User=root
EnvironmentFile=/etc/restic/restic.env
ExecStartPre=-/usr/local/bin/restic unlock
ExecStart=/usr/local/bin/restic backup \
    --exclude-file /etc/restic/excludes.txt \
    /home /etc /var/lib/docker/volumes
ExecStartPost=/usr/local/bin/restic forget --prune \
    --keep-daily 7 --keep-weekly 4 --keep-monthly 12 --keep-yearly 3
```

```ini
# /etc/systemd/system/restic-backup.timer
[Unit]
Description=Run Restic backup daily

[Timer]
OnCalendar=*-*-* 03:30:00
Persistent=true
RandomizedDelaySec=1800

[Install]
WantedBy=timers.target
```

```bash
# /etc/restic/restic.env
RESTIC_REPOSITORY=rest:https://backup.example.com/client1
RESTIC_PASSWORD_FILE=/etc/restic/password
# ... and backend creds as needed
```

```bash
# /etc/restic/excludes.txt
/dev
/proc
/sys
/tmp
/run
**/node_modules
**/.cache
**/*.log
```

```bash
sudo chmod 600 /etc/restic/restic.env /etc/restic/password
sudo systemctl daemon-reload
sudo systemctl enable --now restic-backup.timer
systemctl list-timers restic-backup
```

### Cron alternative

```cron
# /etc/cron.d/restic-backup
30 3 * * * root . /etc/restic/restic.env && /usr/local/bin/restic backup /home /etc >> /var/log/restic.log 2>&1
```

## Verification + weekly check

Running `restic check` periodically detects corruption on the backend:

```bash
# Quick check (metadata only)
sudo -E restic check

# Full check (re-reads a subset of data blobs — more expensive)
sudo -E restic check --read-data-subset=10%
```

Add as a second systemd timer that runs weekly.

## Restore

```bash
# List snapshots
restic snapshots

# Restore a full snapshot to a target dir
restic restore abc123ef --target /tmp/restore

# Restore specific paths
restic restore latest --target /tmp/restore --include /home/alice

# Browse via FUSE (read-only)
mkdir /mnt/restic
restic mount /mnt/restic
# In another shell: cd /mnt/restic/snapshots/latest ; ls
fusermount -u /mnt/restic   # when done
```

## Upgrade procedure

```bash
sudo restic self-update
```

Binary replaces itself in-place. Repo format is stable — no migration needed between restic versions.

## Data layout

**On the backup target (repo):**

```
repository/
├── config          # encrypted metadata
├── data/00..ff/    # packfiles (encrypted chunks)
├── index/          # searchable indices
├── keys/           # encrypted per-password keys
├── locks/          # exclusive locks on operations
└── snapshots/      # one file per snapshot
```

**On the client (nothing persistent)** — restic is stateless. Your only local state is the password file + env vars.

**Backup of the backup:** the repo itself can be copied with `rsync` / `rclone sync` as long as no operation is in flight. Or use `restic copy` to mirror between repos.

## Gotchas

- **Losing the repo password = losing all data.** Restic cannot recover without it. Period. Print the password, store it in a password manager, share with a trusted person, put a copy in a safe deposit box. This is the #1 reason people lose restic backups.
- **Losing backend credentials = losing access.** If you don't control the S3 keys / B2 keys / REST server creds, you can't reach the repo. Rotate safely: add a new key via the backend before retiring the old one.
- **`restic forget` does NOT free disk space.** It only tags snapshots as deleted. Run `restic prune` (or `forget --prune`) to actually reclaim space. Prune is I/O intensive — schedule separately from backups.
- **`restic prune` before 0.15 was very slow.** Modern restic (0.15+) has `--max-unused` and much faster prune. Use the latest release.
- **Two simultaneous backups to the same repo can cause lock conflicts.** Restic acquires an exclusive lock per operation. If a backup hangs and leaves a stale lock, `restic unlock` clears it. Scheduled jobs should include `ExecStartPre=restic unlock` defensively.
- **`restic check` on TB-scale repos over slow backends is hours.** Plan for it. `--read-data-subset=N%` randomly verifies N% of data; over a year of weekly checks it averages full coverage.
- **`restic mount` (FUSE) is read-only + uses a LOT of memory** for repos with many snapshots. Not for routine browsing of large repos — use `restic ls` / `restic dump` for targeted queries.
- **Deduplication is across the whole repo.** If Host A and Host B back up overlapping files to the same repo, you save disk. But it also means you CAN'T delete Host A's backups without potentially affecting Host B (restic handles this correctly via reference counting, but be mindful).
- **No dedicated per-client auth in repo format.** If two hosts share a repo, both need the SAME password, and each can see the other's data. For isolation, use one repo per host (or use rest-server's `--private-repos`).
- **Time skew breaks retention logic.** `forget --keep-daily 7` expects snapshots with valid `time` metadata. If your host's clock is hours off, retention may behave weirdly. Use NTP.
- **Backing up open files (databases, VM disks).** `restic backup /var/lib/postgresql/` while Postgres is running will copy an inconsistent DB. ALWAYS use `pg_dump | restic backup --stdin` (or equivalent snapshots for MySQL / LVM / ZFS / btrfs) for live databases.
- **Memory use on huge repos.** Backing up multi-TB datasets with millions of files can spike restic to several GB of RAM during indexing. If OOM-killed, use `--pack-size 64` to reduce in-memory pack cache, or back up subtrees separately.
- **Windows + case-insensitive filesystems** occasionally hit edge cases (snapshot restored with wrong-case filenames). Upstream tracks these; check release notes.
- **rclone backend is a pipe,** not a first-class integration. If rclone crashes mid-backup, the operation fails. rclone has its own "serve restic" mode (`rclone serve restic`) which is more robust for very-large remote backups.
- **`restic backup` exit codes:** 0 = success, 1 = fatal error, 3 = partial success (some files couldn't be read but most worked). Don't assume `$? != 0` = failure; 3 often means "a file was in use, we'll get it next time."
- **REST server default: `--no-auth` in examples is LAN-only.** Never expose a no-auth REST server to the internet. Use `--private-repos` + htpasswd + TLS.
- **Backup source path = snapshot path.** If today you back up `/home/alice` and tomorrow you back up `/srv/alice`, those become two trees in different snapshots. Be consistent with source paths for dedup to be maximally effective.

## Links

- Upstream repo: <https://github.com/restic/restic>
- Docs: <https://restic.readthedocs.io/en/latest/>
- Installation: <https://restic.readthedocs.io/en/latest/020_installation.html>
- Backends: <https://restic.readthedocs.io/en/latest/030_preparing_a_new_repo.html>
- Forum: <https://forum.restic.net/>
- Releases: <https://github.com/restic/restic/releases>
- REST server: <https://github.com/restic/rest-server>
- `restic-cheatsheet`: <https://github.com/restic/restic#compared-with-other-backup-programs>
- Video intro: <https://www.youtube.com/watch?v=xtmM9mdupNE>
- Integrations (resticprofile, autorestic, backrest web UI): community — <https://github.com/restic/awesome-restic>
