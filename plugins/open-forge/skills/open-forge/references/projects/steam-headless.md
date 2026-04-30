---
name: Steam Headless
description: "Unofficial headless remote Steam server in Docker. Debian Trixie + Xfce + noVNC + Moonlight. GPU pass-through (NVIDIA/AMD/Intel). Flatpak/Appimage; Heroic/Lutris/EmuDeck. Steam Remote Play / Moonlight streaming. Check license."
---

# Steam Headless

Steam Headless is **"GeForce NOW / Steam Cloud — but self-hosted + headless + Docker"** — a Docker container packaging a **Steam client on Debian + Xfce4 + noVNC + Moonlight server** for remote game streaming. Play your games via: (a) web-browser noVNC (b) Moonlight app (c) Steam Link (d) Steam Remote Play. Supports **NVIDIA / AMD / Intel GPU pass-through**. Easy install of EmuDeck + Heroic + Lutris via Flatpak. Full controller support.

Built + maintained by **Josh Sunnex (joshstar)** + Steam-Headless org + community. License: check repo. Active; based on Debian Trixie; comprehensive docs; Unraid + Ubuntu + Docker Compose install paths.

Use cases: (a) **cloud-gaming-at-home** — thin clients stream from beefy gaming PC (b) **GPU-server sharing** — one GPU; many streaming clients (c) **play on Mac/Linux** games available only on Windows-via-Proton (d) **travel gaming** — Moonlight from laptop → home gaming PC (e) **multi-launcher unification** — Steam + Heroic + Lutris + EmuDeck in one container (f) **SteamOS-without-hardware** — SteamOS-like environment in Docker (g) **family gaming server** — kids stream from shared GPU (h) **emulation hub** — EmuDeck + all-in-one.

Features (per README):

- **Steam client on Linux + Proton** (Debian Trixie)
- **Moonlight-compatible server** (NVIDIA GameStream-compatible protocol)
- **Heroic Games Launcher / Lutris / EmuDeck** via Flatpak
- **Full noVNC web access** to Xfce4 desktop
- **NVIDIA / AMD / Intel GPU** support
- **Controller pass-through**
- **Root access** to the container
- **Flatpak + AppImage** install-methods
- **Auto-start apps** (Steam auto-starts)

- Upstream repo: <https://github.com/Steam-Headless/docker-steam-headless>
- Docker-compose docs: <https://github.com/Steam-Headless/docker-steam-headless/blob/master/docs/docker-compose.md>
- Unraid docs: <https://github.com/Steam-Headless/docker-steam-headless/blob/master/docs/unraid.md>
- Ubuntu docs: <https://github.com/Steam-Headless/docker-steam-headless/blob/master/docs/ubuntu-server.md>

## Architecture in one minute

- **Debian Trixie** inside container
- **Xfce4** desktop + **noVNC** for web-view
- **PulseAudio** for audio
- **Sunshine / moonlight-server** for GameStream protocol
- **X server** (or host X passthrough via `MODE=secondary`)
- **Resource**: VERY HEAVY — GPU + 8-16GB RAM + large disk for games (100-500GB+)
- **Ports**: noVNC (8083), Sunshine (various), Steam Remote Play (27031-27036 UDP + 27015 TCP)

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker Compose** | **On gaming-capable host (GPU)**                                | **Primary**                                                                        |
| **Unraid**         | **Upstream template**                                            | **Very popular — Unraid homelabs**                                                                        |
| **Ubuntu Server**  | **Upstream docs**                                                | Bare Ubuntu + Docker                                                                                   |
| **TrueNAS Scale**  | Supported but less-documented                                                                            |                                                                                    |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| GPU                  | NVIDIA / AMD / Intel                                        | Hardware     | **MANDATORY**                                                                                    |
| GPU driver           | Host + container drivers matching                                                                                                         | Hardware     |                                                                                    |
| Steam account        | **Your Steam credentials**                                  | Auth         | **Stored in container**                                                                                    |
| Games library path   | `/mnt/games` recommended                                    | Storage      | LARGE — TBs for heavy library                                                                                    |
| `DISPLAY` + `MODE`   | `:0` + `secondary` if host-X passthrough                                                                                                  | Display      |                                                                                    |
| Network mode         | Custom bridge OR host (Steam Remote Play needs LAN-visibility)                                                                                                                          | Network      |                                                                                    |
| Port forwards        | Moonlight / Sunshine                                                                                                            | Network      |                                                                                                                                            |
| Controller pass-through | USB device mapping                                                                                                                        | Hardware     |                                                                                                                                            |

## Install via Docker Compose

Follow: <https://github.com/Steam-Headless/docker-steam-headless/blob/master/docs/docker-compose.md>

```yaml
# High-level shape — see upstream for full example:
services:
  steam-headless:
    image: josh5/steam-headless:latest        # **pin version in prod**
    privileged: true                           # Often required for GPU + audio + controllers
    ipc: host
    shm_size: "2g"
    environment:
      - TZ=America/Los_Angeles
      - USER_LOCALES=en_US.UTF-8
      - MODE=primary
      - WEB_UI_ENABLED=true
      - ENABLE_STEAM=true
    volumes:
      - /opt/steam-headless/home:/home/default
      - /mnt/games:/mnt/games                   # Your game library
    devices:
      - /dev/dri:/dev/dri                       # AMD/Intel GPU
      # - /dev/nvidia0, etc. for NVIDIA
    ports:
      - "8083:8083"                             # noVNC
      # Sunshine + Moonlight ports per docs
```

## First boot

1. Provision gaming-capable host (GPU + drivers + Docker)
2. Install host GPU drivers (NVIDIA/AMD/Intel)
3. Deploy compose; wait for container init (first-boot takes minutes)
4. Browse `:8083` noVNC → log into Steam + launch
5. Moonlight client: scan for host → connect
6. Steam Remote Play: mark as LAN-visible (ensure `network_mode: host` or same-LAN)
7. Configure controllers (see Xfce settings)
8. Install additional launchers (Heroic/Lutris) via WebUI → Applications

## Data & config layout

- `/home/default/` — desktop user home; Steam state
- Games library mount point (`/mnt/games`)
- `~/init.d/` — custom startup scripts (auto-run on boot)
- **Everything outside home-dir is ephemeral** (per README)

## Backup

```sh
# Steam has cloud-save; your Steam account owns game progress
# Back up home-dir for custom settings:
sudo tar czf steam-headless-home-$(date +%F).tgz /opt/steam-headless/home
# Games library = separate; typically NOT backed-up (re-downloadable from Steam)
```

## Upgrade

1. Releases: <https://github.com/Steam-Headless/docker-steam-headless/releases>. Active.
2. Docker pull + restart
3. **Changes outside home-dir are wiped on update** (per README)

## Gotchas

- **STEAM CREDENTIALS IN CONTAINER**:
  - Steam account + 2FA state stored in container
  - Compromise of container / volume = Steam account theft
  - **CROWN-JEWEL RISK**: Steam account tied to payment, games library, credit-card
  - **75th tool in hub-of-credentials family — Tier 1 CROWN-JEWEL**
  - **NEW CROWN-JEWEL Tier 1 sub-category: "game-platform-account-as-payment-hub"** — 1st tool named (Steam Headless)
  - **CROWN-JEWEL Tier 1: 16 tools; 15 sub-categories**
- **ROOT-ACCESS CONTAINER + PRIVILEGED = HOST COMPROMISE RISK**:
  - README mentions "Root access" as a feature
  - `privileged: true` typical
  - Container escape → root on host
  - **Recipe convention: "privileged-container-host-compromise-risk" callout**
  - **NEW recipe convention** (Steam Headless 1st)
- **GPU PASSTHROUGH = KERNEL-LEVEL-TRUST**:
  - Host GPU drivers, container GPU drivers
  - Attack surface: GPU driver bugs reach host kernel
  - **Recipe convention: "GPU-driver-kernel-trust-boundary" callout**
- **STEAM'S ANTI-CHEAT SYSTEMS**:
  - Some games' anti-cheat (EAC, BattlEye) detect Linux/Proton and may reject
  - Proton-compatible lists: protondb.com
  - **Recipe convention: "anti-cheat-Linux-compatibility" callout** for gaming-tools
  - **NEW recipe convention**
- **LICENSE / TOS-COMPLIANCE**:
  - Steam TOS permits running on Linux (officially via Steam for Linux)
  - Running headless + multiple-clients on one account = GRAY AREA (Steam generally permits ONE active client per account)
  - **Concurrent Steam sessions on same account may conflict** (Steam kicks first login)
  - **Recipe convention: "one-active-client-per-Steam-account" callout**
- **GAMES LIBRARY STORAGE**:
  - Each game: 10-100GB
  - Full library: multiple-TBs
  - Plan storage accordingly
  - **Recipe convention: "TB-scale-storage-requirement" callout**
- **NETWORK MODE MATTERS**:
  - Custom bridge = games work; Steam Remote Play may not (Steam thinks you're remote)
  - Host mode = Steam Remote Play works; port-conflicts possible
  - **Recipe convention: "network-mode-steam-remote-play-tradeoff" callout**
- **MOONLIGHT = OPEN-PROTOCOL NVIDIA GAMESTREAM-COMPATIBLE**:
  - Sunshine + Moonlight = OSS equivalent to NVIDIA GameStream (discontinued)
  - Low-latency; hardware-encoded streaming
  - **Recipe convention: "Moonlight-Sunshine-streaming positive-signal"**
- **HARDWARE-DEPENDENT-TOOL CATEGORY EXTENDED**:
  - Steam Headless requires GPU (**NVIDIA/AMD/Intel**)
  - **2nd tool in hardware-dependent-tool category** (Willow 101 = always-on-mic; Steam Headless = GPU)
  - **Hardware-dependent-tool: 2 tools**
- **UNOFFICIAL = NO STEAM OFFICIAL SUPPORT**:
  - README explicitly says "Unofficial headless remote Steam server"
  - Steam / Valve don't sanction this use-case
  - If issues: no Steam support; community-only
  - **Recipe convention: "unofficial-vendor-wrapping-headless-tool" callout**
  - **NEW recipe convention**
- **EPHEMERAL-FILESYSTEM-OUTSIDE-HOMEDIR**:
  - README: "All files that are store outside your home directory are not persistent and will be wiped if there is an update"
  - Classic Docker container-ephemerality
  - Mount anything-to-keep under `/home/default` or explicit volume
  - **Recipe convention: "home-dir-only-persistent" callout**
- **INSTITUTIONAL-STEWARDSHIP**: joshstar + Steam-Headless org + community. **61st tool — sole-maintainer-with-community sub-tier (30th tool).**
- **TRANSPARENT-MAINTENANCE**: active + multi-OS docs + Unraid template + Ubuntu docs + Debian-Trixie-base. **69th tool in transparent-maintenance family.**
- **GAME-STREAMING-CATEGORY:**
  - **Steam Headless** — Docker + Steam + Moonlight + multi-launcher
  - **Sunshine** (standalone) — Moonlight-server; install on host
  - **Parsec** (commercial) — proprietary streaming
  - **GeForce NOW** (commercial) — NVIDIA cloud gaming
  - **Shadow** (commercial) — cloud gaming service
  - **SteamOS** (official) — OS-level
  - **ChimeraOS** — SteamOS-alternative OS
  - **Bazzite** — gaming-focused OS
- **ALTERNATIVES WORTH KNOWING:**
  - **Sunshine** directly — if you don't need Docker wrapper + want direct-install
  - **ChimeraOS / Bazzite** — if you want gaming-OS (whole host)
  - **SteamOS** — if you have Steam Deck / want official
  - **Parsec** — commercial; polished UX
  - **Choose Steam Headless if:** you want Docker + multi-launcher + noVNC + comprehensive-package.
- **PROJECT HEALTH**: active + multi-OS docs + Debian-Trixie + Unraid-integration. Strong for niche gaming-tool.

## Links

- Repo: <https://github.com/Steam-Headless/docker-steam-headless>
- Sunshine: <https://github.com/LizardByte/Sunshine>
- Moonlight: <https://moonlight-stream.org>
- SteamOS: <https://store.steampowered.com/steamos>
- ChimeraOS: <https://chimeraos.org>
- Bazzite: <https://bazzite.gg>
- Heroic: <https://heroicgameslauncher.com>
- Lutris: <https://lutris.net>
- EmuDeck: <https://www.emudeck.com>
- ProtonDB: <https://www.protondb.com>
