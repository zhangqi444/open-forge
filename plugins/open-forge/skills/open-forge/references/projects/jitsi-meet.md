---
name: jitsi-meet-project
description: Jitsi Meet recipe for open-forge. Apache-2.0 secure, fully-open-source video conferencing — WebRTC-based, no account needed, HD audio/video, screen sharing, breakout rooms, polls, raise-hand, chat with private conversations, E2EE (Palava protocol), virtual backgrounds, mobile apps (Android/iOS + F-Droid). Used by 8x8 (via JaaS hosted) and thousands of orgs. Architecture has 4 components (prosody XMPP, jicofo conference focus, jitsi-meet web, JVB video bridge) — `docker-jitsi-meet` bundles them. Covers the official Docker Compose install, ports + UDP media reality, Let's Encrypt automation, NAT/JVB_ADVERTISE_IPS mystery, Debian/Ubuntu apt install path, and JaaS as the managed alternative.
---

# Jitsi Meet

Apache-2.0 secure video conferencing. Upstream: <https://github.com/jitsi/jitsi-meet>. Handbook: <https://jitsi.github.io/handbook/>. Docker: <https://github.com/jitsi/docker-jitsi-meet>. Maintained by 8x8. Public instance: <https://meet.jit.si>.

Browser-based video conferencing (any WebRTC-capable browser; mobile apps also available). Anyone with the meeting URL can join — no account required by default. Scales from 2-person calls to large webinars (with scaling adjustments).

## Features

- HD audio + video, Opus + VP8/VP9/AV1
- Screen sharing, presenter mode
- Chat (public + private 1:1)
- Reactions, raise hand, polls
- Virtual backgrounds (blur or image)
- Breakout rooms
- Recording (via Jibri — separate component) and live streaming to YouTube
- Dial-in via Jigasi (SIP gateway — separate component)
- **End-to-End Encryption** for 1:1 calls (WebRTC E2EE, experimental for group calls)
- i18n, mobile apps, SDK for embedding in your own app
- No user accounts needed (optional auth via XMPP / OIDC / JWT can be enabled)

## Architecture (the 4 core components)

| Component | Role | Default Docker image |
|---|---|---|
| **prosody** | XMPP server — signaling, presence, MUC rooms | `jitsi/prosody` |
| **jicofo** (Jitsi Conference Focus) | Selects one JVB per conference; manages conference-level state | `jitsi/jicofo` |
| **jitsi-meet-web** | Static web client + API proxy (nginx) | `jitsi/web` |
| **JVB** (Jitsi Videobridge) | SFU — forwards media between participants | `jitsi/jvb` |

Optional:

- **Jibri** — recording + streaming.
- **Jigasi** — SIP gateway (dial-in by phone).
- **Etherpad-lite** — collaborative notes inside meeting.

`docker-jitsi-meet` bundles all 4 core components as separate containers.

## ⚠️ UDP + NAT = the hard part

Video conferencing over WebRTC requires UDP for media. If any of:

- Server behind NAT without port forwarding
- Server in a cloud VPC without the right firewall rules
- UDP port 10000 blocked anywhere between client and server

…your meetings "join" but no one can see/hear anyone. Symptoms: the meeting loads, you see participants, but video + audio are black/silent.

**Required firewall / NAT config:**

| Port | Protocol | Purpose |
|---|---|---|
| 80 | TCP | HTTP (redirects to HTTPS) + Let's Encrypt HTTP-01 challenge |
| 443 | TCP | HTTPS (web UI + WebSocket signaling) |
| 10000 | **UDP** | **Media (JVB → participants). The critical one.** |
| 4443 | TCP | JVB media fallback (TCP when UDP blocked) |

Also: `JVB_ADVERTISE_IPS` env var must be set to the server's PUBLIC IP(s) if the server is behind NAT. Without it, JVB tells clients "connect back to my private IP," which they can't.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose (`docker-jitsi-meet`) | <https://github.com/jitsi/docker-jitsi-meet> | ✅ Recommended | Most self-hosters. |
| Debian/Ubuntu apt (`jitsi-meet` package) | <https://jitsi.github.io/handbook/docs/devops-guide/devops-guide-quickstart> | ✅ | Bare-metal linux, long-running production. |
| Kubernetes | <https://github.com/jitsi-contrib/jitsi-kubernetes> + community Helm | ⚠️ Community | Clusters. |
| Source build (all 4 components) | <https://jitsi.github.io/handbook/docs/dev-guide/> | ✅ | Devs. |
| JaaS (8x8 Jitsi as a Service) | <https://jaas.8x8.vc> | ✅ paid | Managed service — skip the whole stack. |
| Public `meet.jit.si` | <https://meet.jit.si> | Free | Don't self-host. |

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Install method?" | `AskUserQuestion`: `docker-compose` / `debian-apt` / `kubernetes` | Drives section. |
| dns | "Public domain?" | Free-text, e.g. `meet.example.com` | Sets `PUBLIC_URL`. Must point to server IP. |
| tls | "Let's Encrypt?" | Boolean | Docker stack can auto-provision via built-in certbot. Needs port 80 reachable. |
| tls | "ACME email?" | Free-text, e.g. `admin@example.com` | Required for Let's Encrypt. |
| network | "Server behind NAT / has a private IP?" | Boolean | If yes → set `JVB_ADVERTISE_IPS=<public-ip>`. |
| network | "Firewall allows UDP 10000 inbound?" | Boolean | If no, open it. Non-negotiable. |
| ports | "HTTP port / HTTPS port?" | Defaults `80` / `443` (or `8000` / `8443` in docker quickstart) | Many docker configs use high ports + reverse-proxy. |
| auth | "Require authentication to create rooms?" | `AskUserQuestion`: `none (anyone can create)` / `internal (local users)` / `jwt` / `matrix` | Default is none (public-by-default). |
| record | "Enable recording (Jibri)?" | Boolean | Adds a Jibri container; requires extra setup. |
| record | "Enable SIP dial-in (Jigasi)?" | Boolean | Adds a Jigasi container. |

## Install — Docker Compose (docker-jitsi-meet)

Upstream install guide: <https://jitsi.github.io/handbook/docs/devops-guide/devops-guide-docker>.

```bash
# Download the official bundle
git clone https://github.com/jitsi/docker-jitsi-meet -b stable
cd docker-jitsi-meet

# Copy env template and edit
cp env.example .env

# Required: generate strong random passwords
./gen-passwords.sh

# Create config dirs (referenced in .env as $CONFIG)
mkdir -p ~/.jitsi-meet-cfg/{web,transcripts,prosody/config,prosody/prosody-plugins-custom,jicofo,jvb,jigasi,jibri}
```

Edit `.env` — the essentials:

```bash
# .env (excerpt — see full env.example for options)
CONFIG=~/.jitsi-meet-cfg
HTTP_PORT=8000
HTTPS_PORT=8443
TZ=UTC
PUBLIC_URL=https://meet.example.com:8443   # include port if non-standard
# JVB_ADVERTISE_IPS=<public-ip-or-empty>   # REQUIRED if behind NAT

# Let's Encrypt (optional but recommended for production)
ENABLE_LETSENCRYPT=1
LETSENCRYPT_DOMAIN=meet.example.com
LETSENCRYPT_EMAIL=admin@example.com
# LETSENCRYPT_USE_STAGING=1   # uncomment for testing to avoid LE rate limits
```

Start:

```bash
docker compose up -d
docker compose logs -f
# → https://meet.example.com:8443
```

### Port 80 + 443 (no non-standard ports)

If you want the stack to bind directly to 80/443 (no reverse proxy):

```bash
# .env
HTTP_PORT=80
HTTPS_PORT=443
PUBLIC_URL=https://meet.example.com
```

Make sure no other process has those ports bound, and make sure Let's Encrypt HTTP-01 challenges can reach your server on port 80.

### Authentication (optional)

By default, anyone who visits your URL can create a room with any name. To restrict room creation:

```bash
# .env
ENABLE_AUTH=1
AUTH_TYPE=internal      # or 'jwt' / 'matrix' / 'ldap'
ENABLE_GUESTS=1         # 1 = guests can join if an authenticated user creates the room
```

Then create users inside the prosody container:

```bash
docker compose exec prosody prosodyctl --config /config/prosody.cfg.lua register alice meet.jitsi alicepass
```

### docker-compose services (built-in)

The upstream compose contains `jitsi`, `prosody`, `jicofo`, `jvb` (and optionally `jibri`, `jigasi`, `etherpad`, `whisper`). All 4 core containers are mandatory.

## Install — Debian/Ubuntu (apt)

```bash
# From jitsi.github.io/handbook docs
echo 'deb https://download.jitsi.org stable/' | sudo tee /etc/apt/sources.list.d/jitsi-stable.list
curl -sSL https://download.jitsi.org/jitsi-key.gpg.key | sudo apt-key add -
sudo apt update
sudo apt install jitsi-meet
# Installer prompts for domain + Let's Encrypt email
```

The apt package installs all components + nginx + configs + systemd units. Debian 12 / Ubuntu 22.04+ recommended.

## Reverse proxy (when using the Docker stack with non-standard ports)

If you're fronting with nginx / Caddy / Traefik instead of Jitsi's built-in nginx:

```caddy
meet.example.com {
    reverse_proxy jitsi:8443 {
        transport http {
            tls_insecure_skip_verify
        }
    }
}
```

⚠️ The JVB UDP port (10000) cannot be reverse-proxied by HTTP-layer tools. It must be reachable directly on the server's public IP, OR port-forwarded transparently at the firewall level.

## Recording + streaming (Jibri)

Jibri records conferences to local files / streams to YouTube. Requires:

- A dedicated Chromium + X11 environment (Jibri runs a headless browser that joins the meeting and records the rendered output).
- Significant CPU (one Jibri instance can record ONE meeting at a time).
- Extra container + extra configuration.

See <https://jitsi.github.io/handbook/docs/devops-guide/devops-guide-docker#jibri-recording--live-streaming>.

## Data layout

| Path (`$CONFIG`) | Content |
|---|---|
| `~/.jitsi-meet-cfg/web/` | Web component configs + Let's Encrypt certs |
| `~/.jitsi-meet-cfg/prosody/` | XMPP config + virtual host + user DB |
| `~/.jitsi-meet-cfg/jicofo/` | Jicofo config |
| `~/.jitsi-meet-cfg/jvb/` | Videobridge config |
| `~/.jitsi-meet-cfg/transcripts/` | Recording artifacts (if enabled) |
| `~/.jitsi-meet-cfg/jibri/` | Recordings output dir |

**Backup**: `prosody/` (users, rooms) + `web/` (certs). Others regenerate from config.

## Upgrade procedure

```bash
cd docker-jitsi-meet
git pull
docker compose pull
docker compose down
docker compose up -d
docker compose logs -f
```

Read release notes: <https://github.com/jitsi/jitsi-meet/releases>. Major Jitsi versions may require `CONFIG` dir regeneration for internal config format changes.

## Gotchas

- **UDP 10000 is non-negotiable.** If this port is blocked anywhere between client and server (ISP, NAT, cloud firewall, container network), media WILL NOT flow. "Meeting joins fine but video black" = UDP problem 95% of the time. Fall-back to TCP 4443 works but adds latency.
- **`JVB_ADVERTISE_IPS`** needs the SERVER'S PUBLIC IP if behind NAT. Look up `curl ifconfig.me` on the server and set it. Without this, clients try to connect to the server's private IP and fail.
- **Cloud providers block UDP by default.** AWS EC2, GCP, Azure all require explicit security-group rules for UDP. Allow UDP 10000 inbound from `0.0.0.0/0`.
- **Let's Encrypt rate limits** — 5 failed attempts per hour, 50 certs per domain per week. Test with `LETSENCRYPT_USE_STAGING=1` first; switch to production after you've confirmed the issuance works.
- **`PUBLIC_URL` must include the non-standard port** if you bind 8443 instead of 443. Otherwise browsers try to connect to 443 and fail. e.g. `PUBLIC_URL=https://meet.example.com:8443`.
- **Let's Encrypt HTTP-01 challenge needs port 80 reachable.** If you block port 80, LE can't issue. Use DNS-01 + separate certbot if you can't open port 80.
- **Scaling beyond ~50 participants per conference** requires multiple JVB instances + careful tuning. Single JVB can handle 50-100 participants depending on CPU. For large webinars (1000+), use 8x8's JaaS or architect a cluster (see <https://github.com/jitsi/jitsi-meet/tree/master/resources/jvb>).
- **Recording (Jibri) is expensive.** Each Jibri = one full Chromium rendering a 1080p video + encoding it to MP4. Budget ~2 CPU cores + 2 GB RAM per Jibri instance + good disk I/O.
- **E2EE is per-call opt-in** and currently works well only for ≤4 participants. Group E2EE at scale isn't production-ready (as of 2026). Default meetings are encrypted client→JVB, but JVB CAN see media.
- **Default = anyone can create any room.** An open instance is a spam / abuse vector. For any public-facing deploy: enable auth (`ENABLE_AUTH=1`), or at minimum lobby mode (participants wait for a moderator to admit them).
- **The apt install (Debian) is harder to customize** than the Docker stack. Uses Jitsi's own nginx vhost + their prosody config; layering custom config on top is fiddly. Docker is easier to pin config.
- **`docker-jitsi-meet` versions** lag slightly behind the main `jitsi-meet` release. Use the `stable` branch tags, not `master` / `main`.
- **Browser compatibility drifts.** WebRTC implementations in Chrome / Firefox / Safari change frequently. Older Jitsi versions may break on new browser releases. Keep up with stable releases.
- **Mobile apps (Android + iOS)** can point at your self-hosted domain via their settings — works, but the apps are designed primarily for `meet.jit.si`. Some features (screen share behavior, push notifications) may differ.
- **F-Droid Android app** is the Google-Play-independent version. Functionally identical but without any Google push notifications.
- **Etherpad integration** for collaborative notes requires a separate Etherpad container + `ETHERPAD_URL_BASE` env var. Not in default compose.
- **JVB ports `JVB_PORT` + `JVB_TCP_PORT`** need to be consistent across `.env`, firewall, and (in NAT setups) port forwarding. Off-by-one is a common "media works for some but not others" bug.
- **Prosody TURN settings** for NAT-traversal on the client side: Jitsi can embed a TURN server or use `turnserver.example.com`. Required for users behind symmetric NATs (some corporate networks). Default setup ships with a bundled coturn-like functionality.
- **Captions / transcription (`whisper` container)** — newer feature, optional. Requires additional compute (CPU or GPU for Whisper models).

## Links

- Upstream repo (web UI + SDK): <https://github.com/jitsi/jitsi-meet>
- docker-jitsi-meet: <https://github.com/jitsi/docker-jitsi-meet>
- Handbook (docs): <https://jitsi.github.io/handbook/>
- DevOps guide (Docker): <https://jitsi.github.io/handbook/docs/devops-guide/devops-guide-docker>
- DevOps guide (quickstart, apt): <https://jitsi.github.io/handbook/docs/devops-guide/devops-guide-quickstart>
- Jitsi Videobridge (JVB): <https://github.com/jitsi/jitsi-videobridge>
- Jicofo: <https://github.com/jitsi/jicofo>
- Jibri (recording/streaming): <https://github.com/jitsi/jibri>
- Jigasi (SIP gateway): <https://github.com/jitsi/jigasi>
- Kubernetes: <https://github.com/jitsi-contrib/jitsi-kubernetes>
- Releases: <https://jitsi.github.io/handbook/docs/releases>
- JaaS (managed): <https://jaas.8x8.vc>
- Public meet.jit.si: <https://meet.jit.si>
- Community forum: <https://community.jitsi.org>
- Security: <https://jitsi.org/security>
- E2EE whitepaper: <https://jitsi.org/e2ee-whitepaper/>
