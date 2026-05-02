---
name: backups
description: Cross-cutting backup module for open-forge — restic / BorgBackup / native cloud-snapshot patterns for protecting recipe data dirs. Loaded by recipes that have persistent state (Postgres / SQLite / file uploads / vector DB / config dirs). Default recommendation is restic to S3-compatible object storage; falls through to borg + Backblaze B2 for self-hosted-feel storage; cloud-snapshot patterns documented for users on AWS / Azure / GCP / Hetzner where the cloud's own snapshot APIs are sufficient.
---

# Backups module

Every recipe that lives long enough to matter has data worth losing. This module covers the cross-cutting backup patterns recipes can reference instead of inventing per-recipe backup strategies.

> **Operating Principle reminder.** Per CLAUDE.md operating principle #2 (*"Towards production-ready architecture"*): even single-node hobby deploys should be on a path to backups. Don't write recipes that "work" but leave the system one outage away from data loss.

## What needs backing up — per recipe

Each recipe should specify its **backup-relevant paths** in the recipe body (typically a "Backup" section after "Lifecycle"). Common categories:

| Category | Examples | Notes |
|---|---|---|
| **Database** | Postgres, MySQL, MariaDB, SQLite | Use the DB's native dump tool; don't snapshot live DB files (corrupt-on-restore risk) |
| **Object / file storage** | Image uploads, attachments, document store, vector-DB on-disk files | File-level backup (restic / borg) is fine if the app stops cleanly first |
| **Configuration** | `.env`, `config.production.json`, `secrets/` | Often small but mandatory — without these the restored DB can't be decrypted |
| **Encryption keys** | `APP_KEY` (Laravel), `SECRET_KEY` (Django), JWT signing keys | Required for decrypting DB-stored encrypted fields, sessions, tokens |
| **Generated certificates** | Let's Encrypt private keys when not auto-renewed | Usually regenerable; backup is a convenience |
| **State files** | `~/.open-forge/deployments/<name>.yaml` | Helpful for resume after disaster recovery; not catastrophic if lost |

The recipe states which paths fall in which category. This module covers **how** to back them up.

## Choosing a backup approach

| Approach | When to pick | Effort |
|---|---|---|
| **Cloud-native snapshots** (AWS EBS, Azure Disk, GCP PD, Hetzner Cloud Volumes) | Single-cloud deploy where the cloud already does what you need | Lowest — UI-driven, no install |
| **`restic` to S3-compatible object storage** | Most setups; cross-cloud portable; works against AWS S3, Backblaze B2, Wasabi, Cloudflare R2, MinIO, self-hosted SeaweedFS | Low — single binary, simple repo init |
| **`borg` (BorgBackup) + `borgmatic`** | Power users wanting deduplication + compression; self-hosted backup server (or rsync.net / BorgBase) | Medium — borg is more featureful, more concepts |
| **`pgBackRest` / `wal-g`** | Production Postgres needing PITR (point-in-time recovery) and WAL archiving | High — only worth it when you have a real ops budget |
| **Application-level backup** (Ghost-CLI's `ghost backup`, Vaultwarden's `vaultwarden_backup.sh`, etc.) | When upstream ships its own backup tool — usually best, since it knows the app's invariants | Medium — varies per app |

**Default recommendation for open-forge recipes**: `restic` to S3-compatible storage. Single binary, deterministic repo format, encryption + deduplication built-in, ubiquitously supported.

---

## Pattern 1 — restic to S3-compatible storage (recommended default)

> **Source**: <https://restic.readthedocs.io/en/stable/030_preparing_a_new_repo.html#amazon-s3>

### Install

```bash
# macOS / Linux
brew install restic
# OR
curl -sSL https://github.com/restic/restic/releases/latest/download/restic_$(uname -s)_amd64.bz2 \
  | bunzip2 > /usr/local/bin/restic && chmod +x /usr/local/bin/restic

restic version
```

Many distros ship restic in their package managers (`apt install restic`, `dnf install restic`); confirm it's >= 0.16 (older versions miss some features).

### Init the repo

Choose any S3-compatible backend; the URL shape is the same:

```bash
# AWS S3
export AWS_ACCESS_KEY_ID=<key>
export AWS_SECRET_ACCESS_KEY=<secret>
export RESTIC_REPOSITORY=s3:s3.amazonaws.com/<bucket-name>/<deployment-name>
export RESTIC_PASSWORD=$(openssl rand -hex 32)   # store this in your password manager

# Backblaze B2 (cheap, S3-compatible since 2022)
export AWS_ACCESS_KEY_ID=<b2-key-id>
export AWS_SECRET_ACCESS_KEY=<b2-app-key>
export RESTIC_REPOSITORY=s3:s3.us-west-002.backblazeb2.com/<bucket>/<deployment-name>

# Wasabi
export RESTIC_REPOSITORY=s3:s3.wasabisys.com/<bucket>/<deployment-name>

# Cloudflare R2 — endpoint includes account ID
export RESTIC_REPOSITORY=s3:<account-id>.r2.cloudflarestorage.com/<bucket>/<deployment-name>

# MinIO (self-hosted)
export RESTIC_REPOSITORY=s3:https://minio.example.com/<bucket>/<deployment-name>

# Initialize (one-time)
restic init
```

**Save the `RESTIC_PASSWORD` outside the host you're backing up.** The repo is encrypted at rest with this password; lose it and the backup is unrecoverable.

### Back up

The recipe specifies which paths to back up. Generic shape:

```bash
# Stop the app cleanly first, OR use the app's native dump-while-live tool
docker compose stop <service>

# Snapshot files
restic backup \
  /opt/<deployment>/data \
  /opt/<deployment>/config \
  --tag $(date +%Y-%m-%d) \
  --tag <deployment-name>

# Restart
docker compose start <service>
```

For databases, **always use the native dump tool** rather than snapshotting live files:

```bash
# Postgres
docker compose exec -T db pg_dump -U <user> <db> | gzip > /tmp/db-$(date +%F).sql.gz
restic backup /tmp/db-*.sql.gz --tag db --tag <deployment-name>
rm /tmp/db-*.sql.gz

# MySQL / MariaDB
docker compose exec -T db mariadb-dump -u <user> -p"$DB_PASSWORD" <db> | gzip > /tmp/db-$(date +%F).sql.gz
restic backup /tmp/db-*.sql.gz --tag db --tag <deployment-name>
rm /tmp/db-*.sql.gz

# SQLite (must use sqlite3 .backup, NOT cp — live cp can corrupt)
sqlite3 /path/to/app.db ".backup /tmp/app-$(date +%F).db"
restic backup /tmp/app-*.db --tag db --tag <deployment-name>
rm /tmp/app-*.db
```

### Schedule

Two patterns:

**Systemd timer** (Linux server with system access):

```ini
# /etc/systemd/system/open-forge-backup.service
[Unit]
Description=open-forge backup for <deployment-name>
After=docker.service

[Service]
Type=oneshot
EnvironmentFile=/etc/open-forge/<deployment-name>.env
ExecStart=/usr/local/bin/open-forge-backup-<deployment-name>.sh
```

```ini
# /etc/systemd/system/open-forge-backup.timer
[Unit]
Description=Daily backup for <deployment-name>

[Timer]
OnCalendar=daily
RandomizedDelaySec=15m
Persistent=true

[Install]
WantedBy=timers.target
```

Enable: `systemctl enable --now open-forge-backup.timer`.

**Cron** (simpler when systemd isn't available):

```cron
# /etc/cron.d/open-forge-backup
0 3 * * * root /usr/local/bin/open-forge-backup-<deployment-name>.sh >> /var/log/open-forge-backup.log 2>&1
```

### Retention

```bash
restic forget \
  --keep-daily 7 \
  --keep-weekly 4 \
  --keep-monthly 6 \
  --keep-yearly 2 \
  --tag <deployment-name> \
  --prune    # actually delete forgotten snapshots from the repo
```

Run `forget --prune` weekly (separately from `backup`) — it can take a while on large repos.

### Verify

```bash
# Quick sanity check — list snapshots
restic snapshots --tag <deployment-name>

# Full integrity check (slow; do periodically, e.g. monthly)
restic check --read-data-subset=10%
```

### Restore

```bash
# To original paths
restic restore latest --target / --tag <deployment-name>

# To a different path (for testing or DR drill)
restic restore latest --target /tmp/restore-test --tag <deployment-name>

# Then for DBs, replay the dump:
gunzip < /tmp/restore-test/tmp/db-*.sql.gz | docker compose exec -T db psql -U <user> <db>
```

**Test restores at least quarterly.** A backup you've never restored is a hope, not a backup.

---

## Pattern 2 — Cloud-native snapshots (lowest effort)

If the deploy is on a single cloud and you don't need cross-cloud portability, the cloud's native snapshot APIs are usually sufficient and require no install.

| Cloud | Snapshot UI / CLI | Granularity |
|---|---|---|
| **AWS** | EC2 / Lightsail console → Snapshots; or `aws ec2 create-snapshot` | EBS volume |
| **Azure** | Portal → Disk → Create snapshot; or `az snapshot create` | Managed disk |
| **GCP** | Console → Compute → Snapshots; or `gcloud compute disks snapshot` | Persistent disk |
| **Hetzner Cloud** | hcloud Console → Server → Snapshots; or `hcloud server create-image` | Whole server (image) or volume |
| **DigitalOcean** | Control panel → Droplet → Snapshots; or `doctl compute droplet-action snapshot` | Whole droplet or volume |

**Pros**: Zero install, deeply integrated with the cloud's recovery tools.
**Cons**: Locked to one cloud; harder to cross-restore; usually billed by snapshot size + storage class; encryption is the cloud's, not yours.

For DBs running on the snapshot'd disk: stop the DB cleanly before snapshot, OR use the DB-aware snapshot mechanism (e.g. RDS automated snapshots) — file-level snapshot of live DB files is **not safe** without filesystem-level freeze (`fsfreeze`).

### Schedule

Most clouds offer scheduled snapshot policies:

- **AWS**: Data Lifecycle Manager (DLM)
- **Azure**: Azure Backup vaults (cross-resource)
- **GCP**: Snapshot schedules attached to a disk
- **Hetzner**: Manual or via CLI cron
- **DigitalOcean**: Backups (weekly, paid add-on, flat 20% of droplet cost)

---

## Pattern 3 — BorgBackup + borgmatic (power-user)

> **Source**: <https://borgbackup.readthedocs.io/en/stable/quickstart.html> + <https://torsion.org/borgmatic/>

When restic isn't enough — typically when you want server-side append-only mode, more aggressive deduplication across overlapping backups, or a managed Borg target like [BorgBase](https://www.borgbase.com/) or rsync.net.

### Install

```bash
sudo apt install borgbackup borgmatic     # Debian / Ubuntu
brew install borgbackup borgmatic         # macOS
# or grab single-file binary from
# https://github.com/borgbackup/borg/releases
```

### Init the repo

```bash
# Local repo
borg init --encryption=repokey-blake2 /backup/borg-repo

# Remote (BorgBase, rsync.net, your own SSH host)
borg init --encryption=repokey-blake2 ssh://<user>@<host>:<port>/<path>/borg-repo
```

You'll be prompted for a passphrase; **store it outside the backed-up host**.

### Configure borgmatic

`/etc/borgmatic/config.yaml`:

```yaml
location:
  source_directories:
    - /opt/<deployment>/data
    - /opt/<deployment>/config
  repositories:
    - path: ssh://<user>@<host>/<path>/borg-repo

storage:
  encryption_passphrase: "${BORG_PASSPHRASE}"
  compression: zstd
  archive_name_format: '<deployment>-{now:%Y-%m-%dT%H:%M:%S}'

retention:
  keep_daily: 7
  keep_weekly: 4
  keep_monthly: 6

consistency:
  checks:
    - name: repository
      frequency: 4 weeks
    - name: archives
      frequency: 4 weeks

hooks:
  before_backup:
    - docker compose -f /opt/<deployment>/docker-compose.yml stop <service>
    - docker compose -f /opt/<deployment>/docker-compose.yml exec -T db pg_dump -U <user> <db> | gzip > /tmp/db-{now:%Y%m%d}.sql.gz
  after_backup:
    - rm /tmp/db-*.sql.gz
    - docker compose -f /opt/<deployment>/docker-compose.yml start <service>
```

Schedule: `systemctl enable --now borgmatic.timer` (ships with the borgmatic package).

---

## Pattern 4 — Application-level backup tools

Some recipes ship their own backup tool — that's almost always preferable to a generic file-level approach because the upstream tool knows the app's invariants (e.g. flushing in-memory caches, locking write-paths, dumping in a restorable format).

When this exists, the recipe should reference it in its **Backup** section. Examples already in the catalog:

- **Ghost** (`ghost.md`): Bitnami blueprint variant uses `ghost backup` (Ghost-CLI subcommand) which packages the DB + content directory + theme files into a single tarball.
- **Vaultwarden** (`vaultwarden.md`): community-maintained `vaultwarden_backup.sh` script handles SQLite+Postgres modes plus `attachments/`, `sends/`, and `rsa_key.*` files.
- **Nextcloud**: built-in `occ maintenance:mode` + `mysqldump` + filesystem snapshot pattern, scriptable.

Recipes should prefer these over generic restic backups when they exist.

---

## Recipe integration pattern

Recipes reference this module from a `## Backup` section (typically after `## Lifecycle` and before `## Gotchas`). Standard shape:

```markdown
## Backup

What needs preserving for `<recipe>`:

| Category | Path | Notes |
|---|---|---|
| Database | `/opt/<deployment>/db-data/` | Use `pg_dump` not file copy |
| Uploads | `/opt/<deployment>/uploads/` | Safe to copy live |
| Config | `/opt/<deployment>/.env` | Required for restore |
| Encryption key | `/opt/<deployment>/.env` (`APP_KEY=`) | Required for restore — store separately too |

Default approach: `restic` to S3-compatible storage — see [`references/modules/backups.md`](../modules/backups.md) § *Pattern 1*.

If on a single cloud, cloud-native snapshots are simpler — see [`references/modules/backups.md`](../modules/backups.md) § *Pattern 2*.

Recipe-specific gotchas:

- [List any app-specific quirks: e.g. "stop the app before snapshot",
  "use `<app> backup` rather than file copy", "restore order matters: schema before data"]
```

---

## Disaster recovery drill (recommended quarterly)

A backup that's never been restored is a hope, not a backup. Quarterly:

1. Provision a fresh instance per the recipe (different deployment name).
2. Restore the latest backup to it (`restic restore latest --target /opt/<test-deployment>`).
3. Bring up the app pointing at the restored data.
4. Smoke-test: log in, view a known-recent record, post-create-and-verify.
5. Tear down the test instance.

Record the date + outcome in the deployment state file (`~/.open-forge/deployments/<name>.yaml` → `last_dr_drill: 2026-XX-XX`).

---

## Common gotchas (cross-cutting)

- **Encryption-key loss = total loss.** restic / borg / Vaultwarden / Ghost — all encrypt the backup with a key you set. Lose the key and the backup is cryptographically inaccessible. Store keys in a password manager *and* a printed offline copy for catastrophic-recovery scenarios.
- **DB file-copy is unsafe on a running DB.** Always use the native dump tool, OR stop the DB cleanly first, OR use a filesystem-level freeze (`fsfreeze`) — never raw `cp` of a live DB file.
- **First-restore-failure pattern.** Most backup-restore failures are discovered on the first restore — and that's usually the worst possible time. Run a DR drill before you need it.
- **Retention != cost control.** restic + B2 / Wasabi at default retention (7d/4w/6m/2y) for typical recipes is well under $1/mo for most workloads. Don't skimp on retention to save pennies.
- **Test from a different machine.** Restoring on the same host that has the source files isn't really a DR test — it doesn't exercise the credential-recovery / network-recovery paths. Restore to a fresh VM occasionally.
- **State-file dependency.** `~/.open-forge/deployments/<name>.yaml` records the deployment's inputs (domain, AWS profile, etc.). Back it up too — losing it doesn't break the running deploy but makes resume / DR much harder.

---

## TODO — verify on subsequent deployments

- [ ] Verify the systemd-timer + borgmatic-timer paths on real deployments — different distros ship them differently.
- [ ] Add per-cloud snapshot-API examples (currently the cloud-snapshots section is text-only; could include a copy-paste `aws ec2 create-snapshot --volume-id ...` per cloud).
- [ ] Document `pgBackRest` setup as Pattern 5 once a recipe needs it (currently nothing in the catalog requires PITR).
- [ ] Verify the Wasabi / R2 / B2 endpoint URLs at first deploy — these change occasionally.
- [ ] Pair with `references/modules/monitoring.md` (when written) for backup-success alerting (a missed backup that no one notices is the same as no backup).
