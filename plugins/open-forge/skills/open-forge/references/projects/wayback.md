---
name: wayback
description: Wayback (wabarc) recipe for open-forge. Covers Docker and binary install. Wayback is a self-hosted toolkit for archiving webpages to the Internet Archive, archive.today, IPFS, and local file systems.
---

# Wayback (wabarc)

Self-hosted web archiving toolkit that preserves webpages to multiple destinations: Internet Archive (Wayback Machine), archive.today, IPFS, and local disk. Can run as a daemon integrated with Telegram, Discord, Matrix, Mastodon, IRC, Slack, Twitter/X, and XMPP — so users can send links to the bot and receive archived URLs back. Built in Go as a single static binary. Upstream: <https://github.com/wabarc/wayback>. Docs: <https://docs.wabarc.eu.org>.

**License:** GPL-3.0 · **Language:** Go · **Stars:** ~2,200

> **Activity note:** The last release was v0.20.1 in July 2024. Commits are sporadic. The tool works well but development has slowed — review the release page before deploying.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker | <https://hub.docker.com/r/wabarc/wayback> | ✅ | **Recommended** — easiest deployment. |
| Binary | <https://github.com/wabarc/wayback/releases> | ✅ | Bare-metal, systemd service. |
| APT (Debian/Ubuntu) | <https://repo.wabarc.eu.org/apt/> | ✅ | System-managed install on Debian/Ubuntu. |
| RPM (Fedora/CentOS) | <https://repo.wabarc.eu.org/yum/> | ✅ | System-managed install on RPM-based distros. |
| Snap | `snap install wayback` | Community | Ubuntu/Snap users. |
| Go install | `go install github.com/wabarc/wayback/cmd/wayback@latest` | ✅ | Go development environments. |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| daemon_type | "Run as which daemon? (telegram / discord / matrix / mastodon / web / none — for CLI use only)" | AskUserQuestion | All methods. |
| telegram_token | "Telegram Bot Token (from BotFather)" | Free-text | Telegram daemon. |
| telegram_channel | "Telegram channel username (optional, for posting results)" | Free-text | Optional. |
| ipfs_enable | "Archive to IPFS? (requires IPFS node or API key)" | AskUserQuestion: Yes / No | Optional. |
| local_storage | "Store archived files locally on disk?" | AskUserQuestion: Yes / No | Optional. |

## Archiving targets

Wayback can archive to multiple destinations simultaneously:

| Flag | Env var | Destination |
|---|---|---|
| `--ia` | `WAYBACK_ENABLE_IA=true` | Internet Archive (Wayback Machine) |
| `--is` | `WAYBACK_ENABLE_IS=true` | archive.today |
| `--ip` | `WAYBACK_ENABLE_IP=true` | IPFS |
| `--ph` | `WAYBACK_ENABLE_PH=true` | Telegraph (for publishing results) |
| `--local` | `WAYBACK_STORAGE_DIR=/path` | Local filesystem |

## Install — Docker (Telegram bot daemon)

```bash
mkdir wayback && cd wayback

cat > docker-compose.yml << 'COMPOSE'
services:
  wayback:
    image: wabarc/wayback:latest
    restart: unless-stopped
    environment:
      - WAYBACK_TELEGRAM_TOKEN=YOUR_BOT_TOKEN
      # Optional: post results to a Telegram channel
      # - WAYBACK_TELEGRAM_CHANNEL=@yourchannel
      # Enable archiving targets:
      - WAYBACK_ENABLE_IA=true
      - WAYBACK_ENABLE_IS=true
      # Optional local storage
      # - WAYBACK_STORAGE_DIR=/data
    command: ["wayback", "--daemon", "telegram"]
    volumes:
      - wayback-data:/data

volumes:
  wayback-data:
COMPOSE

docker compose up -d
```

### Web daemon (HTTP API + web UI)

```bash
docker run -d \
  --name wayback \
  -p 8964:8964 \
  -e WAYBACK_ENABLE_IA=true \
  -e WAYBACK_ENABLE_IS=true \
  wabarc/wayback:latest \
  wayback --daemon web
```

## Install — Binary

```bash
# Quick install
curl -fsSL https://get.wabarc.eu.org | sh

# Or download from releases
VERSION=v0.20.1
curl -LO https://github.com/wabarc/wayback/releases/download/${VERSION}/wayback_linux_amd64.tar.gz
tar xzf wayback_*.tar.gz
sudo mv wayback /usr/local/bin/

# Test CLI archiving
wayback --ia --is https://example.com
```

### Systemd service (Telegram bot)

```ini
# /etc/systemd/system/wayback.service
[Unit]
Description=Wayback Archiving Daemon
After=network.target

[Service]
Type=simple
EnvironmentFile=/etc/wayback/wayback.env
ExecStart=/usr/local/bin/wayback --daemon telegram
Restart=unless-stopped
User=www-data

[Install]
WantedBy=multi-user.target
```

```bash
# /etc/wayback/wayback.env
WAYBACK_TELEGRAM_TOKEN=YOUR_BOT_TOKEN
WAYBACK_ENABLE_IA=true
WAYBACK_ENABLE_IS=true
```

```bash
sudo systemctl enable --now wayback
```

## Install — APT (Debian/Ubuntu)

```bash
curl -fsSL https://repo.wabarc.eu.org/apt/gpg.key | sudo gpg --dearmor -o /usr/share/keyrings/packages.wabarc.gpg
echo "deb [arch=amd64,arm64,armhf signed-by=/usr/share/keyrings/packages.wabarc.gpg] https://repo.wabarc.eu.org/apt/ /" | sudo tee /etc/apt/sources.list.d/wayback.list
sudo apt update
sudo apt install wayback
```

## Configuration

Wayback can be configured via environment variables, a config file, or CLI flags.

Key config file (`~/wayback.conf` or `/etc/wayback.conf`):

```ini
[Wayback]
# Archiving targets
ia = true        # Internet Archive
is = true        # archive.today
ip = false       # IPFS
ph = false       # Telegraph

[Telegram]
token = "YOUR_BOT_TOKEN"
channel = ""    # Optional channel to post results

[Storage]
# Local storage directory (empty = disabled)
dir = ""

[Web]
# Web daemon listen address
listen = "0.0.0.0:8964"
```

Full configuration reference: <https://docs.wabarc.eu.org/configuration/>

## CLI usage (one-shot archiving)

```bash
# Archive a single URL to Internet Archive
wayback --ia https://example.com

# Archive to Internet Archive and archive.today
wayback --ia --is https://example.com

# Archive multiple URLs
wayback --ia https://url1.com https://url2.com

# Archive to IPFS (requires IPFS API key / Pinata)
WAYBACK_SLOT=pinata WAYBACK_APIKEY=YOUR_API_KEY WAYBACK_SECRET=YOUR_SECRET \
  wayback --ip https://example.com
```

## Software-layer concerns

| Concern | Detail |
|---|---|
| No local storage by default | By default, Wayback archives to external services (Internet Archive, archive.today). Set `WAYBACK_STORAGE_DIR` to also save locally. |
| Internet Archive rate limits | Archiving via Wayback Machine can hit rate limits. Wayback queues and retries automatically. |
| archive.today CAPTCHAs | archive.today sometimes requires CAPTCHA solving — automated archiving may fail or be slow. |
| IPFS archiving | Requires an IPFS node, Pinata account, or similar. Not automatic — needs API credentials. |
| Telegram bot setup | Create a bot via BotFather. Users send URLs to the bot in a chat; the bot archives and replies with links. |
| Media archiving | Video/audio download requires FFmpeg installed on the host or in the container. |
| Web daemon | HTTP endpoint at `:8964` with a form UI for submitting URLs. No auth by default — put behind a reverse proxy. |

## Upgrade procedure

```bash
# Docker
docker compose pull
docker compose up -d

# Binary
curl -fsSL https://get.wabarc.eu.org | sh

# APT
sudo apt update && sudo apt upgrade wayback
```

## Gotchas

- **Slowing development:** Last release was mid-2024. Core functionality is stable but don't expect rapid new features or bug fixes.
- **archive.today blocking:** archive.today frequently changes anti-bot measures. Automated archiving to it can break unexpectedly.
- **No authentication on web daemon:** The web daemon has no built-in auth. Expose it publicly only behind a reverse proxy with basic auth or similar.
- **Telegram bot privacy:** In groups, Telegram bots can only read messages addressed to them (due to privacy mode). In direct chats and channels, all messages can be processed.
- **IPFS credentials:** IPFS archiving doesn't use a local IPFS node by default — it uses the Pinata API. Provide `WAYBACK_SLOT`, `WAYBACK_APIKEY`, `WAYBACK_SECRET` environment variables.

## Upstream links

- GitHub: <https://github.com/wabarc/wayback>
- Docs: <https://docs.wabarc.eu.org>
- Configuration reference: <https://docs.wabarc.eu.org/configuration/>
- Releases: <https://github.com/wabarc/wayback/releases>
- Docker Hub: <https://hub.docker.com/r/wabarc/wayback>
- APT repo: <https://repo.wabarc.eu.org/apt/>
