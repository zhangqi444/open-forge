# Github Ntfy (ntfy_alerts)

**Release notification bot for GitHub and Docker Hub** — Rust-based service that polls GitHub repositories and Docker Hub for new releases and pushes notifications to ntfy, Gotify, Discord, or Slack. Runs as a single Docker container with a simple web UI.

**Official site:** https://github.com/BreizhHardware/ntfy_alerts
**Source:** https://github.com/BreizhHardware/ntfy_alerts
**License:** GPL-3.0

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any VPS / bare metal | Docker | Recommended; multi-arch (amd64, arm64, armv7) |
| Any Linux | Rust binary | Build from source with `cargo build --release` |

---

## Inputs to Collect

### Phase 1 — Planning
- Notification targets: ntfy, Gotify, Discord, Slack (one or more)
- GitHub repositories and/or Docker Hub images to watch
- Check interval (default: 3600 seconds / 1 hour)

### Phase 2 — Deploy
- `USERNAME` and `PASSWORD` — web UI credentials (required)
- Notification service credentials (one or more):
  - ntfy: `NTFY_URL`
  - Gotify: `GOTIFY_URL` + `GOTIFY_TOKEN`
  - Discord: `DISCORD_WEBHOOK_URL`
  - Slack: `SLACK_WEBHOOK_URL`
- GitHub token (`GHNTFY_TOKEN`) — optional but recommended to avoid rate limits; needs `repo`, `read:org`, `read:user` permissions
- Docker Hub credentials (`DOCKER_USERNAME`, `DOCKER_PASSWORD`) — optional, for private repos or to avoid rate limits

---

## Software-Layer Concerns

- **Stack:** Rust; rewritten from Python in v2.0 for performance and lower resource use
- **Poll interval:** `GHNTFY_TIMEOUT` env var; default 3600 seconds
- **Data persistence:** Mount `/data` volume to persist watched repo/image list and last-seen release state
- **Web UI:** Exposed on port 80; manage watched repos/images through the browser

---

## Deployment

```yaml
services:
  github-ntfy:
    image: breizhhardware/github-ntfy:latest
    container_name: github-ntfy
    restart: unless-stopped
    ports:
      - "8080:80"
    environment:
      - USERNAME=admin
      - PASSWORD=your-secure-password
      - NTFY_URL=https://ntfy.example.com/your-topic   # ntfy
      # - GOTIFY_URL=https://gotify.example.com        # Gotify
      # - GOTIFY_TOKEN=your-gotify-token
      # - DISCORD_WEBHOOK_URL=https://discord.com/...  # Discord
      # - SLACK_WEBHOOK_URL=https://hooks.slack.com/.. # Slack
      - GHNTFY_TIMEOUT=3600
      - GHNTFY_TOKEN=your-github-token                 # optional but recommended
    volumes:
      - ./data:/data
```

---

## Upgrade Procedure

```bash
docker compose pull
docker compose up -d
```

---

## Gotchas

- **`USERNAME` and `PASSWORD` are required** — the web UI will not start without them
- **GitHub token recommended** — without it, unauthenticated GitHub API requests are rate-limited to 60/hour; a token raises this to 5000/hour
- **`/data` volume required for persistence** — without it, the list of watched repos resets on container restart
- **Notification service config is optional per service** — configure only the services you actually use; unconfigured services are silently skipped
- **No multi-architecture currently in TODO** — listed as a planned improvement; current multi-arch support covers amd64/arm64/armv7

---

## Links

- Upstream README: https://github.com/BreizhHardware/ntfy_alerts#readme
- Related: ntfy (https://github.com/binwiederhier/ntfy)
