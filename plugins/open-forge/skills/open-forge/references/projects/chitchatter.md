---
name: Chitchatter
description: "Serverless P2P chat. WebRTC E2E-encrypted. Ephemeral (no persistence). NO API SERVER required. GPL-v2. jeremyckahn creator. Vite + Trystero. Embeddable via iframe. File transfer via secure-file-transfer."
---

# Chitchatter

Chitchatter is **"Serverless Signal/Session — WebRTC P2P in the browser + decentralized + NO BACKEND"** — a free (price + freedom) P2P communication tool. **Browser-to-browser** via WebRTC; E2E encrypted; **ephemeral** (no disk persistence on client or server); **DECENTRALIZED** — no API server required (GitHub for static assets + public WebTorrent/TURN relays for P2P bootstrap). **Optional** API server for enhanced connectivity. Users share a room URL; anyone with URL joins. Room name = encryption key.

Built + maintained by **Jeremy Kahn (jeremyckahn)**. License: **GPL-v2**. Active; Snyk vuln-badge; official instance at chitchatter.im.

Use cases: (a) **private conversation without accounts** — share URL and chat (b) **group ephemeral chat** (c) **file transfer** without upload-to-server (d) **screen sharing** for quick help (e) **embedded chat** — `iframe` into other apps (f) **classroom-temporary-chat** (g) **incident-response-bridge** — ad-hoc (h) **privacy-focused-friends-chat**.

Features (per README):

- **P2P** (WebRTC) with TURN fallback
- **E2E encrypted**
- **Ephemeral** (no persistence)
- **Decentralized** (no API server required)
- **Multiple peers per room**
- **Public + private rooms**
- **Video + audio chat**
- **Screen sharing**
- **Direct messaging**
- **File sharing** (unlimited size; encrypted; chunked)
- **`iframe` embedding**
- **Markdown** + code syntax highlighting
- **Conversation backfilling** (new peers get history from current peers)

- Upstream repo: <https://github.com/jeremyckahn/chitchatter>
- Official instance: <https://chitchatter.im>
- Trystero (P2P lib): <https://github.com/dmotz/trystero>
- secure-file-transfer: <https://github.com/jeremyckahn/secure-file-transfer>

## Architecture in one minute

- **Vite + React** static site
- **WebRTC** (Trystero — handles DHT bootstrap via WebTorrent/MQTT/Firebase relays)
- **TURN fallback** for NAT-traversal
- **NO backend** (optional API server for relay enhancement)
- **Resource** (if self-hosted): just static hosting

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Static hosting** | **Nginx / Caddy / CDN**                                         | **Primary (it's a SPA)**                                                                        |
| **Docker**         | Static image with Nginx                                                                                                | Alt                                                                                   |
| **GitHub Pages**   | Official deploy                                                                                                        | Works                                                                                   |
| **Optional API**   | Enhanced connectivity; not required                                                                                   | Opt                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain (optional)    | `chat.example.com`                                          | URL          | TLS MANDATORY — WebRTC requires secure context                                                                                    |
| Static web host      | Any                                                         | Host         |                                                                                    |
| TURN server (optional)| coturn for reliable connectivity                           | Enhance      | Public relays may hit limits                                                                                    |
| API server (optional)| Node.js helper                                              | Enhance      | Not required                                                                                    |

## Install (static self-host)

Clone, build, deploy:
```sh
git clone https://github.com/jeremyckahn/chitchatter.git
cd chitchatter
npm ci
npm run build
# Deploy build/ to any static host with TLS
```

Docker (community):
```yaml
services:
  chitchatter:
    image: nginx:alpine
    volumes:
      - ./chitchatter-build:/usr/share/nginx/html:ro
    ports: ["80:80"]
```

## First boot

1. Deploy static site with TLS (mandatory for WebRTC)
2. Open; create a random-UUID room
3. Share URL via a secure medium (encrypted email, Signal, Burner Note, Yopass)
4. Second peer joins; WebRTC establishes
5. Test video/audio/file-transfer
6. Optionally deploy TURN (coturn) for NAT-constrained users
7. No backup needed (ephemeral)

## Data & config layout

- **Ephemeral** — no data on disk
- Static assets only (the SPA build)

## Backup

**No data to back up.** Ephemeral by design.

## Upgrade

1. Releases: <https://github.com/jeremyckahn/chitchatter/releases>. Active.
2. Rebuild + redeploy static
3. No state migration (stateless)

## Gotchas

- **124th HUB-OF-CREDENTIALS Tier 4/ZERO — ZERO-CREDENTIAL-HUB**:
  - NO persistent credentials; no accounts; no server-side state
  - Only "credential" is room URL = sharable = encryption key
  - **124th tool in hub-of-credentials family — Tier 4/ZERO**
  - **Zero-credential-hub-tool Tier 4/ZERO: 2 tools** (MAZANOKE+Chitchatter) 🎯 **2-TOOL MILESTONE**
  - **Zero-server-side-data-at-rest: 2 tools** (MAZANOKE+Chitchatter) 🎯 **2-TOOL MILESTONE**
- **ROOM-URL = ENCRYPTION-KEY**:
  - Whoever has the URL has full access (there's no additional auth)
  - Share URL over SECURE channel (not SMS, not email)
  - **Recipe convention: "URL-as-encryption-key-secure-sharing callout"** — critical
  - **NEW recipe convention** (Chitchatter 1st formally)
- **WEBRTC METADATA LEAKAGE**:
  - WebRTC reveals IP addresses to peers (unless TURN-only mode)
  - **Recipe convention: "WebRTC-IP-leakage-to-peers callout"** — critical
  - **NEW recipe convention** (Chitchatter 1st formally)
- **EPHEMERAL ≠ UNTRACEABLE**:
  - Messages not persisted, but ISPs + DNS still see connection patterns
  - Not anonymous (use Tor if that's the need)
  - **Recipe convention: "ephemeral-does-not-mean-anonymous" callout**
  - **NEW recipe convention** (Chitchatter 1st formally)
- **NO-API-SERVER ≠ NO-INFRASTRUCTURE**:
  - Depends on GitHub (static assets), WebTorrent/Firebase/MQTT public relays, TURN servers
  - If those fail or are attacked, service degrades
  - **Recipe convention: "no-backend-depends-on-public-relays" callout**
  - **NEW recipe convention** (Chitchatter 1st formally)
- **TRYSTERO DEPENDENCY**:
  - P2P bootstrap abstraction
  - Upstream lib is critical
  - **Recipe convention: "critical-upstream-library-dependency" callout**
  - Applies to many tools
- **GPL-v2 LICENSE**:
  - Classic copyleft
  - **Recipe convention: "GPL-v2-license positive-signal"**
- **SNYK VULN-BADGE**:
  - Public dependency-vuln monitoring
  - **Recipe convention: "Snyk-vulnerability-badge positive-signal"**
  - **NEW positive-signal convention** (Chitchatter 1st formally)
- **STATELESS-TOOL-RARITY**:
  - Fully stateless
  - **Stateless-tool-rarity: 12 tools** 🎯 **12-TOOL MILESTONE**
- **BURNER-NOTE / YOPASS RECOMMENDATION**:
  - README recommends using burner-note / Yopass for sharing URLs
  - Chain-of-secure-tools mentality
  - **Recipe convention: "chain-of-secure-tools-recommendation positive-signal"**
  - **NEW positive-signal convention** (Chitchatter 1st formally)
- **EMBEDDABLE VIA IFRAME**:
  - Composable with other web apps
  - **Recipe convention: "iframe-embeddable positive-signal"**
  - **NEW positive-signal convention** (Chitchatter 1st formally)
- **INSTITUTIONAL-STEWARDSHIP**: jeremyckahn + community + official instance + Snyk + Trystero-ecosystem. **110th tool — sole-maintainer-with-ecosystem-library sub-tier** (reuses prior).
- **TRANSPARENT-MAINTENANCE**: active + Snyk + official instance + docs + releases + logo-credit-to-contributor. **117th tool in transparent-maintenance family.**
- **P2P-CHAT-CATEGORY:**
  - **Chitchatter** — browser-only; WebRTC; zero-backend
  - **Signal** — mobile + desktop; commercial-scale; mature
  - **Session** — onion-routed; mature; Tor-like
  - **Jami** — P2P; mature; desktop
  - **Briar** — P2P over Tor; mobile
  - **Tox** — P2P; aging
- **ALTERNATIVES WORTH KNOWING:**
  - **Signal** — if you want mature + mobile + battle-tested
  - **Session** — if you want anonymity + Tor
  - **Jami** — if you want desktop P2P
  - **Choose Chitchatter if:** you want browser-only + no-install + zero-backend + share-URL simplicity.
- **PROJECT HEALTH**: active + Snyk + official-instance + static-deploy + clear-philosophy. Strong.

## Links

- Repo: <https://github.com/jeremyckahn/chitchatter>
- Official: <https://chitchatter.im>
- Trystero: <https://github.com/dmotz/trystero>
- Signal (alt): <https://signal.org>
- Session (alt): <https://getsession.org>
- Jami (alt): <https://jami.net>
