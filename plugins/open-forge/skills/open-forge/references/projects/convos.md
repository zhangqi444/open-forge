---
name: Convos
description: "Self-hosted always-on IRC web client. Docker or one-line install. Perl/Mojolicious + Svelte. convos-chat/convos. Persistent connections, multi-user, file sharing, video/audio, search, notifications, mobile-friendly."
---

# Convos

**Always-on IRC client in your browser.** Convos keeps a persistent connection to IRC networks so you never miss messages — even when your browser is closed. Multi-user, persistent chat history, file sharing, video/audio support, full-text search, desktop notifications, mobile-friendly. Runs as a single self-contained binary or Docker container.

Built + maintained by **convos-chat team**. Artistic License 2.0.

- Upstream repo: <https://github.com/convos-chat/convos>
- Website + docs: <https://convos.chat>
- Getting started: <https://convos.chat/doc/start>
- GHCR: `ghcr.io/convos-chat/convos:alpha`
- Docker Hub: `convos/convos`
- Snap Store: `snap install convos`

## Architecture in one minute

- **Perl / Mojolicious** backend (async web framework)
- **Svelte** frontend
- Runs as a **single process** — web server + IRC connection manager in one
- Port **3000** (web UI)
- Data directory: `$HOME/convos/data` (or configured path)
- No external database — Convos uses its own flat-file storage
- Resource: **low** — Perl async; very lightweight; runs on a Raspberry Pi

## Compatible install methods

| Infra       | Runtime                            | Notes                                           |
| ----------- | ---------------------------------- | ----------------------------------------------- |
| **Docker**  | `ghcr.io/convos-chat/convos:alpha` | **Primary** — GHCR; also on Docker Hub          |
| **One-liner** | `curl https://convos.chat/install.sh \| sh -` | Downloads and runs locally         |
| **Snap**    | `snap install convos`              | Ubuntu/Snap systems                             |
| **Manual**  | Perl + Carton dependencies         | Source install for advanced setups              |

## Install via Docker

```bash
mkdir -p $HOME/convos/data
docker run -it -p 8080:3000 \
  -v $HOME/convos/data:/data \
  ghcr.io/convos-chat/convos:alpha
```

Or Docker Compose:

```yaml
services:
  convos:
    image: ghcr.io/convos-chat/convos:alpha
    container_name: convos
    ports:
      - "8080:3000"
    volumes:
      - ./data:/data
    restart: unless-stopped
```

Visit `http://localhost:8080`.

## One-line install (bare metal)

```bash
curl https://convos.chat/install.sh | sh -
./convos/script/convos daemon
```

Starts immediately at `http://localhost:3000`.

## First boot

1. Deploy via Docker or one-line install.
2. Visit `http://localhost:3000`.
3. Register the first user (admin).
4. Add a **connection** (IRC network): Settings → Connections → Add:
   - Server hostname (e.g. `irc.libera.chat`)
   - Port (6667 plain / 6697 TLS)
   - Your IRC nick, username, real name
   - (Optional) SASL/NickServ password
5. Join **channels** via the `+` button next to your connection.
6. Convos stays connected even when your browser is closed.
7. Put behind TLS (nginx/Caddy reverse proxy).

## Features overview

| Feature | Details |
|---------|---------|
| Persistent connections | IRC stays connected 24/7; logs all messages |
| Chat history | Searchable log of all conversations |
| Multi-user | Each user has their own IRC connections |
| File sharing | Upload and share files in chat |
| Video/audio | WebRTC-based video and audio calls |
| Notifications | Desktop + mobile push notifications |
| Mobile UI | Responsive; works well on phones |
| Multi-network | Connect to multiple IRC networks simultaneously |
| SASL | IRC authentication (SASL PLAIN, EXTERNAL) |
| Search | Full-text search across all chat history |

## Gotchas

- **IRC protocol only.** Convos currently supports IRC. The README mentions it can be extended for other protocols, but IRC is the only implemented one. Use Matrix (Element) if you need a modern federated protocol.
- **`alpha` Docker tag.** The official Docker image is tagged `:alpha` — this refers to the channel name, not stability status. Convos is production-ready; the `:alpha` tag tracks the main development branch. There's also a `:stable` branch for the more conservative release.
- **Old Docker Hub images.** The README notes `Nordaaker/convos` and `convos/convos` on Docker Hub are still around but the new official image is `ghcr.io/convos-chat/convos`. Use GHCR.
- **Single data directory.** All user data, connections, and logs are in the data volume. Back it up — losing it means losing all chat history and user accounts.
- **TLS via reverse proxy.** Convos doesn't handle TLS itself — put it behind nginx or Caddy for HTTPS. Required for secure access from outside localhost.
- **IRC is not Matrix/Discord.** Convos makes IRC pleasant but it's still IRC — no end-to-end encryption, no rich media embeds, no reactions. For encrypted modern chat, use Matrix.
- **Resources on Raspberry Pi.** Convos is famously lightweight — the Perl async server handles many connections with very low RAM. It runs comfortably on a Raspberry Pi 3+.
- **Multi-user but not multi-tenant.** All users on a Convos instance share the same install but have separate connections and private logs. Not designed for large public deployments.

## Backup

```sh
docker compose stop convos
sudo tar czf convos-$(date +%F).tgz data/
docker compose start convos
```

## Upgrade

```sh
docker compose pull && docker compose up -d
```

## Project health

Active Perl/Svelte development, GHCR, Snap, one-line install, WebRTC video/audio, full-text search. Solo-maintained by jhthorsen/convos-chat team. Artistic License 2.0.

## IRC-client-family comparison

- **Convos** — Perl+Svelte, always-on IRC, web UI, multi-user, file sharing, video/audio, tiny footprint
- **The Lounge** — Node.js, always-on IRC web client; popular alternative; similar scope
- **ZNC** — C++, IRC bouncer (proxy); no web interface; pairs with a local IRC client
- **WeeChat** — C, terminal IRC client with relay; powerful but terminal-centric
- **Matrix/Element** — modern federated protocol; bridges to IRC; heavier; E2E encryption

**Choose Convos if:** you want a lightweight, always-on IRC client in your browser with persistent history, file sharing, and video/audio — on minimal server resources.

## Links

- Repo: <https://github.com/convos-chat/convos>
- Docs: <https://convos.chat>
- Getting started: <https://convos.chat/doc/start>
- GHCR: `ghcr.io/convos-chat/convos:alpha`
