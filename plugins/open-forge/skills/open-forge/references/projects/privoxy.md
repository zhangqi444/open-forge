---
name: privoxy-project
description: Privoxy recipe for open-forge. Covers package manager install (apt/yum), source build, and Docker. Based on upstream docs at https://www.privoxy.org/user-manual/.
---

# Privoxy

Non-caching web proxy with advanced filtering capabilities for enhancing privacy, ad blocking, tracking removal, and HTTP header modification. GPL-2.0. Upstream: https://www.privoxy.org. Docs: https://www.privoxy.org/user-manual/

Privoxy is typically deployed as a local or network-level HTTP proxy (default port 8118). Clients configure their browser/system proxy to point at Privoxy, which then filters traffic before forwarding to the upstream internet.

## Compatible install methods

| Method | Platform | When to use |
|---|---|---|
| apt / deb package | Debian, Ubuntu, Raspberry Pi OS | Simplest; managed by system package manager |
| yum / rpm package | RHEL, CentOS, Fedora | Same — system-managed |
| FreeBSD Ports | FreeBSD | `cd /usr/ports/www/privoxy; make install clean` |
| macOS (Homebrew / MacPorts / Fink) | macOS | brew install privoxy |
| Source build | Any Unix | Full control; required for custom patches |
| Docker | Any | Containerised; many community images available |
| Windows installer | Windows | GUI installer from privoxy.org/download |

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| preflight | "Which install method?" | package / source / docker / windows | Drives which section to follow |
| config | "Listen address and port?" | host:port (default 127.0.0.1:8118) | Use 0.0.0.0:8118 to accept from LAN |
| config | "Forward traffic through upstream proxy?" | Yes / No | If yes, collect upstream host:port |
| config | "Which filter sets to enable?" | default / custom | Default config ships ready-to-use filter lists |

## Software-layer concerns

| Concern | Detail |
|---|---|
| Config file | /etc/privoxy/config (Linux package installs) |
| Log file | /var/log/privoxy/logfile |
| Default listen | 127.0.0.1:8118 — change listen-address in config for network-wide use |
| Filters | /etc/privoxy/default.filter — user-defined filters go in /etc/privoxy/user.filter |
| Action files | default.action, match-all.action, user.action — control which rules apply |
| Upstream forwarding | forward-socks5t / forward directives in config for chaining to Tor or another proxy |
| No TLS inspection | Privoxy filters HTTP and CONNECT tunnels but cannot decrypt HTTPS body content |
| Service name | privoxy (systemd/init) |

## Install: apt (Debian / Ubuntu)

Source: https://www.privoxy.org/user-manual/installation.html

```bash
sudo apt-get update
sudo apt-get install privoxy
sudo systemctl enable --now privoxy
```

Config file: /etc/privoxy/config
Log: /var/log/privoxy/logfile

## Install: macOS (Homebrew)

```bash
brew install privoxy
brew services start privoxy
```

Default config: $(brew --prefix)/etc/privoxy/config

## Install: FreeBSD Ports

```bash
cd /usr/ports/www/privoxy
make install clean
```

## Install: Docker

No official Docker image is maintained by the Privoxy project. The most commonly referenced community image:

```bash
docker run -d \
  --name privoxy \
  --restart unless-stopped \
  -p 8118:8118 \
  -v /path/to/privoxy/config:/etc/privoxy \
  vimagick/privoxy:latest
```

Or build your own:

```dockerfile
FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y privoxy && rm -rf /var/lib/apt/lists/*
EXPOSE 8118
CMD ["privoxy", "--no-daemon", "/etc/privoxy/config"]
```

## Install: Windows

Download the installer from https://www.privoxy.org/download/. Double-click to run. Config files are placed in the install directory. Install/uninstall as a Windows service with `--install` / `--uninstall` flags.

## Upgrade procedure

Package: `sudo apt-get upgrade privoxy` (or equivalent). Config files in /etc/privoxy are preserved across upgrades (dpkg will prompt on conflicts).

Source / Docker: Replace binary / image; config files are separate and persist.

## Gotchas

- LAN access requires changing listen-address: Default binds to 127.0.0.1:8118. Edit `listen-address` in config to `0.0.0.0:8118` (or a specific NIC IP) for network-wide use.
- No HTTPS content filtering: Privoxy cannot inspect HTTPS body content — it only sees the CONNECT tunnel for TLS. Use it for HTTP and metadata/header filtering.
- Client proxy config required: Privoxy does nothing until client devices are configured to use it as their HTTP proxy (browser settings or system-wide proxy).
- Log verbosity: Default log level is verbose. Adjust `logfile` and `debug` directives in config to reduce disk usage.
- Forwarding to Tor: Use `forward-socks5t / .onion 127.0.0.1:9050 .` to route .onion addresses through Tor while keeping clearnet traffic direct.

## Links

- User Manual: https://www.privoxy.org/user-manual/
- Installation section: https://www.privoxy.org/user-manual/installation.html
- Configuration reference: https://www.privoxy.org/user-manual/config.html
- Download: https://www.privoxy.org/download/
