---
name: Zoraxy
description: "General-purpose HTTP reverse proxy + TLS/ACME + TCP/UDP stream proxy + forward-auth + uptime monitor + web-SSH + utilities, all in a single Go binary with a web UI. Homelab-friendly alternative to Nginx Proxy Manager / Traefik / Caddy-with-UI. AGPL-3.0."
---

# Zoraxy

Zoraxy is **"a reverse proxy and homelab Swiss-army knife"** — a single Go binary that provides HTTP/HTTPS reverse proxy with auto-TLS, stream proxy (TCP + UDP), an uptime monitor, forward-auth integration (Authelia / Authentik / OAuth2 / reCAPTCHA), web-SSH terminal, mDNS scanner, port scanner, Wake-on-LAN, blacklist/whitelist by country or CIDR, and a plugin system. Developed by **Toby Chui (tobychui)**. Mature, actively developed, popular in homelab community.

Positioning vs alternatives:
- **Nginx Proxy Manager (NPM)** — similar UX; more mature; smaller feature scope
- **Traefik** — more Kubernetes-native; configuration-as-code
- **Caddy** — simpler + elegant; less UI
- **Zoraxy** — **single binary** + **many utilities** + **opinionated UI** + homelab-focus

Features:

- **HTTP/2 reverse proxy** with virtual directory, WebSocket (auto), Basic Auth, aliases, custom headers, load balancing
- **Redirection rules**
- **TLS / ACME** — auto Let's Encrypt + SAN certs + **DNS-challenge** for many providers (go-acme/lego)
- **Geo + IP ACLs** — country blocklist, CIDR/wildcard IP lists
- **Stream proxy** — TCP + UDP
- **Uptime monitor** (built-in)
- **Web-SSH terminal** (à la WeTTY — batch 73)
- **Plugin system** — extend functionality
- **Utilities** — CIDR converter, mDNS scanner, WOL, debug forward proxy, IP scanner, port scanner
- **Forward-auth** — Authelia, Authentik
- **OAuth 2.0 + reCAPTCHA**
- **SMTP** for password reset
- **Dark mode**

- Upstream repo: <https://github.com/tobychui/zoraxy>
- Releases (binaries): <https://github.com/tobychui/zoraxy/releases/latest>
- Getting Started wiki: <https://github.com/tobychui/zoraxy/wiki/Getting-Started>
- Plugin system: check repo wiki

## Architecture in one minute

- **Go 1.23+ single binary** — serves admin UI + reverse proxy on same or different ports
- **Embedded datastore** — config + stats (no external DB)
- **Runs in foreground** or via systemd
- **Listens on port 80/443** for proxied traffic; admin UI on separate port
- **Resource**: small — 50-150 MB RAM; handles thousands of concurrent connections

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Any Linux VM / NAS | **Binary + systemd**                                               | **Upstream-flagship** — download + run                                             |
| Windows            | `.exe` download                                                            | First-party supported                                                                      |
| Raspberry Pi       | arm64 binary                                                                          | Popular                                                                                                |
| Docker             | Community images exist                                                                                | Not first-party; check releases                                                                                             |
| Kubernetes         | Possible but not the target                                                                                            | Prefer Traefik/Ingress-Nginx for K8s                                                                                                        |

## Inputs to collect

| Input                | Example                                     | Phase        | Notes                                                                    |
| -------------------- | ------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Admin port           | `:8000` (default)                               | URL          | Separate from proxy 80/443                                                       |
| Admin user           | first-run wizard sets                                | Bootstrap    | Strong password; 2FA if possible                                                                |
| Domains              | your site hostnames                                         | Proxy        | Add hosts to route via UI                                                                        |
| Upstream targets     | `http://backend:port`                                                 | Proxy        | Where to route                                                                                           |
| TLS                  | ACME (Let's Encrypt) / custom certs                                    | TLS          | DNS challenge recommended for wildcard + internal                                                                            |
| ACLs                 | country / CIDR rules                                                               | Security     | Optional but easy geo-blocking                                                                                                |

## Install via binary (Linux)

```sh
# Download
wget https://github.com/tobychui/zoraxy/releases/latest/download/zoraxy_linux_amd64 -O /usr/local/bin/zoraxy
chmod +x /usr/local/bin/zoraxy

# Run (listen admin on :8000; proxy will bind 80/443 from UI config)
sudo /usr/local/bin/zoraxy -port=:8000

# Or systemd unit — adapt from repo wiki
```

Browse `http://<host>:8000/` → first-run wizard → set admin credentials.

## First boot

1. Create admin
2. Add your first proxy rule (hostname → upstream URL)
3. Enable TLS / ACME for that hostname (HTTP-01 if port 80 reachable; else DNS-01)
4. Verify via `curl https://your-domain/` → expected backend response + valid LE cert
5. Enable forward-auth if using Authelia/Authentik — pair with batch 69 Authelia recipe
6. Add uptime monitor for important hosts
7. Configure country/CIDR blocklists if relevant
8. Enable 2FA on admin account
9. Back up config

## Data & config layout

- `./conf/` (next to binary) — config, certs, proxy rules, ACLs, stats
- Single-directory backup

## Backup

```sh
sudo tar czf zoraxy-$(date +%F).tgz conf/
```

Small. Include certs (Let's Encrypt private keys); treat backup as sensitive.

## Upgrade

1. Releases: <https://github.com/tobychui/zoraxy/releases>. Active.
2. Download new binary → replace → restart service.
3. Config migrates in place; ALWAYS back up `conf/` first.
4. Major version bumps: read release notes.

## Gotchas

- **Single-maintainer project** (Toby Chui). Active + popular (5000+ ★). Bus-factor-1 same framing as batches 70-73. Not a deal-breaker; plan.
- **AGPL-3.0**: like WriteFreely above — hosting a modified fork publicly = must publish changes. Fine for self-hosting; restricts closed-commercial forks.
- **Binding port 80/443**: requires root OR Linux capabilities (`setcap cap_net_bind_service=+ep`). Most deployments run Zoraxy as root under systemd — acceptable if the machine is dedicated to proxy duty + locked down.
- **Admin UI port is your admin plane** — don't expose to internet. Use LAN-only, VPN, SSH tunnel, or front with forward-auth MFA.
- **Let's Encrypt rate limits**: 50 certs/week per registered domain (combined with all issuance methods). Adding + deleting proxies = re-issuing. Use staging endpoint for testing + `Certbot.sh` knowledge transfers here.
- **DNS-01 challenge for wildcards**: pick a supported provider (list on go-acme/lego). DNS-01 requires API token; treat that token as secret.
- **Web-SSH terminal built-in**: if you enable it, same threat model as WeTTY (batch 73) — requires TLS + MFA + strict network ACLs. Consider leaving disabled unless needed.
- **WoL utility** (homelab-friendly): magic-packet WoL is UDP broadcast — works on LAN; cross-VLAN needs router help. Same caveat as batch 71 UpSnap.
- **Plugin system**: extends feature set; each plugin is code running inside Zoraxy. Audit before install.
- **Country/CIDR blocks**: useful but accuracy depends on GeoIP data source; VPN users bypass trivially. Defense in depth, not silver bullet.
- **Stream proxy (TCP/UDP)**: handy for non-HTTP services (SSH, databases, game servers). TLS passthrough vs termination = understand which mode you're in.
- **Uptime monitor built-in** saves running a separate tool for small scale. At larger scale use dedicated uptime (Uptime Kuma — batch 44 area, Checkly, etc.).
- **Config is NOT GitOps-friendly** by default: it's config files + DB-ish state, not clean YAML you version. Back up conf/ dir instead.
- **Migration from NPM/Caddy/Traefik**: no automated import — manual recreate of rules. Allocate an afternoon + do it carefully.
- **Windows support**: first-class; unusual for a proxy tool. Good for Windows homelab users.
- **HTTP/3 / QUIC**: check current docs — Go's HTTP/3 support has evolved; Zoraxy tracks.
- **License**: **AGPL-3.0** (verify in LICENSE file).
- **Alternatives worth knowing:**
  - **Nginx Proxy Manager (NPM)** — mature; smaller feature scope; similar UX
  - **Traefik** — K8s-native; config-as-code; Docker-label integration
  - **Caddy** — elegant; single-binary; less UI
  - **Caddy + caddy-docker-proxy** — Caddy with Docker-label autoconfig
  - **HAProxy** — hardcore; best-in-class perf
  - **Pangolin** — newer Zoraxy-competitor
  - **SWAG (LSIO)** — Nginx + Let's Encrypt + fail2ban bundle
  - **Cloudflare Tunnel** — managed; no port forwarding
  - **Choose Zoraxy if:** homelab + want many utilities bundled + web UI + single binary + TLS + forward-auth easy.
  - **Choose NPM if:** simpler scope + similar UX + more community examples.
  - **Choose Traefik if:** Docker-Compose label-based config or K8s.
  - **Choose Caddy if:** cleanest config + elegant TLS out of the box.

## Links

- Repo: <https://github.com/tobychui/zoraxy>
- Releases: <https://github.com/tobychui/zoraxy/releases/latest>
- Getting Started: <https://github.com/tobychui/zoraxy/wiki/Getting-Started>
- Tutorial (community): <https://geekscircuit.com/installing-zoraxy-reverse-proxy-your-gateway-to-efficient-web-routing/>
- go-acme/lego DNS providers: <https://go-acme.github.io/lego/dns/>
- Nginx Proxy Manager (alt): <https://nginxproxymanager.com>
- Traefik: <https://traefik.io>
- Caddy: <https://caddyserver.com>
- SWAG: <https://docs.linuxserver.io/general/swag/>
- Authelia (batch 69 forward-auth pair): <https://www.authelia.com>
- WeTTY (batch 73, web-SSH alt): <https://github.com/butlerx/wetty>
