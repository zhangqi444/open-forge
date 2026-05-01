---
name: Gossa
description: "Minimal self-hosted file server with web UI. Docker or binary. Go. pldubouilh/gossa. <250 lines of code, drag-and-drop upload, video streaming, PDF viewer, note editor, keyboard nav, PWA, multi-user via proxy, MIT."
---

# Gossa

**Fast and simple self-hosted web file server.** Browse, upload, stream, and manage your files from any browser. Under 250 lines of code, zero dependencies, and reproducible builds. Video streaming, picture browser, PDF viewer, note editor, keyboard navigation, drag-and-drop upload, PWA support. Multi-user setup via Caddy/nginx proxy.

Built + maintained by **pldubouilh**. MIT license.

- Upstream repo: <https://github.com/pldubouilh/gossa>
- Docker Hub: <https://hub.docker.com/r/pldubouilh/gossa>

## Architecture in one minute

- **Go** binary — single executable, zero external dependencies
- No database — serves a filesystem directory directly
- Port **8001** (default)
- Multi-platform: Linux, macOS, Windows, ARM
- ~35–75 MB RAM; sub-millisecond page loads
- HTTPS and auth are delegated to a proxy (Caddy/nginx) — see sample configs in `support/`
- Resource: **tiny** — pure Go static file server

## Compatible install methods

| Infra       | Runtime               | Notes                                              |
| ----------- | --------------------- | -------------------------------------------------- |
| **Docker**  | `pldubouilh/gossa`    | Docker Hub; multi-arch                             |
| **Binary**  | GitHub Releases       | Pre-built binaries; all platforms; reproducible    |
| **AUR**     | `gossa`               | Arch Linux                                         |
| **Nix**     | `nix-shell -p gossa`  | Nix package manager                                |
| **MPR**     | `makedeb`             | makedeb package repository                         |

## Install via Docker

```bash
mkdir ~/LocalDirToShare
docker run -d \
  -v ~/LocalDirToShare:/shared \
  -p 8001:8001 \
  --name gossa \
  pldubouilh/gossa
```

Visit `http://localhost:8001`.

## Install via binary

```bash
# Download from https://github.com/pldubouilh/gossa/releases
chmod +x gossa
./gossa ~/LocalDirToShare
```

## CLI options

```
./gossa --help

./gossa [flags] <path to serve>

  -h string    host (default "127.0.0.1")
  -p string    port (default "8001")
  -r           read-only mode (no upload/delete)
  -prefix      URL prefix (e.g. /files)
```

Expose on all interfaces:
```bash
./gossa -h 0.0.0.0 ~/storage
```

## Multi-user setup (Caddy/nginx proxy)

Gossa delegates authentication and HTTPS to a proxy layer. Sample Caddy configurations for multi-user setup (different users rooted to different directories) are in the repo at `support/`. This allows you to have multiple users each accessing their own subdirectory — without any user management built into Gossa itself.

See: <https://github.com/pldubouilh/gossa/tree/master/support>

## Features overview

| Feature | Details |
|---------|---------|
| File browser | Directory listing with icons; click to navigate |
| Video streaming | In-browser video player for common formats |
| Picture browser | Image gallery viewer |
| PDF viewer | Inline PDF rendering |
| Note editor | Simple text/note editor for `.txt` files |
| Upload | Drag-and-drop file upload |
| Keyboard navigation | Keyboard shortcuts for all operations |
| Read-only mode | `-r` flag to disable all write operations |
| PWA | Progressive Web App — installable on mobile/desktop |
| Multi-platform | Linux, macOS, Windows, ARM |
| Reproducible builds | Build hashes published on release page |
| >95% test coverage | Strong test coverage for a tiny codebase |

## Keyboard shortcuts

Press `Ctrl/Cmd + H` in the UI to see all keyboard shortcuts.

## Gotchas

- **No authentication built-in.** Gossa serves files without any login. For protected access, put it behind a proxy (nginx/Caddy) with HTTP Basic Auth or OAuth. The `support/` folder has ready-made Caddy configs.
- **No HTTPS built-in.** Same as auth — delegate to the proxy. Use Caddy (automatic Let's Encrypt) or nginx + certbot.
- **Read-only mode protects from accidental writes.** The `-r` flag disables upload, move, rename, delete. Use it when sharing files publicly where you don't want anyone to modify them.
- **Single directory scope.** Gossa serves one directory (and its subdirectories). It won't let users browse above the root directory you specify.
- **Multi-user = multiple Gossa instances.** The Caddy sample config runs one Gossa instance per user, each rooted to a different directory. There's no built-in user management — multiple instances is the pattern.
- **Zero configuration file.** Gossa has no config file — everything is command-line flags. Very simple, but means you re-type flags on each start (or use a systemd unit / Docker run command).
- **Systemd unit available.** For automatic start at boot on bare metal, a sample systemd user service is in `support/`. See the support folder in the repo.

## Backup

Gossa is stateless — just back up the directory it serves.

## Upgrade

```bash
# Docker
docker pull pldubouilh/gossa && docker restart gossa
# Binary: download new release, replace binary, restart
```

## Project health

Active Go development, Docker Hub (multi-arch), AUR, Nix, reproducible builds, >95% test coverage. Solo-maintained by pldubouilh. MIT license.

## File-server-family comparison

- **Gossa** — Go, <250 lines, zero deps, drag-and-drop, video/PDF/images, keyboard nav, PWA, MIT
- **filebrowser** — Go, polished UI, user management built-in, more features; heavier
- **Caddy file server** — Go, TLS + WebDAV + browse; no drag-and-drop UI; config-file-based
- **Serve (npm)** — Node.js, one-liner dev server; no UI for upload
- **Apache/nginx** — web servers with directory listing; no upload UI

**Choose Gossa if:** you want the simplest possible self-hosted file server — browse, stream, upload, and share files from any browser — with zero configuration and a tiny codebase.

## Links

- Repo: <https://github.com/pldubouilh/gossa>
- Docker Hub: <https://hub.docker.com/r/pldubouilh/gossa>
- Sample proxy configs: <https://github.com/pldubouilh/gossa/tree/master/support>
