---
name: ClipCascade
description: "Self-hosted clipboard sync across multiple devices with end-to-end encryption. Docker or JAR. Java/Spring. Sathvik-Rao/ClipCascade. Multi-user + cross-platform clients."
---

# ClipCascade

**Self-hosted clipboard sync across devices with end-to-end encryption.** Automatically syncs clipboard content between workstations, phones, and any device running the client. Multi-user (isolates per-user clipboard), E2E-encrypted, web dashboard for activity + settings, native clients for Windows/macOS/Linux/Android.

Built + maintained by **Sathvik Rao**. Public community server at clipcascade.sathvik.dev (free account, sync instantly).

- Upstream repo: <https://github.com/Sathvik-Rao/ClipCascade>
- Docker Hub: <https://hub.docker.com/r/sathvikrao/clipcascade>
- Community server (free): <http://clipcascade.sathvik.dev>
- Releases (clients + JAR): <https://github.com/Sathvik-Rao/ClipCascade/releases>

## Architecture in one minute

- **Java 21+ / Spring Boot** server
- Port **8080** — web dashboard + WebSocket sync endpoint
- **SQLite-backed user DB** under `/database` (mounted volume)
- **End-to-end encryption** — server never sees plaintext clipboard
- Native clients for **Windows / macOS / Linux / Android**
- Resource: **low** (tiny JVM; single-digit MB clipboard items)

## Compatible install methods

| Infra              | Runtime                                    | Notes                                                                 |
| ------------------ | ------------------------------------------ | --------------------------------------------------------------------- |
| **Docker**         | `sathvikrao/clipcascade`                   | **Primary** — one-liner install                                       |
| **Bare-metal JVM** | `ClipCascade-Server-JRE_21.jar`            | For Windows / macOS / Linux hosts with Java 21+                       |
| **Community SaaS** | clipcascade.sathvik.dev                    | No setup; free; trust-model is "trust the maintainer"                 |

## Inputs to collect

| Input                        | Example                            | Phase      | Notes                                                       |
| ---------------------------- | ---------------------------------- | ---------- | ----------------------------------------------------------- |
| Domain                       | `clip.example.com`                 | URL        | Reverse-proxy + TLS in front — **WebSocket support needed** |
| Max message size (MiB)       | `1` (default) / `10`               | Config     | `CC_MAX_MESSAGE_SIZE_IN_MiB` env                            |
| Admin / first user           | username + password                | Auth       | Register via web UI on first visit                          |
| Storage dir                  | `./cc_users`                       | Storage    | Mount at `/database` inside container                       |

## Install via Docker (one-liner)

```sh
docker run -d --name clipcascade \
  -p 8080:8080 \
  -e CC_MAX_MESSAGE_SIZE_IN_MiB=1 \
  -v ./cc_users:/database \
  --restart unless-stopped \
  sathvikrao/clipcascade
```

## Install via Docker Compose

```yaml
services:
  clipcascade:
    image: sathvikrao/clipcascade:latest
    ports:
      - "8080:8080"
    restart: unless-stopped
    environment:
      - CC_MAX_MESSAGE_SIZE_IN_MiB=1
    volumes:
      - ./cc_users:/database
```

Additional config snippets (TLS variants, proxy-behind modes) are in the upstream repo at `ClipCascade_Server/docker-compose/`.

## Install bare-metal (JAR)

1. Install Java 21+ (`sudo apt install openjdk-21-jre` or equivalent).
2. Download `ClipCascade-Server-JRE_21.jar` from the [releases page](https://github.com/Sathvik-Rao/ClipCascade/releases).
3. Run: `java -jar ClipCascade-Server-JRE_21.jar`
4. Visit `http://localhost:8080`

## First boot

1. Deploy server.
2. Visit `http://<host>:8080` → register first account (auto-becomes an admin-enabled user in single-server deployments).
3. Install the native client for each device you want to sync; point it at your server URL + login.
4. **Set an encryption passphrase** in the client — this is what enables E2E encryption. Same passphrase on every device you want to sync together.
5. Copy something on device A → it appears in clipboard on device B.
6. Put server behind TLS (WebSockets require `wss://` if using HTTPS frontend).
7. Back up `./cc_users/`.

## Data & config layout

- `/database/` (host: `./cc_users/`) — SQLite DB with user accounts + encrypted clipboard history
- No plaintext clipboard data is ever stored server-side (E2E)

## Backup

```sh
sudo tar czf clipcascade-$(date +%F).tgz cc_users/
# Contents: user accounts + encrypted clipboard history (plaintext only reconstructable with the passphrase from the clients)
```

## Upgrade

1. Releases: <https://github.com/Sathvik-Rao/ClipCascade/releases>
2. Docker: `docker pull sathvikrao/clipcascade:latest && docker compose up -d`
3. JAR: download new jar, restart

## Gotchas

- **WebSocket support mandatory at the proxy.** Clipboard sync is real-time via WebSocket. Reverse proxies must pass `Upgrade` + `Connection` headers — nginx/Caddy examples in the upstream repo. Without this, the dashboard loads but sync silently fails.
- **E2E encryption is client-side — passphrase must match on every device.** Lose the passphrase → lose all synced history (server literally can't recover it). Forget to set it → content gets stored but only the same-passphrase devices can read it.
- **Clipboard often contains credentials.** Users copy passwords, API keys, 2FA codes, recovery phrases. ClipCascade stores them encrypted, but **passphrase = the whole shop**. Treat it like a password manager master password.
- **`CC_MAX_MESSAGE_SIZE_IN_MiB` limits clipboard item size.** Default `1` MiB — enough for text/small images. If users copy large images, bump this (and the proxy's body-size limit).
- **Multi-user isolation is per-account, not per-device.** Each user has their own clipboard pool; "devices" are just clients logged into the same account. For team-wide shared clipboards, all team members share one account (not recommended for sensitive use).
- **No 2FA on server login by default.** Single-factor password → brute-force risk if exposed publicly. Restrict with IP allowlist, Cloudflare Access, Tailscale, or a reverse-proxy with basic auth on top.
- **SQLite at `/database/cc_users.db`.** Single-file backup-friendly. For a NAS deploy, point `/database` at a persistent volume that's snapshotted.
- **No federation / public sharing.** All clipboard data stays within your server's user base. No "share a clip to a public URL" feature.
- **Desktop clients need accessibility/clipboard permissions.** On macOS: System Settings → Privacy → Input Monitoring. On Windows: usually works out-of-box. Linux clients vary by desktop env (Wayland vs X11 — check release notes).

## Project health

Active; Docker Hub auto-build; native clients for 4 platforms; community server publicly available for free; solo-maintained by Sathvik Rao.

## Clipboard-sync-family comparison

- **ClipCascade** — Java/Spring, E2E, multi-user, clients for all major desktops + Android
- **Clipboard Manager (native OS)** — no sync across devices
- **KDE Connect / Warpinator** — LAN-only, no server
- **Syncthing** — general file sync, not clipboard-aware
- **SyncClipboard / universal-clipboard** — smaller projects, similar scope

**Choose ClipCascade if:** you want a self-hosted cross-device clipboard with E2E that works across Android + all three desktop OSes, and can accept a JVM dependency on the server.

## Links

- Repo: <https://github.com/Sathvik-Rao/ClipCascade>
- Docker Hub: <https://hub.docker.com/r/sathvikrao/clipcascade>
- Releases (clients + JAR): <https://github.com/Sathvik-Rao/ClipCascade/releases>
- Community server: <http://clipcascade.sathvik.dev>
