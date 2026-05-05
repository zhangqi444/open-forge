# Dex

Federated OpenID Connect (OIDC) identity provider / SSO broker. Dex acts as a portal to upstream identity providers (LDAP, SAML, GitHub, Google, Microsoft, Active Directory, and more) and issues standard OIDC ID Tokens to client apps. Kubernetes, AWS STS, and many other services consume Dex tokens natively.

**Official site:** https://dexidp.io

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux host | Docker / Docker Compose | Official image `ghcr.io/dexidp/dex` |
| Kubernetes | Helm (`dex/dex`) | Official chart |
| Kubernetes | manifest | `examples/k8s/` in repo |

---

## Inputs to Collect

### Phase 1 — Planning
- Public issuer URL (e.g. `https://dex.example.com/dex`) — must be reachable by clients
- Connector type: LDAP, GitHub, Google, OIDC passthrough, SAML, etc.
- Storage backend: SQLite (dev only), Kubernetes CRDs, PostgreSQL, MySQL, etcd
- Client apps and their redirect URIs

### Phase 2 — Deployment
- `issuer` URL
- Connector credentials (LDAP bind DN/password, OAuth2 client ID/secret, etc.)
- Client `id`, `secret`, `redirectURIs` for each app
- Storage DSN

---

## Software-Layer Concerns

### Docker Compose

```yaml
services:
  dex:
    image: ghcr.io/dexidp/dex:latest
    command: dex serve /etc/dex/config.yaml
    ports:
      - "5556:5556"
      - "5557:5557"     # gRPC (optional)
    volumes:
      - ./config.yaml:/etc/dex/config.yaml:ro
      - dex-data:/var/dex
    restart: unless-stopped

volumes:
  dex-data:
```

### Minimal Config (`config.yaml`)

```yaml
issuer: https://dex.example.com/dex

storage:
  type: sqlite3
  config:
    file: /var/dex/dex.db

web:
  http: 0.0.0.0:5556

connectors:
  - type: ldap
    id: ldap
    name: LDAP
    config:
      host: ldap.example.com:389
      bindDN: cn=serviceaccount,dc=example,dc=com
      bindPW: password
      userSearch:
        baseDN: ou=users,dc=example,dc=com
        filter: "(objectClass=person)"
        username: uid
        idAttr: uid
        emailAttr: mail
        nameAttr: displayName

oauth2:
  skipApprovalScreen: true

staticClients:
  - id: my-app
    secret: my-app-secret
    name: My App
    redirectURIs:
      - https://myapp.example.com/callback
```

### Storage Backends
| Backend | Use case |
|---------|----------|
| `sqlite3` | Dev/single-node only |
| `postgres` / `mysql` | Production multi-instance |
| `kubernetes` | CRD-based; recommended for K8s |
| `etcd` | Distributed; larger deployments |

### Config Paths
- Config file: `/etc/dex/config.yaml` (path passed via `dex serve <config>`)
- SQLite default: `/var/dex/dex.db`

---

## Upgrade Procedure

1. Pull new image: `docker pull ghcr.io/dexidp/dex:latest`
2. Stop, replace image, restart. Dex applies DB migrations automatically.
3. Review release notes for connector or config schema changes.

---

## Gotchas

- **Issuer URL is immutable** after tokens are issued — changing it invalidates all existing tokens and sessions.
- **SAML connector is unmaintained** and potentially vulnerable to auth bypasses (`#1884`) — avoid in new deployments.
- **SAML lacks refresh token support** — clients needing offline access (`kubectl`) cannot use SAML.
- **TLS required in production** — put Dex behind a TLS-terminating reverse proxy or configure built-in TLS.
- **Static clients vs. dynamic registration** — static clients defined in config do not support DCR; use the gRPC API for dynamic registration.
- **Kubernetes CRD storage** lets connectors and clients be managed via `kubectl` without restarting Dex.

---

## References
- GitHub: https://github.com/dexidp/dex
- Docs: https://dexidp.io/docs/
- Helm chart: https://github.com/dex-idp/helm-charts
- GHCR image: https://github.com/dexidp/dex/pkgs/container/dex
