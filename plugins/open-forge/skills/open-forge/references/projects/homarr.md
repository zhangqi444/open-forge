---
name: Homarr
description: "Customizable self-hosted homepage/dashboard with integrations for dozens of self-hosted apps. Drag-and-drop grid UI; widgets for app status, media queues, download stats, system metrics. Node.js / Next.js. Docker-native + Kubernetes Helm support. MIT."
---

# Homarr

Homarr is **"the polished, feature-rich dashboard for your self-hosted homelab"** — the go-to Start Page / App Launcher that lives between you and your 20+ self-hosted tools. Drag-and-drop grid layout, no YAML, integrates with the ENTIRE self-hosted ecosystem: AdGuard Home, Pi-hole, *arr stack (Sonarr / Radarr / Lidarr / Prowlarr / Bazarr / Readarr), qBittorrent / Transmission / Deluge / SABnzbd / NZBGet, Plex / Jellyfin / Emby, Portainer, Proxmox, Unraid, TrueNAS, Docker, Kubernetes, Home Assistant, Nextcloud, Overseerr / Jellyseerr, Tautulli, Uptime Kuma, and dozens more.

Built + maintained by **homarr-labs** (team + community). **MIT-licensed**. Docker-native with official Kubernetes Helm chart for serious homelabbers. Internationalized via Crowdin. Actively developed with frequent releases.

Use cases: (a) **homelab dashboard / homepage** — one place to see everything (b) **family app launcher** — hide service URLs behind tiles (c) **admin / monitoring dashboard** via integrated widgets (d) **Bookmarks + app integrations** in one UI (e) **replace Heimdall / Organizr / Dashy / Homepage** — competing tools in same niche (f) **multi-user dashboard** with per-user boards + RBAC.

Features (from upstream README):

- **Highly customizable** with drag-and-drop grid
- **Seamless integration** with many self-hosted apps (see upstream for full list)
- **No YAML** — easy app management via UI
- **User management** with permissions + groups
- **SSO** via OIDC / LDAP
- **Secure encryption**: BCrypt + AES-256-CBC for stored credentials
- **Realtime widget updates** via WebSockets + tRPC + Redis
- **Search** across integrations + local data
- **Icon picker** with 11K+ icons
- **Cross-platform**: x86, Raspberry Pi, old laptops; Windows, Linux, TrueNAS, Unraid
- **Kubernetes Helm** support
- **Translations** via Crowdin

- Upstream repo: <https://github.com/homarr-labs/homarr>
- Homepage: <https://homarr.dev>
- Docs: <https://homarr.dev/docs>
- Install guide: <https://homarr.dev/docs/category/installation-1/>
- Integrations list: <https://homarr.dev/docs/category/integrations>
- Discord: <https://discord.gg/aCsmEV5RgA>
- Translations (Crowdin): <https://crowdin.com/project/homarr_labs>

## Architecture in one minute

- **Next.js / Node.js / TypeScript** — full-stack TS
- **tRPC + WebSockets** — realtime
- **Redis** — realtime + cache
- **SQLite (default) or external DB** — app state
- **Resource**: light-moderate — 200-400MB RAM; scales with number of integrations
- **Port 7575** default (Docker)

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker**         | **`ghcr.io/homarr-labs/homarr:latest`**                         | **Primary self-host path**                                                         |
| Docker compose     | Upstream provides recommended compose                                     | Standard                                                                                   |
| **Kubernetes Helm** | Official Helm chart                                                      | For homelabs on K8s / production                                                                       |
| Unraid / TrueNAS / Synology | Community apps + native store entries                                                            | Homelab-friendly                                                                                                          |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain (opt)         | `home.example.com` (or bare IP for homelab LAN)             | URL          | TLS if exposed                                                                                    |
| DB                   | SQLite (default) or Postgres                                | DB           | SQLite fine for single-user                                                                                    |
| Redis                | Local or external                                                          | Realtime     | Required for WebSocket widgets                                                                                    |
| Admin user + password | At bootstrap                                                                                           | Bootstrap    | Strong password                                                                                                            |
| Encryption key       | Auto-generated or provided                                                                                                 | Secrets      | **IMMUTABLE** — encrypts stored integration creds                                                                                                                                   |
| Integration creds    | API keys for each tool (Sonarr / qBit / Pi-hole / etc.)                                                                                          | Per-integration | Stored encrypted in Homarr DB                                                                                                                                                        |

## Install via Docker

```yaml
services:
  homarr:
    image: ghcr.io/homarr-labs/homarr:latest   # **pin version** in prod
    container_name: homarr
    restart: unless-stopped
    volumes:
      - ./homarr-data:/appdata
      # Optional: Docker socket for container-integration widget
      - /var/run/docker.sock:/var/run/docker.sock:ro
    ports: ["7575:7575"]
    environment:
      - SECRET_ENCRYPTION_KEY=${HOMARR_ENCRYPTION_KEY}   # 64-char hex; generate once
```

## First boot

1. Generate encryption key: `openssl rand -hex 32`
2. Set `SECRET_ENCRYPTION_KEY` in env
3. Start Homarr → browse `http://host:7575`
4. Create admin user
5. Create your first **Board** (dashboard layout)
6. Add **Apps** (tiles linking to your self-hosted services)
7. Add **Integrations** — enter API keys / creds for Sonarr / Radarr / qBit / Pi-hole / etc.
8. Add **Widgets** — status, stats, queues, metrics
9. Configure user groups + RBAC if multi-user
10. Optional: SSO via OIDC
11. Back up `/appdata` (includes SQLite DB + encrypted creds)

## Data & config layout

- `/appdata` (Docker volume) — SQLite DB + user data
- Encryption key in env — `SECRET_ENCRYPTION_KEY`
- Uploaded logos / custom icons
- Per-user board configs

## Backup

```sh
docker compose stop homarr
sudo tar czf homarr-$(date +%F).tgz homarr-data/
docker compose start homarr
# DON'T forget to back up SECRET_ENCRYPTION_KEY separately (in password manager)
```

## Upgrade

1. Releases: <https://github.com/homarr-labs/homarr/releases>. Frequent.
2. Docker pull + restart; DB migrations auto-run.
3. **Back up appdata + encryption key BEFORE upgrades** — major versions can have breaking changes pre-v1 stability.
4. Check release notes.

## Gotchas

- **`SECRET_ENCRYPTION_KEY` IMMUTABILITY** — encrypts your stored integration creds (API keys for Sonarr / qBit / Pi-hole / etc.). If you lose the key, you can't decrypt those stored creds. **Store it alongside your DB backup — both are needed to restore.** **15th tool in immutability-of-secrets family.**
- **HUB-OF-CREDENTIALS crown-jewel** — Homarr holds **every API key** for **every tool** in your homelab:
  - Sonarr / Radarr / Lidarr / Readarr API keys
  - qBittorrent / Transmission / Deluge / SABnzbd / NZBGet passwords / API keys
  - Plex / Jellyfin / Emby tokens
  - Pi-hole / AdGuard Home API keys
  - Proxmox / Portainer / Docker-socket credentials
  - Home Assistant tokens
  - Nextcloud passwords
  - **19th tool in hub-of-credentials family, Tier 2 (crown-jewel proper)**, approaching Tier 1 depending on scope.
  - **Defense**:
    - Strong encryption key + backed up separately
    - Don't expose Homarr to the internet without strong auth + TLS (VPN / Tailscale / reverse-proxy-with-SSO)
    - Use **scoped / read-only API keys** where each integrated tool supports them (same discipline as Rotki batch 87 crypto-API-keys)
    - Regular audit of what integrations are configured
- **DOCKER SOCKET = ROOT-EQUIVALENT** (same warning as pad-ws / xyops / batch 85+ previous):
  - If you mount `/var/run/docker.sock` to Homarr, Homarr has root-equivalent privilege on the host via Docker API
  - **Read-only mount (`:ro`)** helps but is NOT sufficient (a read-only docker-sock can still EXEC into containers)
  - **Alternatives**: Docker Socket Proxy (`tecnativa/docker-socket-proxy`) to scope Homarr's Docker API access to only-what-it-needs
  - **Threat model**: if Homarr is compromised via XSS or auth bypass, attacker gets Docker-root via the socket
- **Exposing Homarr to internet** = exposing ALL your integrations. If someone gets into Homarr, they see your entire homelab topology + can leverage stored API keys. **Strongly recommend NOT exposing Homarr publicly.** Access via VPN / Tailscale / reverse-proxy-with-SSO.
- **SSO via OIDC / LDAP** is well-supported — if you have an existing identity provider (Authelia / Authentik / Zitadel / Keycloak), use it.
- **Widget performance**: each widget polls its target integration. **20 widgets × 5s refresh = lots of requests**. Default polling intervals are usually sane; tune if your targets complain (rate limits) or your Homarr dashboard becomes sluggish.
- **Integration fragility**: when a target tool upgrades its API, Homarr's integration can break. **Same provider-API-churn-reality as Bazarr (batch 86), pyLoad (88).** Active homarr-labs team mitigates via frequent releases. Stay reasonably current.
- **Realtime requires Redis** in separated-services deployment or embedded. Official Docker image handles this; custom deployments need Redis configured.
- **MIT license for a dashboard tool** = permissive + friendly. **6th tool in permissive-license-ecosystem-asset family** (following Rustpad 85 / IronCalc 86 / yarr 87 / Guacamole 87 / Octelium dual-license 88). No AGPL-style strings for embedding / customization.
- **Multi-user + board-sharing**: Homarr supports per-user boards + per-group RBAC. Useful for families: adults see all integrations, kids see only media launcher tiles.
- **Kubernetes Helm production path**: mature + supported. Good for homelabbers running K8s cluster + wanting Homarr as a first-class workload.
- **v1.x post-rewrite**: Homarr v1 was a major rewrite from the v0.x Python-based original. v1+ is Node/Next.js. If you see old blog posts referencing v0.x features, verify against current docs.
- **Competitive landscape for homelab dashboards**:
  - **Homepage** (getHomepage; Docker-native; YAML-config; growing fast) — Homarr's main competitor
  - **Heimdall** — older, simpler, stable
  - **Organizr** — long-running, *arr-stack-friendly
  - **Dashy** — Vue-based, feature-rich
  - **Flame** — lighter, simpler
  - **Dashdot** — system-metrics-specialized
  - **Choose Homarr if:** you want modern + drag-drop + many integrations + MIT + active + K8s-ready.
  - **Choose Homepage (getHomepage) if:** you prefer YAML-config + file-based + minimal UI + equally-active alternative.
  - **Choose Dashy if:** you like Vue + highly-customizable + established.
- **Project health**: active team + frequent releases + Discord community + Crowdin translations + MIT + K8s-native. Strong signals.
- **Alternatives worth knowing:**
  - **Homepage** (gethomepage.dev) — direct competitor, YAML-config
  - **Heimdall** — simpler, older, stable
  - **Organizr** — legacy *arr-stack dashboard
  - **Dashy** — Vue, customizable
  - **Flame** — minimalist
  - **Glance** — newer Go-based; clean design

## Links

- Repo: <https://github.com/homarr-labs/homarr>
- Homepage: <https://homarr.dev>
- Docs: <https://homarr.dev/docs>
- Install: <https://homarr.dev/docs/category/installation-1/>
- Integrations: <https://homarr.dev/docs/category/integrations>
- Discord: <https://discord.gg/aCsmEV5RgA>
- Crowdin: <https://crowdin.com/project/homarr_labs>
- Homepage (alt): <https://gethomepage.dev>
- Heimdall (alt): <https://github.com/linuxserver/Heimdall>
- Dashy (alt): <https://dashy.to>
- Flame (alt): <https://github.com/pawelmalak/flame>
- Glance (alt): <https://github.com/glanceapp/glance>
- Docker Socket Proxy (hardening): <https://github.com/Tecnativa/docker-socket-proxy>
