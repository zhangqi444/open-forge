---
name: pyLoad
description: "Free and open-source download manager in pure Python (pyload-ng) — one-click hosters, cloud drives, decrypters, captcha-solving integration, premium accounts, web UI. Runs on Linux/macOS/Windows/NAS. AGPL-3.0. Network-service-legal-risk class."
---

# pyLoad

pyLoad is **"the self-hosted JDownloader alternative — download manager for one-click hosters + file-share sites"**. Pure-Python rewrite (`pyload-ng` on PyPI); web-UI-driven; heavy plugin ecosystem. Runs headless on a NAS / Pi / VPS and grinds through your download queue: one-click hoster links, cloud-drive shares, link decrypters (Rapidgator / Mega / Uptobox / etc.), captcha-solving integrations, premium-account handling.

Built + maintained by the **pyLoad team**. **AGPL-3.0**. Active on PyPI as `pyload-ng`.

Use cases: (a) **bulk-download from one-click hosters** (file-share sites with download limits / captcha) (b) **scheduled / background downloading** to NAS for later consumption (c) **link-decrypter** — unfurl obfuscated/encrypted sharing links (d) **download-queue manager** across many sources (e) **homelab "download-everything" server** paired with Sonarr / Radarr / your media stack.

Features:

- **Web interface** — manage queue from browser
- **Plugin-driven** — hundreds of hosters + decrypters + addons
- **Captcha-solving service integration** — 9kw, AntiCaptcha, etc.
- **Premium account support** — use premium hoster accounts for speed
- **Link decrypters** — unfurl obfuscated sharing URLs
- **Schedulers + notifications** via plugins
- **Cross-platform**: Linux, macOS, Windows, FreeBSD
- **Python 3.9+** compatibility
- **Headless daemon mode** for server deploys
- **REST-ish JSON API** for automation

- Upstream repo: <https://github.com/pyload/pyload>
- Homepage: <https://pyload.net>
- PyPI: <https://pypi.org/project/pyload-ng/>
- Docker: <https://hub.docker.com/r/writl/pyload>, <https://docs.linuxserver.io/images/docker-pyload-ng>
- Docs: <https://github.com/pyload/pyload/wiki>

## Architecture in one minute

- **Python 3.9+** — pure Python
- **Web server** — built-in (Bottle-based); listens on port 8000 by default
- **Config + state** — flat files in `~/.pyload/`
- **Plugins** — Python modules installed into the pyLoad plugin directory
- **Resource**: light — 100-300MB RAM + whatever your download queue demands disk-wise

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| PyPI (pip)         | **`pip install --pre pyload-ng[all]`**                          | **Upstream-primary**                                                               |
| Docker (LSIO)      | `lscr.io/linuxserver/pyload-ng` (multi-arch)                              | **Recommended for server use**                                                             |
| Docker (writl)     | `writl/pyload` community image                                                         | Alternative                                                                                |
| Source             | `git clone + pip install -e .`                                                                  | For dev                                                                                               |
| Windows bundle     | Binary distribution on releases                                                                         | For desktop Windows                                                                                                |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| `--storagedir`       | `/mnt/downloads/pyload`                                     | Storage      | WHERE downloads land                                                                                    |
| `--userdir`          | `~/.pyload` (default)                                                  | Config       | User data + config files                                                                                    |
| Admin user + password | Default `pyload`/`pyload` — **change on first boot**                                  | **CRITICAL** | **Default creds PUBLIC**                                                                                    |
| Plugin accounts      | Hoster premium account creds                                                       | Accounts     | Per-hoster in web UI                                                                                                      |
| Captcha service creds (opt) | API key for 9kw / AntiCaptcha                                                                              | Optional     | For sites requiring captcha                                                                                                              |
| SMTP / notification (opt) | For download-complete alerts                                                                                     | Optional     | Plugin-dependent                                                                                                                  |

## Install via Docker (LSIO)

```yaml
services:
  pyload:
    image: lscr.io/linuxserver/pyload-ng:latest    # **pin version** in prod
    restart: unless-stopped
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=UTC
    volumes:
      - ./pyload-config:/config
      - /mnt/downloads:/downloads
    ports: ["8000:8000"]
```

## First boot

1. Browse `http://host:8000`
2. Log in with default `pyload` / `pyload`
3. **CHANGE PASSWORD IMMEDIATELY** (`--reset` flag or admin UI)
4. Configure storage directory (downloads destination)
5. Add hoster accounts (premium logins) — **these are stored in pyLoad config**
6. Optionally configure captcha-solving API keys
7. Test with a safe link (public FOSS ISO download)
8. Put behind TLS reverse proxy + strong auth
9. Back up `/config`

## Data & config layout

- `~/.pyload/` (or `/config` in Docker) — user data:
  - `pyload.cfg` — main config
  - `accounts.cfg` — hoster account passwords (SECRETS)
  - `database.db` — queue state + history
  - Plugin configs + state
- Storage dir — downloaded files (YOUR data, SEPARATE from pyLoad state)
- Temp dir — in-progress download fragments

## Backup

```sh
# Config (includes account passwords — treat as secret)
sudo tar czf pyload-config-$(date +%F).tgz pyload-config/
# Downloads — your responsibility, usually already on a separate backup path
```

## Upgrade

1. PyPI path: `pip install --upgrade --pre pyload-ng[all]`
2. Docker: pull latest + restart
3. Plugin compatibility: breaking changes in pyLoad major versions can break plugins. Check upstream changelog.
4. Back up config FIRST.

## Gotchas

- **DEFAULT CREDS `pyload` / `pyload` ARE PUBLIC** — same family as Black Candy / PMS / Guacamole. **4th tool in default-credentials-PUBLIC family.** Change on first boot; don't skip this.
- **Never expose pyLoad directly to the internet without strong auth + TLS.** pyLoad can download arbitrary URLs + execute plugin code → a compromised pyLoad = remote code execution vector. Use VPN / reverse-proxy-with-auth / IP allowlist.
- **Hoster-site legal risk** — this is the core legal consideration:
  - **pyLoad is legal software** — it's a download manager.
  - **What you download with it** can be legal (public FOSS, your own backups, DMCA-safe content) or illegal (copyrighted material without license, pirated content).
  - **pyLoad is heavily associated with "warez" / piracy communities** historically — one-click hosters (Rapidgator / Uploaded / etc.) host a mix of legal + pirated content. The plugin ecosystem reflects this.
  - **Legal exposure is on YOU, not pyLoad.** Treat like Bitmagnet (batch 85), AzuraCast (87), 13ft (83) — **9th tool in network-service-legal-risk family**.
  - **VPN recommendation**: if your use case is borderline, same VPN-with-port-forward pattern as Bitmagnet. Separate legal-liability question.
- **HUB-OF-CREDENTIALS (LIGHT)**: pyLoad stores **premium-hoster account passwords + captcha-service API keys**. These cost money (premium-hoster subscriptions); compromised config = someone uses your paid accounts or API-key budget. **14th tool in hub-of-credentials family, LIGHT tier.**
  - Defense: strong file perms on `~/.pyload/` (`chmod 700`); full-disk encryption; offsite-backup-encrypted.
- **Plugin code = remote code execution surface**: pyLoad plugins are Python modules. A malicious plugin = full server compromise. **Only install from the official pyLoad plugin repo + trusted community sources.** Same class as Shaarli / Piwigo plugin warnings (batch 87 / 88).
- **Plugin breakage reality**: hoster sites CHANGE constantly (anti-bot / Cloudflare / captcha updates). Plugins lag. Expect some plugins to be broken + needing community fixes at any given time. **Provider-API-churn-reality** pattern (same as Bazarr batch 86 subtitle providers). **Active community is your lifeline.**
- **Captcha-solving ethics**: automated captcha solving via paid services is a gray area for the target site's ToS. You're bypassing a security-by-obscurity measure. Legal status varies by jurisdiction + site ToS.
- **Python packaging warning**: `pyload-ng` is on PyPI as `--pre` (pre-release) typically. Not stability-signal BAD; just project's release conventions. Read changelogs.
- **Disk fill-up risk**: an unattended download queue can fill your NAS. Set size limits + monitor disk.
- **Python 3.9+ requirement**: old distro Python may not satisfy; use pyenv / deadsnakes / newer base OS.
- **Network-heavy workload**: pyLoad will saturate your download bandwidth. If shared with other users / household, set rate limits. Premium hosters often multi-threaded = high link utilization.
- **Competing tools**:
  - **JDownloader2** (Java, closed-source-mostly but free, desktop-primary) — the commercial-ish incumbent; many users prefer it; supports more hosters more reliably
  - **aria2** — simpler + protocol-focused (HTTP/FTP/BitTorrent/Metalink)
  - **youtube-dl / yt-dlp** — video-download-specific
  - **Sonarr / Radarr + SABnzbd / NZBGet / qBittorrent** — media-automation stack integrates NZB/torrent not hoster-links
  - **pyLoad's niche**: headless + self-hosted + plugin-rich + Python-friendly + hoster-link-focused
- **AGPL-3.0** fine for self-hosted use.
- **Project health**: active PyPI release cadence + GitHub actions passing + community contributions. Reasonable project-health signals. Single-figurehead concerns less severe due to AGPL + community plugin ecosystem.
- **Alternatives worth knowing:**
  - **JDownloader2** — proprietary desktop; often the go-to for hoster downloads
  - **aria2** — simpler multi-protocol downloader
  - **SABnzbd / NZBGet** — Usenet-focused
  - **qBittorrent** — torrent-focused
  - **yt-dlp** — video-site-focused
  - **Commercial hoster-bypass services** (Debrid services: Real-Debrid, AllDebrid, Premiumize) — buy a subscription, get fast + simplified downloads; pairs with pyLoad or used directly
  - **Choose pyLoad if:** you want self-hosted + headless + plugin-rich + server-daemon mode + Python.
  - **Choose JDownloader2 if:** you want desktop UX + broader hoster support + mature (at cost of OSS-pure).
  - **Choose aria2 if:** you want minimal + command-line + just HTTP/FTP/torrent.

## Links

- Repo: <https://github.com/pyload/pyload>
- Homepage: <https://pyload.net>
- PyPI: <https://pypi.org/project/pyload-ng/>
- Wiki: <https://github.com/pyload/pyload/wiki>
- LSIO Docker: <https://docs.linuxserver.io/images/docker-pyload-ng>
- Issues: <https://github.com/pyload/pyload/issues>
- JDownloader2 (proprietary alt): <https://jdownloader.org>
- aria2 (alt): <https://aria2.github.io>
- yt-dlp (video alt): <https://github.com/yt-dlp/yt-dlp>
- Real-Debrid (commercial bypass): <https://real-debrid.com>
