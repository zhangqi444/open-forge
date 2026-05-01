---
name: Databag
description: "Federated, end-to-end encrypted self-hosted messenger. Docker. Go. balzack/databag. Public-key identity, topic threads, audio/video calls, F-Droid + App Store + Play Store clients."
---

# Databag

**Federated, E2E-encrypted self-hosted messenger.** Minimal resource usage (runs on a Raspberry Pi Zero), decentralized public-key identity, federated (accounts on different nodes can message each other), topic-based threads (not contact-based chat), audio/video calls (via STUN/TURN), MFA, mobile push notifications (UnifiedPush, FCM, APN), unlimited participants per thread, and unlimited accounts per node.

Built + maintained by the **Databag team (balzack)**.

- Upstream repo: <https://github.com/balzack/databag>
- Docker Hub: <https://hub.docker.com/r/balzack/databag>
- F-Droid: <https://f-droid.org/en/packages/com.databag/>
- App Store: <https://apps.apple.com/us/app/databag/id6443741428>
- Google Play: <https://play.google.com/store/apps/details?id=com.databag>
- Demo (ephemeral): <https://databag.coredb.org>
- Design overview: [Design doc](https://github.com/balzack/databag/blob/main/doc/design_overview.md)

## Architecture in one minute

- **Go** server (single binary / single container)
- **SQLite** database — stored in a mounted volume (`/var/lib/databag`)
- Port **7000** — web app + API + WebSocket (all in one)
- Client apps: iOS, Android (F-Droid/Play Store), web browser
- Federation: nodes communicate directly (not via central relay)
- E2E encryption: **sealed topics** — admin cannot read encrypted content
- Audio/video: WebRTC via STUN/TURN (requires a relay server for NAT traversal)
- Resource: **tiny** — single Go binary; runs on Pi Zero v1.3

## Compatible install methods

| Infra          | Runtime                      | Notes                                                                        |
| -------------- | ---------------------------- | ---------------------------------------------------------------------------- |
| **Docker**     | `balzack/databag`            | **Primary** — one-liner or Compose                                           |
| **Docker Compose (SWAG/certbot)** | `docker-compose-swag.yml` | Auto-SSL variant                                        |
| **Nginx Proxy Manager** | manual NPM config      | See README for NPM + Portainer setup                                         |
| **1-click**    | CapRover, CasaOS, Unraid, Runtipi, Kubero, Umbrel | Various app store installs |
| **Bare metal** | Go binary + systemd          | Pi Zero / AWS guides in `/doc/`                                              |

## Inputs to collect

| Input                         | Example                           | Phase    | Notes                                                                                    |
| ----------------------------- | --------------------------------- | -------- | ---------------------------------------------------------------------------------------- |
| Domain + DNS                  | `chat.example.com`                | Network  | DNS A-record → server IP; **TLS required** for federation + secure WebSocket             |
| `ADMIN` password              | strong password                   | Auth     | Set via `ADMIN` env var; used for the node admin panel                                   |
| Volume path                   | `/var/lib/databag` in container   | Storage  | Map to a host path or named volume                                                       |
| STUN/TURN server (optional)   | coturn URL + user + pass          | Calls    | Required for audio/video calls through NAT; see README for coturn setup or Cloudflare    |

## Install via Docker (one-liner)

```bash
docker run -d \
  --name databag \
  -p 7000:7000 \
  -e ADMIN="your-admin-password" \
  -v databag_data:/var/lib/databag \
  --restart unless-stopped \
  balzack/databag:latest
```

Then put a reverse proxy (nginx / Caddy / NPM) in front with TLS, proxying to port 7000. **Requires WebSocket upgrade headers.**

## Install via Docker Compose (certbot/SWAG auto-SSL)

```bash
git clone https://github.com/balzack/databag.git
# Edit net/container/docker-compose-swag.yml — add your domain
mkdir -p ~/appdata
docker compose -f net/container/docker-compose-swag.yml -p databag up -d
```

## Nginx proxy config (manual)

```nginx
location / {
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "Upgrade";
    proxy_set_header Host $host;
    proxy_pass http://127.0.0.1:7000;
    client_max_body_size 0;
    proxy_max_temp_file_size 0;
}
```

## First boot

1. Deploy + put behind TLS.
2. Open `https://chat.example.com` in browser → click the cog icon (top right).
3. Enter your admin password.
4. In admin dashboard → Settings → set **Federated Host** to `chat.example.com` (your actual domain). **Required for federation.**
5. Generate an account link → share with users to create accounts.
6. Mobile: install client from F-Droid / App Store / Play Store → enter server address + credentials.
7. Test E2E (sealed) topics by sealing a thread — admin cannot view content.
8. If using audio/video: configure STUN/TURN in admin Settings → WebRTC.
9. Back up `/var/lib/databag/`.

## Audio/Video calls

Databag supports WebRTC audio/video. Requires a STUN/TURN server for NAT traversal. Options:

- **Self-hosted coturn** — [guide](https://gabrieltanner.org/blog/turn-server/)
- **Cloudflare TURN** — `turn.cloudflare.com` (free tier available)
- **Testing relay** (demo only, regularly wiped): `turn:34.210.172.114:3478`

In admin Settings:
- Enable WebRTC Calls → on
- WebRTC Server URL: `turn:<server>:<port>?transport=udp`
- WebRTC Username + Password: your coturn credentials

## Data & config layout

- `/var/lib/databag/` — SQLite DB (messages, contacts, accounts, media attachments)
- Config: admin password via `ADMIN` env var; all other settings in the admin panel

## Backup

```sh
docker stop databag
sudo tar czf databag-$(date +%F).tgz <databag_data_volume>/
docker start databag
```

Contents: **all messages, contacts, sealed/unsealed topics, user accounts, media**. E2E-encrypted topics (sealed) are stored encrypted — admin cannot read them even from backup. Still treat as sensitive (unencrypted topics visible in backup).

## Upgrade

1. Releases: <https://github.com/balzack/databag/releases>
2. `docker pull balzack/databag:latest && docker compose up -d` (or `docker restart databag`)

## Gotchas

- **TLS is required for federation and WebSocket.** Federation between nodes uses HTTPS; clients connect via `wss://`. Self-signed certs won't work for federation. Use Let's Encrypt via Caddy/Certbot/NPM.
- **Set Federated Host in admin settings.** This is the domain other nodes use to federate with yours. Without it set correctly, federation fails silently.
- **WebSocket upgrade headers are mandatory** at the proxy. Standard reverse proxy configs that strip `Upgrade` + `Connection` headers break Databag's real-time push. Copy the nginx config from the README verbatim.
- **`ADMIN` env var is the node admin password** — not a user account. Users create their own accounts via the invite link generated in the admin panel.
- **Sealed (E2E) topics.** When you seal a topic/thread, messages are encrypted client-side. The server stores only ciphertext. Even a database backup doesn't expose content. Unsealed topics are plaintext server-side — behave accordingly.
- **Federation = accounts on different nodes communicate.** Your users can add contacts on other Databag nodes (e.g., `alice@chat.example.com` adds `bob@friend.example.com`). Public-key identity means accounts aren't tied to a domain — they can be moved.
- **Audio/video without a TURN server = fails behind symmetric NAT.** Most home/corporate networks have symmetric NAT. Without coturn or Cloudflare TURN configured, audio/video will silently fail to connect for many users.
- **UnifiedPush for Android push** — if your users run de-Googled Android (no FCM), UnifiedPush (via ntfy, Gotify, etc.) is supported. Configure via app settings.
- **Single file DB.** SQLite makes backup trivial (copy one file). For heavy usage, monitor DB size; SQLite handles millions of rows fine but very large media attachments can grow it fast.
- **Pi Zero v1.3 compatible.** If you want the most minimal possible deploy, the upstream docs include a bare-metal Pi Zero guide.

## Project health

Active Go development, F-Droid + App Store + Play Store clients, Docker Hub, arm64 + amd64 images, federation, STUN/TURN, UnifiedPush support. Maintained by balzack. MIT license.

## Federated-messenger-family comparison

- **Databag** — Go, E2E optional, public-key identity, federated, topic threads, audio/video, minimal footprint
- **Matrix / Element** — Federated via Matrix protocol; gold standard; heavy
- **XMPP / Prosody** — Classic federated chat; XMPP protocol; many clients
- **Mattermost** — Team messaging, Slack alt; not E2E; not federated
- **Rocket.Chat** — Slack alt + omnichannel; not federated
- **Signal** — E2E, centralized, no federation, best UX; not self-hosted

**Choose Databag if:** you want a minimal, self-hostable, federated, E2E-capable messenger that runs on a Pi Zero and gives you topic-based threads with audio/video calls.

## Links

- Repo: <https://github.com/balzack/databag>
- Docker Hub: <https://hub.docker.com/r/balzack/databag>
- F-Droid: <https://f-droid.org/en/packages/com.databag/>
- Pi Zero guide: <https://github.com/balzack/databag/blob/main/doc/pizero.md>
- coturn setup: <https://gabrieltanner.org/blog/turn-server/>
- Matrix/Element (heavier alt): <https://element.io>
