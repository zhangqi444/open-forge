# HashiCorp Vault

Secrets management, encryption, and identity tool. Vault secures, stores, and tightly controls access to secrets (API keys, passwords, certificates, database credentials). Supports dynamic secrets, encryption as a service, PKI, and detailed audit logs. Upstream: <https://github.com/hashicorp/vault>. Docs: <https://developer.hashicorp.com/vault/docs>.

> ⚠️ **License change:** HashiCorp changed Vault's license from MPL 2.0 to BSL 1.1 starting with v1.14. The last MPL-licensed version is v1.13.x. The BSL restricts use in competing products. If you need a truly open-source fork, see **OpenBao** (<https://openbao.org>).

Vault listens on port `8200` by default. It requires initialization (`vault operator init`) and unsealing after every restart. Storage backends vary: file (dev only), integrated Raft (recommended for production), Consul, or PostgreSQL.

## Compatible install methods

Verified against upstream docs at <https://developer.hashicorp.com/vault/docs/install>.

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Binary (Linux/Mac/Windows) | <https://developer.hashicorp.com/vault/install> | ✅ | Direct install on a host. Linux packages available via apt/yum. |
| Docker | <https://hub.docker.com/r/hashicorp/vault> | ✅ | Containerized single-node. `hashicorp/vault` on Docker Hub. |
| Kubernetes / Helm (Vault Helm chart) | <https://github.com/hashicorp/vault-helm> | ✅ | Production Kubernetes. Supports HA with Raft integrated storage. |
| Dev mode (`vault server -dev`) | <https://developer.hashicorp.com/vault/docs/concepts/dev-server> | ✅ | Local development only. In-memory, auto-unsealed, not persistent. |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| preflight | "Install method?" | `AskUserQuestion`: `Docker` / `Binary` / `Kubernetes/Helm` / `Dev mode` | All |
| storage | "Storage backend?" | `AskUserQuestion`: `Raft (integrated)` / `File` / `Consul` | Non-dev |
| storage | "Data directory for Raft/file storage?" | Free-text (e.g. `/vault/data`) | Raft/file |
| tls | "TLS cert and key paths (or disable TLS)?" | Free-text | Production |
| network | "Vault API address (VAULT_ADDR)?" | Free-text (e.g. `https://vault.example.com:8200`) | All |

## Software-layer concerns

### Config file (`vault.hcl` or `vault.json`)

Minimal production config with Raft integrated storage:

```hcl
storage "raft" {
  path    = "/vault/data"
  node_id = "node1"
}

listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_cert_file = "/vault/tls/tls.crt"
  tls_key_file  = "/vault/tls/tls.key"
}

api_addr = "https://vault.example.com:8200"
cluster_addr = "https://vault.example.com:8201"
ui = true
```

For development (no TLS):
```hcl
storage "file" {
  path = "/vault/data"
}
listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = true
}
ui = true
```

### Key environment variables

| Variable | Purpose | Notes |
|---|---|---|
| `VAULT_ADDR` | Vault API URL | Set in client shells to communicate with Vault |
| `VAULT_TOKEN` | Client auth token | Set after `vault login` or init |
| `VAULT_CAPATH` | CA cert path | For TLS verification |
| `VAULT_SKIP_VERIFY` | Skip TLS verify | Dev only — never in production |

### Docker Compose (development)

```yaml
services:
  vault:
    image: hashicorp/vault:latest
    cap_add:
      - IPC_LOCK
    ports:
      - "8200:8200"
    environment:
      VAULT_ADDR: http://0.0.0.0:8200
      VAULT_API_ADDR: http://0.0.0.0:8200
    volumes:
      - ./config:/vault/config
      - vault_data:/vault/data
    command: vault server -config=/vault/config/vault.hcl
    restart: unless-stopped

volumes:
  vault_data:
```

### Initialization (first-run)

After starting Vault for the first time, it must be initialized:

```bash
export VAULT_ADDR='http://localhost:8200'

# Initialize — generates unseal keys and root token
vault operator init

# Unseal (repeat with 3 of 5 key shares by default)
vault operator unseal <unseal-key-1>
vault operator unseal <unseal-key-2>
vault operator unseal <unseal-key-3>

# Login with root token
vault login <initial_root_token>
```

> ⚠️ **Store unseal keys securely.** If you lose them, you cannot unseal Vault and will lose all secrets. Distribute key shares among different trusted people.

### Data directories

| Path | Contents |
|---|---|
| `/vault/data` | Raft or file storage (encrypted secrets, metadata) |
| `/vault/config` | Vault config files (`.hcl` or `.json`) |
| `/vault/tls` | TLS certificate and key |
| `/vault/logs` | Audit logs (if file audit backend enabled) |

## Upgrade procedure

Based on <https://developer.hashicorp.com/vault/docs/upgrading>:

1. Read the **upgrade guide** for the target version — breaking changes are documented.
2. **Back up** the storage backend (`/vault/data` for Raft/file).
3. For single-node: stop → replace binary/image → start → unseal.
4. For HA Raft cluster: rolling upgrade — update standby nodes first, then the active node.
5. Check `vault status` after upgrade.
6. Review and apply any required migration steps from the upgrade docs.

## Gotchas

- **Vault must be unsealed after every restart.** This is by design (protection against physical theft). Automate with Auto-Unseal using AWS KMS, GCP KMS, Azure Key Vault, or Transit secret engine on another Vault.
- **BSL license since v1.14.** Not OSI-open-source. For a truly open-source alternative, see OpenBao (<https://openbao.org>).
- **`IPC_LOCK` capability is required.** Vault uses `mlock()` to prevent secrets from swapping to disk. Add `cap_add: [IPC_LOCK]` in Docker or set `disable_mlock = true` in config (not recommended for production).
- **Root token should not be used day-to-day.** Create purpose-specific tokens/policies immediately after init.
- **Audit logging is not enabled by default.** Enable a file or syslog audit backend immediately to track all secret access.
- **Dev mode is not persistent.** `vault server -dev` stores everything in memory. Never use for production.

## Links

- Upstream: <https://github.com/hashicorp/vault>
- Docs: <https://developer.hashicorp.com/vault/docs>
- Install: <https://developer.hashicorp.com/vault/install>
- Docker Hub: <https://hub.docker.com/r/hashicorp/vault>
- Vault Helm chart: <https://github.com/hashicorp/vault-helm>
- Upgrade guides: <https://developer.hashicorp.com/vault/docs/upgrading>
- OpenBao (OSS fork): <https://openbao.org>
