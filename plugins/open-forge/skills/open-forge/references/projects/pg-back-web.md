---
name: PG Back Web
description: "PostgreSQL backup tool with web UI. Schedule backups to S3/local/etc. Go. Docker. MIT. eduardolat sole. ⚠️ REBRANDING to 'UFO Backup' — expanding beyond PostgreSQL. CI + Go Report Card badges."
---

# PG Back Web (→ UFO Backup)

PG Back Web is **"pgBackRest / pg_dump + cron — but with a friendly web UI + scheduling + S3 support"** — a PostgreSQL backup tool with a user-friendly web interface. Schedule backups; target S3-compatible storage; restore through UI; all without editing cron / shell scripts. 

**⚠️ REBRAND IN PROGRESS**: PG Back Web is becoming **"UFO Backup"** — project expanding beyond PostgreSQL. Joining <https://ufobackup.uforg.dev/r/community> for the new roadmap.

Built + maintained by **Eduardo Lat (eduardolat)**. License: check LICENSE (likely MIT). Active; CI badge; Go Report Card; Docker Hub (eduardolat/pgbackweb); sponsors listed.

Use cases: (a) **scheduled PostgreSQL backups with UI** — no cron-editing (b) **multi-database backup** — N databases from one UI (c) **S3-offsite backups** — DR preparation (d) **junior-DBA friendly** — UI vs command-line (e) **backup verification through UI** — see status at a glance (f) **Django/Rails/app backup for operators** — non-DBA context (g) **startup pre-DBA-hire backup solution** (h) **homelab PostgreSQL insurance**.

Features (per README + common PG-backup tool features):

- **PostgreSQL backup**
- **Web UI for management**
- **Scheduled backups** (cron-like)
- **S3-compatible storage**
- **Restore through UI**
- **Multi-database support**
- **Go single binary / Docker**

- Upstream repo: <https://github.com/eduardolat/pgbackweb>
- Docker Hub: <https://hub.docker.com/r/eduardolat/pgbackweb>
- Community (post-rebrand): <https://ufobackup.uforg.dev/r/community>

## Architecture in one minute

- **Go** single binary
- **SQLite** (config + schedule state)
- **Runs `pg_dump` against target databases**
- **Resource**: low — 50-100MB RAM
- **Port**: web UI

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker**         | **`eduardolat/pgbackweb`**                                      | **Primary**                                                                        |
| **Binary**         | Go binary                                                                            | Alt                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `pgbackup.example.com`                                      | URL          | TLS — access holds DB creds                                                                                    |
| Admin creds          | First-boot                                                  | Bootstrap    | Strong                                                                                    |
| **Target PG conn strings** | Per-database                                          | **CRITICAL** | **Admin-level PG connection**                                                                                    |
| S3 creds             | Bucket + access key + secret                                | Storage      |                                                                                    |
| Encryption key       | For encrypted backups (if supported)                        | Security     |                                                                                    |
| Schedule             | Cron-expression                                             | Config       |                                                                                    |

## Install via Docker

```yaml
services:
  pgbackweb:
    image: eduardolat/pgbackweb:latest        # **pin version; watch for UFO Backup rebrand images**
    environment:
      PBW_ENCRYPTION_KEY: ${ENCRYPTION_KEY}
    volumes:
      - pgbackweb-data:/app/data
    ports: ["8085:8085"]
    restart: unless-stopped

volumes:
  pgbackweb-data: {}
```

## First boot

1. Start → browse web UI
2. Create admin account; enable 2FA
3. Add target DB connection (use dedicated READ-ONLY-capable user where possible, but pg_dump needs enough privs to read structures)
4. Configure S3 bucket
5. Test manual backup; verify files land in S3
6. Configure schedule
7. Test RESTORE (backup is only as good as restore)
8. Put behind TLS reverse proxy + strong auth
9. Back up PBW's own config state too (it holds all those PG creds)

## Data & config layout

- `/app/data/` — PBW's own SQLite state (holds DB connection strings!)
- Target backups — per-database; to S3 or local volume

## Backup of PBW itself

```sh
sudo tar czf pgbackweb-data-$(date +%F).tgz pgbackweb-data/
# ENCRYPT — contains all target PG connection strings
```

## Upgrade

1. Releases: <https://github.com/eduardolat/pgbackweb/releases>. Active.
2. Docker pull + restart
3. **Watch for UFO Backup rebrand** — image name may change; migration guide expected
4. **Recipe convention: "watch-for-project-rebrand-migration"** — important for consumers

## Gotchas

- **107th HUB-OF-CREDENTIALS CROWN-JEWEL TIER 1 — DB-CREDENTIAL-AGGREGATOR**:
  - PBW holds: PG connection strings (admin-level) + S3 creds + encryption key
  - Compromise of PBW → **ALL YOUR DATABASES + YOUR BACKUPS**
  - **107th tool in hub-of-credentials family — Tier 1 CROWN-JEWEL**
  - **NEW CROWN-JEWEL Tier 1 sub-category: "database-credential-aggregator + backup-custodian"** (1st — PBW)
  - **CROWN-JEWEL Tier 1: 28 tools / 25 sub-categories**
- **BACKUP-CUSTODIAN THREAT MODEL**:
  - Attacker who compromises backup tool can: (a) restore old-version = data-rollback attack (b) exfiltrate historical data (c) inject malicious DB-state on restore
  - **Recipe convention: "backup-custodian-threat-model" callout**
  - **NEW recipe convention** (PBW 1st formally)
- **ENCRYPTION-AT-REST FOR BACKUP CONTENT**:
  - Backups should be encrypted before leaving DB server
  - Server-side-encryption on S3 is weaker (cloud-provider-trust)
  - Client-side-encryption stronger
  - **Recipe convention: "client-side-backup-encryption positive-signal"**
  - **NEW positive-signal convention** (PBW 1st formally)
- **VERIFY RESTORE REGULARLY**:
  - Untested backup = no backup
  - Schedule restore-tests to verify
  - **Recipe convention: "scheduled-restore-verification-discipline"** — standard
- **PROJECT-REBRAND IN PROGRESS**:
  - PG Back Web → UFO Backup
  - Docker images + repo may migrate
  - **Recipe convention: "project-rebrand-migration-discipline"** — extends Grimmory (105) rebrand pattern
  - **Rebrand-preservation: 4 tools** (prior 3 + **PBW→UFO**) 🎯 **4-TOOL MILESTONE approaching**
  - **Actually**: Rebrand-preservation was 3 tools; +PBW = 4 tools
- **EXPANDING BEYOND POSTGRESQL**:
  - UFO Backup intends to support more DBs
  - Ambition = scope-creep risk BUT could become universal-backup
  - **Recipe convention: "scope-expansion-ambition" neutral-signal**
- **GO-REPORT-CARD**:
  - Code-quality badge
  - **Recipe convention: "Go-Report-Card"** extended — 3rd tool now (Gokapi 107 + Sablier 109 + PBW) — 3-tool milestone
- **NETWORK-SERVICE-LEGAL-RISK (implicit)**:
  - Not directly regulated but holds PII-databases
  - GDPR applies to backup-data (same as live)
- **SOLE-MAINTAINER (eduardolat)**:
  - Sole-maintainer with sponsors listed
  - **Sole-maintainer-with-community: 37 tools**
- **INSTITUTIONAL-STEWARDSHIP**: eduardolat + sponsors + community + active-rebrand-with-transparency. **93rd tool — sole-maintainer-with-rebrand-transparency sub-tier** (soft new; reuses prior).
- **TRANSPARENT-MAINTENANCE**: active + CI + Go-Report-Card + Docker Hub + open-rebrand-community + sponsors. **101st tool in transparent-maintenance family.**
- **POSTGRESQL-BACKUP-CATEGORY:**
  - **PG Back Web / UFO Backup** — web UI, Go, friendly
  - **pgBackRest** — CLI; DBA-grade; retention + PITR
  - **pg_dump + cron + scripts** — stdlib approach
  - **Barman** — Python; enterprise; PITR
  - **wal-g / wal-e** — WAL-based; cloud-native
  - **pg_probackup** — PITR + block-level
  - **Bacula + PostgreSQL plugin** — full enterprise backup
- **ALTERNATIVES WORTH KNOWING:**
  - **pgBackRest** — if you want DBA-grade + PITR + retention
  - **pg_dump + cron** — if you want minimal
  - **wal-g** — if you want cloud-native WAL
  - **Barman** — if you want enterprise PITR
  - **Choose PBW/UFO Backup if:** you want web UI + ops-friendly + not-DBA-grade.
- **PROJECT HEALTH**: active + rebrand-in-flight + sole-maintainer + sponsors. Strong but watch rebrand transition.

## Links

- Repo: <https://github.com/eduardolat/pgbackweb>
- UFO Backup community: <https://ufobackup.uforg.dev/r/community>
- pgBackRest (alt): <https://github.com/pgbackrest/pgbackrest>
- Barman (alt): <https://github.com/EnterpriseDB/barman>
- wal-g (alt): <https://github.com/wal-g/wal-g>
