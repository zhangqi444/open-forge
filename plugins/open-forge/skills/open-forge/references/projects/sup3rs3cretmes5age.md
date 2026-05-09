---
name: sup3rs3cretmes5age
description: Recipe for sup3rS3cretMes5age — a self-destructing one-time message service backed by HashiCorp Vault. Docker Compose. Based on upstream README at https://github.com/algolia/sup3rS3cretMes5age (master branch).
---

# sup3rS3cretMes5age

Simple, secure, self-destructing message service. Share sensitive information (passwords, tokens, secrets) via a one-time URL — the message is automatically deleted from storage after the recipient reads it. Backed by HashiCorp Vault's cubbyhole backend for tamper-proof one-time-token storage. MIT license. Official upstream: <https://github.com/algolia/sup3rS3cretMes5age>.

Supports: configurable TTL (default 48h, max 7 days), file uploads up to 50MB, rate limiting (10 req/s), TLS (auto via Let's Encrypt or manual cert), CLI integration (Bash/Zsh/Fish shell functions), REST API, Kubernetes Helm chart.

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Linux host / VM / VPS | Docker Compose | Recommended — Vault + app in one compose stack |
| Any host | Kubernetes (Helm) | Helm chart included in repo under `deploy/helm/` |
| Any host | Go binary + external Vault | Build from source; bring your own Vault cluster |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Vault deployment — dev (in-memory, not for production) or production Vault server?" | Dev Vault is bundled in the compose file; production requires an existing Vault |
| tls | "TLS mode — auto (Let's Encrypt), manual cert, or HTTP only?" | HTTP only is fine behind a reverse proxy; auto TLS requires a public domain |
| tls (auto) | "Domain for Let's Encrypt certificate?" | Set `SUPERSECRETMESSAGE_TLS_AUTO_DOMAIN` |
| tls (manual) | "Path to TLS cert and key files?" | Set `SUPERSECRETMESSAGE_TLS_CERT_FILEPATH` + `_KEY_FILEPATH` |
| network | "What port should the app listen on?" | HTTP default `:8082` (container), HTTPS `:443` |

## Software-layer concerns

- **Image**: `algolia/supersecretmessage:latest` (Docker Hub). Multi-platform: `linux/amd64`, `linux/arm64`.
- **Vault dependency**: the app stores all messages in HashiCorp Vault's cubbyhole backend — Vault is required. The compose file ships a dev Vault container (`vault:latest`) for easy local testing; use a production Vault server for real deployments.
- **Vault token**: one-time tokens with exactly 2 uses are created per message (create + retrieve). Vault must be unsealed and the `VAULT_TOKEN` must have cubbyhole read/write access.
- **No persistent state in the app itself**: all secrets live in Vault. The app container is stateless.
- **Vault prefix**: default `cubbyhole/`. Override with `SUPERSECRETMESSAGE_VAULT_PREFIX`.
- **File uploads**: base64-encoded, stored in Vault. Max 50MB per file.

## Docker Compose

Based on the example in `deploy/docker-compose.yml` (upstream repo):

```yaml
# For local/dev use — Vault dev server stores data in memory (not persistent)
services:
  vault:
    image: vault:latest
    container_name: vault
    environment:
      VAULT_DEV_ROOT_TOKEN_ID: root
    cap_add:
      - IPC_LOCK
    expose:
      - 8200

  supersecret:
    image: algolia/supersecretmessage:latest
    container_name: supersecret
    environment:
      VAULT_ADDR: http://vault:8200
      VAULT_TOKEN: root
      SUPERSECRETMESSAGE_HTTP_BINDING_ADDRESS: ":80"
      # For TLS via Let's Encrypt (public domain required):
      # SUPERSECRETMESSAGE_HTTPS_BINDING_ADDRESS: ":443"
      # SUPERSECRETMESSAGE_TLS_AUTO_DOMAIN: secrets.example.com
      # SUPERSECRETMESSAGE_HTTPS_REDIRECT_ENABLED: "true"
    ports:
      - "8082:80"
    depends_on:
      - vault
```

Start:

```bash
docker compose -f deploy/docker-compose.yml up -d
# Open http://localhost:8082
```

Or use `make run` from the repo root (clones + starts everything).

### Production: external Vault

Replace the `vault` service with your production Vault server credentials:

```yaml
environment:
  VAULT_ADDR: https://vault.yourdomain.com
  VAULT_TOKEN: <your-vault-token>
  SUPERSECRETMESSAGE_HTTPS_BINDING_ADDRESS: ":443"
  SUPERSECRETMESSAGE_TLS_AUTO_DOMAIN: secrets.yourdomain.com
  SUPERSECRETMESSAGE_HTTPS_REDIRECT_ENABLED: "true"
  SUPERSECRETMESSAGE_HTTP_BINDING_ADDRESS: ":80"
```

## Configuration options

| Variable | Description |
|---|---|
| `VAULT_ADDR` | Vault server URL (e.g. `http://vault:8200`) |
| `VAULT_TOKEN` | Vault authentication token |
| `SUPERSECRETMESSAGE_HTTP_BINDING_ADDRESS` | HTTP listen address (e.g. `:80`) |
| `SUPERSECRETMESSAGE_HTTPS_BINDING_ADDRESS` | HTTPS listen address (e.g. `:443`) |
| `SUPERSECRETMESSAGE_HTTPS_REDIRECT_ENABLED` | Redirect HTTP to HTTPS (`true`/`false`) |
| `SUPERSECRETMESSAGE_TLS_AUTO_DOMAIN` | Domain for automatic Let's Encrypt cert |
| `SUPERSECRETMESSAGE_TLS_CERT_FILEPATH` | Path to manual TLS cert file |
| `SUPERSECRETMESSAGE_TLS_CERT_KEY_FILEPATH` | Path to manual TLS cert key file |
| `SUPERSECRETMESSAGE_VAULT_PREFIX` | Vault storage prefix (default `cubbyhole/`) |

## Upgrade procedure

```bash
docker compose -f deploy/docker-compose.yml pull
docker compose -f deploy/docker-compose.yml up -d
```

**Important**: Vault dev server data is in-memory — it is lost on container restart. Back up or migrate any unretrieved messages before upgrading if using the dev Vault container.

## Gotchas

- **Dev Vault is in-memory only.** The bundled `vault:latest` dev container loses all data when restarted. For production use, deploy a proper Vault server with persistent storage and proper unsealing. Messages not yet read will be permanently lost on Vault restart.
- **Run behind TLS in production.** Secrets sent over plain HTTP are vulnerable to interception. Either configure auto-TLS via `SUPERSECRETMESSAGE_TLS_AUTO_DOMAIN` (Let's Encrypt) or place the container behind a reverse proxy (Traefik/Caddy/nginx) that handles TLS.
- **Vault token permissions.** The `VAULT_TOKEN` needs read/write access to the cubbyhole path. In production, use a Vault policy scoped to `cubbyhole/*` rather than a root token.
- **`IPC_LOCK` capability.** The Vault container requires `cap_add: IPC_LOCK` to prevent secrets from being swapped to disk. Without it, Vault logs a warning and runs in dev mode.
- **Rate limiting.** Built-in at 10 requests/second. If deploying behind a load balancer with multiple instances, rate limits are per-instance.
- **File size limit.** 50MB per upload, base64-encoded and stored in Vault. Large files will consume significant Vault storage.
- **selfh.st slug note.** The selfh.st directory uses the slug `sup3rS3cretMes5age` (mixed case). This recipe is filed as `sup3rs3cretmes5age.md` (lowercase) for filesystem consistency.

## References

- Upstream README: https://github.com/algolia/sup3rS3cretMes5age
- Docker Hub: https://hub.docker.com/r/algolia/supersecretmessage
- Upstream blog post: https://blog.algolia.com/secure-tool-for-one-time-self-destructing-messages/
