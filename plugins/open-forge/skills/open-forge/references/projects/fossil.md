---
name: fossil
description: Fossil recipe for open-forge. Distributed version control system with built-in wiki, bug tracker, and forum. Single-binary, SQLite-backed, self-contained. BSD-2-Clause. Source: https://fossil-scm.org/
---

# Fossil

A distributed version control system in a single self-contained binary, with built-in wiki, bug tracker, forum, chat, and documentation system. Everything stored in a single SQLite file per repository — easy to back up, replicate, and move. Designed for small-to-medium teams that want the full project management stack without external services. BSD-2-Clause-FreeBSD licensed, written in C. Website: <https://fossil-scm.org/>. Download: <https://fossil-scm.org/home/uv/download.html>

## Compatible Combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux / macOS / Windows | Native binary (standalone) | Single static binary — no installation beyond copying to PATH |
| Any Linux | NGINX/Apache + CGI | Serve over HTTPS with a reverse proxy |
| Any Linux | Fossil server mode | `fossil server` built-in HTTP server |
| Any Linux | systemd + fossil | Long-running server process |

## Inputs to Collect

### Phase 1 — Preflight

| Prompt | Format | Notes |
|---|---|---|
| "Repository storage directory?" | Path | Where `.fossil` repo files are stored |
| "Domain for web interface?" | FQDN | e.g. code.example.com |
| "Admin username?" | string | First admin account — set on `fossil new` |
| "Serve one repo or all repos in a directory?" | Single / Directory | Directory mode serves all `.fossil` files under a path |

### Phase 2 — Deploy

| Prompt | Format | Notes |
|---|---|---|
| "Reverse proxy?" | NGINX / Caddy / none | Recommended for HTTPS |
| "Authentication required?" | Yes / No | Fossil can be public read + authenticated write |

## Software-Layer Concerns

- **Single SQLite file**: Each repository is one `.fossil` file. Contains all history, wiki, tickets, attachments. Easy to `cp` for backup.
- **Single binary**: Download the fossil binary, copy to `$PATH` — done. No install scripts, no dependencies.
- **Built-in web server**: `fossil server` starts an HTTP server — lightweight enough for personal use; use NGINX in front for production.
- **User management**: Users and access levels managed through the web UI (admin panel) or `fossil user` CLI commands.
- **Clone = full copy**: `fossil clone` downloads the entire repository history to a local `.fossil` file — truly distributed.
- **Sync model**: `fossil sync` pushes and pulls all changes (code, wiki, tickets) to/from a remote.
- **Not Git-compatible**: Fossil uses its own protocol and format — cannot directly clone/push to GitHub/GitLab.
- **Tickets and wiki**: Built into every repo — no separate issue tracker needed.

## Deployment

### Install binary

```bash
# Download pre-built binary from fossil-scm.org
# https://fossil-scm.org/home/uv/download.html
wget https://fossil-scm.org/home/uv/fossil-linux-x64-2.25.tar.gz
tar xzf fossil-linux-x64-2.25.tar.gz
sudo install fossil /usr/local/bin/fossil
fossil version
```

### Create and serve a repository

```bash
# Create new repo
mkdir -p /srv/fossil
fossil new /srv/fossil/myproject.fossil

# Start web server (all repos in directory)
fossil server /srv/fossil/ --port 8080 --baseurl https://code.example.com

# Or single repo
fossil server /srv/fossil/myproject.fossil --port 8080
```

### NGINX reverse proxy

```nginx
server {
    listen 443 ssl;
    server_name code.example.com;

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $remote_addr;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### systemd service

```ini
[Unit]
Description=Fossil SCM server
After=network.target

[Service]
ExecStart=/usr/local/bin/fossil server /srv/fossil/ --port 8080 --baseurl https://code.example.com --localhost
Restart=on-failure
User=fossil
WorkingDirectory=/srv/fossil

[Install]
WantedBy=multi-user.target
```

### Clone and work locally

```bash
# Clone from server
fossil clone https://code.example.com/myproject myproject.fossil

# Open (check out) into a working directory
mkdir myproject && cd myproject
fossil open ../myproject.fossil

# Commit
fossil add .
fossil commit -m "Initial commit"
fossil push
```

## Upgrade Procedure

1. Download new binary from fossil-scm.org.
2. Replace `/usr/local/bin/fossil`.
3. Restart systemd service: `sudo systemctl restart fossil`.
4. Run `fossil rebuild /srv/fossil/*.fossil` if upgrading across major versions.
5. Repository SQLite files are forward-compatible.

## Gotchas

- **Not Git**: Fossil is a complete alternative to Git, not a wrapper. Different commands, different mental model. `fossil add`, `fossil commit`, `fossil push` — not `git add/commit/push`.
- **Backup = copy the .fossil file**: The entire repo (history, wiki, tickets) is one SQLite file. `cp myproject.fossil myproject.fossil.bak` is a complete backup.
- **`fossil rebuild`** after major upgrades: Rebuilds indexes and normalizes the SQLite file — good practice after version bumps.
- **Admin account setup**: On a new `fossil server`, the first user to visit the web UI and register gets admin rights, or use `fossil user new` CLI.
- **Directory mode exposes all .fossil files**: When serving a directory, every `.fossil` file in it is accessible — keep private repos in a separate directory.
- **HTTPS + baseurl**: Set `--baseurl https://code.example.com` so Fossil generates correct absolute links and redirect URLs.

## Links

- Website: https://fossil-scm.org/
- Quick start: https://fossil-scm.org/home/doc/trunk/www/quickstart.wiki
- Server setup: https://fossil-scm.org/home/doc/trunk/www/server/
- Download: https://fossil-scm.org/home/uv/download.html
- Documentation index: https://fossil-scm.org/home/doc/trunk/www/index.wiki
