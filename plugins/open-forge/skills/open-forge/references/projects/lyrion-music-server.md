---
name: Lyrion Music Server (LMS)
description: "Streaming audio server for Squeezebox hardware + software emulators. Formerly SlimServer / SqueezeCenter / Logitech Mediaserver. Perl. Runs anywhere Perl runs. LMS-Community/slimserver. lyrion.org."
---

# Lyrion Music Server (LMS)

Lyrion Music Server is **"SqueezeCenter reborn — the Squeezebox-ecosystem server, community-continued after Logitech discontinuation"** — a streaming audio server that powers Squeezebox hardware (3rd Gen, Boom, Receiver, Transporter, Squeezebox2, Squeezebox, SLIMP3) plus software emulators (Squeezelite, SqueezePlay). **Written in Perl**, runs anywhere Perl runs (Linux, macOS, Solaris, Windows, NAS, RPi).

**Legacy names**: SlimServer, SqueezeCenter, SqueezeboxServer, Logitech Mediaserver, SliMP3. Renamed to **Lyrion** after Logitech discontinued official Squeezebox server support — community-continued.

Built + maintained by **LMS-Community** org. Docker Hub + ghcr.io. lyrion.org official docs. Community forums + hardware-comparison references. Plugin-driven extension (stream music services, internet radio).

Use cases: (a) **keep Squeezebox hardware alive** after Logitech EOL (b) **whole-home audio via Squeezeboxes** (c) **RPi as LMS host** feeding Squeezelite players (d) **legacy-hardware music ecosystem** (e) **streaming music services aggregator** (f) **internet radio hub** (g) **multi-room audio** (h) **retro-audio enthusiast central server**.

Features (per README):

- **Streaming audio server** for Squeezebox + emulators
- **Perl** — cross-platform
- **Plugin ecosystem** (streaming services, internet radio)
- **Community-continued** after Logitech EOL
- **Runs on**: Linux, macOS, Solaris, Windows, NAS, RPi
- **Docker + ghcr.io**

- Upstream repo: <https://github.com/LMS-Community/slimserver>
- Website/docs: <https://lyrion.org>
- Getting started: <https://lyrion.org/getting-started/>
- Hardware compat: <https://lms-community.github.io/players-and-controllers/hardware-comparison/>

## Architecture in one minute

- **Perl** server
- Local DB (SQLite)
- Serves multiple Squeezebox clients
- Plugin-driven
- **Resource**: low
- **Port**: HTTP (9000 typical) + SlimProto client port

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker**         | Docker Hub / ghcr.io                                                                                                   | **Primary**                                                                                   |
| **Native**         | Linux/macOS/Solaris/Windows                                                                                            | Alt                                                                                   |
| **Distro pkg**     | Debian/RPM                                                                                                             | Alt                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Music library        | `/music`                                                    | Storage      | **RO mount recommended**                                                                                    |
| Players              | Squeezebox / Squeezelite                                    | Clients      | Discovery via SlimProto                                                                                    |
| Plugin creds         | Streaming-service tokens (optional)                         | Secret       |                                                                                    |

## Install via Docker

Per lyrion.org:
```yaml
services:
  lms:
    image: lmscommunity/lyrionmusicserver:latest        # **pin**
    ports:
      - "9000:9000"
      - "9090:9090"
      - "3483:3483"
      - "3483:3483/udp"
    volumes:
      - /music:/music:ro        # **RO**
      - ./lms-config:/config
    restart: unless-stopped
```

## First boot

1. Start
2. Browse UI on :9000
3. Scan music library
4. Power on Squeezebox / Squeezelite clients — auto-discovered
5. Install plugins (streaming services, radio)
6. Configure rooms/players
7. Back up `/config`

## Data & config layout

- `/config/` — DB (library index, favorites, settings, plugin-state)
- `/music/` — source music (RO)

## Backup

```sh
sudo tar czf lms-$(date +%F).tgz lms-config/
# Contains: library index, plugin credentials (streaming services)
```

## Upgrade

1. Releases: <https://github.com/LMS-Community/slimserver/releases>
2. Docker pull + restart
3. Watch for plugin compat breaking changes

## Gotchas

- **201st HUB-OF-CREDENTIALS Tier 3 — MUSIC-LIBRARY-INDEX + STREAMING-SERVICE-TOKENS**:
  - Holds: library index, streaming-service tokens (Spotify/Tidal/etc. via plugins), preferences
  - **201st tool in hub-of-credentials family — Tier 3**
- **COMMUNITY-FORK-AFTER-DISCONTINUATION**:
  - Logitech discontinued official SqueezeCenter
  - Community continued as Lyrion
  - Historic name chain: SliMP3 → SlimServer → SqueezeCenter → SqueezeboxServer → Logitech Mediaserver → Lyrion
  - **Community-fork-after-original-discontinuation: 2 tools** (Statping-ng + Lyrion) 🎯 **2-MILESTONE**
- **PERL-BACKEND**:
  - Rare in modern catalog
  - **Perl-backend: 2 tools** (SmokePing + Lyrion) 🎯 **2-MILESTONE**
- **LEGACY-HARDWARE-ECOSYSTEM-PRESERVATION**:
  - Hardware from ~2005-2012 still works
  - **Recipe convention: "legacy-hardware-ecosystem-preservation positive-signal"**
  - **NEW positive-signal convention** (Lyrion 1st formally)
- **MULTI-GENERATION-PROJECT-RENAMING**:
  - 6 historical names
  - **Multi-generation-fork-lineage: 2 tools** (Medusa+Lyrion) 🎯 **2-MILESTONE**
- **SLIMPROTO-CUSTOM-PROTOCOL**:
  - Custom TCP protocol for Squeezebox clients
  - **Recipe convention: "custom-hardware-protocol-dedicated-ports neutral-signal"**
  - **NEW neutral-signal convention** (Lyrion 1st formally)
- **PLUGIN-ECOSYSTEM**:
  - **Plugin-API-architecture: 7 tools** 🎯 **7-MILESTONE** (+Lyrion)
- **CROSS-PLATFORM-PERL**:
  - Perl runs everywhere
  - **Cross-platform-server-tool: 3 tools** (Cloud Commander+Diskover+Lyrion) 🎯 **3-MILESTONE**
- **MULTI-ARCH-DOCKER**:
  - **Multi-arch-Docker-image: 4 tools** 🎯 **4-MILESTONE** (+Lyrion)
- **DECADE-PLUS-OSS** (deep):
  - SliMP3 dates to ~2001. Two-decade+ OSS with multiple generations.
  - **Decade-plus-OSS: 18 tools** 🎯 **18-MILESTONE** (+Lyrion)
  - **Two-decade-plus-OSS: 3 tools** (Review Board+sabre/dav+Lyrion) 🎯 **3-MILESTONE**
- **INSTITUTIONAL-STEWARDSHIP**: LMS-Community org + lyrion.org + multi-arch Docker + community-rescue-fork + 20+ year project + hardware-preservation ethos. **187th tool — community-rescue-continuation-steward sub-tier** (NEW-soft).
- **TRANSPARENT-MAINTENANCE**: active + releases + docs + community-rescued + multi-arch. **193rd tool in transparent-maintenance family.**
- **MUSIC-SERVER-HARDWARE-CATEGORY:**
  - **Lyrion/LMS** — Squeezebox ecosystem preservation
  - **Roon** — commercial; high-end
  - **Navidrome** — Subsonic-compat
  - **Volumio / moOde** — RPi-audio-appliance
- **ALTERNATIVES WORTH KNOWING:**
  - **Navidrome** — if you don't have Squeezebox hardware
  - **Volumio** — if you want turnkey RPi audio
  - **Choose Lyrion if:** you have Squeezebox hardware + want to keep it alive.
- **PROJECT HEALTH**: active community + multi-arch + 20+ year project + rescue-ethos. Exceptional.

## Links

- Repo: <https://github.com/LMS-Community/slimserver>
- Website: <https://lyrion.org>
- Navidrome (alt): <https://github.com/navidrome/navidrome>
- Squeezelite: <https://github.com/ralph-irving/squeezelite>
