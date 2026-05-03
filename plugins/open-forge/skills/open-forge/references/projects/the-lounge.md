---
name: The Lounge
description: "Modern self-hosted web IRC client with always-on connection, push notifications, link previews, synchronized multi-device experience. Node.js server + Vue.js frontend. Keeps you connected to IRC servers while offline. MIT."
---

# The Lounge

The Lounge is **a modern, self-hosted web IRC client** — stays connected to IRC servers on your behalf, syncs state across devices, brings 21st-century features (push notifications, link previews, unread-markers, responsive UI) to Internet Relay Chat.

Official community fork of **Shout** (by Mattias Erming). The canonical "web-based IRC bouncer with a client UI" — think of it as **ZNC + a web client in one package**.

Features:

- **Always-connected** — runs as a server; maintains IRC connections; you reconnect and catch up
- **Synchronized** across desktop / mobile / tablet — same state everywhere
- **Push notifications** (browser + mobile PWA)
- **Link previews** — inline URL/image preview
- **New-message markers** — pick up where you left off
- **Channel list / auto-join** — remembers your networks + channels
- **Private / shared mode** — single user or multi-user
- **Command-line IRC** — `/join`, `/msg`, `/whois`, etc. as you'd expect
- **Chat search / history** (optional logging)
- **Themes** — dark + light + community themes
- **Mobile-friendly** PWA
- **Keyboard shortcuts**
- **Custom CSS**
- **TLS** — secure IRC (IRCS / STARTTLS)
- **SASL** authentication (PLAIN, EXTERNAL, SCRAM)

- Upstream repo: <https://github.com/thelounge/thelounge>
- Website: <https://thelounge.chat>
- Docs: <https://thelounge.chat/docs>
- Demo: <https://demo.thelounge.chat>
- Docker: <https://github.com/thelounge/thelounge-docker>

## Architecture in one minute

- **Node.js server** (`thelounge`) — maintains IRC connections + serves web UI
- **Vue.js frontend**
- **Config**: YAML (`config.yml`) + per-user JSON
- **Storage**: local filesystem (users, logs, uploads)
- **No DB** — files for everything
- **Low resource** — ~100 MB RAM idle; scales with users + channels

## Compatible install methods

| Infra              | Runtime                                                      | Notes                                                                       |
| ------------------ | ------------------------------------------------------------ | --------------------------------------------------------------------------- |
| Single VM          | **npm / yarn global** (`yarn global add thelounge`)                | **Upstream-recommended for native**                                             |
| Single VM          | **Docker (`ghcr.io/thelounge/thelounge`)**                                     | Very popular                                                                              |
| Single VM          | Distro package (Debian/Ubuntu — sometimes lagging)                                     | OK                                                                                                  |
| Raspberry Pi       | arm64 Node.js or Docker                                                                       | Works                                                                                                           |
| Kubernetes         | Community manifests                                                                                         | Possible                                                                                                                    |
| Managed            | — (no SaaS; demo.thelounge.chat is demo-only)                                                                            |                                                                                                                                             |

## Inputs to collect

| Input            | Example                                 | Phase    | Notes                                                                      |
| ---------------- | --------------------------------------- | -------- | -------------------------------------------------------------------------- |
| Domain           | `irc.example.com`                           | URL      | For web UI                                                                       |
| Port             | `9000`                                              | Network  | Default; reverse-proxy to 443                                                                   |
| Mode             | `private` (per-user accounts) or `public` / `ldap`    | Config   | Private is the common self-host choice                                                                   |
| Admin user       | `thelounge add alice`                                  | Bootstrap | CLI-created                                                                                                |
| Reverse proxy    | nginx / Caddy / Traefik                                        | TLS      | Required for TLS + push notifications                                                                                         |
| Push keys        | generated by thelounge                                                 | Feature  | For web push notifications                                                                                                     |

## Install via Docker

```yaml
services:
  thelounge:
    image: ghcr.io/thelounge/thelounge:4.4.3         # pin
    container_name: thelounge
    restart: unless-stopped
    ports:
      - "9000:9000"
    volumes:
      - ./config:/var/opt/thelounge
    environment:
      TZ: America/Los_Angeles
```

Create a user:

```sh
docker exec -it thelounge thelounge add alice
# Prompts for password; creates ~/.thelounge/users/alice.json
```

Browse `http://<host>:9000/`.

## Install via npm

```sh
npm install -g thelounge        # or yarn global add thelounge
thelounge start                  # creates ~/.thelounge by default
thelounge add alice              # add user

# For prod, systemd unit + run as dedicated user
```

## First boot

1. Log in as `alice`
2. **Add network**: network name, server address (e.g., `irc.libera.chat:6697`), SSL on, nick, channels to auto-join
3. Connect → your channels populate
4. Message → appears in real-time
5. Enable browser push notifications for mentions
6. Install as PWA on mobile for persistent-connection-feel

## Data & config layout

- `/var/opt/thelounge/config.yml` — global config (mode, port, reverse proxy, push)
- `/var/opt/thelounge/users/` — per-user JSONs (networks, channels, settings)
- `/var/opt/thelounge/logs/` — chat logs (if enabled)
- `/var/opt/thelounge/storage/` — uploaded files (if file upload enabled)

## Backup

```sh
tar czf thelounge-$(date +%F).tgz /var/opt/thelounge/
```

User passwords are hashed — safe to backup.

## Upgrade

1. Releases: <https://github.com/thelounge/thelounge/releases>. Moderate cadence.
2. Docker: bump tag → restart.
3. npm: `npm update -g thelounge` → restart service.
4. Watch for major version breaks (e.g., v3 → v4 UI rewrite).

## Gotchas

- **`private` vs `public` mode**: private requires users; public allows anonymous connection. For a homelab self-host, always `private`. For a community IRC bouncer, `public` is the idea.
- **Reverse proxy is effectively mandatory** — IRC over HTTP without TLS is sketchy; push notifications *require* HTTPS. Configure nginx/Caddy/Traefik with WebSocket support.
- **WebSocket config**: reverse proxies need `Upgrade` + `Connection: upgrade` headers + long read timeouts for IRC idle connections.
- **Idle connections** — keep reverse proxy timeouts high (`proxy_read_timeout 24h;` in nginx) or they'll drop silently.
- **IRC TLS**: always connect to the IRC server with TLS (`+6697` or `:6697` with `tls: true`). Plain 6667 leaks passwords/content.
- **SASL authentication**: configure per-network in user settings; preferred over NickServ IDENTIFY for reliability.
- **Push notifications**: modern browsers require service workers + HTTPS + PWA manifest. The Lounge does it but requires a properly-served HTTPS site + VAPID keys (auto-generated).
- **Logs**: off by default for privacy. Enable per-user in user config.
- **File uploads**: disabled by default; enable in config.yml. Uploads go to `storage/`.
- **Nickname collisions** — each user defines their own nick; no conflict within The Lounge, but IRC network may already have it → rename handler.
- **Multi-network**: each user can join many networks (Libera, OFTC, EFnet, private IRCds, etc.).
- **ZNC migration**: The Lounge replaces ZNC + web client; import isn't automatic but networks + channels list is manual entry (~30s per network).
- **IRCv3 capabilities**: supported (SASL, server-time, message-tags, etc.). Modern IRC networks (Libera, OFTC) use these.
- **Resource tuning**: each user = one Node.js socket + IRC connections per network. 100+ users fine on small VPS; thousands needs horizontal scaling (not The Lounge's target).
- **Mobile app**: no native apps officially; PWA is the answer. iOS/Android PWAs work but iOS has notification limitations vs native.
- **Keybase / Matrix migration**: if your IRC network has dwindled, consider Matrix bridges or moving entirely.
- **License**: MIT.
- **Alternatives worth knowing:**
  - **ZNC** — classic IRC bouncer; no web UI (uses external client) (separate recipe likely)
  - **Shout** — the original; discontinued; The Lounge is its successor
  - **Soju** — modern IRC bouncer from emersion; IRCv3-native (separate recipe likely)
  - **Quassel** — Qt-based IRC with server+client model
  - **WeeChat + relay** — terminal IRC + web relay
  - **Matrix (Element Web)** — federated chat; IRC bridges available
  - **IRCCloud** — SaaS commercial IRC client
  - **Choose The Lounge if:** you want a polished, self-hosted web IRC client with multi-device sync.
  - **Choose ZNC + separate IRC client if:** you want classic bouncer + your own client.
  - **Choose Soju if:** you want a modern bouncer with IRCv3 + stay with your preferred client.
  - **Choose Matrix if:** you're moving beyond IRC.

## Links

- Repo: <https://github.com/thelounge/thelounge>
- Website: <https://thelounge.chat>
- Docs: <https://thelounge.chat/docs>
- Install + upgrade: <https://thelounge.chat/docs/install-and-upgrade>
- Demo: <https://demo.thelounge.chat>
- Docker repo: <https://github.com/thelounge/thelounge-docker>
- Docker image (GHCR): <https://github.com/thelounge/thelounge/pkgs/container/thelounge>
- Releases: <https://github.com/thelounge/thelounge/releases>
- IRC channel: `#thelounge` on Libera.Chat
- ZNC (alt): <https://znc.in>
- Soju (alt): <https://soju.im>
- Libera.Chat (popular network): <https://libera.chat>
- Shout (predecessor): <https://github.com/erming/shout>
