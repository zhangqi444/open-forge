---
name: SWAG (Secure Web Application Gateway)
description: "nginx reverse proxy + Let's Encrypt/ZeroSSL cert automation + fail2ban in one Docker image. By LinuxServer.io. The de-facto homelab reverse-proxy for self-hosters. GPL-3.0 (project) / docker image curated + maintained by LinuxServer.io."
---

# SWAG

SWAG (Secure Web Application Gateway, formerly known as `letsencrypt` — no relation to Let's Encrypt™) is **"the homelab's default reverse-proxy-in-a-box"** — a curated Docker image from **LinuxServer.io** that bundles **nginx + certbot + php-fpm + fail2ban** into one container. Drop it in front of your self-hosted apps, point DNS at it, configure proxy-confs from the generous `proxy-confs` directory of pre-made nginx snippets, get free Let's Encrypt / ZeroSSL certs auto-renewed + intrusion-protection via fail2ban + nginx's proven security. The **#1 reverse-proxy choice** in the LinuxServer.io-using homelab ecosystem (Plex / Jellyfin / *arr / Nextcloud users).

Built + maintained by the **LinuxServer.io** team — institutional-stewardship-grade community project with ~weekly rebuilds + base-image-update discipline + multi-arch (amd64 + arm64) + Jenkins CI + security-updates. **Container image: GPL-3 / per-component licenses**; upstream nginx + certbot + fail2ban each have their own licenses.

Use cases: (a) **homelab reverse proxy** fronting all your self-hosted services (b) **auto-SSL** for every subdomain via wildcard or per-service Let's Encrypt/ZeroSSL (c) **fail2ban-protected public-facing services** (d) **GeoIP blocking** + **Cloudflare IP allowlist** + **basic auth on specific subdomains** via pre-made proxy-confs (e) **HTTP/2 + HTTP/3 (QUIC)** termination (f) **Authelia / Authentik integration** via pre-configured proxy snippets.

Features:

- **nginx** with modern TLS + HTTP/2 + HTTP/3 ready config
- **certbot** for Let's Encrypt + ZeroSSL (DNS-01 + HTTP-01)
- **fail2ban** for intrusion prevention (brute-force protection)
- **PHP 8.x support** (PHP-FPM included — host simple PHP apps too)
- **`proxy-confs/` directory** — curated reverse-proxy snippets for 200+ self-hosted apps (pre-made, just enable)
- **Cloudflare IP allowlist** scripts + snippets
- **GeoIP** blocking support
- **Auto-renewal** cron-driven
- **Authelia / Authentik / Zitadel SSO integration snippets**
- **Multi-arch**: amd64 + arm64
- **s6-overlay** base for proper service supervision
- **LinuxServer.io base image** — weekly OS updates + shared layers across ecosystem

- Upstream repo: <https://github.com/linuxserver/docker-swag>
- Docker Hub: <https://hub.docker.com/r/linuxserver/swag>
- GHCR: <https://ghcr.io/linuxserver/swag>
- Docs: <https://docs.linuxserver.io/general/swag/>
- proxy-confs dir: <https://github.com/linuxserver/reverse-proxy-confs>
- Blog: <https://blog.linuxserver.io>
- Discord: <https://discord.gg/linuxserver> (realtime support)

## Architecture in one minute

- **Base image**: LinuxServer.io custom Alpine/Ubuntu + s6-overlay
- **nginx** + **certbot** + **PHP-FPM** + **fail2ban** + **certbot DNS-01 plugins** (many providers)
- **`/config`** volume — all state + certs + proxy-confs + fail2ban jail configs
- **Resource**: light — 50-150MB RAM idle; scales with traffic + enabled services
- **Ports**: 80 + 443 (+ 443/udp for QUIC if enabled)

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker**         | **`lscr.io/linuxserver/swag:latest`** (multi-arch)              | **De-facto homelab path**                                                          |
| Docker compose     | Upstream provides compose snippets                                        | Standard                                                                                   |
| Kubernetes / Helm  | Works as a container but K8s users typically prefer ingress-nginx / Traefik / cert-manager natively          | Pattern-mismatch for K8s-native deployments                                                                                           |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `example.com` + subdomains                                  | DNS          | DNS A-records → your SWAG host; or wildcard if using DNS-01                                                                         |
| `URL` env            | Your base domain                                            | Config       | Used for cert SAN                                                                                    |
| `SUBDOMAINS`         | `plex,jellyfin,sonarr,...` or `wildcard`                                        | Config       | Comma-separated OR `wildcard` (requires DNS-01)                                                                                    |
| `VALIDATION`         | `http` or `dns`                                                                     | Config       | DNS-01 needed for wildcard + private-network certs                                                                                                      |
| `DNSPLUGIN`          | `cloudflare`, `route53`, `google`, `acmedns`, ... (if VALIDATION=dns)                                           | Config       | Per-provider plugin; see docs                                                                                                                           |
| `EMAIL`              | Let's Encrypt account email                                                                                      | Config       | For expiry notifications                                                                                                                                     |
| `CERTPROVIDER`       | `letsencrypt` (default) or `zerossl`                                                                                                   | Config       | Defaults to LE                                                                                                                                                          |
| Port 80 + 443        | Open on host                                                                                                                         | Network      | 80 required for HTTP-01; both for production                                                                                                                                                                                    |

## Install via Docker

```yaml
services:
  swag:
    image: lscr.io/linuxserver/swag:latest   # **pin version** in prod
    container_name: swag
    cap_add: [NET_ADMIN]
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=UTC
      - URL=example.com
      - SUBDOMAINS=wildcard
      - VALIDATION=dns
      - DNSPLUGIN=cloudflare
      - EMAIL=you@example.com
      - CERTPROVIDER=letsencrypt
    volumes:
      - ./swag-config:/config
    ports:
      - "80:80"
      - "443:443"
      - "443:443/udp"   # QUIC / HTTP/3 if enabled
    restart: unless-stopped
```

Put your DNS provider API token in `/config/dns-conf/cloudflare.ini` (or relevant provider file).

## First boot

1. Start SWAG → watch logs: certs generate on first run
2. Browse `https://example.com` → default "Welcome to SWAG" page
3. Enable a proxy-conf:
   ```sh
   cd swag-config/nginx/proxy-confs/
   cp plex.subdomain.conf.sample plex.subdomain.conf
   # Edit to point `upstream_app` at your actual container name/IP
   ```
4. Restart SWAG (`docker restart swag`) → `https://plex.example.com` routes to your Plex container
5. Enable fail2ban for services that need brute-force protection (in `/config/fail2ban/`)
6. (opt) Set up Authelia / Authentik / Zitadel + enable the `authelia-server.conf` / `authentik-server.conf` snippet
7. Back up `/config` directory

## Data & config layout

- `/config/nginx/site-confs/` — main nginx server configs
- `/config/nginx/proxy-confs/` — per-app reverse-proxy snippets (HUGE library)
- `/config/keys/letsencrypt/` — **PRIVATE KEYS** — treat as secret
- `/config/etc/letsencrypt/` — certbot metadata
- `/config/dns-conf/` — DNS provider API credentials
- `/config/fail2ban/` — jail configs + local overrides
- `/config/log/` — nginx + fail2ban logs

## Backup

```sh
docker compose stop swag
sudo tar czf swag-config-$(date +%F).tgz swag-config/
docker compose start swag
```

The `keys/` directory contains your TLS private keys — treat as a crown-jewel secret. If you rotate keys, let's encrypt re-issue is cheap; but DNS-API-tokens in `dns-conf/` are much more sensitive.

## Upgrade

1. LinuxServer.io rebuilds weekly with base-OS + security updates.
2. `docker pull lscr.io/linuxserver/swag:latest && docker compose up -d swag`
3. Pin to specific release tags if you want stability — LSIO tags by upstream version.
4. **SWAG major versions occasionally change nginx config defaults** — read release notes in the GitHub repo before blindly upgrading.
5. `proxy-confs` updates via `lsiown` periodically (new apps, security fixes).

## Gotchas

- **"SWAG is not a gateway, it's a reverse proxy with nice defaults"** — despite the name, SWAG is primarily a sensibly-configured nginx + certbot bundle. If you want application-layer identity-aware access (ZTNA-style), combine with Authelia / Authentik / Octelium (batch 88). SWAG alone = network-level + path-level rules, not identity-aware.
- **PORT 80 + 443 MUST BE REACHABLE** from the public internet for HTTP-01 cert issuance. If your ISP blocks port 80 (common on residential) = use **DNS-01 validation** with a DNS plugin. DNS-01 also enables **wildcard certs** + **internal-only domains**.
- **DNS PROVIDER API TOKEN = PRIVILEGED SECRET**: the token in `/config/dns-conf/*.ini` can modify your DNS records. **Scope it tightly** if your DNS provider supports fine-grained tokens (e.g., Cloudflare API tokens with zone-edit-only scope on specific zones). A leaked broad API token = attacker can hijack your DNS = takeover + phishing + TLS-cert-for-phishing.
- **CERTIFICATE PRIVATE KEYS in `/config/keys/` = crown-jewel secrets**: if exfiltrated, an attacker can impersonate your domain (with TLS-decryption ability) until you rotate. Full-disk encryption + backup-encryption matter here. Restoring SWAG to a NEW host with the SAME keys = seamless; to a different domain = trivially re-issued.
- **fail2ban requires `NET_ADMIN` capability** — container needs `cap_add: [NET_ADMIN]` to manipulate iptables / nftables. Without it, fail2ban runs but doesn't actually block. **Don't skip `cap_add`** or you silently lose brute-force protection.
- **Cloudflare + SWAG**: if you use Cloudflare as a proxy (orange cloud), traffic to SWAG comes from CF IPs only. **Add the `ssl-params.conf` + Cloudflare real-IP snippet** so nginx + fail2ban see the actual client IP from `CF-Connecting-IP` header. Without it, all bans are against Cloudflare IPs = useless.
- **Rate limits + DDoS**: SWAG alone won't save you from serious DDoS. Front it with Cloudflare / Fastly / cloud WAF for public services seeing attack traffic. For homelab-personal-use, SWAG's nginx rate-limit snippets suffice.
- **QUIC / HTTP/3 is NEW** in recent SWAG versions. Enable via config. UDP port 443 must be forwarded. Browsers negotiate HTTP/3 only after HTTP/2 + Alt-Svc handshake; test with a site like `http3check.net`.
- **proxy-confs library** is a massive ecosystem asset — 200+ pre-made snippets. **Check the sample first before writing your own nginx config.** SWAG's community-curated snippets handle edge cases (WebSocket upgrades for apps like Jellyfin/Synapse, CSP headers, auth integration) that a newcomer won't get right first try.
- **HSTS**: enabled by default in SWAG's site-conf with a long max-age. **Understand HSTS commitment**: once set, browsers won't let users bypass cert errors for that long. Great for security; painful if you screw up certs. LE auto-renew makes this reliable, but know the behavior.
- **OCSP stapling** enabled by default. Good security practice.
- **Basic auth path-protection**: SWAG has snippets for basic-auth-per-path (e.g., expose only `/api` behind basic-auth while leaving `/` public). Good for lightweight access-control. Same weakness as always: basic auth over TLS only; revoke individually is manual.
- **fail2ban jails**: default set covers nginx 4xx patterns, auth-log patterns. **Add jails for apps that log auth failures** (e.g., Jellyfin, Nextcloud) — custom regex matching the app's log format. Community examples in LSIO docs + forums.
- **LinuxServer.io institutional trust**: well-funded community project + ~weekly rebuilds + known team + Open Collective funding + Jenkins CI + broad trust in homelab community. **9th tool in institutional-stewardship family** (same family as ASF for Guacamole 87, NLnet for Unbound 80, Deciso for OPNsense 80, TryGhost, Codeberg e.V., Element).
- **When to choose SWAG vs alternatives**:
  - **SWAG**: best for LSIO-ecosystem homelab users + Docker-compose-based stacks
  - **Traefik**: better for Docker-native dynamic-discovery setups (label-based config)
  - **Caddy**: simpler config for basic proxy needs; native auto-HTTPS
  - **nginx Proxy Manager (NPM)**: GUI-driven; friendlier for beginners
  - **cert-manager + ingress-nginx/Traefik** (Kubernetes): native K8s path; skip SWAG on K8s
- **Migrating away from SWAG** is straightforward: export your site-confs, migrate to your chosen alternative, re-issue certs (LE allows many issuances).
- **Commercial tier**: LinuxServer.io has an Open Collective for donations; no paid SaaS. **Services-around-OSS** tier (donations + in-kind contributions; no paid product).
- **Alternatives worth knowing:**
  - **Caddy** — auto-HTTPS out-of-the-box; simpler config; single binary
  - **Traefik** — Docker-label-driven dynamic config; great for Docker-Swarm/Compose
  - **nginx Proxy Manager (NPM)** — GUI on top of nginx; friendlier for beginners
  - **Pangolin** — modern tunnel-based reverse-proxy gateway
  - **Zoraxy** — Go-based reverse-proxy with dashboard
  - **HAProxy** — battle-tested L4/L7 load balancer
  - **cert-manager + ingress-nginx/Traefik** (Kubernetes native)
  - **Cloudflare Tunnel** — commercial alternative; no self-host-of-proxy needed
  - **Choose SWAG if:** you're LSIO-ecosystem + Docker-compose + want curated nginx + fail2ban + proxy-confs library.
  - **Choose Caddy if:** you want simplest-possible + single-binary + auto-TLS.
  - **Choose Traefik if:** you want Docker-native label-driven dynamic config.
  - **Choose NPM if:** you prefer GUI management over text config.

## Links

- Repo: <https://github.com/linuxserver/docker-swag>
- Docker: <https://hub.docker.com/r/linuxserver/swag>
- Docs: <https://docs.linuxserver.io/general/swag/>
- proxy-confs: <https://github.com/linuxserver/reverse-proxy-confs>
- Authelia integration: <https://www.authelia.com/integration/proxies/swag/>
- Caddy (alt): <https://caddyserver.com>
- Traefik (alt): <https://traefik.io/traefik>
- nginx Proxy Manager (alt): <https://nginxproxymanager.com>
- Pangolin (alt): <https://github.com/fosrl/pangolin>
- Zoraxy (alt): <https://github.com/tobychui/zoraxy>
- Let's Encrypt: <https://letsencrypt.org>
- ZeroSSL: <https://zerossl.com>
- LinuxServer.io: <https://linuxserver.io>
- Open Collective (support LSIO): <https://opencollective.com/linuxserver>
