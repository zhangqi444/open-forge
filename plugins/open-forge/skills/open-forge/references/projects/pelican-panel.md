---
name: Pelican Panel
description: "Open-source game server control panel. Docker-container isolation per game; extensive Eggs library (Minecraft/Palworld/Rust/ARK/etc). Wings node-agent. PHP/Laravel. Pterodactyl-fork/successor. pelican-dev org. Website + Docs + Discord."
---

# Pelican Panel

Pelican Panel is **"Pterodactyl — but re-energized and actively maintained"** — an open-source game-server management panel. Deploy, configure, manage **Minecraft, Palworld, ARK, Rust, Factorio, Terraria, 7 Days to Die, Counter-Strike, GTA, Valheim, DayZ, etc.** as Docker-isolated containers. Real-time resource monitoring. Extensive "Eggs" library (recipes per-game). Wings node-agent runs game containers.

Built + maintained by **pelican-dev** org. Active. Discord; website; docs. Active fork/successor of Pterodactyl.

**Companion**: **Wings** — <https://github.com/pelican-dev/wings> — the agent that runs on game-server hosts.

Use cases: (a) **Minecraft multi-server management** (b) **Palworld/ARK/Rust hosting business** (c) **LAN-party game hosting** (d) **game-server-as-a-service** (e) **community-game-hosting** (f) **hosting company admin-panel** (g) **per-user game-subscription** (h) **isolated game-instances with resource-limits**.

Features (per README):

- **Docker-container isolation** per game-server instance
- **Real-time resource monitoring**
- **Extensive game support** via "Eggs" recipes
- **Web-based management**
- **Wings node-agent architecture** — panel + nodes

Supported games (partial):
- **Minecraft**: Paper, Sponge, Bungeecord, Waterfall
- **SteamCMD**: 7 Days to Die, ARK, Arma 3, CS, DayZ, Enshrouded, L4D, Palworld, Project Zomboid, Satisfactory, Sons of the Forest, Starbound
- **Standalone**: Among Us, Factorio, FTL, GTA, KSP, Mindustry, Rimworld, Terraria
- **Bots/Voice/Software/DB/Programming** categories

- Upstream repo: <https://github.com/pelican-dev/panel>
- Wings: <https://github.com/pelican-dev/wings>
- Website: <https://pelican.dev>
- Docs: <https://pelican.dev/docs>
- Discord: <https://discord.gg/pelican-panel>

## Architecture in one minute

- **PHP/Laravel** panel (web UI + API)
- **MySQL/MariaDB** or PostgreSQL DB
- **Redis** for cache + queues
- **Wings** (Go) agent — per node; manages Docker containers
- **Nginx + PHP-FPM** web
- **Docker** on each Wings node
- **Resource**: panel = ~500MB-1GB; each game container = varies wildly

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker Compose** | **Panel + Wings separate**                                      | **Primary**                                                                        |
| **Native**         | Per-component                                                                                                          | Alt                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Panel domain         | `panel.example.com`                                         | URL          | TLS                                                                                    |
| Wings node domains   | `node1.example.com`                                         | URL          | TLS; daemon-port                                                                                    |
| MySQL/Postgres       | Panel DB                                                    | DB           |                                                                                    |
| Redis                | Cache + queue                                               | Infra        |                                                                                    |
| SSL certs            | Let's Encrypt                                               | TLS          | Must be TLS                                                                                    |
| Admin creds          | First-boot                                                  | Bootstrap    | Strong                                                                                    |
| Per-server allocations | IP + port per game                                        | Network      |                                                                                    |

## Install via Docker

See <https://pelican.dev/docs/>. Architecture: Panel + Wings separated (typically on different hosts for security).

Panel:
```yaml
services:
  panel:
    image: ghcr.io/pelican-dev/panel:latest        # **pin**
    ports: ["80:80", "443:443"]
    depends_on: [mariadb, redis]
    # See docs for full compose

  mariadb:
    image: mariadb:11
    environment:
      MARIADB_ROOT_PASSWORD: ${DB_ROOT_PASSWORD}

  redis:
    image: redis:7
```

Wings (on each game-host node):
```yaml
services:
  wings:
    image: ghcr.io/pelican-dev/wings:latest        # **pin**
    privileged: true
    network_mode: host
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - /var/lib/pterodactyl:/var/lib/pterodactyl
      # ... additional per docs
```

## First boot

1. Deploy panel + DB
2. Create admin
3. Create node record for each Wings host
4. Install + configure Wings on each host (config pulled from panel)
5. Create first game server — pick egg, allocate port
6. Start server; verify container runs + port open
7. Put behind TLS (BOTH panel AND Wings)
8. Back up PG/MariaDB + Wings config

## Data & config layout

- **Panel**: MariaDB DB + Redis + Laravel logs
- **Wings**: `/var/lib/pterodactyl/volumes/` per game server + config.yml

## Backup

```sh
docker compose exec mariadb mysqldump ... > panel-$(date +%F).sql
# Wings: rsync /var/lib/pterodactyl (HUGE — game data)
# Wings config.yml — ENCRYPT (contains panel-node-token)
```

## Upgrade

1. Releases: <https://github.com/pelican-dev/panel/releases>
2. Panel + Wings versions must be compatible
3. DB migrations auto
4. Upgrade Wings AFTER panel usually

## Gotchas

- **144th HUB-OF-CREDENTIALS CROWN-JEWEL TIER 1 — GAME-HOSTING-INFRA-CREDS**:
  - Panel: all game-server configs, admin tokens, user billing, Wings-node-tokens
  - Wings: Docker-privileged access, root-equivalent on node
  - **144th tool in hub-of-credentials family — Tier 1 CROWN-JEWEL**
  - **NEW CROWN-JEWEL Tier 1 sub-category: "game-server-control-panel + privileged-node-agent"** (1st — Pelican)
  - **CROWN-JEWEL Tier 1: 44 tools / 41 sub-categories**
- **WINGS-RUNS-PRIVILEGED + DOCKER-SOCKET**:
  - Wings requires `privileged: true` AND `docker.sock` access
  - This is a MEGA-privileged setup — Wings node compromise = host root
  - **Recipe convention: "privileged-mode-container-host-root-equivalent callout"**
  - **NEW recipe convention** (Pelican 1st formally) — HIGHEST-severity
  - **Docker-socket-mount-privilege-escalation: 7 tools** (+Pelican-Wings) 🎯 **7-TOOL MILESTONE**
- **NODE-TOKEN-LEAKAGE**:
  - Wings config contains token to register with panel
  - Leaked token = panel-takeover vector
  - **Recipe convention: "node-registration-token-secrecy callout"**
  - **NEW recipe convention** (Pelican 1st formally)
- **PTERODACTYL-FORK/SUCCESSOR**:
  - Forked from Pterodactyl due to maintenance concerns
  - Active fork-opportunity-for-abandoned-OSS pattern (113 Astuto parallel)
  - **Fork-of-prior-OSS: 1 tool** 🎯 **NEW FAMILY** (Pelican-from-Pterodactyl)
- **"EGGS" AS PACKAGE-REPOS**:
  - Community-curated game-recipes
  - Trust-model: anyone can submit
  - **Recipe convention: "community-egg-recipes-trust-review callout"**
  - **NEW recipe convention** (Pelican 1st formally)
- **PANEL + WINGS SEPARATE-HOST DEPLOY**:
  - Best practice: panel on one host, Wings on game-hosts
  - Reduces blast-radius
  - **Recipe convention: "split-control-plane-data-plane positive-signal"**
  - **NEW positive-signal convention** (Pelican 1st formally)
- **GAME-ABUSE-POTENTIAL**:
  - Multi-user hosting = moderation workload
  - Games can host cheaters, illegal content (GTA mods), etc.
  - **Recipe convention: "multi-tenant-game-hosting-abuse-mitigation callout"**
  - **NEW recipe convention** (Pelican 1st formally)
- **INSTITUTIONAL-STEWARDSHIP**: pelican-dev org + Discord + website + docs + active-fork + multi-repo (Panel + Wings + eggs) + revived-OSS. **130th tool 🎯 130-TOOL MILESTONE — revived-fork sub-tier** (NEW-soft).
- **TRANSPARENT-MAINTENANCE**: active + Discord + website + docs + multi-repo + releases + eggs-community. **136th tool in transparent-maintenance family.**
- **GAME-PANEL-CATEGORY:**
  - **Pelican Panel** — active Pterodactyl-revived fork
  - **Pterodactyl** — original; less-active
  - **AMP** (commercial) — paid, feature-rich
  - **Crafty Controller** — Minecraft-only
- **ALTERNATIVES WORTH KNOWING:**
  - **Crafty Controller** — if Minecraft-only + simpler
  - **AMP** — if you want commercial-supported
  - **Choose Pelican if:** you want active + multi-game + Pterodactyl-successor.
- **PROJECT HEALTH**: active fork + revived + Discord + website + Wings-separate-repo. Strong.

## Links

- Repo: <https://github.com/pelican-dev/panel>
- Wings: <https://github.com/pelican-dev/wings>
- Website: <https://pelican.dev>
- Discord: <https://discord.gg/pelican-panel>
- Pterodactyl (predecessor): <https://github.com/pterodactyl/panel>
