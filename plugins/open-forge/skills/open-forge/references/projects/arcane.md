---
name: Arcane
description: "Modern, beautiful web-based Docker management interface — alternative to Portainer. Stacks/containers/images/volumes/networks + multi-host via Arcane Agent. Go backend + SvelteKit frontend. BSD-3-Clause."
---

# Arcane

Arcane is **a modern Docker management UI** — a fresh alternative to Portainer / Dockge / Yacht for managing Docker containers, stacks (compose), images, volumes, and networks through a web interface. Emphasis on polished UX + modern tooling (Go + SvelteKit + DaisyUI). Started by **Kyle Mendell (kmendell)**; active, growing community.

**Project move note (from current README):**
> *"All Arcane repos have moved to the @getarcaneapp org on GitHub."*
>
> - Main image: `ghcr.io/getarcaneapp/arcane`
> - Agent image: `ghcr.io/getarcaneapp/arcane-headless`
> - Older `ghcr.io/kmendell/arcane*` tags work for ≤ 1.7.2 but **new releases only under the new org**
> - Update your compose `image:` paths

Features:

- **Full Docker stack management** — containers, stacks (compose), images, volumes, networks
- **Multi-host** via **Arcane Agent** — manage remote Docker hosts from central UI
- **Stack editor** — edit compose directly in-UI with validation
- **Container actions** — start/stop/restart/logs/exec/stats
- **Image management** — pull, tag, prune
- **Modern UI** — SvelteKit + Tailwind/DaisyUI; clean + responsive
- **Translations** — Crowdin-based; many languages
- **SBOM published** — software bill of materials transparency (<https://getarcane.app/sbom>)
- **User management + RBAC** (check current docs for scope)
- **Dark + light themes**

- Upstream repo: <https://github.com/getarcaneapp/arcane>
- Website / docs: <https://getarcane.app>
- SBOM: <https://getarcane.app/sbom>
- Translations: <https://crowdin.com/project/arcane-docker-management>
- Sponsor: <https://github.com/sponsors/kmendell>

## Architecture in one minute

- **Go backend** — talks to Docker daemon socket; exposes REST API
- **SvelteKit frontend** — modern reactive UI
- **SQLite** (typical) — users + settings
- **Arcane Agent** (optional) — headless Go binary on remote hosts; streams Docker events/stats to main Arcane
- **Resource**: small — ~100-200 MB RAM main; agent is smaller
- **Single container deployment** — mount Docker socket, go

## Compatible install methods

| Infra                    | Runtime                                                        | Notes                                                                          |
| ------------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Single VM / NAS          | **Docker (`ghcr.io/getarcaneapp/arcane`)**                         | **Upstream-recommended**                                                           |
| Multi-host               | Arcane server + `arcane-headless` agent on each remote host                | Native multi-host pattern                                                                              |
| Raspberry Pi             | arm64 images available                                                                       | Fine for small homelabs                                                                                               |
| Kubernetes               | Not the target — Arcane is Docker-focused, not K8s                                                                     | Use Rancher / Lens / Headlamp for K8s                                                                                                                    |
| Bare-metal binary        | Go binary releases — possible                                                                                         | Uncommon                                                                                                                                       |

## Inputs to collect

| Input                | Example                                          | Phase        | Notes                                                                        |
| -------------------- | ------------------------------------------------ | ------------ | ---------------------------------------------------------------------------- |
| Domain               | `docker.home.lan`                                     | URL          | TLS reverse proxy                                                                    |
| Docker socket        | `/var/run/docker.sock`                                       | Integration  | Mount into Arcane container                                                                       |
| Remote hosts         | Docker daemons on other machines                                          | Multi-host   | Install `arcane-headless` agent                                                                                       |
| Admin                | first-run wizard                                                        | Bootstrap    | Strong password + 2FA                                                                                                        |
| OAuth / OIDC (opt)   | per repo docs                                                                   | Auth         | Enterprise-style SSO                                                                                                                                  |
| Port                 | `3552` (typical — check current docs)                                                                | Network      | Configurable                                                                                                                                                              |

## Install via Docker

```yaml
services:
  arcane:
    image: ghcr.io/getarcaneapp/arcane:latest          # pin version in prod
    container_name: arcane
    restart: unless-stopped
    ports:
      - "3552:3552"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro   # read-only socket if you don't need to manage
      - ./data:/app/data
    environment:
      TZ: America/Los_Angeles
```

> **Docker socket is effectively root.** See gotchas. Use `:ro` where possible (read-only = view but no manage — only useful if Arcane can't manage at all, which defeats the purpose). For full management, socket must be rw. Mitigate by running Arcane only on trusted networks + strong auth.

Browse `http://<host>:3552/` → first-run wizard.

## Install Arcane Agent (remote hosts)

```yaml
services:
  arcane-agent:
    image: ghcr.io/getarcaneapp/arcane-headless:latest
    container_name: arcane-agent
    restart: unless-stopped
    ports:
      - "3553:3553"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
```

Register agent from Arcane UI (Settings → Hosts → Add).

## First boot

1. Browse → create admin
2. Default host shows as "local" (the Docker socket mounted into container)
3. Deploy a test stack via Arcane's compose editor → verify UI shows container running
4. (Optional) register remote hosts via Arcane Agent
5. Set up user accounts + RBAC if team use
6. Enable 2FA / OIDC for production
7. Put behind reverse proxy with TLS

## Data & config layout

- `/app/data/` (container) — SQLite + config
- `docker.sock` mounted read-write for management
- Single-directory backup

## Backup

```sh
sudo tar czf arcane-$(date +%F).tgz data/
```

Small. Stacks themselves are defined in-Arcane (compose YAML stored in DB) — so backup = stack defs too.

## Upgrade

1. Releases: <https://github.com/getarcaneapp/arcane/releases>. Active.
2. **Update image path to `ghcr.io/getarcaneapp/arcane`** (not old `kmendell/arcane`).
3. Docker: bump tag → restart → migrations auto.
4. Agents: upgrade independently; typically forward-compat one minor version.

## Gotchas

- **Docker socket = root on host.** Anyone with write access to `/var/run/docker.sock` can spawn a container with the host filesystem mounted and privilege-escalate to host root. **Arcane is only as secure as your access control to its UI.**
  - Never expose Arcane's UI to the internet without auth + TLS + IP allowlist.
  - Use strong password + 2FA (or OIDC).
  - Consider `docker-socket-proxy` (Tecnativa) to limit what Arcane can do via the socket.
  - Same applies to Portainer, Yacht, Dockge, LazyDocker, and every other Docker UI.
- **Repo-org move**: update image paths from `kmendell/arcane` → `getarcaneapp/arcane`. Old tags still pullable for legacy installs but new releases only on new path. Documented at top of README.
- **Not for Kubernetes**: Arcane is Docker-only. For K8s, use Rancher / Lens / Headlamp / Kubernetes Dashboard.
- **Multi-host agent**: convenient but the agent also has root-equivalent Docker socket access. Secure its endpoint (:3553) and traffic between Arcane server + agent (TLS — check current docs).
- **Compose editor**: edit + validate compose files in-UI. Nice UX but **a typo in a compose edit in-UI is still a typo** — prefer git-backed compose + sync, or at minimum diff-check before applying.
- **Backup of stacks**: stacks defined in Arcane live in Arcane's DB. If you also keep them in git (recommended), re-create on new install; if not, restore `data/` to get them back.
- **Permission model**: check current docs — fine-grained RBAC is evolving. May not yet match Portainer's maturity.
- **SBOM publication**: notable + laudable — Arcane publishes SBOM at getarcane.app/sbom. Transparency signal.
- **Crowdin translations**: community-driven localization; many languages.
- **Dev pace**: active; breaking changes possible pre-2.0. Pin versions.
- **Portainer comparison**:
  - Portainer: more mature, more features (Edge, Business, advanced RBAC), BSD-licensed community + Commercial Business tier
  - Arcane: cleaner UX, newer, purely FOSS (BSD-3), lighter footprint, active
  - Both mount docker.sock + have same root-equivalent risk
- **License**: **BSD-3-Clause**.
- **Alternatives worth knowing:**
  - **Portainer CE / Business** — most mature Docker UI
  - **Yacht** — older; lighter
  - **Dockge** — focused on compose stack management; Louis Lam
  - **LazyDocker** — TUI (terminal) not web
  - **Docker Desktop** — official; GUI on workstation
  - **Rancher** — K8s-focused
  - **Kubernetes Dashboard / Lens / Headlamp** — for K8s
  - **Choose Arcane if:** modern UI + FOSS + multi-host Docker management.
  - **Choose Portainer if:** most features + proven track record + need enterprise tier.
  - **Choose Dockge if:** compose-stack-centric workflow.
  - **Choose LazyDocker if:** terminal-first.

## Links

- Repo: <https://github.com/getarcaneapp/arcane>
- Website: <https://getarcane.app>
- SBOM: <https://getarcane.app/sbom>
- Releases: <https://github.com/getarcaneapp/arcane/releases>
- Agent image: <https://github.com/getarcaneapp/arcane/pkgs/container/arcane-headless>
- Main image: <https://github.com/getarcaneapp/arcane/pkgs/container/arcane>
- Sponsor: <https://github.com/sponsors/kmendell>
- Translations: <https://crowdin.com/project/arcane-docker-management>
- Portainer (alt mature): <https://www.portainer.io>
- Dockge (alt compose-focused): <https://github.com/louislam/dockge>
- Docker-socket-proxy: <https://github.com/Tecnativa/docker-socket-proxy>
