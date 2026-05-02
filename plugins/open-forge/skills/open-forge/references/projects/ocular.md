# Ocular

**Self-hosted personal budgeting app**
Official site: https://github.com/simonwep/ocular

Ocular is a minimalist budgeting app focused on clarity. Track budgets across multiple years, carry over balances, view Sankey diagrams and analytics, manage users, and use it as a PWA on mobile. Single Docker image, file-based storage — no external database needed.

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Docker host | docker run | Single image, minimal setup |
| Any Docker host | docker-compose | Recommended for persistence management |
| Docker Swarm | docker stack deploy | Supports Docker secrets via `_FILE` suffix |

## Inputs to Collect

### Phase: Pre-deployment (required)
- `GENESIS_JWT_SECRET` — long random string for JWT signing (`openssl rand -base64 48`)
- `GENESIS_CREATE_USERS` — initial user(s) in format `username!:password` (colon-separated, multiple users semicolon-separated)

### Phase: Optional
- `GENESIS_JWT_TOKEN_EXPIRATION` — token lifetime in minutes (default: `60`)
- `GENESIS_JWT_COOKIE_ALLOW_HTTP` — set `true` to allow plain HTTP (not recommended for production)

## Software-Layer Concerns

**Docker image:** `ghcr.io/simonwep/ocular:v2`

**Data volume:** `./data:/data/genesis` — all budget data stored here; **back this up regularly**

**Port:** `3030` → container's `80`

**Key env vars:**
| Variable | Purpose |
|----------|---------|
| `GENESIS_JWT_SECRET` | Signing key for session tokens — keep secret |
| `GENESIS_JWT_TOKEN_EXPIRATION` | Session length in minutes |
| `GENESIS_CREATE_USERS` | Bootstrap user accounts (`user!:pass`) |
| `GENESIS_JWT_COOKIE_ALLOW_HTTP` | Enable plain HTTP mode (local networks only) |

**User creation format:** `username!:password` — note the `!` before the colon. Multiple users: `user1!:pass1;user2!:pass2`

**Docker secrets support (v2.3+):** Any `GENESIS_*` var can be passed as `GENESIS_*_FILE` pointing to a secret file.

**HTTPS note:** Ocular defaults to Secure cookies — HTTPS required outside localhost. Set `GENESIS_JWT_COOKIE_ALLOW_HTTP=true` only on trusted local networks.

## Upgrade Procedure

1. Pull new image: `docker-compose pull` (or `docker pull ghcr.io/simonwep/ocular:v2`)
2. Recreate: `docker-compose up -d`
3. Data in `./data` persists unchanged
4. If migrating from v1, follow the [migration guide](https://simonwep.github.io/ocular/pages/migrating)

## Gotchas

- **HTTPS required in production** — plain HTTP will break session cookies by default; use a reverse proxy with TLS
- **`GENESIS_CREATE_USERS` syntax** — the `!` separator between username and password is required; incorrect format silently fails to create users
- **Single-image, no DB** — all data is file-based under `/data/genesis`; straightforward backup but no SQL query access
- **v2 is a rewrite** — if upgrading from v1, data format changed; read the migration guide before upgrading
- **Managed options available** — PikaPods offers managed Ocular hosting if self-hosting is too much overhead

## References
- Upstream README: https://github.com/simonwep/ocular/blob/HEAD/README.md
- Deploy docs: https://simonwep.github.io/ocular/pages/deploy
- Live demo: https://simonwep.github.io/ocular/demo
