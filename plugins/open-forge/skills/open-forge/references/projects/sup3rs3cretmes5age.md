# sup3rS3cretMes5age

**What it is:** Self-destructing, one-time secret message service backed by HashiCorp Vault. Share sensitive information (passwords, tokens, credentials) via a link that automatically self-destructs after the recipient reads it once. Supports file uploads up to 50 MB, configurable TTL, rate limiting, and TLS.

**GitHub:** https://github.com/algolia/sup3rS3cretMes5age  
**Docker Hub:** `algolia/supersecretmessage:latest`  
**License:** MIT

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS/VM | Docker Compose | App + Vault dev server via `make run` |
| Any Linux VPS/VM | Docker + production Vault | Use an existing Vault cluster for persistence |
| Kubernetes | Helm chart | Helm chart included in repo |
| Bare metal | Go binary | Build from source |

---

## Stack Components

| Component | Role |
|-----------|------|
| Go web app | Serves the UI and API; creates/retrieves secrets |
| HashiCorp Vault | Stores secrets in cubbyhole backend with one-time tokens |

---

## Inputs to Collect

### Phase: Deploy (Docker Compose dev/simple)

| Variable | Description |
|----------|-------------|
| `VAULT_ADDR` | URL of Vault server (default `http://vault:8200`) |
| `VAULT_TOKEN` | Vault root/auth token |
| `SUPERSECRETMESSAGE_HTTP_BINDING_ADDRESS` | Listen address (default `:8080`) |

### Phase: Production config options

| Option | Description |
|--------|-------------|
| TLS cert/key | For direct HTTPS (or use reverse proxy) |
| HTTP → HTTPS redirect | Configurable in `deploy/docker-compose.yml` |
| Rate limit | Built-in: 10 req/sec |
| TTL | Default 48h, max 7 days per message |

---

## Software-Layer Concerns

- **HashiCorp Vault cubbyhole backend** — each secret stored with a one-time token (2 uses: create + retrieve); after retrieval, the token and secret are permanently deleted
- **Dev mode Vault** (default in `make run`) uses in-memory storage — **secrets lost on restart**; for production use a persistent Vault instance
- **No database** beyond Vault — all secret storage is Vault-managed
- **File uploads up to 50 MB** — base64-encoded before storage
- **All frontend assets are self-hosted** — no external CDNs or tracking (8.9 KB JS bundle)
- **Multi-platform Docker images**: linux/amd64 + linux/arm64

---

## Quick Start

```bash
git clone https://github.com/algolia/sup3rS3cretMes5age.git
cd sup3rS3cretMes5age
make run        # starts Vault dev server + app
# App at http://localhost:8082
```

For production, use a persistent Vault instance and configure `VAULT_ADDR` + `VAULT_TOKEN` accordingly.

---

## Upgrade Procedure

1. Pull new image: `docker pull algolia/supersecretmessage:latest`
2. Restart container(s)
3. No persistent state to migrate (Vault holds all secrets)

---

## Gotchas

- **Dev-mode Vault is NOT persistent** — use a production Vault cluster for any real deployment; secrets in dev mode are lost on restart
- **One-time tokens mean no recovery** — if the link is lost before being read, the secret cannot be retrieved
- **Vault must be unsealed and healthy** for the app to function — monitor Vault separately
- Default `make run` binds to port 8082 — change in `deploy/docker-compose.yml` as needed
- For Kubernetes deployments, see the included Helm chart in the repo

---

## Links

- GitHub: https://github.com/algolia/sup3rS3cretMes5age
- Docker Hub: https://hub.docker.com/r/algolia/supersecretmessage
- Blog post: https://blog.algolia.com/secure-tool-for-one-time-self-destructing-messages/
