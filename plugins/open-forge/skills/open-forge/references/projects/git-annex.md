---
name: git-annex
description: Git Annex recipe for open-forge. File synchronization and management tool built on Git. Handles large files across computers, servers, and external drives. GPL-3.0, Haskell. Source: https://git.joeyh.name/index.cgi/git-annex.git/
---

# Git Annex

A tool for managing large files with Git, syncing files across computers, servers, and external drives without checking file contents into Git itself. Git stores metadata and pointers; git-annex tracks the actual content in an "object store" and syncs it on demand. Supports dozens of backends: SSH remotes, S3, Glacier, WebDAV, rsync, Bittorrent, Tahoe-LAFS, and more. GPL-3.0, written in Haskell. Website: <https://git-annex.branchable.com/>

## Compatible Combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux / macOS | git-annex binary (package) | Works with any standard git remote |
| SSH server | git-annex on remote | Enables SSH-based file sync |
| Any Linux + NGINX | git-annex assistant + webapp | Web UI for monitoring sync status |
| S3 / B2 / WebDAV | Special remotes | Store content on cloud backends |

## Inputs to Collect

### Phase 1 — Preflight

| Prompt | Format | Notes |
|---|---|---|
| "Primary use case?" | Sync between machines / Archive / Backup | Drives which remotes to configure |
| "Remote storage type?" | SSH server / S3 / External drive / WebDAV | Determines special remote config |
| "SSH server for sync?" | user@host | For standard SSH remote setup |

### Phase 2 — Deploy

| Prompt | Format | Notes |
|---|---|---|
| "Annex in existing Git repo?" | Yes / No | `git annex init` works in any git repo |
| "Sync large files only?" | Yes / No | Can configure which files go into annex vs regular git |

## Software-Layer Concerns

- **Git integration**: git-annex extends git — every annexed repo is also a valid git repo. Git handles metadata; git-annex handles content.
- **Content availability tracking**: git-annex knows which copies of each file exist on which remotes. `git annex whereis` shows file locations.
- **On-demand content**: Files appear as symlinks (or pointer files) locally until `git annex get` fetches the actual content.
- **Required copies**: Configure `numcopies` to ensure git-annex won't drop the last copy of a file.
- **Backends**: SHA256E (default) uses SHA256 hash + extension. Multiple backends available for different use cases.
- **Special remotes**: Cloud backends (S3, B2, WebDAV, rsync.net, etc.) configured as "special remotes" — content-addressed, encrypted optional.
- **git-annex assistant**: Background daemon + web UI for automatic sync — similar to Dropbox-style continuous sync.
- **Haskell binary**: Self-contained binary — all Haskell dependencies statically linked. Install from package or download standalone binary.

## Deployment

### Install

```bash
# Debian/Ubuntu
apt install git-annex

# Fedora
dnf install git-annex

# macOS (Homebrew)
brew install git-annex

# Standalone binary (any Linux)
# https://git-annex.branchable.com/install/Linux_standalone/
```

### Basic workflow

```bash
# Initialize a git-annex repo
git init myproject
cd myproject
git annex init "my laptop"

# Add large files to annex (instead of git add)
git annex add bigfile.iso photos/

# Commit metadata (pointers, not content)
git commit -m "Add files"

# Push metadata to remote
git remote add origin user@server:/srv/annex/myproject
git push origin main git-annex

# Sync content to remote
git annex copy --to origin bigfile.iso
```

### SSH remote setup (server side)

```bash
# On the server — create bare repo + init annex
ssh user@server
mkdir -p /srv/annex/myproject
cd /srv/annex/myproject
git init --bare
git annex init "server"
```

```bash
# On client
git remote add server user@server:/srv/annex/myproject
git annex sync server       # sync metadata
git annex copy --to server  # copy content
```

### S3 special remote

```bash
git annex initremote s3-backup type=S3 encryption=none \
  bucket=my-annex-backup \
  datacenter=us-east-1 \
  AWS_ACCESS_KEY_ID=xxx AWS_SECRET_ACCESS_KEY=yyy

git annex copy --to s3-backup bigfile.iso
```

### git-annex assistant (auto-sync daemon)

```bash
# Start assistant (creates web UI at localhost:8888)
git annex assistant --autostart

# Or start for specific repo
cd myproject
git annex assistant
# Open http://localhost:8888 to configure sync remotes
```

## Upgrade Procedure

1. `apt update && apt upgrade git-annex` (Debian/Ubuntu).
2. Run `git annex upgrade` in each repo after upgrading — migrates repo format if needed.
3. Check https://git-annex.branchable.com/upgrades/ for version-specific notes.

## Gotchas

- **Symlinks vs pointer files**: By default, annexed files appear as symlinks (Unix) or pointer text files (Windows). Direct mode or `annex.thin` can change this.
- **`numcopies` is critical**: Set `git annex numcopies 2` to prevent accidental data loss — git-annex won't drop content if it's the only copy.
- **Sync metadata separately from content**: `git annex sync` syncs metadata; `git annex copy/move/get` moves content. Easy to accidentally leave content un-synced.
- **Haskell binary size**: The git-annex standalone binary is ~150MB (statically linked Haskell). Package manager versions are smaller.
- **Partial content**: A repo can have metadata for thousands of files but local content for only a subset — intended behavior.
- **Unlock before editing**: Annexed files are read-only by default. Run `git annex unlock <file>` before editing.

## Links

- Website: https://git-annex.branchable.com/
- Install guide: https://git-annex.branchable.com/install/
- Walk-through: https://git-annex.branchable.com/walkthrough/
- Special remotes: https://git-annex.branchable.com/special_remotes/
- Source: https://git.joeyh.name/index.cgi/git-annex.git/
