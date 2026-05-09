---
name: drydock-project
description: Drydock recipe for open-forge. Container image update monitoring with a modern web dashboard, 23 registry providers, 20 notification triggers, OIDC auth, Prometheus metrics, vulnerability scanning, and distributed multi-host agents.
---

# Drydock

Open-source Docker container update monitoring dashboard. Watches running containers across multiple Docker hosts for image updates, sends notifications, and can apply updates automatically. Upstream: https://github.com/CodesWhat/drydock. Official site: https://getdrydock.com.

Drydock v1.5.0. Language: TypeScript. License: AGPL-3.0. Multi-arch: amd64, arm64. Images: codeswhat/drydock (Docker Hub), ghcr.io/codeswhat/drydock (GHCR), quay.io/codeswhat/drydock (Quay.io).

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux host | Docker Engine + Compose (socket proxy) | Recommended: limits Drydock's Docker API exposure |
| Any Linux host | Docker Engine + Compose (direct socket) | Simpler but grants full Docker socket access — use only for testing |
| Kubernetes | — | Not officially supported |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | Docker socket access method: socket proxy (recommended) or direct mount | Socket proxy limits API exposure |
| auth | Admin username | Required — auth is on by default |
| auth | Admin password | Must be hashed with argon2id before passing as DD_AUTH_BASIC_ADMIN_HASH |
| network | Port to expose Drydock UI on (default: 3000) | |
| notifications | Which notification channels to configure (Slack, Discord, SMTP, etc.) | 20 supported triggers |
| registries | Any private registry credentials needed | 23 supported registry providers |
| optional | OIDC provider (Authelia, Auth0, Authentik) | For SSO instead of basic auth |
| optional | DD_SERVER_NAME | Custom name shown in multi-host notification prefixes |
| optional | DD_UPDATE_MAX_CONCURRENT | Max concurrent container updates (default: 0 = unlimited) |

## Software-layer concerns

### Key environment variables

| Variable | Purpose | Example |
|---|---|---|
| DD_AUTH_BASIC_ADMIN_USER | Admin username | admin |
| DD_AUTH_BASIC_ADMIN_HASH | Argon2id password hash | see hash generation below |
| DD_ANONYMOUS_AUTH_CONFIRM | Allow anonymous access (opt-in) | true |
| DD_WATCHER_LOCAL_HOST | Docker socket proxy hostname | socket-proxy |
| DD_WATCHER_LOCAL_PORT | Docker socket proxy port | 2375 |
| DD_SERVER_NAME | Identifier in multi-host notifications | homelab |
| DD_UPDATE_MAX_CONCURRENT | Max concurrent container updates | 2 |

### Password hash generation

Using argon2 CLI:
  echo -n "yourpassword" | argon2 $(openssl rand -base64 32) -id -m 16 -t 3 -p 4 -l 64 -e

Using Node.js 24+: see upstream README for the node -e one-liner.

Legacy hash formats ({SHA}, $apr1$, crypt) were deprecated and removed in v1.6.0. Use argon2id for all new installs.

### Docker Compose (recommended — with socket proxy)

See upstream Quick Start at https://github.com/CodesWhat/drydock#quick-start for the full docker-compose.yml with socket proxy setup. Key services: drydock + tecnativa/docker-socket-proxy. Drydock connects to the proxy via DD_WATCHER_LOCAL_HOST/PORT instead of mounting the socket directly.

Socket proxy environment flags needed:
  CONTAINERS=1, IMAGES=1, EVENTS=1, SERVICES=1
  Add POST=1 and NETWORKS=1 to enable container actions and auto-updates.

### Docker Compose (quick start — direct socket)

  services:
    drydock:
      image: codeswhat/drydock:latest
      ports:
        - 3000:3000
      volumes:
        - /var/run/docker.sock:/var/run/docker.sock
      environment:
        - DD_AUTH_BASIC_ADMIN_USER=admin
        - DD_AUTH_BASIC_ADMIN_HASH=<paste-argon2id-hash>
      restart: unless-stopped

WARNING: Direct socket access grants the container full control over the Docker daemon. Use the socket proxy setup for production.

### Image tags

| Tag | Description |
|---|---|
| codeswhat/drydock:latest | Latest stable release |
| codeswhat/drydock:1.5.0 | Pinned version |
| ghcr.io/codeswhat/drydock:latest | GHCR mirror |
| quay.io/codeswhat/drydock:latest | Quay.io mirror |

### Data dirs

Drydock is stateless by default (no persistent volume required for basic monitoring). Notification history and dedup state are stored in-process. Check upstream docs for persistent storage options when using multi-host agent mode.

## Upgrade procedure

  docker compose pull
  docker compose up -d

No database migration needed for stateless deployments. Review the changelog at https://github.com/CodesWhat/drydock/blob/main/CHANGELOG.md for breaking changes before upgrading (especially auth hash format changes at v1.6.0).

## Gotchas

- Auth required by default — anonymous access must be explicitly opted in with DD_ANONYMOUS_AUTH_CONFIRM=true; do not do this on a public-facing instance.
- Legacy hash formats removed in v1.6.0 — if upgrading from v1.3.x or earlier, regenerate all password hashes in argon2id format before upgrading.
- Socket proxy POST permissions — to enable container restart/update actions from the UI, add POST=1 and NETWORKS=1 to the socket proxy environment; without these, only read operations work.
- Distributed agents — monitoring remote Docker hosts requires running a Drydock agent on each remote host and registering it in the controller.
- API versioning — the unversioned /api/* prefix is deprecated; integrations should migrate to /api/v1/* before v1.6.0 removes it.
- Trivy supply chain — built-in Trivy binary is pinned to v0.69.3 (safe version); see https://getdrydock.com/security/trivy-supply-chain-march-2026.

## Links

- Upstream README: https://github.com/CodesWhat/drydock
- Documentation: https://getdrydock.com/docs
- Quick Start: https://getdrydock.com/docs/quickstart
- Docker Hub: https://hub.docker.com/r/codeswhat/drydock
- Live demo: https://demo.getdrydock.com
