---
name: myip
description: MyIP recipe for open-forge. All-in-one IP toolbox — check IPs, geolocation, DNS leaks, WebRTC, speed test, MTR, availability checks, and more. Docker or Node.js install. Upstream: https://github.com/jason5ng32/MyIP
---

# MyIP

All-in-one IP toolbox. Check your IPs from multiple sources, IP geolocation, DNS leak testing, WebRTC detection, speed tests, MTR tests, website availability checks, WHOIS lookup, and more — all in one self-hosted web app.

10,239 stars · MIT

Upstream: https://github.com/jason5ng32/MyIP
Website: https://ipcheck.ing
Demo: https://ipcheck.ing
Docker Hub: https://hub.docker.com/r/jason5ng32/myip

## What it is

MyIP provides a comprehensive network diagnostics and IP information toolkit:

- **Multi-source IP detection** — Shows local IPs from multiple IPv4 and IPv6 providers simultaneously
- **IP geolocation** — Country, region, ASN, coordinates for any IP address
- **DNS leak test** — Identify DNS endpoints to detect VPN/proxy leaks
- **WebRTC detection** — Reveals IP addresses exposed via WebRTC connections
- **Speed test** — Network speed against edge nodes
- **MTR test** — Multi-hop traceroute to global servers
- **Website availability** — Check if sites (Google, GitHub, ChatGPT, etc.) are reachable
- **Global latency test** — Ping servers in different regions
- **DNS resolver** — Resolve domains from multiple sources to detect contamination
- **Censorship check** — Check if a website is blocked in specific countries
- **WHOIS search** — Domain and IP WHOIS lookups
- **MAC lookup** — Physical address information
- **Browser fingerprinting** — Multiple fingerprint calculation methods
- **Cybersecurity checklist** — 258-item security checklist
- **PWA support** — Installable as desktop/mobile app
- **Dark mode** — Auto-detects system preference

Note: depends_3rdparty=true — some features call external APIs (geolocation providers, speed test nodes).

## Compatible combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Docker | Single container | Simplest deploy, port 18966 |
| Node.js | Node 18+ | npm install + npm run build + npm start |
| VPS | Docker or Node | Both work well |

## Inputs to collect

### Phase 1 — Pre-install
- Public URL / domain for the instance
- Port to expose (default: 18966)
- Reverse proxy setup (Nginx/Traefik for HTTPS)

## Software-layer concerns

### Config paths
- No persistent data directory needed — stateless app
- Environment variables for customization (see upstream README for full list)

### Docker Compose install
  version: '3'
  services:
    myip:
      image: jason5ng32/myip:latest
      container_name: myip
      restart: always
      ports:
        - "18966:18966"

Access at http://<host>:18966

### Node.js install
  git clone https://github.com/jason5ng32/MyIP.git
  cd MyIP
  npm install && npm run build
  npm start

### Reverse proxy (Nginx)
  server {
    listen 443 ssl;
    server_name ipcheck.example.com;
    location / {
      proxy_pass http://localhost:18966;
      proxy_set_header Host $host;
      proxy_set_header X-Real-IP $remote_addr;
    }
  }

## Upgrade procedure

1. Pull latest image: docker pull jason5ng32/myip:latest
2. Restart container: docker compose up -d --force-recreate
3. For Node.js: git pull && npm install && npm run build && npm restart

## Gotchas

- Third-party API dependency — geolocation, speed test, MTR features call external services; some may be rate-limited or unavailable in certain regions
- Port 18966 — non-standard port; remember to update firewall and reverse proxy config
- Self-host vs demo — the demo at ipcheck.ing is public; self-hosted instance gives you control over access logs and custom configuration
- HTTPS recommended — WebRTC and some browser APIs require secure context; set up SSL via reverse proxy
- PWA install requires HTTPS — service worker registration requires a secure origin
- IPv6 — for accurate IPv6 detection, ensure your server and Docker network have IPv6 enabled
- No auth built-in — the app is open to anyone who can reach the port; consider IP allowlist or auth proxy if private use is needed

## Links

- Upstream README: https://github.com/jason5ng32/MyIP/blob/main/README.md
- Docker Hub: https://hub.docker.com/r/jason5ng32/myip
- Live demo: https://ipcheck.ing
