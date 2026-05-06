---
name: tinyproxy
description: Tinyproxy recipe for open-forge. Lightweight HTTP/HTTPS proxy daemon for small networks. Self-hosted via native packages (deb/rpm) or compiled from source. Source: https://github.com/tinyproxy/tinyproxy. Docs: https://tinyproxy.github.io.
---

# Tinyproxy

Small, efficient HTTP/HTTPS proxy daemon for small network environments where a heavier proxy (Squid, etc.) would be overkill. Key feature: buffering — Tinyproxy buffers high-speed server responses and relays them to clients at the client's maximum speed, reducing sluggishness over shared connections. Upstream: <https://github.com/tinyproxy/tinyproxy>. Website: <https://tinyproxy.github.io>.

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Linux VPS / bare metal | deb/rpm package | Upstream provides .deb and .rpm packages; also in most distro repos |
| Linux VPS / bare metal | Compiled from source | Required for enabling optional features (filtering, transparent proxy) |
| Docker | Community image (not official) | No official Docker image; use `vimagick/tinyproxy` or build your own |
| Raspberry Pi / small device | deb package | Very lightweight (~600 KB binary); ideal for embedded/home use |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Which Linux distro?" | Debian/Ubuntu = apt; RHEL/Fedora = dnf/yum; Alpine = apk |
| network | "Which port should Tinyproxy listen on?" | Default: 8888 |
| access | "Which IP(s)/subnets are allowed to use the proxy?" | Allow directive; default is localhost only — open to your LAN CIDR |
| logging | "Log verbosity level?" | Options: Critical, Error, Warning, Notice, Connect, Info |
| filter | "Enable domain filtering?" | Requires compiling with --enable-filter |

## Software-layer concerns

- Config file: /etc/tinyproxy/tinyproxy.conf (package install) or /usr/local/etc/tinyproxy/tinyproxy.conf (source)
- Default port: 8888
- Default allow: 127.0.0.1 only (must add Allow directives for your network)
- Log file: /var/log/tinyproxy/tinyproxy.log
- PID file: /run/tinyproxy/tinyproxy.pid
- User: runs as tinyproxy system user (created on package install)
- No external database; fully stateless

### Install (Debian/Ubuntu)

```bash
sudo apt-get update && sudo apt-get install tinyproxy
sudo systemctl enable --now tinyproxy
```

### Key tinyproxy.conf settings

```conf
Port 8888
Listen 0.0.0.0

# Allow only specific subnets
Allow 127.0.0.1
Allow 192.168.1.0/24

LogLevel Notice
LogFile "/var/log/tinyproxy/tinyproxy.log"
MaxClients 100

# Optional: upstream proxy (chain to another proxy)
# upstream http upstream-proxy.example.com:8080

# Optional: basic auth
# BasicAuth user password
```

Apply changes: `sudo systemctl reload tinyproxy` (or restart if reload isn't supported).

### Test the proxy

```bash
curl -x http://localhost:8888 https://example.com
```

### Docker (community image)

```yaml
services:
  tinyproxy:
    image: vimagick/tinyproxy:latest
    ports:
      - "8888:8888"
    volumes:
      - ./tinyproxy.conf:/etc/tinyproxy/tinyproxy.conf:ro
    restart: unless-stopped
```

## Upgrade procedure

1. Debian/Ubuntu: `sudo apt-get update && sudo apt-get install --only-upgrade tinyproxy`
2. From source: pull new tag, `./autogen.sh && ./configure [flags] && make && sudo make install`, restart service
3. Check release notes: https://github.com/tinyproxy/tinyproxy/releases

## Gotchas

- **Allow directive is mandatory** for non-localhost use: without an `Allow` entry matching the client IP, Tinyproxy returns 403. Always add your LAN CIDR (e.g. `Allow 192.168.0.0/24`).
- **Optional features require compile flags**: domain filtering (`--enable-filter`), transparent proxy mode (`--enable-transparent`), upstream proxy support (`--enable-upstream`) must be compiled in. Distro packages usually include all features.
- **No HTTPS MITM**: Tinyproxy forwards HTTPS tunnels (CONNECT method) without decrypting them. It is a forwarding proxy, not a TLS-intercepting proxy.
- **MaxClients**: Default 100 concurrent connections is usually enough for home/small office use. Raise for higher traffic.
- **Logging**: Connect log level is useful for auditing — logs every CONNECT request. Info is verbose and may fill disk quickly on busy networks.
- **Transparent proxy**: Requires kernel-level traffic redirection (iptables REDIRECT or TPROXY rules); the Tinyproxy config alone is not sufficient.

## Links

- Upstream repo: https://github.com/tinyproxy/tinyproxy
- Website / docs: https://tinyproxy.github.io
- Man page: https://tinyproxy.github.io/man-tinyproxy.8.html
- Config reference: https://tinyproxy.github.io/man-tinyproxy.conf.5.html
- Release notes: https://github.com/tinyproxy/tinyproxy/releases
