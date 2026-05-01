# Portabase

**Self-hosted database backup and restoration platform — integrates with lightweight agents to back up PostgreSQL, MySQL, MariaDB, MongoDB, SQLite, Redis, Valkey, and Firebird.**
Official site: https://portabase.io
Docs: https://portabase.io/docs
GitHub: https://github.com/Portabase/portabase

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux | Automated CLI (recommended) | One-command install |
| Any Linux | Docker run | Quick single container |
| Any Linux | Docker Compose | Full stack setup |
| Kubernetes | Helm chart | Available via GHCR |

---

## Inputs to Collect

### Required
- Database target credentials — host, port, user, password for each DB to back up
- Backup storage destination — local path or cloud (S3, etc.)

---

## Software-Layer Concerns

### Install via CLI (recommended)
```bash
curl -fsSL https://portabase.io/install.sh | bash
```
Follow the interactive setup prompts.

### Docker Compose
See full compose example at: https://portabase.io/docs/dashboard/setup#docker-compose

### Agent setup
Portabase uses a lightweight Rust agent ([portabase-agent](https://github.com/Portabase/agent-rust)) installed on each database host. The agent handles the actual backup/restore operations securely.

### Supported databases

| Engine | Versions | Restore |
|--------|----------|---------|
| PostgreSQL | 12–18 | Yes |
| MySQL | 5.7, 8, 9 | Yes |
| MariaDB | 10, 11 | Yes |
| MongoDB | 4–8 | Yes |
| SQLite | 3.x | Yes |
| Redis | 2.8+ | No |
| Valkey | 7.2+ | No |
| Firebird | 3.0, 4.0, 5.0 | Yes |

---

## Upgrade Procedure

1. Re-run the CLI install script (detects and updates existing install)
2. Or: docker compose pull && docker compose up -d

---

## Gotchas

- Agent must be installed on each database host separately — see https://portabase.io/docs/agent/db
- Redis and Valkey backup supported but restore is not
- MSSQL Server support is in progress (not yet stable)
- License: Apache 2.0

---

## References
- Installation guide: https://portabase.io/docs/dashboard/setup
- Agent documentation: https://portabase.io/docs/agent/db
- GitHub: https://github.com/Portabase/portabase#readme
