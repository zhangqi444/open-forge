---
name: Tugtainer
description: "Self-hosted Docker container auto-updater with web UI. Docker. Quenary/tugtainer. Multi-host agents, socket proxy, cron schedule, Apprise notifications, dependency-aware updates, OIDC auth."
---

# Tugtainer

**Self-hosted app for automating updates of your Docker containers.** Web UI with authentication, per-container config (check only or auto-update), cron scheduling, dependency-aware update order, multi-host agent support, socket proxy support, Apprise notifications, private registry support, and basic container controls (start/stop/logs/inspect). Automatic updates are **disabled by default** — opt-in per container.

Built + maintained by **Quenary**. Python backend + Angular frontend.

- Upstream repo: <https://github.com/Quenary/tugtainer>
- GHCR: `ghcr.io/quenary/tugtainer` + `ghcr.io/quenary/tugtainer-agent`

> ⚠️ **Not recommended for production environments** — upstream's own advisory. Test in staging first.

## Architecture in one minute

- **Python** backend + **Angular** frontend (single image)
- Port **9412** (app) + **9413** (agent)
- Connects to Docker via **socket** (direct mount or **socket proxy**)
- Persistent data in `/tugtainer` volume (config + update history)
- Optional **agent** containers for remote host management (connects back to main instance)
- Resource: **low** — Python app, infrequent polling

## Compatible install methods

| Infra        | Runtime                              | Notes                                                       |
| ------------ | ------------------------------------ | ----------------------------------------------------------- |
| **Docker**   | `ghcr.io/quenary/tugtainer:1`        | **Primary** — Docker Hub / GHCR                             |
| **Agent**    | `ghcr.io/quenary/tugtainer-agent:1`  | Deploy on remote hosts for multi-host management            |

## Inputs to collect

| Input                        | Example                           | Phase    | Notes                                                                                      |
| ---------------------------- | --------------------------------- | -------- | ------------------------------------------------------------------------------------------ |
| Docker socket / socket proxy | `/var/run/docker.sock:ro`         | Docker   | Direct mount or `DOCKER_HOST=tcp://socket-proxy:port`                                      |
| Admin password               | set on first login                | Auth     | Default password auth; OIDC optional                                                       |
| Agent secret                 | `AGENT_SECRET=CHANGE_ME`          | Security | For agent ↔ main instance authentication; change from default                             |
| Cron schedule                | `0 3 * * *` (3 AM daily)         | Config   | Configured in UI → Settings → Schedule                                                     |
| Apprise URL (optional)       | Discord / Slack / email           | Notify   | Any Apprise-supported service for update/failure notifications                             |

## Install via Docker (quick start)

```bash
# Create volume
docker volume create tugtainer_data

# Run app (with direct socket mount)
docker run -d -p 9412:80 \
  --name=tugtainer \
  --restart=unless-stopped \
  -v tugtainer_data:/tugtainer \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  ghcr.io/quenary/tugtainer:1
```

Visit `http://localhost:9412`.

## Install via Docker Compose (recommended — uses socket proxy)

Use [docker-compose.app.yml](https://github.com/Quenary/tugtainer/blob/main/docker-compose.app.yml) from upstream — it configures Tugtainer + a socket proxy by default:

```bash
curl -O https://raw.githubusercontent.com/Quenary/tugtainer/main/docker-compose.app.yml
docker compose -f docker-compose.app.yml up -d
```

The compose file uses a LinuxServer socket proxy (`CONTAINERS, IMAGES, POST, INFO, PING, NETWORKS` permissions).

## Install agent (remote host management)

On each **remote host**:

```bash
docker run -d -p 9413:8001 \
  --name=tugtainer-agent \
  --restart=unless-stopped \
  -e AGENT_SECRET="CHANGE_ME!" \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  ghcr.io/quenary/tugtainer-agent:1
```

Then in the main Tugtainer UI: Menu → Hosts → Add → enter agent host:9413 + secret.

## First boot

1. Deploy app (+ agent on remote hosts if needed).
2. Visit `http://localhost:9412` → set admin password.
3. Configure **schedule** (Settings → Schedule — cron syntax).
4. Configure **notifications** (Settings → Notifications — Apprise URL + Jinja2 template).
5. Review containers — set each to "Check Only" or "Auto Update" per your comfort level.
6. Mark Tugtainer itself and any agent/socket-proxy containers as `dev.quenary.tugtainer.protected=true` (or use the UI protection toggle) so they can't be auto-updated by the app.
7. Run a **manual check** first to verify digest comparison is working.
8. Enable scheduled auto-check/update once confident.

## Custom labels

Apply on containers to control Tugtainer behavior:

```yaml
labels:
  dev.quenary.tugtainer.protected: "true"       # cannot be stopped/updated by Tugtainer
  dev.quenary.tugtainer.depends_on: "postgres,redis"  # custom dependency ordering
```

## Backup

```sh
docker compose stop tugtainer
sudo tar czf tugtainer-$(date +%F).tgz <tugtainer_data>/
docker compose start tugtainer
```

Contents: Tugtainer config, update history, notification templates, host definitions.

## Upgrade

```sh
docker pull ghcr.io/quenary/tugtainer:1 && docker compose up -d
```

> ⚠️ Do **not** include Tugtainer (or its agent) in the set of containers it auto-updates — they are protected by default in the upstream compose. Updating a running agent mid-operation breaks communication.

## Gotchas

- **Not for production — upstream's own warning.** Treat as alpha/beta quality. Test updates in staging. Auto-updating containers in production without rollback testing is risky regardless of the tool.
- **Protect Tugtainer + agent + socket-proxy containers.** If these get auto-updated mid-run, you'll have a broken update pipeline. The upstream compose marks them protected by default — don't remove that.
- **Dependency graph handles compose `depends_on`.** When container A depends on B, Tugtainer stops A before stopping B, and starts B before starting A during an update. This avoids cascading failures.
- **"available(notified)" vs "available".** After Tugtainer notifies about a new image once, subsequent checks show `available(notified)` — suppressed in the default notification template (no duplicate alerts). A truly new image resets to `available`.
- **Socket proxy permissions.** If using a socket proxy, enable at minimum: `CONTAINERS, IMAGES, POST, INFO, PING` for check; add `NETWORKS` for update.
- **Private registries.** Mount `~/.docker/config.json` (containing registry auth) as `:ro` into the Tugtainer (or agent) container — Docker CLI handles the rest.
- **OIDC auth from v1.6.0.** Password auth is default; OIDC configurable via env vars. See `.env.example` in the repo.
- **Rollback on failure.** If container recreation fails, Tugtainer attempts to restore the old image. "rolled_back" in notification = update failed but old container is back. "failed" = full failure, old container not restored.
- **API is documented.** Swagger at `/api/docs`, Redoc at `/api/redoc`. Public endpoints (`/api/public/summary` etc.) require `ENABLE_PUBLIC_API=true`.

## Project health

Active Python + Angular development, multi-host support, OIDC, socket proxy, Apprise, dependency graph. Solo-maintained by Quenary. GHCR CI.

## Container-auto-update-family comparison

- **Tugtainer** — Python + Angular, web UI, multi-host agents, dependency-aware, socket proxy, OIDC
- **Watchtower** — Go, daemon, no UI, most widely deployed, simple
- **Diun** — Go, notification-only (no auto-update), great for alerting
- **Portainer** — full container management UI; update via Stack/Service redeploy
- **Renovate** — updates Dockerfiles/compose files via PR; not a runtime updater

**Choose Tugtainer if:** you want a web UI for Docker container update management with multi-host support, per-container control, and dependency-aware ordering — and can accept an early-stage project.

## Links

- Repo: <https://github.com/Quenary/tugtainer>
- docker-compose.app.yml: <https://github.com/Quenary/tugtainer/blob/main/docker-compose.app.yml>
- docker-compose.agent.yml: <https://github.com/Quenary/tugtainer/blob/main/docker-compose.agent.yml>
- Apprise: <https://github.com/caronc/apprise>
- Watchtower (simpler alt): <https://containrrr.dev/watchtower>
