---
name: mycorrhiza-wiki
description: Mycorrhiza Wiki recipe for open-forge. Lightweight filesystem + Git-based wiki engine written in Go. Uses Mycomarkup markup, no database, every change stored in Git, categories, RSS/Atom feeds, authorization support. Source: https://github.com/bouncepaw/mycorrhiza
---

# Mycorrhiza Wiki

Lightweight wiki engine that stores all content as plain files on the filesystem with Git for history. No database. Each page (called a "hypha") is a text file + optional attachment. Uses Mycomarkup, a purpose-built unambiguous markup language. Supports categories, transclusion, interwiki, RSS/Atom/JSON feeds, keyboard navigation, Telegram login, and plain username/password auth. Written in Go. AGPL-3.0.

Upstream: <https://github.com/bouncepaw/mycorrhiza> | Wiki/docs: <https://mycorrhiza.wiki>

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Alpine Linux | apk (community repo) | Preferred — official package |
| Arch Linux | AUR (mycorrhiza) | Available in AUR |
| Gentoo | GURU overlay | www-apps/mycorrhiza |
| NixOS | nixpkgs | mycorrhiza in nixpkgs ≥ 21.11 |
| macOS | Homebrew | brew install mycorrhiza |
| OpenBSD | ports | www/mycorrhiza |
| Any | Build from source (Go 1.22+) | 5 min build; only runtime dep is `git` CLI |
| Any | Docker | Dockerfile in repo; may need customization |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| config | Wiki data directory | Where hypha files and Git history are stored |
| config | Port | Default: 1737 |
| config (optional) | Authorization method | None (public), plain username/password, or Telegram login |
| config (optional) | Custom domain for reverse proxy | For HTTPS via nginx/Caddy |

## Software-layer concerns

### Architecture

- Single Go binary (`mycorrhiza`) — serves all web requests
- Git (CLI) — runtime dependency; tracks all edits as commits
- Filesystem — wiki content stored as `.myco` text files + attachment files
- No external database, no external cache

### Data structure

Each hypha (page) consists of:
- `hyphaname.myco` — text content in Mycomarkup
- `hyphaname.jpg` (or other extension) — optional attachment (image, video, etc.)

All changes are committed to a Git repo in the wiki directory.

### Config

Mycorrhiza reads a config file at startup (pass with `-config`). Key options:

```toml
# mycorrhiza.toml
[server]
addr = "0.0.0.0:1737"

[wiki]
wiki_dir = "/var/lib/mycorrhiza"
wiki_name = "My Wiki"
wiki_description = "My personal wiki"

[authorization]
auth_method = "fixed"    # none | fixed | telegram
# For fixed auth:
# [[authorization.fixed_credentials]]
# login = "admin"
# password = "bcrypt-hash-here"
```

See full config reference at https://mycorrhiza.wiki/hypha/configuration

## Install — Package manager (recommended)

```bash
# Alpine Linux
apk add mycorrhiza

# Arch Linux (AUR)
yay -S mycorrhiza
# or: paru -S mycorrhiza

# Homebrew (macOS)
brew install mycorrhiza

# NixOS
nix-env -iA nixpkgs.mycorrhiza
```

## Install — Build from source

```bash
# Requires Go 1.22+ and git
git clone https://codeberg.org/bouncepaw/mycorrhiza.git
cd mycorrhiza
make
sudo make install   # installs to /usr/local/bin + man page
```

## Running

```bash
# Start a wiki (creates the directory automatically)
mycorrhiza /path/to/your/wiki

# With custom config
mycorrhiza -config /etc/mycorrhiza.toml /path/to/your/wiki

# Wiki is available at http://localhost:1737
```

## Systemd service

```ini
# /etc/systemd/system/mycorrhiza.service
[Unit]
Description=Mycorrhiza Wiki
After=network.target

[Service]
Type=simple
User=mycorrhiza
ExecStart=/usr/local/bin/mycorrhiza /var/lib/mycorrhiza
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl enable --now mycorrhiza
```

## Upgrade procedure

```bash
# Package manager: follow distro upgrade process
apk upgrade mycorrhiza      # Alpine
brew upgrade mycorrhiza     # Homebrew

# From source:
cd mycorrhiza && git pull
make && sudo make install
sudo systemctl restart mycorrhiza
```

## Gotchas

- `git` CLI must be installed on the server — it's the only runtime dependency besides the binary itself. The wiki silently fails to track history without it.
- The wiki directory becomes a Git repository on first run — don't delete the `.git` subdirectory inside it.
- Authorization is optional but strongly recommended for internet-facing wikis — without it, anyone can edit pages.
- Mycomarkup is not Markdown — it's Mycorrhiza's own markup language. Check the help pages at https://mycorrhiza.wiki/help/en/mycomarkup before migrating content.
- Docker image is community-maintained and may need customization for volume mounts — the official deployment path is via distro packages or binary.
- Reverse proxy recommended for HTTPS — Mycorrhiza only speaks HTTP; use nginx/Caddy with TLS termination for production.

## Links

- Source: https://github.com/bouncepaw/mycorrhiza
- Codeberg mirror: https://codeberg.org/bouncepaw/mycorrhiza
- Docs/wiki: https://mycorrhiza.wiki
- Deployment guide: https://mycorrhiza.wiki/hypha/deployment
- Configuration: https://mycorrhiza.wiki/hypha/configuration
