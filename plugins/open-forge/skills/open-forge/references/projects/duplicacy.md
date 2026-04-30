---
name: Duplicacy
description: "Cross-platform cloud backup with lock-free deduplication — multiple computers to same storage, no chunk DB, strong encryption + erasure coding. CLI is FOSS (free for personal); Web GUI + commercial use require paid license. IEEE-published algorithm. Go."
---

# Duplicacy

Duplicacy is **a deduplicated, encrypted, cross-platform cloud backup tool** with a **distinctive lock-free architecture**: multiple machines can back up concurrently to the same storage without coordination. Each chunk is stored independently (named by hash) — no centralized chunk database, no distributed locks, no coordination protocol. This makes Duplicacy unusually well-suited for **cloud storage backends** (which don't offer reliable locking primitives) and for **multi-machine cross-deduplication** (N machines sharing OS files = one copy in storage).

The algorithm is **IEEE-published** (IEEE Transactions on Cloud Computing, 2020). Created by **Gilbert Chen**.

> **⚠️ License is unusual — read carefully.**
> - **CLI (command-line Duplicacy)** — source code in repo. **Free for personal use** (non-commercial); **paid license required for commercial use**.
> - **Web GUI (Windows/macOS/Linux)** — proprietary; **paid license** (personal + commercial tiers).
> - License terms at <https://duplicacy.com/customer/license>.
> - **This is NOT an open-source-free-forever project** despite repo access. If you're using it at work, you owe a license fee.
> - **Compare to alternatives below** if strict FOSS matters to you (restic, BorgBackup, Kopia are Apache/BSD).

Features:

- **Lock-free deduplication** — multi-machine concurrent backup to same storage, zero coordination
- **Database-less** — chunks named by hash; no centralized metadata DB; fewer failure modes
- **Client-side encryption** — AES-256 (symmetric) or **RSA asymmetric encryption** (asymmetric backup scenario)
- **Erasure coding** — optional Reed-Solomon for bit-rot resilience
- **Wide storage support** — local, SFTP, S3, Wasabi, DO Spaces, GCS, Azure, B2, Google Drive, OneDrive, WebDAV, pCloud, Box
- **Fast** — published benchmarks show Duplicacy beating restic/Attic/duplicity on Linux-kernel-sized backups
- **Web GUI** — schedules, multi-backend, dashboard (paid)
- **Snapshots** — per-repository snapshots; retention policies
- **Pruning** — remove old snapshots + unreferenced chunks
- **Cross-platform** — Linux, macOS, Windows, FreeBSD
- **VMware ESXi edition** (Vertical Backup — separate product)

- Upstream repo (CLI): <https://github.com/gilbertchen/duplicacy>
- Website: <https://duplicacy.com>
- Wiki: <https://github.com/gilbertchen/duplicacy/wiki>
- Quick start: <https://github.com/gilbertchen/duplicacy/wiki/Quick-Start>
- Paper: <https://github.com/gilbertchen/duplicacy/blob/master/duplicacy_paper.pdf>
- Forum: <https://forum.duplicacy.com>
- Vertical Backup (ESXi): <https://www.verticalbackup.com>

## Architecture in one minute

- **Single Go binary** CLI (Web GUI is a separate electron-style wrapper)
- **Snapshot + chunk model**: repository = directory-tree; backup slices files into content-defined variable-sized chunks (~4 MB avg); stores each chunk once by hash
- **Storage layout**: `chunks/` (deduplicated data) + `snapshots/<repo>/<id>/` (snapshot manifests)
- **No server component** — the "server" IS the storage; Duplicacy client directly reads/writes storage
- **Encryption** applied client-side before upload
- **Resource**: small — light RAM + CPU (hash + encrypt + upload)

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Any host           | **CLI binary** (download from GitHub releases)                     | **Canonical FOSS path**                                                           |
| Any host           | **Duplicacy Web** (commercial GUI) — Windows/macOS/Linux                   | Paid                                                                                       |
| Synology / QNAP    | CLI + custom scripts / DSM packages                                                        | Popular homelab                                                                                        |
| Kubernetes         | Run as sidecar / cron job                                                                             | Works                                                                                                              |
| Cloud VM           | Backup cloud VMs to S3/B2/etc.                                                                                        | Typical                                                                                                                             |

## Inputs to collect

| Input                 | Example                                     | Phase       | Notes                                                                      |
| --------------------- | ------------------------------------------- | ----------- | -------------------------------------------------------------------------- |
| Source path           | `/home/user/docs`                               | Setup       | Repository root                                                                   |
| Storage URL           | `s3://us-east-1@mybucket/path`                          | Storage     | Per supported backend syntax                                                                   |
| Storage credentials   | S3 access/secret, B2 app key, etc.                              | Auth        | Per backend                                                                                                   |
| Encryption password   | strong passphrase                                                       | Security    | **Write down — irrecoverable if lost**                                                                                           |
| Snapshot ID           | `laptop`, `server1`, etc.                                                      | Naming      | Logical name for this backup source                                                                                                    |
| Retention policy      | e.g., `-keep 0:365 -keep 7:30 -keep 30:7`                                         | Policy      | Daily for 7d, weekly for 30d, monthly for 365d, ...                                                                                                                |
| Erasure coding (opt)  | `-erasure-coding 5:2`                                                                         | Reliability | Adds ~40% overhead for 2-of-7 bit-rot resistance                                                                                                                                      |

## Install via CLI (Linux)

```sh
# Download latest binary
wget https://github.com/gilbertchen/duplicacy/releases/download/v3.2.3/duplicacy_linux_x64_3.2.3
sudo mv duplicacy_linux_x64_3.2.3 /usr/local/bin/duplicacy
sudo chmod +x /usr/local/bin/duplicacy

# Initialize repository
cd /home/user/docs
duplicacy init -e laptop s3://us-east-1@mybucket/backups

# First backup
duplicacy backup -stats

# Restore
duplicacy restore -r <revision-id> path/to/restore

# Prune old snapshots
duplicacy prune -keep 0:365 -keep 7:30 -keep 30:7 -a
```

Schedule via cron / systemd timer / Windows Task Scheduler.

## First boot / workflow

1. Install CLI binary on each machine
2. On storage (S3/B2/local/whatever): create bucket/path
3. On each source machine:
   ```sh
   cd /path/to/back/up
   duplicacy init -e <snapshot-id> <storage-url>
   duplicacy add <storage2-name> <snapshot-id> <storage2-url>   # optional second destination
   duplicacy backup
   ```
4. Schedule regular `backup` + periodic `prune`
5. **Test restore periodically** — on a different machine, to a different path, verify integrity
6. Set up monitoring / email on failures
7. Store passphrase + storage credentials **offline**

## Data & config layout

- Source-side: `.duplicacy/` dir in repository root (per-source config + cache)
- Storage-side: `chunks/` + `snapshots/<id>/<revision>` + `config` (encrypted metadata)
- **No separate metadata DB on any side** — chunks are self-describing

## Backup

Duplicacy IS the backup tool, but **meta-backup discipline** (see Zerobyte/Backrest precedents) applies:

```sh
# The storage target IS your backup — but:
# 1. Use multiple backends (primary + secondary) — Duplicacy supports this natively via `duplicacy add`
# 2. Store encryption passphrase OFFLINE (paper + safe, password manager export)
# 3. Store .duplicacy/preferences for each source (or re-init)
# 4. Test restore monthly
```

**3-2-1 backup rule**: 3 copies, 2 media, 1 offsite. Duplicacy makes the offsite cloud part easy; don't forget the "2 media" part (don't rely solely on one cloud provider).

## Upgrade

1. Releases: <https://github.com/gilbertchen/duplicacy/releases>. Active but slow-ish.
2. Binary swap; no migration needed on storage side.
3. Web GUI: separate installer/updater.
4. Breaking storage-format changes are rare — backups from old versions generally restorable by new.

## Gotchas

- **License model**: CLI free for personal, **paid for commercial**. Web GUI paid always. If you're a company, factor license cost (see <https://duplicacy.com/buy.html>). Not OSI-approved "open source" in the strict sense.
- **Passphrase loss = data loss** — the *most important* thing to back up separately is the passphrase. **Write it down + store offline + password manager + multiple locations.** Extends Zerobyte / OpenBao / Backrest passphrase discipline.
- **Lock-free claim vs restic's lock claim**: Duplicacy's author is explicit about restic's locking limitations in the README's comparison section. The concern is specifically: distributed locking on cloud storage is hard → faulty lock = accidental chunk deletion during prune → data loss. Duplicacy's design sidesteps this. **Real-world impact**: both tools are mature + safe in practice; distinction matters most at multi-machine scale.
- **Deduplication across machines**: if you back up 10 Linux laptops to one storage, only one copy of `/usr/lib/libc.so` lives in storage. Saves enormous space. **Compromising ANY machine's credentials = attacker can read all chunks** (with passphrase), including other machines' data. Use separate storage per trust zone.
- **Encryption model**: AES-256-GCM with key derived from passphrase. **Zero-knowledge** — storage provider can't read. **But**: encryption passphrase is shared across all machines using that storage. Key rotation is non-trivial.
- **Asymmetric encryption** (RSA mode): lets write-only machines back up without being able to read — useful for distrusted clients (e.g., employee laptops where you don't want them able to read each other's data). More complex setup.
- **Erasure coding**: adds ~40% overhead but protects against bit rot + partial chunk corruption. Enable for long-retention / untrusted storage.
- **Pruning is destructive**: `prune` deletes chunks not referenced by remaining snapshots. Don't run while backups are in progress (Duplicacy's lock-free design handles this safely, but plan schedule to avoid).
- **Cloud storage costs**: API request costs can dominate for frequent small backups. Tune chunk size / upload interval. B2/Wasabi/Storj typically cheaper than S3-IA for backup workloads.
- **Egress costs**: restoring a 1 TB backup from cloud = 1 TB egress (could be $$). Factor into cost model.
- **Restore granularity**: can restore specific files/directories; no need to restore full snapshot.
- **Incremental restore**: not quite — each restore is full transfer of needed chunks. But chunks might already be locally cached.
- **Performance**: published benchmarks show Duplicacy faster than restic/duplicity/Attic on common workloads. Real-world depends on chunk cache + network + storage latency.
- **Multi-destination**: back up to local + cloud with a single `backup` command — highly recommended for 3-2-1 compliance.
- **Web GUI**: paid; nice for non-CLI users + scheduling + dashboard; not required.
- **Windows VSS** support (for locked files) — Web GUI handles; CLI requires flag.
- **Community forum** at forum.duplicacy.com is active + helpful; Gilbert (author) responds.
- **Single-maintainer risk**: CLI is primarily one person's project; thoughtful but bus-factor-1.
- **License**: see <https://github.com/gilbertchen/duplicacy/blob/master/LICENSE> — **personal free; commercial paid**.
- **Alternatives worth knowing:**
  - **restic** — Go; Apache-2.0; single binary; very popular; locks-based but safe in practice (separate recipe likely)
  - **BorgBackup** — Python; BSD; deduplicating, compression, encryption; no cloud-native (use with rclone/B2 CLI) (separate recipe)
  - **Kopia** — Go; Apache-2.0; single binary; dedup + encryption; GUI; modern competitor
  - **Rclone** (with crypt) — sync not snapshot; different model
  - **Duplicati** — .NET; open-source; GUI; community doesn't love its reliability record
  - **Backrest** (batch 66) — restic wrapper with web UI
  - **Zerobyte** (batch 65) — Restic wrapper
  - **Bacula / Bareos** — enterprise-scale backup; different scope
  - **Veeam / CrashPlan / Carbonite** — commercial
  - **Choose Duplicacy if:** multi-machine cross-dedup + published algorithm + willing to pay for commercial.
  - **Choose restic/Kopia/Borg if:** strict FOSS requirement; Apache/BSD licensing; restic/Kopia are single-binary Go like Duplicacy.
  - **Choose Backrest (batch 66) if:** want restic-based tool with easy web UI + free.

## Links

- Repo: <https://github.com/gilbertchen/duplicacy>
- Website: <https://duplicacy.com>
- Wiki: <https://github.com/gilbertchen/duplicacy/wiki>
- Quick start: <https://github.com/gilbertchen/duplicacy/wiki/Quick-Start>
- Storage backends: <https://github.com/gilbertchen/duplicacy/wiki/Storage-Backends>
- Paper (IEEE): <https://github.com/gilbertchen/duplicacy/blob/master/duplicacy_paper.pdf>
- Forum: <https://forum.duplicacy.com>
- Pricing: <https://duplicacy.com/buy.html>
- Releases: <https://github.com/gilbertchen/duplicacy/releases>
- Vertical Backup (ESXi): <https://www.verticalbackup.com>
- restic (alt FOSS): <https://github.com/restic/restic>
- BorgBackup (alt FOSS): <https://www.borgbackup.org>
- Kopia (alt FOSS): <https://kopia.io>
- Backrest (batch 66, alt free): <https://github.com/garethgeorge/backrest>
