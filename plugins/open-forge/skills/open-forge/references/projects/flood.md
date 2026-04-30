---
name: Flood
description: "Modern web UI for torrent clients (rTorrent/qBittorrent/Transmission/Deluge). Node.js server + React UI. Crowdin-localized. GPL-3.0. jesec maintainer; Flood-UI org; active."
---

# Flood

Flood is **"ruTorrent / Transmission-Web-UI — but modern + unified + multi-client"** — a Node.js monitoring service that talks to various torrent clients + serves a polished web UI for administration. Supports rTorrent + qBittorrent v4.1+ + Transmission + Deluge v2+ (experimental). Multi-language via Crowdin. **Flood-UI organization** hosts related projects.

Built + maintained by **Jesse Chen (jesec)** + Flood-UI org + community. License: **GPL-3.0**. Active; GitHub Actions CI + tests (vitest) for multiple clients; Crowdin localization; Discord; Docker images.

Use cases: (a) **unified UI for multi-client torrent setup** — rTorrent + qBittorrent + Transmission in one UI (b) **rTorrent web UI replacement** — replace ruTorrent with modern UI (c) **remote torrent management** — seedbox / home-server / VPS (d) **mobile-friendly torrent admin** — responsive UI (e) **team/shared seedbox** — authenticated web access (f) **RSS-feed autodownload** — torrent clients' RSS via Flood (g) **arr-stack integration** — Sonarr/Radarr talk to torrent client; you observe via Flood (h) **API-integration** — Node.js service with documented API.

Features (per README):

- **Multi-client support**: rTorrent (tested), qBittorrent 4.1+ (tested), Transmission (tested), Deluge 2+ (experimental)
- **Modern React UI**
- **Node.js server**
- **Crowdin-localized**
- **Docker + bare-metal install**
- **Multiple authentication modes**
- **API documented inline**

- Upstream repo: <https://github.com/jesec/flood>
- Homepage: <https://flood.js.org>
- Flood-UI org: <https://github.com/Flood-UI>
- Community docs: <https://flood-api.netlify.app>
- Discord: <https://discord.gg/Z7yR5Uf>

## Architecture in one minute

- **Node.js** server
- **React** frontend
- **Resource**: low — 100-200MB RAM
- **Port 3000** default
- **Connects to torrent client's API**

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker**         | **`jesec/flood`** images                                        | **Primary**                                                                        |
| **npm / bare**     | Node.js install                                                                            | Alt                                                                                   |
| Source             | Clone + build                                                                                                             | Dev                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `flood.example.com`                                         | URL          | TLS MANDATORY (creds + torrents)                                                                                    |
| Torrent client       | rTorrent / qBittorrent / Transmission / Deluge              | Client       |                                                                                    |
| Client RPC endpoint  | Per-client                                                  | Network      | rTorrent socket / qBT Web / Transmission-RPC / Deluge daemon                                                                                    |
| Client creds         | Per-client                                                  | Auth         |                                                                                    |
| Flood admin creds    | First-boot                                                  | Auth         | Strong                                                                                    |
| Downloads dir        | Shared with torrent-client                                  | Storage      |                                                                                    |
| VPN (STRONGLY RECOMMENDED) | Airvpn/Mullvad/ProtonVPN                                                                                    | Privacy/Legal | Torrent client should be routed via VPN                                                                                    |

## Install via Docker

```yaml
services:
  flood:
    image: jesec/flood:latest        # **pin version**
    command:
      - "--host=0.0.0.0"
      - "--port=3000"
      - "--allowedpath=/data/downloads"
    ports: ["3000:3000"]
    volumes:
      - ./flood-config:/config
      - /path/to/downloads:/data/downloads
    restart: unless-stopped
```

## First boot

1. Start Flood (with torrent-client running)
2. Browse `:3000`
3. Create first user → configure torrent-client-RPC credentials
4. Verify Flood sees torrents from client
5. Test adding new torrent
6. Configure localization
7. Put behind TLS reverse proxy
8. **ROUTE TORRENT CLIENT VIA VPN** (see gotcha)

## Data & config layout

- `/config/` — Flood's user data + sessions
- Torrent client has its own data dir
- Downloads dir shared with torrent client

## Backup

```sh
sudo tar czf flood-$(date +%F).tgz flood-config/
# Torrent client data is separate; back up that independently
```

## Upgrade

1. Releases: <https://github.com/jesec/flood/releases>. Active.
2. Docker pull + restart
3. Check torrent-client compatibility (e.g., qBT major versions)

## Gotchas

- **TORRENTING = LEGAL/TOS-RISK CROWN-JEWEL**:
  - Torrenting copyrighted content = copyright infringement
  - DMCA takedown → ISP notice → potential lawsuit / ISP disconnect
  - **Recipe convention: "torrent-legal-risk" callout**
  - **Copyright-content-hosting-risk META-FAMILY EXTENDED**: now 4 tools (Grimmory 105 + Wizarr 105 + ytdl-sub 105 + **Flood 106**)
  - **META-FAMILY: 4 tools** — solidifying
- **VPN-REQUIREMENT FOR PRIVACY**:
  - Torrent client exposes your IP to swarm = public
  - Without VPN: every swarm peer sees your real IP
  - **Recipe convention: "torrent-VPN-routing-mandatory" callout**
  - **NEW recipe convention** (Flood 1st formally)
- **TORRENT-CLIENT-RPC CREDS IN FLOOD**:
  - Flood stores qBT/rTorrent/Transmission admin creds
  - Compromise = control over torrent client
  - **84th tool in hub-of-credentials family — Tier 2**
- **PUBLIC-EXPOSURE = DOS RISK**:
  - Flood's UI exposed to public = legal-target (copyright holders scan for Flood/ruTorrent instances)
  - **Mitigation**: VPN-only access; reverse-proxy with auth
  - **Recipe convention: "don't-expose-torrent-UI-publicly" callout**
- **CLIENT-COMPATIBILITY DRIFT**:
  - qBittorrent API versions change; Flood may lag
  - rTorrent JSON-RPC has specific config requirements (README shows)
  - Deluge marked "experimental"
  - **Recipe convention: "client-API-version-matrix" callout**
  - **NEW recipe convention**
- **RTORRENT CONFIG REQUIREMENTS** (README):
  - For rakshasa/rtorrent >0.15.1 with json-rpc:
    - `method.insert=d.down.sequential,value|const,0`
    - `method.insert=d.down.sequential.set,value|const,0`
  - **Recipe convention: "upstream-tool-config-requirements documented" positive-signal** — Flood README is explicit
- **FLOOD-UI ORG = ECOSYSTEM**:
  - Flood-UI hosts related projects (API libraries, integrations, community docs)
  - **Recipe convention: "project-org-for-ecosystem-spread" positive-signal**
- **CROWDIN LOCALIZATION**:
  - Community translation via Crowdin
  - **Recipe convention: "Crowdin-community-translations" positive-signal**
  - **NEW positive-signal convention** (distinct from Weblate; both are translation platforms)
- **API-DOCUMENTED-INLINE**:
  - Flood's API is documented via comments in source
  - **Less-ideal than dedicated API-docs** — URLs drift
  - **Recipe convention: "inline-docs-instead-of-dedicated-docs" neutral-signal** — works but fragile
- **UNOFFICIAL COMMUNITY DOCS SITE** (flood-api.netlify.app):
  - Community-run, not official
  - **Recipe convention: "community-docs-auxiliary positive-signal"**
- **MULTI-CLIENT TESTING**:
  - vitest integration tests for rTorrent + qBT + Transmission
  - **Recipe convention: "multi-client-integration-tests positive-signal"** — rare engineering discipline for multi-client tools
  - **NEW positive-signal convention**
- **INSTITUTIONAL-STEWARDSHIP**: jesec + Flood-UI-org + community + Discord. **70th tool — sole-maintainer-with-org-and-community sub-tier** (**NEW sub-tier** — distinct from "sole-maintainer-with-community" because of org-scaffolding for related projects)
  - **NEW sub-tier: "sole-maintainer-with-ecosystem-org"** — 1st tool named (Flood)
- **TRANSPARENT-MAINTENANCE**: active + CI + vitest + Crowdin + Discord + releases + Flood-UI-org + community-docs. **78th tool in transparent-maintenance family.**
- **TORRENT-UI-CATEGORY:**
  - **Flood** — modern; multi-client; Node.js
  - **ruTorrent** — legacy PHP; rTorrent-specific; mature
  - **Transmission Web UI** — built-in to Transmission
  - **qBittorrent Web UI** — built-in to qBT
  - **Deluge Web UI** — built-in to Deluge
- **ALTERNATIVES WORTH KNOWING:**
  - **Built-in Web UIs** (qBT, Transmission, Deluge) — if you don't need fancy UI
  - **ruTorrent** — if rTorrent + PHP + legacy comfort
  - **Choose Flood if:** you want modern UI + multi-client + Node.js.
- **PROJECT HEALTH**: active + multi-client tests + Crowdin + Discord + ecosystem-org. Strong.

## Links

- Repo: <https://github.com/jesec/flood>
- Homepage: <https://flood.js.org>
- Flood-UI org: <https://github.com/Flood-UI>
- API docs: <https://flood-api.netlify.app>
- ruTorrent (legacy alt): <https://github.com/Novik/ruTorrent>
- qBittorrent: <https://www.qbittorrent.org>
- Transmission: <https://transmissionbt.com>
- rTorrent: <https://rakshasa.github.io/rtorrent>
