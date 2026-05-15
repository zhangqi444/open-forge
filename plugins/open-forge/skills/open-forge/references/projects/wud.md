---
name: WUD (What's up Docker?)
description: "Notifications for Docker image updates. Watches running containers, queries their registries, alerts when newer images available. Supports many registries + notification channels. Node.js. MIT. Active maintenance; community + donations."
---

# WUD (What's up Docker?)

WUD — **"What's up Docker?"** — is **"the watcher that tells you when your containers are outdated"** — a lightweight service you run alongside your Docker stack that periodically checks every running container's image against its registry + notifies you (Discord/Slack/Telegram/email/many more) when newer tags are available. Doesn't auto-update by default (though it can integrate with tools that do, like Diun for monitoring or watchtower for auto-pull). Gentler + more observable than watchtower: you stay in the loop.

Built + maintained by **getwud team** + community. **License: MIT**. Active + widely-adopted in the Docker/homelab community. Funded via PayPal + BuyMeACoffee donations. Simple, focused, does one thing well.

Use cases: (a) **homelab update monitoring** — "what needs updating this weekend?" (b) **security-patch awareness** — alert on image updates likely to contain CVE fixes (c) **CI/CD integration** — trigger build/deploy pipeline on upstream tag change (d) **avoiding-automatic-updates** approach — humans decide + apply updates (vs. watchtower's auto-pull) (e) **release-tracking for dependencies** — know when postgres / redis / traefik / etc. ship new versions.

Features (from upstream repo + docs):

- **Watches running Docker containers** — matches their images to registry state
- **Many registries supported** — Docker Hub, GHCR, GCR, Quay, ECR, ACR, GitLab, Artifactory, custom
- **Many notification triggers** — Discord, Slack, Email, Telegram, Apprise, Gotify, HTTP webhook, IFTTT, MQTT, etc.
- **Web UI** — view tracked containers + state
- **REST API**
- **Kubernetes support** (via kube-api watch)
- **Customizable include/exclude** — label-based or regex-based filtering
- **Semver + latest + regex-based tag patterns**
- **Supports watchtower-style auto-update** via trigger chaining (if desired)

- Upstream repo: <https://github.com/getwud/wud>
- Homepage + docs: <https://getwud.github.io/wud>
- Docker Hub: <https://hub.docker.com/r/getwud/wud>
- Donate PayPal: <https://www.paypal.com/donate/?business=ZSDMEC3ZE8DQ8&no_recurring=0&currency_code=EUR>
- Donate BMC: <https://www.buymeacoffee.com/61rUNMm>
- Releases: <https://github.com/getwud/wud/releases>

## Architecture in one minute

- **Node.js** backend
- **Static web UI** (for dashboard)
- **Docker socket** — reads running containers (read-only suffices)
- **Optional kube-API access** for Kubernetes mode
- **Resource**: tiny — ~100MB RAM + light periodic-poll network traffic
- **Port 3000** default

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker**         | **`getwud/wud:latest`**                                         | **Primary**                                                                        |
| Docker compose     | Sidecar to existing stack                                                 | Typical                                                                                   |
| Kubernetes         | Deployment + RBAC for pod-listing                                                        | Supported                                                                                               |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Docker socket        | `/var/run/docker.sock` RO                                   | **CRITICAL** | Read-only suffices; see gotchas                                                                                    |
| Registry credentials | For private registries                                      | Auth         | Env-vars per registry type                                                                                     |
| Notification targets | Discord webhook, Slack URL, Apprise stack, etc.             | Integration  | Configure via env vars                                                                                     |
| Trigger rules        | When to notify (tag-change / digest-change / both)          | Config       | Fine-tune to avoid noise                                                                                     |
| `WUD_AUTH_*`         | Dashboard auth                                                                                   | Auth         | Enable; not default                                                                                                            |

## Install via Docker

```yaml
services:
  wud:
    image: getwud/wud:8.2.2         # **pin version**
    restart: unless-stopped
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
    environment:
      # watch all local Docker containers
      - WUD_WATCHER_LOCAL_HOST=unix:///var/run/docker.sock
      # notify via Discord
      - WUD_TRIGGER_DISCORD_MAIN_URL=${DISCORD_WEBHOOK_URL}
      # Dashboard auth
      - WUD_AUTH_BASIC_ADMIN_USER=admin
      - WUD_AUTH_BASIC_ADMIN_HASH=${BCRYPT_HASH_OF_PASSWORD}
    ports: ["3000:3000"]
```

## First boot

1. Start → browse `http://host:3000` → see list of watched containers + current / latest tags
2. Configure notification trigger; send test notification
3. Tune labels on containers to include/exclude from watch (e.g., `wud.watch=true`)
4. Review notification cadence; adjust poll interval (default usually hourly)
5. Integrate with Apprise or your preferred notification hub
6. Put dashboard behind reverse proxy + auth (even though it's mostly read-only)

## Data & config layout

- **NO PERSISTENT STATE** (mostly) — WUD reads Docker + polls registries + emits notifications
- Optional DB for some features (history tracking) — volume mount if enabled
- Config via env vars

## Backup

- Almost nothing to back up. Config is declarative (env vars / compose file). Version-control your compose file.

## Upgrade

1. Releases: <https://github.com/getwud/wud/releases>. Active + semver.
2. Docker: pull + restart.
3. **Ironic twist: WUD itself needs updating** — use WUD to watch itself!
4. Read release notes — notification-format changes possible.

## Gotchas

- **WATCHING ≠ UPDATING (by design)**: WUD tells you "there's a new version"; it doesn't install it. This is a FEATURE — humans decide when + whether to upgrade. Watchtower auto-pulls-and-restarts which is riskier for production. **Decide deliberately** which tool fits your risk tolerance.
- **DOCKER SOCKET = ROOT-EQUIVALENT** (recurring theme — OliveTin 91, DVB 92, Homarr 89): though WUD only *reads* from the socket, a container with `/var/run/docker.sock` mounted can potentially escalate via kernel bugs / Docker API abuse. Mitigations:
  - **Use docker-socket-proxy** (Tecnativa) to restrict WUD's API surface to `GET /containers` + `GET /images` only
  - Mount `:ro` (limits some operations but the socket itself is a Unix socket — container can still call docker API as long as it can read/write the socket file perms)
- **NOTIFICATION FATIGUE**: if you watch 50 containers on `latest` tag, you get ~50 notifications/week. Configure:
  - **Tag pattern matching** — only alert on SEMVER minor/major; ignore patch-level floating tags
  - **Grouping** — batch multiple updates into one digest notification
  - **Exclude-noisy-images** — some images push daily CI tags; exclude
- **DIGEST vs TAG CHANGE distinction**: a mutable tag (`:latest`, `:3`) can change digest without changing tag string — you're silently getting a different image. WUD should detect digest changes; configure to track both.
- **LATEST TAG IS A LIE**: `latest` in registry means "whatever was last pushed by someone" — not necessarily "latest stable release". **Pin to specific version tags** for production + use WUD to notify when new specific tags are published (`v1.2.3` → `v1.2.4` announcement). This is the **opposite** of watchtower auto-pull culture.
- **REGISTRY CREDENTIALS = HUB-OF-CREDENTIALS LIGHT**: WUD stores registry auth creds (Docker Hub, GHCR, private registry). **32nd tool in hub-of-credentials family — LIGHT tier.** Not extreme; worth care.
- **NOTIFICATION WEBHOOKS = IMMUTABILITY CONCERN**: Discord/Slack webhook URLs grant post-access to that channel. If leaked: attacker spoofs "new version available" messages or spams the channel. Rotate periodically + don't commit webhook URLs to public git.
- **PRIVATE REGISTRY ACCESS**: storing registry creds means an attacker with WUD access can read your private images. If you're using WUD in a team context, limit registry-creds-scope to read-only + image-list scope.
- **RATE-LIMIT AWARENESS**: Docker Hub imposes anonymous-pull + authenticated-pull rate limits. WUD polling every container's manifest costs API calls. Configure poll interval reasonably (every 6h or daily is usually enough); be a good citizen with registry APIs.
- **KUBERNETES MODE**: polling kube-API + all namespaces = operational visibility + potential blast radius. Use RBAC to scope WUD's service account to ONLY list pods + get images (not exec, not secrets).
- **TRANSPARENT-MAINTENANCE**: semver releases + MIT + Docker Hub image counts + clear notification integrations. **14th tool in transparent-maintenance family.**
- **SOLE-MAINTAINER / SMALL-TEAM with community**: getwud is a small team + community. Active + MIT-licensed + forkable. **6th tool in sole-maintainer-with-community class.**
- **COMMERCIAL-TIER**: pure-donation (PayPal + BMC). **7th tool in pure-donation commercial-tier.**
- **INTEGRATIONS-FIRST CULTURE**: WUD's value is in the **long list of notification channels + registries** it supports. This is **ecosystem-asset-of-integration-library** (SWAG proxy-confs 90, Homarr integrations 89 — same meta-pattern). **4th tool recognized in this ecosystem-asset category.**
- **ALTERNATIVES WORTH KNOWING:**
  - **Diun** — Go; similar purpose; "Docker Image Update Notifier"; MIT
  - **Watchtower** — AUTO-PULLS + restarts (different risk profile; aggressive)
  - **Renovate Bot** — CI/CD focused; PRs for dependency updates (different use case: application deps vs container images)
  - **Dependabot** — GitHub-native (application deps)
  - **Podman auto-update** — native Podman feature for Systemd-scheduled auto-updates
  - **Docker Hub webhooks** (push-based rather than pull-polling)
  - **newreleases.io** — SaaS service for release notifications (not container-focused)
  - **Choose WUD if:** you want NOTIFY-ONLY (human-in-loop) + wide-registry-support + many-notification-channels + MIT + lightweight.
  - **Choose Diun if:** you want Go-based alternative + similar featureset.
  - **Choose Watchtower if:** you want AUTO-UPDATE (accepting risk) + no-human-in-loop.
  - **Choose Renovate if:** you want repo-level dependency updates with PRs.
- **PROJECT HEALTH**: active + MIT + Docker-ecosystem-integration + wide-notification-channels + community-driven. Strong signals.

## Links

- Repo: <https://github.com/getwud/wud>
- Homepage: <https://getwud.github.io/wud>
- Docker Hub: <https://hub.docker.com/r/getwud/wud>
- Donate: <https://www.buymeacoffee.com/61rUNMm>
- Diun (alt): <https://crazymax.dev/diun/>
- Watchtower (auto-update alt): <https://containrrr.dev/watchtower/>
- Renovate (deps alt): <https://www.mend.io/free-developer-tools/renovate/>
- Dependabot (deps alt): <https://github.com/dependabot>
- Tecnativa docker-socket-proxy: <https://github.com/Tecnativa/docker-socket-proxy>
- Apprise (notification lib): <https://github.com/caronc/apprise>
