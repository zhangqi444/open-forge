# nforwardauth

> Extremely lightweight forward auth service — a single login wall protecting all your reverse-proxied services. Works with Traefik, Caddy, nginx, and any proxy that supports forward authentication middleware.

**Official URL:** https://github.com/nosduco/nforwardauth  
**Docker Hub:** https://hub.docker.com/r/nosduco/nforwardauth

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS/VM | Docker | Primary deployment; pairs with any reverse proxy |
| Any Linux VPS/VM | Docker Compose | Recommended alongside Traefik/Caddy stack |
| Bare metal | Binary | Build from source (Go) |

**Requires:** A reverse proxy that supports forward auth (Traefik, Caddy, nginx, etc.)

---

## Inputs to Collect

### Phase: Pre-Deploy
| Input | Description | Example |
|-------|-------------|---------|
| `AUTH_HOST` | Public URL where nforwardauth is accessible | `auth.yourdomain.com` |
| `TOKEN_SECRET` | Secret used to sign auth tokens — keep private, never rotate casually | random 32+ char string |
| `passwd` file | File with `username:hashed_password` pairs (one per line) | see below |

### Phase: Optional Tuning
| Input | Description | Default |
|-------|-------------|---------|
| `COOKIE_SECURE` | Set cookies with Secure flag (disable for HTTP-only/LAN) | `true` |
| `COOKIE_DOMAIN` | Cookie domain; allows SSO across `*.yourdomain.com` | inferred from `AUTH_HOST` |
| `COOKIE_NAME` | Cookie name (change if running multiple instances) | `nforwardauth` |
| `PORT` | Listening port | `3000` |
| `PASS_USER_HEADER` | Pass `X-Forwarded-User` header downstream | `true` |
| `RATE_LIMITER_ENABLED` | Enable built-in brute-force rate limiter | `true` |
| `RATE_LIMITER_MAX_RETRIES` | Max failed logins before lockout | `3` |
| `RATE_LIMITER_BAN_TIME` | Lockout duration in seconds | `300` |

---

## Software-Layer Concerns

### Creating the passwd File
Generate a hashed password entry using openssl:
```bash
echo "myuser:$(openssl passwd -6 mypassword)" >> /path/to/passwd
```
The file format is `username:sha512crypt_hash` — one user per line. Mount as read-only at `/passwd` inside the container.

### Data Directories
| Path (container) | Purpose |
|------------------|---------|
| `/passwd` | Credentials file — mount read-only from host |

### Ports
- Default: `3000` — not exposed publicly; reverse proxy routes to it internally

### Traefik Integration (docker-compose excerpt)
```yaml
nforwardauth:
  image: nosduco/nforwardauth:v1
  environment:
    - TOKEN_SECRET=your-secret-here
    - AUTH_HOST=auth.yourdomain.com
  labels:
    - "traefik.http.routers.nforwardauth.rule=Host(`auth.yourdomain.com`)"
    - "traefik.http.middlewares.nforwardauth.forwardauth.address=http://nforwardauth:3000"
    - "traefik.http.middlewares.nforwardauth.forwardauth.authResponseHeaders=X-Forwarded-User"
    - "traefik.http.services.nforwardauth.loadbalancer.server.port=3000"
  volumes:
    - "/path/to/passwd:/passwd:ro"
```

Then protect any service by adding `traefik.http.routers.<service>.middlewares=nforwardauth` to its labels.

### Basic Auth Compatibility
nforwardauth accepts HTTP Basic Auth credentials in the URL (e.g. `https://user:pass@app.yourdomain.com`), which allows apps like nzb360 to authenticate programmatically without the login page.

---

## Upgrade Procedure

1. Pull the latest image: `docker pull nosduco/nforwardauth:v1`
2. Stop the container: `docker compose down`
3. Start with new image: `docker compose up -d`
4. Token secret and passwd file are external — no migration needed

---

## Gotchas

- **TOKEN_SECRET must be stable** — changing it invalidates all existing auth cookies; all users will be logged out
- **COOKIE_DOMAIN needed for SSO** — without it, the cookie only works on the exact `AUTH_HOST` subdomain; set `COOKIE_DOMAIN=yourdomain.com` to share auth across all subdomains
- **HTTP vs HTTPS** — `COOKIE_SECURE=true` (default) requires HTTPS; set to `false` only on LAN or dev setups
- **Single shared session** — login on one site grants access to all sites behind the middleware; this is by design (SSO), not a bug
- **No CSRF protection yet** — noted in the roadmap; mitigate by keeping the login page behind HTTPS with a strong `TOKEN_SECRET`
- **Multiple instances** — if running two nforwardauth instances for different domains, set different `COOKIE_NAME` values to prevent token collisions

---

## Links
- GitHub: https://github.com/nosduco/nforwardauth
- Docker Hub: https://hub.docker.com/r/nosduco/nforwardauth
- Examples directory: https://github.com/nosduco/nforwardauth/tree/main/examples
