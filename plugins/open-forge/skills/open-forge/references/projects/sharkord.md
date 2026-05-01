---
name: Sharkord
description: "Self-hosted Discord-like real-time communication platform. Docker or binary. TypeScript/Bun + Mediasoup. Sharkord/sharkord. Voice channels, text chat, file sharing, WebRTC/SFU. Alpha stage."
---

# Sharkord

**Self-hosted Discord-like communication platform.** Voice channels (WebRTC/Mediasoup SFU), text chat, and file sharing — on your own infrastructure. No third-party dependencies, complete data ownership. Single binary bundles server + web client. Currently in **alpha stage**.

Built + maintained by **Sharkord team**. MIT license.

- Upstream repo: <https://github.com/Sharkord/sharkord>
- Docs: <https://sharkord.com/docs>
- Live demo: <https://demo.sharkord.com>
- Docker Hub: `sharkord/sharkord`

## Architecture in one minute

- **TypeScript + Bun** backend (JS runtime)
- **Mediasoup** WebRTC SFU (Selective Forwarding Unit) for real-time voice/video
- **tRPC** API layer
- **React + Radix UI + shadcn** frontend (bundled in the binary)
- **Drizzle ORM** for database
- Single container/binary — server + web client in one
- Ports: **4991** (web UI + API), **40000** (WebRTC media — TCP + UDP)
- Data stored in `/home/bun/.config/sharkord`
- Resource: **low-medium** — Bun runtime; Mediasoup adds load for voice/video

## Compatible install methods

| Infra         | Runtime                    | Notes                                                        |
| ------------- | -------------------------- | ------------------------------------------------------------ |
| **Docker**    | `sharkord/sharkord`        | **Primary** — Docker Hub                                     |
| **Binary**    | GitHub Releases            | Linux x64, Windows, macOS; single executable                 |

## Install via Docker

```bash
docker run -d \
  -p 4991:4991/tcp \
  -p 40000:40000/tcp \
  -p 40000:40000/udp \
  -v ./sharkord-data:/home/bun/.config/sharkord \
  --name sharkord \
  sharkord/sharkord:latest
```

Or Docker Compose:

```yaml
services:
  sharkord:
    image: sharkord/sharkord:latest
    ports:
      - "4991:4991/tcp"
      - "40000:40000/tcp"
      - "40000:40000/udp"
    volumes:
      - ./data:/home/bun/.config/sharkord
    restart: unless-stopped
```

Visit `http://localhost:4991`.

## First boot

1. Start the container.
2. **Check the container logs immediately** — Sharkord prints a secure owner token on first launch:
   ```bash
   docker logs sharkord
   ```
   Save this token securely. It grants full owner access to your server.
3. Visit `http://localhost:4991`.
4. Use the owner token to set up your server and create your admin account.
5. Create channels (text + voice) and invite users.
6. Put behind TLS — **required for WebRTC in browsers** (browsers enforce HTTPS for microphone/camera access).

## Install via binary (Linux)

```bash
curl -L https://github.com/Sharkord/sharkord/releases/latest/download/sharkord-linux-x64 -o sharkord
chmod +x sharkord
./sharkord
```

## Ports explained

| Port | Protocol | Purpose |
|------|----------|---------|
| 4991 | TCP | Web UI + API + WebSocket |
| 40000 | TCP + UDP | WebRTC media (voice/video via Mediasoup) |

Both ports must be open and reachable for voice/video to work. The UDP path is preferred by WebRTC for lower latency; TCP is the fallback.

## Gotchas

- **Alpha software.** Sharkord is in alpha — expect bugs, incomplete features, and breaking changes between releases. Don't rely on it for critical communications yet.
- **Owner token is one-time.** The secure token printed on first launch is the only way to claim owner access. If you lose it before using it, you may need to wipe the data volume and restart. Store it immediately.
- **WebRTC requires HTTPS.** Browsers require a secure context (HTTPS) for microphone and camera access. Put Sharkord behind a reverse proxy with TLS. Without TLS, voice/video won't work.
- **Port 40000 UDP must be open.** WebRTC media flows through port 40000. Firewall rules must allow UDP 40000 inbound — both from clients and, for some NAT setups, publicly reachable. If UDP is blocked, Mediasoup falls back to TCP but with higher latency.
- **Demo has limited WebRTC capacity.** The official demo at demo.sharkord.com has limited ports open — voice/video may not work with many concurrent users. Self-host for full capacity.
- **Mediasoup SFU model.** Mediasoup is a server-side SFU — audio/video flows through your server (not P2P). This means server bandwidth scales with the number of participants in voice channels. Plan bandwidth accordingly.

## Backup

```sh
docker compose stop sharkord
sudo tar czf sharkord-$(date +%F).tgz sharkord-data/
docker compose start sharkord
```

## Upgrade

```sh
docker compose pull && docker compose up -d
```

## Project health

Active TypeScript/Bun development, Mediasoup SFU, binary releases (Windows/macOS/Linux), Docker Hub. Solo/small team by Sharkord. MIT license. **Alpha stage.**

## Self-hosted-chat-family comparison

- **Sharkord** — TypeScript+Bun, Mediasoup SFU, Discord-like UX, single binary, MIT, alpha
- **Matrix/Element** — Matrix protocol, federated, E2E encryption, production-grade, complex
- **Rocket.Chat** — Node.js, full-featured Slack-alt, voice via Jitsi integration, production-grade
- **Mattermost** — Go, Slack-like, no native voice, production-grade
- **Revolt** — similar scope to Sharkord; also Discord-like self-hosted
- **Mumble** — C++, voice-only, no text/file sharing; very mature

**Choose Sharkord if:** you want a Discord-like self-hosted communication server (voice + text + file sharing) and are comfortable with alpha-stage software.

## Links

- Repo: <https://github.com/Sharkord/sharkord>
- Docs: <https://sharkord.com/docs>
- Demo: <https://demo.sharkord.com>
