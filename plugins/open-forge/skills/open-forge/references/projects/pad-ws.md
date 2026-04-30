---
name: pad.ws
description: "Whiteboard + IDE mashup — Excalidraw canvas integrated with Coder cloud-dev-environments, giving you a browser whiteboard that can embed real terminals + VS Code panes. Early-development / beta. Python (FastAPI) + React. MIT-licensed. PostgreSQL + Redis + Keycloak + Coder."
---

# pad.ws

pad.ws is **"whiteboard-as-an-IDE"** — an Excalidraw canvas where individual shapes can become **live terminals + full VS Code instances** backed by **Coder** cloud-development-environments. Draw your architecture, then zoom into a box → that box is a real shell running in a real dev VM → write code + switch back to sketch mode. The goal: **merge ideation + coding** into one visual-first surface.

Built + maintained by **coderamp-labs** (pad-ws org). **MIT-licensed**. Public managed version at <https://pad.ws>. Early-stage — upstream is **explicit**: _"IMPORTANT NOTICE: This repository is in early development stage. The setup provided in `docker-compose.yml` is for development and testing purposes only."_ Self-hosting is possible but the maintainers signal it's not yet battle-hardened.

Use cases: (a) **visual-first developers** who sketch architecture before coding (b) **teaching / workshops** where instructor shows a diagram that drills into live code (c) **team whiteboarding + pair-programming** in one tool (d) **interview + coding-challenges** with rich visual context (e) **early-adopter homelab experimentation** with novel UX.

Features:

- **Interactive Excalidraw whiteboard** — standard Excalidraw drawing tools
- **Embedded terminals** — shell into dev VMs from within a shape
- **Embedded VS Code** — browser-based code editor backed by Coder workspace
- **Desktop-client access** — use VS Code / Cursor against the Coder workspace from your local editor
- **Cloud-dev-env** — ephemeral + configurable per-user Ubuntu environments
- **OIDC auth** — via Keycloak in the reference compose
- **Multi-user canvas** — shared whiteboards (check current sharing model)

- Upstream repo: <https://github.com/coderamp-labs/pad.ws>
- Homepage + managed: <https://pad.ws>
- Engine (Excalidraw): <https://github.com/excalidraw/excalidraw>
- Engine (Coder): <https://github.com/coder/coder>
- OIDC (Keycloak): <https://www.keycloak.org>

## Architecture in one minute

- **FastAPI** backend + **React/Excalidraw** frontend
- **PostgreSQL** — canvas + config persistence
- **Redis** — sessions + caching (password-authenticated)
- **Keycloak** — OIDC provider for SSO (Coder + pad both use it)
- **Coder** — cloud-dev-env engine; pad orchestrates Coder workspaces
- **Docker** — Coder needs Docker socket access (for nested dev containers)
- **Resource**: moderate — stack = 5 containers (pad + postgres + redis + keycloak + coder); each dev workspace adds its own container
- **Ports**: pad=8000, keycloak=8080, coder=7080

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Managed SaaS       | <https://pad.ws>                                               | **Recommended** during beta                                                        |
| Docker Compose     | Reference `docker-compose.yml` in repo                                    | **Dev/test only** per upstream; NOT production-hardened                                    |
| Kubernetes         | Not officially documented                                                                 | Community-only                                                                                         |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Linux host          | Tested only on Ubuntu                                           | Platform     | Docker + Compose                                                                                    |
| `.env` file          | Copy `.env.template`                                                    | Config       | Contains passwords, secrets, all service config                                                                                    |
| PostgreSQL password  | Random                                                                                | Secret       | Persistence DB                                                                                                            |
| Redis password       | Random                                                                                                    | Secret       | Via `REDIS_PASSWORD`                                                                                                                |
| Keycloak realm + client                       | e.g., `pad-ws`                                                                                                                 | Auth         | Realm name; client with client-auth enabled; audience mapper                                                                                                                       |
| OIDC secrets         | Keycloak-generated                                                                                                                              | Auth         | `OIDC_CLIENT_ID`, `OIDC_CLIENT_SECRET`                                                                                                                                                     |
| Coder API key        | Coder-generated                                                                                                                                                  | Integration  | `CODER_API_KEY`, `CODER_TEMPLATE_ID`, `CODER_DEFAULT_ORGANIZATION`                                                                                                                                                         |
| `DOCKER_GROUP_ID`    | `getent group docker | cut -d: -f3`                                                                                                                                                            | Integration  | For Coder to access Docker socket                                                                                                                                                                    |

## Install via Docker Compose

Per upstream README — the process is multi-step:

1. `cp .env.template .env` and fill in passwords
2. `docker compose up -d postgres` + `redis`
3. `docker compose up -d keycloak` → set up realm + client + user + audience mapper (Keycloak admin UI)
4. `docker compose up -d coder` → admin login → create template → generate API key → find template ID + org ID → update `.env`
5. `docker compose up -d pad`

Full step-by-step in README: <https://github.com/coderamp-labs/pad.ws>.

## First boot

Per upstream README sequence above. Key first-boot decisions:

- **Keycloak realm name** — bake into `.env`
- **Coder template** — choose your dev-env base image (Ubuntu default; can customize)
- **Audience mapper** in Keycloak — required for Coder to accept OIDC tokens

Test by accessing `http://localhost:8000`, login via Keycloak, create a pad → embed a terminal shape → verify it connects to a Coder workspace.

## Data & config layout

- **Postgres** — canvas content, user-pad associations
- **Redis** — sessions
- **Keycloak DB** — separate Postgres or H2 by default
- **Coder DB** — separate Postgres
- **Docker volumes for dev-workspaces** — per-user VM filesystems

## Backup

```sh
# DB dumps
pg_dump -Fc -U padws padws > padws-db-$(date +%F).dump
# Keycloak export (realm export via kc.sh)
docker exec keycloak /opt/keycloak/bin/kc.sh export --dir /tmp/export --realm pad-ws
# Dev-workspaces are BIG — may not be worth backing up; can be recreated from template
```

## Upgrade

1. Releases: <https://github.com/coderamp-labs/pad.ws/releases>. Active + early-stage = breaking changes likely.
2. **READ RELEASE NOTES — early-stage software.**
3. Compose: `docker compose pull && docker compose up -d`.
4. DB schema changes possible; back up first.

## Gotchas

- **Upstream EXPLICITLY says "dev/testing only"** for the current self-hosted setup. **Respect this.** If you self-host pad.ws in production, you're taking on:
  - Unaudited dependency chain (5 services)
  - No documented hardening guide
  - Breaking-change risk on every release
  - Defaults tuned for localhost (you need to harden them)
  - Same "honest-upstream-communication" pattern as Wakapi ("PRs closed" 81), xyOps ("no feature PRs" 84), Dim ("pace slowing" 84). **Fourth tool** in that transparency family. Respect the signal.
- **Managed version at pad.ws is the recommended path during beta.** Free Ubuntu dev-envs during beta per upstream; pay when it graduates. Standard "commercial-tier-funds-upstream" pattern.
- **5-service stack** (pad + Postgres + Redis + Keycloak + Coder) = significant operational surface. Each component has its own backup/upgrade/security story. Cost of integrated experience: 5x ops complexity.
- **Docker-socket access mandatory** for Coder — this is a **root-equivalent** permission on the host. Coder spawns containers = orchestrates the Docker daemon = can do anything Docker can do = can escape to host. Threat model: **treat the Coder container as a privileged component**. Same class as any tool with Docker socket access (Portainer, Dockge, dozens of others). Network-isolate it.
- **Hub-of-credentials crown-jewel** — Keycloak stores user passwords + OIDC secrets; Coder stores SSH/template/workspace tokens; pad stores canvas data which may include sensitive sketches (architecture, secrets-in-pictures, customer-names). **Sixth tool** in hub-of-credentials family. TLS mandatory. Backup Keycloak realm. Strong admin passwords throughout.
- **Coder licensing + commercial-tier** — Coder itself is AGPL-3 for community + has paid Enterprise tier. pad.ws depends on Coder; if Coder's license / features shift, pad.ws inherits that risk.
- **Keycloak is HEAVY** — ~1GB RAM baseline for Keycloak alone. If you can't afford it, Authentik / Authelia are lighter alternatives, but pad.ws's reference setup assumes Keycloak.
- **"Tested on Ubuntu only"** — other Linux distros likely work but untested by upstream. Report bugs upstream if you try Fedora/Arch.
- **Excalidraw is the canvas engine** — if you just want Excalidraw (drawing without IDE integration), use standalone Excalidraw (batch 3). pad.ws's differentiator is the IDE + terminal embedding.
- **Dev-workspace persistence + costs**: each user's workspace is a container with its own filesystem. At scale, these accumulate storage + CPU. Managed pad.ws handles this; self-hosted = your problem.
- **Multi-user collaboration model**: check current version for real-time multi-cursor on a shared pad. Excalidraw supports it; pad.ws may or may not wire it through. Test before depending.
- **Browser-based IDE latency**: same reality as Webtop (83) / Cloudron browser-desktops. VS Code in browser = adequate locally + increasingly painful over high-latency networks. Use the desktop VS Code / Cursor option against Coder workspace for serious coding.
- **Early-stage license risk**: MIT now; commercial entity (coderamp-labs) = could theoretically relicense. MIT work already-released stays MIT. Monitor for governance shifts.
- **Project health**: early-stage + small team + paid-managed-version + MIT. Genuinely interesting concept; bus-factor-small; **experiment-friendly not production-friendly today**. Revisit in 12 months.
- **Alternatives worth knowing:**
  - **Excalidraw** (standalone) — just the whiteboard; no IDE
  - **tldraw** — another excellent whiteboard
  - **Coder** (standalone) — cloud dev envs without whiteboard
  - **code-server** — VS Code in browser (no whiteboard)
  - **Gitpod** / **GitHub Codespaces** — commercial cloud-dev-envs
  - **Miro + separate IDE** — SaaS whiteboard + local dev
  - **FigJam + separate IDE** — similar
  - **Choose pad.ws if:** you want the integrated whiteboard+IDE experience + willing to ride the early-stage edge.
  - **Choose Excalidraw + code-server if:** you want stability; run them side-by-side.

## Links

- Repo: <https://github.com/coderamp-labs/pad.ws>
- Managed: <https://pad.ws>
- Excalidraw (engine): <https://github.com/excalidraw/excalidraw>
- Coder (engine): <https://github.com/coder/coder>
- Keycloak: <https://www.keycloak.org>
- code-server (alt): <https://github.com/coder/code-server>
- tldraw (alt whiteboard): <https://github.com/tldraw/tldraw>
- Gitpod (alt cloud dev-env): <https://www.gitpod.io>
