---
name: Databasus
description: "Self-hosted database-backup scheduler with UI — Postgres (primary), MySQL, MariaDB, MongoDB. Schedules, GFS retention, AES-256-GCM encryption, multi-destination (S3/R2/GDrive/SFTP/FTP/NAS/Rclone), notifications (Email/Slack/Discord/Telegram/webhooks). Apache-2.0 + commercial tiers."
---

# Databasus

Databasus is **a self-hosted database backup scheduler with a web UI**. Point it at your Postgres/MySQL/MariaDB/MongoDB, pick a schedule (hourly/daily/weekly/monthly/cron), a destination (local/S3/R2/Google Drive/SFTP/Dropbox/rclone), configure encryption + retention, and you get backups on cron with Slack/Discord/email/webhook alerts on success + failure.

Aims to sit in the same space as `pgbackrest`, `backrest`, `restic-cron-scripts` + `n8n-automation`, but with a friendly UI, multi-engine support, and enterprise-grade retention.

Features:

- **Supported databases**:
  - Postgres 12-18
  - MySQL 5.7, 8, 9
  - MariaDB 10, 11, 12
  - MongoDB 4-8
- **Scheduling** — cron + preset (hourly/daily/weekly/monthly)
- **Retention**:
  - Time period (e.g., 7 days, 1 year)
  - Count (keep last N)
  - **GFS (Grandfather-Father-Son)** — hourly + daily + weekly + monthly + yearly layered (enterprise-grade)
  - Size caps — per-backup + total
- **Storage destinations** — Local, S3, Cloudflare R2, Google Drive, Dropbox, NAS, SFTP, Rclone, and more
- **Notifications** — Email, Telegram, Slack, Discord, webhooks
- **Security**:
  - **AES-256-GCM** encryption at rest for backup files
  - Secret encryption in the DB (no plaintext passwords in logs)
  - Read-only DB user recommended (no write perms needed)
- **Zero vendor lock-in** — encrypted backups can be decrypted + restored *without* Databasus (docs on how)
- **Compression** — 4-8× space savings with balanced profile
- **Restore flow** — UI + CLI

- Upstream repo: <https://github.com/databasus/databasus>
- Website: <https://databasus.com>
- Docker Hub: <https://hub.docker.com/r/databasus/databasus>
- Storage destinations: <https://databasus.com/storages>
- Notifier options: <https://databasus.com/notifiers>
- Security docs: <https://databasus.com/security>
- Recovery without Databasus: <https://databasus.com/how-to-recover-without-databasus>

## Architecture in one minute

- **Single binary / single Docker container** — web UI + scheduler + backup runner + storage drivers
- **Uses native `pg_dump` / `mysqldump` / `mongodump`** under the hood — safe, idiomatic tools
- **Internal DB**: SQLite for config + job history (no external DB for Databasus itself)
- **Stateless-ish**: config + job history in a small SQLite file
- **Resource**: small — hundreds of MB RAM; CPU spikes during dump/compress/encrypt

## Compatible install methods

| Infra         | Runtime                                        | Notes                                                                        |
| ------------- | ---------------------------------------------- | ---------------------------------------------------------------------------- |
| Single VM     | **Docker (`databasus/databasus`)**                 | **Upstream-recommended**                                                         |
| Single VM     | Native binary (Linux/macOS/Windows)                         | Cross-platform                                                                             |
| Kubernetes    | Deploy as a single-replica Deployment + PVC                              | Works                                                                                             |
| Raspberry Pi  | arm64 Docker available                                                         | Ideal for backing up home-lab DBs                                                                        |
| Managed       | — (self-host only; commercial tiers are feature unlocks, not hosting)               |                                                                                                                  |

## Inputs to collect

| Input                | Example                           | Phase     | Notes                                                                     |
| -------------------- | --------------------------------- | --------- | ------------------------------------------------------------------------- |
| Domain (if behind proxy) | `backups.example.com`                 | URL       | For UI                                                                            |
| DB connection        | Postgres/MySQL/MongoDB DSN              | Target    | **Use a read-only user** where supported                                                         |
| Storage creds        | S3 access key / R2 token / SFTP / etc.     | Destination | At least one destination                                                                              |
| Encryption key       | random 32 bytes                                   | Security  | **WRITE IT DOWN / STORE OFFLINE** — lose it = lose restore ability                                                      |
| Schedule             | cron `0 3 * * *`                                     | Schedule  | Or preset                                                                                                         |
| Retention            | 7 days / 30 backups / GFS                                | Policy    | Match compliance needs                                                                                                       |
| Notifications        | Telegram bot token, Slack webhook, email              | Alerts    | At least email                                                                                                                        |
| Admin account        | first-run UI                                                   | Bootstrap | Change default                                                                                                                                |

## Install via Docker

```yaml
services:
  databasus:
    image: databasus/databasus:latest            # pin in prod
    container_name: databasus
    restart: unless-stopped
    environment:
      DATABASUS_TZ: America/Los_Angeles
    volumes:
      - ./data:/data                               # SQLite + job state
      - ./backups:/backups                         # local storage destination (if used)
    ports:
      - "3000:3000"                                # web UI
```

Reverse-proxy with Caddy/Traefik for TLS. First-boot creates admin; go through UI.

## First boot

1. Browse UI → create admin
2. Add a **Database source** — host, port, DB name, user (prefer read-only for Postgres/MySQL), password
3. Test connection
4. Add a **Storage destination** — S3 / R2 / local / SFTP / etc.
5. **Generate an encryption key** — save it somewhere safe **outside this server** (1Password, paper safe, offline drive). You **cannot restore without it.**
6. Create a **Backup Job** — source + destination + schedule + retention + encryption + notifications
7. Run a manual test — verify backup appears in destination
8. **Test restore** (seriously — untested backups aren't backups)

## Data & config layout

- `/data/` — SQLite (config + job log)
- `/backups/` — local destination if used (delete offsite after retention)
- Encryption key — **not stored in the DB** per upstream security doc (check current); if on disk, back it up separately

## Backup (Databasus itself)

```sh
# Meta-backup: the backup tool's own data
tar czf db-config-$(date +%F).tgz data/
```

And **document your encryption key recovery process**. Offline. In writing.

## Upgrade

1. Releases: <https://github.com/databasus/databasus/releases>. Active.
2. Back up `/data/`.
3. Docker: bump tag → restart; migrations auto.

## Gotchas

- **The encryption key is sacred.** Lose it, lose every backup that was ever encrypted. Multi-location offline backup (paper, password manager, safety deposit box). **This is the single biggest operational risk** of using encrypted backup tools.
- **Test restores, routinely.** "I back up nightly" ≠ "I can restore." Schedule a quarterly restore drill; script it; document the steps. Backups that haven't been restored are probabilistic fiction.
- **Read-only DB user** — use one. If Databasus' DB credentials get exfiltrated, the attacker shouldn't be able to `DROP TABLE`.
- **Lock down the Databasus UI** — don't expose publicly. It holds DB creds + storage creds + encryption keys. Put behind Authelia/Authentik/VPN/Tailscale.
- **Large DBs**: dumping multi-GB DBs takes time + disk space (even with streaming). Plan maintenance windows; confirm `pg_dump` + `mysqldump` run during that window don't block long-running queries.
- **MongoDB backups** can be huge; `mongodump` is logical (slow). For 100+ GB Mongos, consider `mongodump --oplog` or native filesystem snapshots.
- **Postgres streaming vs `pg_dump`** — Databasus uses `pg_dump` (logical). For WAL-shipping / PITR, use `pgBackRest` / Barman instead.
- **Destination costs**: S3/R2 egress + storage costs can balloon with high-frequency backups. Apply retention + use lifecycle policies (Glacier / cold storage).
- **GFS retention** — understand the math: hourly × 24 + daily × 7 + weekly × 4 + monthly × 12 = 47+ concurrent backups per DB. Set size caps.
- **Notification noise**: failure alerts are critical; success alerts can be daily fatigue. Configure success-only-on-schedule (e.g., weekly summary).
- **Time zone**: set `DATABASUS_TZ` explicitly; otherwise cron schedules are in UTC and confuse humans.
- **Network**: Databasus must reach the DB server + the storage destination. Firewall accordingly.
- **Decryption without Databasus**: upstream supports this — encryption scheme documented. Keep a copy of that doc + the decryption CLI/script alongside your offsite backups.
- **License**: Apache-2.0 for the core; **commercial tiers** for some enterprise features (check current state — the project has free vs paid tiers with some features gated).
- **Alternatives worth knowing:**
  - **pgBackRest** — Postgres-specific; WAL shipping + full/diff/incremental; industry standard (separate recipe likely)
  - **Barman** — Postgres streaming replication-based backup
  - **WAL-G** — continuous archiving for Postgres/MySQL/SQL Server
  - **Percona XtraBackup** — MySQL/MariaDB hot backup
  - **MongoDB: `mongodump` + your own cron** / MongoDB Atlas Continuous Backup (commercial)
  - **AutoMySQLBackup** — old-school MySQL cron script
  - **pgbackweb** — similar Postgres-centric web UI for pg_dump (separate recipe likely)
  - **Restic + cron + custom scripts** — DIY; encryption + storage backend built in
  - **Borgbackup + borgmatic** — FS-level, deduplicated
  - **Kopia** — cross-platform, modern
  - **Duplicati** — cross-platform, user-friendly (separate recipe)
  - **BackBlaze B2 / AWS Backup service** — cloud-native
  - **Choose Databasus if:** you want a UI-driven multi-DB backup scheduler with encryption, retention, notifications.
  - **Choose pgBackRest/Barman/WAL-G if:** you're Postgres-only + need PITR.
  - **Choose Restic/Borg/Kopia if:** you want filesystem-level dedupe + will script the DB dumps yourself.

## Links

- Repo: <https://github.com/databasus/databasus>
- Website: <https://databasus.com>
- Docker Hub: <https://hub.docker.com/r/databasus/databasus>
- Features / Storages: <https://databasus.com/storages>
- Notifiers: <https://databasus.com/notifiers>
- Security: <https://databasus.com/security>
- Recover without Databasus: <https://databasus.com/how-to-recover-without-databasus>
- Releases: <https://github.com/databasus/databasus/releases>
- pgBackRest (alt): <https://pgbackrest.org>
- WAL-G (alt): <https://github.com/wal-g/wal-g>
- pgbackweb (alt): <https://github.com/eduardolat/pgbackweb>
- Restic (alt): <https://restic.net>
