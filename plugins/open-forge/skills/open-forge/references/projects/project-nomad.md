---
name: project-nomad-project
description: Project N.O.M.A.D. (Node for Offline Media, Archives, and Data) recipe for open-forge. Apache 2.0 offline-first knowledge / education / survival server bundle, built as a management UI ("Command Center") + API that orchestrates a suite of containerized self-hosted apps via Docker. Bundles Kiwix (offline Wikipedia/books/ZIM files), Kolibri (Khan Academy courses), Ollama + Qdrant (local AI chat + RAG/semantic search), ProtoMaps (offline maps), CyberChef (data tools), FlatNotes (markdown notes), Dozzle (log viewer), + MySQL/Redis deps. Debian/Ubuntu-only install via bash installer script → `/opt/project-nomad` with systemd + docker compose. UI on :8080, Dozzle on :9999. Critical caveat - ZERO AUTH BY DESIGN (user quote: "intended to be open and available without hurdles"), explicitly "not designed to be exposed directly to the internet." Built for emergency/prepper/offline-classroom use cases on a beefy GPU-backed machine.
---

# Project N.O.M.A.D.

**N**ode for **O**ffline **M**edia, **A**rchives, and **D**ata — Apache 2.0 offline-first knowledge + education + AI server. Upstream: <https://github.com/Crosstalk-Solutions/project-nomad>. Website: <https://www.projectnomad.us>. Benchmark leaderboard: <https://benchmark.projectnomad.us>.

**Positioning:** a self-contained, offline-first "survival computer" / classroom-in-a-box / emergency knowledge server. Designed to be useful when the internet is gone — pre-cached Wikipedia, medical references, Khan Academy courses, offline maps, local LLMs, data analysis tools, markdown notes. Built by Crosstalk Solutions.

## What it actually is

N.O.M.A.D. is NOT a single app — it's a **Command Center** (management UI + API on :8080) that installs, configures, and updates a curated bundle of self-hosted containerized apps via Docker. You pick what to install from a catalog; N.O.M.A.D. handles the container orchestration for you.

| Capability | Backed by | Use case |
|---|---|---|
| Offline info library | Kiwix (serves ZIM files: Wikipedia, medical refs, survival guides, ebooks) | Emergency reference |
| AI chat + RAG | Ollama + Qdrant (semantic search over uploaded documents) | Ask-the-AI when offline |
| Education | Kolibri (Khan Academy courses, progress tracking, multi-user) | Home-school / disaster scenarios |
| Offline maps | ProtoMaps (downloadable regional maps) | Navigation without internet |
| Data tools | CyberChef (encoding, hashing, encryption) | "Cyber Swiss Army knife" |
| Notes | FlatNotes (markdown-based) | Local journaling / knowledge capture |
| Log viewer | Dozzle | Container logs via browser |
| Benchmark | Built-in | Hardware score + community leaderboard |

Additional built-in management tools: Wikipedia content selector, ZIM library manager, content explorer.

## ⚠️ Security model = NO AUTH BY DESIGN

Per upstream README verbatim: *"By design, Project N.O.M.A.D. is intended to be open and available without hurdles - it includes no authentication."*

Translation:

- Anyone who can reach :8080 can use the Command Center.
- Anyone on the LAN has full access to Kiwix, Kolibri, notes, AI, etc.
- Upstream explicitly says: *"N.O.M.A.D. is not designed to be exposed directly to the internet, and we strongly advise against doing so unless you really know what you're doing."*

**DO NOT put this on a public IP.** Use on a LAN / mesh VPN / physical-access-only device. A future release may add optional auth per the roadmap.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Install script (Debian-based only) | <https://raw.githubusercontent.com/Crosstalk-Solutions/project-nomad/main/install/install_nomad.sh> | ✅ Recommended | Typical install. |
| Docker Compose (advanced) | <https://raw.githubusercontent.com/Crosstalk-Solutions/project-nomad/main/install/management_compose.yaml> | ✅ | Users who want manual control. |
| Bare-metal / other OS | — | ❌ Not supported | Debian/Ubuntu only. |

Image: `ghcr.io/crosstalk-solutions/project-nomad:latest` (admin UI).

## Hardware requirements

Per upstream:

| Tier | Use case | Specs |
|---|---|---|
| **Minimum** | Barebones NOMAD management app only | 2 GHz dual-core, 4 GB RAM, 5 GB free, Debian-based |
| **Optimal** | AI tools + multiple LLMs | AMD Ryzen 7 / Intel i7+, 32 GB RAM, NVIDIA RTX 3060+ or AMD equiv, 250 GB SSD |

Unlike most "offline Raspberry Pi" projects, N.O.M.A.D. is NOT lightweight when AI is enabled. The management app is tiny; the content (ZIM files, AI models, course materials) is gigabytes-to-terabytes.

The Hardware Guide at <https://www.projectnomad.us/hardware> has $150 / $500 / $1,000+ build recommendations.

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "OS?" | Must be Debian/Ubuntu (recommended) | Hard requirement. Installer is apt-based. |
| preflight | "GPU?" | `AskUserQuestion`: `nvidia` / `amd` / `cpu-only` | Determines Ollama backend. |
| preflight | "Storage available?" | Min 5 GB for base; 250+ GB for AI + content | ZIM files + LLM weights are huge. |
| dns | "URL for admin UI?" | e.g. `http://<device-ip>:8080` | Baked into `URL` env var — replace "replaceme". |
| ports | "Admin port?" | Default `8080` | Command Center UI. |
| ports | "Dozzle port?" | Default `9999` | Log viewer. |
| secrets | "`APP_KEY`?" | ≥16 chars | Replace "replaceme" — container won't start otherwise. |
| secrets | "`DB_PASSWORD` + `MYSQL_PASSWORD`?" | Random, matching | Replace "replaceme" in both places. |
| network | "LAN or mesh VPN?" | `AskUserQuestion`: `lan-only` / `tailscale-mesh` / `wireguard-mesh` | Pick one — DO NOT expose to public internet. |

## Install — install script (typical path)

```bash
sudo apt-get update && \
sudo apt-get install -y curl && \
curl -fsSL https://raw.githubusercontent.com/Crosstalk-Solutions/project-nomad/refs/heads/main/install/install_nomad.sh \
  -o install_nomad.sh && \
sudo bash install_nomad.sh
```

Runs for a few minutes, installs:

- Docker + Docker Compose (if missing).
- `/opt/project-nomad/` directory (all data + config lives here).
- Admin service + MySQL + Redis + Dozzle.
- Systemd service to auto-start on boot.
- Helper scripts: `start_nomad.sh`, `stop_nomad.sh`, `update_nomad.sh`.

After install:

```
http://localhost:8080          # Command Center UI
http://<device-ip>:8080        # LAN access
http://<device-ip>:9999        # Dozzle logs
```

## Install — Docker Compose (advanced)

Download the upstream `management_compose.yaml`:

```bash
mkdir /opt/project-nomad && cd /opt/project-nomad
curl -fsSLO https://raw.githubusercontent.com/Crosstalk-Solutions/project-nomad/main/install/management_compose.yaml
mv management_compose.yaml docker-compose.yml

# Edit "replaceme" values — APP_KEY, URL, DB_PASSWORD (matching MYSQL_PASSWORD), MYSQL_ROOT_PASSWORD
nano docker-compose.yml

docker compose up -d
```

The compose file brings up:

| Service | Image | Port | Purpose |
|---|---|---|---|
| `admin` | `ghcr.io/crosstalk-solutions/project-nomad:latest` | `8080:8080` | Command Center UI + API |
| `dozzle` | `amir20/dozzle:v10.0` | `9999:8080` | Container log viewer |
| `mysql` | `mysql:8.0` | — (internal) | Admin DB |
| `redis` | (default image) | — (internal) | Admin cache / queue |

Critical env vars that MUST be changed from "replaceme":

| Variable | Service | Required |
|---|---|---|
| `APP_KEY` | admin | ≥16 chars |
| `URL` | admin | Must match user-facing URL |
| `DB_PASSWORD` | admin | Random |
| `MYSQL_PASSWORD` | mysql | MATCHING `DB_PASSWORD` |
| `MYSQL_ROOT_PASSWORD` | mysql | Random |

Volume `/opt/project-nomad/storage` is mounted into the admin container. The admin container also mounts `/var/run/docker.sock` to orchestrate other containers.

⚠️ **Mounting `/var/run/docker.sock` = the admin container has root on the HOST.** This is by design (it needs to install/remove other containers), but it means compromising the admin UI = compromising the host.

## First-run

1. Open `http://<device-ip>:8080`.
2. Setup wizard guides you through:
   - Downloading a starter content bundle.
   - Picking which apps to install (AI / Kiwix / Kolibri / etc.).
   - Configuring storage location (default `/opt/project-nomad/storage`).
3. Each app is installed as additional containers, orchestrated by the admin.
4. Start using.

## AI setup specifics

Default behavior: admin tries to install **Ollama on the HOST** (not in a container) when AI Assistant is selected. This gives Ollama direct GPU access.

Alternative: run Ollama on a different machine. Set `OLLAMA_HOST=0.0.0.0` on the remote host, then enter the URL in the AI Assistant settings.

Alt-alt: point at any OpenAI-compatible API (LM Studio, llama.cpp, vLLM). Note Ollama-only features like auto-model-download won't work with OpenAI-API endpoints.

## Data layout

```
/opt/project-nomad/
├── docker-compose.yml           # Management compose
├── storage/                     # Main data dir
│   ├── <app-specific-dirs>/     # Kiwix ZIM files, Kolibri channels, notes, etc.
│   └── ollama/                  # LLM weights (big!)
├── start_nomad.sh
├── stop_nomad.sh
├── update_nomad.sh
└── uninstall_nomad.sh
```

**Backup priority:**

1. **`/opt/project-nomad/storage`** — ZIM libraries, course data, notes, vector embeddings, downloaded models. This is the bulk of disk use.
2. **MySQL DB** (named docker volume, admin metadata) — `docker exec nomad_mysql mysqldump`.
3. **`docker-compose.yml`** with your env overrides.
4. Model weights (Ollama) — re-downloadable.
5. ZIM files — re-downloadable but SLOW (Wikipedia = ~100 GB).

## Helper scripts (from `/opt/project-nomad`)

```bash
sudo bash /opt/project-nomad/start_nomad.sh     # start all installed app containers
sudo bash /opt/project-nomad/stop_nomad.sh      # stop all
sudo bash /opt/project-nomad/update_nomad.sh    # pull latest Command Center image + recreate (NOT app containers)
```

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/Crosstalk-Solutions/project-nomad/refs/heads/main/install/uninstall_nomad.sh \
  -o uninstall_nomad.sh && \
sudo bash uninstall_nomad.sh
```

## Upgrade procedure

```bash
sudo bash /opt/project-nomad/update_nomad.sh
```

This updates ONLY the Command Center admin + mysql + redis. Individual installed app containers (Kiwix / Kolibri / Ollama / etc.) are updated through the Command Center UI, app-by-app.

Release notes: <https://github.com/Crosstalk-Solutions/project-nomad/releases>.

## Gotchas

- **NO AUTHENTICATION BY DESIGN.** Anyone on your LAN (or whatever network exposes :8080) is an admin. Treat as trusted-network-only. Do NOT port-forward. Use a mesh VPN (Tailscale/Headscale/WireGuard) if you need remote access.
- **Admin container mounts `/var/run/docker.sock` with r/w** — it's root-equivalent on the host. Compromise of admin UI = host compromise. Combined with no-auth, this is a serious threat model.
- **Debian-based only** — installer uses `apt`. RHEL / Fedora / Arch / NixOS users need manual install via compose, and the installer's kernel-module assumptions may still break.
- **`replaceme` values in compose WILL prevent startup** — APP_KEY needs ≥16 chars; DB_PASSWORD + MYSQL_PASSWORD MUST match.
- **AI on CPU-only is slow and limited.** For useful LLM responses, budget a GPU. RTX 3060 (12 GB VRAM) is the practical minimum per upstream; RTX 4090 / A100-tier for larger models.
- **Storage requirements escalate fast.** Full offline Wikipedia ZIM ≈ 100 GB. Add Khan Academy ≈ 250 GB. Add multiple LLM weights ≈ 50+ GB. Plan for 500 GB - 1 TB SSD.
- **Ollama runs on the HOST by default, not in a container** — so Docker logs won't show LLM activity. Check `systemctl status ollama` on the host.
- **Dozzle is exposed on :9999 with no auth** — uses the env vars `DOZZLE_ENABLE_ACTIONS=false` + `DOZZLE_ENABLE_SHELL=false` to prevent container control / shell exec (good!), but still shows all logs. LAN-only.
- **ZIM downloads are BIG** — download during install on a fast connection. Pre-seed the `/opt/project-nomad/storage` dir from another NOMAD device if possible.
- **"Installation requires internet"** — the software needs internet to install dependencies + download content. After that, fully offline-capable.
- **Benchmark tool sends data to public leaderboard** (<https://benchmark.projectnomad.us>) — opt-out if you want zero external traffic.
- **Helper scripts only update the admin** — individual app updates happen through the UI or `docker pull` manually.
- **Adding custom apps** requires forking / modifying — the Command Center's app catalog is curated.
- **Kolibri requires its own user accounts** (multi-user education platform). Kiwix + FlatNotes + AI don't — they're single-instance open.
- **Note data (FlatNotes)** is plain markdown files on disk — good for backup, bad if anyone on the network can read/edit them.
- **Regional maps in ProtoMaps** require manual download of PMTiles for your region.
- **Internet connectivity test** pings Cloudflare (`https://1.1.1.1/cdn-cgi/trace`) — this is the ONE outbound request; disable in settings if you want strict offline.
- **AI telemetry**: per upstream, NOMAD has zero built-in telemetry, but Ollama itself may phone home unless disabled. Check `OLLAMA_NOHISTORY=1` etc.
- **NOT for production corporate classrooms** without adding auth — multi-user Kolibri works, but the OS-level access is unsecured.
- **Roadmap has auth** (https://roadmap.projectnomad.us/posts/1/) — upvote if you need it. No ETA.
- **Raspberry Pi works for the management layer** (arm64 image exists). AI won't be useful on Pi — stick to CPU-only tools (Kiwix / notes / CyberChef).
- **Power outage / improper shutdown** can corrupt MySQL — keep a battery/UPS for the device if critical.
- **Comparable projects**: Internet-in-a-Box (IIAB — Raspberry-Pi-focused), Endless OS (distro), Rachel (RACHEL Plus, offline content device), LibreMesh (mesh networking + content). NOMAD's niche = AI + heavyweight hardware.

## Links

- Upstream repo: <https://github.com/Crosstalk-Solutions/project-nomad>
- Website: <https://www.projectnomad.us>
- Installation guide: <https://www.projectnomad.us/install>
- Hardware guide: <https://www.projectnomad.us/hardware>
- Installer script: <https://raw.githubusercontent.com/Crosstalk-Solutions/project-nomad/main/install/install_nomad.sh>
- Management compose: <https://raw.githubusercontent.com/Crosstalk-Solutions/project-nomad/main/install/management_compose.yaml>
- Uninstall script: <https://raw.githubusercontent.com/Crosstalk-Solutions/project-nomad/main/install/uninstall_nomad.sh>
- FAQ: <https://github.com/Crosstalk-Solutions/project-nomad/blob/main/FAQ.md>
- Troubleshooting: <https://github.com/Crosstalk-Solutions/project-nomad/blob/main/TROUBLESHOOTING.md>
- Benchmark leaderboard: <https://benchmark.projectnomad.us>
- Discord: <https://discord.com/invite/crosstalksolutions>
- Roadmap (auth request): <https://roadmap.projectnomad.us/posts/1/>
- Releases: <https://github.com/Crosstalk-Solutions/project-nomad/releases>
- Component references: Kiwix <https://kiwix.org>, Kolibri <https://learningequality.org/kolibri/>, Ollama <https://ollama.com>, Qdrant <https://qdrant.tech>, ProtoMaps <https://protomaps.com>, CyberChef <https://gchq.github.io/CyberChef/>, FlatNotes <https://github.com/dullage/flatnotes>, Dozzle <https://dozzle.dev>
