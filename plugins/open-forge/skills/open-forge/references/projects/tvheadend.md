---
name: TVHeadend
description: "Leading Linux TV streaming server + DVR. Supports DVB-T/C/S, ATSC, HDHomeRun, IPTV, SAT>IP inputs. Outputs HTSP (native), HTTP, SAT>IP. GPL-3.0. 20+ years; Coverity-scanned; Cloudsmith-packaged. De-facto OTA-TV recording for cord-cutters + Kodi integration."
---

# TVHeadend

TVHeadend is **"the TV tuner server that makes Linux-powered home TV recording actually work"** — the leading open-source TV streaming server + digital video recorder for Linux. Point your DVB-T / DVB-C / DVB-S / ATSC tuner (or an HDHomeRun networked tuner, or IPTV / SAT>IP source) at it; it decodes the signal, streams it live via HTSP/HTTP, records scheduled programs, fetches EPG (electronic program guide), and pairs beautifully with Kodi / Jellyfin / Plex for a complete cord-cutter TV-on-demand setup. 20+ years old; Coverity-scanned; still active.

Built + maintained by **tvheadend team** + **community** (packages hosted by Cloudsmith). **License: GPL-3.0**. Long-running project (since ~2006); broad hardware support; IRC + forum community.

Use cases: (a) **OTA (over-the-air) TV DVR** — record ATSC/DVB free broadcasts for time-shift viewing (b) **HDHomeRun networked-tuner server** — one TVH instance serves TV throughout the house (c) **Kodi/Jellyfin live-TV backend** — watch live + recorded TV on any screen via frontend clients (d) **IPTV aggregator** — unify IPTV playlists into an EPG-enabled stream (e) **SAT>IP server** — distribute DVB-S content over LAN (f) **cord-cutter replacement for cable-DVR** — record local broadcast at HD quality (g) **multi-room TV distribution** from a single tuner pool.

Inputs supported (per README):

- **ATSC** — US broadcast TV
- **DVB-C / DVB-C2** — European cable
- **DVB-S / DVB-S2** — satellite
- **DVB-T / DVB-T2** — European/ROW terrestrial
- **HDHomeRun** — SiliconDust networked tuners
- **IPTV** (UDP / HTTP)
- **SAT>IP**
- **Unix Pipe** (for scripted stream sources)

Outputs:

- **HTSP** — TVHeadend native protocol (used by Kodi + official apps)
- **HTTP** — generic streaming
- **SAT>IP** — re-broadcast as a SAT>IP server

- Upstream repo: <https://github.com/tvheadend/tvheadend>
- Homepage / forum: <https://tvheadend.org>
- Docs: <https://docs.tvheadend.org>
- Cloudsmith packages: <https://cloudsmith.io/~tvheadend/repos/tvheadend/packages/>
- Coverity Scan: <https://scan.coverity.com/projects/2114>
- IRC: #hts on Libera.Chat (<https://web.libera.chat/#hts>)
- Releases: <https://github.com/tvheadend/tvheadend/releases>

## Architecture in one minute

- **C / C++** binary — high-performance real-time stream handling
- **libhts** — core streaming library
- **XMLTV / grabbers** — EPG data (many formats + sources)
- **Web UI** (Ajax / Extjs) for configuration + management
- **DB**: filesystem-backed config + recorded data
- **Resource**: varies with inputs — 200MB-1GB RAM; CPU for transcoding if enabled
- **Ports**: 9981 (HTTP web UI + streaming), 9982 (HTSP)

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Distro package** | **`apt install tvheadend`** (Debian/Ubuntu)                     | **Traditional path**                                                               |
| Cloudsmith repo    | Upstream-maintained packages (newer versions)                             | <https://cloudsmith.io/~tvheadend/repos/tvheadend/packages/>                                                                                   |
| Docker (LSIO)      | `linuxserver/tvheadend`                                                                                | Popular homelab path                                                                                               |
| Bare-metal source  | `./configure && make && make install`                                                                                                 | For custom hardware / kernel modules                                                                                                 |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Tuner hardware       | USB DVB / PCIe DVB / HDHomeRun / IPTV URL / etc.            | Hardware     | Dictates input module                                                                                    |
| DVB drivers          | Kernel modules present for hardware                         | Kernel       | `lsmod | grep dvb`                                                                                     |
| Storage path         | `/var/lib/tvheadend/recordings`                             | Disk         | Large — HD TV is ~3-5GB/hour                                                                                    |
| EPG source           | XMLTV grabber / over-the-air EIT / Schedules Direct         | EPG          | Schedules Direct = paid US EPG                                                                                    |
| Admin creds          | First-boot setup                                                                             | Bootstrap    | Strong password                                                                                    |
| `/dev/dvb/*`         | Docker-mount DVB devices into container                                                                            | Docker       | Required for hardware passthrough                                                                                                            |

## Install via Docker (LSIO)

```yaml
services:
  tvheadend:
    image: lscr.io/linuxserver/tvheadend:latest
    container_name: tvheadend
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=UTC
    volumes:
      - ./tvh-config:/config
      - /mnt/recordings:/recordings
    devices:
      - /dev/dvb:/dev/dvb  # DVB tuner hardware passthrough
    network_mode: host     # often simplest for streaming discovery
    restart: unless-stopped
```

## First boot

1. Browse `http://host:9981` → wizard walks through network + DVB scan
2. Set admin username + password (MUST — security gotcha below)
3. Configure tuner + scan for channels
4. Configure EPG grabber (OTA EIT is free; Schedules Direct is paid US/Canada)
5. Set up DVR profiles (record format, post-processing, etc.)
6. Configure Kodi / Jellyfin / Plex live-TV client to connect via HTSP (port 9982)
7. Back up `/config`

## Data & config layout

- `/config` (Docker) or `~/.hts/tvheadend/` — all config + user DB + channel DB
- `/recordings` — recorded programs (large; plan disk)
- Logs — `/config/logs/` or syslog

## Backup

```sh
sudo tar czf tvh-config-$(date +%F).tgz tvh-config/
# Recordings: backup policy depends on retention needs; they're big
```

## Upgrade

1. Releases: <https://github.com/tvheadend/tvheadend/releases>. Active; frequent.
2. Distro package updates / Docker pull.
3. Read release notes for tuner-driver changes or EPG-grabber changes.
4. Back up config BEFORE major upgrades.

## Gotchas

- **DEFAULT CREDS `admin:` with EMPTY PASSWORD on first boot**: TVHeadend's default admin has NO password until you set one. **This is critical** — first-boot MUST set a real password before exposing beyond localhost. **7th tool in default-creds-risk family** (Black Candy 83, PMS 86, Guacamole 87, pyLoad 88, VerneMQ 91, CommaFeed 92). Multi-user TVHeadend has granular ACL; configure after first login.
- **NETWORK_MODE: HOST is OFTEN REQUIRED**: DVB + SAT>IP + HDHomeRun discovery needs multicast + broadcast on local LAN. Bridged Docker networking often fails. `network_mode: host` simplifies but reduces container isolation. Trade-off: functionality vs isolation.
- **BROADCAST-TV DVR = LEGAL NUANCE**:
  - **US**: "Betamax" (1984 Sony v. Universal) + subsequent DVR rulings permit **private time-shift recording** for personal use. Sharing recordings / distributing is different (copyright infringement).
  - **UK**: personal time-shift explicitly permitted; TV Licence required to watch live TV anywhere in UK.
  - **Germany + most EU**: similar personal-use carve-outs; commercial / redistribution restricted.
  - **Storage + redistribution limits** apply everywhere. Don't run TVH to rip-and-redistribute; run it for personal time-shift + multi-room-TV.
  - **12th tool in network-service-legal-risk family** — DVR-personal-use sub-family distinct from *arr-piracy-tooling (Readarr 93) or IoT-safety (VerneMQ 91).
- **IPTV-INPUT LEGAL-RISK**: IPTV support means TVHeadend can ingest any IPTV URL. **Some IPTV providers are pirated re-streams of paid services** (satellite, Netflix, premium sports, etc.). If you add such URLs to TVHeadend:
  - Legally equivalent to using pirated IPTV services directly
  - ISPs may throttle / flag
  - DMCA-class rights-holder actions possible
  - **Keep TVHeadend for legal uses** (OTA / legal IPTV / HDHomeRun) + don't use it as a pirate-IPTV-client infrastructure
- **DVB HARDWARE COMPATIBILITY** is the long-tail pain point: Linux kernel DVB driver quality varies enormously. Before buying a USB tuner:
  - Check LinuxTV wiki for driver status
  - Prefer kernel-integrated drivers (no out-of-tree modules)
  - HDHomeRun (networked tuners) SIDESTEPS this — no drivers needed, just network
  - Consider HDHomeRun if drivers stress you
- **EPG DATA QUALITY**: OTA EIT (broadcast-embedded EPG) is often patchy. For US: Schedules Direct ($25/year) is the gold standard. XMLTV grabbers exist for many countries; quality varies. Bad EPG = bad DVR scheduling = missed recordings.
- **STORAGE PLANNING**: 1 hour of 720p TV = ~2-3 GB. 1080p = ~4-5 GB. ATSC HD can be higher. Plan:
  - 1TB for ~300-500 hours of HD
  - Retention policy (auto-delete after N days)
  - Separate disk from OS (avoid filling root)
- **TRANSCODING CPU**: TVHeadend can transcode H.264/H.265 if your CPU / GPU has capacity. Real-time transcoding of multiple streams needs decent CPU. Consider disabling if your hardware doesn't support it, or use GPU passthrough.
- **HUB-OF-CREDENTIALS Tier 2**: TVHeadend stores:
  - Admin + user accounts (passwords hashed)
  - EPG grabber service credentials (Schedules Direct)
  - IPTV provider URLs (may contain tokens)
  - **36th tool in hub-of-credentials family — Tier 2.**
- **CONFIG IS FILESYSTEM-BASED**: no DB; tvheadend uses JSON files in config dir. **Positive: easy to back up + grep + edit**. Negative: file corruption can brick config. Regular backups matter.
- **KODI / JELLYFIN / PLEX CLIENT SETUP**:
  - **Kodi**: use HTS (HTSP) PVR addon; configure with TVH server IP + HTSP port + admin creds
  - **Jellyfin**: has TVHeadend live-TV plugin; HTTP-stream-based
  - **Plex**: has DVR feature; supports HDHomeRun directly AND TVHeadend via HDHomeRun-emulation-mode in TVH
- **COVERITY SCAN BADGE**: TVHeadend runs Coverity static analysis → positive security-stewardship signal. **18th tool in transparent-maintenance family** (code-quality-audit sub-signal).
- **AGE-AS-MATURITY-SIGNAL**: 20+ years; stable + mature + broad hardware support. Same family as ddclient (batch 93). Reinforces "age = maturity" framing.
- **INSTITUTIONAL-STEWARDSHIP**: community-maintained + Cloudsmith-hosted packages + IRC community. **17th tool in institutional-stewardship family — community-steward-of-legacy-tool sub-tier** (5th sub-tier member).
- **COMMERCIAL-TIER**: no paid services; GPL-3; community-funded. **10th tool in pure-donation/pure-community category.**
- **ALTERNATIVES WORTH KNOWING:**
  - **MythTV** — even older; PVR-focused; GPL-2; C++; large deployment base
  - **NextPVR** — freemium; Windows-first but runs on Linux
  - **Emby DVR** — closed-source; integrated with Emby media server
  - **Plex DVR** — closed-source; requires Plex Pass
  - **Jellyfin Live TV** — OSS; Plex fork; integrated DVR
  - **ErsatzTV** — IPTV-channel-server (different use case)
  - **xTeVe** — IPTV-proxy that looks like HDHomeRun to Plex
  - **Choose TVHeadend if:** you want FLEXIBLE + broad-hardware-support + GPL + proven + kodi-integration.
  - **Choose MythTV if:** you want mature-PVR + traditional-architecture + deep-features.
  - **Choose Jellyfin DVR if:** you want integrated-media-server + modern + OSS.
  - **Choose Plex DVR if:** you accept closed-source + want polished-UX.
- **PROJECT HEALTH**: active (last commit badge) + Coverity-scanned + GPL-3 + Cloudsmith packages + active IRC/forum + 20-year track record. Bedrock cord-cutter tool.

## Links

- Repo: <https://github.com/tvheadend/tvheadend>
- Homepage: <https://tvheadend.org>
- Docs: <https://docs.tvheadend.org>
- Cloudsmith packages: <https://cloudsmith.io/~tvheadend/repos/tvheadend/packages/>
- Coverity: <https://scan.coverity.com/projects/2114>
- IRC: #hts on Libera.Chat
- LinuxServer image: <https://docs.linuxserver.io/images/docker-tvheadend>
- MythTV (alt): <https://www.mythtv.org>
- Jellyfin (alt): <https://jellyfin.org>
- Schedules Direct (US EPG): <https://www.schedulesdirect.org>
- HDHomeRun: <https://www.silicondust.com>
