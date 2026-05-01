---
name: Cup
description: "Fast container image update checker. Docker or binary. Go. sergi0g/cup. CLI + web UI, Docker Hub/GHCR/Quay/lscr.io/Gitea support, JSON API, rate-limit-safe, tiny binary (5 MB)."
---

# Cup

**The easiest way to check for container image updates.** Cup compares your running container images against their registries and shows which ones have newer versions available. Go binary, fast (parallel checks), tiny (5 MB), and rate-limit-safe. CLI + optional web server with JSON API.

Built + maintained by **sergi0g**. MIT license.

- Upstream repo: <https://github.com/sergi0g/cup>
- Docs: <https://cup.sergi0g.dev/docs>
- Discord: <https://discord.gg/jmh5ctzwNG>
- GHCR: `ghcr.io/sergi0g/cup`

## Architecture in one minute

- **Go** binary — single executable, no runtime dependencies
- Reads running containers via **Docker socket** (or agent mode for remote)
- Queries container registries: Docker Hub, GHCR, Quay, lscr.io, Gitea (+ derivatives)
- Two usage modes:
  1. **CLI** — `cup check` → print update status and exit
  2. **Server** — `cup serve` → web UI + JSON API (`/api/v3/json`) for dashboards/integrations
- Does **not** auto-update containers — check-only by design
- Resource: **tiny** — 5.4 MB binary; event-driven; minimal CPU/RAM

## Compatible install methods

| Infra       | Runtime               | Notes                                             |
| ----------- | --------------------- | ------------------------------------------------- |
| **Docker**  | `ghcr.io/sergi0g/cup` | **Primary** — GHCR; mount Docker socket          |
| **Binary**  | GitHub Releases       | Single Go binary; run on host directly            |

## Install via Docker (server mode)

```yaml
services:
  cup:
    image: ghcr.io/sergi0g/cup:latest
    container_name: cup
    command: serve
    ports:
      - "8000:8000"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
    restart: unless-stopped
```

Visit `http://localhost:8000` for the web UI. JSON API at `http://localhost:8000/api/v3/json`.

## Install via binary (CLI)

```bash
# Download from https://github.com/sergi0g/cup/releases
chmod +x cup
./cup check        # check once and exit
./cup serve        # start web server
```

## Usage

```bash
# Check all running containers for updates (CLI)
cup check

# Check specific images
cup check nginx redis ghcr.io/homeassistant/home-assistant

# Output as JSON
cup check -r   # raw JSON output

# Start web server
cup serve --port 8000
```

## Configuration

Cup supports configuration for:
- **Authentication** — protect the web UI/API
- **Automatic refresh** — periodic background re-checks (configure interval)
- **Ignored registries** — skip checking certain registries
- **Ignored update types** — ignore major/minor/patch updates selectively
- **Include/exclude images** — filter which containers to check
- **Insecure registries** — allow HTTP registries
- **Multiple servers** (agent mode) — check containers on remote Docker hosts
- **Custom socket path** — if Docker socket is not at default location

Full config docs: <https://cup.sergi0g.dev/docs/configuration>

## JSON API

`GET /api/v3/json` returns update status for all containers as structured JSON. Easy to integrate with:
- **Homepage** widget
- **Home Assistant** (via REST sensor)
- Custom dashboards / scripts
- Cron-based notification scripts

## Supported registries

| Registry | Notes |
|----------|-------|
| Docker Hub | No rate limit exhaustion by design |
| GHCR (ghcr.io) | GitHub Container Registry |
| Quay (quay.io) | Red Hat / Quay.io |
| lscr.io | LinuxServer.io |
| Gitea | And derivatives (Forgejo, Gogs) |

## Gotchas

- **Cup checks, not updates.** By design, Cup doesn't pull or restart containers. It reports what's available and leaves the decision to you (or another tool like Watchtower). "Simple" is a design goal.
- **Docker socket access.** Cup needs the Docker socket to list running containers. Mount `:ro` (read-only) — Cup only reads container metadata, never writes.
- **Rate limits.** Cup is specifically designed not to exhaust Docker Hub's pull rate limits. It checks manifest digests rather than pulling images — much lighter. This was the original motivation for creating Cup.
- **Automatic refresh via cron or server mode.** In CLI mode, Cup exits after checking. For continuous monitoring, either run `cup serve` (has built-in auto-refresh) or schedule `cup check -r` with a cronjob.
- **Tag vs digest tracking.** Cup compares the current image digest against the registry's latest digest for the same tag. If you pin to a specific digest (not just a tag), Cup may show false "no update" since the tag hasn't changed.
- **Agent mode for remote servers.** Cup has an agent mode for checking containers on remote Docker hosts. See <https://cup.sergi0g.dev/docs/configuration/agent>.
- **Important changes notice.** The README links to a `NOTICE.md` about development changes — check it for the current project status.

## Backup

Cup is stateless — no data to back up. Docker socket is read-only.

## Upgrade

```sh
docker compose pull && docker compose up -d
```

## Project health

Active Go development, GHCR, docs site, Discord, JSON API, Homepage/Home Assistant integrations. Solo-maintained by sergi0g. MIT license.

## Container-update-checker-family comparison

- **Cup** — Go, check-only, web UI + JSON API, rate-limit-safe, tiny (5 MB), MIT
- **Watchtower** — Go, auto-update daemon (pulls + restarts); no check-only mode
- **Diun** — Go, check-only + notifications (email/Slack/etc.); feature-rich; heavier
- **What's up Docker (WUD)** — Node.js, check + notify + integrations; more complex
- **Renovate** — dependency update bot; Dockerfile/compose support; CI/CD focus

**Choose Cup if:** you want a fast, lightweight, rate-limit-safe container image update checker with a web UI and JSON API — without auto-updating anything.

## Links

- Repo: <https://github.com/sergi0g/cup>
- Docs: <https://cup.sergi0g.dev/docs>
- GHCR: `ghcr.io/sergi0g/cup`
- Discord: <https://discord.gg/jmh5ctzwNG>
