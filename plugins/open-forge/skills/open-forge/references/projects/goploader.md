---
name: goploader
description: goploader recipe for open-forge. Easy file sharing with server-side encryption. CLI client for curl/httpie/wget-style uploads. Web UI for drag-and-drop. Go server + client binary. Source: https://github.com/Depado/goploader
---

# goploader

File sharing server with server-side encryption. Supports a command-line client (curl/httpie/wget compatible) and a web UI for drag-and-drop uploads. Files are optionally encrypted at rest. First-run setup via web interface. Written in Go — single binary for both server and client. MIT licensed.

> ⚠️ **Maintenance warning**: The upstream repo notes "most of the tech used for this project is now outdated. Use at your own risk." The project is maintained as-is but not actively developed.

Upstream: <https://github.com/Depado/goploader> | Docs: <https://depado.github.io/goploader/>

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any | Docker | Build locally |
| Linux | Binary (Go build) | Single server binary |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| config | Port | Default: 8080 |
| config | Data directory | Where uploaded files are stored |
| config (optional) | Max file size | Configurable via setup UI |
| config (optional) | File lifetime | How long uploads persist before deletion |

## Software-layer concerns

### Architecture

- `goploader-server` — HTTP server, handles uploads/downloads, setup UI
- `gpldr` (client) — CLI tool for uploading from terminal (curl-compatible)
- No external database — uses local filesystem + BoltDB

### First-run setup

On first start, navigate to http://yourserver:8080 to complete setup:
- Set server name, max file size, file lifetime, encryption settings
- Configuration is saved as `server.yml`

## Install — Docker

```bash
git clone https://github.com/Depado/goploader.git
cd goploader

# Build image
make docker

# Run (first start: open http://127.0.0.1:8080 to complete setup)
docker run -d \
  --name goploader \
  --restart unless-stopped \
  -v goploader:/data \
  -p 8080:8080 \
  gpldr:latest
```

## Install — Binary (Go)

```bash
git clone https://github.com/Depado/goploader.git
cd goploader

# Build server
go build -trimpath -ldflags '-s -w' -o goploader-server ./server/

# Build client (optional)
go build -trimpath -ldflags '-s -w' -o gpldr ./client/

# Run server (opens setup UI on first start)
./goploader-server
```

## CLI client usage

```bash
# Install client binary, then upload:
gpldr /path/to/file.txt

# Or use curl directly (no client needed):
curl -F "file=@/path/to/file.txt" http://yourserver:8080/u/
```

## Upgrade procedure

```bash
git pull
make docker
docker rm -f goploader
# Re-run docker run
```

## Gotchas

- Outdated tech stack — the upstream author notes this project uses outdated dependencies. It works, but don't use it for sensitive data without reviewing the code.
- First-run setup is required before the server accepts uploads — visit the web UI at startup to configure server settings (max size, lifetime, encryption).
- No authentication by default — anyone who can reach the server can upload files. Deploy behind a reverse proxy with auth if exposing to the internet.
- Client binary must match the server version — build both from the same source checkout.

## Links

- Source: https://github.com/Depado/goploader
- Documentation: https://depado.github.io/goploader/
- Releases: https://github.com/Depado/goploader/releases
