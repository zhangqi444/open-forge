---
name: Tyk
description: "Fast, cloud-native open-source API gateway supporting REST, GraphQL, TCP, and gRPC — with rate limiting, authentication, analytics, and a developer portal. Go. MPL-2.0."
---

# Tyk

Tyk Gateway is a fast, open-source API gateway written in Go, supporting REST, GraphQL, TCP, and gRPC protocols. It handles authentication, rate limiting, quota management, analytics, and API versioning out of the box with no feature lockout in the open-source edition.

Maintained by Tyk Technologies Ltd (London). The open-source gateway (MPL-2.0) is "batteries-included" — the full-featured gateway with no artificial restrictions. Tyk Self-Managed and Tyk Cloud add a Management Dashboard, Developer Portal, and Analytics UI as paid additions on top of the gateway.

Use cases: (a) API gateway for microservices (b) rate limiting and authentication proxy for public APIs (c) self-hosted alternative to Kong or AWS API Gateway (d) GraphQL gateway with field-level security (e) API management platform for enterprises wanting self-hosted control.

Features:

- **Protocol support** — REST, GraphQL, TCP, gRPC, WebSockets
- **Authentication** — API keys, OAuth 2.0, JWT, HMAC, LDAP, OpenID Connect, mutual TLS, custom auth
- **Rate limiting** — per-user, per-API, per-endpoint rate limits and quotas
- **Analytics** — request/response logging; built-in analytics storage (pump to multiple targets)
- **Middleware** — request/response transformation, URL rewriting, header injection, body modification
- **API versioning** — manage multiple API versions simultaneously
- **GraphQL** — schema stitching, field-level access control, query depth limiting
- **Hot reload** — update API definitions without restarts
- **Kubernetes-native** — Tyk Operator for CRD-based API management in k8s
- **High availability** — Redis-backed; horizontally scalable
- **Plugins** — Go, Python, Lua, JavaScript (gRPC) for custom middleware
- **Virtual endpoints** — serverless-style JavaScript functions as API endpoints

- Upstream repo: https://github.com/TykTechnologies/tyk
- Homepage: https://tyk.io/
- Docs: https://tyk.io/docs/
- Docker quickstart: https://github.com/TykTechnologies/tyk-gateway-docker

## Architecture

Tyk has several components:

| Component | License | Description |
|-----------|---------|-------------|
| **Tyk Gateway** | MPL-2.0 (open source) | The API gateway itself; handles all traffic |
| **Tyk Pump** | MPL-2.0 (open source) | Forwards analytics to storage backends (MongoDB, Postgres, Elasticsearch, etc.) |
| **Tyk Dashboard** | Commercial | Web UI for managing APIs, users, analytics; not open source |
| **Tyk Developer Portal** | Commercial | Developer-facing API portal |
| **Tyk Operator** | Apache-2.0 | Kubernetes CRD operator for gateway config |

Self-hosting with **only open-source components** means: Gateway + Pump + Redis (required) + optional MongoDB or PostgreSQL for analytics. API management is done via the REST API or YAML config files — no GUI.

For the full Dashboard/Portal, use Tyk Self-Managed (paid) or Tyk Cloud.

## Compatible install methods

| Infra       | Runtime                    | Notes                                                     |
|-------------|----------------------------|-----------------------------------------------------------|
| Docker      | docker compose             | Quickstart repo: tyk-gateway-docker                       |
| Kubernetes  | Tyk Operator (Helm)        | CRD-based; recommended for k8s deployments                |
| Linux       | Binary / deb / rpm         | Direct install; systemd service                           |
| Docker      | Gateway-only (no Dashboard)| Open-source only; API management via REST API             |

## Inputs to collect

| Input         | Example                    | Phase   | Notes                                                        |
|---------------|----------------------------|---------|--------------------------------------------------------------|
| Redis         | `redis:6379`               | Required| Tyk requires Redis for rate limiting and session storage     |
| Gateway secret| strong random string       | Config  | `tyk_analytics.conf` → `secret`                             |
| Node secret   | strong random string       | Config  | `tyk.conf` → `node_secret`                                   |
| Listen port   | `8080`                     | Config  | Gateway HTTP port                                            |
| Upstream APIs | `http://your-service:3000` | Config  | Target services the gateway proxies to                       |

## Quick start (Docker Compose)

```sh
git clone https://github.com/TykTechnologies/tyk-gateway-docker
cd tyk-gateway-docker
docker compose up -d
```

This starts the gateway + Redis. The gateway API is at `http://localhost:8080`.

Create your first API via REST:

```bash
curl -H "x-tyk-authorization: <your-secret>" \
  -H "Content-Type: application/json" \
  -X POST \
  http://localhost:8080/tyk/apis/ \
  -d '{
    "name": "My API",
    "slug": "my-api",
    "api_id": "my-api",
    "org_id": "default",
    "auth": {"auth_header_name": "Authorization"},
    "definition": {"location": "header", "key": "x-api-version"},
    "version_data": {
      "not_versioned": true,
      "versions": {"Default": {"name": "Default"}}
    },
    "proxy": {
      "listen_path": "/myapi/",
      "target_url": "http://your-upstream-service:3000/",
      "strip_listen_path": true
    },
    "active": true
  }'

# Hot reload to apply
curl -H "x-tyk-authorization: <your-secret>" \
  http://localhost:8080/tyk/reload/group
```

## Data & config layout

- **`tyk.conf`** — gateway configuration (Redis, listen port, secrets, middleware settings)
- **`apps/`** — API definition JSON files (one per API)
- **`middleware/`** — custom JS/Python/Go middleware files
- **Redis** — session data, rate limit counters, key storage
- **Optional: MongoDB/PostgreSQL** — analytics storage (via Tyk Pump)

## Upgrade

```sh
docker pull tykio/tyk-gateway:latest
docker compose up -d
```

Review release notes for config changes: https://github.com/TykTechnologies/tyk/releases

## Gotchas

- **Dashboard is not open source** — the web management UI (Tyk Dashboard) requires a paid license. Managing the open-source gateway is done entirely via REST API or config files. This is fine for engineers but a barrier for teams expecting a GUI.
- **Redis is mandatory** — Tyk requires Redis for rate limiting, session management, and API key storage. There's no option to run without it.
- **Hot reload required after API changes** — API definition changes don't auto-apply; you must call the reload endpoint or restart the gateway. Easy to forget in scripts.
- **MPL-2.0 license** — modifications to Tyk Gateway files must be released under MPL-2.0 if distributed. However, using Tyk as a gateway for your own services (without distributing modified Tyk code) has no copyleft requirement.
- **Analytics volume** — Tyk logs every request by default. In high-traffic environments, this generates significant MongoDB/storage write volume. Configure Tyk Pump carefully; use sampling or selective analytics for very high traffic.
- **GraphQL federation limitations** — GraphQL schema stitching in the open-source edition has limitations; advanced federation (Apollo Federation, subgraph composition) may require the Enterprise tier.
- **Kubernetes Operator learning curve** — the Tyk Operator for k8s is powerful but the CRD model has a steep learning curve. Start with Docker Compose for non-k8s environments.
- **Alternatives:** Kong (Lua/Go; open-source; rich plugin ecosystem), Traefik (Go; dynamic config; excellent k8s integration; middleware via plugins), Caddy (simpler; excellent for smaller setups), NGINX (battle-tested reverse proxy; manual config), AWS API Gateway / Azure APIM (cloud-managed; SaaS).

## Links

- Repo: https://github.com/TykTechnologies/tyk
- Homepage: https://tyk.io/
- Documentation: https://tyk.io/docs/
- Quickstart repo (Docker): https://github.com/TykTechnologies/tyk-gateway-docker
- Tyk Operator (Kubernetes): https://github.com/TykTechnologies/tyk-operator
- Tyk Pump (analytics): https://github.com/TykTechnologies/tyk-pump
- Releases: https://github.com/TykTechnologies/tyk/releases
- Community forum: https://community.tyk.io/
