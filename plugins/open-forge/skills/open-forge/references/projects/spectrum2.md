---
name: spectrum2
description: Spectrum 2 recipe for open-forge. Open-source XMPP transport/gateway that bridges XMPP to other IM networks (Slack, Telegram, IRC, etc.) via libpurple or other backends. C++. Source: https://github.com/SpectrumIM/spectrum2
---

# Spectrum 2

Open-source instant messaging transport (gateway) for XMPP servers. Bridges XMPP users to other IM networks — users on your XMPP server can chat with contacts on Slack, Telegram, IRC, Discord, and other networks without switching clients. Uses libpurple (Pidgin) or other backends. Written in C++. GPL-3.0.

Upstream: <https://github.com/SpectrumIM/spectrum2> | Site: <https://spectrum.im>

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Debian/Ubuntu | apt package | Available in distro repos; may be outdated |
| Any | Build from source (C++) | cmake + libpurple + libev + Swiften/XMPP |
| Any (with XMPP server) | Prosody, ejabberd, Openfire | Spectrum 2 acts as a component connecting to your XMPP server |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | XMPP server (Prosody/ejabberd) running | Spectrum 2 connects as a component, not standalone |
| config | XMPP server host and component port | Usually 127.0.0.1:5347 (Prosody default) |
| config | Component JID | e.g. telegram.xmpp.example.com |
| config | Component password | Set in XMPP server component config |
| config | Backend type | telegram, slack, irc, etc. (via libpurple plugins) |
| config | Database backend | SQLite (simple) or MySQL/PostgreSQL |

## Software-layer concerns

### Architecture

Spectrum 2 runs as a component that connects to an XMPP server via the XMPP component protocol (XEP-0114). It proxies messages between the XMPP user's account and the external IM network using a backend plugin.

```
[XMPP Client] ← XMPP → [XMPP Server (Prosody)] ← component port → [Spectrum 2] ← backend → [Telegram/Slack/IRC/...]
```

### Config file

`/etc/spectrum2/<transport>.cfg` (one file per transport/network):

```ini
[service]
jid = telegram.example.com
server = 127.0.0.1
port = 5347
password = component-secret
backend = /usr/lib/spectrum2/backends/spectrum2_telegram_backend

[identity]
name = Telegram Transport
type = telegram

[database]
backend = sqlite
database = /var/lib/spectrum2/telegram.db

[logging]
config = /etc/spectrum2/logging.cfg
```

### Prosody component setup

Add to Prosody `prosody.cfg.lua`:
```lua
Component "telegram.example.com"
    component_secret = "component-secret"
```

### libpurple backends

Available backends depend on installed libpurple plugins:
- telegram-purple → Telegram
- slack-libpurple → Slack
- purple → IRC, XMPP-to-XMPP bridging
- Various others via Pidgin plugin ecosystem

## Install — Debian/Ubuntu

```bash
sudo apt-get install spectrum2 spectrum2-backend-purple libpurple-dev

# For Telegram backend:
sudo apt-get install telegram-purple
# or build telegram-purple from https://github.com/majn/telegram-purple
```

## Install — from source

```bash
sudo apt-get install cmake libpurple-dev libevent-dev libpopt-dev \
  libprotobuf-dev protobuf-compiler libboost-dev libssl-dev \
  libsqlite3-dev libmysqlclient-dev

git clone https://github.com/SpectrumIM/spectrum2.git
cd spectrum2
mkdir build && cd build
cmake ..
make -j$(nproc)
sudo make install
```

## Running

```bash
# Create config dirs
sudo mkdir -p /etc/spectrum2 /var/lib/spectrum2 /var/log/spectrum2

# Copy and edit config
sudo cp /usr/share/spectrum2/examples/telegram.cfg /etc/spectrum2/telegram.cfg
sudo $EDITOR /etc/spectrum2/telegram.cfg

# Start (as spectrum user)
sudo -u spectrum spectrum2 /etc/spectrum2/telegram.cfg

# Or with systemd (if service file is installed)
sudo systemctl enable --now spectrum2@telegram
```

## Upgrade procedure

```bash
# apt
sudo apt-get upgrade spectrum2

# from source
cd spectrum2 && git pull
mkdir -p build && cd build
cmake .. && make -j$(nproc)
sudo make install
sudo systemctl restart spectrum2@telegram
```

## Gotchas

- Spectrum 2 is not a standalone server — it requires an existing XMPP server (Prosody, ejabberd, Openfire) to connect to as a component. Set up the XMPP server first.
- The component JID (e.g. `telegram.example.com`) must be a subdomain that resolves to your server or is handled by your XMPP server's component listener.
- One Spectrum 2 instance per network — run a separate process for each IM network you want to bridge (one for Telegram, one for IRC, etc.).
- libpurple backends are the most common but quality varies by network — Telegram via telegram-purple works well; other backends may be less maintained.
- As of 2023, the latest release tag is 2.2.1 — the project has low recent commit activity. Check GitHub for current status before deploying.
- Users must register their IM network credentials with the transport via their XMPP client (in-band registration, XEP-0077).

## Links

- Source: https://github.com/SpectrumIM/spectrum2
- Website: https://spectrum.im
- Documentation: https://spectrum.im/documentation/
