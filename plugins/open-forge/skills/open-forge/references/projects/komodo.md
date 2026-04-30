---
name: Komodo
description: Multi-host Docker / build + deploy orchestrator. Manage containers, stacks, and builds across many servers from one UI. Docker Swarm/Kubernetes alternative for small-to-mid fleets; Portainer competitor. Rust core + React UI + MongoDB/FerretDB. GPL-3.0.
---

# Komodo

Komodo (formerly Monitor, by `moghtech`) is a **fleet manager for Docker**. One web UI manages many servers — deploying container stacks, building images from source, tailing logs, and viewing stats across your whole fleet.

Positioned as:

- **More capable than Portainer** — first-class source-of-truth sync (`git sync`), build-on-server workflow, resource templates
- **Simpler than Docker Swarm / Kubernetes** — no cluster networking, no orchestrator drama
- **Complementary to Dockge / Yacht** — bigger scale, more features, multi-host

Features:

- **Multi-server fleet** — any number of Linux hosts running Docker; no limit (explicit design: "no business edition")
- **Stacks** — docker-compose as a first-class resource; deploy/update from UI
- **Builds** — clone a repo on a build server, `docker build`, push to your registry
- **Procedures** — sequenced multi-step actions (deploy → health check → notify)
- **Syncs** — declarative: keep your fleet in sync with files in a git repo
- **Alerts** — webhook on container stopped, host down, stack failed
- **Stats** — per-container + per-host CPU/RAM/disk graphs
- **Resource tree** — logical grouping of resources
- **API** for automation
- **OAuth** login (GitHub, Google, OIDC)

- Upstream repo: <https://github.com/moghtech/komodo>
- Website: <https://komo.do>
- Docs: <https://komo.do/docs>
- Demo: <https://demo.komo.do> (login `demo`/`demo`)
- GHCR images: <https://github.com/orgs/moghtech/packages?repo_name=komodo>
- Discord: <https://discord.gg/DRqE8Fvg5c>

## Architecture in one minute

Two components deploy per fleet:

- **Komodo Core** — the central brain + web UI. Runs on one host. Talks to Periphery agents via key-pair auth.
- **Komodo Periphery** — agent. Installed on every host you want to manage. Can run as a container (with Docker socket mounted) OR a systemd binary.

Storage:

- **MongoDB** (default) OR **FerretDB** (Postgres-compatible MongoDB-like DB, drop-in replacement) for Core's state
- **Volumes**: `keys` (Core ↔ Periphery auth keys), `backups` (dated DB backups), optional `syncs` (git-backed config), optional `custom config`

Ports:

- **Core**: `9120` (web UI + API)
- **Periphery**: `8120` (Core → Periphery)

## Compatible install methods

| Infra       | Runtime                                              | Notes                                                                     |
| ----------- | ---------------------------------------------------- | ------------------------------------------------------------------------- |
| Single VM   | Docker Compose (Core + Periphery + Mongo/FerretDB)   | **Upstream-documented**                                                    |
| Multi-host  | Core on one host + Periphery container on each host    | **Standard production model**                                               |
| Multi-host  | Periphery as systemd binary on each host               | More lightweight than Periphery-in-Docker                                    |
| Kubernetes  | Core as Deployment; Peripheries on each Node           | Community charts                                                              |

## Inputs to collect

| Input                               | Example                                | Phase     | Notes                                                  |
| ----------------------------------- | -------------------------------------- | --------- | ------------------------------------------------------ |
| `KOMODO_HOST`                       | `https://komodo.example.com`            | DNS       | Used for OAuth redirect URIs + webhook URLs             |
| `KOMODO_TITLE`                      | `My Fleet`                              | Branding  | Browser tab title                                        |
| `KOMODO_DATABASE_USERNAME/PASSWORD` | strong                                  | DB        | For Mongo / FerretDB                                     |
| `COMPOSE_KOMODO_BACKUPS_PATH`       | `/etc/komodo/backups`                    | Storage   | Dated DB backups on the host                              |
| Periphery public key                | `/config/keys/periphery.pub`             | Security  | Shared between Core + Peripheries                          |
| OAuth creds (optional)              | GitHub/Google/OIDC client ID + secret    | Auth      | Via env vars                                              |
| TZ                                  | `America/Los_Angeles`                    | Config    | For schedule cron                                          |

## Install via Docker Compose (Core + Mongo + one Periphery on same host)

Use upstream's compose files. Brief version:

```sh
mkdir -p /etc/komodo
cd /etc/komodo
curl -O https://raw.githubusercontent.com/moghtech/komodo/main/compose/compose.env
curl -O https://raw.githubusercontent.com/moghtech/komodo/main/compose/mongo.compose.yaml
# Edit compose.env: set KOMODO_HOST, KOMODO_DATABASE_USERNAME/PASSWORD, TZ
docker compose --env-file compose.env -f mongo.compose.yaml up -d
```

What this deploys:

- `mongo` — database
- `core` — Komodo Core (port 9120)
- `periphery` — one Periphery on the same host (managing Docker on this host)

Browse `http://<host>:9120` — create first admin account (first-user-is-admin).

## Add additional hosts (extra Peripheries)

On each extra host:

```sh
# Option A: container
docker run -d --name komodo-periphery \
  --restart unless-stopped \
  -p 8120:8120 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v komodo-keys:/config/keys \
  -e PERIPHERY_PASSKEYS=<passkey from Core config> \
  ghcr.io/moghtech/komodo-periphery:2

# Option B: systemd binary (upstream provides install script)
curl -fsSL https://raw.githubusercontent.com/moghtech/komodo/main/scripts/setup-periphery.py | python3
```

Then in Core UI → **Servers** → Add → enter host + port 8120 + passkey.

## Data & config layout

Volumes (from upstream compose):

- `mongo-data` — Mongo DB
- `mongo-config` — Mongo config
- `keys` — shared between Core + Periphery for mutual auth
- `${COMPOSE_KOMODO_BACKUPS_PATH}:/backups` — dated DB dumps (per Komodo's scheduled backups)

On Periphery hosts:

- `/var/run/docker.sock` mount → Periphery has full Docker control on that host

## Backup

Komodo **auto-backs up** its Mongo database to the `$COMPOSE_KOMODO_BACKUPS_PATH` directory on a schedule. Snapshots are dated.

Manual:

```sh
docker compose exec -T mongo mongodump --archive --quiet | gzip > komodo-db-$(date +%F).archive.gz

# Or back up the whole volume:
docker run --rm -v mongo-data:/src -v "$PWD":/backup alpine \
  tar czf /backup/komodo-mongo-$(date +%F).tgz -C /src .
```

## Upgrade

1. Image tags use major semver: `ghcr.io/moghtech/komodo-core:2`, `ghcr.io/moghtech/komodo-periphery:2`. Minor + patch pulls forward within the same major.
2. Read release notes: <https://github.com/moghtech/komodo/releases>.
3. Back up Mongo → `docker compose pull && docker compose up -d`. Core → Periphery version skew is tolerated but narrow (keep same major).
4. Pin `COMPOSE_KOMODO_IMAGE_TAG` in `compose.env` to a specific minor (e.g., `2.x.x`) for reproducibility.

## Gotchas

- **Docker socket = root on host** — every Periphery has full Docker (and thus root-equivalent) access on its host. Keep Periphery's auth keys secret; don't expose port 8120 to internet.
- **Core ↔ Periphery auth is via shared passkey** rotation — changing passkey requires updating all Peripheries.
- **Mongo OR FerretDB**: Komodo supports both. FerretDB (Postgres-backed MongoDB-compatible) avoids Mongo's SSPL license concerns + is often easier to HA. Try `ferretdb.compose.yaml`.
- **Mongo license (SSPL)** — Mongo isn't open-source by OSI definition. For a truly OSS stack, use FerretDB.
- **Komodo is GPL-3.0 + Mongo is SSPL** — your whole stack isn't OSI-OSS with default Mongo. Swap to FerretDB if that matters.
- **First-user-is-admin** — lock down registration after creating admin. Settings → Users → disable open signup.
- **OAuth providers**: GitHub, Google, OIDC (for Keycloak/Zitadel/etc.). Configure via env vars in Core; redirect URI uses `KOMODO_HOST`.
- **`KOMODO_HOST` is baked into OAuth redirect URIs** — fix before registering apps with GitHub/Google.
- **Stacks ≠ Docker Swarm stacks.** In Komodo, a "Stack" is a docker-compose file + env, deployed to one or more Peripheries. It's not a distributed orchestration primitive.
- **Builds happen on whichever Periphery you choose.** Common pattern: a dedicated "build" host with more CPU → builds images + pushes to your registry → other Peripheries pull deployed images.
- **Syncs** = git-backed declarative config. Commit your stacks/deploys to a repo; Komodo pulls and applies. GitOps-lite without needing Argo/Flux.
- **Procedures** can chain actions with conditions — "deploy → wait for healthcheck → promote to prod → notify."
- **Alerts** via Discord/Slack/webhook/email.
- **Stats retention** — per-container time-series data; configurable retention. Not meant to replace Grafana/Prometheus for long-term metrics.
- **Resource tree** is organizational only (tags/groups); doesn't change what runs where.
- **Demo server** — <https://demo.komo.do> login `demo`/`demo` — play around without installing.
- **Komodo-managed containers are tagged** with labels; Komodo **skips containers labeled `komodo.skip`** (e.g., Mongo itself) from "stop all" operations. Use this label to protect infrastructure containers.
- **GPL-3.0 license** — strong copyleft. Commercial use fine; modifications must be GPL'd if redistributed.
- **Upstream is transparent + active** — solo-maintainer-supported but responsive on Discord.
- **Alternatives worth knowing:**
  - **Portainer** — most popular; free CE + paid Business; multi-host; more mature UI
  - **Dockge** — single-host, simpler, stack-focused; great for one server
  - **Yacht** — similar single-host target; lighter
  - **Cockpit + Cockpit Podman** — built-in RHEL/Fedora management; less pretty
  - **Docker Swarm** — orchestration (not just management); built into Docker
  - **Kubernetes + Lens / Headlamp / k9s** — bigger hammer; much more complexity
  - **Nomad (HashiCorp)** — simpler-than-k8s orchestrator
  - **CapRover** — PaaS-style; opinionated
  - **Rancher** — enterprise k8s + Docker management; heavier
  - **Pterodactyl** — game-server focused, not general
  - Pick **Komodo** over Portainer if you want: git-sync of config as source of truth, builds first-class, no business-edition feature gates.

## Links

- Repo: <https://github.com/moghtech/komodo>
- Website + docs: <https://komo.do>
- Setup: <https://komo.do/docs/setup>
- Periphery setup: <https://github.com/moghtech/komodo/blob/main/scripts/readme.md>
- Compose examples: <https://github.com/moghtech/komodo/tree/main/compose>
- Demo: <https://demo.komo.do> (demo/demo)
- Build server: <https://build.mogh.tech> (komodo/komodo)
- GHCR Core: <https://github.com/moghtech/komodo/pkgs/container/komodo-core>
- GHCR Periphery: <https://github.com/moghtech/komodo/pkgs/container/komodo-periphery>
- Releases: <https://github.com/moghtech/komodo/releases>
- Roadmap: <https://github.com/moghtech/komodo/blob/main/roadmap.md>
- Discord: <https://discord.gg/DRqE8Fvg5c>
