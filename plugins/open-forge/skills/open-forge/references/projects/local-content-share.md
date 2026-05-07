# Local Content Share

**Local-network clipboard and file sharing** — store and share text snippets, files, and links within your local network with no setup required on client devices. Works as an all-in-one alternative to AirDrop, a local pastebin, and a scratchpad.

**Source:** https://github.com/Tanq16/local-content-share  
**Docker Hub:** https://hub.docker.com/r/tanq16/local-content-share  
**License:** MIT

> ⚠️ **No authentication.** This app is designed for trusted local networks only. Do not expose to the public internet without an auth proxy.

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any | Docker | Primary install method |
| Linux/macOS | Go binary | Build from source |

---

## Inputs to Collect

### Provision phase
| Input | Description | Default |
|-------|-------------|---------|
| `HTTP_PORT` | External port to expose | `8080` |
| `DATA_DIR` | Host directory for persistent storage | `~/.localcontentshare` |

---

## Software-layer Concerns

### Docker CLI
```bash
mkdir $HOME/.localcontentshare
docker run --name local-content-share \
  -p 8080:8080 \
  -v $HOME/.localcontentshare:/app/data \
  tanq16/local-content-share:main
```

### Docker Compose
```yaml
services:
  local-content-share:
    image: tanq16/local-content-share:main
    container_name: local-content-share
    ports:
      - '8080:8080'
    volumes:
      - ./data:/app/data
    restart: unless-stopped
```

Access at `http://localhost:8080` (or your server IP on the local network). Also installable as a PWA from the browser.

### Features
- Text snippets: create, edit, rename, view/share
- File uploads: multi-file drag-and-drop, view/download on any device
- Link sharing (LIFO order)
- Built-in Markdown notepad with preview
- Configurable TTL per item: Never / 1h / 4h / 1 day / Custom
- Server-Sent Events (SSE) for real-time updates across all connected clients
- Works offline (fully local assets, no CDN dependencies)
- Multi-arch Docker image (x86-64 + ARM64)
- Catppuccin themed UI, auto light/dark mode, mobile-friendly PWA

### Persistent data
All data lives under the mounted volume (`/app/data` inside container). Back up this directory to preserve all content.

---

## Upgrade Procedure

```bash
docker compose pull
docker compose up -d
```

---

## Gotchas

- **No authentication built-in.** Anyone on your network can read, add, or delete content. Use a reverse proxy with auth (e.g., Authelia, Authentik) if you need access control.
- **Designed for LAN use.** Exposing to the public internet without auth is a security risk.
- **TTL-expired items are deleted automatically.** There is no recycle bin.
- **ARM64 + x86-64 supported** natively via the `main` tag.

---

## References

- Upstream README: https://github.com/Tanq16/local-content-share#readme
