---
name: ngircd
description: Recipe for ngIRCd — a portable, lightweight Internet Relay Chat (IRC) server for small or private networks. C, package manager or Docker.
---

# ngIRCd

Portable, lightweight Internet Relay Chat (IRC) server designed for small or private networks. Supports IPv6, SSL/TLS, PAM authentication, IDENT requests, server-to-server links, channel modes, and user cloaking. Simple INI-style configuration file. Written in C; widely available in Linux and BSD package repositories. Upstream: <https://github.com/ngircd/ngircd>. Website: <https://ngircd.barton.de/>.

License: GPL-2.0. Platform: Linux, BSD, macOS, Docker. Port: `6667` (IRC), `6697` (IRC+TLS).

## Compatible install methods

| Method | When to use |
|---|---|
| Package manager | Recommended — available in most distro repos |
| Docker (linuxserver/ngircd) | Containerised deploy |
| Source build | For latest version or custom compile options |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| network | "IRC server name (must contain a dot, e.g. irc.home.net)?" | Must be unique in any linked network |
| network | "Host port for IRC?" | Default `6667` (plain) or `6697` (TLS) |
| tls | "Enable TLS? Certificate and key paths?" | Optional but recommended for non-local networks |
| admin | "Admin info (name, location, email)?" | Required by IRC RFC; shown via `/admin` command |
| channels | "Any default channels to pre-create?" | Optional `[Channel]` blocks in config |

## Package manager install

### Debian / Ubuntu
```bash
sudo apt install ngircd
# Config: /etc/ngircd/ngircd.conf
# Service: sudo systemctl enable --now ngircd
```

### Alpine Linux
```bash
apk add ngircd
```

### Arch Linux
```bash
pacman -S ngircd
```

## Docker

```bash
mkdir ngircd && cd ngircd
```

`docker-compose.yml`:
```yaml
services:
  ngircd:
    image: linuxserver/ngircd:latest
    restart: unless-stopped
    ports:
      - "6667:6667"
      - "6697:6697"
    volumes:
      - ./config:/config
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=UTC
```

```bash
docker compose up -d
```

Edit `./config/ngircd.conf` then restart: `docker compose restart ngircd`

## Configuration (`/etc/ngircd/ngircd.conf`)

Minimal working config:
```ini
[Global]
Name = irc.example.net
AdminInfo1 = My IRC Server
AdminInfo2 = Home Lab
AdminEMail = admin@example.com
Ports = 6667

[Options]
PAM = no

[Limits]
MaxConnections = 100
MaxConnectionsIP = 10
```

With TLS (port 6697):
```ini
[SSL]
CertFile = /etc/ssl/ngircd.crt
KeyFile = /etc/ssl/ngircd.key
Ports = 6697
```

Channel pre-create:
```ini
[Channel]
Name = #general
Topic = General discussion
MaxUsers = 50
```

## Validate config

Always validate after changes:
```bash
ngircd --configtest
```

## Software-layer concerns

| Concern | Detail |
|---|---|
| Config file | `/etc/ngircd/ngircd.conf` (or `/usr/local/etc/ngircd.conf` from source) |
| Drop-in dir | `/etc/ngircd/ngircd.conf.d/*.conf` — override settings without editing main file |
| IRC port | `6667` (plain TCP) |
| TLS port | `6697` (IRC over SSL) |
| Logs | `syslog` / `journald` |
| Server-to-server | Link multiple ngIRCd instances via `[Server]` blocks |
| PAM auth | Enable with `PAM = yes` in `[Options]` for system user authentication |

## Upgrade procedure

```bash
# Package manager
sudo apt update && sudo apt upgrade ngircd
sudo systemctl restart ngircd
```

## Gotchas

- **Server name must contain a dot**: The `Name` setting (e.g. `irc.home.net`) must contain at least one period. Names without a dot are rejected.
- **AdminInfo required by RFC**: If `AdminInfo1`, `AdminInfo2`, and `AdminEMail` are not set, ngIRCd starts with a warning and the `/admin` command returns incomplete info.
- **Config changes require restart**: ngIRCd does not hot-reload its configuration. Changes require `systemctl restart ngircd`.
- **Always run `--configtest` after changes**: `ngircd --configtest` catches syntax errors and warns about common misconfigurations before they cause runtime issues.
- **No web UI**: ngIRCd is a pure IRC server. Users connect with any IRC client (HexChat, WeeChat, irssi, etc.).
- **Drop-in directory preferred**: Use `/etc/ngircd/ngircd.conf.d/` for custom settings rather than editing the main config file, to avoid losing changes on package upgrades.

## Upstream links

- Source: <https://github.com/ngircd/ngircd>
- Website: <https://ngircd.barton.de/>
- QuickStart guide: <https://github.com/ngircd/ngircd/blob/master/doc/QuickStart.md>
- Sample config: <https://ngircd.barton.de/doc/sample-ngircd.conf>
- Manual page: `man ngircd.conf` or <https://ngircd.barton.de/documentation>
