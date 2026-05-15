---
name: watchtower-project
description: Watchtower recipe for open-forge. Covers Docker-based deployment of Watchtower, which automatically monitors running Docker containers and pulls updated images, then restarts containers with the new image. Includes configuration for monitor-only mode, label-based opt-in/opt-out, notifications (Slack/email/gotify), and production safety guidance.
---

# Watchtower

Watchtower automatically monitors running Docker containers and pulls updated images, then restarts containers with the new image. Upstream: <https://github.com/containrrr/watchtower>. Docs: <https://containrrr.dev/watchtower/>.

Watchtower itself is a stateless Docker container that watches the Docker socket and polls registries on a configurable interval. On finding a newer image for a running container, it pulls it and restarts the container in-place (same name, ports, env, volumes). In production environments, **monitor-only mode** is strongly recommended — Watchtower observes and sends notifications without restarting anything, leaving upgrades under human control.

## Install method

| Method | When to use |
|---|---|
| Docker run (single container) | Quick start, ad-hoc use |
| Docker Compose | Persistent deployment alongside your other services |

## Inputs to collect

| Phase | Prompt | Applicability |
|---|---|---|
| preflight | "Should Watchtower auto-update containers, or just monitor and notify?" | Drives `WATCHTOWER_MONITOR_ONLY` |
| preflight | "How often should Watchtower check for updates? (seconds, default 86400 = 24h)" | Sets `WATCHTOWER_POLL_INTERVAL` |
| preflight | "Should old images be cleaned up after an update?" | Sets `WATCHTOWER_CLEANUP` |
| notifications | "Which notification channel? Slack / email / Gotify / none" | Loads the matching notification block |
| notifications | Slack: "Slack webhook URL?" | `WATCHTOWER_NOTIFICATION_SLACK_HOOK_URL` |
| notifications | Email: "SMTP host, port, user, password, from, to?" | `WATCHTOWER_NOTIFICATION_EMAIL_*` env vars |
| notifications | Gotify: "Gotify server URL and token?" | `WATCHTOWER_NOTIFICATION_GOTIFY_URL` / `_TOKEN` |

## Docker Compose deployment

```yaml
# compose.yaml
services:
  watchtower:
    image: containrrr/watchtower:v1.7.1
    container_name: watchtower
    restart: unless-stopped
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      WATCHTOWER_POLL_INTERVAL: "${WATCHTOWER_POLL_INTERVAL:-86400}"
      WATCHTOWER_CLEANUP: "${WATCHTOWER_CLEANUP:-true}"
      WATCHTOWER_MONITOR_ONLY: "${WATCHTOWER_MONITOR_ONLY:-false}"
      # Add notification vars below as needed
```

```bash
docker compose up -d
docker compose logs -f watchtower
```

## Key environment variables

| Variable | Default | Purpose |
|---|---|---|
| `WATCHTOWER_POLL_INTERVAL` | `86400` (24h) | Seconds between registry polls |
| `WATCHTOWER_CLEANUP` | `false` | Remove old images after update |
| `WATCHTOWER_MONITOR_ONLY` | `false` | Check for updates but do not apply them |
| `WATCHTOWER_NOTIFICATIONS` | (unset) | Comma-separated notification types: `slack`, `email`, `gotify`, `msteams`, `shoutrrr` |
| `WATCHTOWER_NOTIFICATION_SLACK_HOOK_URL` | (unset) | Slack incoming webhook URL |
| `WATCHTOWER_NOTIFICATION_EMAIL_FROM` | (unset) | SMTP from address |
| `WATCHTOWER_NOTIFICATION_EMAIL_TO` | (unset) | SMTP to address |
| `WATCHTOWER_NOTIFICATION_GOTIFY_URL` | (unset) | Gotify server URL |
| `WATCHTOWER_NOTIFICATION_GOTIFY_TOKEN` | (unset) | Gotify application token |
| `WATCHTOWER_LABEL_ENABLE` | `false` | Only update containers with the `com.centurylinklabs.watchtower.enable=true` label |
| `WATCHTOWER_SCHEDULE` | (unset) | Cron expression (alternative to poll interval, e.g. `0 4 * * *` for 4 AM daily) |
| `WATCHTOWER_TIMEOUT` | `10s` | Timeout for stopping a container before a restart |
| `WATCHTOWER_INCLUDE_STOPPED` | `false` | Also update stopped containers |
| `WATCHTOWER_REVIVE_STOPPED` | `false` | Start stopped containers after update |
| `WATCHTOWER_NO_RESTART` | `false` | Pull but do not restart containers (update images only) |

## Label-based opt-in / opt-out

### Opt-out (default mode — update everything except labeled containers)

Add to any container you want Watchtower to skip:

```yaml
labels:
  - "com.centurylinklabs.watchtower.enable=false"
```

### Opt-in (label-enable mode — only update labeled containers)

Set `WATCHTOWER_LABEL_ENABLE=true` on Watchtower, then add to each container you want updated:

```yaml
labels:
  - "com.centurylinklabs.watchtower.enable=true"
```

## Notification examples

### Slack

```yaml
environment:
  WATCHTOWER_NOTIFICATIONS: slack
  WATCHTOWER_NOTIFICATION_SLACK_HOOK_URL: "https://hooks.slack.com/services/XXX/YYY/ZZZ"
  WATCHTOWER_NOTIFICATION_SLACK_IDENTIFIER: "watchtower-myserver"
```

### Email (SMTP)

```yaml
environment:
  WATCHTOWER_NOTIFICATIONS: email
  WATCHTOWER_NOTIFICATION_EMAIL_FROM: "watchtower@example.com"
  WATCHTOWER_NOTIFICATION_EMAIL_TO: "admin@example.com"
  WATCHTOWER_NOTIFICATION_EMAIL_SERVER: "smtp.example.com"
  WATCHTOWER_NOTIFICATION_EMAIL_SERVER_PORT: "587"
  WATCHTOWER_NOTIFICATION_EMAIL_SERVER_USER: "watchtower@example.com"
  WATCHTOWER_NOTIFICATION_EMAIL_SERVER_PASSWORD: "${SMTP_PASSWORD}"
  WATCHTOWER_NOTIFICATION_EMAIL_DELAY: "2"
```

### Gotify

```yaml
environment:
  WATCHTOWER_NOTIFICATIONS: gotify
  WATCHTOWER_NOTIFICATION_GOTIFY_URL: "https://gotify.example.com"
  WATCHTOWER_NOTIFICATION_GOTIFY_TOKEN: "${GOTIFY_TOKEN}"
```

## Recommended production configuration

In production, never auto-apply updates blindly. Use monitor-only mode with notifications so you are notified when new images are available and can update on your schedule:

```yaml
environment:
  WATCHTOWER_MONITOR_ONLY: "true"
  WATCHTOWER_NOTIFICATIONS: slack      # or email or gotify
  WATCHTOWER_POLL_INTERVAL: "43200"    # check every 12h
```

When ready to apply the update, do it explicitly:

```bash
docker compose pull <service>
docker compose up -d <service>
```

## Run once (manual update, then exit)

```bash
docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  containrrr/watchtower \
  --run-once
```

Useful for triggering an immediate check from CI or a cron job.

## Verify

```bash
docker compose logs watchtower        # startup + recent checks
docker compose ps                     # container is 'running'
```

A healthy startup log looks like:

```
time="..." level=info msg="Watchtower 1.x.x"
time="..." level=info msg="Starting Watchtower and scheduling first run..."
```

## Lifecycle (upgrade)

Watchtower is stateless — upgrading is just pulling the new image and recreating the container:

```bash
docker compose pull watchtower
docker compose up -d watchtower
```

## Gotchas

- **Auto-update can break production.** An upstream image can ship a breaking change or a bug at any time. Use `WATCHTOWER_MONITOR_ONLY=true` + notifications in production and apply updates manually after review.
- **Requires Docker socket access.** Mounting `/var/run/docker.sock` gives Watchtower (and by extension, any image it runs) root-equivalent access to the Docker daemon. Ensure the image is trusted.
- **Label-enable mode changes the default.** When `WATCHTOWER_LABEL_ENABLE=true`, only explicitly opted-in containers are updated. All others (including Watchtower itself if not labeled) are skipped.
- **Watchtower does not update itself by default.** If you want Watchtower to self-update, add the opt-in label to its own service definition.
- **Private registries.** For images pulled from private registries, provide credentials via `~/.docker/config.json` (mount it as a volume: `-v $HOME/.docker/config.json:/config.json`).
- **`WATCHTOWER_SCHEDULE` vs `WATCHTOWER_POLL_INTERVAL`.** Use one or the other — if `WATCHTOWER_SCHEDULE` is set, `WATCHTOWER_POLL_INTERVAL` is ignored.
- **Timeout.** If a container takes longer than `WATCHTOWER_TIMEOUT` to stop gracefully, Watchtower force-kills it. Increase `WATCHTOWER_TIMEOUT` for services with slow shutdown (e.g. databases).
