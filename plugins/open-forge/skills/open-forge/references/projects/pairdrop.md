---
name: PairDrop
description: AirDrop-like file-sharing web app that runs in any modern browser. Peer-to-peer via WebRTC for same-network transfers; temporary public rooms for cross-network; persistent device pairing via 6-digit code. Fork of Snapdrop with many improvements. Node.js. GPL-3.0.
---

# PairDrop

PairDrop is a self-hosted, browser-based, AirDrop-like file-sharing tool. Open the URL on two devices on the same network (or paired via code); one shows up as a peer on the other; click, send, done. No accounts. No installs (just a web page). Works on anything with a modern browser — iOS, Android, macOS, Windows, Linux, ChromeOS.

It's a fork of [Snapdrop](https://github.com/RobinLinus/snapdrop) with significant improvements:

- **Persistent device pairing** — pair once via 6-digit code / QR; pair persists across sessions
- **Temporary public rooms** — enter 5-letter code to share with anyone (good for public Wi-Fi, mobile hotspots, NATs)
- **Internet transfers via TURN** — fallback when direct P2P fails
- **Transfer requests** — receiver accepts before transfer starts
- **ZIP-bundled multi-file** download
- **Context-menu / Share-menu integration** — Windows context menu, Ubuntu Nautilus, iOS/Android Share menu, CLI
- **Video/audio previews** before accepting
- **Prevents device sleep** during transfer
- **Multi-tab / multi-device on one user** supported
- **Wake-lock** to keep phones alive mid-transfer

- Upstream repo: <https://github.com/schlagmichdoch/PairDrop>
- Hosted instance: <https://pairdrop.net>
- Host-your-own docs: <https://github.com/schlagmichdoch/PairDrop/blob/main/docs/host-your-own.md>
- FAQ: <https://github.com/schlagmichdoch/PairDrop/blob/main/docs/faq.md>
- Docker Hub: <https://hub.docker.com/r/lscr/pairdrop> (via LinuxServer.io)

## Architecture in one minute

- **Node.js backend** (signaling server)
- **Vanilla HTML/CSS/JS** frontend + Progressive Web App manifest
- **WebRTC** for peer-to-peer file transfer (files never touch your server if direct P2P works)
- **WebSockets** for signaling (which peers are online, exchange of WebRTC offers)
- **IndexedDB** on each device for paired-device secrets + transfer queue
- **Port 3000** by default
- **STUN/TURN** — PairDrop.net uses public STUN + provides TURN; for self-host, configure your own if you want internet transfers

## Compatible install methods

| Infra       | Runtime                                       | Notes                                                            |
| ----------- | --------------------------------------------- | ---------------------------------------------------------------- |
| Single VM   | Docker / Compose                               | **Most common**                                                   |
| Single VM   | Node.js 18+ native                                | `npm install && npm start`                                           |
| Raspberry Pi | Node.js ARM builds work                             | Low-power option                                                         |
| Kubernetes  | Any small Node.js chart                                | Minimal resources                                                           |
| Managed     | fly.io / Render / railway one-click                       | Public presence (requires TURN config)                                       |

## Inputs to collect

| Input                      | Example                           | Phase     | Notes                                                          |
| -------------------------- | --------------------------------- | --------- | -------------------------------------------------------------- |
| Port                       | `3000`                             | Network   | Default                                                           |
| `RTC_CONFIG`               | JSON with STUN/TURN servers         | NAT traversal | For internet transfers; without TURN = LAN-only                      |
| TLS                        | MUST be HTTPS for WebRTC API           | TLS       | Browsers block WebRTC on plain HTTP (except localhost)                   |
| `SIGNALING_SERVER` (implicit) | your domain                        | Network   | Clients auto-use the origin as signaling server                              |
| Rate limits (optional)      | `RATE_LIMIT=...`                    | Abuse     | Restrict connections per IP                                                    |
| `WS_FALLBACK=true` (optional) | enable                              | Fallback  | If WebRTC fails entirely, fall back to server-relayed transfer (slower + uses your bandwidth) |

## Install via Docker (LinuxServer.io image)

```yaml
services:
  pairdrop:
    image: lscr.io/linuxserver/pairdrop:latest    # pin a version tag when possible
    container_name: pairdrop
    restart: unless-stopped
    ports:
      - "3000:3000"
    environment:
      PUID: 1000
      PGID: 1000
      TZ: UTC
      # Optional — WebRTC NAT traversal
      # RTC_CONFIG: '{"iceServers":[{"urls":"stun:stun.l.google.com:19302"}]}'
      # WS_FALLBACK: "true"
```

Put behind a reverse proxy with TLS:

```
# Caddy
pairdrop.example.com {
    reverse_proxy 127.0.0.1:3000
    header {
        X-Content-Type-Options "nosniff"
        X-Frame-Options "SAMEORIGIN"
    }
}
```

Or build from source:

```sh
git clone https://github.com/schlagmichdoch/PairDrop
cd PairDrop
docker build -t pairdrop .
docker run -d --name pairdrop -p 3000:3000 pairdrop
```

## Install natively (Node.js)

```sh
git clone https://github.com/schlagmichdoch/PairDrop
cd PairDrop
npm install
npm start
# Listens on :3000
```

## Configure STUN/TURN (for internet transfers)

By default, self-hosted PairDrop can only discover peers on the SAME local network (subnet) via WebRTC's mDNS / host-candidate. For devices on different networks (phone on cellular + laptop on office Wi-Fi), you need:

1. **STUN** to learn your public IPs (can use Google's free STUN: `stun:stun.l.google.com:19302`)
2. **TURN** relay for when both peers are behind symmetric NATs (must run your own or buy)

Run your own TURN server with [coturn](https://github.com/coturn/coturn):

```yaml
# docker-compose snippet
  coturn:
    image: coturn/coturn:latest
    container_name: coturn
    restart: unless-stopped
    network_mode: host
    command: >
      -n
      --log-file=stdout
      --listening-port=3478
      --external-ip=<your-public-ip>
      --fingerprint
      --lt-cred-mech
      --user=pairdrop:<strong>
      --realm=pairdrop.example.com
    # Open UDP 3478 + 49152-65535 in firewall
```

Then in PairDrop:

```
RTC_CONFIG='{"iceServers":[{"urls":"stun:stun.l.google.com:19302"},{"urls":"turn:<your-public-ip>:3478","username":"pairdrop","credential":"<strong>"}]}'
```

## First use

1. Open `https://pairdrop.example.com` on device 1 → random name appears (like "Pink Lion")
2. Open same URL on device 2 (same LAN) → both devices see each other
3. Click the other device → file picker opens → select file(s) → other device gets "Accept?" prompt → accepted files download

For remote devices:

- **Pair permanently**: device 1 shows 6-digit code; device 2 enters it. Paired. Next time you open PairDrop, paired devices auto-show (across networks).
- **Temporary public room**: both enter the same 5-letter code. Room dissolves when last device leaves.

## Data & config layout

PairDrop is **stateless on the server** — no database, no uploads stored. Files pass through WebRTC; signaling just brokers the connection.

Client-side: IndexedDB holds paired-device secrets + display name preferences.

## Backup

Nothing to back up server-side.

Clients: tell users that clearing browser data clears paired devices (they'll need to re-pair).

## Upgrade

1. Releases: <https://github.com/schlagmichdoch/PairDrop/releases>. Active.
2. `docker compose pull && docker compose up -d`. No state migration.
3. Native: `git pull && npm install && npm start`.
4. **Zero downtime** possible — run a second instance, switch DNS; there's no persistent server state to worry about.

## Gotchas

- **HTTPS is mandatory** — browsers block the WebRTC DataChannel API on plain HTTP (except `localhost`). No TLS = no file transfers. Use Let's Encrypt via Caddy/Traefik.
- **Reverse-proxy must pass WebSockets** — add `Upgrade` / `Connection` headers in nginx. Most proxies do this out of the box (Caddy, Traefik). Cloudflare: enable WebSockets in the dashboard.
- **Same-network discovery** uses WebRTC's local-candidate exchange + the server tracking "peers on the same IP." If your server sees everyone as a single IP (behind a big NAT, e.g., CGNAT), peers will see each other that shouldn't. Use public rooms or pairing instead.
- **Internet transfer needs TURN** — direct P2P fails for ~20-30% of real-world network combinations. Without TURN, those transfers hang. Run coturn or use a TURN-as-a-service (ExpressTURN, Metered, Xirsys have small free tiers).
- **TURN uses your bandwidth** — relayed transfers pipe through your TURN server. A busy PairDrop with TURN needs real egress bandwidth budget.
- **Large files in memory** — some browsers buffer entire transfers in RAM. Chromium handles streaming well; older iOS Safari had limits (~2 GB). Test with your target file sizes.
- **No transfer resumption** — interrupt a 10 GB transfer, start over. PairDrop keeps resending chunks until the connection drops; if it drops, you restart.
- **Public rooms** accept anyone who enters the same 5-letter code. Don't use for sensitive stuff; use pairing.
- **Pairing secrets are stored in IndexedDB** — clearing browser data (private mode, "clear site data") unpairs. Enable persistence in Chrome via "add to home screen" for reliability.
- **LinuxServer.io image vs upstream**: LSIO uses their own init/PUID/PGID/Docker mods system; works fine but adds their wrapper. Upstream Dockerfile is simpler.
- **Snapdrop (parent project)** is largely dormant — PairDrop is where the active development is. Don't be confused if you find Snapdrop recipes online; they apply with differences.
- **Not end-to-end encrypted** at the application layer — relies on WebRTC's DTLS encryption for transport. Good against passive snooping; not hardened against malicious peers (which is fine since you only share with known devices).
- **File size limits** are browser-determined, not server-determined. Most browsers handle GBs fine.
- **Share menu integrations** require config steps specific to each OS — see the [how-to docs](https://github.com/schlagmichdoch/PairDrop/blob/main/docs/how-to.md) for Windows/Ubuntu/iOS/Android/CLI.
- **GPL-3.0 license** — copyleft.
- **Alternatives worth knowing:**
  - **Snapdrop** — the parent project; less actively maintained
  - **LocalSend** — native apps (iOS/Android/macOS/Windows/Linux); non-browser; no server needed at all (mDNS on LAN)
  - **Syncthing** — folder sync; different mental model
  - **Warpinator** (Linux Mint) — LAN file sending
  - **KDE Connect** / **GSConnect** — Linux desktop ↔ Android integration
  - **OnionShare** — Tor-based; anonymous one-shot transfers
  - **Croc** — CLI end-to-end encrypted transfer
  - **WeTransfer / SendAnywhere / Send Anywhere** — commercial SaaS
  - **Firefox Send** — discontinued
  - **Choose PairDrop if:** you want zero-install browser-only + AirDrop UX + persistent pairing across networks.
  - **Choose LocalSend if:** you're OK installing an app; you want the best LAN-first experience.
  - **Choose Syncthing if:** you want ongoing folder sync, not one-off sending.

## Links

- Repo: <https://github.com/schlagmichdoch/PairDrop>
- Hosted instance: <https://pairdrop.net>
- Host-your-own: <https://github.com/schlagmichdoch/PairDrop/blob/main/docs/host-your-own.md>
- How-to guides (OS integrations): <https://github.com/schlagmichdoch/PairDrop/blob/main/docs/how-to.md>
- FAQ: <https://github.com/schlagmichdoch/PairDrop/blob/main/docs/faq.md>
- LinuxServer.io Docker image: <https://hub.docker.com/r/linuxserver/pairdrop>
- Releases: <https://github.com/schlagmichdoch/PairDrop/releases>
- Snapdrop (parent): <https://github.com/RobinLinus/snapdrop>
- Translations (Weblate): <https://hosted.weblate.org/engage/pairdrop/>
- Donate: <https://www.buymeacoffee.com/pairdrop>
- coturn TURN server: <https://github.com/coturn/coturn>
