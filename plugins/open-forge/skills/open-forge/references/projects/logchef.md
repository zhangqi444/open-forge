# Logchef

**Lightweight, high-performance log analytics platform — single binary, ClickHouse backend, LogchefQL + SQL querying, AI query assistant, real-time alerting, OIDC/RBAC, and MCP integration.**
Official site: https://logchef.app
Demo: https://demo.logchef.app
GitHub: https://github.com/mr-karan/logchef

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux | Docker Compose | Logchef + ClickHouse + Dex (OIDC) |
| Any Linux | Single binary | No runtime dependencies |

---

## Inputs to Collect

### Required
- ClickHouse connection — host, port, credentials
- OIDC provider credentials — Dex (bundled) or external provider

---

## Software-Layer Concerns

### Docker Compose (quickstart)
```bash
curl -LO https://raw.githubusercontent.com/mr-karan/logchef/refs/heads/main/deployment/docker/docker-compose.yml
docker compose up -d
```
Access at http://localhost:8125

### What's included in the compose stack
- `logchef` — main application (port 8125)
- `clickhouse` — log storage and querying engine
- `dex` — OIDC identity provider (bundled for convenience)

### Ports
- `8125` — Logchef web UI and API
- `8123` (localhost only) — ClickHouse HTTP interface
- `9000` (localhost only) — ClickHouse native protocol

### Key features
- LogchefQL and raw ClickHouse SQL query modes
- AI Query Assistant — natural language to SQL
- Real-time alerting with email and webhook notifications
- OIDC SSO + RBAC team-based access
- Schema-agnostic — point at any ClickHouse table
- Prometheus metrics endpoint
- MCP (Model Context Protocol) server for AI assistants
- CLI for terminal log querying with syntax highlighting

### CLI
```bash
logchef auth --server https://logs.example.com
logchef query "level:error" --since 1h
logchef sql "SELECT * FROM logs.app WHERE level='error' LIMIT 10"
```

---

## Upgrade Procedure

1. docker compose pull
2. docker compose up -d

---

## Gotchas

- ClickHouse is required — Logchef does not include its own storage engine
- Config is provided via `config.toml` mounted as a Docker config (see upstream compose file for full example)
- ClickHouse ports are bound to 127.0.0.1 by default — not exposed externally
- License: AGPLv3

---

## References
- Documentation: https://logchef.app
- CLI guide: https://logchef.app/integration/cli/
- Docker Compose: https://github.com/mr-karan/logchef/blob/main/deployment/docker/docker-compose.yml
- GitHub: https://github.com/mr-karan/logchef#readme
