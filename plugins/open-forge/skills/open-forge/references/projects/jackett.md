---
name: Jackett
description: Indexer proxy for torrent/usenet trackers. Translates queries from Sonarr/Radarr/Lidarr/CouchPotato into tracker-specific search API calls. Supports 500+ public, semi-private, and private trackers. GPL-2.0.
---

# Jackett

Jackett presents a unified API (Torznab/Potato) to downstream clients like Sonarr, Radarr, Lidarr, Readarr, and CouchPotato. When those apps ask "find me The Expanse S04E01", Jackett translates that into the specific search language of each enabled tracker, scrapes the results, and returns a normalized response. This avoids each app having to maintain its own library of tracker definitions.

Complementary to Prowlarr (a more recent reimplementation) — many installations now prefer Prowlarr for the *arr stack.

- Upstream repo: <https://github.com/Jackett/Jackett>
- Docs: <https://github.com/Jackett/Jackett/wiki>
- Community Docker image: `lscr.io/linuxserver/jackett` (LinuxServer.io)

## Compatible install methods

| Infra     | Runtime                              | Notes                                                          |
| --------- | ------------------------------------ | -------------------------------------------------------------- |
| Single VM | Docker (`lscr.io/linuxserver/jackett`) | **Recommended.** Sidesteps Mono stability issues                 |
| Windows   | MSI installer                        | Native .NET — good for Windows users                            |
| Linux     | Mono + binary release                | Upstream ships a one-command installer; Mono dependency is fading |
| macOS     | Download + `./jackett`              | Intel + ARM builds                                              |
| Homebrew  | `brew install jackett`               | For dev machines                                                |
| Synology / QNAP | Package via SynoCommunity / container | Docker path strongly recommended                         |
| OpenWrt / Alpine | Wiki-documented                | Niche                                                           |

## Inputs to collect

| Input          | Example                         | Phase    | Notes                                                           |
| -------------- | ------------------------------- | -------- | --------------------------------------------------------------- |
| `PUID` / `PGID` | `1000` / `1000`                | Runtime  | Match host user for volume writes                                |
| Port           | `9117:9117`                     | Network  | Jackett's web UI + API port                                     |
| Config volume  | `./jackett:/config`             | Data     | Tracker definitions, API keys, cookies                           |
| Downloads volume | `./downloads:/downloads`       | Data     | Optional; used if "save to blackhole" is configured              |
| `AUTO_UPDATE`  | `true` (default in LSIO)        | Runtime  | Jackett updates tracker definitions on start                     |
| Admin password | set in web UI                   | Bootstrap | **Default has NO password** — set one immediately                 |
| Reverse proxy  | for TLS + optional auth         | Security | Never expose unauthenticated Jackett to the internet             |

## Install via Docker Compose (LSIO)

From <https://github.com/linuxserver/docker-jackett>:

```yaml
services:
  jackett:
    image: lscr.io/linuxserver/jackett:latest
    container_name: jackett
    restart: unless-stopped
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Etc/UTC
      - AUTO_UPDATE=true           # Jackett self-updates definitions on start
      # - RUN_OPTS=                # optional extra CLI flags
    volumes:
      - ./jackett/config:/config
      - ./jackett/downloads:/downloads   # optional; for "save to blackhole"
    ports:
      - 9117:9117
```

Browse `http://<host>:9117`. First load: **set an admin password immediately** via the dashboard top-right → Admin Password. No password = anyone who can reach port 9117 can reconfigure Jackett, scrape trackers on your behalf (potentially getting your account banned), and steal your private-tracker cookies.

## Adding trackers

1. Dashboard → `Add indexer` → search for a tracker (e.g. "iptorrents").
2. For private trackers: fill in username + password OR cookie (depending on tracker).
3. Click `Test` to verify Jackett can authenticate and search.
4. Copy the `Torznab Feed` URL + `API Key` for the tracker — paste into Sonarr/Radarr/Lidarr.

## Data & config layout

Inside `/config`:

- `ServerConfig.json` — main config (base path, admin password hash, port, update channel)
- `Indexers/*.json` — per-tracker saved state (credentials, cookies, last-update)
- `DataProtection-Keys/` — .NET data protection keys (encrypt saved passwords)
- `log.txt` — runtime logs
- `Definitions/` — tracker definition files (YAML); auto-updated from <https://github.com/Jackett/Jackett/tree/master/src/Jackett.Common/Definitions>

**Critical:** the `DataProtection-Keys` directory contains the encryption keys for all your stored tracker credentials. Losing them means re-entering every tracker's credentials. Back up `/config` as a whole unit.

## Install via native Linux (one-command)

From <https://github.com/Jackett/Jackett#linux-installation-amd-x64>:

```sh
# AMD64 one-liner (runs as a systemd service):
curl -sfL https://raw.githubusercontent.com/Jackett/Jackett/master/install_service_systemd.sh | sudo bash
```

Service is `jackett.service`. Config lives at `/home/jackett/.config/Jackett/` (or wherever the installer places it).

## Backup

```sh
# Docker variant
docker compose stop jackett
tar czf jackett-config-$(date +%F).tgz ./jackett/config
docker compose start jackett

# Native Linux
sudo systemctl stop jackett
sudo tar czf jackett-$(date +%F).tgz -C /home/jackett .config/Jackett
sudo systemctl start jackett
```

## Upgrade

1. Releases: <https://github.com/Jackett/Jackett/releases>.
2. **Docker (LSIO):** `docker compose pull && docker compose up -d` — LSIO rebuilds weekly on upstream releases.
3. **Native Linux:** re-run the installer, which overwrites the binary. Or use Jackett's in-app updater (dashboard → Update).
4. Tracker definitions auto-update on start — separate from core version upgrades.
5. Jackett has historically shipped security-relevant updates (auth bypasses, XSS) — keep current.

## Gotchas

- **Default install has NO admin password.** Set one on first visit. Anyone who reaches port 9117 without auth can add indexers, change the port, see your private tracker credentials.
- **Never expose Jackett to the public internet.** Even with an admin password, Jackett's tracker-scraping capability makes it an attractive abuse vector. LAN-only or VPN-only access; use a reverse proxy with its own auth layer if you need remote access.
- **Private tracker cookies can get your account banned.** If Jackett scrapes aggressively enough to trigger a tracker's anti-abuse, your account (not the IP, your account) can be nuked. Respect per-tracker rate limits — Jackett exposes `Queries per 15 seconds` in tracker settings.
- **Tracker definitions change frequently.** A tracker redesigns their site → Jackett's YAML definition breaks → search returns nothing. Usually fixed within 24–48h by the community. Keep `AUTO_UPDATE=true` on.
- **Prowlarr is the modern alternative.** <https://github.com/Prowlarr/Prowlarr> reimplements Jackett for the *arr stack with a nicer UI, Sonarr-style sync, authentication built in. Many long-time Jackett users have migrated. Jackett is still maintained and preferred for non-*arr apps (e.g. CouchPotato, custom scripts).
- **Mono on Linux has historical stability issues.** The Docker image sidesteps this by using a Mono-less .NET build. Native Linux installs now use .NET 6/8, not Mono — but older installs might still be on Mono.
- **`RUN_OPTS` for reverse proxy base path.** To serve Jackett under `https://example.com/jackett`, set `RUN_OPTS=--ProxyConnection=http://<upstream>:<port> --PathBase=/jackett` in the container env, then reverse-proxy `/jackett/` → `http://jackett:9117/jackett/`.
- **Each tracker's API is different.** Jackett parses HTML for scraper-type trackers; it's brittle by design. Expect tracker breakage monthly on average across a large indexer list.
- **Definitions live under `/config/Definitions/` if you override them.** Custom definitions (for self-hosted / private YAML definitions) go there; stock definitions auto-update from upstream.
- **The installer script is Ubuntu/Debian-centric.** CentOS/RHEL users end up building from source or using Docker.
- **Public trackers = lots of garbage.** Jackett will dutifully return every result a public tracker gives, including fakes/malware. Downstream *arr apps do some filtering; you should too (via *arr blacklists).
- **IP bans at trackers are by IP, not account.** Sharing a Jackett instance across too many users through the same outbound IP can get your IP banned on strict private trackers.
- **No built-in authentication for API clients.** Jackett's API key is the only "auth"; it's a bearer token in the URL. Treat it as a secret, rotate if leaked (resets by clicking "Regenerate API Key" in dashboard).
- **Windows users should prefer the MSI installer** over Docker-on-WSL2 unless they have other reasons to run Linux containers.

## Links

- Repo: <https://github.com/Jackett/Jackett>
- Wiki: <https://github.com/Jackett/Jackett/wiki>
- Releases: <https://github.com/Jackett/Jackett/releases>
- LinuxServer Docker repo: <https://github.com/linuxserver/docker-jackett>
- Docker Hub: <https://hub.docker.com/r/linuxserver/jackett>
- Tracker definitions: <https://github.com/Jackett/Jackett/tree/master/src/Jackett.Common/Definitions>
- Prowlarr (modern alternative): <https://github.com/Prowlarr/Prowlarr>
