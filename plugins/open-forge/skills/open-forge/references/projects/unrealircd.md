---
name: UnrealIRCd
description: Modular, advanced, highly configurable IRC server. Runs on Linux, BSD, Windows, macOS. 37% IRC market share. GPL-2.0 licensed.
website: https://www.unrealircd.org/
source: https://github.com/unrealircd/unrealircd
license: GPL-2.0
stars: 513
tags:
  - irc
  - chat
  - messaging
  - community
platforms:
  - C
  - Docker
---

# UnrealIRCd

UnrealIRCd is an open-source IRC server that has been serving networks since 1999. It holds ~37% of the IRC server market share and is the most widely deployed IRCd. Features include full IRCv3 support, TLS/SSL, JSON-RPC API, cloaking, anti-flood/anti-spam, GeoIP, remote includes, and a powerful module system. Runs on Linux, macOS, BSD, and Windows.

Official site: https://www.unrealircd.org/
Source: https://github.com/unrealircd/unrealircd
Docs: https://www.unrealircd.org/docs/
Latest stable: UnrealIRCd 6 (6.x series)

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VM / VPS | Build from source | Primary method; well-documented |
| Debian/Ubuntu | apt package | Via unrealircd.org repo |
| Any Linux | Docker | Community images available |
| Windows Server | Installer | Official Windows installer |

## Inputs to Collect

**Phase: Planning**
- Server hostname (must resolve to your server's IP)
- Network name for the IRC network
- Admin name and email
- TLS certificate (Let's Encrypt or existing cert)
- Ports: 6667 (plain IRC), 6697 (SSL IRC), 8167 (optional services)
- Whether linking multiple servers (requires shared link block config)

**Phase: First Boot**
- IRC operator username and password (OPER block in config)
- Services (NickServ/ChanServ) — separate daemon (e.g., Anope or Atheme)

## Software-Layer Concerns

**Install from source (Linux):**

```bash
# Dependencies (Debian/Ubuntu)
sudo apt install build-essential libssl-dev libpcre2-dev \
  libargon2-dev libsodium-dev pkg-config

# Download and build
wget https://www.unrealircd.org/downloads/unrealircd-6.1.x.tar.gz
tar -xzf unrealircd-6.1.x.tar.gz
cd unrealircd-6.1.x
./Config   # interactive build configuration
make && make install
# Installs to ~/unrealircd/ by default
```

**Install via apt (Debian/Ubuntu):**

```bash
curl -s https://www.unrealircd.org/unrealircd-repos.sh | bash
sudo apt install unrealircd
```

**Key config file: `unrealircd.conf`**

```
/* Minimal example */
me {
    name "irc.example.com";
    info "My IRC Server";
    sid "001";
}

admin {
    "Admin Name";
    "admin@example.com";
}

class clients {
    pingfreq 90;
    maxclients 1000;
    sendq 200k;
    recvq 8000;
}

allow {
    ip *;
    class clients;
    maxperip 3;
}

listen {
    ip *;
    port 6667;
}

listen {
    ip *;
    port 6697;
    options { tls; }
}

tls-options {
    certificate "/path/to/fullchain.pem";
    key "/path/to/privkey.pem";
}

oper admin {
    class clients;
    mask *@your.ip.here;
    password "CHANGE_ME";
    flags { global-oper; can-rehash; }
}

include "help/help.conf";
include "badwords.conf";
include "spamfilter.conf";
```

**Start/stop:**

```bash
~/unrealircd/unrealircd start
~/unrealircd/unrealircd stop
~/unrealircd/unrealircd rehash   # reload config without restart
```

**Systemd service:** Available in `extras/` directory after install.

**Ports to open in firewall:**
- 6667/tcp — plain IRC (optional, consider TLS-only)
- 6697/tcp — IRC over TLS
- 8167/tcp — optional, for linking servers

## Upgrade Procedure

1. Download new version tarball from https://www.unrealircd.org/downloads/
2. Build new version: `./Config && make && make install`
3. `~/unrealircd/unrealircd stop && ~/unrealircd/unrealircd start`
4. Or use apt: `sudo apt upgrade unrealircd`
5. Upgrade notes: https://www.unrealircd.org/docs/Upgrading

## Gotchas

- **UnrealIRCd 6 only**: UnrealIRCd 5 reached EOL; only 6.x is supported
- **TLS strongly recommended**: Plain IRC on port 6667 transmits passwords in plaintext; use port 6697 with a valid cert
- **Services daemon separate**: UnrealIRCd is the IRC server only — NickServ, ChanServ, etc. require a separate services daemon (Anope or Atheme recommended)
- **Config syntax**: The config file uses a C-style block format (`{}`); syntax errors prevent startup — use `~/unrealircd/unrealircd configtest` to validate
- **Linking servers**: Multi-server networks require matching link blocks on both sides with shared passwords
- **Module system**: Hundreds of third-party modules available at https://modules.unrealircd.org/
- **JSON-RPC**: Built-in management API for scripting and monitoring; see https://www.unrealircd.org/docs/JSON-RPC

## Links

- Upstream README: https://github.com/unrealircd/unrealircd/blob/unreal60/README.md
- Documentation: https://www.unrealircd.org/docs/
- FAQ: https://www.unrealircd.org/docs/FAQ
- Downloads: https://www.unrealircd.org/downloads/
- Module library: https://modules.unrealircd.org/
- Support IRC: irc.unrealircd.org #unreal-support
