---
name: VueTorrent
description: "Modern, sleek, responsive, mobile-friendly Vue.js WebUI for qBittorrent 4.4+. Replaces the default qBittorrent WebUI. Static-site drop-in. Open-source (GPL-3.0)."
---

# VueTorrent

VueTorrent is **a beautiful modern WebUI for qBittorrent** — Vue 3 + Vuetify 3, PWA-installable, desktop + mobile responsive, dark/light themes, keyboard shortcuts, configurable dashboard, better UX than the stock qBittorrent WebUI. It talks to qBittorrent via the normal Web API, so it's a drop-in replacement.

> **This is NOT a torrent client.** It's a frontend. You still need **qBittorrent 4.4+** running (WebUI API enabled) — VueTorrent sits on top of it.

Features (things the default qBittorrent WebUI lacks):

- **Mobile-friendly** — installable as a PWA
- **Configurable dashboard** — pick which torrent properties to show
- **Keyboard shortcuts** (with Mac keymap)
- **Beautiful UI** — Material Design 3, animated, responsive
- **Dark/light themes**
- **Multi-select modes** — Ctrl-click, Shift-click ranges
- **Search integration** — search for torrents from within UI
- **Session stats + transfer graphs**
- **Rename, file selection, category/tag management** — all stock qBittorrent features

- Upstream repo: <https://github.com/VueTorrent/VueTorrent>
- Installation wiki: <https://github.com/VueTorrent/VueTorrent/wiki/Installation>
- Demo (mocked): <https://vuetorrent.github.io/demo>
- Discord: <https://discord.gg/KDQP7fR467>

## Architecture in one minute

- **Pure static Vue 3 build** — HTML/CSS/JS bundle; no backend of its own
- **Uses qBittorrent's Web API** — all torrent operations via HTTP to qBittorrent
- **Two install modes:**
  1. **qBittorrent "Use alternative WebUI" option** — qBittorrent serves VueTorrent on its own WebUI port (simplest)
  2. **Separate static host** — nginx/Caddy serves VueTorrent; users log in to qBittorrent via its URL through VueTorrent's config
- **PWA** — installable on phone/desktop for app-like experience

## Compatible install methods

| Infra        | Runtime                                              | Notes                                                                  |
| ------------ | ---------------------------------------------------- | ---------------------------------------------------------------------- |
| Any          | **Drop-in qBittorrent "Alternative WebUI"**              | **Simplest** — put VueTorrent files next to qBittorrent                    |
| Docker       | **LinuxServer.io qBittorrent image** has `WEBUI_PORT=8080` + `DOCKER_MODS=linuxserver/mods:qbittorrent-vuetorrent`     | **One env var**                                                                    |
| Static site  | Host VueTorrent on nginx/Caddy; point at qBittorrent                        | For separation                                                                                 |
| Native qBittorrent | Download release zip, point qBittorrent's alt-WebUI path                    | Works on any OS                                                                                         |
| Managed      | — (no SaaS; static files)                                                                            |                                                                                                                      |

## Inputs to collect

| Input                 | Example                              | Phase     | Notes                                                                   |
| --------------------- | ------------------------------------ | --------- | ----------------------------------------------------------------------- |
| qBittorrent           | 4.4+ running with WebUI enabled          | Prereq    | **Mandatory upstream**                                                                |
| WebUI auth            | qBittorrent admin user + password           | Auth      | qBittorrent handles auth; VueTorrent just forwards                                                |
| VueTorrent release    | zip from releases page                           | Install   | Or `linuxserver/mods:qbittorrent-vuetorrent`                                                            |
| qBittorrent setting   | "Use alternative WebUI" → path to VueTorrent dist | Config    | Or Docker env                                                                                                 |

## Install: LinuxServer.io Docker mod (easiest)

```yaml
services:
  qbittorrent:
    image: lscr.io/linuxserver/qbittorrent:latest      # pin in prod
    container_name: qbittorrent
    environment:
      PUID: "1000"
      PGID: "1000"
      TZ: America/Los_Angeles
      WEBUI_PORT: "8080"
      DOCKER_MODS: linuxserver/mods:qbittorrent-vuetorrent
    volumes:
      - ./config:/config
      - /srv/downloads:/downloads
    ports:
      - "8080:8080"                  # WebUI (now serving VueTorrent)
      - "6881:6881"
      - "6881:6881/udp"
    restart: unless-stopped
```

The `DOCKER_MODS` env var auto-downloads VueTorrent + points qBittorrent to it. VueTorrent updates automatically on container restart with the mod.

## Install: manual (Alternative WebUI)

1. Download VueTorrent release zip: <https://github.com/VueTorrent/VueTorrent/releases>
2. Unzip to e.g. `/opt/vuetorrent/`
3. qBittorrent → Tools → Options → Web UI → "Use alternative WebUI" → browse to `/opt/vuetorrent/public` (or wherever `index.html` lives)
4. Restart qBittorrent
5. Browse to qBittorrent's WebUI port — now shows VueTorrent

## First boot

1. Open VueTorrent URL (qBittorrent's WebUI port)
2. Log in with qBittorrent admin creds
3. Settings (VueTorrent has its own settings pane in addition to qBittorrent's):
   - Dashboard → choose columns
   - Appearance → theme + dark mode default
   - Keyboard shortcuts → enable
4. Install as PWA (Chrome: install icon in URL bar; iOS: Share → Add to Home Screen)

## Data & config layout

- No data of its own — static HTML/CSS/JS
- User preferences (dashboard layout, theme) stored in browser LocalStorage
- All torrent state on qBittorrent side

## Backup

Nothing to back up on VueTorrent side. Back up qBittorrent's `config/` directory as usual (BT_backup, qBittorrent.conf).

## Upgrade

1. Releases: <https://github.com/VueTorrent/VueTorrent/releases>. Active.
2. LinuxServer.io mod: automatic — container restart pulls latest mod.
3. Manual: download new zip, replace files in `/opt/vuetorrent/`.
4. Clear browser cache if UI looks stale (service worker caching).
5. Check qBittorrent version compat — older qBittorrent (<4.4) missing API endpoints → errors.

## Gotchas

- **qBittorrent 4.4+ required.** Older versions lack API endpoints VueTorrent needs. Don't install on a NAS with qBittorrent 4.1.
- **Host header validation** — in dev or when hosting VueTorrent separately, you may hit "403 Host header validation" from qBittorrent. Either:
  - qBittorrent → Options → WebUI → Uncheck "Enable host header validation" (less secure), OR
  - Add your VueTorrent hostname to the whitelist
- **Service worker caching** — PWA caches aggressively; after upgrading VueTorrent, clear site data if UI shows old version.
- **CORS** — if hosting separately and pointing at a different-origin qBittorrent, you may need qBittorrent CORS whitelist config.
- **Not a torrent client** — frequent question. VueTorrent doesn't download torrents; qBittorrent does.
- **WebUI authentication** — qBittorrent's session cookie handles login; set a strong password in qBittorrent options, not default `admin/adminadmin`.
- **HTTPS**: put a reverse proxy (Caddy/Traefik/Nginx) in front for TLS; qBittorrent can do TLS directly but proxy is cleaner.
- **Mobile**: PWA installs from browser; some gestures work great, some (drag-drop) don't translate.
- **Keyboard shortcuts on Mac** use Cmd instead of Ctrl — documented.
- **Browser support** — modern evergreen; IE11 won't work; older Safari may have quirks.
- **Dark mode** is a first-class theme.
- **Advanced features** (reannounce, copy magnet, trackers editing) all present; some are tucked into right-click menus.
- **Multi-language** — i18n supports several languages; check Settings → General → Language.
- **VueTorrent doesn't modify qBittorrent behavior** — if torrent misbehaves, the bug is probably in qBittorrent.
- **Default qBittorrent WebUI still accessible** — some setups keep both available at different paths for admin use.
- **License**: GPL-3.0.
- **Alternatives worth knowing:**
  - **qBittorrent default WebUI** — functional but dated
  - **qbit-manage** — CLI automation around qBittorrent (companion, not alternative UI)
  - **Flood** — frontend for rTorrent/Transmission/qBittorrent; earlier modern UI attempt
  - **Deluge + WebUI** — if you use Deluge instead
  - **Transmission Web** — simple UI for Transmission
  - **qBittorrent-nox** (headless) + VueTorrent = the modern homelab stack
  - **ruTorrent** — old-school classic rtorrent UI
  - **Choose VueTorrent if:** you run qBittorrent and want a modern polished UI + PWA.
  - **Choose Flood if:** you use multiple clients and want one UI.
  - **Choose default WebUI if:** simplicity + no JS-framework concerns.

## Links

- Repo: <https://github.com/VueTorrent/VueTorrent>
- Releases: <https://github.com/VueTorrent/VueTorrent/releases>
- Installation wiki: <https://github.com/VueTorrent/VueTorrent/wiki/Installation>
- Discord: <https://discord.gg/KDQP7fR467>
- Demo (mocked): <https://vuetorrent.github.io/demo>
- LinuxServer.io qBittorrent mod: <https://github.com/linuxserver/docker-mods/tree/qbittorrent-vuetorrent>
- qBittorrent: <https://github.com/qbittorrent/qBittorrent>
- qBittorrent Alternative WebUI docs: <https://github.com/qbittorrent/qBittorrent/wiki/WebUI>
- Flood alternative: <https://github.com/jesec/flood>
