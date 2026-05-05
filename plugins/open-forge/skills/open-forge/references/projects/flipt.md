---
name: flipt-project
description: Flipt recipe for open-forge. Git-native feature flag management platform. Go single binary or Docker. Upstream: https://github.com/flipt-io/flipt
---

# Flipt

Git-native, enterprise-ready feature flag management platform. Stores feature flags directly in your Git repositories alongside code — no separate database required by default. Supports multi-environment flag management, OpenFeature SDK integration, server-sent events for real-time propagation, and OIDC/JWT/OAuth authentication. Single Go binary with embedded UI. Upstream: https://github.com/flipt-io/flipt. Docs: https://docs.flipt.io

Note: Flipt v2 (current) is Git-native. Flipt v1 (legacy, `main` branch) uses a database (MySQL/PostgreSQL/SQLite) — check which version you need.

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux VPS/bare-metal | Single Go binary | Zero dependencies by default; statically linked |
| Docker host | Docker (single container) | Official image at docker.flipt.io/flipt/flipt |
| Kubernetes | Helm chart | Official Helm chart available |
| Any Linux VPS/bare-metal | Docker Compose | Simple compose wraps the single container |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | Flipt version (v2 Git-native or v1 database-backed) | v2 is recommended for new installs |
| preflight | Port to expose (default: 8080 UI/API, 9000 gRPC) | Configure in config.yml |
| storage (v2) | Git repository URL for flag storage | Flags stored as YAML in a Git repo |
| storage (v2) | Git branch or path for flag files | Defaults to main branch |
| auth (optional) | Authentication method (OIDC, JWT, GitHub OAuth, static tokens) | Optional; open access by default |
| storage (v1 only) | Database type (SQLite / PostgreSQL / MySQL) | v1 only |
| storage (v1 only) | Database connection string | v1 only |

## Software-layer concerns

### Docker (v2 — Git-native)

```bash
docker run --rm \
  -p 8080:8080 \
  -p 9000:9000 \
  -v /path/to/config.yml:/etc/flipt/config/default.yml \
  docker.flipt.io/flipt/flipt:v2
```

UI available at: http://localhost:8080

### Configuration file (config.yml)

```yaml
# Git-native storage (v2)
storage:
  type: git
  git:
    repository: https://github.com/yourorg/feature-flags.git
    ref: main
    # For auth, use SSH key or token

server:
  http_port: 8080
  grpc_port: 9000

log:
  level: INFO
```

Full config schema: https://docs.flipt.io/v2/configuration/overview

### Authentication (optional)

Flipt v2 supports OIDC, GitHub OAuth, JWT, and static tokens. Configure in config.yml under `authentication:`. Without auth configured, the UI and API are open.

```yaml
authentication:
  required: true
  methods:
    oidc:
      enabled: true
      providers:
        google:
          issuer_url: https://accounts.google.com
          client_id: YOUR_CLIENT_ID
          client_secret: YOUR_CLIENT_SECRET
          redirect_address: https://flipt.yourdomain.com
```

### Binary install

```bash
# Linux amd64
curl -fsSL https://github.com/flipt-io/flipt/releases/latest/download/flipt_linux_x86_64.tar.gz | tar xz
./flipt
```

Homebrew: `brew install flipt-io/brew/flipt`

### Port reference

- 8080 — HTTP (UI + REST API)
- 9000 — gRPC API

### Data directories

- Config: /etc/flipt/config/default.yml (or path set by --config flag)
- v1 SQLite default: /var/opt/flipt/flipt.db
- v2 Git: flags stored in your Git repo; no local database

## Upgrade procedure

```bash
# Docker
docker pull docker.flipt.io/flipt/flipt:v2
docker stop flipt && docker rm flipt
# Re-run docker run with same config

# Binary
# Download new release, replace binary, restart service
```

Check release notes before upgrading, especially v1 → v2 migration: https://docs.flipt.io/v2/migration

## Gotchas

- v1 vs v2 are architecturally different — v2 stores flags in Git (no DB); v1 uses a database. Do not conflate the two.
- Git write access required for v2 — Flipt v2 needs push access to the flags Git repo to create/modify flags via the UI/API.
- No database by default (v2) — this is a feature, not a bug: flags travel with code in CI/CD. If you need a DB-backed central server, consider v1 or Flipt Cloud.
- gRPC port 9000 — SDK integrations typically use gRPC; ensure port 9000 is accessible from your application hosts.
- Auth is optional but recommended — by default the API is unauthenticated; enable authentication for any non-localhost deployment.
- SSE for real-time flag propagation — client SDKs can subscribe to SSE on the Flipt server for instant flag updates without polling.

## Links

- Upstream repo: https://github.com/flipt-io/flipt
- Docs (v2): https://docs.flipt.io/v2/introduction
- Configuration reference: https://docs.flipt.io/v2/configuration/overview
- v1 → v2 migration guide: https://docs.flipt.io/v2/migration
- Docker Hub: https://hub.docker.com/r/flipt/flipt (also docker.flipt.io/flipt/flipt)
- OpenFeature SDKs: https://openfeature.dev/ecosystem/?instant_search[refinementList][technology][0]=Flipt
