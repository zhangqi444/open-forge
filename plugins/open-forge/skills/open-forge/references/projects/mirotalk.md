---
name: MiroTalk P2P
description: "Self-hosted open-source WebRTC peer-to-peer video conferencing. Up to 8K @ 60fps, unlimited rooms + time. Chat, whiteboard, recording, ChatGPT integration, OIDC auth. Node.js. AGPL-3.0 (or one-time commercial license via CodeCanyon)."
---

# MiroTalk P2P

MiroTalk P2P is **"self-hosted Zoom/Meet via direct browser-to-browser WebRTC"** — no SFU (Selective Forwarding Unit), no media-relay server: participants connect peer-to-peer once signaling is complete. Up to **8K @ 60fps**, **unlimited rooms + unlimited time**, **chat + collaborative whiteboard + file sharing + screen sharing + recording + ChatGPT integration + OIDC auth + REST API + embeddable iframe + 133 languages**. Built + maintained by **Miroslav Pejic** as AGPLv3 open-source; **one-time commercial license** available via CodeCanyon for non-AGPL use. Sponsored by Recall.ai.

**Key design decision: P2P vs SFU.** MiroTalk P2P uses direct peer connections = low latency + no server bandwidth for media = but **scales poorly beyond ~6-8 participants** (N² connection mesh). For larger meetings, upstream's sister project **MiroTalk SFU** uses a selective forwarding unit — which scales to 20-50+ but requires more server resources. Choose based on meeting size.

Features:

- **Video up to 8K @ 60fps** — quality limited by browser + network
- **Screen sharing + recording** — saved locally by default
- **Picture-in-picture**
- **Chat** with Markdown + emoji
- **Collaborative whiteboard**
- **File sharing** via P2P
- **ChatGPT (OpenAI) integration** — in-meeting AI
- **Speech recognition**
- **OIDC auth** — integrate with your IdP
- **Host protection** + **JWT credentials** + **room passwords**
- **End-to-end encryption** (WebRTC DTLS-SRTP)
- **REST API**
- **Slack + Mattermost** integrations
- **Embeddable iframe + widget**
- **133 languages**

- Upstream repo: <https://github.com/miroslavpejic85/mirotalk>
- Homepage + demo: <https://p2p.mirotalk.com>
- Docs: <https://docs.mirotalk.com/mirotalk-p2p/>
- Self-hosting docs: <https://docs.mirotalk.com/mirotalk-p2p/self-hosting/>
- Discord: <https://discord.gg/rgGYfeYW3N>
- Sponsor: <https://github.com/sponsors/miroslavpejic85>
- Docker Hub: <https://hub.docker.com/r/mirotalk/p2p>
- Commercial license (one-time): <https://codecanyon.net/item/mirotalk-p2p-webrtc-realtime-video-conferences/38376661>
- Sister projects: **MiroTalk SFU** (scales further), **MiroTalk C2C**, **MiroTalk BRO** (broadcast)

## Architecture in one minute

- **Node.js / Express** signaling server
- **Socket.io** for signaling
- **WebRTC** for media — direct browser-to-browser
- **STUN server** (public) + **TURN server** (for NAT traversal fallback)
- **No DB required** for basic operation — stateless signaling
- **Resource**: server itself is TINY (signaling only). Media flows between clients. Server's bandwidth = low.

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Single VM          | **Docker / Docker Compose**                                        | **Upstream-primary**                                                               |
| Bare-metal Node    | Node.js 18+ + `npm install && npm start`                                   | Simple; dev-friendly                                                                       |
| Kubernetes         | Helm chart / manifests                                                                | Works                                                                                                  |
| PaaS               | DigitalOcean App Platform / Railway / Render                                                      | One-click patterns                                                                                                  |

## Inputs to collect

| Input                | Example                                                       | Phase        | Notes                                                                    |
| -------------------- | ------------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `meet.example.com`                                                | URL          | **TLS MANDATORY** — WebRTC `getUserMedia` requires HTTPS                         |
| TURN server          | coturn (self-host) / Metered / Twilio NTS / Xirsys                          | NAT traversal | **REQUIRED for users behind strict NATs/firewalls** — without it ~20% connections fail                                         |
| OIDC (opt)           | Keycloak / Authentik / Authelia / Kanidm (batch 76)                          | Auth         | For authenticated-only access                                                                                                 |
| JWT secret           | random 32+ chars                                                                  | Secret       | Set once; rotate = all tokens invalid (immutability class)                                                                                             |
| Host password        | for "host protection" feature                                                                | Room control | Prevents rogue hosts                                                                                                                 |
| ChatGPT API key (opt)| OpenAI API key                                                                                    | AI           | Optional feature; billable                                                                                                                                  |

## Install via Docker Compose

```sh
git clone https://github.com/miroslavpejic85/mirotalk.git
cd mirotalk
cp .env.template .env
# edit .env — TRUST_PROXY, TURN_URLS, TURN_USERNAME, TURN_PASSWORD, JWT_KEY, etc.
cp app/src/config.template.js app/src/config.js
docker compose up -d
```

Browse `http://<host>:3000/`.

## First boot

1. Deploy + set strong `JWT_KEY`
2. Configure TURN (self-host coturn or use managed Metered/Xirsys/Twilio NTS)
3. Put behind TLS reverse proxy with WebSocket upgrade + WebRTC port forwarding if any
4. Create test room → join from 2 devices (ideally different networks, not same LAN) to validate NAT traversal
5. Configure OIDC if wanted
6. Tune UI + branding via `app/src/config.js`
7. Optional: wire ChatGPT for in-meeting AI
8. Set up host-protection password

## Data & config layout

- `.env` — server secrets (JWT_KEY, TURN_PASSWORD, OIDC secrets, ChatGPT key)
- `app/src/config.js` — UI + behavior config
- Recordings — by default saved to user's local disk (not server-side; unusual privacy-win)
- No persistent DB in basic setup

## Backup

```sh
sudo tar czf mirotalk-$(date +%F).tgz .env app/src/config.js
```

Recordings are client-side; users back up their own.

## Upgrade

1. Releases: <https://github.com/miroslavpejic85/mirotalk/releases>. Active.
2. Docker: bump tag OR `git pull && docker compose up -d --build`.
3. Review changelog — WebRTC + browser compat can shift.
4. **AGPL §13 reminder**: if you run modified MiroTalk as a commercial service, source disclosure required; or buy CodeCanyon license.

## Gotchas

- **P2P vs SFU is THE architectural decision.** P2P = ~6-8 participants max (browser CPU + upload bandwidth per-peer becomes limiting). Beyond that, MiroTalk SFU or Jitsi Meet or LiveKit. Know your meeting-size profile BEFORE deploying.
- **TURN SERVER IS EFFECTIVELY MANDATORY.** Corporate firewalls + carrier-grade NAT + mobile networks BLOCK direct WebRTC. Without TURN ~20-40% of connection attempts fail silently. Options:
  - **Self-host coturn** (OSS) on a VPS with public IP + open UDP ports 3478, 49152-65535
  - **Managed TURN** (Metered, Xirsys, Twilio NTS) — pay-per-minute, simpler
  - **No TURN**: works on LANs + cooperative networks; breaks elsewhere
- **HTTPS is non-negotiable.** `getUserMedia` (camera/mic) refuses to prompt on HTTP. TLS for the signaling server + TURNS (TLS over 5349) for full encryption in transit on hostile networks.
- **WebRTC port ranges** (49152-65535 UDP typically) must be open on firewalls. Corporate users report blocked firewalls regularly.
- **P2P N² mesh**: 4 participants = 12 connections (each uploads to 3); 8 participants = 56. Upload bandwidth per peer grows linearly. Users on mobile/slow-up = quality collapses.
- **AGPL-3.0 commercial considerations**: self-host privately OR buy CodeCanyon one-time commercial license for commercial service. Same pattern as AnonAddy, WriteFreely, etc., but with explicit alternative-license purchase option that's one-time not recurring (a genuine differentiator).
- **ChatGPT integration = data leaves your instance.** In-meeting AI features send transcripts to OpenAI. Review + communicate to participants before enabling. Consent + privacy policy implication. Same AI-privacy-boundary class as WhoDB / Baserow Kuma / ezBookkeeping (batches 77-78).
- **JWT + OIDC**: for public-facing deployments, require auth. For internal-team use, JWT room-tokens suffice. Open access = Zoom-bombing risk.
- **Recording is client-side by default** — unusual + privacy-preserving. If you need server-side recording (compliance, archival), that's NOT what MiroTalk P2P provides; look at Jitsi Meet's Jibri or Recall.ai (MiroTalk's sponsor).
- **Browser compat**: WebRTC is well-supported (Chrome/Edge/Firefox/Safari). iOS Safari has historical issues — test on current versions.
- **"Up to 8K"** is theoretical — browser decoder + camera + upload bandwidth will almost always limit well below. Realistic: 1080p/30 for most participants is great quality.
- **Embeddable iframe + widget** for integrating video into your existing app — underrated feature for SaaS products wanting meeting rooms without building from scratch.
- **133 languages** — community translation. A healthy global project signal.
- **Project health**: Miroslav Pejic solo-led core + growing community + commercial licensing revenue + Recall.ai sponsorship. Bus-factor-1 mitigated by (a) popularity (multi-K stars) (b) Recall.ai sponsor (c) commercial licensing revenue. Active releases.
- **Alternatives worth knowing:**
  - **Jitsi Meet** — the incumbent FOSS video. Feature-rich SFU; 50+ participants; JVB infrastructure required
  - **LiveKit** — modern WebRTC SFU; developer-friendly
  - **BigBlueButton** — education-focused; feature-heavy
  - **MiroTalk SFU** — sister project; handles more participants
  - **Janus** / **Mediasoup** — WebRTC media server libraries
  - **Whereby** / **Zoom** / **Google Meet** — commercial SaaS
  - **Choose MiroTalk P2P if:** small meetings (≤8) + minimal infra + maximum quality per-participant.
  - **Choose MiroTalk SFU / Jitsi Meet if:** larger meetings + willing to run SFU.
  - **Choose LiveKit if:** building a custom product around WebRTC.

## Links

- Repo: <https://github.com/miroslavpejic85/mirotalk>
- Homepage + demo: <https://p2p.mirotalk.com>
- Docs overview: <https://docs.mirotalk.com/overview/>
- Self-hosting: <https://docs.mirotalk.com/mirotalk-p2p/self-hosting/>
- Host protection: <https://docs.mirotalk.com/mirotalk-p2p/host-protection/>
- Integration: <https://docs.mirotalk.com/mirotalk-p2p/integration/>
- Discord: <https://discord.gg/rgGYfeYW3N>
- Docker Hub: <https://hub.docker.com/r/mirotalk/p2p>
- Commercial license (CodeCanyon): <https://codecanyon.net/item/mirotalk-p2p-webrtc-realtime-video-conferences/38376661>
- Sponsor: <https://github.com/sponsors/miroslavpejic85>
- MiroTalk SFU (scales further): <https://github.com/miroslavpejic85/mirotalk-sfu>
- Jitsi Meet (alt): <https://jitsi.org>
- LiveKit (alt): <https://livekit.io>
- BigBlueButton (alt): <https://bigbluebutton.org>
- coturn (TURN server): <https://github.com/coturn/coturn>
- Metered TURN: <https://www.metered.ca/tools/openrelay/>
