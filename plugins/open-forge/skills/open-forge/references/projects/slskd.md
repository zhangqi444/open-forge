---
name: slskd
description: "Modern client-server web app for Soulseek P2P file-sharing network. Daemonizable, internet-exposable, token-authed, reverse-proxy compatible. C#/.NET. Unusual in the P2P space for being designed-for-self-host. AGPL-3.0. Active."
---

# slskd

slskd is **"a modern client-server daemon for Soulseek, designed to run in your network or in the cloud"** — a web-based front end for the **Soulseek P2P file-sharing network** (a long-running peer-to-peer network primarily used for obscure/out-of-print music + other files). Unlike the classic Soulseek Windows client (GUI-only), slskd is a daemon + web UI, designed to be deployed like any other self-hosted service, exposed to the internet, token-protected, and compatible with reverse proxies. You can search, download, manage queue, chat, and join rooms via the browser.

Built + maintained by **slskd contributors** (jpdillingham founder + community). **License: AGPL-3.0**. Active; Docker + binary releases; Discord + Matrix community.

Use cases: (a) **music-collection-research** — Soulseek is famous for rare music + live-bootleg trading + DJ-community-sharing — slskd-via-browser makes this accessible (b) **remote Soulseek** — search/download from your phone or any browser away from home (c) **headless server** deployment — no Windows client required (d) **integration with music library** — drop downloads into Navidrome / Jellyfin / Plex libraries (e) **old-catalog archiving** — music that never made it to streaming services (f) **DJ communities** — trading edits + unreleased tracks (traditional Soulseek use) (g) **replace nicotine+** (GTK Soulseek client) with web UI.

Features (from upstream README):

- **Modern web UI** (access from browser)
- **Runs as daemon / Docker** in your network
- **Token-authenticated** — designed for internet exposure
- **Reverse-proxy compatible**
- **Search** + sort + filter
- **Download queue management** (speed, status, per-user/folder)
- **Browse shares + chat + chat rooms + private message** — full Soulseek client feature parity
- **Pretty much everything** official Soulseek client supports

- Upstream repo: <https://github.com/slskd/slskd>
- Homepage: <https://slskd.org>
- Config docs: <https://github.com/slskd/slskd/blob/master/docs/config.md>
- Reverse proxy docs: <https://github.com/slskd/slskd/blob/master/docs/reverse_proxy.md>
- Docker Hub: <https://hub.docker.com/r/slskd/slskd>
- Discord: <https://slskd.org/discord>
- Matrix: <https://slskd.org/matrix>
- Soulseek network: <https://www.slsknet.org/news/>

## Architecture in one minute

- **C# / .NET** — daemon
- **Web UI** — self-hosted
- Stateful: downloads + config + queue state
- **Resource**: moderate — 200-500MB RAM, bandwidth depending on sharing
- **Ports**:
  - **5030/5031** — web UI (HTTP/HTTPS)
  - **50300** — Soulseek network port (needs to be reachable for incoming connections)

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker**         | **`slskd/slskd:latest`**                                       | **Primary**                                                                        |
| Docker compose     | With VPN sidecar often                                                    | Common                                                                                   |
| Binary release     | .NET 6 + binary                                                                             | Bare-metal                                                                                               |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Soulseek username + password | Soulseek network account                            | **CRITICAL** | **Your Soulseek network credentials**                                                                                    |
| Share directory      | `/data/shared` — what you offer to the network              | **CRITICAL** | **You MUST share to be allowed to download reasonably**                                                                                    |
| Download directory   | `/data/downloads`                                           | Storage      | Where incoming files land                                                                                    |
| Port 50300           | TCP incoming; must be reachable                                                                           | Network      | NAT/firewall config; without this, you're "unreachable"                                                                                    |
| Web UI token         | `SLSKD_JWT_SECRET` or similar                                                                           | **CRITICAL** | **AGPL daemon but token-authed**                                                                                                            |
| Admin password       | For UI auth                                                                                                          | Auth         | Strong                                                                                                                            |

## Install via Docker

```sh
docker run -d \
  -p 5030:5030 \
  -p 5031:5031 \
  -p 50300:50300 \
  -e SLSKD_REMOTE_CONFIGURATION=true \
  -v /path/to/data:/app \
  --name slskd \
  --user 1000:1000 \
  slskd/slskd:latest     # **pin version**
```

## First boot

1. Start → browse `http://host:5030`
2. Configure Soulseek credentials (network login)
3. Configure share directory (MANDATORY — sharing maintains Soulseek ratio)
4. Configure download directory
5. Verify Soulseek port 50300 is externally reachable (upnp or manual port-forward)
6. Test search; verify results come back
7. Test download
8. Put UI behind TLS reverse proxy with auth
9. Back up config + share index + auth tokens

## Data & config layout

- `/app/config/slskd.yml` (or similar) — main config
- `/app/shared/` — your shared library (usually bind-mounted to actual media)
- `/app/downloads/` — incoming files
- `/app/logs/`

## Backup

- Config files should be backed up
- Shared folder: depends on whether it's your library (back up with your music library)
- Downloads: transient

## Upgrade

1. Releases: <https://github.com/slskd/slskd/releases>. Active.
2. Docker: pull + restart.
3. Read release notes; config format may evolve.

## Gotchas

- **SOULSEEK-NETWORK-LEGALITY = SIGNIFICANT**:
  - Soulseek is **a peer-to-peer file-sharing network** — users share + download files
  - **Copyrighted content** is widely shared on Soulseek (though Soulseek's culture emphasizes out-of-print / rare / bootleg / DJ-edit content NOT available commercially — argument: fair-use / preservation)
  - **Downloading copyrighted content without rights** remains illegal in most jurisdictions regardless of commercial availability
  - **Rights holders + anti-piracy agencies monitor P2P networks**, including Soulseek
  - **ISPs + hosting providers** receive DMCA notices based on IP activity
  - **19th tool in network-service-legal-risk family — P2P-file-sharing sub-family (NEW, 10th)** — distinct from *arr-piracy-tooling (Readarr 93), IPTV-conduit (Dispatcharr 96), front-end-proxy (Redlib 95), content-download-wrapper (YDL-M 97), commercial-API-dependency (Mixpost 97). slskd accesses a dedicated P2P network. **10th sub-family of network-service-legal-risk.**
- **LEGAL NUANCE: Soulseek's CULTURAL NICHE**:
  - Much Soulseek content IS commercially-unavailable: out-of-print albums, DJ edits, unreleased live bootlegs, obscure genres
  - Soulseek predates streaming; many users are music-preservationists
  - Courts have been sympathetic in some preservation cases
  - **That doesn't make copyright-infringement legal**; it contextualizes motivation
  - **Recipe convention: neutral, honest framing** for P2P/piracy-adjacent tools (reinforces GrowChief 94 precedent + Redlib 95)
- **VPN STRONGLY RECOMMENDED**:
  - Running slskd behind VPN (Gluetun sidecar pattern — Dispatcharr 96 precedent) protects your home IP from exposure to Soulseek peers + DMCA notices
  - Many Soulseek users default to VPN-routed
  - **VPN-sidecar pattern** applies: `network_mode: "service:gluetun"`
- **UPLOAD RATIO EXPECTATIONS**: Soulseek culture expects you to share as much as you download. Running slskd + sharing nothing → "leech" reputation + effectively-blocked by power-users. **Share generously; be a good citizen.**
- **HUB-OF-CREDENTIALS LIGHT → TIER 2**:
  - Soulseek network password (your account)
  - Web UI token + admin password
  - Reverse proxy auth config
  - **52nd tool in hub-of-credentials family — Tier 2 (considering Soulseek account compromise could lead to reputation-hit + shared-library-exposure)**
- **PUBLIC EXPOSURE CONSIDERATIONS**: slskd IS designed to be internet-exposed (token-authed + reverse-proxy-ready). That's unusual for P2P clients (typically LAN-only). However:
  - Exposure = more attackers see the web UI
  - Token-only + TLS reverse proxy is the documented path
  - **No default creds** (verify — configuration-required for first use)
- **UPNP vs MANUAL PORT-FORWARD**: slskd needs port 50300 reachable for inbound Soulseek peer connections. UPnP automates; manual is more controllable. Common homelab setup.
- **SHARED DIRECTORY ≠ DOWNLOAD DIRECTORY**: you bind-mount your ACTUAL music library as `/app/shared` (read-only strongly recommended), and a writable `/app/downloads` for incoming files. If you bind-mount downloads as shared, you create an auto-share-what-you-download loop (can be useful or problematic).
- **ISP-LEVEL P2P DETECTION**: some ISPs throttle or disrupt P2P traffic. VPN addresses this. Cloud hosting providers often prohibit P2P — read ToS.
- **TRANSPARENT-MAINTENANCE**: AGPL-3 + active + Discord + Matrix + docs + internet-exposable-by-design + token-auth. **34th tool in transparent-maintenance family.** Unusually transparent for a P2P tool.
- **INSTITUTIONAL-STEWARDSHIP**: jpdillingham founder + community contributors. **28th tool in institutional-stewardship — sole-maintainer-with-community sub-tier**. slskd has healthy contributor count.
- **AGPL-3.0 = APPROPRIATE CHOICE**: prevents cloud providers from lifting + offering as proprietary SaaS. For P2P tool, AGPL + self-host emphasis match operational model.
- **NICOTINE+ vs slskd**: Nicotine+ is the GTK desktop Soulseek client (mature, feature-rich, Linux-first). slskd is the web-daemon form. **Complementary, not competing**; many users run Nicotine+ on desktop + slskd on server for remote access.
- **P2P TOOL OPERATIONAL MODEL**:
  - Always-on (you're a peer, not just a client)
  - Share as you download
  - Accept "upload-while-you-sleep" pattern
  - Higher bandwidth use than most self-hosted tools (upload + download constantly)
- **ANTI-ABUSE IN SOULSEEK CULTURE**: Soulseek has no central authority but:
  - User-level bans + shares-visible enforcement
  - Ratio-aware matchmaking
  - Community norms (greet before asking for files, etc.)
- **SONARR/RADARR-ADJACENT for music**: similar role to what Lidarr (music *arr) plays, but via Soulseek instead of torrents. Some users run Soulseek alongside *arr stack for music.
- **ALTERNATIVES WORTH KNOWING:**
  - **Nicotine+** — GTK Soulseek desktop client (mature, full-feature)
  - **SoulseekQt** — the official Soulseek client (Windows + minimal macOS/Linux)
  - **Lidarr** — music *arr variant; uses torrent + usenet (different network)
  - **Beets** — music-library-organizer (not downloader)
  - **Navidrome / Jellyfin** — music-server (consumption side)
  - **qBittorrent / Transmission** — general-P2P for torrents
  - **Resilio / Syncthing** — self-to-self P2P (different use case)
  - **Choose slskd if:** you want WEB UI + daemon + remote-access + self-host + AGPL + Soulseek-specifically.
  - **Choose Nicotine+ if:** you want desktop GUI + Linux-first.
  - **Choose Lidarr if:** you want torrent/usenet-based music automation.
- **PROJECT HEALTH**: active + AGPL-3 + Discord + Matrix + documented + internet-exposure-designed-in. Mature for P2P-space.

## Links

- Repo: <https://github.com/slskd/slskd>
- Homepage: <https://slskd.org>
- Config docs: <https://github.com/slskd/slskd/blob/master/docs/config.md>
- Reverse proxy: <https://github.com/slskd/slskd/blob/master/docs/reverse_proxy.md>
- Docker: <https://hub.docker.com/r/slskd/slskd>
- Discord: <https://slskd.org/discord>
- Matrix: <https://slskd.org/matrix>
- Nicotine+ (alt): <https://nicotine-plus.org>
- Soulseek network: <https://www.slsknet.org>
- Gluetun (VPN sidecar): <https://github.com/qdm12/gluetun>
