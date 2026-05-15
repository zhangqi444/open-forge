---
name: OneDev
description: Self-hosted Git server with CI/CD, Kanban, packages, built-in AI (MCP server), and code-intelligence features. A single-binary Java alternative to GitLab / Forgejo. MIT.
---

# OneDev

OneDev is an "everything in one" self-hosted developer platform: Git hosting with pull requests, branch protection, code review, language-aware symbol search across any commit, automated Kanban boards tied to issues, native CI/CD (YAML in-repo), built-in package registry (Docker, Maven, npm, PyPI, etc.), service-desk email-to-issue, OpenCode / Claude / Codex "Vibe Coding" workspaces in-browser, and an MCP server for AI agents.

Competes with GitLab Community, Gitea + Woodpecker, and Forgejo + forgejo-runner — OneDev packages all of that in a single JVM process.

- Upstream repo: <https://github.com/theonedev/onedev> (mirror; development happens at <https://code.onedev.io>)
- Docs: <https://docs.onedev.io>
- Docker Hub: <https://hub.docker.com/r/1dev/server>
- Upstream docker-compose: <https://github.com/theonedev/onedev/blob/main/server-product/docker/docker-compose.yaml>

## Architecture in one minute

Two containers by default:

1. **`1dev/server`** — the entire OneDev: Git server, web UI, issue tracker, CI/CD scheduler, package registry. Also mounts `/var/run/docker.sock` so CI jobs can run Docker containers on the host directly.
2. **`postgres:14`** — default database. OneDev also supports MySQL, SQL Server, Oracle, and embedded HSQLDB (testing only).

CI runners are optional separate processes (`1dev/agent`). For small setups, OneDev uses `server-docker` executor: runs CI jobs as Docker containers on the same host via the mounted socket. For scale, deploy remote agents or Kubernetes executors.

Ports: `6610` (HTTP UI + API), `6611` (SSH for git).

## Compatible install methods

| Infra      | Runtime                                          | Notes                                                                   |
| ---------- | ------------------------------------------------ | ----------------------------------------------------------------------- |
| Single VM  | Docker Compose (`1dev/server` + `postgres:14`)   | **Recommended for self-host.** Matches upstream's published compose      |
| Single VM  | Bare-metal JVM 17+ + external DB                 | Upstream ships a `.zip`; runs under systemd                              |
| Kubernetes | Helm chart                                       | <https://code.onedev.io/onedev/server/~files/kubernetes/>                |
| Managed    | code.onedev.io (free public tier) / OneDev Cloud | Upstream-hosted                                                         |

## Inputs to collect

| Input                           | Example                                          | Phase    | Notes                                                          |
| ------------------------------- | ------------------------------------------------ | -------- | -------------------------------------------------------------- |
| Public URL                      | `https://onedev.example.com`                     | Runtime  | Set via `hibernate_` env or server config UI on first boot     |
| Postgres password               | strong value                                     | DB       | **Upstream default is `changeit` in both places** — replace     |
| Admin account                   | created during first-boot web setup              | Bootstrap | Wizard runs on first HTTP visit                                |
| Git SSH port                    | `6611:6611`                                      | Network  | Or re-map to `22` if OneDev is the only app on the host        |
| HTTP port                       | `6610:6610`                                      | Network  | Behind TLS-terminating reverse proxy                           |
| `/var/run/docker.sock` mount    | host docker socket                               | CI       | Required for server-docker CI executor                         |
| Data volume                     | `./onedev:/opt/onedev`                           | Data     | Git repos, attachments, settings, logs                         |

## Install via upstream Docker Compose

From <https://github.com/theonedev/onedev/blob/main/server-product/docker/docker-compose.yaml>:

```yaml
services:
  onedev:
    image: 1dev/server:15.0.7          # pin to specific release tag in production
    restart: always
    ports:
      - "6610:6610"                    # HTTP
      - "6611:6611"                    # SSH git
    volumes:
      - ./onedev:/opt/onedev
      - /var/run/docker.sock:/var/run/docker.sock   # required for server-docker CI executor
    environment:
      # Use a strong password here AND in postgres service below
      hibernate_connection_password: "REPLACE_WITH_STRONG_PASSWORD"
      hibernate_dialect: io.onedev.server.persistence.PostgreSQLDialect
      hibernate_connection_driver_class: org.postgresql.Driver
      hibernate_connection_url: jdbc:postgresql://postgres:5432/onedev
      hibernate_connection_username: postgres
    tty: true
    depends_on:
      postgres:
        condition: service_healthy

  postgres:
    image: postgres:14
    restart: always
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 5s
      timeout: 5s
      retries: 5
      start_period: 30s
    environment:
      POSTGRES_PASSWORD: "REPLACE_WITH_STRONG_PASSWORD"    # must match hibernate_connection_password above
      POSTGRES_USER: "postgres"
      POSTGRES_DB: "onedev"
    expose:
      - "5432"
    volumes:
      - ./onedev/site/postgres:/var/lib/postgresql/data
```

### Bring it up

```sh
docker compose up -d

# First boot takes ~90 s. Browse http://<host>:6610
# Web wizard asks for admin username/email/password + server URL + HTTPS / HTTP.
```

### Production reverse proxy

Place Caddy/Traefik/nginx in front of :6610 (HTTP). Example Caddyfile:

```caddyfile
onedev.example.com {
    reverse_proxy localhost:6610
}
```

For SSH git, either:

- Let SSH on :6611 be direct (update DNS + firewall), or
- Put `sshpiperd` / `sslh` in front if port 22 is taken.

## Data & config layout

Inside `/opt/onedev` (mounted as `./onedev` on host):

- `site/` — database (if embedded HSQLDB), settings, attachments
- `site/projects/` — Git repositories (bare repos, one per project)
- `site/buildlogs/` — CI build artifacts
- `site/lfs/` — Git LFS objects
- `conf/` — server.properties, hibernate.properties (generated on first boot)
- `logs/` — application logs

When using Postgres, only git repos + artifacts live in the data volume; database is in the Postgres volume.

## Backup

From <https://docs.onedev.io/administration-guide/backup-restore/>:

```sh
# Stop OneDev (database consistency):
docker compose stop onedev

# Postgres dump
docker compose exec -T postgres pg_dump -U postgres onedev | gzip > onedev-db-$(date +%F).sql.gz

# Data volume (git repos, artifacts, LFS)
tar czf onedev-data-$(date +%F).tgz ./onedev

docker compose start onedev
```

Alternative: OneDev's built-in `system-backup` via admin UI produces a single zip including DB + data. See upstream docs for restore procedure.

## Upgrade

1. Releases: <https://github.com/theonedev/onedev/releases> (and upstream at <https://code.onedev.io/onedev/server>).
2. Update `image:` tag to new version, `docker compose pull && docker compose up -d`.
3. OneDev runs schema migrations automatically on startup — watch logs for `INFO Upgrading database ...`.
4. **Major upgrades** (e.g. 9.x → 10.x) may require Java version bumps or Postgres version bumps — read release notes at <https://docs.onedev.io/release-notes/>.
5. Downgrade is **not supported** once migrations run; always back up before upgrading.

## Gotchas

- **Upstream default password `changeit`** appears in TWO places in the compose (`hibernate_connection_password` and `POSTGRES_PASSWORD`). Change BOTH to the same strong value. Mismatched = container fails to connect to DB.
- **Development happens at `code.onedev.io`, not GitHub.** The GitHub repo is a mirror; bug reports and PRs go to the self-hosted OneDev instance. The `main` branch on GitHub is a build artifact, not a dev branch.
- **Docker socket mount is broad access.** `/var/run/docker.sock` lets OneDev spawn containers on the host — essential for server-docker CI but also means a compromised OneDev process can pwn the host. Use a remote agent or Kubernetes executor for untrusted-PR builds.
- **Server-docker executor by default runs jobs as root.** Per-job users + cgroups help but isolation is weaker than a dedicated runner VM. For public-facing OneDev accepting community contributions, use remote agents on throwaway VMs.
- **Postgres 14 is the default in the compose, but OneDev supports newer.** You can bump to `postgres:17` but must `pg_upgrade` the data dir first. OneDev itself is version-agnostic on Postgres 10+.
- **SSH git on port 6611 is non-standard.** Most git clients need `ssh://git@host:6611/owner/repo` in the URL. Upstream suggests either mapping 6611 to 22 on the host (if nothing else uses it) or documenting the non-standard port.
- **First-run admin account is whoever clicks the URL first.** Bootstrap race: bring up OneDev on a private network first, create admin, THEN expose to the internet.
- **`tty: true` is required** in the compose — OneDev's JVM log output needs it for proper stderr handling.
- **License is MIT since 2022.** Older versions were under a custom non-commercial license; verify you're on a recent version if license compliance matters.
- **Project hierarchy (trees)** is a OneDev-specific feature: parent projects can pass settings (permissions, CI config) down to children. Powerful for mono-orgs; confusing if you come from GitLab groups model.
- **Code search requires language-specific parsers.** Ship with Java/JS/TS/Python/Go/Kotlin/Rust/C/C++/etc. New languages may need waiting for upstream parser work.
- **AI features ("Vibe Coding", MCP server)** require an OpenAI-compatible LLM endpoint configured in admin. Not on by default; no data leakage until you configure it.
- **Package registry scope: pull-through + local publish.** OneDev can proxy npm / Maven / PyPI / Docker Hub and cache locally. Enable per-project in settings.
- **Service desk email integration** requires SMTP + IMAP config — separate from outgoing SMTP alone. Without IMAP, email-to-issue doesn't work.
- **Single-replica.** No built-in HA. For HA, rely on filesystem replication + Postgres replication + active/passive failover (not zero downtime).
- **`hibernate_*` environment variables** are OneDev's way of passing JDBC config. Dot-to-underscore mapping: `hibernate.connection.url` → `hibernate_connection_url`. See upstream for full list.
- **Self-hostable CI runners** (`1dev/agent` image) register with the OneDev server via a join token. Use these for isolated/untrusted workloads.
- **Alternatives worth knowing:**
  - **Gitea + Woodpecker / Drone** — more modular, less integrated
  - **Forgejo** — Gitea community fork, actively developed
  - **GitLab Community Edition** — more features, much heavier
  - **Gogs** — minimal git, no CI

## Links

- Repo (mirror): <https://github.com/theonedev/onedev>
- Upstream (dogfood): <https://code.onedev.io>
- Docs: <https://docs.onedev.io>
- Docker Hub: <https://hub.docker.com/r/1dev/server>
- Compose file: <https://github.com/theonedev/onedev/blob/main/server-product/docker/docker-compose.yaml>
- Installation guide: <https://docs.onedev.io/category/installation>
- Backup / restore: <https://docs.onedev.io/administration-guide/backup-restore/>
- Release notes: <https://docs.onedev.io/release-notes/>
- Tutorials: <https://docs.onedev.io/tutorials/>
- MCP server: <https://docs.onedev.io/tutorials/ai/working-with-mcp>
