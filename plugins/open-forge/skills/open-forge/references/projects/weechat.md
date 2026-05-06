---
name: weechat
description: WeeChat recipe for open-forge. Fast, extensible terminal IRC/chat client with a scripting API. Source: https://github.com/weechat/weechat. Website: https://weechat.org.
---

# WeeChat

Fast, lightweight, and extensible terminal chat client (Wee Enhanced Environment for Chat). Primarily used for IRC but supports other protocols via plugins. Written in C with a multi-protocol plugin architecture. Supports scripts in Perl, Python, Ruby, Lua, Tcl, JavaScript, Scheme, and PHP. Runs natively on Linux, macOS, BSD, and Windows (WSL/Cygwin). License: GPL-3.0. Upstream: <https://github.com/weechat/weechat>. Website: <https://weechat.org/>.

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| VPS / server | Native (apt/dnf/pkg) | Recommended; run in tmux/screen for persistence |
| VPS / server | Docker | Official image available |
| Local desktop | Native install | Direct terminal use |
| Any Linux | Build from source | For latest version or custom features |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| irc_server | "IRC server hostname?" | e.g. irc.libera.chat |
| irc_port | "IRC port?" | Default: 6667 (plain), 6697 (TLS) |
| irc_nick | "IRC nickname?" | |
| irc_username | "IRC username/ident?" | |
| irc_realname | "Real name/GECOS?" | |
| tls | "Use TLS for IRC?" | Strongly recommended |
| sasl | "Use SASL authentication?" | Needed for NickServ on most networks |
| sasl_user | "SASL username?" | Usually same as nick |
| sasl_pass | "SASL password?" | |

## Software-layer concerns

- WeeChat is a **client**, not a server — it connects to external IRC/chat servers
- Config stored in `~/.config/weechat/` (or `~/.weechat/` on older installs)
  - `irc.conf` — IRC connection settings
  - `weechat.conf` — core settings (colors, keys, etc.)
  - `plugins.conf` — plugin/script settings
- For always-on IRC presence, run WeeChat in a persistent tmux/screen session on a VPS
- **WeeChat Relay**: built-in relay protocol lets mobile apps (Weechat-Android, Glowing-Bear) connect to a running WeeChat instance remotely
- Docker image: `weechat/weechat` (Docker Hub)
- Scripts (plugins) installed via `/script install <name>` in-client, or by dropping files into `~/.config/weechat/python/`, `perl/`, etc.

### Install (Debian/Ubuntu)

```bash
sudo apt install weechat weechat-plugins weechat-python weechat-perl
weechat
```

### Install (macOS via Homebrew)

```bash
brew install weechat
weechat
```

### Docker (persistent config)

```bash
docker run -it \
  --name weechat \
  -v ~/.config/weechat:/home/user/.config/weechat \
  weechat/weechat
```

### Connect to an IRC server (in-client commands)

```
# Add server
/server add libera irc.libera.chat/6697 -ssl

# Set nick and SASL
/set irc.server.libera.nicks "mynick"
/set irc.server.libera.sasl_mechanism plain
/set irc.server.libera.sasl_username "mynick"
/set irc.server.libera.sasl_password "mypassword"
/set irc.server.libera.autoconnect on

# Connect
/connect libera

# Join a channel
/join #weechat
```

### Always-on VPS setup (tmux)

```bash
# On your VPS:
tmux new-session -d -s weechat weechat
# Reattach later:
tmux attach -t weechat
```

### WeeChat Relay (for mobile access)

```
# In WeeChat:
/relay add ssl.weechat 9001
/set relay.network.password "yourpassword"
# Then connect Glowing-Bear (https://www.glowing-bear.org) or Weechat-Android
```

### Useful scripts to install

```
/script install autosort.py        # Auto-sort buffers
/script install buflist.pl         # Buffer list panel
/script install highmon.pl         # Highlight monitor
/script install multiline.pl       # Multi-line message input
/script install text_item.py       # Custom status bar items
```

## Upgrade procedure

1. **Package manager**: `sudo apt upgrade weechat` (or equivalent)
2. **Docker**: `docker pull weechat/weechat && docker stop weechat && docker rm weechat`, then re-run with same volume mount
3. **Source build**: pull latest tag, `cmake -B build && cmake --build build && sudo cmake --install build`
4. Config format is generally backward-compatible; check release notes for breaking changes

## Gotchas

- **Not a server**: WeeChat is a client. For a self-hosted chat network, pair it with an IRC server (e.g. InspIRCd, UnrealIRCd) or use it as a client to connect to existing networks.
- **Persistent sessions require tmux/screen**: WeeChat exits when the terminal closes. Run it inside `tmux` or `screen` on a VPS to stay connected 24/7.
- **Config directory changed in v4**: Older installs use `~/.weechat/`; v4+ prefers `~/.config/weechat/`. WeeChat migrates automatically but scripts and tools should reference the new path.
- **TLS verification**: By default, WeeChat verifies TLS certs. On networks with self-signed certs, set `/set irc.server.SERVERNAME.ssl_verify off` (not recommended for production).
- **Flood protection**: WeeChat sends messages with flood protection delays by default. On busy channels, this is intentional; don't disable it or you may get killed for flooding.
- **Docker image is minimal**: The official Docker image is stripped down. Install additional language plugins (`weechat-python`, `weechat-perl`) if needed by rebuilding the image or using the full Debian package.

## Links

- Upstream repo: https://github.com/weechat/weechat
- Website: https://weechat.org/
- Documentation: https://weechat.org/doc/weechat/
- Script repository: https://weechat.org/scripts/
- Docker Hub: https://hub.docker.com/r/weechat/weechat
- Glowing-Bear (web frontend): https://www.glowing-bear.org
- Release notes: https://weechat.org/files/releasenotes/RelNotes-devel.html
