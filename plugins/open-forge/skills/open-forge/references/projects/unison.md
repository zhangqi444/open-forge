---
name: unison
description: Unison recipe for open-forge. Bidirectional file-synchronization tool for Linux, macOS, and Windows. Synchronizes two replicas (local or remote over SSH/TCP) and handles conflicting changes. Source: https://github.com/bcpierce00/unison. Docs: https://www.cis.upenn.edu/~bcpierce/unison/docs.html.
---

# Unison

Bidirectional file synchronization tool for POSIX systems and Windows. Unlike rsync (one-way mirror), Unison synchronizes two replicas — detecting and propagating changes on both sides. Works across platforms, communicates over SSH or direct TCP, and has been stable and in active use for 25+ years. Upstream: <https://github.com/bcpierce00/unison>. Docs: <https://www.cis.upenn.edu/~bcpierce/unison/docs.html>.

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Linux + Linux | SSH (client/server) | Most common: sync two Linux servers or workstation + server |
| Linux + macOS | SSH | Cross-platform supported; both ends must run the same Unison major version |
| Linux + Windows | SSH or TCP | Windows build available; GUI version (unison-gtk) available |
| Local (same machine) | Direct (no network) | Sync two local directories on the same host |
| Automated / cron | CLI + repeat mode | Use -repeat=watch for continuous sync or cron for scheduled |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Local-to-local or local-to-remote sync?" | Drives SSH/TCP setup |
| paths | "Path to first replica (local root)?" | Absolute path, e.g. /home/user/docs |
| paths | "Path to second replica (remote or local)?" | For remote: ssh://user@host/path or //host/path |
| ssh | "SSH user and host for remote replica?" | Remote host must have Unison installed at same major version |
| profile | "Profile name?" | Saved in ~/.unison/<name>.prf for reuse |
| sync | "Auto-accept non-conflicting changes?" | -auto flag; prompts user for conflicts |

## Software-layer concerns

- Config: profiles stored in ~/.unison/*.prf; each profile = one sync pair
- Version matching: both sides must run the same Unison major.minor version (e.g. both 2.53.x). Mismatched versions refuse to sync.
- No daemon required: Unison is a client-side CLI tool. The remote side needs `unison` in $PATH (or specify path with -servercmd).
- Conflict resolution: Unison detects true conflicts (both sides changed the same file) and asks the user to choose. Non-conflicting changes are propagated automatically.
- Archive files: ~/.unison/*.unison.bak stores sync state. Do not delete; this is how Unison tracks what changed since last sync.
- repeat=watch mode: Uses inotify/FSEvents for continuous sync; requires Unison 2.53+ compiled with filesystem watcher support

### Install

```bash
# Debian/Ubuntu
sudo apt-get install unison

# macOS (Homebrew)
brew install unison

# From source (latest release)
git clone https://github.com/bcpierce00/unison.git
cd unison && make && sudo cp src/unison /usr/local/bin/
```

Remote host: install the same version of Unison via the same method.

### Basic one-time sync

```bash
unison /local/path ssh://user@remote-host//remote/path
```

### Profile file (~/.unison/myprofile.prf)

```
root = /home/user/docs
root = ssh://user@remote-host//home/user/docs

# Auto-accept non-conflicting updates
auto = true

# Prefer newer file on conflicts
prefer = newer

# Ignore common junk
ignore = Name .DS_Store
ignore = Name *.tmp
ignore = Name .git

# Batch mode (no interactive prompts; useful in cron)
batch = true
```

Run with profile: `unison myprofile`

### Continuous sync (repeat mode)

```bash
unison myprofile -repeat watch
```

### Cron schedule (every 15 min)

```cron
*/15 * * * * /usr/bin/unison myprofile -batch >> /var/log/unison.log 2>&1
```

## Upgrade procedure

1. Upgrade both sides simultaneously to the same new version
2. Check release notes: https://github.com/bcpierce00/unison/releases
3. Test with a non-critical profile first; archive files from old version are usually compatible but verify
4. `sudo apt-get install --only-upgrade unison` (Debian/Ubuntu)

## Gotchas

- **Version mismatch is a hard error**: If local and remote Unison versions differ in major.minor, sync refuses with a clear error. Upgrade both hosts together.
- **Not a daemon**: Unison doesn't run in the background by default. Use -repeat=watch for continuous mode, or schedule via cron/systemd timer.
- **Conflict resolution in batch mode**: With -batch, unrelated conflicts are skipped (not resolved). Always review the log for skipped conflicts.
- **SSH key auth required** for unattended/cron usage: password prompts break non-interactive runs.
- **Large initial sync**: First sync of a large tree downloads/sends all files. Run interactively first to check what it will do before automating.
- **Archive corruption**: If ~/.unison/ archives get corrupted or deleted, Unison treats everything as new on both sides at next sync — verify before accepting.
- **Not a backup tool**: Unison synchronizes; deletes on one side propagate to the other. For one-way backup use rsync with --backup.

## Links

- Upstream repo: https://github.com/bcpierce00/unison
- Docs: https://www.cis.upenn.edu/~bcpierce/unison/docs.html
- Wiki (incl. bug reporting guide): https://github.com/bcpierce00/unison/wiki
- Release notes: https://github.com/bcpierce00/unison/releases
