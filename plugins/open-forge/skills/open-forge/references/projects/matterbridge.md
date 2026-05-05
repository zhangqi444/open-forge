---
name: Matterbridge
description: "Multi-protocol chat bridge — relay messages between Discord, Slack, Telegram, IRC, Matrix, Mattermost, Rocket.Chat, Teams, XMPP, Zulip, WhatsApp, and more. Single binary or Docker container. Apache 2.0."
---

# Matterbridge

**What it is:** A lightweight, single-binary chat bridge that connects 20+ messaging platforms. Configure channels on different platforms to relay messages to each other — a message sent in a Discord channel appears in a Telegram group and an IRC channel, and vice versa. Minimal setup, TOML config, runs as a daemon or in Docker.

**Official site:** https://github.com/42wim/matterbridge
**Wiki / docs:** https://github.com/42wim/matterbridge/wiki
**License:** Apache 2.0

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Docker | `42wim/matterbridge` | Recommended; config via volume mount |
| Docker Compose | Any Linux host | Easy to manage with restart policy |
| Bare metal binary | Linux / macOS / Windows | Download prebuilt binary from releases |
| Systemd service | Linux | Run as a system service |

---

## Inputs to Collect

### Per platform (examples — configure only the platforms you need)

**Discord:**
- Bot token (create at https://discord.com/developers/applications)
- Server (guild) name or ID
- Channel names to bridge

**Telegram:**
- Bot token from @BotFather
- Chat ID (group/channel ID, negative number for groups)

**Slack:**
- Legacy token or bot token with appropriate scopes
- Workspace name, channel names

**IRC:**
- Server hostname + port (e.g. `irc.libera.chat:6697`)
- Nick, optional SASL credentials
- Channel names (e.g. `#general`)

**Matrix:**
- Homeserver URL
- Username and password (or access token)
- Room IDs or aliases

**Mattermost:**
- Server URL, username, password (or personal access token)
- Team name, channel names

---

## Software-Layer Concerns

### Config file
Single TOML file — `matterbridge.toml`. All platform credentials and bridge rules live here.

### Config structure
```toml
[platform.name]          # e.g. [discord.myserver]
  Token = "..."          # credentials
  ...

[[gateway]]              # a bridge = one gateway
  name = "mybridge"
  enable = true

  [[gateway.inout]]      # each participant channel
    account = "discord.myserver"
    channel = "general"

  [[gateway.inout]]
    account = "telegram.mybot"
    channel = "-1001234567890"
```

### Running as Docker container
```
docker run -d \
  --name matterbridge \
  -v /path/to/matterbridge.toml:/etc/matterbridge/matterbridge.toml:ro \
  42wim/matterbridge
```

---

## Deployment Steps

```bash
mkdir -p ~/docker-apps/matterbridge && cd ~/docker-apps/matterbridge

# Download sample config
curl -o matterbridge.toml \
  https://raw.githubusercontent.com/42wim/matterbridge/master/matterbridge.toml.sample

# Edit matterbridge.toml — fill in credentials and define [[gateway]] blocks

cat > docker-compose.yml << 'COMPOSE'
version: "3"
services:
  matterbridge:
    image: 42wim/matterbridge:stable
    volumes:
      - ./matterbridge.toml:/etc/matterbridge/matterbridge.toml:ro
    restart: unless-stopped
COMPOSE

docker compose up -d
docker compose logs -f   # watch for auth errors
```

---

## Supported Platforms

Discord, Gitter, IRC, Keybase, Matrix, Mattermost, Microsoft Teams, Mumble, Rocket.Chat, Slack, Telegram, Twitch, VK, WhatsApp (beta), XMPP, Zulip — and more via the Matterbridge API.

---

## Upgrade Procedure

```bash
cd ~/docker-apps/matterbridge
docker compose pull
docker compose up -d
```

For binary installs: download the new release binary from https://github.com/42wim/matterbridge/releases and replace the existing one.

---

## Gotchas

- **Credentials in config file** — `matterbridge.toml` contains all bot tokens and passwords in plain text. Restrict file permissions (`chmod 600`) and never commit it to a public repo.
- **Discord bot setup** — The Discord bot needs Message Content Intent enabled in the Developer Portal, and must be invited to the server with appropriate permissions (Read Messages, Send Messages, Manage Webhooks for avatars).
- **Telegram group IDs** — Group chat IDs are negative integers (e.g. `-1001234567890`). Use `@userinfobot` or the Telegram API to find the correct ID.
- **IRC flood limits** — High-traffic bridges can trigger IRC flood protection. Tune `MessageDelay` and `MessageQueue` options in the IRC config section.
- **WhatsApp is beta** — WhatsApp support requires a separate build with `whatsapp` tag due to library restrictions. The standard Docker image may not include it.
- **Message formatting** — Each platform has different formatting rules. Matterbridge does basic conversion but complex markdown/emoji may not translate perfectly across all platforms.
- **No persistence** — Matterbridge does not store messages; it's a real-time relay only. Messages sent while it's offline are lost.
- **Matrix encryption** — Bridging to encrypted Matrix rooms requires additional setup (Pantalaimon or a compatible proxy); not supported out of the box.

---

## Links
- GitHub: https://github.com/42wim/matterbridge
- Wiki: https://github.com/42wim/matterbridge/wiki
- Config guide: https://github.com/42wim/matterbridge/wiki/How-to-create-your-config
- All settings: https://github.com/42wim/matterbridge/wiki/Settings
- Sample config: https://raw.githubusercontent.com/42wim/matterbridge/master/matterbridge.toml.sample
- Releases: https://github.com/42wim/matterbridge/releases
