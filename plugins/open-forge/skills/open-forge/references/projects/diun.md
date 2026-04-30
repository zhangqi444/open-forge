---
name: Diun
description: "Docker Image Update Notifier — watches registries for new tags/digests + notifies via Slack/Discord/Telegram/email/webhook/Gotify/Matrix/ntfy/Apprise/Teams/RocketChat. Single Go binary or container. Great for keeping self-hosted stacks current. MIT."
---

# Diun

Diun (**D**ocker **I**mage **U**pdate **N**otifier) is **"silent image drift kills me — tell me when to update"** — a tiny Go utility that watches container registries for new tags or digest changes on images you care about. Run it alongside your existing stack; it notifies you through the channels you already use when updates are available.

Built + maintained by **Maxime Vaillancourt / crazy-max** — prolific maintainer of many well-loved Docker+Go tools (e.g., `diun`, `ddns-route53`, `retry-go`, Docker buildx work).

Use case: **You run 20 containers on your homelab/VPS. You fall behind on updates because manually watching each registry is tedious. Diun polls + notifies. You decide when to update.**

Features (per upstream + docs):

- **Watches providers**: Docker (running containers) / Swarm / Kubernetes / Nomad / file (YAML list) / static registry lookup
- **Notifies via**: Slack, Discord, Telegram, email, webhook, Gotify, Matrix, ntfy, Apprise, Teams, RocketChat, MQTT, ScriptExecutor, Pushover, mail, more
- **Registry support**: Docker Hub, GitHub Container Registry, GitLab Container Registry, Quay, AWS ECR, Azure Container Registry, Google Artifact Registry, Harbor, private registries
- **Scheduled scans** via cron expressions
- **Digest change detection** — catches rebuilt-same-tag cases (security rebuilds, `latest` updates)
- **Configurable watch criteria** — include/exclude tag patterns
- **Single binary** — Go
- **Docker image** `crazymax/diun` for containerized deploy

- Upstream repo: <https://github.com/crazy-max/diun>
- Docs: <https://crazymax.dev/diun/>
- Docker Hub: <https://hub.docker.com/r/crazymax/diun>
- Releases: <https://github.com/crazy-max/diun/releases>
- Sponsor: <https://github.com/sponsors/crazy-max>
- PayPal: <https://www.paypal.me/crazyws>

## Architecture in one minute

- **Go binary** or Docker image
- **SQLite** (internal state: last-seen tags/digests)
- **Polls** configured providers on cron schedule
- **Pushes notifications** — does not self-update; you read the alert, then upgrade manually
- **Resource**: tiny — ~30 MB RAM; minimal CPU except during scans

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Single VM          | **Docker (`crazymax/diun`)** with Docker socket mounted            | **Upstream-primary**                                                               |
| Bare-metal         | **Go binary** — Linux / macOS / Windows / ARM                              | From GitHub Releases                                                                       |
| Swarm              | Watch Swarm services provider                                                           | Documented                                                                                              |
| Kubernetes         | Watch K8s workloads provider                                                                          | Documented                                                                                              |
| Nomad              | Watch Nomad provider                                                                                    | Documented                                                                                              |
| File provider      | YAML list of explicit images                                                                                      | Mix/match                                                                                                         |

## Inputs to collect

| Input                | Example                                                        | Phase        | Notes                                                                    |
| -------------------- | -------------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Docker socket        | `/var/run/docker.sock` (read-only)                               | Provider     | For "watch running containers" mode                                              |
| Config file          | `diun.yml` — watch rules + cron + notifications                  | Config       | Upstream has full schema docs                                                            |
| Notification channel | Slack webhook / Telegram bot token / Discord webhook / email / etc.     | Notify       | One or more channels                                                                                 |
| Cron schedule        | `0 */6 * * *` (every 6h) / `@every 30m`                                                       | Schedule     | Per-watch override possible                                                                                            |
| Registry auth (opt)  | Docker Hub / private registry creds                                                                       | Auth         | For private images                                                                                                 |

## Install via Docker

```yaml
services:
  diun:
    image: crazymax/diun:latest                # pin specific version in prod
    container_name: diun
    restart: always
    environment:
      TZ: UTC
      LOG_LEVEL: info
      DIUN_WATCH_WORKERS: "10"
      DIUN_WATCH_SCHEDULE: "0 */6 * * *"
      DIUN_PROVIDERS_DOCKER: "true"
      DIUN_NOTIF_TELEGRAM_TOKEN: ${TG_TOKEN}
      DIUN_NOTIF_TELEGRAM_CHATIDS: ${TG_CHAT_ID}
    volumes:
      - ./data:/data
      - /var/run/docker.sock:/var/run/docker.sock:ro        # read-only
```

## First boot

1. Start Diun → reads Docker socket → enumerates running containers
2. For each container, checks registry for newer tags/digests
3. Reports initial state (all currently-watched images + last-seen digest)
4. On next scheduled scan, posts notifications for any changes
5. You receive the notification → decide whether to `docker pull` + `docker compose up -d` (Diun does NOT self-update — safety decision)

## Data & config layout

- `/data/diun.db` — BoltDB state (last-seen tags + digests)
- `/data/diun.yml` (or env vars) — config
- No other persistence

## Backup

```sh
sudo tar czf diun-$(date +%F).tgz /var/lib/docker/volumes/diun_data
```

Losing state = first-scan-after-restore will flag everything as "new" (false-positive noise until baseline re-established). Not catastrophic.

## Upgrade

1. Releases: <https://github.com/crazy-max/diun/releases>. Very active.
2. Docker: bump tag → restart.
3. **Diun does NOT update your OTHER containers** — it only notifies. That's a deliberate safety choice.

## Gotchas

- **Diun NOTIFIES; it does NOT auto-update.** This is a feature. Auto-update tools (Watchtower, shepherd) can pull+restart without warning, which is a bad idea for stateful apps with breaking migrations. Diun's notify-only model forces human-in-the-loop.
- **Docker socket mount = effectively root on the host.** Same Docker-group-is-root-equivalent security framing as Unregistry (batch 78). If Diun container is compromised, attacker = host root. Mitigate:
  - Mount socket READ-ONLY (`:ro`) — prevents container creation/modification
  - Run Diun on a dedicated host if multi-tenant concerns
  - Consider `docker-socket-proxy` (tecnativa) as a scoped-permissions proxy between Diun and the socket
- **Notification channel secrets** (Telegram bot tokens, Slack webhooks) should come from env OR mounted secret files — NOT committed to `diun.yml` in git. Use `DIUN_NOTIF_TELEGRAM_TOKEN` env + compose `.env` file.
- **Notification fatigue**: watching 50 containers with 6-hourly polling = many notifications per week. Categorize:
  - Filter `:latest` tags (will always change noisily)
  - Watch semver-tagged images (more meaningful updates)
  - Group per channel (security → ntfy high-priority; routine → low-priority)
- **Rate limits on registries** matter for polling. Docker Hub anonymous = 100 pulls/6h per IP. Diun's "check tags" calls ARE rate-limited. Use Docker Hub authenticated pulls (free tier = 200/6h; Pro = unlimited). Same for ghcr.io (generous but finite).
- **Private registries** require credentials in Diun config. Store securely.
- **Digest-change detection** catches "same-tag, different image" (e.g., `nginx:1.25` periodically rebuilt for CVEs). This is where Diun shines vs "just watch tag list."
- **Include/exclude patterns**: tag regex like `^v?\d+\.\d+\.\d+$` (semver only) filters pre-release noise. Tune per image.
- **Cron schedule tradeoff**: more frequent = faster notification but more API calls + rate-limit risk. `0 */6 * * *` (every 6h) is a good default for most homelabs.
- **Kubernetes provider** requires correct RBAC — Diun service account needs read access to workloads.
- **Doesn't handle everything**: Diun watches images, not:
  - Helm chart updates
  - OS package updates (use `unattended-upgrades`, Renovate, dependabot)
  - Non-Docker software (binaries, VMs)
  - For app-dependency updates: **Renovate / Dependabot** are the tools (different category)
- **Great pairing**: Diun + **Unregistry** (batch 78) + **Uncloud** (batch 74) — three tools by two authors (crazy-max + psviderski) covering notify-of-new-images, push-to-remote-without-registry, deploy-across-multiple-docker-hosts. Homelab happy stack.
- **License**: **MIT**.
- **Project health**: very active; crazy-max is a prolific maintainer with strong track record. Sponsored via GitHub + PayPal.
- **Alternatives worth knowing:**
  - **Watchtower** — auto-updates containers (different philosophy: notify vs auto-apply)
  - **shepherd** — Swarm auto-update
  - **Renovate / Dependabot** — code-dependency-focused (different scope)
  - **What's Up Docker (WUD)** — similar to Diun; Node-based
  - **CrowdSec (hub updates)** — niche
  - **Choose Diun if:** notify-only discipline + rich notification channels + multi-provider (Docker/Swarm/K8s/file).
  - **Choose Watchtower if:** you genuinely want auto-update (understand the risk).
  - **Choose WUD if:** you prefer Node over Go + want web UI (Diun is config-file-driven).

## Links

- Repo: <https://github.com/crazy-max/diun>
- Docs: <https://crazymax.dev/diun/>
- Docker Hub: <https://hub.docker.com/r/crazymax/diun>
- Releases: <https://github.com/crazy-max/diun/releases>
- Sponsor: <https://github.com/sponsors/crazy-max>
- Configuration reference: <https://crazymax.dev/diun/config/diun/>
- Notification providers: <https://crazymax.dev/diun/notif/>
- Watchtower (auto-update alt): <https://containrrr.dev/watchtower/>
- What's Up Docker (alt): <https://github.com/getwud/wud>
- Renovate (app-dep alt): <https://docs.renovatebot.com>
- docker-socket-proxy (security): <https://github.com/Tecnativa/docker-socket-proxy>
