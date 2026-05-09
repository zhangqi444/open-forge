---
name: metamcp-project
description: MetaMCP recipe for open-forge. MCP aggregator, orchestrator, middleware, and gateway — dynamically composes multiple MCP servers into a unified endpoint with auth, rate limiting, OIDC, and tool override support. Single Docker Compose deploy.
---

# MetaMCP

Open-source MCP (Model Context Protocol) proxy that aggregates multiple MCP servers into a single unified endpoint with namespacing, middleware, rate limiting, API-key auth, and OIDC support. Works as a drop-in MCP server for any MCP client. Upstream: https://github.com/metatool-ai/metamcp. Docs: https://docs.metamcp.com. License: MIT.

Language: TypeScript (Next.js + Node.js). Database: PostgreSQL. Image: `ghcr.io/metatool-ai/metamcp:latest`. Multi-arch: amd64, arm64.

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux / macOS host | Docker Compose | Recommended. Single command startup |
| VPS | Docker Compose | Works fine behind a reverse proxy |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | Public URL MetaMCP will be served at | Required — CORS enforced on APP_URL; all access must go through this URL |
| auth | BETTER_AUTH_SECRET | Generate with: openssl rand -hex 32 |
| database | POSTGRES_PASSWORD | Change from default before exposing publicly |
| optional | BOOTSTRAP_USERS | JSON array of seed users (email, password, name) — created on first start |
| optional | BOOTSTRAP_API_KEYS | JSON array of API keys to create on first start |
| optional | OIDC provider config | OIDC_ISSUER / OIDC_CLIENT_ID / OIDC_CLIENT_SECRET |

## Software-layer concerns

### Key environment variables

| Variable | Purpose | Default |
|---|---|---|
| APP_URL | Public URL — MetaMCP enforces CORS on this | http://localhost:12008 |
| NEXT_PUBLIC_APP_URL | Same URL for frontend | mirrors APP_URL |
| BETTER_AUTH_SECRET | Auth signing secret — change in production | your-super-secret-key-change-this-in-production |
| POSTGRES_HOST | PostgreSQL host | postgres |
| POSTGRES_PORT | PostgreSQL port | 5432 |
| POSTGRES_USER | PostgreSQL user | metamcp_user |
| POSTGRES_PASSWORD | PostgreSQL password | m3t4mcp |
| POSTGRES_DB | PostgreSQL database | metamcp_db |
| DATABASE_URL | Composed connection string | postgresql://... (auto-built from above vars) |
| TRANSFORM_LOCALHOST_TO_DOCKER_INTERNAL | Rewrites localhost to host.docker.internal for STDIO servers | true |

### Docker Compose (recommended)

Based on upstream docker-compose.yml at https://github.com/metatool-ai/metamcp/blob/main/docker-compose.yml.

  git clone https://github.com/metatool-ai/metamcp.git
  cd metamcp
  cp example.env .env
  # Edit .env: set APP_URL, BETTER_AUTH_SECRET, POSTGRES_PASSWORD
  docker compose up -d

MetaMCP is available at http://localhost:12008 (or configured APP_URL).

Important: access MetaMCP only through the configured APP_URL. CORS blocks any other origin.

### Postgres volume naming

The default Compose file uses a volume named postgres_data. This name is global across Docker Compose projects. If another project uses the same name, collisions can occur. Rename in docker-compose.yml for multi-project hosts:

  volumes:
    metamcp_postgres_data:
      driver: local

### STDIO MCP server environment variables

For STDIO MCP servers managed by MetaMCP, environment variables can be passed three ways:
1. Raw values (not recommended for secrets)
2. References: ${ENV_VAR_NAME} resolved from MetaMCP container's environment at runtime
3. Auto-matching: variables present in MetaMCP container environment are passed through automatically

### Connecting MCP clients

After setup, generate an API key in the MetaMCP UI.

Cursor (mcp.json):
  {
    "metamcp": {
      "url": "http://localhost:12008/mcp/<namespace-slug>",
      "headers": { "Authorization": "Bearer <api-key>" }
    }
  }

Claude Desktop (stdio-only clients via mcp-remote):
  {
    "mcpServers": {
      "metamcp": {
        "command": "npx",
        "args": ["-y", "mcp-remote", "http://localhost:12008/sse/<namespace-slug>",
                 "--header", "Authorization: Bearer <api-key>"]
      }
    }
  }

## Upgrade procedure

  cd metamcp
  docker compose pull
  docker compose up -d

Schema migrations run automatically on container start. No manual migration steps.

## Gotchas

- APP_URL is enforced via CORS — all client access must come from this origin. Changing APP_URL after first start requires also updating NEXT_PUBLIC_APP_URL and recreating containers.
- Postgres volume name collision — the default postgres_data volume is global; rename it in docker-compose.yml when running multiple Compose projects on the same host.
- TRANSFORM_LOCALHOST_TO_DOCKER_INTERNAL=true rewrites localhost in STDIO server configs to host.docker.internal. Set to false only if host.docker.internal is not available on your platform.
- Cold start for STDIO servers — STDIO MCP servers spawn on first tool call; first-call latency is expected. Use a custom Dockerfile to pre-install uvx/npx runtimes for faster cold starts.
- Rate limiting — configure rate limits per namespace to prevent a single agent from exhausting upstream API quotas.

## Links

- Upstream README: https://github.com/metatool-ai/metamcp
- Documentation: https://docs.metamcp.com
- GHCR image: https://github.com/metatool-ai/metamcp/pkgs/container/metamcp
- Demo video: https://youtu.be/Cf6jVd2saAs
