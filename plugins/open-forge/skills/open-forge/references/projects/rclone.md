---
name: rclone-project
description: Rclone recipe for open-forge. MIT-licensed "rsync for cloud storage" — CLI tool that syncs files to/from 70+ cloud providers (S3, GCS, Azure, Dropbox, Google Drive, Box, WebDAV, SFTP, etc.). NOT a daemon by default — it's a CLI you run on a control host, though `rclone serve` and `rclone mount` expose server/FUSE modes. This recipe covers the upstream install.sh, precompiled binaries, package manager installs, Docker, and the two "long-running" shapes (`rclone mount` as a FUSE filesystem via systemd; `rclone serve` as HTTP/WebDAV/SFTP/S3 frontend).
---

# Rclone

MIT-licensed "rsync for cloud storage." Sync, copy, move, mount, serve files across 70+ backends. Upstream: <https://github.com/rclone/rclone>. Docs: <https://rclone.org/docs/>.

**Not a daemon — a CLI.** Rclone's primary form is `rclone copy/sync/check` on a control host. The long-running server modes exist (`rclone serve`, `rclone mount`, `rclone rcd`) but most deployments are scheduled jobs (cron / systemd timers) that run a one-shot `rclone` invocation.

## What self-hosting Rclone actually means

| Intent | What you want |
|---|---|
| "Sync my files between cloud providers" | Install rclone + configure remotes + run via cron / systemd timer. |
| "Expose a cloud bucket as a local mount on a VPS" | `rclone mount` running under a systemd unit with `--allow-other`. |
| "Expose a cloud bucket as WebDAV / SFTP / S3 for other apps" | `rclone serve webdav|sftp|s3|http` as a systemd unit. |
| "Remote-control rclone from a GUI" | `rclone rcd` + rclone Web UI (experimental). |

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| install.sh (one-liner) | <https://rclone.org/install/#script-installation> | ✅ | Quickest install on Linux/macOS. |
| Precompiled binaries | <https://rclone.org/downloads/> | ✅ | Offline install / air-gapped / manual version pinning. |
| APT / DEB (Debian/Ubuntu) | <https://rclone.org/install/#linux-debian-ubuntu> | ✅ | Distro repos; version may lag upstream by a major version. |
| RPM (RHEL/Fedora) | Same docs page | ✅ | Same caveat. |
| Homebrew (macOS) | `brew install rclone` | ✅ | macOS dev. |
| MacPorts / choco (Windows) / Scoop | `rclone.org/install` | ✅ | Platform-specific package managers. |
| Docker (`rclone/rclone`) | <https://hub.docker.com/r/rclone/rclone> | ✅ | Sync jobs in containerized env; `mount` requires `--cap-add SYS_ADMIN --device /dev/fuse`. |
| Go install | `go install github.com/rclone/rclone@latest` | ✅ | Custom builds. |

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Install method?" | `AskUserQuestion` | Drives section. |
| intent | "What are you doing with rclone?" | `AskUserQuestion`: `Scheduled sync (cron/timer)` / `FUSE mount` / `Serve over HTTP/WebDAV/SFTP/S3` / `Interactive use` | Drives post-install config. |
| remote | "Which cloud backend?" | `AskUserQuestion` from the 70+ providers at <https://rclone.org/> | Determines the interactive `rclone config` flow. |
| auth | (provider-specific) "Paste OAuth token / API key / service-account JSON" | Free-text (sensitive) | Most providers use OAuth (`rclone config` opens a browser); service-account / HMAC for S3-compatible / GCS. |
| mount | "Mount point?" + "Run as user?" | Free-text | Only for the FUSE mount shape. |
| serve | "Port + auth?" | Free-text (HTTP basic-auth user/pass) | Only for `rclone serve`. |

## Install — install.sh (upstream one-liner)

```bash
# Linux/macOS
sudo -v ; curl https://rclone.org/install.sh | sudo bash

# Or beta channel
sudo -v ; curl https://rclone.org/install.sh | sudo bash -s beta
```

The script downloads the appropriate binary + man page, drops `rclone` into `/usr/bin`. Verify:

```bash
rclone version
```

## Install — Precompiled binary

```bash
# Linux amd64 example
cd /tmp
curl -O https://downloads.rclone.org/rclone-current-linux-amd64.zip
unzip rclone-current-linux-amd64.zip
cd rclone-*-linux-amd64
sudo cp rclone /usr/local/bin/
sudo chmod +x /usr/local/bin/rclone
sudo mkdir -p /usr/local/share/man/man1
sudo cp rclone.1 /usr/local/share/man/man1/
sudo mandb
rclone version
```

## Install — APT (Debian/Ubuntu)

```bash
sudo apt-get update && sudo apt-get install -y rclone
# Distro version often lags — check `rclone version` against https://rclone.org/downloads/
```

For newer versions on Ubuntu, prefer install.sh or the precompiled binary.

## Install — Docker

```bash
# Ephemeral one-shot
docker run --rm -it \
  -v ~/.config/rclone:/config/rclone \
  -v /path/to/local/data:/data \
  rclone/rclone config   # → interactive config; writes to $HOME/.config/rclone

docker run --rm \
  -v ~/.config/rclone:/config/rclone \
  -v /path/to/local/data:/data \
  rclone/rclone sync /data myremote:bucket

# Mount requires FUSE
docker run -d --restart always \
  --cap-add SYS_ADMIN --device /dev/fuse --security-opt apparmor:unconfined \
  -v ~/.config/rclone:/config/rclone \
  -v /mnt/cloud:/mnt/cloud:shared \
  rclone/rclone mount myremote:bucket /mnt/cloud --allow-other
```

## Configuration

Config lives at `~/.config/rclone/rclone.conf` (Linux/macOS) or `%APPDATA%\rclone\rclone.conf` (Windows). Structure:

```ini
[myremote]
type = s3
provider = AWS
access_key_id = AKIA...
secret_access_key = ...
region = us-east-1

[gdrive]
type = drive
client_id = ...
client_secret = ...
token = {"access_token":"...","token_type":"Bearer","refresh_token":"...","expiry":"..."}
```

**Generate interactively:**

```bash
rclone config
# n) New remote
# name> myremote
# <choose type from numbered list>
# <answer provider-specific prompts>
# y) Yes (confirm)
# q) Quit config
```

For cloud providers with OAuth (Google Drive, OneDrive, Dropbox, Box), the config flow asks "Use auto config? (y/n)":

- **Auto config (local)**: opens a browser on the host. Works only if you're running `rclone config` on a machine with a browser.
- **Remote config (headless)**: prints a URL; you open it on another machine, complete OAuth, and paste the returned token back into the SSH session. Use this on VPS installs.

### Encrypting config

```bash
rclone config
# s) Set configuration password
# → prompts for a password; config.conf is now encrypted
```

Every `rclone` invocation will then prompt for the password. Export `RCLONE_CONFIG_PASS=...` in env (or `RCLONE_PASSWORD_COMMAND="pass rclone"`) for unattended use.

## Long-running shape 1 — `rclone mount` (FUSE)

Mount a cloud bucket as a local filesystem:

```bash
# Manual test
sudo mkdir -p /mnt/cloud
rclone mount myremote:bucket /mnt/cloud \
  --allow-other \
  --vfs-cache-mode writes \
  --vfs-cache-max-size 10G \
  --log-file /var/log/rclone-mount.log
```

### Systemd unit

```ini
# /etc/systemd/system/rclone-mount.service
[Unit]
Description=Rclone mount (myremote:bucket → /mnt/cloud)
AssertPathIsDirectory=/mnt/cloud
After=network-online.target
Wants=network-online.target

[Service]
Type=notify
User=rclone
Group=rclone
Environment="RCLONE_CONFIG=/etc/rclone/rclone.conf"
ExecStart=/usr/bin/rclone mount myremote:bucket /mnt/cloud \
  --allow-other \
  --vfs-cache-mode writes \
  --vfs-cache-max-size 10G \
  --dir-cache-time 72h \
  --poll-interval 15s \
  --umask 002 \
  --log-level INFO \
  --log-file /var/log/rclone-mount.log
ExecStop=/bin/fusermount -uz /mnt/cloud
Restart=on-failure
RestartSec=10

[Install]
WantedBy=default.target
```

`/etc/fuse.conf` must contain `user_allow_other` for `--allow-other` to work.

## Long-running shape 2 — `rclone serve`

Expose a remote over HTTP / WebDAV / FTP / SFTP / S3 / DLNA / Restic-REST:

```bash
# WebDAV for generic mounting
rclone serve webdav myremote:bucket \
  --addr 127.0.0.1:8080 \
  --user myuser --pass mypass \
  --vfs-cache-mode full

# SFTP (clients: sshfs, Filezilla, etc.)
rclone serve sftp myremote:bucket \
  --addr 0.0.0.0:2022 \
  --user myuser --pass mypass

# S3 (for apps that expect S3 API but you want to back it with another backend)
rclone serve s3 myremote:bucket \
  --addr 0.0.0.0:9000 \
  --auth-key "accesskey,secretkey"
```

Wrap in a systemd unit; front with a reverse proxy for TLS.

## Scheduled sync — systemd timer

```ini
# /etc/systemd/system/rclone-backup.service
[Unit]
Description=Daily rclone backup
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
User=rclone
Group=rclone
Environment="RCLONE_CONFIG=/etc/rclone/rclone.conf"
ExecStart=/usr/bin/rclone sync /home/user/Documents backup:documents \
  --bwlimit 10M \
  --log-file /var/log/rclone-backup.log \
  --log-level INFO
```

```ini
# /etc/systemd/system/rclone-backup.timer
[Unit]
Description=Daily rclone backup timer

[Timer]
OnCalendar=*-*-* 03:00:00
Persistent=true

[Install]
WantedBy=timers.target
```

```bash
sudo systemctl enable --now rclone-backup.timer
sudo systemctl list-timers | grep rclone
```

## Upgrade procedure

```bash
# install.sh / binary: rerun install.sh to grab latest stable
sudo -v ; curl https://rclone.org/install.sh | sudo bash

# APT: sudo apt-get update && sudo apt-get upgrade rclone
# Docker: docker pull rclone/rclone:latest

# Restart long-running services
sudo systemctl restart rclone-mount
```

Config is forward-compatible across rclone versions — `rclone.conf` from 2020 still works in current versions. Rare backend changes (provider API deprecations) are called out in release notes at <https://rclone.org/changelog/>.

## Gotchas

- **Not a daemon, don't treat it like one.** Most "rclone is slow / stuck" issues on Reddit are users running `rclone copy` inside a browser tab SSH and wondering why it hangs when the session drops. Use `tmux` / `nohup` / systemd.
- **`--vfs-cache-mode` matters a lot for mounts.** `off` (default) breaks many apps that expect random writes. `writes` is the safe default; `full` caches reads too and is best for media playback. Cache size must be bounded (`--vfs-cache-max-size`) or it will fill the disk.
- **FUSE + `--allow-other`** needs `/etc/fuse.conf: user_allow_other` AND must run as a user with read access to the mount target. Running mount as root usually causes permission surprises in other apps.
- **Docker mount needs privileged-ish flags.** `--cap-add SYS_ADMIN --device /dev/fuse --security-opt apparmor:unconfined`. These weaken container isolation — consider running rclone on the host instead of in a container for mounts.
- **OAuth token refresh on headless hosts.** When a token refresh fails (e.g. Google revoked it, or the refresh_token expired), the scheduled sync silently fails. Monitor log files; many users don't notice for days.
- **`--bwlimit` is critical on consumer connections.** A full-speed `rclone sync` to S3 will saturate your upload and make the household complain.
- **Delete safety.** `rclone sync` is destructive — it makes destination match source (deletes extras). Use `rclone copy` unless you mean it. For dangerous ops, add `--dry-run` first, then `--interactive` for confirmations, or back up with `rclone sync --backup-dir`.
- **Config-file secrets.** `rclone.conf` contains raw API keys and OAuth tokens. `chmod 600` + ownership of the rclone user; consider `rclone config` password encryption for extra protection.
- **Encrypted remotes (`crypt`) have a chicken-and-egg with cache.** The `crypt` backend wraps another remote; always point `--vfs-cache` at local disk, NOT the encrypted remote.
- **Rate limits hit without warning.** Google Drive has a 750 GB/day upload quota per account; hit it and your sync 403s. Check `--drive-upload-cutoff`, `--drive-server-side-across-configs`, and backoff flags.
- **Distro package often lags.** The version in `apt install rclone` might be a year or two old. For any new feature / backend, install via install.sh or the binary.
- **`rclone rcd` + Web UI is experimental** and not upstream-recommended for production. Use CLI or `rclone serve` for stable long-running modes.

## Links

- Upstream repo: <https://github.com/rclone/rclone>
- Install docs: <https://rclone.org/install/>
- Downloads: <https://rclone.org/downloads/>
- Docs: <https://rclone.org/docs/>
- Provider list: <https://rclone.org/#providers>
- `rclone mount` options: <https://rclone.org/commands/rclone_mount/>
- `rclone serve` options: <https://rclone.org/commands/rclone_serve/>
- Changelog: <https://rclone.org/changelog/>
- Docker image: <https://hub.docker.com/r/rclone/rclone>
- Forum: <https://forum.rclone.org/>
