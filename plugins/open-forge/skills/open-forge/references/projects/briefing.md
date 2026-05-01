---
name: Briefing / Brie.fi/ng
description: "Secure direct WebRTC video group chat. Docker or Node. holtwick/briefing. No account needed, no data stored, peer-to-peer. AGPL + commercial license."
---

# Briefing (Brie.fi/ng)

**Secure direct video group chat over WebRTC.** Privacy-focused: no accounts, no data stored server-side — the server is just a signaling relay; actual media is peer-to-peer via WebRTC. Features desktop sharing, text chat, invite links. Works in all modern browsers, no plugin install needed. Free iOS app available.

Built + maintained by **Dirk Holtwick** (independent developer, Germany).

- Upstream repo: <https://github.com/holtwick/briefing>
- Hosted: <https://brie.fi/ng> (free to use)
- Docker Hub: <https://hub.docker.com/r/holtwick/briefing>
- iOS app: <https://apps.apple.com/app/briefing-video-chat/id1510803601>
- Docs: <https://github.com/holtwick/briefing/blob/master/docs/README.md>
- License: **AGPL 3.0** (public/OSS); **Commercial license** available for white-labeling

## Architecture in one minute

- **Vue 3 + TypeScript** SPA + **Zerva** signaling server (Node.js)
- Port **8080** — serves app + signaling endpoint
- WebRTC: actual A/V streams are **peer-to-peer** (STUN included); server only brokers the signaling handshake
- No accounts, no login, no persistent data — ephemeral rooms
- STUN server bundled (no TURN required for most LAN/Internet topologies; may need TURN behind symmetric NAT)
- Resource: **tiny** — just the signaling server; no media relay unless you add a TURN server

## Compatible install methods

| Infra          | Runtime                         | Notes                                                                        |
| -------------- | ------------------------------- | ---------------------------------------------------------------------------- |
| **Docker**     | `holtwick/briefing`             | **Easiest** — `docker run -d -p 8080:8080 holtwick/briefing`                |
| **Node**       | `npm run start` (dev)           | Clone + `npm install && npm run start`                                       |
| **Build+copy** | `npm run build:docker`          | Produces a `docker/` folder; copy to server + `docker compose up -d --build` |
| **fly.io**     | see `docs/fly.io.md`            | One-file deploy                                                              |
| **render.com** | see `docs/render.com.md`        | Free tier deploy                                                             |
| **Hosted**     | <https://brie.fi/ng>            | No setup; free for public rooms                                              |

## Inputs to collect

| Input       | Example                      | Phase  | Notes                                                                                           |
| ----------- | ---------------------------- | ------ | ----------------------------------------------------------------------------------------------- |
| Domain      | `meet.example.com`           | URL    | **TLS required for camera + microphone** — browsers block `getUserMedia` on non-HTTPS origins   |
| TURN server | coturn URL + creds (optional) | Network | Only needed if users behind symmetric NAT/firewall report video not connecting                 |

## Install via Docker

```sh
docker run -d -p 8080:8080 holtwick/briefing
```

Visit `http://localhost:8080`.

**For production (TLS required for camera access):**

```yaml
# docker-compose.yml (minimal)
services:
  briefing:
    image: holtwick/briefing
    restart: unless-stopped
    ports:
      - "8080:8080"
```

Put behind Caddy / nginx / Nginx Proxy Manager with HTTPS. Upstream recommends [nginxproxymanager.com](https://nginxproxymanager.com/).

Examples with proxy configs are in [docs/examples/](https://github.com/holtwick/briefing/tree/master/docs/installation).

## First boot

1. Deploy container + TLS proxy.
2. Visit `https://meet.example.com` — a random room URL is auto-generated.
3. Share the room URL with participants (no accounts, no registration).
4. Test camera + microphone access (requires HTTPS — see gotchas).
5. Optionally configure TURN server if users behind NAT can't connect.

## Configuration

Fine-tune via environment variables. See [docs/configuration.md](https://github.com/holtwick/briefing/blob/master/docs/configuration.md) for the full list. Common ones:

| Env var | Effect |
|---------|--------|
| `BRIEFING_PORT` | Override listen port |
| `BRIEFING_TURN_*` | Configure TURN server creds |
| `BRIEFING_SIGNAL_*` | Signaling server tuning |

## Embed

Briefing can be iframe-embedded into an existing site (useful for customer support, clinic portals, etc.). Use the [embed configurator](https://brie.fi/ng/embed-demo) to generate the snippet.

## Backup

Nothing to back up server-side — rooms are ephemeral; no user data, no recordings, no DB.

## Upgrade

1. Releases: <https://github.com/holtwick/briefing/releases>
2. `docker pull holtwick/briefing && docker compose up -d`

## Gotchas

- **HTTPS is mandatory for camera + microphone.** Browsers enforce this via the [getUserMedia privacy spec](https://developer.mozilla.org/en-US/docs/Web/API/MediaDevices/getUserMedia#privacy_and_security). HTTP-only deploys will show "camera not available." Put behind a TLS proxy before testing with real users.
- **TURN server for symmetric NAT.** WebRTC's STUN (bundled) works for most connections but fails if participants are behind symmetric NAT (common in some corporate networks / mobile ISPs). If users report "connecting..." forever, add a TURN server (coturn is the standard self-hosted option).
- **AGPL 3.0 license.** If you modify Briefing's source and serve it over a network, you must publish your modified source. For white-labeling / closed-source use, purchase the commercial license from `license@holtwick.de`.
- **Signaling server is the bottleneck, not the media.** The server only handles room negotiation (~KB of signaling traffic); media stays P2P. You can run Briefing on tiny hardware and support many concurrent rooms.
- **No recording, no storage, no logs of room content.** By design. If you need recording, you'll need a TURN relay + recording layer — not built in.
- **Room URLs are the only access control.** Rooms are open to anyone with the link — no passwords, no waiting room, no kick feature in the base version. Share links carefully for sensitive calls.
- **Localization**: README and docs are also available in German (`README-de.md`, `README-de.md`) — project has i18n support; community translations in `locales/`.
- **V2 replaced socket.io with Zerva.** V3 migrated to Vue 3 + TypeScript. If following old blog posts or StackOverflow answers referencing v1/socket.io, note that the architecture changed significantly.

## License note

**AGPL** for public/OSS. **Commercial license** required for white-labeling (building a product around Briefing, closed-source). Contact `license@holtwick.de`. One-time fee, not subscription.

## Project health

Active (v3 migrated to Vue3/Zerva), iOS app, hosted public instance, embed support, Docker Hub, fly.io + render.com deploy guides. Solo-maintained by Dirk Holtwick (sponsored via GitHub Sponsors).

## WebRTC-video-chat-family comparison

- **Briefing** — zero-setup, no accounts, P2P, signaling-only server, AGPL + commercial
- **Jitsi Meet** — full-featured, self-hosted, media server (Jitsi Videobridge), heavier
- **BigBlueButton** — enterprise-grade, webinar features, very heavy
- **Element / Matrix** — full communication suite; video is one feature
- **Daily.co / Whereby** — SaaS, not self-hosted

**Choose Briefing if:** you want a minimal, no-account WebRTC group chat with zero server-side user data, and can accept the link-sharing = access-control trade-off.

## Links

- Repo: <https://github.com/holtwick/briefing>
- Docs: <https://github.com/holtwick/briefing/blob/master/docs/README.md>
- Embed demo: <https://brie.fi/ng/embed-demo>
- Hosted instance: <https://brie.fi/ng>
- Jitsi Meet (alt): <https://jitsi.org>
- coturn (TURN server): <https://github.com/coturn/coturn>
