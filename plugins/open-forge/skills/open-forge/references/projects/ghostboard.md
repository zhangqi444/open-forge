# Ghostboard

A lightweight, self-hosted real-time text synchronisation tool. Open the page, type something — all connected clients see it instantly via WebSocket. Supports multiple independent boards via URL paths (e.g. `/team`, `/notes`). Full Markdown rendering, dark/light mode, REST API, and a bundled nginx reverse proxy in Docker. Ideal for LAN/intranet use.

> ⚠️ **No encryption or authentication:** Ghostboard has no security features — do not expose it to the public internet.

- **GitHub:** https://github.com/jon6fingrs/ghostboard
- **Docker image:** `thehelpfulidiot/ghostboard-server` (`:latest-arm64` for ARM)
- **Live demo:** https://ghostboard.app/ (read-only)
- **License:** Open-source

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| LAN / trusted network | docker run | Simplest; open port 80 |
| LAN / trusted network | Docker Compose | Same image; easier restart/management |

---

## Inputs to Collect

No configuration required. Ghostboard runs with no env vars or config files.

| Setting | Default | Notes |
|---------|---------|-------|
| Port | 80 | Map host port to container port 80 |

---

## Software-Layer Concerns

### Architecture
- Single Python + nginx container (as of v3.2.0, nginx is bundled)
- WebSocket server syncs text between clients
- Per-path boards: each unique URL path (e.g. `/myboard`) is a separate independent board
- SQLite or in-memory state (no persistent volume needed for basic use)

### Ports
- 80 — Web UI + WebSocket

---

## Minimal Setup

```bash
# One-liner
docker run -d --name ghostboard -p 8080:80 thehelpfulidiot/ghostboard-server

# Docker Compose
services:
  ghostboard:
    image: thehelpfulidiot/ghostboard-server
    container_name: ghostboard
    ports:
      - "8080:80"
    restart: unless-stopped

# ARM (Raspberry Pi etc.)
docker run -d --name ghostboard -p 8080:80 thehelpfulidiot/ghostboard-server:latest-arm64
```

Access at `http://your-server:8080`. Different boards at `http://your-server:8080/board1`, `/board2`, etc.

---

## Upgrade Procedure

```bash
docker pull thehelpfulidiot/ghostboard-server
docker compose up -d ghostboard
```

No persistent data to migrate.

---

## Gotchas

- **LAN/trusted network only:** There is intentionally no authentication or encryption — any visitor can read and overwrite any board; never expose to the internet
- **No persistence by default:** Board content is lost on container restart; if persistence matters, check the GitHub issues/releases for any persistence options added in newer versions
- **Multiple boards via URL paths:** Create logically separate boards just by using different paths — `/dev`, `/ops`, `/scratch` etc. all work independently out of the box
- **Markdown support:** As of v3.1.0, board content renders as Markdown; write normal text and it displays formatted
- **REST API available:** As of v3.4.0, a REST API lets you get/set board content programmatically — useful for scripts and automation

---

## References
- GitHub: https://github.com/jon6fingrs/ghostboard
- Demo: https://ghostboard.app/
