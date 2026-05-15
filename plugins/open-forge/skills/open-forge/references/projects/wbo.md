---
name: wbo
description: WBO (whitebophir) recipe for open-forge. Covers Docker (recommended) and Node.js bare install. WBO is an online collaborative whiteboard — real-time multi-user drawing on a persistent virtual board.
---

# WBO (Whitebophir)

Online collaborative whiteboard that allows many users to draw simultaneously on a large virtual board. The board is updated in real time for all connected users, and its state is always persisted. Useful for art, teaching, design, and brainstorming. Upstream: <https://github.com/lovasoa/whitebophir>. Demo: <https://wbo.ophir.dev>.

**License:** AGPL-3.0 · **Language:** Node.js · **Default port:** 5001 (host) → 80 (container) · **Stars:** ~2,600

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker | <https://hub.docker.com/r/lovasoa/wbo> | ✅ | Recommended — single command, no dependency management. |
| Node.js (bare) | <https://github.com/lovasoa/whitebophir#running-the-code-without-a-container> | ✅ | When Docker is not available; requires Node.js v22+. |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| preflight | "Which install method — Docker or Node.js?" | AskUserQuestion | Determines section below. |
| data | "Where should board data be persisted on the host?" | Free-text (directory path, default: ./wbo-boards) | Docker method. |
| network | "External port to expose WBO on?" | Free-text (default 5001) | Docker method. |
| proxy | "Are you placing a reverse proxy in front?" | AskUserQuestion: Yes / No | Affects WBO_IP_SOURCE env var. |
| proxy_type | "Which proxy/CDN? (nginx / Caddy / Cloudflare / other)" | AskUserQuestion | When proxy=Yes; determines WBO_IP_SOURCE value. |

## Install — Docker (recommended)

Reference: <https://github.com/lovasoa/whitebophir#running-the-code-in-a-container>

```bash
mkdir wbo-boards
chown -R 1000:1000 wbo-boards

docker run -it \
  --publish 5001:80 \
  --volume "$(pwd)/wbo-boards:/opt/app/server-data" \
  lovasoa/wbo:v2.8.4
```

WBO is now available at `http://localhost:5001`.

### Docker Compose

```yaml
services:
  wbo:
    image: lovasoa/wbo:v2.8.4
    restart: unless-stopped
    ports:
      - "5001:80"
    volumes:
      - ./wbo-boards:/opt/app/server-data
    environment:
      # Set to X-Forwarded-For, Forwarded, or CF-Connecting-IP when behind a proxy/CDN
      # Leave unset (or remoteAddress) for direct internet access
      WBO_IP_SOURCE: remoteAddress
```

Create data directory and start:

```bash
mkdir wbo-boards
chown -R 1000:1000 wbo-boards
docker compose up -d
```

### Behind a reverse proxy (nginx example)

Set `WBO_IP_SOURCE: X-Forwarded-For` in the Compose environment, then proxy from nginx:

```nginx
server {
    listen 443 ssl;
    server_name whiteboard.example.com;

    location / {
        proxy_pass http://127.0.0.1:5001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $remote_addr;
    }
}
```

Note: WBO uses WebSockets for real-time updates — ensure your proxy passes `Upgrade` and `Connection` headers.

## Install — Node.js (bare)

Reference: <https://github.com/lovasoa/whitebophir#running-the-code-without-a-container>

```bash
git clone https://github.com/lovasoa/whitebophir.git
cd whitebophir

# Node.js v22 or higher required
node -v

npm install --production
npm start
```

WBO starts on port 5001 by default.

## Software-layer concerns

| Concern | Detail |
|---|---|
| Data directory | Board data persisted to /opt/app/server-data in container. Mount a host volume so data survives container restarts. |
| File ownership | Container runs as UID 1000; host directory must be owned by 1000:1000 (chown -R 1000:1000 wbo-boards). |
| WBO_IP_SOURCE | Controls how WBO reads client IPs for rate limiting. Set to X-Forwarded-For (nginx/Caddy), CF-Connecting-IP (Cloudflare), or Forwarded. Leave as remoteAddress for direct internet access. |
| WebSockets | WBO requires WebSocket support for real-time updates. Ensure reverse proxy passes Upgrade/Connection headers. |
| Port | Container port 80; default host binding 5001. Change -p HOST:80 in Docker run or Compose ports. |
| Auth | None built-in — boards are publicly accessible by URL. Add proxy-level auth to restrict access. |
| Board URLs | Any URL path = a board (e.g. /boards/my-class). No server-side access control per board. |
| Persistence | Board data written to server-data directory as JSON files. Back up the volume directory. |

## Upgrade procedure

```bash
docker pull lovasoa/wbo:v2.8.4
docker compose pull && docker compose up -d
```

Board data is in the mounted volume and survives upgrades. No schema migration required.

## Gotchas

- **UID 1000 ownership:** If the wbo-boards directory is not owned by UID 1000, the container will fail to write board data. Run `chown -R 1000:1000 wbo-boards` before starting.
- **WebSocket proxying:** WBO's real-time sync requires WebSocket support. If your proxy doesn't forward Upgrade/Connection headers, users will get a degraded polling experience or fail to connect.
- **WBO_IP_SOURCE mismatch:** If you set the wrong IP source, rate limiting breaks (either too permissive or blocks all users as the same IP). Match the env var to your actual proxy stack.
- **No per-board access control:** All boards are publicly readable and writable by URL. For private use, put WBO behind VPN or proxy-level basic auth.
- **Anonymous board:** The /boards/anonymous board is world-accessible and shared. Use a unique URL path for any private boards.
- **Node.js version:** Requires Node.js v22+. Older Node versions are not supported.

## Upstream links

- GitHub: <https://github.com/lovasoa/whitebophir>
- Docker Hub: <https://hub.docker.com/r/lovasoa/wbo>
- Demo: <https://wbo.ophir.dev>
