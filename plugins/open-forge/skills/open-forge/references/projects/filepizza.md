---
name: FilePizza
description: "Browser-to-browser peer-to-peer file transfers via WebRTC — no server-side storage, no upload step. Short/long URLs, password protection, multi-file ZIP downloads, Service-Worker streaming. Next.js + TypeScript. BSD-3-Clause."
---

# FilePizza

FilePizza is the spiritual cousin of PairDrop: "send a file from my browser to yours without ever uploading it to a server." You pick files in your browser, get a short URL, send it to someone. They open the URL, the transfer runs WebRTC peer-to-peer directly between browsers. Your browser has to stay open until the transfer completes.

Hosted instance: **<https://file.pizza>** — use it without any setup.

Differences vs PairDrop:

- **Link-based, not peer-discovery**: FilePizza generates a URL to share; receiver opens it (no "same network" concept)
- **No persistent pairing** — each share is ephemeral
- **Password protection** optional
- **ZIP download for multi-file** transfers
- **Service Worker streaming** — receiver downloads in chunks, not buffered in memory
- **Works on mobile browsers** (including iOS Safari since v2)

Recent (v2) improvements:

- Dark-mode UI
- Direct WebRTC (dropped WebTorrent complexity)
- Redis-backed channel metadata (multi-instance scaling)
- Sender progress monitoring + cancellation
- Password + reporting

- Upstream repo: <https://github.com/kern/filepizza>
- Hosted instance: <https://file.pizza>
- Namesake comic: <https://xkcd.com/949/> (xkcd "File Transfer")

## Architecture in one minute

- **Next.js** (React + TypeScript) frontend + backend
- **PeerJS** (WebRTC abstraction) for browser-to-browser transfer
- **Redis** (optional) — stores channel metadata for multi-replica deploys; falls back to in-memory
- **PeerJS server** — can run embedded (default) OR point at self-hosted PeerJS
- **coturn** (optional) — TURN relay for NAT traversal
- **No file storage on server** — zero-byte server; bandwidth only for signaling

## Compatible install methods

| Infra       | Runtime                                          | Notes                                                              |
| ----------- | ------------------------------------------------ | ------------------------------------------------------------------ |
| Single VM   | Docker / Compose                                   | **Most common**                                                       |
| Single VM   | Node.js + `pnpm build && pnpm start`                  | Native                                                                    |
| PaaS        | Vercel / Render / Fly                                 | Works; TURN config needed for public access                                  |
| Kubernetes  | Tiny Node.js chart                                    | Redis for multi-replica                                                        |

## Inputs to collect

| Input             | Example                              | Phase     | Notes                                                          |
| ----------------- | ------------------------------------ | --------- | -------------------------------------------------------------- |
| Port              | `3000`                                | Network   | Default                                                          |
| `REDIS_URL`       | `redis://redis:6379`                   | Scale     | Multi-instance scaling; in-memory is fine for single host               |
| `COTURN_ENABLED`  | `true`                                 | NAT       | Enable TURN relay for internet NAT traversal                                |
| `TURN_HOST`       | your public IP                         | NAT       | Required if COTURN_ENABLED                                                      |
| `TURN_REALM`      | your domain                             | NAT       | Defaults to `file.pizza`                                                              |
| `STUN_SERVER`     | `stun:stun.l.google.com:19302`          | NAT       | Default                                                                                        |
| `PEERJS_HOST`     | `0.peerjs.com`                           | Signaling | Default uses public PeerJS; set to your own for self-contained deploy                               |
| `PEERJS_PATH`     | `/`                                       | Signaling | Default                                                                                                  |
| TLS               | REQUIRED                                  | Security  | WebRTC DataChannel only works over HTTPS (except localhost)                                                        |

## Install via Docker Compose

```yaml
services:
  filepizza:
    image: ghcr.io/kern/filepizza:latest    # pin a version tag
    container_name: filepizza
    restart: unless-stopped
    ports:
      - "3000:3000"
    environment:
      REDIS_URL: redis://redis:6379
      # Optional TURN
      # COTURN_ENABLED: "true"
      # TURN_HOST: <your-public-ip>
      # TURN_REALM: filepizza.example.com
    depends_on:
      - redis

  redis:
    image: redis:7-alpine
    container_name: filepizza-redis
    restart: unless-stopped
    volumes:
      - filepizza-redis:/data

  # Optional self-hosted TURN (coturn)
  # coturn:
  #   image: coturn/coturn:latest
  #   container_name: coturn
  #   restart: unless-stopped
  #   network_mode: host
  #   command: >
  #     -n --listening-port=3478
  #     --external-ip=<your-public-ip>
  #     --fingerprint --lt-cred-mech
  #     --user=filepizza:<strong>
  #     --realm=filepizza.example.com

volumes:
  filepizza-redis:
```

Reverse proxy for TLS (required):

```
# Caddy
files.example.com {
    reverse_proxy 127.0.0.1:3000
}
```

## Install from source (`pnpm`)

```sh
git clone https://github.com/kern/filepizza.git
cd filepizza
pnpm install
pnpm build
pnpm start
# Listens on :3000
```

## First use

1. Open `https://files.example.com`
2. Drop or select file(s)
3. Optionally set a password
4. Get a short + long URL → share them
5. Receiver opens URL → enters password (if set) → WebRTC handshake → file streams directly

Uploader's browser must stay open until transfer completes.

## Data & config layout

- Nothing on disk on the server (apart from Redis channel metadata)
- Client-side state only — no user accounts, no history

## Backup

Nothing to back up server-side. FilePizza is stateless.

## Upgrade

1. Releases: <https://github.com/kern/filepizza/releases>. Moderate-paced.
2. `docker compose pull && docker compose up -d`. Zero-state means no migrations.
3. Redis cached channels can be flushed at will (`redis-cli FLUSHDB`); breaks any in-flight transfers.
4. v1 → v2 was a major rewrite — new docker image, new architecture. Upgrade paths are "wipe + redeploy."

## Gotchas

- **HTTPS is mandatory** — WebRTC's DataChannel API requires a secure context. Browsers refuse to initiate peer connections from plain HTTP (except on `localhost`). Deploy behind Caddy/Traefik/nginx with Let's Encrypt.
- **Uploader's browser must stay open** — if you close the tab, the URL dies. Long transfers = keep the tab alive.
- **No resume** — interrupted transfers restart from zero.
- **File size is browser-limited**, not server-limited. Modern Chrome/Edge/Firefox handle >10 GB in streaming mode. Older iOS Safari had memory limits.
- **TURN relay for NAT traversal** — direct P2P works for most home-to-home cases but fails across corporate NATs, CGNATs, symmetric NATs. Enable COTURN for reliability; otherwise expect ~20-30% failure rate in adversarial networks.
- **Public PeerJS cloud** — default `PEERJS_HOST=0.peerjs.com` means your signaling goes through a public service. For self-contained deploy, run `peerjs-server` and point `PEERJS_HOST`/`PATH` at it.
- **Abuse reporting**: v2 added reporting; spammers sharing illegal content via URLs is a real risk on public deploys. Private/invite-only usage is safer.
- **Abuse prevention**: consider rate limits at reverse proxy (e.g., Caddy rate-limit module) + short TTLs in Redis.
- **Not a "long-term" file-sharing service** — this is ephemeral. Use Nextcloud/Seafile/S3 for persistent sharing.
- **WebRTC encryption** — all transfers are DTLS-encrypted at the transport layer. Add a password for UI-level confirmation.
- **Service Worker streaming** lets receivers "stream" a download to disk rather than buffering in RAM — critical for large files on memory-constrained devices (phones). v2 enables this by default.
- **Multi-file ZIP**: sender selects many; receiver downloads a single ZIP. Zip is composed client-side; memory depends on browser implementation.
- **Corporate firewalls** may block WebRTC ports entirely (UDP 49152-65535). Users on corporate Wi-Fi may need to tether to mobile for transfers.
- **Self-host on a tiny VPS** — FilePizza itself uses minimal resources; only TURN (if enabled) needs bandwidth budget.
- **BSD-3-Clause license** — permissive; commercial use OK.
- **Alternatives worth knowing:**
  - **PairDrop** — LAN-first + public rooms + pairing; no link URL model (separate recipe)
  - **LocalSend** — native apps; LAN-first; mDNS peer discovery
  - **WormHole (wormhole.app)** — E2E encrypted; up to 10 GB free; nice UX but commercial
  - **Croc** — CLI E2E encrypted; great for tech users
  - **OnionShare** — Tor-based anonymous transfers
  - **Magic Wormhole** — original CLI tool; FilePizza is loosely inspired by its UX (short codes)
  - **Firefox Send** — discontinued in 2020
  - **Sharedrop / Snapdrop** — older AirDrop-web clones
  - **Choose FilePizza if:** you want link-based P2P in the browser, no account needed, no server storage.
  - **Choose PairDrop if:** you want AirDrop-style device discovery + pairing.
  - **Choose LocalSend if:** you're OK with native apps; best LAN UX.

## Links

- Repo: <https://github.com/kern/filepizza>
- Hosted instance: <https://file.pizza>
- xkcd 949 (the comic): <https://xkcd.com/949/>
- Releases: <https://github.com/kern/filepizza/releases>
- PeerJS: <https://peerjs.com>
- PeerJS server: <https://github.com/peers/peerjs-server>
- coturn: <https://github.com/coturn/coturn>
- Author (Alex Kern): <https://kern.io>
