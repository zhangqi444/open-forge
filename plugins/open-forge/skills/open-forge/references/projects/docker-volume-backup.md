---
name: Docker Volume Backup
description: "Lightweight companion container that backs up Docker volumes on recurring schedules to local / S3 / WebDAV / Azure Blob / Dropbox / Google Drive / SSH. GPG encryption, rotation, failure notifications. Sub-25MB image. MPL-2.0. Built by offen.software."
---

# Docker Volume Backup

docker-volume-backup is **"the tiny companion-container that takes real backups of your Docker volumes, to wherever you want them, on a cron"** — a sub-25MB image (`offen/docker-volume-backup`) that you add to any compose stack, mount your volumes + the Docker socket into, and configure via env vars. It:

- **Stops + restarts labeled containers** around backup (for integrity)
- Creates a tar.gz of mounted volume paths
- **Optionally GPG-encrypts** the archive
- **Uploads** to any combination of: local directory, S3-compatible, WebDAV, Azure Blob, Dropbox, Google Drive, SSH target
- **Rotates** old backups (retention policy)
- **Notifies** on success/failure (many integrations via shoutrrr)

Built + maintained by **offen.software** (Frederik Ring + community). **License: MPL-2.0**. Active + mature + high-quality recipe culture (upstream maintains `recipes/` dir for common scenarios).

Use cases: (a) **homelab backup substrate** — every stateful service backed up off-box (b) **pre-migration snapshot** — one-off backup before a host rebuild (c) **DR plan foundation** — scheduled offsite backups to S3/B2 (d) **compliance retention** — rotate + encrypted + offsite = checks regulatory boxes (e) **pairs with restic / borg** — DVB does volume-snapshot; restic/borg can backup DVB's output for deduplicated long-term retention (f) **disaster recovery drills** — test restore procedure quarterly.

Features:

- **Multiple backends** — S3 + WebDAV + Azure + Dropbox + Google Drive + SSH + local
- **Combination targets** — e.g., local mirror + S3 off-site simultaneously
- **GPG encryption** — sym + asym supported
- **Container-stop-during-backup** label — integrity-safe backups of DB-writing services
- **Exec commands before/after** — custom DB-dump hooks, VSS-style pre-freeze
- **Rotation** — age-based + count-based retention
- **Notifications via shoutrrr** — Discord + Slack + Telegram + Teams + email + many more
- **Small image** (<25MB)
- **Single binary Go tool** — minimal attack surface
- **One-off backups** via `docker run` — ad-hoc snapshots

- Upstream repo: <https://github.com/offen/docker-volume-backup>
- Homepage: <https://www.offen.software>
- Docs: <https://offen.github.io/docker-volume-backup>
- Config reference: <https://offen.github.io/docker-volume-backup/reference/>
- How-tos: <https://offen.github.io/docker-volume-backup/how-tos/>
- Recipes: <https://offen.github.io/docker-volume-backup/recipes/>
- Docker Hub: <https://hub.docker.com/r/offen/docker-volume-backup>
- Releases: <https://github.com/offen/docker-volume-backup/releases>

## Architecture in one minute

- **Go single binary** — inside a minimal container
- **Cron-scheduled** — internal cron (`BACKUP_CRON_EXPRESSION`) or trigger-on-demand
- **Uses Docker socket** (read-only) to find labeled containers to stop during backup
- **Tar+gzip** the mounted volume paths; optionally GPG encrypt; upload; rotate
- **Resource**: sub-25MB image, minimal RAM except during backup run (streams through)

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker compose** | **As a `backup` sidecar service alongside your stack**          | **Canonical pattern**                                                              |
| Docker run (one-off) | `docker run --rm ... --entrypoint backup ...`                                | For ad-hoc backups                                                                                 |
| Kubernetes         | Similar pattern as a CronJob or sidecar                                                                | Community-adapted                                                                                              |

## Inputs to collect

| Input                      | Example                                                                 | Phase        | Notes                                                                    |
| -------------------------- | ----------------------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| `BACKUP_FILENAME`          | `backup-%Y-%m-%dT%H-%M-%S.tar.gz`                                       | Config       | Time-templated                                                                                     |
| `BACKUP_CRON_EXPRESSION`   | `0 2 * * *` (2am daily)                                                 | Schedule     | Standard cron syntax                                                                                     |
| `AWS_*` vars               | S3 endpoint + bucket + creds                                            | Remote       | For S3 backend (or B2, Wasabi, MinIO S3-compat)                                                                                     |
| `GPG_PASSPHRASE` / pubkey  | For encryption                                                          | **CRITICAL** | **IMMUTABLE — lose it, lose all backups**                                                                                     |
| `BACKUP_RETENTION_DAYS`    | `30`                                                                    | Rotation     | Age-based pruning                                                                                     |
| Container labels           | `docker-volume-backup.stop-during-backup=true` on data-writing services | Pattern      | Required for DB/stateful integrity                                                                                     |
| Notification URL           | shoutrrr URL for failure alerts                                         | Observability | **CRITICAL** — silent-backup-failure is the classic bug                                                                                     |

## Install via Docker Compose (canonical pattern)

```yaml
services:
  app:
    image: my/app:1.0
    volumes:
      - appdata:/var/lib/app
    labels:
      - docker-volume-backup.stop-during-backup=true      # **critical for integrity**

  backup:
    image: offen/docker-volume-backup:v2.43.0              # **pin version** per upstream advice
    restart: always
    environment:
      - BACKUP_FILENAME=backup-%Y-%m-%dT%H-%M-%S.tar.gz
      - BACKUP_CRON_EXPRESSION=0 2 * * *
      - BACKUP_RETENTION_DAYS=30
      # S3-compatible backend
      - AWS_ACCESS_KEY_ID=${S3_KEY}
      - AWS_SECRET_ACCESS_KEY=${S3_SECRET}
      - AWS_S3_BUCKET_NAME=my-backups
      - AWS_ENDPOINT=s3.eu-west-1.amazonaws.com
      # GPG symmetric encryption
      - GPG_PASSPHRASE=${GPG_PASSPHRASE}
      # Failure notification via shoutrrr
      - NOTIFICATION_URLS=discord://token@id
      - NOTIFICATION_LEVEL=error
    volumes:
      - appdata:/backup/app:ro
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - /mnt/local-mirror:/archive       # optional local mirror

volumes:
  appdata:
```

## First boot

1. Start → `docker logs -f backup` → confirm cron registered
2. Trigger manual backup: `docker exec backup backup`
3. Verify archive created remotely + locally; check size
4. **Restore test** — critical — download an archive, GPG-decrypt, extract, verify data
5. Set up notification URL + test it (configure an intentional failure)
6. Document the GPG passphrase in your team secret store; ENSURE it's not ONLY in this container

## Data & config layout

- **NO PERSISTENT STATE** inside the container itself — stateless tool
- **Backups** live wherever you configure (local `/archive` + remote S3 etc.)
- **Config** in env vars / `.env` file
- **Docker socket** RO-mounted (needed for container lifecycle management during backup)

## Backup (of the backup tool?)

- DVB itself has no state to back up. The config (env vars / compose file) should be version-controlled (carefully, without secrets in git).
- **GPG passphrase is the CRITICAL artifact** — store in team password manager + offline-paper-copy in a fire-safe.

## Upgrade

1. Releases: <https://github.com/offen/docker-volume-backup/releases>. Active + semver.
2. Pin version in compose (upstream explicitly recommends against `:latest`).
3. **Read release notes for env var changes** — config is stable but evolves.
4. Pull + restart → works.

## Gotchas

- **TEST YOUR RESTORES. SERIOUSLY.** This is the **universal backup warning**. A backup that's never been restored is Schrödinger's backup. Scheduled restore-drills (quarterly) verify:
  - GPG passphrase is still correct + accessible
  - The archive format is still readable
  - Your restore procedure works on a fresh host
  - Data restored is complete + usable
- **SILENT BACKUP FAILURE is the CLASSIC FAILURE MODE**: backup ran, returned 0, but actually skipped a volume / wrote empty archive / failed upload + ignored error. **NOTIFICATION_URLS is not optional** — configure failure-alerts via shoutrrr (Discord/Telegram/email). **Send success notifications too** (or monitor "no success in 25h → alert") — silent-silence is sometimes the failure.
- **`docker-volume-backup.stop-during-backup` LABEL is for INTEGRITY**: live DB files being copied mid-transaction = corrupt backup. Apps MUST be stopped OR have a pre-freeze hook OR dump DB separately before the tar step. **PostgreSQL + MySQL + SQLite all risk corruption with hot file-level copy.** Prefer:
  - Stop container during backup (simple, acceptable for brief downtime)
  - Pre-hook: `pg_dump` / `mysqldump` to a file in the volume, then tar the dump-file
  - Don't file-copy live DB data dirs
- **GPG PASSPHRASE IMMUTABILITY**: **23rd tool in immutability-of-secrets family.** Lose the passphrase = backups unrecoverable. **Multiple copies** of passphrase + test decryption periodically.
  - For asymmetric GPG: the PRIVATE key is what matters for decryption. Back it up separately from backups (if private key is in the same bucket, a bucket compromise = keys + data together).
- **DOCKER SOCKET = ROOT-EQUIVALENT**: DVB mounts `/var/run/docker.sock` (read-write, despite `:ro` on path — socket perms are Docker-side, not filesystem-side, and some commands need write). Attacker with DVB container access = Docker root = host root. **Same warning** as OliveTin 91, pad-ws, xyops, Homarr 89.
  - Mitigation: **docker-socket-proxy** (Tecnativa) — limit DVB to only the API calls it needs (containers list + stop + start). Reduces blast radius.
- **REPLICATION ≠ BACKUP** (reinforces Garage 90 precedent): if you back up to S3 with bucket-replication, a `rm -rf` or ransomware write gets replicated too. **Backups require VERSIONING + OBJECT LOCK + OFFLINE-PROTECTED COPIES** — S3 Object Lock + bucket versioning + separate credentials for backup-restore vs backup-write.
- **3-2-1 BACKUP RULE**: 3 copies, 2 different media, 1 offsite. DVB makes the offsite easy; still need the 2-different-media part. Adding local-archive mount alongside S3 covers 2 media.
- **RANSOMWARE SCENARIO**: attacker with creds to your S3 bucket deletes/encrypts all backups + primary data. Defense:
  - **S3 Object Lock** (WORM for N days) — even bucket-owner can't delete
  - **Separate cred pair** for DVB-write (append-only) vs restore-read
  - **Bucket-versioning** + MFA-delete on versions
  - **Offline copy** periodically (physical disk rotated offsite)
- **BACKUP SIZE GROWTH**: tar.gz is good baseline; **no deduplication** across backup runs. Each backup = full snapshot. For long retention: pair with restic/borg/rustic which dedupe across runs (backup DVB's output to restic).
- **HUB-OF-CREDENTIALS Tier 2**: DVB stores:
  - S3 / WebDAV / Dropbox / Google Drive / SSH credentials for backup targets
  - GPG passphrase or private key
  - Notification webhook URLs
  - **28th tool in hub-of-credentials family — Tier 2 crown-jewel**. Compromise = attacker reads all your backups + can tamper.
- **PERMISSIONS ON BACKUPS**: backup tarballs contain FULL file system perms + uid/gid. When restored, you need the same uid/gid mappings. Document container uid/gid. `--numeric-owner` is used by tar by default in DVB path.
- **COMPLIANCE**: backups often contain personal data (user DB, logs, uploads). **GDPR right-to-erasure** applies to backups too (theoretically) — most orgs handle via retention policies + documented justification for retention-beyond-erasure. Consult legal for regulated industries.
- **"STOPPING CONTAINER BRIEFLY"** pattern: stops apps for ~seconds. For 24/7 critical services: use a replica + rotate backup onto the replica OR use application-level backup (pg_dump over network without stopping DB). DVB supports `exec` hooks to run custom commands.
- **MPL-2.0**: file-level copyleft; fine for self-host + internal + commercial.
- **TRANSPARENT-MAINTENANCE**: offen.software maintains clean release cadence + structured docs + recipes dir + explicit pinning advice in README. **11th tool in transparent-maintenance family.**
- **INSTITUTIONAL-STEWARDSHIP**: offen.software (company) + Frederik Ring (founder). **14th tool in institutional-stewardship, company sub-tier.**
- **ALTERNATIVES WORTH KNOWING:**
  - **restic** — dedup-backup CLI + many backends; widely adopted; BSD-2
  - **Borg** / **Borgmatic** — battle-tested dedup backup
  - **Duplicati** — GUI-first dedup backup; .NET
  - **Kopia** — modern dedup backup; Apache-2
  - **rclone** — file-sync (not dedup-backup) to many targets
  - **Velero** — Kubernetes-native cluster backup
  - **db-backup.sh scripts** — simple app-specific approach
  - **Choose DVB if:** you want SIMPLE + Docker-compose-native + multi-target + GPG + small image + low-skill-barrier.
  - **Choose restic/borg if:** you want DEDUP + encryption + long retention + more efficient storage usage. Pair DVB → restic for best of both.
  - **Choose Velero if:** Kubernetes-primary.
- **Project health**: active + offen.software institutional + MPL-2 + structured-docs + recipes-dir. Strong signals.

## Links

- Repo: <https://github.com/offen/docker-volume-backup>
- Docs: <https://offen.github.io/docker-volume-backup>
- Config reference: <https://offen.github.io/docker-volume-backup/reference/>
- Recipes: <https://offen.github.io/docker-volume-backup/recipes/>
- Docker: <https://hub.docker.com/r/offen/docker-volume-backup>
- restic (alt dedup): <https://restic.net>
- Borg (alt dedup): <https://www.borgbackup.org>
- Borgmatic (Borg wrapper): <https://torsion.org/borgmatic/>
- Duplicati (GUI alt): <https://www.duplicati.com>
- Kopia (alt): <https://kopia.io>
- Velero (k8s alt): <https://velero.io>
- shoutrrr (notifications lib): <https://containrrr.dev/shoutrrr>
- offen.software: <https://www.offen.software>
