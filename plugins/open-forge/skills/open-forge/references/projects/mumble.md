---
name: Mumble
description: "Low-latency, high-quality open source voice-chat for groups — gaming, meetups, podcasts. Positional audio, Opus codec, strong encryption, cert-based identity. Client (Qt) + server (mumble-server, formerly 'murmur'). Cross-platform. BSD-3."
---

# Mumble

Mumble is a **low-latency, high-quality voice chat server** — the old-school, rock-solid choice for gaming clans, TTRPG groups, podcast recording, and group voice that predates Discord and still outperforms it on latency/quality. Opus codec, strong TLS encryption, positional audio (3D sound tied to in-game position), certificate-based identity.

Two components:

- **Mumble client** (desktop app) — Windows, Linux, FreeBSD, OpenBSD, macOS
- **Mumble server** (`mumble-server`, historically called `murmur`) — daemon users connect to

Key strengths:

- **Opus codec** — exceptional voice quality at 10-100 kbps
- **Low latency** — typically <50ms round trip over LAN; <150ms over internet
- **Positional audio** — plugins link voices to in-game coordinates (CS, Dota, MSFS, etc.)
- **Cert-based identity** — no passwords per user; your certificate IS your identity
- **Channel hierarchy** — rooms within rooms; ACLs per channel
- **Push-to-talk or voice activity**
- **Server moderation** — kick, ban, mute, move, ACLs
- **Bots** — scripting via ICE or ZeroC; **mumo**, **botamusique**
- **Encrypted by default** — TLS for control, AES for voice
- **Resource light** — a 50-user server runs on a Pi
- **BSD-3-Clause license**

- Upstream repo: <https://github.com/mumble-voip/mumble>
- Website: <https://www.mumble.info>
- Docs: <https://www.mumble.info/documentation/>
- Docker image (official): <https://hub.docker.com/r/mumblevoip/mumble-server>
- Matrix: `#mumble:matrix.org`

## Architecture in one minute

- **Server**: single binary (C++/Qt). Config in `mumble-server.ini`. Storage in SQLite (default) or MySQL/Postgres.
- **Client**: Qt desktop app
- **Protocol**: TCP (control + text + registration) + UDP (voice). Falls back to TCP for voice if UDP blocked.
- **Ports**: 64738/tcp + 64738/udp (default, both on same port number)
- **Server runs on**: ~5-30 MB RAM baseline; scales to thousands of concurrent users on modest hardware
- **Voice data does NOT pass through on server disk** — server just relays packets; no recordings by default

## Compatible install methods

| Infra          | Runtime                                          | Notes                                                           |
| -------------- | ------------------------------------------------ | --------------------------------------------------------------- |
| Single VM/Pi   | **Native `mumble-server` package**                  | **Tiny, stable, recommended**                                       |
| Single VM      | Docker (`mumblevoip/mumble-server`)                     | Works well                                                              |
| Any OS         | Pre-built binaries on mumble.info                         | Windows/Linux/macOS for clients                                               |
| Kubernetes     | Community manifests                                             | Small deployment                                                                    |

## Inputs to collect

| Input            | Example                         | Phase     | Notes                                                         |
| ---------------- | ------------------------------- | --------- | ------------------------------------------------------------- |
| Server port      | `64738` (TCP+UDP)                | Network   | Both protocols on same port                                        |
| Domain (opt)     | `voice.example.com`               | URL       | For SRV records + cert SAN                                              |
| TLS cert         | Let's Encrypt or self-signed           | Security  | For channel-cert trust; clients will warn on self-signed                    |
| Server password  | string (or none)                          | Auth      | Set `serverpassword=` in mumble-server.ini                                      |
| SuperUser pass   | set via CLI flag                             | Bootstrap | `mumble-server -supw <pass>`; used for channel admin ops                              |
| Max users        | 100                                             | Capacity  | `users=` in ini                                                                             |
| Bandwidth        | 72000 bps                                          | Quality   | Per-user upstream; 40-72 kbps is typical Opus                                                     |
| Greeting text    | HTML welcome                                          | UX        | `welcometext=` in ini                                                                                   |
| Channel certs    | self-signed by server                                    | Crypto    | Generated automatically on first boot                                                                                    |
| DNS SRV record   | `_mumble._tcp.example.com. IN SRV 0 0 64738 voice.example.com.` | DNS   | Optional; lets clients find server via domain                                                                                    |

## Install natively (Debian/Ubuntu)

```sh
sudo apt install mumble-server
sudo dpkg-reconfigure mumble-server     # prompts for autostart, high-priority, superuser password
sudo systemctl enable --now mumble-server
sudo ss -ltnp | grep 64738              # verify listening
```

## Install via Docker

```sh
docker run -d --name mumble \
  --restart unless-stopped \
  -p 64738:64738 -p 64738:64738/udp \
  -v /srv/mumble:/data \
  -e MUMBLE_CONFIG_SERVER_PASSWORD=<optional> \
  -e MUMBLE_SUPERUSER_PASSWORD=<strong> \
  mumblevoip/mumble-server:v1.5.857   # pin tag
```

## Install via Docker Compose

```yaml
services:
  mumble-server:
    image: mumblevoip/mumble-server:v1.5.857   # pin specific version
    container_name: mumble-server
    restart: unless-stopped
    ports:
      - "64738:64738"
      - "64738:64738/udp"
    volumes:
      - ./data:/data
    environment:
      MUMBLE_CONFIG_SERVER_PASSWORD: <optional>
      MUMBLE_SUPERUSER_PASSWORD: <strong>
      MUMBLE_CONFIG_WELCOMETEXT: "<br />Welcome to our Mumble server.<br />"
      MUMBLE_CONFIG_USERS: "100"
      MUMBLE_CONFIG_BANDWIDTH: "72000"
```

## Config highlights (`mumble-server.ini`)

```ini
database=/data/mumble-server.sqlite
port=64738
welcometext="<br />Welcome to our Mumble server.<br />"
serverpassword=        # blank = open; set a string to require
bandwidth=72000        # max bits/sec per user
users=100              # max concurrent
opusthreshold=100      # % of users that must support Opus before using it; 100 = always Opus

# TLS (use Let's Encrypt if externally reachable)
sslCert=/etc/letsencrypt/live/voice.example.com/fullchain.pem
sslKey=/etc/letsencrypt/live/voice.example.com/privkey.pem

# Registration — require email + password per user, or leave unauthenticated
registerName=MyServer
registerHostname=voice.example.com
registerUrl=https://example.com
registerPassword=
```

## First boot

1. Start server.
2. **Set SuperUser password**: `mumble-server -ini /etc/mumble-server.ini -supw <password>` (or via env in Docker).
3. Install Mumble client on desktop.
4. Client → Server menu → Add New → hostname, port 64738, username → Connect.
5. Right-click root channel → Edit → set ACLs / sub-channels.
6. Log in as **SuperUser** (username `SuperUser`, password you just set) to gain full admin.

## Channel + ACL model

- Root channel (everyone) → sub-channels (rooms) → sub-sub-channels (breakouts)
- Per-channel ACLs (read-only, speak, join, admin)
- **Groups** — `@admin`, `@auth` (= registered user), custom groups
- **Registration**: users can "register" their cert with the server → becomes a known identity → grant permissions per-identity
- **No central password system by default** — identity = your client certificate. This is a strength (no passwords to steal) and a surprise for newcomers.

## Bots + integrations

- **mumo** — moderator bot
- **botamusique** — music bot (stream YouTube/SoundCloud/URL to the channel)
- **Ice/ZeroC RPC** — server RPC for external apps
- **Web admin panels**: MumbleDJ, Mumble-Web (browser client)

## Data & config layout

- `/etc/mumble-server.ini` (native) or `/data/mumble-server.ini` (Docker) — all config
- `mumble-server.sqlite` — channels, bans, registered users
- TLS certs in wherever you pointed `sslCert` / `sslKey`

## Backup

```sh
cp /var/lib/mumble-server/mumble-server.sqlite mumble-$(date +%F).sqlite
cp /etc/mumble-server.ini mumble-ini-$(date +%F).bak
```

Clients can also export their own **certificate** (File → Certificate Wizard → Export). **Do this once** — losing the cert = losing your identity on all servers where you're registered.

## Upgrade

1. Releases: <https://github.com/mumble-voip/mumble/releases>. Slow + steady (1.5.x is current stable as of 2025).
2. Native: `apt upgrade mumble-server`.
3. Docker: bump tag, pull, up -d.
4. SQLite DB upgrades automatically; back up first.
5. Client-server version mismatch: 1.5 server supports 1.3, 1.4, 1.5 clients; very old clients (1.2 or earlier) may need server-side concessions.

## Gotchas

- **Certificate = identity**: the first time a client connects, it generates a cert. **Back up the cert.** Losing it = new identity = admins must re-register you.
- **Self-signed server cert**: clients warn on first connect. Install Let's Encrypt cert and point `sslCert` / `sslKey` at it — no more warnings.
- **UDP is preferred; TCP fallback is lower quality**. If voice is crackly, check if firewall/NAT is blocking UDP 64738 → force-TCP is usable but laggy.
- **NAT and port forwarding**: server needs TCP+UDP 64738 (or chosen port) open + forwarded. Clients don't need inbound.
- **IPv6**: Mumble supports v6; dual-stack config may need `host=::` vs default IPv4-only.
- **Positional audio** — requires a plugin in the client tied to a specific game; server doesn't do anything game-specific. Plugin support is limited on macOS + ARM.
- **Low-latency mode** (high-priority scheduling) — on Linux `nice=-19` or SCHED_FIFO; see `mumble-server.ini`. Helps on loaded hosts.
- **Recording voice**: the server **does not record by default**; clients can record locally if enabled. For server-side recording use a bot (mumble-recordbot) — **respect local laws about two-party consent**.
- **Privacy: no chat history**: text chat is ephemeral by default. Registered messages can be logged but usually aren't.
- **Bans**: persistent in DB; bans by cert hash more robust than bans by IP.
- **Max bandwidth**: per-user upload cap. Default ~72 kbps is generous for Opus; dropping to 32-40 kbps is fine for most voice.
- **Multi-server one host**: run multiple `mumble-server` instances on different ports or use virtual servers (Murmur supports multiple `-ini` instances).
- **Mumble-Web** — WebRTC browser client (no native app install). Good for casual/guest users.
- **SRV records**: `_mumble._tcp.example.com` → helps clients connect via `voice.example.com` without specifying port. Nice touch.
- **Version compatibility**: 1.5 is current; 1.4 still common. Codec Opus since 1.2.4. Ancient CELT-only clients (<1.2.4) are dead.
- **vs Discord**: Discord is free, easier, has video + chat + moderation tooling but you give them all your voice. Mumble has lower latency + local control + privacy. For gaming Mumble still wins on voice quality. For "general friend server," Discord dominates. Both can coexist.
- **vs TeamSpeak**: closed-source commercial alternative; similar feature set; non-commercial free tier. Mumble is OSS.
- **vs Jitsi Meet**: video-first; WebRTC in browser; different tool (separate recipe).
- **vs Element / Matrix Voice**: federated; newer; in-development for voice rooms.
- **vs Rocket.Chat voice** — basic; built into team chat.
- **Choose Mumble if:** you want low-latency, high-quality, self-hosted group voice for gaming/podcasts.
- **Choose Jitsi if:** you want video-first browser-based meetings.
- **Choose Element (Matrix) if:** you want a federated chat-and-voice platform.

## Links

- Repo: <https://github.com/mumble-voip/mumble>
- Website: <https://www.mumble.info>
- Docs: <https://www.mumble.info/documentation/>
- Server config reference: <https://github.com/mumble-voip/mumble/blob/master/auxiliary_files/mumble-server.ini>
- Docker Hub: <https://hub.docker.com/r/mumblevoip/mumble-server>
- Releases: <https://github.com/mumble-voip/mumble/releases>
- Matrix room: <https://matrix.to/#/#mumble:matrix.org>
- Plugins: <https://www.mumble.info/documentation/user/plugins/>
- Clients (official downloads): <https://www.mumble.info/downloads/>
- mumble-web (browser client): <https://github.com/Johni0702/mumble-web>
- botamusique (music bot): <https://github.com/azlux/botamusique>
- mumo (moderation bot): <https://github.com/mumble-voip/mumo>
