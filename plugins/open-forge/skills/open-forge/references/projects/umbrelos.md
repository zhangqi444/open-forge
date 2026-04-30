---
name: umbrelOS
description: Beautiful home-server OS for self-hosting, with app store of 100+ curated self-hosted apps (Immich, Jellyfin, Home Assistant, Bitcoin node, Nextcloud, etc.). Flashable OS image, not a Docker app. PolyForm Noncommercial (commercial use requires license).
---

# umbrelOS

umbrelOS is a full **operating system** — not a Docker container — optimized for running self-hosted apps on a home server with a slick, App-Store-like UX. You install it by flashing it to disk (like installing Ubuntu), and then browse a catalog of 100+ curated apps that install with a single click.

- **Full OS** — Debian-based; replaces the host OS entirely
- **App Store** — 100+ curated apps with one-click install
- **Web UI** — home-screen grid of your installed apps (mobile + desktop)
- **Remote access** — Tailscale integration for accessing from anywhere
- **Bitcoin/Lightning first-class** — Umbrel's origin was as a Bitcoin node OS; BTC/LN stack is polished
- **Apps include**: Immich, Jellyfin, Home Assistant, Nextcloud, Bitwarden, PhotoPrism, NextcloudPi, Plex, Transmission, SearXNG, Gitea, Mastodon, Matrix, LLM (Ollama), Pi-hole, and many more

**Target hardware**:

- **Umbrel Pro** / **Umbrel Home** — commercial hardware with first-class support + all features
- **Raspberry Pi 5** — supported, community-tested
- **x86 systems** (any mini-PC, old laptop, NAS hardware) — free, core features only, best-effort support

- Upstream repo: <https://github.com/getumbrel/umbrel>
- Website: <https://umbrel.com>
- App store (browsable): <https://apps.umbrel.com>
- Umbrel Pro / Home: <https://umbrel.com/umbrel-pro> / <https://umbrel.com/umbrel-home>
- Raspberry Pi install: <https://github.com/getumbrel/umbrel/wiki/Install-umbrelOS-on-a-Raspberry-Pi-5>
- x86 install: <https://github.com/getumbrel/umbrel/wiki/Install-umbrelOS-on-x86-systems>

## Architecture in one minute

- **umbrelOS** = Debian 12 + custom system services + Docker + a web dashboard
- **Apps** install as Docker containers orchestrated by `umbreld` (the Umbrel daemon)
- **Each app** has a manifest (`umbrel-app.yml`) + a docker-compose file
- **Home screen** is a Next.js SPA
- **Community App Store** — you can add third-party app store repos (git URLs) for apps not in the official store
- **Port 80** (or 443 if exposed) — serves the dashboard
- **Tailscale** — integrated for remote access; activated via toggle in UI

**NOT a "install on top of my existing Linux" thing**. It's a full OS image.

## Compatible install methods

| Hardware              | Install path                                                                |
| --------------------- | --------------------------------------------------------------------------- |
| Umbrel Pro            | Pre-installed; flash with USB if reinstalling                                 |
| Umbrel Home           | Pre-installed; flash with USB if reinstalling                                 |
| **Raspberry Pi 5**    | Flash to SD card or USB with Raspberry Pi Imager → boot                       |
| **x86 mini-PC / NAS** | Flash to USB stick → boot → install to internal drive                         |
| **VM** (Proxmox, VirtualBox, etc.) | Boot the x86 ISO; **supported but not officially blessed**     |
| **Other SBCs** (Pi 4, Rock Pi, etc.) | **NOT SUPPORTED** by official builds (old Umbrel-1.x forks exist)  |

## Inputs to collect

| Input              | Example                       | Phase     | Notes                                                         |
| ------------------ | ----------------------------- | --------- | ------------------------------------------------------------- |
| Target storage     | internal SSD / external USB    | Hardware  | Internal drive recommended for prod                              |
| RAM                | 4 GB min, 8-16 GB recommended   | Hardware  | Many apps; 16 GB is comfortable                                  |
| CPU                | x86_64 or ARM64                 | Hardware  | 64-bit only                                                      |
| Network            | wired Ethernet recommended      | Network   | Wi-Fi supported but wired is faster/more reliable                 |
| Admin user         | created via web wizard          | Bootstrap | First visit to `umbrel.local` — set name + strong password       |
| Tailscale (opt.)   | Tailscale account               | Remote    | For off-LAN access                                                |

## Install on x86 (general self-hosting)

1. Download ISO: <https://umbrel.com/download>
2. Flash to USB: `dd if=umbrelos.iso of=/dev/sdX bs=4M status=progress` (or use balenaEtcher / Rufus)
3. Boot target machine from USB
4. **Installer** — pick target disk → install to internal drive (**wipes disk**)
5. Reboot → remove USB
6. Find the machine at `umbrel.local` on your LAN OR by IP
7. Web wizard — create admin account

## Install on Raspberry Pi 5

1. Raspberry Pi Imager → "Other general-purpose OS" → umbrelOS
2. Flash to microSD card or SSD
3. Insert, boot, find at `umbrel.local`

## Post-install

1. **App Store** → browse / install apps
2. **Settings → Tailscale** → enable for remote access (optional)
3. **Settings → External storage** → attach USB drives for media (Jellyfin, PhotoPrism)
4. **Bitcoin node** (if desired) — pick Bitcoin Core app → installs the full node + Lightning optional

## Data & config layout

Inside umbrelOS (hidden from most users):

- `/home/umbrel/umbrel/` — Umbrel root
  - `app-data/` — per-app state (each app's DB, config, files)
  - `app-stores/` — cloned app store git repos
  - `apps/` — installed app definitions (docker-compose + manifests)
  - `logs/`
  - `umbreld.log`

Each app is a subdirectory; inspect with `cd /home/umbrel/umbrel/app-data/<appname>`.

## Backup

Umbrel's official backup path (as of recent umbrelOS versions):

1. **Settings → Backups → Enable backups**
2. Provide a backup destination: USB drive, another Umbrel, or S3-compatible storage
3. Automatic periodic backups of app-data

Manual backup (SSH into umbrelOS, requires admin):

```sh
ssh umbrel@umbrel.local
sudo tar czf /mnt/external/umbrel-backup-$(date +%F).tgz \
  --exclude=app-data/*/cache \
  /home/umbrel/umbrel/app-data
```

**Per-app backup discipline** is essential — some apps (Immich, Nextcloud) have their own export/backup flows you should use for important data.

## Upgrade

- **umbrelOS core**: Settings → Software Updates → check + install. Upgrades are seamless (atomic; rollback if fails).
- **Apps**: App Store → Updates tab → per-app update. Apps can also auto-update (setting).
- **Bitcoin-related apps** have specific upgrade paths — read release notes before upgrading during an actively-syncing period.
- Release notes: <https://github.com/getumbrel/umbrel/releases>.

## Gotchas

- **PolyForm Noncommercial license** (for umbrelOS 1.0+, changed from MIT) — **free for personal use**, but **commercial deployment requires a paid license**. Not an "open source" license in the OSI sense. Historical versions are MIT.
- **Commercial license required** for:
  - Offering umbrelOS-based hardware for sale
  - Running umbrelOS to operate a business
  - Any revenue-generating use
  Contact Umbrel for pricing. For personal / family / friends use, it's free.
- **Not a drop-in replacement for Linux** — it's a purpose-built home-server OS. Install umbrelOS and you lose your existing OS. Plan accordingly.
- **Hardware "tiers" of support**:
  - **Umbrel Pro/Home**: all features, first-class support
  - **Pi 5 / x86 DIY**: core works, some features may lag, community-supported
  - Old Pi 4 / Pi 3 / other SBCs: **community forks of old umbrelOS 0.x** exist but aren't maintained
- **Tailscale** integration is a big unlock — it means your phone + laptop reach Umbrel anywhere without port forwarding, DDNS, or reverse proxies.
- **Port exposure to internet** is discouraged — Umbrel's model is "access via Tailscale or LAN." If you want public access, set up your own reverse proxy + auth; Umbrel's built-in apps don't assume internet exposure.
- **App Store security** — official apps are reviewed by Umbrel team. Third-party app stores (community repos) are NOT audited — add only from trusted sources.
- **Updates auto-install** by default — can be disabled in Settings if you want manual control.
- **Data on external USB drive**: umbrelOS exposes `/external/` mount; apps like Immich/Jellyfin can store their data there instead of the internal drive. Recommended if installing on Pi 5 with limited internal storage.
- **Recovery mode**: if umbrelOS won't boot, the installer USB has a recovery option.
- **SSH access**: port 22, user `umbrel`, password = your UI admin password. Good for poking at apps; be careful.
- **Non-Umbrel self-hosting distros** are alternatives:
  - **CasaOS** — similar concept, MIT license, community-curated
  - **Unraid** — commercial, NAS-focused, very mature; $$ for license
  - **TrueNAS SCALE** — NAS + apps via Docker/Kubernetes
  - **Yunohost** — Debian-based self-hosting distro, Apache-2.0
  - **HexOS** — newer, TrueNAS-based with nicer UX
  - **Runtipi** — lighter, more DIY
  - **Cosmos Server** — Go-based app catalog + reverse proxy
  - **Proxmox VE** — VM host; run separate LXC/VM for each app (more control, more admin overhead)

## Links

- Repo: <https://github.com/getumbrel/umbrel>
- Website: <https://umbrel.com>
- App store: <https://apps.umbrel.com>
- Download: <https://umbrel.com/download>
- Raspberry Pi install: <https://github.com/getumbrel/umbrel/wiki/Install-umbrelOS-on-a-Raspberry-Pi-5>
- x86 install: <https://github.com/getumbrel/umbrel/wiki/Install-umbrelOS-on-x86-systems>
- Pro vs DIY comparison: <https://github.com/getumbrel/umbrel/wiki/umbrelOS-on-Umbrel-Home-vs.-DIY>
- Releases: <https://github.com/getumbrel/umbrel/releases>
- Discord: <https://discord.gg/efNtFzqtdx>
- Community forum: <https://community.umbrel.com>
- r/getumbrel: <https://reddit.com/r/getumbrel>
- Building your own app: <https://github.com/getumbrel/umbrel-apps>
- License (PolyForm Noncommercial 1.0.0): <https://polyformproject.org/licenses/noncommercial/1.0.0/>
