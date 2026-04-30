---
name: SimpleX Chat
description: Privacy-first messenger with no user identifiers — no phone, no email, no account number. Uses unidirectional message queues on disposable relay servers. You can run your own SMP + XFTP servers for your community. Haskell. AGPL-3.0.
---

# SimpleX Chat

SimpleX Chat is the first (as of 2022) **identifier-free messenger**: no phone number, no email, no username, no random user ID. Your conversations are routed through one-time message queues on relay servers. Even the servers don't know who's talking to whom — all they see is encrypted bytes flowing through a queue they own.

This recipe is about **self-hosting the SimpleX server infrastructure** (the relay servers that pass messages) — useful if you want your own community's chat to not depend on SimpleX Chat team's preset servers (operated by Flux as of v6.2).

The SimpleX network has **two server types**:

1. **SMP server** — routes text/chat messages (from `simplex-chat/simplexmq`)
2. **XFTP server** — routes file transfers (from `simplex-chat/simplexmq`)

You can run one or both. Users' apps can then use your servers instead of (or alongside) the preset ones.

Features of the platform:

- **No user identifiers** — not even anonymous ones
- **Double-ratchet E2EE** (Signal's algorithm) + additional encryption layers per queue
- **Post-quantum crypto** for the message layer (v5.4+, opt-in)
- **Per-contact unique queue pairs** — no correlation across conversations
- **Decentralizable** — anyone can run servers; users pick which
- **Groups** — up to ~1000 members per group in v6+
- **Voice + video** — WebRTC, E2E encrypted
- **Private forwarding** — hide IP from contacts' servers (like a proxy)
- **Incognito profiles** — auto-generate a random profile per contact
- **Disappearing messages**, read receipts, typing indicators (all per-contact opt-in)
- **Hidden profiles + chat preferences** — multiple personas in one app

- Clients repo: <https://github.com/simplex-chat/simplex-chat>
- Server (SMP + XFTP): <https://github.com/simplex-chat/simplexmq>
- Website: <https://simplex.chat>
- Docs: <https://simplex.chat/docs/>
- Server install guide: <https://simplex.chat/docs/server.html>
- Whitepaper: <https://github.com/simplex-chat/simplexmq/blob/stable/protocol/simplex-chat.md>

## Architecture in one minute

- **Client apps** (iOS, Android, Windows, macOS, Linux desktop + CLI/TUI) hold ALL user state locally — contacts, messages, keys. No cloud backup by default.
- **SMP server** (Simple Messaging Protocol) holds **short-lived encrypted messages** in memory (persisting only queue records). Messages are deleted after delivery.
- **XFTP server** (File Transfer Protocol) holds **large files temporarily** in chunks, encrypted. Files are deleted after all recipients fetch them.
- **No global user directory** — no way to look someone up; you exchange contact via invite link (`simplex://...`) or QR code.

Your server is one peer in a decentralized network. Users can mix-and-match your servers with others.

## Compatible install methods

| Infra       | Runtime                                           | Notes                                                              |
| ----------- | ------------------------------------------------- | ------------------------------------------------------------------ |
| Single VM   | Docker (`simplexchat/smp-server`)                  | **Recommended**                                                     |
| Single VM   | Docker (`simplexchat/xftp-server`)                  | For file transfers                                                    |
| Single VM   | Native Haskell binary                                | For bare-metal enthusiasts                                             |
| Systemd     | Binary + unit file (upstream provides example)       | Production-grade                                                        |

## Inputs to collect

| Input                | Example                                | Phase     | Notes                                                         |
| -------------------- | -------------------------------------- | --------- | ------------------------------------------------------------- |
| Public hostname      | `smp.example.com`                       | DNS       | **PERMANENT** — in the server fingerprint that users add         |
| Port                 | `5223` (SMP default)                    | Network   | `443` for XFTP default; can override                              |
| TLS cert + key       | Let's Encrypt or self-signed             | Security  | Required                                                          |
| Server secret / keys | auto-generated on first run              | Security  | `/etc/opt/simplex/` data dir                                       |
| Storage quota        | for messages + files                     | Capacity  | SMP is in-memory; XFTP needs disk                                   |
| IP whitelist (opt.)  | restrict to known users                   | Policy    | Via config                                                          |

## Install SMP server via Docker

```sh
mkdir -p /etc/opt/simplex

docker run -d --name smp-server \
  --restart unless-stopped \
  -p 5223:5223 \
  -v /etc/opt/simplex:/etc/opt/simplex \
  -e ADDR=smp.example.com \
  simplexchat/smp-server:v6.x    # pin; check tags
```

First run generates server keys + TLS cert in `/etc/opt/simplex`. Logs print the **server fingerprint URI** (`smp://<FINGERPRINT>@smp.example.com:5223`) — copy this; it's what users add to their app.

## Install XFTP server via Docker

```sh
mkdir -p /etc/opt/simplex-xftp /srv/xftp

docker run -d --name xftp-server \
  --restart unless-stopped \
  -p 443:443 \
  -v /etc/opt/simplex-xftp:/etc/opt/simplex-xftp \
  -v /srv/xftp:/srv/xftp \
  -e ADDR=xftp.example.com \
  -e QUOTA=50gb \
  simplexchat/xftp-server:v6.x
```

## Docker Compose (both servers)

```yaml
services:
  smp-server:
    image: simplexchat/smp-server:v6.x
    container_name: smp-server
    restart: unless-stopped
    ports:
      - "5223:5223"
    volumes:
      - /etc/opt/simplex:/etc/opt/simplex
    environment:
      ADDR: smp.example.com

  xftp-server:
    image: simplexchat/xftp-server:v6.x
    container_name: xftp-server
    restart: unless-stopped
    ports:
      - "443:443"
    volumes:
      - /etc/opt/simplex-xftp:/etc/opt/simplex-xftp
      - /srv/xftp:/srv/xftp
    environment:
      ADDR: xftp.example.com
      QUOTA: 50gb
```

## After startup: get the fingerprint URI

```sh
docker logs smp-server 2>&1 | grep 'Server address'
# SMP server started at: smp://xxx@smp.example.com
```

Share this URI with your users — they add it in **App Settings → Network & servers → SMP servers → Add**.

## Install client apps

- **Android**: F-Droid / Google Play — <https://simplex.chat/android>
- **iOS**: App Store — <https://simplex.chat/ios>
- **macOS / Windows / Linux**: desktop app — <https://simplex.chat/docs/install.html>
- **CLI / terminal**:

```sh
curl -o- https://raw.githubusercontent.com/simplex-chat/simplex-chat/stable/install.sh | bash
simplex-chat
```

## Data & config layout

SMP server `/etc/opt/simplex/`:

- `server_identity.key` — **CRITICAL** — server's long-term private key; **losing this breaks all users**
- `server.crt` / `server.key` — TLS
- `stats.log` — queue stats

XFTP server `/etc/opt/simplex-xftp/`:

- `server.key` — **CRITICAL**
- `storage/` — the actual uploaded file chunks (quota-managed)

## Backup

```sh
# Server identity keys (CRITICAL)
tar czf simplex-smp-keys-$(date +%F).tgz -C /etc/opt/simplex .
tar czf simplex-xftp-keys-$(date +%F).tgz -C /etc/opt/simplex-xftp .
```

**If you lose `server_identity.key`**, the server's fingerprint changes after regen → all users need to re-add the server → old queues orphaned → messages mid-flight lost.

## Upgrade

1. Releases: <https://github.com/simplex-chat/simplexmq/releases>.
2. `docker compose pull && docker compose up -d`.
3. Protocol is versioned; SMP/XFTP servers + clients handle version skew.
4. **Never delete `server_identity.key`** during upgrade.

## Gotchas

- **SMP server is MESSAGES only** — in-memory, short-lived. **Not a message archive.** If a recipient is offline for > queue retention period (default ~3 weeks), the message is deleted.
- **Users hold ALL chat history** in their app. No server-side backup. If user loses phone, they lose messages unless they enabled the in-app backup feature.
- **XFTP server IS NOT a file archive** either — files deleted after all recipients fetch. For "permanent links," use something else (Nextcloud, Seafile).
- **Server fingerprint URI is the only thing tying server to users** — back up `server_identity.key` securely.
- **ADDR env must match DNS** — if DNS changes, you need to regenerate TLS + update `ADDR`.
- **Port 5223 isn't firewalled-friendly** — pick accessible ports for your community. Some networks block non-standard ports; use 443 for XFTP (standard HTTPS) if you can.
- **TLS is mandatory** — SimpleX is layered (crypto under TLS), but TLS is still the transport. Let's Encrypt supported; self-signed works if users accept the cert.
- **Scale**: one SMP server handles 10k-100k users comfortably on a modest VPS. Memory is the bottleneck (queues in RAM).
- **"Preset servers" operated by Flux** (since v6.2) — these are community-funded relays that new users get by default. Running yours adds to the network; users can mix.
- **SimpleX vs Matrix**: Matrix uses federation where servers know *which users are on which server* (usernames are `@user:server`). SimpleX has **no user identities at all** — strictly stronger metadata protection. Matrix still has your account when servers go down; SimpleX requires specific server availability for specific queues, but "which queue is whose" is unknowable.
- **SimpleX vs Signal**: Signal requires phone number; SimpleX requires nothing. Signal has a central server; SimpleX allows many. Signal has much larger user base.
- **SimpleX vs Session**: Session uses onion routing + anonymous IDs; SimpleX uses unidirectional queues + no IDs at all. Both are privacy-forward; different tradeoffs.
- **No phone/email bootstrap** means spam is hard (which is good) but also means spam-inbox-filtering on the server is impossible. Moderation happens in-group by participants.
- **AGPL-3.0** for both clients and servers — strongest copyleft; running a public service = source-share.
- **Privacy audits**: SimpleX has been formally audited (Trail of Bits, 2022); see <https://simplex.chat/blog/>.
- **Funding**: SimpleX Inc. + grants; preset infrastructure cost is community-funded.
- **Alternatives worth knowing:**
  - **Signal** — most-used secure messenger; phone-number based; single central server
  - **Matrix** (Element) — federated; per-server identities; group-chat strong
  - **Session** — onion routing + anonymous IDs; Lokinet-based
  - **Briar** — P2P, offline-first, anonymous; super-niche
  - **XMPP + OMEMO** — federated with E2E option
  - **Delta Chat** — E2E encrypted on top of email
  - **Threema** — commercial, anonymous, Swiss; paid
  - **Telegram** — commercial, mostly NOT E2E by default; avoid for privacy use cases
  - **Keybase** — defunct (acquired by Zoom)

## Links

- Clients repo: <https://github.com/simplex-chat/simplex-chat>
- Server repo: <https://github.com/simplex-chat/simplexmq>
- Website: <https://simplex.chat>
- Docs: <https://simplex.chat/docs/>
- Self-hosting your own server: <https://simplex.chat/docs/server.html>
- XFTP server details: <https://simplex.chat/docs/xftp-server.html>
- Privacy protocol whitepaper: <https://github.com/simplex-chat/simplexmq/blob/stable/protocol/simplex-chat.md>
- Blog: <https://simplex.chat/blog/>
- Android: <https://simplex.chat/android>
- iOS: <https://simplex.chat/ios>
- Terminal install: `curl -o- https://raw.githubusercontent.com/simplex-chat/simplex-chat/stable/install.sh | bash`
- Docker Hub: <https://hub.docker.com/r/simplexchat/smp-server>
- Security audits: <https://simplex.chat/blog/>
- Reddit: <https://www.reddit.com/r/SimpleXChat/>
