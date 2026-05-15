---
name: Kopia
description: Fast, cross-platform, open-source backup tool with native web UI, CLI, and desktop app. Encrypted, deduplicated, incremental backups to S3/B2/GCS/Azure/SFTP/WebDAV/Rclone/local. Go. Apache-2.0.
---

# Kopia

Kopia is Borg/restic's modern sibling — similar deduplication + encryption model, but with:

- **Native web UI** (KopiaUI desktop app + a browser-based server UI)
- **First-class cloud backends** (S3, B2, Azure, GCS, SFTP, WebDAV, Rclone, Filesystem)
- **Cross-platform** — runs natively on Linux, macOS, Windows
- **Snapshots** model (vs Borg's archives) — point-in-time, deduplicated
- **Policies per-directory** (compression, retention, filters)
- **No server-side component required** for most backends (client-to-object-storage is direct)

Use cases: personal laptop backups to B2/S3, homelab server backups to a MinIO instance, multi-device dedup to a shared bucket.

- Upstream repo: <https://github.com/kopia/kopia>
- Website: <https://kopia.io>
- Docs: <https://kopia.io/docs/>
- Docker image: `kopia/kopia` on Docker Hub
- Desktop download: <https://kopia.io/docs/installation/>

## Architecture in one minute

Three modes:

1. **CLI** (`kopia`) — all operations from command line
2. **KopiaUI desktop app** — Electron wrapper; manages one or more repos on your laptop
3. **Kopia server** (`kopia server start`) — headless server with web UI, for multi-user / always-on setups

"Repository" = a location (S3 bucket / local disk / SFTP path) holding encrypted, deduplicated data. One repository can have many snapshots from many sources.

## Compatible install methods

| Infra / Host               | Runtime                                              | Notes                                                                |
| -------------------------- | ---------------------------------------------------- | -------------------------------------------------------------------- |
| Linux / macOS / Windows    | Binary or `brew install kopia`                       | Single binary; CLI + embedded web UI                                 |
| macOS / Linux / Windows    | **KopiaUI** desktop app                              | Double-clickable GUI for interactive use                              |
| Headless server            | Docker (`kopia/kopia`) with web UI enabled           | Always-on backup orchestrator                                         |
| Kubernetes                 | Plain Deployment; repo = S3/B2                       | For backing up cluster workloads                                      |
| systemd                    | Binary + systemd unit                                 | For scheduled CLI runs                                                |

## Inputs to collect

| Input                       | Example                                        | Phase     | Notes                                                                  |
| --------------------------- | ---------------------------------------------- | --------- | ---------------------------------------------------------------------- |
| Repository backend          | S3 / B2 / filesystem / SFTP / WebDAV / GCS      | Config    | Pick once per repo                                                      |
| Backend credentials         | S3 access key / B2 app key / etc.              | Auth      | Stored encrypted in Kopia's client state                                |
| Repository password         | `openssl rand -base64 32`                      | Security  | **Cannot be recovered**; losing = losing all data in the repo           |
| Snapshot source paths       | `/home`, `/var/lib/docker`, …                  | Config    | Per host                                                                |
| Retention policy            | e.g. keep 10 latest + 7 daily + 4 weekly + 12 monthly | Policy | Per snapshot source or global                                      |
| Compression                 | `s2-default` (default), `zstd-max`, `none`     | Policy    | `zstd-max` for cold storage; `s2` (fast) for frequent                   |
| Scheduled snapshot interval | every 1h / nightly                              | Schedule  | Kopia server / KopiaUI has built-in scheduler                           |
| Server creds (if using server) | username + password                          | Auth      | Server UI + CLI client auth                                             |

## Install

### Linux (apt)

```sh
# Add repo
curl -s https://kopia.io/signing-key | sudo gpg --dearmor -o /etc/apt/keyrings/kopia-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kopia-keyring.gpg] http://packages.kopia.io/apt/ stable main" | sudo tee /etc/apt/sources.list.d/kopia.list
sudo apt update
sudo apt install kopia
```

### macOS

```sh
brew install kopia     # CLI
brew install --cask kopiaui   # GUI
```

### Standalone binary

From <https://github.com/kopia/kopia/releases> — single `kopia` binary per platform. Drop in `/usr/local/bin/` and run.

### Docker

From upstream [`tools/docker/docker-compose.yml`](https://github.com/kopia/kopia/blob/master/tools/docker/docker-compose.yml):

```yaml
services:
  kopia:
    image: kopia/kopia:0.23.0    # pin; :latest moves
    container_name: kopia
    user: "0:0"                   # needed to read arbitrary source files
    restart: unless-stopped
    privileged: true              # for FUSE mount (snapshot browse)
    cap_add: [SYS_ADMIN]
    security_opt: [apparmor:unconfined]
    devices:
      - /dev/fuse:/dev/fuse:rwm
    command:
      - server
      - start
      - --address=0.0.0.0:51515
      - --server-username=admin
      - --server-password=<strong>
      - --tls-cert-file=/app/config/cert.pem     # generate or mount
      - --tls-key-file=/app/config/key.pem
    volumes:
      - /mnt/kopia-tmp:/tmp:shared                # snapshot mounts here
      - ./kopia-config:/app/config
      - ./kopia-cache:/app/cache
      - ./kopia-logs:/app/logs
      - /:/data:ro                                # mount source as read-only
    environment:
      - KOPIA_PASSWORD=<repo password>
      - TZ=UTC
    ports:
      - "51515:51515"
```

Browse `https://<host>:51515`.

## First repo + first snapshot

### Create a repo (CLI)

```sh
# S3-compatible backend (MinIO / AWS / Wasabi / Backblaze B2)
kopia repository create s3 \
  --bucket my-bucket \
  --endpoint s3.us-west-004.backblazeb2.com \
  --access-key "$B2_KEY_ID" \
  --secret-access-key "$B2_APP_KEY" \
  --password "$REPO_PASSWORD"

# Filesystem backend
kopia repository create filesystem --path /mnt/backup/kopia-repo --password "$REPO_PASSWORD"

# Backblaze B2 native
kopia repository create b2 --bucket my-bucket --key-id ... --key ... --password ...

# Rclone backend — use any of rclone's 40+ backends as Kopia's repo
kopia repository create rclone --remote-path myremote:path --password ...
```

### Connect / disconnect

```sh
# On another machine, connect to the same repo
kopia repository connect s3 --bucket my-bucket --access-key ... --secret-access-key ... --password ...

# Deduplication works across machines sharing the same repo + password
```

### Snapshot a directory

```sh
kopia snapshot create /home/alice

# List snapshots
kopia snapshot list

# Restore
kopia snapshot restore <SNAPSHOT_ID> /restore/target/
# Or mount
kopia mount <SNAPSHOT_ID> /mnt/browse
```

### Schedule via policies

```sh
# Set a policy on /home/alice: hourly snapshots + retention
kopia policy set /home/alice \
  --snapshot-interval 1h \
  --keep-latest 10 \
  --keep-hourly 24 \
  --keep-daily 7 \
  --keep-weekly 4 \
  --keep-monthly 12
```

Kopia server / KopiaUI runs the scheduler; CLI-only runs need a wrapper (systemd timer, cron, Kopia's `--run-once`).

## Data & config layout

Client-side (`~/.config/kopia/`):

- `repository.config` — pointer to which repo this machine is connected to
- `~/.cache/kopia/` — local cache of repo metadata (can be deleted; rebuilds)

Server-side (in the repository itself — encrypted):

- Blobs (chunk pack files)
- Manifests (snapshot metadata, policies)
- Index files

Password + key material are derived from the passphrase; repo is unreadable without it.

## Backup

Kopia's storage backend IS the backup. For disaster recovery:

1. Ensure the backend (S3 bucket / B2 bucket / local path) is replicated or itself backed up
2. Securely store the **repository password** in a password manager + a cold-storage location

**Losing the repo password = losing the backup.** No recovery.

For truly-cold archival, consider using Kopia's `compression: zstd-max` + B2 + B2 lifecycle rules to move to cold archive tier.

## Upgrade

1. Releases: <https://github.com/kopia/kopia/releases>. Semver; regular cadence.
2. Binary: replace with newer version.
3. Docker: `docker compose pull && docker compose up -d`.
4. **Repository format is stable.** Upgrades are in-place; old clients can read new repos as long as they're within 1-2 minor versions.
5. **Downgrade is supported** for repo format unless you explicitly upgraded the format (`kopia repository upgrade`). Don't upgrade format until you're sure.

## Gotchas

- **Repository password is unrecoverable.** Save in a password manager + a second secure location. Losing it = data gone.
- **Default compression `s2-default`** is optimized for speed. For backups you rarely restore (cold archive), switch to `zstd-max` per-policy for 2-3× better ratio.
- **Docker running as `user: 0:0` + `privileged: true`** is a security trade-off for convenience (read arbitrary files, mount FUSE). In stricter setups, run as the target user + skip FUSE mount features.
- **Snapshot mount** (browse as FUSE filesystem) requires `/dev/fuse` + `cap_add: SYS_ADMIN` in Docker — hence the privileged mode.
- **TLS cert** on the server is MANDATORY for the web UI login flow (Kopia server refuses plaintext auth by default). Either generate self-signed (`--tls-generate-cert`) or supply one. Or proxy behind Caddy for free Let's Encrypt.
- **Password in command line = visible in `ps`.** Prefer `KOPIA_PASSWORD` env var or the persistent config.
- **Deduplication scope = a single repository.** Multiple machines snapshotting to the SAME repo with the same password dedup across each other. Different passwords or different repos = no cross-machine dedup.
- **Server mode requires client auth** for each connecting CLI (`kopia repository connect server --url=https://server:51515 --server-username=... --server-cert-fingerprint=...`).
- **`kopia maintenance run --full`** defragments the repo (reclaim space from deleted blobs); runs automatically every N days but can be forced.
- **`kopia repository connect` + `disconnect`** switches active repo — a single kopia binary can point to one repo at a time.
- **Upload retry on transient S3 errors** is automatic; large upload failures just resume.
- **Parallel upload** speeds large first snapshots; tune `--parallel=<N>` (default 10).
- **Actions** (pre/post snapshot hooks) can run DB dumps before snapshotting — cleaner than backing up live DB files.
- **Cold-storage tiers** (S3 Glacier, B2 Backblaze Cloud Storage cold) interact with Kopia's random-access reads. Don't use archive tiers for active repos; they're fine for disconnected long-term copies.
- **File browsing in web UI** loads manifests but doesn't download chunks until you click download/restore — fast UX even on cold-network backends.
- **Schedule only works while Kopia is running.** `kopia server` daemon or KopiaUI desktop app must be alive. CLI-only deployments need external scheduler (cron / systemd timer / launchd).
- **Performance**: typically 50-200 MB/s to local disk; 10-100 MB/s to cloud (network-bound).
- **Alternatives worth knowing:**
  - **Borg** — older, rock-solid, CLI-first (covered separately)
  - **restic** — similar concept, single binary, many cloud backends
  - **Duplicacy** — lock-free dedup, commercial + CLI OSS
  - **BorgBase / rsync.net** — managed Borg hosting
  - **Rclone sync** — not dedup, just copy
  - **Veeam** / **Duplicati** — if you prefer GUI-heavy Windows-native tools

## Links

- Repo: <https://github.com/kopia/kopia>
- Website: <https://kopia.io>
- Docs: <https://kopia.io/docs/>
- Installation: <https://kopia.io/docs/installation/>
- Repository backends: <https://kopia.io/docs/repositories/>
- CLI reference: <https://kopia.io/docs/reference/command-line/>
- Policies: <https://kopia.io/docs/advanced/policies/>
- Actions (hooks): <https://kopia.io/docs/advanced/actions/>
- Releases: <https://github.com/kopia/kopia/releases>
- Docker Hub: <https://hub.docker.com/r/kopia/kopia>
- Docker compose example: <https://github.com/kopia/kopia/blob/master/tools/docker/docker-compose.yml>
- Slack community: <https://slack.kopia.io/>
