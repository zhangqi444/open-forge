---
name: BackupPC
description: "High-performance enterprise-grade backup system to server disk. Perl. backuppc/backuppc. SMB + rsync + tar over SSH. Pool dedup, web UI, Linux/Windows/macOS clients."
---

# BackupPC

**High-performance, enterprise-grade system for backing up Linux, Windows, and macOS PCs to a server's disk.** Highly configurable, deduplicates identical files across all backups (pooling scheme), delivers substantial disk savings. Backup transport via SMB (Samba), rsync, or tar over SSH/RSH/NFS. Web UI for managing hosts, viewing backup status, and restoring files.

Mature, widely-deployed open-source project. Maintained at <https://backuppc.github.io/backuppc/>.

- Upstream repo: <https://github.com/backuppc/backuppc>
- Website + docs: <https://backuppc.github.io/backuppc/>
- Releases: <https://github.com/backuppc/backuppc/releases>
- BackupPC-XS (required Perl module): <https://github.com/backuppc/backuppc-xs/releases>
- rsync-bpc (required server-side rsync fork): <https://github.com/backuppc/rsync-bpc/releases>

## Architecture in one minute

- **Perl** server daemon + web UI (Apache / any HTTPD with Perl CGI)
- Backup transport: **SMB** (Samba/smbclient for Windows), **rsync** (preferred for Linux/macOS), **tar over SSH/RSH/NFS**
- **Pool deduplication**: identical files across backups + hosts stored once → major disk savings on similar OS installations
- Compressed pool storage; incremental backups via rsync's block-level delta
- Web UI for per-host configuration, backup schedule, status, file-browse + restore
- **No client software required** on backup targets (agent-less for SSH/rsync targets)
- Resource: **medium** — Perl, depends on number of hosts and pool size; I/O-bound

## Compatible install methods

| Infra          | Runtime                             | Notes                                                                   |
| -------------- | ----------------------------------- | ----------------------------------------------------------------------- |
| **Package manager** | `apt install backuppc` / `yum` | Simplest; may be older version than upstream release                    |
| **Source install** | `perl configure.pl`            | Upstream-recommended for latest version; requires BackupPC-XS + rsync-bpc |
| **Docker**     | Community images (e.g. `adferrand/backuppc`) | Upstream doesn't publish official Docker image; community-maintained |

## Inputs to collect

| Input                         | Example                            | Phase     | Notes                                                                                            |
| ----------------------------- | ---------------------------------- | --------- | ------------------------------------------------------------------------------------------------ |
| Server install paths          | `/var/lib/BackupPC`, `/etc/BackupPC` | Install  | `configure.pl` prompts; use defaults unless you have NAS mount-point reasons to change          |
| Admin user                    | `backuppc`                         | Auth      | BackupPC creates its own system user; web UI uses htpasswd or system auth                        |
| Hosts to back up              | hostname / IP per host             | Config    | Per-host in `BackupPC/hosts`; each gets its own transport config                                 |
| SSH keys (rsync hosts)        | keypair                            | Auth      | BackupPC server keypair → deployed to each Linux/macOS target's `authorized_keys`                |
| Samba creds (Windows hosts)   | share + user + pw                  | Auth      | For SMB backup of Windows shares                                                                  |
| Schedules                     | full weekly + incremental nightly  | Config    | Per-host cron-style schedule in per-host config files                                             |
| Email (optional)              | SMTP for status alerts             | Notify    | `$Conf{SendmailPath}` + admin email for backup failure alerts                                    |

## Install from source (recommended for latest)

```bash
# 1. Install required Perl modules + system deps
apt-get install perl libapache2-mod-perl2 samba-client rsync ...
# (full list: backuppc.github.io/backuppc/BackupPC.html#INSTALL)

# 2. Install BackupPC::XS
# Download from https://github.com/backuppc/backuppc-xs/releases
tar zxf BackupPC-XS-*.tar.gz && cd BackupPC-XS-*
perl Makefile.PL && make && make install

# 3. Install rsync-bpc (server-side rsync fork with pool support)
# Download from https://github.com/backuppc/rsync-bpc/releases
tar zxf rsync-bpc-*.tar.gz && cd rsync-bpc-*
./configure && make && sudo make install

# 4. Install BackupPC itself
tar zxf BackupPC-*.tar.gz && cd BackupPC-*
sudo perl configure.pl
# Interactive prompts: install paths, web server user, etc.
```

## Install via package manager (easier, may be older)

```bash
# Debian/Ubuntu
sudo apt-get install backuppc

# RHEL/CentOS/Fedora
sudo yum install BackupPC
```

Post-install: configure via `/etc/BackupPC/config.pl` and the web UI.

## First boot

1. Install (source or package).
2. Open web UI (typically `http://<server>/backuppc`).
3. Log in as `backuppc` admin (password set during install or via htpasswd).
4. Add your first host (Settings → Edit Config → per-host).
5. Choose transport: rsync over SSH (Linux targets), SMB (Windows targets), tar (NFS/exotic).
6. For rsync: copy BackupPC's SSH public key (`~backuppc/.ssh/id_rsa.pub`) to each target's `~root/.ssh/authorized_keys`.
7. Run a manual backup of the first host; verify in the web UI.
8. Set up schedules (full weekly, incremental nightly — upstream defaults are sane).
9. Configure email alerts for failures.
10. Document backup restore procedure; test a restore before you need it.

## Data layout

- **Pool**: `/var/lib/BackupPC/pc/` — compressed, deduplicated pool files
- **Config**: `/etc/BackupPC/` — `config.pl` (global) + per-host subdirs
- **Logs**: `/var/log/BackupPC/`
- **Web UI root**: wherever your HTTPD CGI is configured (varies by distro)

## Backup of BackupPC itself

```sh
# Back up the pool + config:
sudo tar czf backuppc-meta-$(date +%F).tgz /etc/BackupPC/ /var/lib/BackupPC/
# Note: the pool can be LARGE (TB-scale for many hosts). Use incremental
# snapshot tools (ZFS send, btrfs send, rsync to offsite) for the pool itself.
```

Pool is append-friendly — rsync/ZFS incremental backups of the pool dir are efficient.

## Upgrade

1. Releases: <https://github.com/backuppc/backuppc/releases>
2. **Check BackupPC-XS + rsync-bpc compatibility** with the new BackupPC version first.
3. `sudo perl configure.pl` over an existing install — the configure script handles upgrades.
4. Restart BackupPC service + web server.

## Gotchas

- **Three-component install.** BackupPC itself + **BackupPC-XS** (Perl XS module for pool operations) + **rsync-bpc** (custom rsync fork). All three must be version-compatible. Check release notes.
- **No official Docker image.** Upstream doesn't ship Docker; community images exist (e.g., `adferrand/backuppc`) but diverge independently. For a production backup server, native install on a dedicated host is safer and upstream-supported.
- **SMB for Windows requires Samba client + nmblookup.** `apt-get install smbclient` on the server. No agent needed on Windows targets.
- **Pool is not a POSIX filesystem backup.** The pool stores files by content hash; you cannot simply `rsync` it to restore. Use BackupPC's own restore mechanism or the web UI. Backing up the pool to tape/cold storage requires dumping BackupPC's catalog alongside.
- **Disk space planning.** BackupPC's dedup pool is efficient but backups of many hosts accumulate. Rule of thumb: 1–2× the size of the largest single host's data for the full pool (dedup helps for similar OS installs; less for unique data).
- **CGI web UI requires Perl + web server.** Most installs use Apache + mod_perl. Nginx without FastCGI support won't serve the CGI directly — use Apache or configure a FCGI wrapper.
- **SSH key distribution is manual.** For each new Linux/macOS host, you must copy BackupPC's SSH public key to `authorized_keys` on that host (as root, for full filesystem backup). Automate with Ansible/Salt if managing many hosts.
- **Windows VSS (Volume Shadow Copy).** BackupPC via SMB does not use VSS by default — open files on Windows may be skipped. For VSS-aware Windows backups, combine with a VSS-aware approach or use Veeam-style tooling instead.
- **Perl dependency chain.** If upgrading system Perl, rebuild BackupPC-XS (Perl XS modules are version-coupled to the Perl binary). Forgetting this causes cryptic missing-symbol errors.
- **Web UI auth is basic by default.** Htpasswd auth out of the box. Consider putting behind a VPN or IP-restricting the `/backuppc` URL in your web server config — the UI has restore capabilities.
- **Tested restore procedure is non-negotiable.** A backup system that hasn't been tested for restore is theater. Schedule a quarterly restore drill.

## Project health

Mature, widely-deployed open-source backup system (been around since early 2000s), actively maintained on GitHub. Three-component release coordination (BackupPC + XS + rsync-bpc) can lag; check GitHub for latest stable before installing from distro packages.

## Backup-system-family comparison

- **BackupPC** — Perl, agentless (SSH/rsync/SMB), pool dedup, web UI; best for mixed Linux+Windows environments, LAN-primary
- **Bacula** — enterprise-grade, client/director/storage daemon architecture; more complex
- **Amanda** — traditional tape/disk backup, Perl, UNIX-centric
- **Restic** — modern, client-side encrypted, cloud + local targets; no central web UI
- **Borgbackup / Vorta** — dedup + encryption, client-side; no central management
- **Veeam Community** — Windows/VMware-centric; free tier; VSS-aware
- **Duplicati** — GUI client app; cloud-first

**Choose BackupPC if:** you need a central backup server for a mixed fleet of Linux/Windows/macOS hosts over LAN with pool deduplication, a web UI for monitoring and restores, and no client agents.

## Links

- Repo: <https://github.com/backuppc/backuppc>
- Docs: <https://backuppc.github.io/backuppc/>
- BackupPC-XS: <https://github.com/backuppc/backuppc-xs>
- rsync-bpc: <https://github.com/backuppc/rsync-bpc>
- Restic (modern alt): <https://restic.net>
- BorgBackup (modern alt): <https://www.borgbackup.org>
