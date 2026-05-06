---
name: swag
description: SWAG (Secure Web Application Gateway) recipe for open-forge. LinuxServer.io Docker image bundling NGINX reverse proxy, automatic Let's Encrypt/ZeroSSL TLS, and fail2ban intrusion prevention in one container. Source: https://github.com/linuxserver/docker-swag. Docs: https://docs.linuxserver.io/general/swag/.
---

# SWAG — Secure Web Application Gateway

LinuxServer.io Docker image that bundles NGINX (reverse proxy + webserver), automatic TLS certificate provisioning via Let's Encrypt or ZeroSSL (using certbot), and fail2ban intrusion prevention — all in one container. Replaces the need to manually configure NGINX + certbot + fail2ban separately. Upstream: <https://github.com/linuxserver/docker-swag>. Docs: <https://docs.linuxserver.io/general/swag/>.

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| VPS / bare metal | Docker Compose | Primary use case; one container handles TLS + reverse proxy |
| Home server | Docker Compose | Popular for self-hosted service stacks (e.g. alongside Sonarr, Radarr, etc.) |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| domain | "Root domain for TLS certificate?" | e.g. example.com — certbot will issue cert for this domain |
| validation | "HTTP validation or DNS validation?" | HTTP=simple (port 80 must be reachable); DNS=needed for wildcards/internal servers |
| dns | "DNS provider (if DNS validation)?" | cloudflare, route53, etc.; installs matching certbot-dns-* plugin |
| subdomains | "Subdomains to include in cert?" | e.g. www,app,media — comma-separated |
| email | "Email for Let's Encrypt expiry notices?" | Optional but recommended |
| uid | "Host PUID/PGID?" | Map to your user to avoid permission issues on volume mounts |

## Software-layer concerns

- Config dir: /config (mounted volume) — contains NGINX config, TLS certs, fail2ban rules
- Ports: 443 (HTTPS, required), 80 (HTTP, required for HTTP validation and redirect)
- Cap: NET_ADMIN required for fail2ban (iptables manipulation)
- NGINX site configs: /config/nginx/site-confs/ — drop .conf files here for proxy configurations
- Predefined proxy configs: /config/nginx/proxy-confs/ — upstream ships ready-made configs for popular apps (Radarr, Sonarr, Nextcloud, etc.)
- TLS certs: stored in /config/etc/letsencrypt/; auto-renewed by built-in cron
- fail2ban: /config/fail2ban/ — pre-configured filters for NGINX, SSH, and common web apps

### Docker Compose

```yaml
services:
  swag:
    image: lscr.io/linuxserver/swag:latest
    container_name: swag
    cap_add:
      - NET_ADMIN
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Etc/UTC
      - URL=example.com
      - VALIDATION=http
      - SUBDOMAINS=www         # optional
      - EMAIL=you@example.com  # optional but recommended
      - STAGING=false          # set true for testing to avoid LE rate limits
    volumes:
      - ./swag-config:/config
    ports:
      - 443:443
      - 80:80
    restart: unless-stopped
```

### DNS validation (for wildcards or internal servers)

```yaml
environment:
  - URL=example.com
  - VALIDATION=dns
  - DNSPLUGIN=cloudflare
  - SUBDOMAINS=wildcard
```

Place your DNS plugin credentials in `/config/dns-conf/<provider>.ini` after first run.

### Adding a reverse proxy config

SWAG ships ready-made proxy configs for 100+ popular apps. To use one:

```bash
# Copy a sample config
cp /config/nginx/proxy-confs/nextcloud.subdomain.conf.sample \
   /config/nginx/site-confs/nextcloud.conf

# Edit to set upstream IP/port
# Then reload NGINX
docker exec swag nginx -s reload
```

For a custom service:

```nginx
# /config/nginx/site-confs/myapp.conf
server {
    listen 443 ssl;
    server_name myapp.example.com;
    include /config/nginx/ssl.conf;

    location / {
        proxy_pass http://192.168.1.100:8080;
        include /config/nginx/proxy.conf;
    }
}
```

## Upgrade procedure

1. `docker compose pull && docker compose up -d`
2. Config in /config volume is preserved; NGINX configs survive upgrades
3. Check release notes for breaking NGINX config changes: https://github.com/linuxserver/docker-swag/releases

## Gotchas

- **Port 80 and 443 must be externally reachable** for HTTP validation and HTTPS traffic. If behind a NAT, set up port forwarding. For DNS validation, port 80 is optional but 443 is still needed.
- **STAGING=true for testing**: Let's Encrypt has rate limits (5 cert failures per domain per hour). Set STAGING=true during initial setup to test without burning rate limit quota. Switch to false once working.
- **NET_ADMIN cap required**: fail2ban needs iptables access. Without cap_add: NET_ADMIN, fail2ban won't be able to ban IPs (but NGINX still works).
- **PUID/PGID**: Set to your host user's UID/GID to avoid volume permission mismatches. Run `id` on the host to find your UID/GID.
- **Wildcard certs require DNS validation**: HTTP validation cannot issue wildcards (*.example.com). Use DNS plugin with VALIDATION=dns.
- **Proxy config reload**: After editing site-confs, reload NGINX with `docker exec swag nginx -s reload` (no full restart needed).
- **fail2ban and Docker networks**: fail2ban bans work at the iptables level. Docker's NAT may obscure real client IPs; configure `real_ip` in NGINX to log actual IPs for fail2ban to use.

## Links

- Upstream repo: https://github.com/linuxserver/docker-swag
- Docs: https://docs.linuxserver.io/general/swag/
- Docker Hub: https://hub.docker.com/r/linuxserver/swag
- LSIO image registry: lscr.io/linuxserver/swag
- Proxy config samples: https://github.com/linuxserver/reverse-proxy-confs
- Release notes: https://github.com/linuxserver/docker-swag/releases
