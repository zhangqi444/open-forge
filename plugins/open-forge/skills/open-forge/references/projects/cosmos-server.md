---
name: Cosmos Server
description: "Secure + privacy-focused self-hosted server OS / dashboard / reverse proxy / auth / VPN — all-in-one alternative to Portainer+Traefik+Authelia+Nginx Proxy Manager. Docker-native. App marketplace, SSO, anti-bot, 2FA. Go + React. Custom license (free self-host, commercial)."
---

# Cosmos Server

Cosmos is **an all-in-one self-hosted server management suite** combining: reverse proxy (like Traefik/Caddy) + authentication layer (like Authelia/Authentik) + app marketplace (like Yunohost/CasaOS) + monitoring dashboard + Docker manager (like Portainer) + VPN/mesh (like WireGuard) into a single binary. Designed for home-lab + small self-host setups that want fewer moving parts.

Target user: someone who runs ~5-30 self-hosted apps + doesn't want to wire together 7 different open-source projects for auth + reverse proxy + monitoring.

Features:

- **Reverse proxy** with auto-HTTPS (Let's Encrypt + custom CAs)
- **Authentication** — built-in accounts + 2FA (TOTP) + hardware keys (WebAuthn)
- **SSO** — forward-auth for downstream apps
- **App marketplace** — one-click install for 200+ apps (Nextcloud, Jellyfin, Immich, etc.) with opinionated Compose templates
- **Docker management** — start/stop/update containers; build Compose UI
- **Anti-bot / anti-DDoS** — rate limiting, geo-blocking, fail2ban-like
- **Constellation (VPN)** — built-in mesh VPN (WireGuard-based) for zero-trust private access
- **Monitoring** — CPU, RAM, disk, network graphs; container health
- **Backups** — config backup + restore
- **Email notifications**
- **Plugin API**
- **Web UI** for everything — no YAML hell required
- **Custom license** — free for self-host (personal + small); commercial tier for enterprise

- Upstream repo: <https://github.com/azukaar/Cosmos-Server>
- Website: <https://cosmos-cloud.io>
- Docs: <https://cosmos-cloud.io/docs>
- Marketplace: <https://cosmos-cloud.io/marketplace>
- Discord: <https://discord.gg/PwMWwsrwHA>
- Docker Hub: <https://hub.docker.com/r/azukaar/cosmos-server>

## Architecture in one minute

- **Go server** (Cosmos) — the core
- **React UI** — web dashboard
- **MongoDB** — config + user DB (bundled)
- **Docker socket** — mounted in; manages containers on host
- **Reverse proxy** baked in — intercepts traffic on ports 80/443
- **Constellation VPN** — separate WireGuard-compatible daemon

## Compatible install methods

| Infra          | Runtime                                                        | Notes                                                                         |
| -------------- | -------------------------------------------------------------- | ----------------------------------------------------------------------------- |
| Single VM      | **Docker (`azukaar/cosmos-server`)**                               | **Upstream-recommended**; needs host network or ports 80/443                      |
| Single VM      | Bare-metal binary                                                           | Works                                                                                       |
| Raspberry Pi   | arm64 Docker                                                                             | Popular for Pi-based homelabs                                                                             |
| VPS            | Any Docker-capable VPS                                                                              | Common                                                                                                                 |
| Kubernetes     | Not the target — defeats the "single-binary-replaces-many-tools" thesis                                                  |                                                                                                                                              |
| Managed        | — (no SaaS; "Cosmos Cloud" domain is marketing)                                                                                  |                                                                                                                                                          |

## Inputs to collect

| Input              | Example                               | Phase      | Notes                                                                    |
| ------------------ | ------------------------------------- | ---------- | ------------------------------------------------------------------------ |
| Host name          | `home.example.com`                        | URL        | Cosmos takes over :80 + :443 for this + subdomains                              |
| DNS wildcards      | `*.home.example.com` → server IP                      | DNS        | For one-click subdomain routing                                                        |
| Admin account      | first-run wizard                                         | Bootstrap  | **Set immediately**                                                                      |
| Email (opt)        | SMTP for notifications + reset                                     | Email      | Nice-to-have                                                                                                  |
| Let's Encrypt email | for ACME                                                             | TLS        | Required                                                                                                                      |
| Docker socket       | `/var/run/docker.sock`                                                            | Runtime    | Cosmos must have access                                                                                                                            |

## Install via Docker

```yaml
services:
  cosmos:
    image: azukaar/cosmos-server:latest               # pin in prod
    container_name: cosmos
    restart: unless-stopped
    network_mode: bridge
    ports:
      - "80:80"
      - "443:443"
      - "4242:4242/udp"                                 # Constellation VPN (if used)
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock       # manages other containers
      - /:/mnt/host:ro                                    # optional, for monitoring (read-only)
      - /var/lib/cosmos:/config
    environment:
      TZ: America/Los_Angeles
    cap_add:
      - NET_ADMIN                                         # for VPN
```

Browse `http://<host>/` → first-run wizard.

## First boot

1. Wizard: set admin user + password
2. Configure HTTPS: hostname + Let's Encrypt email
3. Cosmos obtains cert; redirects you to HTTPS
4. **Marketplace** → pick apps → one-click install (e.g., Nextcloud, Jellyfin, Vaultwarden)
5. Each app gets a subdomain + routed automatically
6. Enable 2FA on your admin
7. (Optional) Set up Constellation VPN → generate client configs for your phone/laptop
8. Explore monitoring dashboard

## Data & config layout

- `/var/lib/cosmos/` or the volume you mount — all Cosmos config + MongoDB data + installed-app metadata
- Installed apps have their own volumes (per marketplace template)
- Let's Encrypt certs inside `/config`

## Backup

```sh
# Stop first for consistent Mongo snapshot
docker compose stop cosmos
sudo tar czf cosmos-$(date +%F).tgz /var/lib/cosmos/
docker compose start cosmos
```

Also back up individual app volumes (Nextcloud data, Jellyfin config, etc.) per their own recipes.

## Upgrade

1. Releases: <https://github.com/azukaar/Cosmos-Server/releases>. Active.
2. Docker: bump tag → restart; migrations auto.
3. **UI has a "check for updates" button** — triggers pull + recreate.
4. Back up config before major version bumps.

## Gotchas

- **Cosmos wants ports 80 + 443.** If you already run nginx/Caddy/Traefik on those ports, conflict. Either replace your existing proxy with Cosmos, or run Cosmos on non-standard ports (loses transparent reverse-proxy UX).
- **Docker socket access** = root on host. Cosmos must have it to manage containers. Treat Cosmos as privileged infrastructure.
- **Marketplace apps are community-curated templates**, not audited software. You still trust the upstream apps; Cosmos just wires them up.
- **Wildcard DNS** is the convention — `*.home.example.com → server IP`. For DNS provider without wildcard support, set specific A records per installed app.
- **Let's Encrypt rate limits**: 50 certs/week per registered domain. Installing 50 marketplace apps → hits limit. Plan accordingly or use wildcard (DNS-01) challenge.
- **Authentication**: Cosmos's built-in auth is forward-auth for downstream apps. Not every app supports forward-auth headers; configure app-side or use native app auth.
- **Constellation VPN** — built-in WireGuard mesh; config QR code for mobile. Competes with Tailscale/Headscale; fewer features but integrated.
- **Mongodb bundled**: separate lifecycle; don't touch unless you know what you're doing.
- **Resource** — Cosmos + MongoDB ~500 MB RAM. Plus each marketplace app adds its own.
- **Monitoring depth**: basic CPU/RAM/disk/net; not Prometheus-level. Use Prometheus + Grafana for serious monitoring.
- **License**: Cosmos uses a **custom source-available license** — free for self-host (personal + small); commercial use above certain thresholds requires a paid license. **Read LICENSE file before deploying for a business.** This is different from typical AGPL/MIT — check the specific terms for your use case.
- **Anti-bot / anti-DDoS**: good first-line defense; not a substitute for Cloudflare / edge protection at serious scale.
- **Backup** via UI — useful; still back up the raw data too.
- **Migration away from Cosmos**: the reverse-proxy config is Cosmos-specific; apps run as standard Docker containers so you can disconnect Cosmos and run apps directly + wire up your own proxy. Not seamless but doable.
- **Compared to Portainer + Traefik + Authelia + Watchtower**: Cosmos integrates all; you lose the modularity + "best of breed" but gain simplicity. Trade-off.
- **Compared to Yunohost / CasaOS / Umbrel / Runtipi**: similar "all-in-one home-server" space. Cosmos is Docker-native (others mix VM/bare-metal/Docker); built-in auth + anti-bot more robust in Cosmos; marketplace smaller than Yunohost.
- **Single point of failure**: Cosmos crashes → all routed apps unreachable. Plan DR.
- **Alternatives worth knowing:**
  - **Yunohost** — mature French project; different philosophy; LDAP + systemd-based (separate recipe likely)
  - **CasaOS** — IceWhale's home server OS; sleek UI (separate recipe likely)
  - **Runtipi** — by the same author as Zerobyte (nicotsx); Node-based; marketplace (separate recipe likely)
  - **Umbrel** — Bitcoin/self-host home server (separate recipe likely)
  - **Portainer + Traefik + Authelia + Watchtower** — modular stack, more control
  - **Coolify** — self-hosted Heroku-like PaaS; app deployment focus (separate recipe likely)
  - **Dokploy** — similar
  - **Nginx Proxy Manager** — just the reverse proxy UI (separate recipe likely)
  - **Cloudflare Tunnel + auth** — cloud-side access gating
  - **Choose Cosmos if:** you want the most integrated all-in-one with auth + anti-bot + VPN + marketplace.
  - **Choose Yunohost/CasaOS if:** you want a Linux-distro-like experience.
  - **Choose Portainer + separate tools if:** you want modular, best-of-breed.
  - **Choose Coolify if:** you want PaaS-like app deployment, not a home server.

## Links

- Repo: <https://github.com/azukaar/Cosmos-Server>
- Website: <https://cosmos-cloud.io>
- Docs: <https://cosmos-cloud.io/docs>
- Installation: <https://cosmos-cloud.io/docs/2-installation/>
- Marketplace: <https://cosmos-cloud.io/marketplace>
- Releases: <https://github.com/azukaar/Cosmos-Server/releases>
- Docker Hub: <https://hub.docker.com/r/azukaar/cosmos-server>
- Discord: <https://discord.gg/PwMWwsrwHA>
- Reddit: <https://www.reddit.com/r/selfhosted/search/?q=cosmos>
- Yunohost (alt): <https://yunohost.org>
- CasaOS (alt): <https://casaos.io>
- Runtipi (alt): <https://runtipi.io>
- Umbrel (alt): <https://umbrel.com>
- Coolify (alt): <https://coolify.io>
- Constellation (bundled VPN): based on WireGuard
