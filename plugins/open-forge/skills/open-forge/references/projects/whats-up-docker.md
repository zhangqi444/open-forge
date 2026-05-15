---
name: whats-up-docker
description: Recipe for WUD (What's Up Docker?) — monitors Docker containers and notifies when new image versions are available.
---

# WUD — What's Up Docker?

Monitors running Docker containers and detects when newer image versions are available upstream. Sends notifications via email, Slack, Telegram, Discord, Ntfy, Pushover, and many more. Can optionally trigger automatic updates. Lightweight Node.js app. Upstream: <https://github.com/getwud/wud>. Docs: <https://getwud.github.io/wud/>. License: MIT.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker | <https://hub.docker.com/r/getwud/wud> | Yes | Recommended |
| Docker Compose | <https://getwud.github.io/wud/> | Yes | Standard compose deployment |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| infra | Port for WUD web UI? | Port (default 3000) | All |
| software | Notification channels? | slack / telegram / discord / email / ntfy / etc. | Required for alerts |
| software | Notification credentials? | Channel-specific tokens/URLs | Required per notifier |
| software | Enable automatic updates? | Boolean | Optional; triggers `docker pull` + restart |
| software | Watchers? | docker socket / remote Docker hosts | Default: local socket |

## Software-layer concerns

### Docker Compose

```yaml
services:
  wud:
    image: getwud/wud:8.2.2
    container_name: wud
    restart: unless-stopped
    ports:
      - "3000:3000"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
    environment:
      # Watcher: local Docker socket (default)
      WUD_WATCHER_LOCAL_SOCKET: /var/run/docker.sock

      # Notifier: Slack
      WUD_NOTIFIER_SLACK_URL: https://hooks.slack.com/services/YOUR/WEBHOOK/URL

      # Notifier: Telegram
      # WUD_NOTIFIER_TELEGRAM_BOTTOKEN: 1234567890:ABCdef...
      # WUD_NOTIFIER_TELEGRAM_CHATID: -100123456789

      # Notifier: Ntfy
      # WUD_NOTIFIER_NTFY_URL: https://ntfy.sh
      # WUD_NOTIFIER_NTFY_TOPIC: wud-updates

      # Optional: trigger auto-updates (pulls + restarts containers)
      # WUD_TRIGGER_DOCKER_LOCAL_PRUNE: true
```

### Environment variable naming pattern

WUD uses a flat env var convention: `WUD_<COMPONENT>_<NAME>_<OPTION>`

| Component | Prefix | Example |
|---|---|---|
| Watcher | WUD_WATCHER_<name>_ | WUD_WATCHER_LOCAL_SOCKET |
| Registry | WUD_REGISTRY_<name>_ | WUD_REGISTRY_HUB_LOGIN / WUD_REGISTRY_HUB_TOKEN |
| Notifier | WUD_NOTIFIER_<name>_ | WUD_NOTIFIER_SLACK_URL |
| Trigger | WUD_TRIGGER_<name>_ | WUD_TRIGGER_DOCKER_LOCAL_PRUNE |

### Private registry authentication

```bash
# Docker Hub (to avoid rate limits)
WUD_REGISTRY_HUB_LOGIN=myusername
WUD_REGISTRY_HUB_TOKEN=my-hub-token

# GHCR
WUD_REGISTRY_GHCR_TOKEN=ghp_mytoken

# Self-hosted registry
WUD_REGISTRY_MYREGISTRY_URL=https://registry.example.com
WUD_REGISTRY_MYREGISTRY_LOGIN=user
WUD_REGISTRY_MYREGISTRY_PASSWORD=pass
```

### Container label overrides

Control WUD behavior per-container with Docker labels:

```yaml
labels:
  # Exclude this container from WUD monitoring
  wud.watch: "false"

  # Pin to a specific semver range (only notify for minor/patch updates)
  wud.tag.include: "^\\d+\\.\\d+\\.\\d+$"

  # Use a display name in notifications
  wud.display.name: "My App"

  # Link to container update docs
  wud.link.template: "https://github.com/myorg/myapp/releases/tag/${major}.${minor}.${patch}"
```

## Upgrade procedure

```bash
docker compose pull && docker compose up -d
```

## Gotchas

- Docker socket access: WUD needs read-only access to the Docker socket to inspect running containers and their image digests. Mounting `:ro` limits to read-only.
- Automatic updates are opt-in and risky: enabling triggers can automatically restart production containers. Test thoroughly. Consider using WUD only for notifications and handling updates manually or via CI/CD.
- Rate limits: Docker Hub rate-limits unauthenticated image manifest checks. Configure `WUD_REGISTRY_HUB_LOGIN` + `WUD_REGISTRY_HUB_TOKEN` to avoid false negatives.
- Semver tags only: WUD works best with semantic versioning tags (e.g. `1.2.3`). Containers using only `:latest` or date-based tags won't get meaningful version comparisons.
- Local Docker socket vs remote: WUD can monitor remote Docker hosts via TCP — configure additional watcher entries for each remote host.

## Links

- GitHub: <https://github.com/getwud/wud>
- Docs: <https://getwud.github.io/wud/>
- Docker Hub: <https://hub.docker.com/r/getwud/wud>
- Notifiers reference: <https://getwud.github.io/wud/configuration/notifiers/>
- Triggers reference: <https://getwud.github.io/wud/configuration/triggers/>
