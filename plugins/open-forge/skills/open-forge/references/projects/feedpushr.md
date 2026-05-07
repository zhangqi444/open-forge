---
name: feedpushr
description: Feedpushr recipe for open-forge. Powerful RSS aggregator service with pluggable filters and outputs. Single Go binary with embedded database. Source: https://github.com/ncarlier/feedpushr
---

# Feedpushr

Powerful RSS aggregator written in Go. Aggregates feeds, applies transformations via a pluggable filter system, and pushes articles to configurable outputs (STDOUT, HTTP, email, Twitter, readflow, etc.). Single binary with embedded BoltDB. Supports WebSub, OpenID Connect auth, OPML import/export, full web UI, REST API, and Prometheus metrics.

Upstream: <https://github.com/ncarlier/feedpushr>

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux/macOS | Go binary | Single binary, no external database |
| Any | Docker (ncarlier/feedpushr) | Official image |
| Any | Docker Compose | See upstream README |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| install | Deployment method: binary or Docker | Docker simplest |
| config | Port to expose | Default: 8080 |
| config | Data persistence path | e.g. ./feedpushr-data mapped to /var/opt/feedpushr |
| config | Auth method: none or OpenID Connect | Open by default |
| config | Output destinations | STDOUT, HTTP webhook, email, Twitter, readflow |

## Software-layer concerns

All configuration via CLI flags or environment variables. Run feedpushr -h to list all params and env var equivalents.

Key env vars:

- APP_PORT — HTTP listen port (default: 8080)
- APP_DB — BoltDB file path (default: /var/opt/feedpushr/feedpushr.db)
- APP_AUTHN — OIDC provider URL for auth (none by default)
- APP_LOG_LEVEL — Log verbosity: debug/info/warn/error (default: info)

Full env var list: https://github.com/ncarlier/feedpushr/blob/master/etc/default/feedpushr.env

Data dir: /var/opt/feedpushr/ — mount as a volume to persist data across restarts.

## Install — Docker (recommended)

Quick run (ephemeral):
```
docker run -d --name=feedpushr ncarlier/feedpushr
```

With persistent data:
```
docker run -d \
  --name=feedpushr \
  -p 8080:8080 \
  --restart always \
  -v ./feedpushr-data:/var/opt/feedpushr \
  ncarlier/feedpushr
```

Docker Compose:
```yaml
services:
  feedpushr:
    image: ncarlier/feedpushr
    ports:
      - "8080:8080"
    restart: always
    volumes:
      - ./feedpushr-data:/var/opt/feedpushr
```

Web UI at http://localhost:8080.

## Install — Binary

```
curl -s https://raw.githubusercontent.com/ncarlier/feedpushr/master/install.sh | bash
feedpushr
```

Or via gobinaries:
```
curl -sf https://gobinaries.com/ncarlier/feedpushr | sh
```

## Upgrade procedure

Docker:
```
docker pull ncarlier/feedpushr
docker compose up -d
```

Binary: re-run the install script, then restart the service.

## Gotchas

- No auth by default — web UI and API are open. Configure APP_AUTHN with OIDC or put behind an auth proxy before exposing publicly.
- Plugin system requires recompilation — output/filter plugins are compiled in at build time, not loaded at runtime. Use pre-built image or build from source with desired plugins.
- OPML categories map to Feedpushr tags via OPML category attribute (comma-separated slash-delimited strings).
- WebSub requires the Feedpushr instance to be publicly reachable for hub callback verification.

## Links

- Upstream README: https://github.com/ncarlier/feedpushr
- Docker Hub: https://hub.docker.com/r/ncarlier/feedpushr
- Env vars reference: https://github.com/ncarlier/feedpushr/blob/master/etc/default/feedpushr.env
