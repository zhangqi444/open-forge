---
name: Organizr
description: "Homelab services organizer + dashboard — unified web page of 'tabs' that iframe your self-hosted apps (Plex, Sonarr, Radarr, etc.). User/guest support, LDAP/Plex/Emby login, iframe management, themes. PHP 7.2+. GPL-3.0."
---

# Organizr

Organizr is **a homelab dashboard / portal** — aggregates all your self-hosted services into one web page with "tabs" that iframe each app. Classic pairing with the *arr ecosystem (Sonarr, Radarr, Prowlarr, Jellyseerr, Overseerr) + Plex/Emby/Jellyfin + Nextcloud + whatever else you run. Users log in to Organizr once, see their curated list of tabs, and seamlessly interact with each app (iframe-embedded) without juggling a dozen URLs/bookmarks.

**Note on project activity**: Organizr was enormously popular in the late-2010s homelab scene but development has **slowed noticeably** in recent years. The v2-develop branch remains the active line. It works well for its core purpose but **expect limited new feature development** — it's in maintenance mode. Modern alternatives (Homepage, Heimdall, Homarr, Dashy) have taken much of the new-user mindshare.

Features:

- **Tabs** per service — iframe or new-window; per-tab permissions
- **Login options** — Plex, Emby, Jellyfin, LDAP, local users, sFTP, 2FA
- **Guest support** — let non-users access chosen tabs
- **Theme system** — many community themes
- **Homepage customization** — logo, colors, layout
- **Nginx `auth_request`** integration — gate other apps behind Organizr login (SSO-ish)
- **Fail2ban integration** — rate-limit brute force
- **API** — programmatic management
- **Integrated dashboard widgets** — system info, service status
- **Multiple login providers**
- **Mobile responsive**
- **Gravatar integration**

- Upstream repo: <https://github.com/causefx/Organizr>
- Website: <https://organizr.app>
- Discord: <https://organizr.app/discord>
- Docs: <https://docs.organizr.app>
- Docker Hub: <https://hub.docker.com/r/organizr/organizr>

## Architecture in one minute

- **PHP 7.2+** (Apache or Nginx + PHP-FPM)
- **SQLite** — stores users, tabs, config
- **Single container** — LSIO-flavor base; serves on :80/:443
- **iframe-based** — most tabs render target apps in iframes (pros: unified UX; cons: apps must allow iframing)
- **Tiny resource footprint** — <100 MB RAM idle

## Compatible install methods

| Infra              | Runtime                                                         | Notes                                                                          |
| ------------------ | --------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Single VM / NAS    | **Docker (`organizr/organizr`)**                                    | **Upstream-recommended**                                                           |
| Single VM          | Native (Apache + PHP + MySQL/SQLite)                                        | Works                                                                                      |
| Raspberry Pi       | Great fit — low resource use                                                                 | Common homelab deployment                                                                                  |
| Synology / QNAP    | Docker package                                                                               | Popular                                                                                                                |
| Kubernetes         | Rare — homelab dashboards don't need K8s                                                                            |                                                                                                                                            |

## Inputs to collect

| Input              | Example                                | Phase       | Notes                                                                    |
| ------------------ | -------------------------------------- | ----------- | ------------------------------------------------------------------------ |
| Domain             | `home.example.com`                         | URL         | TLS reverse proxy                                                                |
| Admin account      | first user on install wizard                     | Bootstrap   | Strong password                                                                                  |
| Tabs               | one per service (Sonarr, Plex, etc.)                    | Setup       | URL + icon + permissions                                                                                          |
| Auth provider      | Plex / Emby / LDAP / local                                       | Auth        | Plex token OAuth is common                                                                                                     |
| X-Frame-Options    | target apps must allow iframing                                          | Integration | Configure Sonarr/Radarr/etc to allow                                                                                                                                      |
| SMTP (opt)         | for password resets                                                              | Email       | Optional                                                                                                                                             |

## Install via Docker

```yaml
services:
  organizr:
    image: organizr/organizr:latest                   # pin in prod
    container_name: organizr
    restart: unless-stopped
    environment:
      PUID: 1000
      PGID: 1000
      TZ: Europe/Berlin
    volumes:
      - ./config:/config
    ports:
      - "8080:80"
```

Browse `http://<host>:8080/` → setup wizard.

## First boot

1. Browse → install wizard → create admin
2. `Settings → Tab Editor → Add Tab` → name, URL (e.g., `http://sonarr:8989`), icon, permissions
3. Repeat for each service
4. `Settings → Auth → Plex/LDAP/etc` — configure login provider if not using local
5. Enable 2FA for admin
6. Customize theme + homepage
7. (Optional) Configure Nginx auth_request to gate other apps behind Organizr login

## Data & config layout

- `/config/` (container) — SQLite DB + config
- `/config/www/` — custom themes + uploads
- All mutable state in `/config/`

## Backup

```sh
# Data (CRITICAL — users + tabs + config)
sudo tar czf organizr-$(date +%F).tgz config/
```

Simple single-directory backup. Restore by unpacking + starting.

## Upgrade

1. Releases: <https://github.com/causefx/Organizr/releases>. Slow pace; check dates.
2. Docker: bump tag (usually `latest` or `v2-develop`). Auto-migrates SQLite.
3. Back up `config/` first.
4. Most updates are minor — major schema changes rare.

## Gotchas

- **Project activity**: as noted, Organizr is in **maintenance mode**. Check last-commit date before adopting for a new homelab in 2026. Modern alternatives: **Homepage** (gethomepage.dev), **Homarr**, **Heimdall**, **Dashy** — all more actively developed.
- **Iframe compatibility**: many modern apps set `X-Frame-Options: SAMEORIGIN` or CSP `frame-ancestors` — **breaks iframe embedding**. Workarounds:
  - Modify target app's config to allow iframing from Organizr's domain
  - Set tab to "new window" instead of iframe
  - Use reverse-proxy rewriting to strip/override X-Frame-Options (Nginx `proxy_hide_header X-Frame-Options`)
- **HTTPS everywhere**: mixed http/https embedding fails. If Organizr is HTTPS, all embedded apps must be HTTPS too.
- **Same-site cookies**: modern browsers block cross-site cookies in iframes → apps appear "not logged in" inside Organizr. Mitigations: same-domain subdomains (e.g., `sonarr.home.example.com` + `home.example.com`) + SameSite=None cookies on target apps.
- **Plex login**: popular auth path. Plex tokens rotated → users re-login.
- **Nginx auth_request**: using Organizr as SSO backing is neat but fragile. Modern homelabs often use **Authelia / Authentik / Keycloak** for proper SSO + Organizr as dashboard-only.
- **PHP 7.2+**: old PHP requirement. Container ships PHP; native install requires managing PHP versions.
- **Themes**: many community themes; some unmaintained. Test before committing.
- **v1 vs v2**: v1 is long-deprecated. Use v2 (`v2-master` / `v2-develop`).
- **Guest mode**: easy to misconfigure and expose private apps. Audit tab permissions carefully.
- **Mobile UX**: responsive but iframe-heavy dashboards can be rough on mobile; per-app native apps often better for phone usage.
- **Backup restore test**: config is in `/config`; restoring in a fresh container is straightforward, but test before relying on it.
- **Security**: Organizr historically had security advisories — **keep updated** + enable 2FA + don't expose admin UI publicly without WAF/VPN.
- **License**: **GPL-3.0**.
- **Alternatives worth knowing (more active in 2026):**
  - **Homepage** (gethomepage.dev) — modern, YAML-config, widget-rich, Kubernetes-aware (separate recipe likely)
  - **Homarr** — modern React-based dashboard with drag-drop (separate recipe)
  - **Heimdall** — classic dashboard, PHP-based, simpler than Organizr (separate recipe)
  - **Dashy** — YAML-configured static dashboard
  - **Flame** — minimalist startpage
  - **Homer** — static YAML dashboard
  - **SUI** — simple start page
  - **Mafl** — customizable startpage
  - **Choose Organizr if:** existing deployment or specifically want iframe-based unified UX + Plex auth + auth_request SSO.
  - **Choose Homepage if:** active development + widgets + Kubernetes-friendly + YAML config.
  - **Choose Homarr if:** best-looking modern UI + drag-drop customization.
  - **Choose Heimdall if:** simpler, minimal, easy.
  - **Choose Dashy if:** YAML-driven, highly customizable.

## Links

- Repo: <https://github.com/causefx/Organizr>
- Website: <https://organizr.app>
- Docs: <https://docs.organizr.app>
- Discord: <https://organizr.app/discord>
- Docker Hub: <https://hub.docker.com/r/organizr/organizr>
- Releases: <https://github.com/causefx/Organizr/releases>
- Homepage (alt, active): <https://gethomepage.dev>
- Homarr (alt): <https://github.com/ajnart/homarr>
- Heimdall (alt): <https://github.com/linuxserver/Heimdall>
- Dashy (alt): <https://dashy.to>
- Flame (alt): <https://github.com/pawelmalak/flame>
