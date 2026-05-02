# Vykar

**What it is:** Fast, encrypted, deduplicated backup tool written in Rust. YAML-configured with multiple storage backends (local, S3-compatible, SFTP, REST), AES-256-GCM or ChaCha20-Poly1305 encryption, LZ4/Zstandard compression, built-in scheduling daemon, desktop GUI, and a WebDAV server for snapshot browsing. Inspired by BorgBackup, Restic, and Rustic but uses its own format.

**Official site:** https://vykar.borgbase.com  
**Install docs:** https://vykar.borgbase.com/install  
**GitHub:** https://github.com/borgbase/vykar  
**License:** GNU GPL v3.0

> ⚠️ **Pre-production warning:** Vykar is not yet recommended for sole-production use. Test alongside an existing backup solution.

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux | Binary | Single binary; install via curl script or releases |
| Any Linux VPS/VM | Docker | Docker image available |
| macOS | Binary | Cross-platform builds |
| Windows | Binary | Cross-platform builds |
| Raspberry Pi / ARM | Binary or Docker | Cross-platform support |

---

## Inputs to Collect

### Phase: Deploy

| Item | Description |
|------|-------------|
| `vykar.yaml` | Main config file — repositories, sources, encryption, schedule |
| Passphrase | Encryption passphrase (Argon2id key derivation) |
| Storage credentials | S3 keys, SFTP credentials, or local path depending on backend |

---

## Software-Layer Concerns

- **Own on-disk format** — not compatible with Borg or Restic repositories
- **Encryption:** AES-256-GCM or ChaCha20-Poly1305 (auto-selected); Argon2id key derivation
- **Deduplication:** FastCDC content-defined chunking with tiered dedup index + mmap-backed pack assembly
- **Compression:** LZ4 (fast) or Zstandard (better ratio)

### Storage backends

| Backend | Notes |
|---------|-------|
| Local filesystem | Direct path |
| S3-compatible | AWS S3, Backblaze B2, MinIO, etc. |
| SFTP | Remote SSH/SFTP server |
| REST server | Vykar's own REST server with append-only enforcement, quotas |

### Scheduling (`vykar daemon`)

Built-in daemon — no cron needed:

```yaml
schedule:
  enabled: true
  every: "24h"
  on_startup: false
  jitter_seconds: 0
  passphrase_prompt_timeout_seconds: 300
```

### Desktop GUI (`vykar-gui`)

- Slint-based desktop app
- Run backups on demand, list and browse snapshots, extract files
- System tray with periodic background backups
- Reads `vykar.yaml` directly; auto-reloads config changes

---

## Quick Start

```bash
# Install
curl -fsSL https://vykar.borgbase.com/install.sh | sh

# Generate starter config
vykar config

# Initialize repo and run first backup
vykar init
vykar backup

# List snapshots
vykar list
```

---

## Upgrade Procedure

1. Download new binary from GitHub releases or re-run install script
2. Replace binary; restart daemon if running
3. For Docker: `docker pull` + restart

---

## Gotchas

- **Not Borg/Restic compatible** — cannot read/write existing Borg or Restic repositories; migration requires exporting and re-importing data
- **Pre-production stability warning** — always use alongside another backup tool until project reaches stable release
- **Passphrase loss = data loss** — no recovery mechanism; store passphrase securely (password manager, secret store)
- **WebDAV server** for snapshot browsing is built-in but may not be suitable for public exposure without auth; configure firewall accordingly
- **REST server append-only mode** prevents deletions from the client side — useful for ransomware resistance but requires server-side compaction

---

## Links

- Website: https://vykar.borgbase.com
- Install: https://vykar.borgbase.com/install
- GitHub: https://github.com/borgbase/vykar
- Releases: https://github.com/borgbase/vykar/releases
