---
name: znc
description: ZNC recipe for open-forge. Covers Docker (linuxserver) and package-based install. ZNC is an advanced IRC bouncer (BNC) that keeps you connected to IRC networks 24/7.
---

# ZNC

Advanced IRC network bouncer (BNC). ZNC stays permanently connected to your IRC networks and channels, so your messages are preserved even when your client is offline. Multiple clients from different locations can connect to the same ZNC account simultaneously, all appearing under the same nickname. Supports modules/plugins for logging, push notifications, SASL auth, and more. Upstream: <https://github.com/znc/znc>. Website: <https://wiki.znc.in/ZNC>.

**License:** Apache-2.0 · **Language:** C++ · **Default port:** 6501 (Web UI + client connects) · **Stars:** ~2,100

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker (linuxserver) | `lscr.io/linuxserver/znc` | Community (LSIO) | **Recommended** — multi-arch, auto-updates, easy setup. |
| Package (Debian/Ubuntu) | `apt install znc` | Distro | System install, managed by apt. |
| Package (macOS) | `brew install znc` | Community | macOS homelab. |
| Build from source | <https://wiki.znc.in/Installation> | ✅ | Latest modules or custom patches. |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| irc_networks | "Which IRC networks do you want to connect to? (e.g. Libera.Chat, OFTC)" | Free-text | All methods. |
| irc_nick | "Your IRC nickname?" | Free-text | All methods. |
| znc_port | "ZNC listen port? (default: 6501)" | Free-text | All methods. |
| tls | "Enable TLS on ZNC port?" | AskUserQuestion: Yes / No | Recommended. |
| puid_pgid | "User/Group ID for file permissions (PUID/PGID — default: 1000/1000)?" | Free-text | Docker. |

## Install — Docker (linuxserver — recommended)

```bash
mkdir znc && cd znc

cat > docker-compose.yml << 'COMPOSE'
services:
  znc:
    image: lscr.io/linuxserver/znc:latest
    container_name: znc
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=America/New_York
    volumes:
      - ./config:/config
    ports:
      - "6501:6501"
    restart: unless-stopped
COMPOSE

docker compose up -d
```

After first start, access the Web UI at `http://<your-server>:6501`.

Default credentials: **admin / admin** — change immediately.

### Initial setup via Web UI

1. Browse to `http://<server>:6501`
2. Log in as `admin` / `admin`
3. Go to **Admin → Your Settings** and change your password
4. Go to **Your Settings → Networks** → Add Network
5. Enter IRC server address (e.g. `irc.libera.chat:6697+ssl`)
6. Set your nickname, realname, and channels
7. Save — ZNC will connect to IRC immediately

## Install — Package (Debian/Ubuntu)

```bash
sudo apt update
sudo apt install znc znc-extra znc-dev

# Run the configuration wizard
znc --makeconf
# Follow the interactive prompts to set up admin user, port, IRC networks

# Start ZNC
znc
# Or as a systemd service (if znc creates one):
sudo systemctl enable --now znc
```

## Client setup

Connect your IRC client to ZNC instead of directly to IRC:

| Setting | Value |
|---|---|
| Server | your-server-ip or hostname |
| Port | 6501 (or your configured port) |
| Password | `znc_username/znc_network:znc_password` |
| TLS | Enable if ZNC has TLS configured |

**Password format:** `username/networkname:password` — the `/networkname` part can be omitted for the default network.

Example for irssi:

```
/server add -tls -tls_verify -network ZNC your-server 6501 admin/libera:yourpassword
/connect ZNC
```

## Configuration file location

ZNC stores its config in `~/.znc/configs/znc.conf` (bare-metal) or `/config/znc.conf` (Docker volume).

### Key config sections

```ini
<User admin>
  Admin = true
  Pass = sha256#<hash>#<salt>#
  Nick = yournick
  AltNick = yournick_
  RealName = Your Name
  Ident = znc

  <Network libera>
    Server = irc.libera.chat +6697
    Chan = #channel1
    Chan = #channel2
  </Network>
</User>
```

## Modules (plugins)

ZNC is extended via modules. Load from Web UI → **Your Settings → Modules**.

Popular modules:

| Module | Purpose |
|---|---|
| `log` | Log all IRC messages to disk |
| `clientnotify` | Push notifications when no client is connected |
| `sasl` | SASL authentication to IRC networks |
| `chansaver` | Auto-save channels you join |
| `controlpanel` | Additional admin controls |
| `identd` | Identd daemon for IRC auth |
| `push` | Push notifications to ntfy, Pushover, etc. |
| `backlog` | Buffer scrollback for connecting clients |
| `cert` | Client TLS certificate auth to IRC servers |

```bash
# Docker: znc-extra usually included in linuxserver image
# Package: install extra modules
sudo apt install znc-extra
```

## TLS configuration

Enable TLS so clients connect securely to ZNC:

```bash
# Generate self-signed cert (ZNC will use it automatically)
znc --makepem

# Or with Docker (linuxserver handles this via webui)
# In Web UI: Admin → Global Settings → Enable TLS listener
```

For Let's Encrypt certificates, mount your cert/key into the Docker container and configure the path in the ZNC Web UI.

## Software-layer concerns

| Concern | Detail |
|---|---|
| Config file | ZNC generates `znc.conf` on first start. Don't hand-edit while ZNC is running — use the Web UI or stop ZNC first. |
| Buffering | ZNC stores messages while you're offline in memory. Use the `log` module for permanent disk-based logs. |
| Multiple networks | ZNC can connect to multiple IRC networks simultaneously under one user account. |
| Multiple users | ZNC supports multiple user accounts — each user has their own IRC networks and settings. |
| SASL auth | Many networks require SASL. Enable the `sasl` module and configure credentials per-network. |
| Timezone | Set `TZ` env var in Docker for correct timestamps in logs. |
| Port conflicts | ZNC uses a single port for both Web UI and IRC client connections. Use TLS on port 6697 for standard IRC SSL port convention. |

## Upgrade procedure

```bash
# Docker
docker compose pull
docker compose up -d

# Package
sudo apt update && sudo apt upgrade znc
# Restart:
sudo systemctl restart znc
# Or kill/restart the ZNC process if running manually
```

## Gotchas

- **Default password is admin/admin:** Change it immediately after first login — the Web UI is exposed on the same port clients use.
- **Password format for IRC clients:** The password you enter in your IRC client must be in the format `username/network:password`. Forgetting the `/network` part causes auth failures if you have multiple networks.
- **Config edits while running:** Never hand-edit `znc.conf` while ZNC is running. Use the Web UI or the `-i` (interactive) control socket. ZNC overwrites the config file on save and you'll lose changes.
- **Buffering vs logging:** By default, ZNC buffers messages in memory only. If you want persistent logs that survive restarts, load the `log` module.
- **IRC network SASL requirements:** Libera.Chat, OFTC, and other modern networks recommend or require SASL authentication. Load the `sasl` module and register your account credentials.
- **Docker TLS note:** linuxserver image documents that read-only mode is not supported with TLS — keep this in mind in hardened environments.

## Upstream links

- GitHub: <https://github.com/znc/znc>
- Wiki / docs: <https://wiki.znc.in/ZNC>
- Docker (linuxserver): <https://docs.linuxserver.io/images/docker-znc>
- Docker Hub: <https://hub.docker.com/r/linuxserver/znc>
- Module list: <https://wiki.znc.in/Modules>
- Installation guide: <https://wiki.znc.in/Installation>
