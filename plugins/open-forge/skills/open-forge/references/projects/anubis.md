---
name: anubis-project
description: Anubis recipe for open-forge. MIT Web AI Firewall — sits as a reverse proxy sidecar between the TLS terminator and an upstream service, issuing proof-of-work challenges to filter AI scraper bots. Stateless by default (random ed25519 key on each restart); persistent with ED25519_PRIVATE_KEY_HEX set. Docker image at ghcr.io/techarohq/anubis. Source: https://github.com/TecharoHQ/anubis. Docs: https://anubis.techaro.lol
---

# Anubis

MIT-licensed Web AI Firewall. Sits between your reverse proxy (Nginx, Caddy, Traefik) and your upstream application, issuing JavaScript proof-of-work challenges to browsers to distinguish human visitors from AI scraper bots. Upstream: <https://github.com/TecharoHQ/anubis>. Docs: <https://anubis.techaro.lol>. Install guide: <https://anubis.techaro.lol/docs/admin/installation>.

Anubis is deliberately minimal — it proxies `TARGET` and injects a challenge page before letting traffic through. One Anubis instance protects one upstream service. No database, no persistent state unless you pin `ED25519_PRIVATE_KEY_HEX`.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker (sidecar in front of service) | <https://anubis.techaro.lol/docs/admin/installation> | Yes | Primary path. Run as a container, configure `TARGET` to point at upstream. |
| Native packages (apt/rpm) | <https://anubis.techaro.lol/docs/admin/installation#native-packages> | Yes | Direct install on the host OS. See native install directions. |
| Traefik forwardAuth | <https://anubis.techaro.lol/docs/admin/installation> | Yes | Traefik middleware mode; set `PUBLIC_URL`. |
| Kubernetes | Community | No | Community manifests exist; no upstream-maintained Helm chart. |

---

## Method — Docker sidecar

> **Source:** <https://anubis.techaro.lol/docs/admin/installation>.

### Topology

```
LB / TLS terminator  -->  Anubis (:8923)  -->  Upstream app
```

One Anubis container per protected service. Anubis proxies all traffic to `TARGET` and challenges unknown clients.

### Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | `TARGET` | URL of the upstream service Anubis should proxy to, e.g. `http://myapp:3000`. Must be reachable from within the Docker network. |
| preflight | `COOKIE_DOMAIN` | Root domain (e.g. `example.com`). Sets the cookie domain so the challenge pass is valid across subdomains. Never include a port number. |
| secrets | `ED25519_PRIVATE_KEY_HEX` | 64-char hex string (32-byte ed25519 private key). Required for challenge cookies to survive Anubis restarts and for multi-instance deployments. Generate: `openssl rand -hex 32` |
| config | `DIFFICULTY` | Default `4` (number of leading zero bits required). Higher = harder for bots, but also adds CPU time for browsers. `4`-`6` is typical. |
| config | `SERVE_ROBOTS_TXT` | `false` by default. Set `true` to have Anubis serve a `robots.txt` that disallows all known AI scrapers. |
| config | `POLICY_FNAME` | Path to a bot policy YAML file (optional). Mounts into the container if used. |

### Example docker-compose.yaml snippet

```yaml
services:
  anubis:
    image: ghcr.io/techarohq/anubis:latest
    restart: unless-stopped
    ports:
      - "8923:8923"
    environment:
      BIND: ":8923"
      TARGET: "http://myapp:3000"
      COOKIE_DOMAIN: "example.com"
      ED25519_PRIVATE_KEY_HEX: "${ED25519_PRIVATE_KEY_HEX}"
      DIFFICULTY: "4"
      SERVE_ROBOTS_TXT: "false"
    # Optional: mount a policy file
    # volumes:
    #   - ./anubis-policy.yaml:/etc/anubis/policy.yaml
    # environment:
    #   POLICY_FNAME: /etc/anubis/policy.yaml

  myapp:
    image: myapp:latest
    # Don't expose myapp's port directly — traffic routes through Anubis
```

Configure your TLS terminator / load balancer to forward to `anubis:8923` (or the mapped host port) instead of directly to `myapp`.

### Key environment variables

| Variable | Default | Notes |
|---|---|---|
| `BIND` | `:8923` | Network address Anubis listens on. Use a Unix socket path for `unix` network. |
| `BIND_NETWORK` | `tcp` | Address family: `tcp`, `unix`. |
| `TARGET` | (required) | URL of the upstream service to proxy. |
| `COOKIE_DOMAIN` | (unset) | Root domain for the challenge cookie. Required for multi-subdomain setups. Never include a port. |
| `COOKIE_DYNAMIC_DOMAIN` | `false` | If true, automatically derives cookie domain from the request hostname. |
| `COOKIE_SECURE` | `true` | Marks cookies as Secure (HTTPS-only). Set `false` if serving over plain HTTP. |
| `COOKIE_SAME_SITE` | `None` | Cookie SameSite mode. Use `Lax` if cookies are rejected (required when `COOKIE_SECURE=false`). |
| `COOKIE_EXPIRATION_TIME` | `168h` | How long a valid challenge pass cookie lasts. |
| `DIFFICULTY` | `4` | Proof-of-work difficulty (leading zero bits). |
| `ED25519_PRIVATE_KEY_HEX` | (auto-generated) | Hex-encoded 32-byte ed25519 private key. Set this for restarts and multi-instance. |
| `METRICS_BIND` | `:9090` | Prometheus metrics endpoint. Migrate to policy file. |
| `SERVE_ROBOTS_TXT` | `false` | Serve a robots.txt disallowing AI scrapers. |
| `POLICY_FNAME` | (unset) | Path to bot policy YAML file. |
| `PUBLIC_URL` | (unset) | External URL — required for Traefik forwardAuth mode. Leave unset for direct sidecar mode. |
| `REDIRECT_DOMAINS` | (unset) | Comma-separated allowlist of domains Anubis may redirect to after a successful challenge. |

### Traefik forwardAuth mode

When using Traefik as a reverse proxy, Anubis can be used as a `forwardAuth` middleware:

```yaml
# In .env: set PUBLIC_URL=https://protected.example.com
environment:
  PUBLIC_URL: "https://protected.example.com"
  TARGET: "http://myapp:3000"
```

Then configure Traefik's `forwardAuth` to point at Anubis. Without `PUBLIC_URL`, redirect building fails with `redir=null`.

### Upgrade procedure

```bash
docker compose pull anubis
docker compose up -d anubis
```

Check the [releases page](https://github.com/TecharoHQ/anubis/releases) for any breaking env var changes before upgrading.

### Gotchas

- **One Anubis instance per service.** Anubis must be deployed once per upstream service you want to protect — it does not route between multiple backends.
- **`ED25519_PRIVATE_KEY_HEX` is required for persistence.** Without it, Anubis generates a random key on every restart. Any existing challenge cookies become invalid after a restart, forcing all visitors to solve a new challenge.
- **Multi-instance deployments must share the same key.** If you run multiple Anubis containers on the same cookie domain (e.g. for HA), they must all use the same `ED25519_PRIVATE_KEY_HEX` — otherwise each instance rejects the other's cookies.
- **`COOKIE_SECURE=true` requires HTTPS.** If your stack serves over plain HTTP (local dev, internal-only), set `COOKIE_SECURE=false` and `COOKIE_SAME_SITE=Lax` or browsers will reject the cookie silently.
- **WebSockets caveat.** Anubis may be a poor fit for apps that maintain long-lived WebSocket connections — upstream docs note this is not well-characterized. Test before deploying in front of WebSocket-heavy apps.
- **Anubis blocks the Internet Archive and small scrapers too.** Configure an allowlist in the policy file for known-good bots you want to allow through.
- **`METRICS_BIND` is being deprecated.** Migrate metrics configuration to the policy file as the env var will be removed in a future release.

### Links

- Upstream README: <https://github.com/TecharoHQ/anubis/blob/main/README.md>
- Installation guide: <https://anubis.techaro.lol/docs/admin/installation>
- Bot policy configuration: <https://anubis.techaro.lol/docs/admin/policies>
- Environment variables reference: <https://anubis.techaro.lol/docs/admin/installation> (env vars table)
- Releases: <https://github.com/TecharoHQ/anubis/releases>
