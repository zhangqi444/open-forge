---
name: Prowlarr
description: "Indexer manager and proxy for the *arr ecosystem — centralizes torrent tracker + Usenet indexer config. Syncs to Sonarr/Radarr/Lidarr/Readarr/Mylar3 automatically. Supports 500+ torrent trackers and 24+ Usenet indexers natively plus Torznab/Newznab generics. .NET/ReactJS. GPL-3.0."
---

# Prowlarr

Prowlarr is **the indexer manager for the \*arr stack** — configure your torrent trackers and Usenet indexers *once* in Prowlarr, and it syncs the config to all your downstream \*arr apps (Sonarr for TV, Radarr for movies, Lidarr for music, Readarr for books, Mylar3 for comics). No more configuring the same 20 indexers across 5 apps.

**Replaces Jackett** in most \*arr workflows — Jackett's design pushed indexer-per-app config; Prowlarr centralizes it and is built on the same Servarr framework as the rest of the suite.

Features:

- **Native Usenet support** for 24+ indexers (NZBGeek, DrunkenSlug, NZBFinder, NinjaCentral, etc.) + Generic Newznab
- **Native torrent tracker support** for 500+ trackers + Generic Torznab
- **Custom YML tracker definitions** via Cardigann — add private trackers without waiting for code release
- **Sync to Lidarr/Mylar3/Radarr/Readarr/Sonarr** — one-time app link; indexers push to all
- **Indexer history + statistics** per-app
- **Manual search** — query tracker directly from UI; grab release to \*arr app
- **FlareSolverr integration** — bypass Cloudflare on private trackers
- **Per-indexer proxy** (SOCKS4/5, HTTP, FlareSolverr)
- **Indexer health alerts** (email / Discord / Telegram / Pushover / webhook / etc.)
- **API-compatible** with Newznab/Torznab so other apps can use Prowlarr as a proxy

- Upstream repo: <https://github.com/Prowlarr/Prowlarr>
- Website: <https://prowlarr.com>
- Wiki / Docs: <https://wiki.servarr.com/prowlarr>
- Supported indexers: <https://wiki.servarr.com/en/prowlarr/supported-indexers>
- Discord: <https://prowlarr.com/discord>
- Indexer requests portal: <https://requests.prowlarr.com>

## Architecture in one minute

- **.NET 6+ app** with ReactJS UI
- **SQLite** internal DB (configs + history)
- **Runs on same framework** as Sonarr/Radarr/Lidarr/Readarr (Servarr base)
- **Reverse proxy friendly** — sits behind Traefik/Caddy/nginx
- **Low resource** — ~200 MB RAM; CPU bursts during search

## Compatible install methods

| Infra              | Runtime                                                     | Notes                                                                        |
| ------------------ | ----------------------------------------------------------- | ---------------------------------------------------------------------------- |
| Single VM          | **Docker (`lscr.io/linuxserver/prowlarr`)**                     | **Most popular** — LinuxServer.io image with PUID/PGID                           |
| Single VM          | **Docker (`hotio/prowlarr`)**                                               | Alt image with auto-init scripts                                                         |
| Single VM          | Native .NET (Linux/Windows/macOS packages)                                          | Official installers from prowlarr.com                                                                 |
| Synology / QNAP    | Docker via Container Manager                                                                 | Common NAS deployment                                                                                           |
| Kubernetes         | Community Helm / manifests                                                                          | Works                                                                                                                       |
| Raspberry Pi       | arm/arm64 Docker                                                                                                | Works                                                                                                                                 |
| Managed            | — (no SaaS)                                                                                                                 |                                                                                                                                                  |

## Inputs to collect

| Input                 | Example                                     | Phase      | Notes                                                                     |
| --------------------- | ------------------------------------------- | ---------- | ------------------------------------------------------------------------- |
| Port                  | `9696`                                          | Network    | Default                                                                            |
| App data dir          | `/config`                                         | Storage    | Persist SQLite + indexer defs                                                                  |
| \*arr app URLs + API keys | Sonarr/Radarr/Lidarr URL + API key                  | Integration | Pull API key from each app's Settings → General                                                                 |
| FlareSolverr (opt)    | `http://flaresolverr:8191`                              | Proxy      | For Cloudflare-protected private trackers                                                                                    |
| Indexer creds         | per-tracker username/passkey                                    | Bootstrap  | After server running                                                                                                         |
| Admin auth            | form-based login                                                       | Security   | **Enable it** — Prowlarr holds your tracker passkeys                                                                                         |

## Install via Docker (LinuxServer.io)

```yaml
services:
  prowlarr:
    image: lscr.io/linuxserver/prowlarr:1.19           # pin
    container_name: prowlarr
    restart: unless-stopped
    environment:
      PUID: "1000"
      PGID: "1000"
      TZ: America/Los_Angeles
    volumes:
      - ./config:/config
    ports:
      - "9696:9696"
```

(Optional: pair with FlareSolverr in the same compose:)

```yaml
  flaresolverr:
    image: ghcr.io/flaresolverr/flaresolverr:latest
    container_name: flaresolverr
    restart: unless-stopped
    environment:
      LOG_LEVEL: info
    ports:
      - "8191:8191"
```

## First boot

1. Browse `http://<host>:9696` → **Settings → General** → enable Authentication (**do this first**)
2. **Indexers → Add Indexer** → pick from 500+ supported list; enter your tracker passkey/creds
3. **Settings → Apps → Add** → Sonarr / Radarr / Lidarr / Readarr — enter each app's URL + API key
4. Prowlarr pushes every configured indexer to those apps automatically
5. **Settings → Indexers → FlareSolverr (if using)** → set URL
6. Test by searching for something in Prowlarr → grab → should appear in downstream app

## Data & config layout

- `/config/prowlarr.db` — SQLite (indexers, apps, history)
- `/config/config.xml` — server config
- `/config/Definitions/` — Cardigann YML tracker defs (auto-updated)
- `/config/logs/`

## Backup

```sh
# Stop first for consistent SQLite snapshot (or use .backup pragma)
sudo docker compose stop prowlarr
sudo tar czf prowlarr-$(date +%F).tgz config/
sudo docker compose start prowlarr
```

## Upgrade

1. Releases: <https://github.com/Prowlarr/Prowlarr/releases>. Regular; `main` = stable, `develop` = nightly.
2. Docker: bump tag → restart. Schema migrations auto.
3. Backup `prowlarr.db` before major (0.x → 1.x) jumps.

## Gotchas

- **Enable authentication IMMEDIATELY.** Prowlarr's DB holds every tracker passkey/cookie you have. Exposed unauthenticated = your trackers see someone else's IPs + potentially HnR-ban your account.
- **Don't expose Prowlarr to the internet directly.** Reverse-proxy with auth (Authelia/Authentik/basic) + restrict to VPN/Tailscale ideally.
- **Private trackers + Cloudflare**: most demand FlareSolverr. Configure it and set Prowlarr indexer Cloudflare bypass → FlareSolverr URL.
- **IP bans from trackers**: excessive searches / wrong User-Agent → tracker bans your IP. Configure indexer-level rate limits + respect tracker ToS.
- **\*arr app sync direction**: Prowlarr → Sonarr/Radarr/etc is ONE-WAY. Don't try to edit indexers in Sonarr; you'll make a mess.
- **VPN**: Prowlarr only searches; doesn't download. VPN is typically only needed on your torrent client (qBittorrent etc.). But some private trackers require the search IP = download IP — know your tracker's rules.
- **Backup your passkeys** — if you lose your trackers' credentials list, re-getting passkeys is annoying. Backup `config/`.
- **Usenet vs Torrent config differs** — Usenet uses Newznab API; Torrent uses Torznab. Both work through Prowlarr.
- **Cardigann YML custom defs** — for private trackers not in the default list, the community shares YML files. Drop in `Definitions/Custom/`.
- **Indexer "Disabled" after errors** — Prowlarr auto-disables flaky indexers; re-enable after fixing.
- **FlareSolverr resource use**: runs a headless Chrome; ~500 MB RAM; CPU spikes during Cloudflare challenges.
- **Comparison to Jackett**: Prowlarr is more polished + syncs to \*arr apps + fewer per-app configs. Jackett still works but has less integration.
- **Legal / ToS**: some trackers prohibit sharing between clients. Using Prowlarr is fine for client sync (Prowlarr → your own apps), but sharing your Prowlarr with others violates most tracker rules.
- **DDL (direct download) indexers** — some DDL sites supported via specialized indexers.
- **Authelia / Authentik SSO**: supported via reverse-proxy auth headers (Authentication Required: Forms → Disabled + External).
- **API key**: Prowlarr exposes a Newznab/Torznab-compatible API — your downstream apps use it. Keep API key secret.
- **License**: GPL-3.0.
- **Alternatives worth knowing:**
  - **Jackett** — the predecessor; still works; less \*arr integration
  - **NZBHydra2** — Usenet-focused aggregator; search-UI-first (separate recipe likely)
  - **Cross-Seed** — adjacent: finds matching content on other trackers to cross-seed
  - **Sonarr/Radarr built-in Newznab/Torznab** — manual config per app (what Prowlarr replaces)
  - **Choose Prowlarr if:** you run 2+ \*arr apps.
  - **Use Jackett if:** running a single \*arr app and want lighter deployment.
  - **Add NZBHydra2 if:** Usenet-heavy and want per-indexer stats + complex aggregation.

## Links

- Repo: <https://github.com/Prowlarr/Prowlarr>
- Website: <https://prowlarr.com>
- Wiki / Docs: <https://wiki.servarr.com/prowlarr>
- Installation: <https://wiki.servarr.com/prowlarr/installation>
- Docker (LSIO): <https://hub.docker.com/r/linuxserver/prowlarr>
- Docker (Hotio): <https://hotio.dev/containers/prowlarr/>
- Releases: <https://github.com/Prowlarr/Prowlarr/releases>
- Supported indexers: <https://wiki.servarr.com/en/prowlarr/supported-indexers>
- Indexer requests: <https://requests.prowlarr.com>
- Discord: <https://prowlarr.com/discord>
- Reddit: <https://www.reddit.com/r/prowlarr>
- API docs: <https://prowlarr.com/docs/api/>
- FlareSolverr: <https://github.com/FlareSolverr/FlareSolverr>
- Jackett (alt): <https://github.com/Jackett/Jackett>
- NZBHydra2 (alt): <https://github.com/theotherp/nzbhydra2>
- Servarr Wiki (umbrella): <https://wiki.servarr.com>
