---
name: Technitium DNS Server
description: "Self-hosted authoritative and recursive DNS server with ad/malware blocking, DNS-over-HTTPS/TLS/QUIC, web admin UI, and DNSSEC support. C#/.NET. GPL-3.0."
---

# Technitium DNS Server

Technitium DNS Server is a self-hosted, open-source DNS server that functions as both an authoritative nameserver and a recursive resolver. It includes network-wide ad and malware blocking (like Pi-hole), encrypted DNS protocols (DoH, DoT, DoQ), a built-in web admin interface, DNSSEC validation, and clustering support — all configurable through a browser-based UI with zero command-line setup required.

Use cases: (a) home network privacy: block ads/malware at DNS level for all devices (b) local DNS authoritative server for split-horizon DNS (c) encrypted DNS resolver for network privacy (DoH/DoT/DoQ) (d) pihole alternative with more DNS features (e) authoritative DNS for internal domains (f) self-hosted DNS infrastructure for organizations.

Features:

- **Authoritative DNS** — host your own DNS zones; primary, secondary, stub, conditional forwarder zones
- **Recursive resolver** — full recursive resolution; configurable forwarders
- **Ad/malware blocking** — block list URLs (hosts files, domain lists); supports REGEX blocking
- **DoH, DoT, DoQ** — serve and forward DNS over HTTPS, DNS over TLS, DNS over QUIC
- **DNSSEC** — validation for RSA, ECDSA, EdDSA; NSEC and NSEC3; DANE TLSA
- **Web admin UI** — full browser-based management; no CLI required
- **Clustering** — manage multiple instances from one admin console
- **DNS Apps** — plugin system for custom logic (geo-based responses, split horizon, etc.)
- **Query logging** — detailed query logs and statistics
- **QNAME minimization, CNAME cloaking, DNS rebinding protection**
- **CNAME flattening** — ANAME records for CNAME at zone apex
- **High performance** — async IO; >100,000 req/sec on commodity hardware
- **Platforms** — Windows, Linux, macOS, Raspberry Pi; Docker

- Upstream repo: https://github.com/TechnitiumSoftware/DnsServer
- Homepage: https://technitium.com/dns/
- Docs: https://github.com/TechnitiumSoftware/DnsServer/blob/master/MANUAL.md
- Docker Hub: https://hub.docker.com/r/technitium/dns-server

## Architecture

- **.NET** runtime (cross-platform)
- **Single binary / Docker image** — no external database; state stored on disk
- **Web UI** runs on configurable HTTP/HTTPS port (default: 5380)
- **DNS** listens on port 53 (UDP/TCP), 853 (DoT), 443/5380 (DoH)
- **No external dependencies** — self-contained; SQLite for query logging

## Compatible install methods

| Infra       | Runtime                        | Notes                                             |
|-------------|--------------------------------|---------------------------------------------------|
| Docker      | `technitium/dns-server`        | Recommended; single container                     |
| Linux       | Shell install script           | Installs as systemd service; .NET included        |
| Windows     | Installer                      | MSI/exe from technitium.com                       |
| Raspberry Pi| Docker or Linux script         | ARM64 supported; Pi 4 handles household traffic easily |
| macOS       | .NET binary                    | Works for development; Docker preferred           |

## Inputs to collect

| Input           | Example                     | Phase    | Notes                                                      |
|-----------------|-----------------------------|----------|------------------------------------------------------------|
| Admin password  | strong password             | Install  | Set on first-run web UI                                    |
| DNS forwarders  | `1.1.1.1`, `8.8.8.8`       | Config   | Upstream resolvers; or use recursive resolution            |
| Block lists     | URL to hosts/domain file    | Blocking | Multiple lists supported; auto-updated                     |
| Domain          | `dns.example.com`           | UI       | Optional; for accessing admin UI via domain                |

## Quick start (Docker)

```sh
docker run -d \
  --name technitium-dns \
  -p 53:53/udp \
  -p 53:53/tcp \
  -p 5380:5380 \
  -v technitium-data:/etc/dns \
  --restart unless-stopped \
  technitium/dns-server:latest
```

Admin UI: `http://localhost:5380` — first visit creates admin password.

## Docker Compose

```yaml
services:
  dns:
    image: technitium/dns-server:latest
    hostname: dns-server
    ports:
      - "53:53/udp"
      - "53:53/tcp"
      - "853:853/tcp"    # DoT
      - "5380:5380/tcp"  # Admin UI
    environment:
      - DNS_SERVER_DOMAIN=dns.example.com
      - DNS_SERVER_ADMIN_PASSWORD=your-strong-password
    volumes:
      - dns-data:/etc/dns
    restart: unless-stopped

volumes:
  dns-data:
```

## First configuration

1. Open `http://localhost:5380`
2. Log in with admin password
3. **Dashboard** → check DNS is responding
4. **Settings → Forwarders** → add upstream resolvers (Cloudflare DoH, Google, etc.) for recursive queries
5. **Block Lists** → add block list URLs:
   - `https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts` (ads + malware)
   - `https://adaway.org/hosts.txt`
6. **Settings → DNS-over-HTTPS** → enable if you want to serve DoH to clients
7. Point your router/devices to the Technitium server IP as DNS

## Authoritative zone example

```
Zone: example.local
Type: Primary

Records:
  homeserver   A      192.168.1.100
  nas          A      192.168.1.200
  *.home       CNAME  homeserver.example.local.
```

Set your router's DNS to Technitium → all devices resolve `homeserver.example.local` → `192.168.1.100` automatically.

## Data & config layout

- **`/etc/dns/`** — all config and data (mount as Docker volume)
  - `dns.config` — main config file
  - `zones/` — zone files
  - `logs/` — query logs

## Upgrade (Docker)

```sh
docker pull technitium/dns-server:latest
docker compose up -d
```

Config and zones persist in the volume.

## Gotchas

- **Port 53 conflict** — on many Linux systems, `systemd-resolved` listens on port 53 (localhost). Disable it before running Technitium on port 53:
  ```sh
  sudo systemctl stop systemd-resolved
  sudo systemctl disable systemd-resolved
  ```
  Or configure `systemd-resolved` to use Technitium as its upstream.
- **Pi-hole vs Technitium** — Technitium does more (authoritative zones, DoH/DoT serving, clustering, DNSSEC) but Pi-hole has a longer track record and more polished blocking UI. Both block ads effectively; choose Technitium if you need the extra DNS features, Pi-hole if you want simplicity.
- **Block list update schedule** — block lists are downloaded at startup and on a configurable schedule. Very large combined lists (millions of domains) can cause brief memory spikes. Stick to 1-3 quality lists rather than dozens.
- **Forwarder vs recursive** — "recursive" mode resolves queries from the root DNS servers (authoritative; no upstream dependency; slower for first query). "Forwarder" mode passes queries to upstream resolvers (Cloudflare, Google, etc.; faster; privacy depends on forwarder). Most home setups use forwarder to a privacy-respecting DoH/DoT resolver.
- **DNSSEC + blocking** — if clients use DNSSEC validation and you block a domain, ensure your block response (NXDOMAIN or custom IP) doesn't cause DNSSEC failures. Configure `blocking type` in Settings accordingly.
- **Alternatives:** Pi-hole (ad blocking focused, well-known), AdGuard Home (Go-based, easier, good UI, similar features), BIND9 (authoritative DNS, no blocking UI), Unbound (recursive resolver, no admin UI), PowerDNS (enterprise authoritative DNS).

## Links

- Repo: https://github.com/TechnitiumSoftware/DnsServer
- Homepage: https://technitium.com/dns/
- Manual / Docs: https://github.com/TechnitiumSoftware/DnsServer/blob/master/MANUAL.md
- Docker Hub: https://hub.docker.com/r/technitium/dns-server
- Releases: https://github.com/TechnitiumSoftware/DnsServer/releases
- Blog: https://blog.technitium.com/
