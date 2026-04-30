---
name: DockSTARTer
description: "Bash-based interactive Docker deployment platform. Menu-driven selection of 100+ apps + variable prompts + compose generation. GhostWriters org + Open Collective funded + Discord + community. Targets home-lab users."
---

# DockSTARTer

DockSTARTer is **"Homelab-installer-wizard for Docker — but Bash + menu-driven + community-maintained"** — a tool to **quickly get up and running with Docker**. Menu-driven: pick apps (Plex, Sonarr, Radarr, Jellyfin, Home Assistant, ... 100+) → answer config prompts → DockSTARTer generates docker-compose + env files. Can be a **stepping stone** to learn Docker, or a **daily driver** for homelab operators.

Built + maintained by **GhostWriters org** + 100+ contributors + Open Collective funding + Discord. License: check LICENSE. Active; tests CI; Alpine/Debian/Ubuntu/Raspbian/Fedora/CentOS support.

Use cases: (a) **homelab-beginner on-ramp** — don't know Docker yet (b) **arr-stack installer** — Sonarr/Radarr/Plex quickly (c) **NAS-at-home ops** — RPi / Intel NUC setup (d) **stepping-stone** — learn Docker by seeing generated configs (e) **ops-documentation** — generated configs as starting point (f) **rapid-prototyping homelab setup** (g) **classroom / workshop intro to Docker** (h) **community-tested app-catalog** (aligned with LinuxServer.io ecosystem).

Features (per README):

- **Bash-based interactive menu**
- **100+ app-catalog**
- **Variable prompts** per app
- **Generated docker-compose** + `.env`
- **Config editor** UI (TUI)
- **CLI** mode for scripting
- **Multi-platform Linux support** (Alpine/Debian/Ubuntu/Raspbian/Fedora/CentOS)

- Upstream repo: <https://github.com/GhostWriters/DockSTARTer>
- Website: <https://dockstarter.com>
- Discord: <https://dockstarter.com/discord>

## Architecture in one minute

- **Bash** scripts
- **Interactive TUI** (whiptail / dialog)
- **Outputs**: `docker-compose.yml` + `.env` to `~/.docker/compose/`
- **No daemon** — runs on-demand

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Bash (native)**  | **Supported Linux distros**                                     | **Primary**                                                                        |
| **NOT Docker-ized** | Runs on host directly                                                                            | By design                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Host OS              | Alpine / Debian / Ubuntu / Raspbian / Fedora / CentOS       | Install      | Pick supported                                                                                    |
| Non-root sudo user   | Standard best-practice                                      | Install      |                                                                                    |
| Selected apps        | From menu                                                   | Config       |                                                                                    |
| Per-app variables    | Ports, data paths, passwords                                | Config       |                                                                                    |

## Install

Per README:
```sh
# Alpine:
sudo apk add curl git
bash -c "$(curl -fsSL https://get.dockstarter.com)"
sudo reboot
# Debian/Ubuntu/Raspbian:
sudo apt install -y curl git
bash -c "$(curl -fsSL https://get.dockstarter.com)"
sudo reboot
```

Then launch: `ds` menu.

## First boot

1. Install DockSTARTer
2. Launch `ds` menu
3. Select apps
4. Answer prompts (ports, paths, passwords)
5. DockSTARTer generates compose files
6. `docker compose up -d`
7. Access apps on configured ports
8. Iterate via `ds` menu

## Data & config layout

- `~/.docker/compose/` — generated configs
- `~/.config/.ds/` — DockSTARTer state
- Per-app data dirs as configured

## Backup

Generated configs live in `~/.docker/compose/`; Git-managed is a good practice.

## Upgrade

1. Releases: <https://github.com/GhostWriters/DockSTARTer/releases>. Active.
2. `ds update`
3. App-version updates managed per-container

## Gotchas

- **108th HUB-OF-CREDENTIALS TIER 2 — META-TOOL**:
  - DockSTARTer itself doesn't host creds persistently, BUT generates `.env` files with per-app passwords
  - The generated `.env` files are hub-of-credentials-of-homelab
  - DockSTARTer compromise → could inject malicious configs
  - **108th tool in hub-of-credentials family — Tier 2** (indirect; via generated outputs)
  - **Sub-family: "meta-tool-that-generates-creds-for-other-tools"** — NEW
  - **NEW sub-family: "meta-tool-generates-configs-with-credentials"** (1st — DockSTARTer)
- **BASH INSTALLER FROM curl | bash = CLASSIC SUPPLY-CHAIN RISK**:
  - `bash -c "$(curl -fsSL https://get.dockstarter.com)"` — trusts get.dockstarter.com
  - DNS / TLS compromise = code execution on install
  - **Recipe convention: "curl-pipe-bash installer supply-chain-risk" callout**
  - **NEW recipe convention** (DockSTARTer 1st formally) — applies to MANY tools
  - **Mitigation**: download script first, review, THEN execute
- **TARGETS NON-TECH USER-BASE**:
  - Homelab-beginners, non-DevOps
  - May not notice config errors
  - Hence TUI + menu-driven
- **COMMUNITY-CURATED APP-CATALOG**:
  - Which apps are in the catalog reflects community values
  - Depends on contributors' review-quality
  - **Recipe convention: "community-curated-app-catalog positive-signal"** (aligned with YunoHost 104; LinuxServer.io)
  - **NEW positive-signal convention** (DockSTARTer 1st formally)
- **GENERATED COMPOSE-CONFIGS ARE EDITABLE**:
  - Output is plain YAML
  - Users can graduate from menus to direct editing
  - **Recipe convention: "stepping-stone-to-direct-editing positive-signal"**
  - **NEW positive-signal convention** (DockSTARTer 1st; very rare)
- **OPEN COLLECTIVE FUNDING**:
  - Transparent finances
  - **Recipe convention: "Open-Collective-transparent-finances"** extended — 2 tools (Silex 106 + DockSTARTer) 🎯
- **MULTI-DISTRO LINUX SUPPORT**:
  - Alpine/Debian/Ubuntu/Raspbian/Fedora/CentOS
  - **Recipe convention: "multi-distro-support positive-signal"**
- **NOT-A-DOCKER-CONTAINER**:
  - DockSTARTer runs on host (Bash)
  - Unusual — most tools run in container
  - Pragmatic for installer-tool
  - **Recipe convention: "host-native-installer-tool"** — neutral
- **RPI / HOMELAB FIRST-CLASS**:
  - Raspbian explicitly supported
  - Signals homelab-friendliness
  - **Recipe convention: "Raspberry-Pi-first-class-support positive-signal"**
  - **NEW positive-signal convention** (DockSTARTer 1st formally)
- **INSTITUTIONAL-STEWARDSHIP**: GhostWriters org + 100+ contributors + Open Collective + Discord + community-driven. **94th tool — org-with-community-open-collective sub-tier** (reuses Silex+Open-Collective precedent).
- **TRANSPARENT-MAINTENANCE**: active + CI + Discord + Open Collective + 100+ contributors + website. **102nd tool in transparent-maintenance family.**
- **HOMELAB-SETUP-CATEGORY (adjacent):**
  - **DockSTARTer** — Bash + menus + Docker-compose output
  - **CasaOS** (prior batches) — full NAS OS with app-store
  - **YunoHost** (batch 104) — Debian-PaaS
  - **Umbrel / Start9 / Runtipi** — full OS
  - **HostingHelper** — simpler
  - **Portainer** — UI for Docker management
- **ALTERNATIVES WORTH KNOWING:**
  - **CasaOS** — if you want full OS + app-store UI
  - **Runtipi** — if you want app-store UI (Docker-based)
  - **YunoHost** — if you want Debian + web-apps
  - **Portainer** — if you want advanced Docker management
  - **Choose DockSTARTer if:** you want Bash + step-by-step + learn-as-you-go + not-forced-OS.
- **PROJECT HEALTH**: active + 100+ contributors + Open Collective + Discord + long-running. Strong.

## Links

- Repo: <https://github.com/GhostWriters/DockSTARTer>
- Website: <https://dockstarter.com>
- Discord: <https://dockstarter.com/discord>
- CasaOS (alt): <https://casaos.io>
- Runtipi (alt): <https://runtipi.io>
- YunoHost (batch 104): <https://yunohost.org>
