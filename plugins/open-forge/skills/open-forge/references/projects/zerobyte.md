---
name: Zerobyte
description: "Self-hosted backup automation for remote storage — web UI layered over Restic. Schedules, retention policies, E2E encryption, compression, multi-protocol sources (NFS/SMB/WebDAV/SFTP/local). By nicotsx (Runtipi creator). Pre-1.0 — expect changes."
---

# Zerobyte

Zerobyte is **a web-UI wrapper around [Restic](https://restic.net)** for scheduling encrypted, compressed, retention-policied backups across multiple remote storage protocols. If you've been running Restic from cron and want a dashboard — schedules, job history, restore UI, email/webhook alerts — Zerobyte is that.

By **nicotsx**, the developer behind [Runtipi](https://runtipi.io). Pre-1.0 (`0.x.x`) — active, changing, not yet production-hardened.

> **⚠️ Pre-1.0 warning (from upstream README):**
>
> > Zerobyte is still in version 0.x.x and is subject to major changes from version to version. I am developing the core features and collecting feedbacks.
>
> Expect breaking config changes across minor versions. Pin image tags. Read release notes before upgrading.

Features:

- **Restic-backed** — proven, widely-used backup engine under the hood
- **End-to-end encryption** — Restic native (AES-256)
- **Compression** — Restic native (zstd)
- **Multi-protocol sources** — NFS, SMB/CIFS, WebDAV, SFTP, local dirs
- **Multi-destination** — any Restic-compatible backend (local, SFTP, S3, B2, Azure, GCS, Swift, rclone proxy)
- **Flexible scheduling** — cron + preset
- **Retention policies** — Restic's `forget --keep-*` semantics
- **Web UI** — scheduling, history, restore browser, logs
- **Provisioning** — JSON file to bootstrap repos + volumes from deployment config (for GitOps)
- **Notifications** (check current — evolving)

- Upstream repo: <https://github.com/nicotsx/zerobyte>
- Website / docs: <https://zerobyte.app>
- Provisioning docs: <https://zerobyte.app/docs/guides/provisioning>
- Discord: <https://discord.gg/XjgVyXrcEH>
- Docker image: `ghcr.io/nicotsx/zerobyte`

## Architecture in one minute

- **Single container** (`ghcr.io/nicotsx/zerobyte`)
- **Needs `SYS_ADMIN` cap + `/dev/fuse`** — to mount remote sources (SMB/NFS/WebDAV) for backup
- **Internal DB**: SQLite-ish in `/var/lib/zerobyte`
- **Wraps Restic** — each "repository" = a Restic repo on a backend
- **Wraps rclone** for remote-source mounting

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                           |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------- |
| Single VM          | **Docker (`ghcr.io/nicotsx/zerobyte`)**                            | **Only supported path**                                                             |
| TrueNAS            | Docker — **use ZFS dataset, NOT `/var/lib`**                                   | Upstream call-out (see gotchas)                                                               |
| Kubernetes         | Possible (needs privileged for FUSE)                                                      | Not the target                                                                                           |
| Raspberry Pi       | arm64 image                                                                                          | Fine for small-scale                                                                                                  |
| Managed            | — (no SaaS; not recommended to expose publicly per upstream)                                                        |                                                                                                                                   |

## Inputs to collect

| Input                | Example                                | Phase       | Notes                                                                      |
| -------------------- | -------------------------------------- | ----------- | -------------------------------------------------------------------------- |
| BASE_URL             | `http://localhost:4096`                    | Required    | URL used to access Zerobyte                                                                |
| APP_SECRET           | `openssl rand -hex 32`                          | Required    | Encrypts sensitive DB fields (repo creds, etc.)                                                             |
| Port                 | `4096`                                                 | Network     | Default                                                                                                     |
| TZ                   | `America/Los_Angeles`                                       | Schedule    | **Crucial** for accurate cron                                                                                                        |
| Volume (source)      | `/mnt/important-data`                                              | Source      | Mounted read-only into container                                                                                                              |
| Storage backend      | S3 / B2 / SFTP / local                                                       | Destination | Restic repo init                                                                                                                                         |
| Restic repo password | long random                                                                            | Security    | **Save it** — lose it = lose backups (same imperative as Databasus)                                                                                                                                           |
| TRUST_PROXY          | `true` if behind Caddy/Traefik                                                                         | Network     | Honors X-Forwarded-For                                                                                                                                                                                 |
| TRUSTED_ORIGINS      | comma-separated CORS                                                                                            | CORS        | For custom frontends                                                                                                                                                                                                  |

## Install via Docker Compose

Straight from upstream README:

```yaml
services:
  zerobyte:
    image: ghcr.io/nicotsx/zerobyte:v0.35            # pin
    container_name: zerobyte
    restart: unless-stopped
    cap_add:
      - SYS_ADMIN
    ports:
      - "127.0.0.1:4096:4096"                          # ← bind to localhost only; expose via reverse proxy
    devices:
      - /dev/fuse:/dev/fuse
    environment:
      TZ: America/Los_Angeles
      BASE_URL: https://zerobyte.example.com
      APP_SECRET: ${APP_SECRET}                         # openssl rand -hex 32
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - /var/lib/zerobyte:/var/lib/zerobyte
      - /mnt/data:/mnt/data:ro                          # mount sources read-only
```

### TrueNAS users — critical warning

**Do NOT use `/var/lib/zerobyte:/var/lib/zerobyte` on TrueNAS** — that host path is ephemeral and **wiped on system upgrades**. Create a ZFS dataset:

```yaml
volumes:
  - /mnt/tank/docker/zerobyte:/var/lib/zerobyte
```

Your configs, encryption keys, and DB persist across TrueNAS upgrades this way. This is called out explicitly in the upstream README — don't skim past it.

### Network share as `/var/lib/zerobyte` — don't

Upstream warns: **do NOT point `/var/lib/zerobyte` at an NFS/SMB share.** Permission issues + severe performance degradation.

## First boot

1. Browse UI (usually via reverse proxy) → setup wizard
2. Create admin account
3. **Add a Repository** (Restic destination): S3 / SFTP / B2 / etc. — set repo password (**save it**)
4. **Add a Volume** (backup source): local path or remote mount (SMB/NFS/WebDAV/SFTP)
5. **Create a Backup Job** — volume + repository + schedule + retention
6. Run manually — verify snapshot
7. **Test restore** — pick a file in UI, restore to a test dir, diff against source

## Data & config layout

- `/var/lib/zerobyte/` — SQLite DB + configs + rclone configs + restic caches
- `/mnt/data/` (or wherever) — your backup sources (mounted read-only)
- Restic repos live on their destination (S3/SFTP/local)

## Backup (meta)

```sh
# Back up Zerobyte's own state (stop first for consistency)
docker compose stop zerobyte
sudo tar czf zb-config-$(date +%F).tgz /var/lib/zerobyte/
docker compose start zerobyte
```

And **the Restic repo passwords must be stored offline** — that's the real backup-of-a-backup-system discipline.

## Upgrade

1. Releases: <https://github.com/nicotsx/zerobyte/releases>. **Active but pre-1.0** — breaking changes per minor.
2. **Read release notes before pulling**. Pin to specific tags.
3. Back up `/var/lib/zerobyte/` before upgrading.

## Gotchas

- **Pre-1.0 status** — call it out with your stakeholders. Breaking changes between `0.34` → `0.35` have happened; will happen again. Not a "set and forget" yet.
- **Don't expose publicly.** Upstream explicitly warns: "It is highly discouraged to run Zerobyte on a server that is accessible from the internet." If you must, bind to `127.0.0.1:4096:4096` + reverse-proxy with strong auth (Authelia/Authentik) + HTTPS. The UI holds repo creds + encryption keys.
- **TrueNAS `/var/lib` is ephemeral** — use a ZFS dataset instead. Upstream README-level warning; easy to miss.
- **Network share as `/var/lib/zerobyte`** — don't. Permission + perf.
- **Restic repo password is the kingdom key** (same as Databasus's encryption key). Lose it = lose every backup. Offline, multiple locations, password manager + paper.
- **FUSE + SYS_ADMIN cap** — required for mounting remote sources. Can't run on Docker setups that disallow these (some hardened k8s).
- **Test restores** (same as Databasus). Schedule quarterly drills. Untested backups are probabilistic fiction.
- **Remote source permissions**: Zerobyte mounts NFS/SMB as root-in-container; credentials to those shares stored in Zerobyte DB encrypted by `APP_SECRET`. Losing `APP_SECRET` = can't decrypt stored creds.
- **Source paths vs volume paths**: UI shows container paths. Mount hosts read-only; document the mapping.
- **Retention math**: Restic's `forget --keep-daily 7 --keep-weekly 4 --keep-monthly 12` is powerful but confusing. Understand before trusting auto-prune.
- **Time zone** — `TZ` env var is crucial; cron schedules default UTC otherwise + humans get confused.
- **Multi-user**: not at 0.x — single operator assumed.
- **Provisioning via JSON** — cool GitOps feature; declaratively define repos + volumes outside the UI. See <https://zerobyte.app/docs/guides/provisioning>.
- **Logging**: set `LOG_LEVEL=debug` during setup; drop to `info` in steady state.
- **Comparison to alternatives**:
  - **Databasus** — DB-specific backup scheduler (pg_dump / mysqldump / mongodump); not file-based like Restic
  - **Backrest** — similar: web UI over Restic; more mature (separate recipe likely)
  - **Hurlstone / CUPS Restic** — other Restic UIs
  - **Duplicati** — cross-platform DIY + web UI
  - **Raw Restic + cron** — the purist path
- **License**: check LICENSE on repo (MIT per badge).
- **Alternatives worth knowing:**
  - **Backrest** — more mature web UI over Restic; active (separate recipe likely)
  - **Databasus** — DB-focused (separate recipe: batch 63)
  - **Duplicati** — cross-platform; dated UI
  - **Kopia** — modern Go-based backup; native UI
  - **Borgbackup + borgmatic** — deduplicated, mature
  - **Restic + cron scripts** — the original
  - **Synology Hyper Backup** / **QNAP HBS** — NAS-vendor commercial
  - **Choose Zerobyte if:** you're already comfortable with pre-1.0 tools + want a modern UI on Restic + like the nicotsx/Runtipi ecosystem.
  - **Choose Backrest if:** you want a more mature, production-ready Restic UI.
  - **Choose Databasus if:** you specifically need DB backup (different target).
  - **Choose Kopia if:** you want a fully-integrated modern backup tool (not Restic-based).

## Links

- Repo: <https://github.com/nicotsx/zerobyte>
- Website / docs: <https://zerobyte.app>
- Provisioning guide: <https://zerobyte.app/docs/guides/provisioning>
- Releases: <https://github.com/nicotsx/zerobyte/releases>
- Docker image: <https://github.com/nicotsx/zerobyte/pkgs/container/zerobyte>
- Discord: <https://discord.gg/XjgVyXrcEH>
- nicotsx (author): <https://github.com/nicotsx>
- Restic (underlying engine): <https://restic.net>
- Restic repo formats / backends: <https://restic.readthedocs.io/en/stable/030_preparing_a_new_repo.html>
- Backrest (alt): <https://github.com/garethgeorge/backrest>
- Databasus (alt): see batch 63 recipe in this repo
- Kopia (alt): <https://kopia.io>
- Runtipi (by same author): <https://runtipi.io>
