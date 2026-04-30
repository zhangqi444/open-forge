---
name: Woodpecker CI
description: "Simple, container-native CI/CD engine — community fork of Drone. YAML pipelines, Docker-based steps, plugin ecosystem. Server + Agent architecture. Tiny footprint (~100 MB server, 30 MB agent). Apache-2.0."
---

# Woodpecker CI

Woodpecker is **a simple yet powerful CI/CD engine with great extensibility** — the community-maintained continuation of the earlier-open-source Drone CI. YAML-defined pipelines run as Docker/Podman/Kubernetes steps; each step is a container image. Plugs into Git hosts (GitHub, GitLab, Gitea, Forgejo, Bitbucket) for push/PR triggers.

Used as the main CI/CD engine at **Codeberg** (Gitea-based OSS code host), and broadly in homelab + small-team deploys.

Features:

- **YAML pipelines** (`.woodpecker.yml` in your repo) — multi-stage, matrix, services, secrets
- **Container-native** — each step = Docker image; guaranteed-clean per-step
- **Multiple runtimes** — Docker (default), Kubernetes, SSH, Local (shell)
- **Git host integrations** — GitHub, GitLab, Gitea, Forgejo, Bitbucket Server/Cloud
- **Secrets management** — per-org / per-repo / per-deployment-env
- **Multi-pipeline** — sequential + dependent pipelines
- **Matrix builds** — fan out across parameters
- **Service containers** (sidecars for DB/queue during tests)
- **Cron triggers** — scheduled pipelines
- **Plugin ecosystem** — Docker images purpose-built as CI steps (publish, notify, scan, deploy)
- **Web UI** — repo list, run history, live log streaming
- **CLI** — `woodpecker-cli`
- **Federation-friendly** — runs alongside small Git servers (Gitea/Forgejo)
- **Tiny footprint** — ~100 MB RAM for server, ~30 MB for agent

- Upstream repo: <https://github.com/woodpecker-ci/woodpecker>
- Website: <https://woodpecker-ci.org>
- Docs: <https://woodpecker-ci.org/docs/intro>
- Plugin marketplace: <https://woodpecker-ci.org/plugins>
- Matrix: `#woodpecker:matrix.org`
- Docker Hub: <https://hub.docker.com/r/woodpeckerci/woodpecker-server> + `/woodpecker-agent`

## Architecture in one minute

Two main services:

1. **woodpecker-server** — web UI, API, webhook receiver, job dispatcher, stores state (SQLite default; Postgres/MySQL optional)
2. **woodpecker-agent** — pulls jobs from server via gRPC, runs them on Docker/K8s/SSH/local; scale horizontally

Optional:
- **woodpecker-cli** — local CLI for triggering/debugging
- **Plugins** are just Docker images invoked as steps; no Woodpecker-specific API needed

## Compatible install methods

| Infra        | Runtime                                                  | Notes                                                                 |
| ------------ | -------------------------------------------------------- | --------------------------------------------------------------------- |
| Single VM    | **Docker Compose** (server + 1 agent)                       | **Simplest — runs on any VPS**                                             |
| Kubernetes   | Helm chart + Kubernetes runtime agent                                | Great for elastic multi-agent                                                 |
| Nomad / Swarm | Supported                                                                | Less common                                                                            |
| Native       | Binary + systemd                                                                | For bare-metal + SSH runtimes                                                                        |
| Raspberry Pi | arm64 images available                                                                    | Fine for homelab CI                                                                                          |
| Managed      | **No first-party SaaS**; self-host only                                                            |                                                                                                                      |

## Inputs to collect

| Input                | Example                                      | Phase      | Notes                                                                              |
| -------------------- | -------------------------------------------- | ---------- | ---------------------------------------------------------------------------------- |
| Domain               | `ci.example.com`                                | URL        | Reverse proxy with TLS                                                                 |
| Git host             | GitHub / GitLab / Gitea / Forgejo / Bitbucket         | Forge      | Pick one (multi-forge unsupported per instance)                                                 |
| OAuth app            | created on Git host                                            | Auth       | Client ID + secret                                                                                       |
| Admins               | `WOODPECKER_ADMIN=alice,bob`                                     | Access     | Comma-separated Git-host usernames                                                                                          |
| Agent secret         | random 32+ chars                                                         | RPC        | Shared between server + agents for gRPC auth                                                                                             |
| Runtime              | Docker (default) / K8s / SSH / Local                                            | Agent      | Match to your infra                                                                                                                        |
| Host                 | `WOODPECKER_HOST=https://ci.example.com`                                                    | URL        | Absolute URL — for webhooks                                                                                                                                       |
| DB                   | SQLite (default) / Postgres / MySQL                                                                      | Storage    | SQLite fine for small instances                                                                                                                                                  |

## Install via Docker Compose

```yaml
services:
  server:
    image: woodpeckerci/woodpecker-server:v3                        # pin major
    container_name: woodpecker-server
    restart: unless-stopped
    environment:
      WOODPECKER_OPEN: "false"
      WOODPECKER_HOST: https://ci.example.com
      WOODPECKER_ADMIN: alice
      # Gitea example
      WOODPECKER_GITEA: "true"
      WOODPECKER_GITEA_URL: https://git.example.com
      WOODPECKER_GITEA_CLIENT: <client-id>
      WOODPECKER_GITEA_SECRET: <client-secret>
      WOODPECKER_AGENT_SECRET: <random-32-chars>
      WOODPECKER_DATABASE_DRIVER: sqlite3
      WOODPECKER_DATABASE_DATASOURCE: /var/lib/woodpecker/woodpecker.sqlite
    volumes:
      - woodpecker-server:/var/lib/woodpecker
    ports:
      - "8000:8000"
      - "9000:9000"        # gRPC for agents

  agent:
    image: woodpeckerci/woodpecker-agent:v3
    container_name: woodpecker-agent
    restart: unless-stopped
    depends_on: [server]
    command: agent
    environment:
      WOODPECKER_SERVER: server:9000
      WOODPECKER_AGENT_SECRET: <random-32-chars>
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock          # Docker runtime

volumes:
  woodpecker-server:
```

Front with Caddy/Traefik; port `9000` internal only (agent ↔ server gRPC).

## First boot

1. Register OAuth app on your Git host pointing `http://ci.example.com/authorize` as redirect
2. Browse `https://ci.example.com/` → log in via Git OAuth → first login = admin
3. "Activate" a repo in the UI → Woodpecker registers a webhook on the Git host
4. Add `.woodpecker.yml` to the repo:
   ```yaml
   when:
     - event: push
   steps:
     - name: test
       image: node:20-alpine
       commands:
         - npm ci
         - npm test
   ```
5. `git push` → webhook fires → pipeline runs → live logs in UI

## Sample `.woodpecker.yml` (matrix + services)

```yaml
when:
  - event: [push, pull_request]
matrix:
  NODE_VERSION: ["18", "20", "22"]
services:
  - name: postgres
    image: postgres:16-alpine
    environment:
      POSTGRES_PASSWORD: testpass
steps:
  - name: test
    image: node:${NODE_VERSION}-alpine
    commands:
      - npm ci
      - npm test
    environment:
      DATABASE_URL: postgres://postgres:testpass@postgres/postgres
```

## Data & config layout

- `/var/lib/woodpecker/` — server state (SQLite, if used)
- Docker volumes on agents — ephemeral per-job (`woodpecker_*` auto-created/destroyed)
- Secrets in DB — encrypted at rest (per upstream config)

## Backup

```sh
# Server state
docker exec woodpecker-server sqlite3 /var/lib/woodpecker/woodpecker.sqlite ".backup '/tmp/wp-backup.sqlite'"
docker cp woodpecker-server:/tmp/wp-backup.sqlite ./wp-$(date +%F).sqlite
```

For Postgres: `pg_dump` as usual.

Loss of server state = loss of run history, activated repos, secrets. Repos re-link quickly; secrets must be re-added.

## Upgrade

1. Releases: <https://github.com/woodpecker-ci/woodpecker/releases>. Frequent; semver major bumps every 12-18 months.
2. Back up DB.
3. Docker: bump tag on **both** `woodpecker-server` and `woodpecker-agent` together → restart.
4. Read release notes — major versions have occasional breaking `WOODPECKER_*` env renames.
5. v2 → v3 migration required deprecation flags + config adjustments; v3 → v4 likely similar. Follow upstream migration guides.

## Gotchas

- **Agent + server version must match** (within major version). Running mixed versions causes gRPC protocol issues.
- **Agent needs Docker socket** (or K8s access, or SSH) — **this is privileged access.** A malicious build step can escape to the host. **Do NOT run agents on your production servers.** Run agents on dedicated throwaway VMs or in K8s with strict RBAC.
- **Pipeline security model** — by default, secrets are injected into steps as env vars. Any step can `echo $SECRET > /tmp/stolen` and exfiltrate. Mark secrets as **pull_request: false** to avoid leaking via malicious PRs.
- **Fork PRs** — auto-running CI on forks of public repos = security risk (malicious PR can run arbitrary code with your agent privileges). Require manual approval (`WOODPECKER_REQUIRE_APPROVAL=pull_requests`).
- **Drone compat** — Woodpecker started as a Drone 0.x fork; early pipeline YAML is similar but v1+ Woodpecker YAML has diverged. Don't assume Drone configs work.
- **`WOODPECKER_OPEN`** — set to `false` for private instances; else anyone with a Git account on your forge can activate repos + run CI on your agents.
- **Admin list** — only admins can configure global secrets / agent assignments.
- **gRPC port** (9000) — agent ↔ server. Firewall it or use mTLS if agents are remote.
- **Plugins are just images** — handy but no sandboxing. Vet plugin images before using (read Dockerfile + source). Prefer plugins from woodpecker-ci org or well-known authors.
- **Disk growth**: agents leave old workspace volumes unless pruned. Cron a `docker volume prune` or `docker system prune -f --volumes` (careful with other containers).
- **SQLite + concurrent writes** — SQLite is fine for small instances; move to Postgres if you see lock errors under load.
- **Codeberg uses Woodpecker** as their CI — good real-world scale reference.
- **Kubernetes runtime** — runs each step as a Pod. Needs kubeconfig + namespace; great for elastic scaling.
- **Local runtime** — steps run as shell commands on the agent host. Fast but **zero isolation** — only use on single-trust environments.
- **License**: Apache-2.0.
- **Alternatives worth knowing:**
  - **Drone CI** — the original; now has a commercial fork at Harness; older OSS version is drift
  - **Gitea Actions** — if you run Gitea; GitHub-Actions-compatible YAML
  - **Forgejo Actions** — same for Forgejo
  - **GitLab CI** — if on GitLab (separate recipe — batch 59)
  - **GitHub Actions** — if on GitHub; self-hosted runners available
  - **Concourse CI** — pipeline-first; steep learning curve
  - **Jenkins** — classic, heavy, plugin-heavy (separate recipe)
  - **Buildkite** (hybrid SaaS) — commercial with self-hosted agents
  - **Earthly** — Dockerfile-like CI language; works in any CI
  - **Dagger** — "CI-as-code" in your language
  - **Choose Woodpecker if:** you want a lightweight, self-hosted, container-native CI that integrates with Gitea/Forgejo/GitHub/GitLab via OAuth.
  - **Choose Gitea/Forgejo Actions if:** you already use Gitea/Forgejo and want GitHub-Actions YAML compatibility.
  - **Choose Jenkins if:** legacy ecosystem + plugins matter more than simplicity.
  - **Choose GitHub/GitLab Actions if:** you host on GitHub/GitLab and don't want a separate CI.

## Links

- Repo: <https://github.com/woodpecker-ci/woodpecker>
- Website: <https://woodpecker-ci.org>
- Docs: <https://woodpecker-ci.org/docs/intro>
- Install docs: <https://woodpecker-ci.org/docs/administration/general>
- Pipeline syntax: <https://woodpecker-ci.org/docs/usage/pipeline-syntax>
- Plugins list: <https://woodpecker-ci.org/plugins>
- Releases: <https://github.com/woodpecker-ci/woodpecker/releases>
- Matrix room: <https://matrix.to/#/#woodpecker:matrix.org>
- Docker Hub (server): <https://hub.docker.com/r/woodpeckerci/woodpecker-server>
- Docker Hub (agent): <https://hub.docker.com/r/woodpeckerci/woodpecker-agent>
- Open Collective: <https://opencollective.com/woodpecker-ci>
- GitHub Sponsors: <https://github.com/sponsors/woodpecker-ci>
- Codeberg (real-world user): <https://codeberg.org>
- Weblate translation: <https://translate.woodpecker-ci.org>
