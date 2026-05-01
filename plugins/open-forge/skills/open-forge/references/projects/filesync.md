---
name: FileSync
description: "Self-hosted real-time file transfer tool between devices. Docker. Node.js. polius/FileSync. WebRTC P2P with PeerJS + TURN relay, end-to-end encryption, no file size limits, no server storage, send to multiple recipients simultaneously."
---

# FileSync

**Send files from one device to many in real-time.** Browser-based file transfer using WebRTC P2P connections — files transfer directly between browsers without being stored on the server. E2E encrypted. No file size limits. Send to multiple recipients simultaneously. Think AirDrop for any browser.

Built + maintained by **polius**. See repo license.

- Upstream repo: <https://github.com/polius/FileSync>
- Docker Hub: `poliuscorp/filesync`

## Architecture in one minute

- **Node.js** web application
- **PeerJS** (WebRTC peer discovery server) — `peerjs/peerjs-server`
- **Coturn** (TURN relay server) — `coturn/coturn` for NAT traversal when direct P2P fails
- Three containers: `filesync` (app) + `peerjs` (discovery) + `coturn` (relay)
- Port **80** (web UI)
- **No server-side file storage** — files go browser-to-browser via WebRTC
- E2E encrypted via WebRTC's built-in DTLS encryption
- Resource: **low** — Node.js + PeerJS; bandwidth scales with active transfers

## Compatible install methods

| Infra      | Runtime                  | Notes                                                           |
| ---------- | ------------------------ | --------------------------------------------------------------- |
| **Docker** | `poliuscorp/filesync`    | **Only method** — Docker Compose; 3-container stack             |

## Inputs to collect

| Input          | Example                                                    | Phase   | Notes                                                       |
| -------------- | ---------------------------------------------------------- | ------- | ----------------------------------------------------------- |
| `SECRET_KEY`   | base64 random string                                       | Security| **Required** — must be identical in `filesync` + `coturn`   |

Generate the secret key:
```bash
python3 -c "import secrets, base64; print(base64.b64encode(secrets.token_bytes(32)).decode())"
```

## Install via Docker Compose

```bash
# Download compose file
curl -O https://raw.githubusercontent.com/polius/FileSync/main/deploy/docker-compose.yml

# Edit: replace BOTH occurrences of <SECRET_KEY> with your generated key
nano docker-compose.yml

# Start
docker compose up -d
```

Compose file (simplified):

```yaml
services:
  filesync:
    image: poliuscorp/filesync
    ports:
      - "80:80"
    environment:
      - SECRET_KEY=your_generated_secret
    depends_on:
      - peerjs

  peerjs:
    image: peerjs/peerjs-server:1.1.0-rc.2
    command: peerjs --path /peerjs
    depends_on:
      - coturn

  coturn:
    image: coturn/coturn:alpine
    command:
      - --fingerprint
      - --use-auth-secret
      - --no-multicast-peers
      - --realm=filesync.app
      - --static-auth-secret=your_generated_secret  # SAME key as filesync
    ports:
      - "3478:3478/tcp"
      - "3478:3478/udp"
```

Visit `http://localhost`.

## First boot

1. Generate the `SECRET_KEY` (see above).
2. Replace **both** occurrences of `<SECRET_KEY>` in the compose file.
3. `docker compose up -d`.
4. Visit `http://localhost`.
5. You'll see a room code — share it with recipients.
6. Recipients open the same URL, enter the room code.
7. Drag and drop files to send — transfers begin immediately.
8. Put behind TLS (nginx/Caddy) for HTTPS — required for production and browser WebRTC in many contexts.

## How it works

1. Sender opens FileSync → gets a room code
2. Recipients join the room using the same URL + code
3. PeerJS facilitates WebRTC peer discovery (signaling)
4. WebRTC negotiates direct browser-to-browser connection
5. If direct P2P fails (strict NAT/firewall), Coturn relays the connection
6. Files transfer encrypted via WebRTC DTLS — no bytes touch the FileSync server

## Gotchas

- **Both `SECRET_KEY` values must match.** The compose file has two places with `<SECRET_KEY>`: the `filesync` app environment AND the `coturn` TURN server `--static-auth-secret`. They must be identical — if they differ, TURN relay fails and users behind strict NAT can't connect.
- **Port 3478 must be accessible for TURN relay.** When direct P2P fails, WebRTC falls back to the Coturn TURN server on port 3478 (TCP + UDP). This port must be open and reachable for users behind corporate firewalls or CG-NAT.
- **HTTPS required for production.** Browsers restrict WebRTC and camera/microphone APIs to secure contexts (HTTPS or localhost). Put FileSync behind a TLS reverse proxy for any non-localhost use.
- **No file size limit in the browser.** FileSync doesn't enforce a server-side file size limit since files don't pass through the server. Large file transfers are limited by browser memory and WebRTC transfer speed.
- **Multiple simultaneous recipients.** FileSync sends to all connected peers in the room simultaneously — each recipient gets the file in parallel, not sequentially.
- **No file persistence.** Files are not stored anywhere — if a recipient isn't connected when you send, they miss the transfer. Both sides must be connected and in the same room simultaneously.
- **Room codes expire.** After the session ends, room codes are gone. Generate a new room for each transfer session.

## Backup

FileSync is stateless — no data to back up (files aren't stored on the server).

## Upgrade

```sh
docker compose pull && docker compose up -d
```

## Project health

Active Node.js development, Docker Hub, WebRTC P2P, Coturn TURN relay, PeerJS. Solo-maintained by polius.

## Local-file-transfer-family comparison

- **FileSync** — Node.js, WebRTC P2P, multi-recipient simultaneous, no storage, Coturn relay
- **Pairdrop** — Node.js, local network WebRTC; no internet transfer
- **LocalSend** — Dart, local network only; no internet
- **OnionShare** — Python, Tor-based; more privacy-focused; slower
- **Snapdrop** — JS, mDNS local network; no internet
- **Sharedrop** — JS, WebRTC; similar approach; no TURN relay included

**Choose FileSync if:** you want browser-based file transfer that works across the internet (not just local network), with multi-recipient support, no file size limits, and no server-side storage.

## Links

- Repo: <https://github.com/polius/FileSync>
- Docker Hub: `poliuscorp/filesync`
