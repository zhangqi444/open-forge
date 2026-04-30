---
name: Duplicati
description: Free, open-source, incremental, encrypted, deduplicated backup client. Backs up laptops, servers, or containers to cloud storage (S3, B2, Azure, Google Drive, SFTP, WebDAV, and many more) via a web UI or CLI. Windows, macOS, Linux. MIT.
---

# Duplicati

Duplicati is a backup client — think duplicity with a friendly web UI, or BorgBackup with native cloud-storage support. AES-256 encryption, block-level deduplication, optional compression, flexible scheduling. Supports 20+ backup destinations: Amazon S3, Backblaze B2, Dropbox, Google Drive, OneDrive, Box, Azure Blob, MEGA, SFTP, FTP, WebDAV, OpenStack Swift, Storj, Tencent COS, Aliyun OSS, and more.

For a self-host context: Duplicati typically runs alongside your other services (on the same host) and backs them up to off-site cloud storage. It's not a storage server itself — it's a backup client.

- Upstream repo: <https://github.com/duplicati/duplicati>
- Docs: <https://docs.duplicati.com>
- Docker docs: <https://github.com/duplicati/duplicati/blob/master/ReleaseBuilder/Resources/Docker/README.md>
- Forum: <https://forum.duplicati.com>
- Website: <https://duplicati.com>

## Release channels

Duplicati ships on four channels — pick based on risk appetite:

| Channel        | Tag              | Purpose                                                              |
| -------------- | ---------------- | -------------------------------------------------------------------- |
| Stable         | `latest`         | **Recommended for production** (2.0.8+ is stable as of late 2025)   |
| Beta           | `beta`           | Regressions possible but mostly safe                                 |
| Experimental   | `experimental`   | Rapid-iteration features                                             |
| Canary         | `canary`         | Nightly builds; prefer to actually run your next backup here         |

Duplicati maintained a long-running "beta" era (2.0.6 was "beta" for years) — the Stable designation is relatively new. Many docs + tutorials still assume "beta" = the recommended channel; check upstream for current guidance.

## Compatible install methods

| Infra                  | Runtime                                        | Notes                                                                 |
| ---------------------- | ---------------------------------------------- | --------------------------------------------------------------------- |
| Laptop / workstation   | Native installer (.msi / .deb / .rpm / .dmg / AppImage) | **Recommended for desktop** — native tray icon            |
| Server                 | Docker (`duplicati/duplicati`)                 | **Recommended for server backups of containerized apps**              |
| Server                 | Docker (`lscr.io/linuxserver/duplicati`)       | LinuxServer.io image; alternative with PUID/PGID                      |
| Server                 | Systemd service (bare metal)                   | Upstream ships systemd units in the .deb/.rpm                         |
| Headless agent         | Docker (`duplicati/duplicati:latest` with `duplicati-agent`) | For unattended deploy with remote management                |
| Synology / QNAP / Unraid | Package via community repos                  | Popular for NAS users                                                 |

## Inputs to collect

| Input                                   | Example                                          | Phase     | Notes                                                             |
| --------------------------------------- | ------------------------------------------------ | --------- | ----------------------------------------------------------------- |
| Web UI port                             | `8200:8200`                                      | Network   | Web interface; **NEVER expose directly to the internet**           |
| `DUPLICATI__WEBSERVICE_PASSWORD`        | strong                                           | Bootstrap | Without this, first-boot password is random (logged once)         |
| `SETTINGS_ENCRYPTION_KEY`               | strong, long                                     | Security  | Encrypts stored backup destination credentials in the SQLite DB    |
| `DUPLICATI__WEBSERVICE_ALLOWED_HOSTNAMES` | `duplicati.example.com`                        | Security  | Restrict Host header to mitigate DNS-rebinding attacks             |
| `UID` / `GID`                           | `1000` / `1000`                                  | Runtime   | Run as non-root user; Duplicati chowns `/data` to match             |
| `TZ`                                    | `Europe/Berlin`                                  | Runtime   | For schedule display; NOT for schedule evaluation                  |
| Backup destination                      | provider + credentials                           | Config    | S3 key, B2 app key, SSH key, etc. — held in `/data`                |
| Encryption passphrase                   | long + stored OUT OF BAND                        | Config    | Per-backup job; **lose this = lose the backup forever**            |
| Source paths                            | `/source/...` bind-mounts                        | Config    | Bind-mount everything you want to back up into the container        |

## Install via Docker

From <https://github.com/duplicati/duplicati/blob/master/ReleaseBuilder/Resources/Docker/README.md>:

```yaml
services:
  duplicati:
    image: duplicati/duplicati:latest     # stable; use :beta for beta channel
    container_name: duplicati
    restart: unless-stopped
    ports:
      - "8200:8200"
    environment:
      - TZ=Europe/Berlin
      - UID=1000
      - GID=1000
      - DUPLICATI__WEBSERVICE_PASSWORD=REPLACE_WITH_STRONG_PW
      - SETTINGS_ENCRYPTION_KEY=REPLACE_WITH_LONG_RANDOM_KEY
      - DUPLICATI__WEBSERVICE_ALLOWED_HOSTNAMES=duplicati.example.com
    volumes:
      - ./duplicati-data:/data          # Duplicati's own settings / DB / cache
      - /some/path:/source/mydata:ro    # mount ANYTHING you want to back up
      - /var/lib/docker/volumes:/source/docker-volumes:ro   # example: back up all docker volumes
      - /etc:/source/etc:ro             # example: back up /etc
```

Browse `http://<host>:8200` — the first sign-in uses `DUPLICATI__WEBSERVICE_PASSWORD` if set; otherwise grep the logs for the auto-generated signin link.

### Quick `docker run`

```sh
docker run -d --name duplicati \
  -p 8200:8200 \
  -e TZ=Europe/Berlin \
  -e UID=$(id -u) -e GID=$(id -g) \
  -e DUPLICATI__WEBSERVICE_PASSWORD='strong' \
  -e SETTINGS_ENCRYPTION_KEY='long-random-key' \
  -v /host/duplicati-data:/data \
  -v /host/to/backup:/source:ro \
  --restart unless-stopped \
  duplicati/duplicati
```

### Headless CLI inside the container

```sh
# Help
docker run --rm duplicati/duplicati duplicati-cli help

# One-shot backup via CLI (not via the scheduler — run from host cron)
docker run --rm -e UID=$(id -u) -e GID=$(id -g) \
  -v /home:/backup/home:ro \
  duplicati/duplicati duplicati-cli backup ssh://user@host /backup/home
```

All CLI args are available as env vars: `--webservice-password` → `DUPLICATI__WEBSERVICE_PASSWORD` (prefix `DUPLICATI__`, dashes → underscores).

## Configuring a backup job

Via web UI (`/`):

1. **Add backup** → General: name + encryption passphrase (store offline, seriously).
2. **Destination** → pick provider + paste credentials.
3. **Source data** → pick directories under `/source/` (whatever you bind-mounted).
4. **Schedule** → cron-like window.
5. **Options** → set retention (e.g. `1W:1D,4W:1W,12M:1M` = daily for 1 week, weekly for 4 weeks, monthly for 12 months).
6. **Run** now to verify.

## Data & config layout

Inside `/data`:

- `Duplicati-server.sqlite` — master DB: list of backup jobs, schedules, destinations (encrypted if `SETTINGS_ENCRYPTION_KEY` is set), web UI users
- `<job-id>-DUPL.sqlite` — per-backup local index/cache (hash → block mapping, speeds up restores)
- `duplicati-*.log` — server + job logs
- `control_dir_v2/` — control-plane state

The per-job SQLite index can be large (several % of backup size). Back up `/data` alongside your sources — losing it forces Duplicati to re-index the remote, which can take hours.

## Backup (of Duplicati itself)

```sh
docker compose stop duplicati
tar czf duplicati-data-$(date +%F).tgz ./duplicati-data
docker compose start duplicati

# Store offsite:
# Either restore to a new host + same SETTINGS_ENCRYPTION_KEY to pick up all jobs,
# or use Duplicati's "Export configuration" feature per-job to get a JSON per-backup
# that documents the destination + options (password is re-entered on import).
```

## Upgrade

1. Releases: <https://github.com/duplicati/duplicati/releases>.
2. Docker: `docker compose pull && docker compose up -d`. Duplicati runs DB migrations automatically.
3. **Major upgrades can change the remote data format.** After a major upgrade, run a `test` operation against each backup destination before the next scheduled backup runs.
4. **DB schema changes** happen occasionally; upstream sometimes requires a "repair" operation post-upgrade. Watch the job log.
5. Native packages: `apt install duplicati` / `rpm -Uvh duplicati.rpm` / run the new MSI. Settings in `~/.config/Duplicati/` persist.

## Gotchas

- **LOSING THE ENCRYPTION PASSPHRASE = LOSING THE BACKUP.** There's no recovery, no "reset". Store the passphrase in a password manager AND a physical offline location. Test restores monthly.
- **`SETTINGS_ENCRYPTION_KEY` is distinct from backup passphrase.** `SETTINGS_ENCRYPTION_KEY` encrypts the server's SQLite DB (which holds destination credentials). The per-backup passphrase encrypts the backup data itself. Both matter; don't conflate.
- **Web UI has NO authentication by default.** Docker images disable the bind-address restriction (`DUPLICATI__WEBSERVICE_INTERFACE=any`). Anyone on port 8200 can access your backups until you set `DUPLICATI__WEBSERVICE_PASSWORD` AND `DUPLICATI__WEBSERVICE_ALLOWED_HOSTNAMES` (to mitigate DNS rebinding).
- **Per-release history includes real data-loss bugs.** Duplicati was famously buggy during the 2.0.5/2.0.6 era; the project has stabilized but "my backups are corrupt" forum posts still appear. **Always test restores before relying on the backup.**
- **Test restore monthly, not "when something bad happens".** Duplicati's complexity + optional features (compact, repair, recreate DB) mean that a backup you've never tested has an unknown probability of being restorable.
- **Duplicati runs as root by default in Docker.** Set `UID` + `GID` env to run as a non-root user. The container chowns `/data` on first boot to match.
- **Schedule uses system time.** `TZ` env affects display but the scheduler uses the container's system clock. If host time drifts (NTP off), schedules fire at wrong real-world times.
- **Large backups bottleneck on the local SQLite index.** For TB-scale backups, the per-job SQLite DB grows into GB and local disk IOPS matters. A spinning disk for `/data` + a big cloud backup = slow scans.
- **Compact operation is critical.** Over time, deleted blocks fragment the remote. Duplicati runs `compact` automatically based on `--auto-compact-interval`; make sure it's enabled — otherwise deleted files keep paying storage fees.
- **`--block-size`, `--dblock-size`** — defaults are sensible for most (100 KB blocks, 50 MB remote volumes). For billions of tiny files: larger blocks. For VM images / DBs: default is fine.
- **Restore is SLOW.** Restoring 500 GB from B2 can take 24+ hours (downloading remote volumes + hashing). Plan RTO accordingly; keep local copies of truly critical data.
- **Dedupe is content-defined, not file-based.** Moving a 1 GB file to a new directory = free. Editing one byte = re-upload one block (~100 KB).
- **S3 / cloud egress costs.** Backups are cheap (B2 is $6/TB/mo); restores are expensive (B2 egress $0.01/GB, AWS egress much more). Factor in test-restore costs.
- **Web UI becomes unresponsive during long operations.** Initial backup of 1 TB can make the UI show "pending" for hours. Don't assume it's hung; check the job log via `docker logs duplicati`.
- **Multiple backups to the same remote folder = data corruption.** Each Duplicati backup job MUST have its own remote folder. Sharing → block hash collisions → unrecoverable.
- **Backing up a database live?** Use `--run-script-before` to dump the DB to a tarball, then back up the tarball, then delete the tarball in `--run-script-after`. Don't back up the live DB files.
- **GPG backend** is available as an alternative to AES. Requires GPG installed in the container (absent in upstream image). Most users stick with AES-256.
- **Alternatives worth knowing:**
  - **Restic** — Go, single-binary, arguably more reliable; no GUI
  - **Borg + BorgBackup** — strong dedupe, requires Borg-aware remote (hurts some cloud providers)
  - **Kopia** — Go, modern UI, strong dedupe
  - **rclone** + cron — simplest for "sync unencrypted to cloud with encryption layer"

## Links

- Repo: <https://github.com/duplicati/duplicati>
- Website: <https://duplicati.com>
- Docs: <https://docs.duplicati.com>
- Docker docs: <https://github.com/duplicati/duplicati/blob/master/ReleaseBuilder/Resources/Docker/README.md>
- Docker Hub: <https://hub.docker.com/r/duplicati/duplicati>
- LinuxServer alternative: <https://github.com/linuxserver/docker-duplicati>
- Forum: <https://forum.duplicati.com>
- Releases: <https://github.com/duplicati/duplicati/releases>
- Download (installers): <https://duplicati.com/download>
- Backup destination overview: <https://docs.duplicati.com/backup-destinations/destination-overview>
- Alternative Restic: <https://restic.net>
- Alternative Kopia: <https://kopia.io>
