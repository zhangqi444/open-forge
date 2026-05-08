---
name: not-th-re-project
description: not-th.re (!3) recipe for open-forge. Client-side encrypted paste sharing platform with Monaco editor. Covers Docker Compose micro/minimal/simple deployments. Based on upstream README at https://github.com/not-three/main.
---

# not-th.re (!3)

Client-side encrypted paste sharing platform with Monaco editor, syntax highlighting, file transfers, and Excalidraw integration. All encryption happens in-browser (Web Crypto API) — the server never sees plaintext. AGPL-3.0. Upstream: https://github.com/not-three/main. Hosted instance: https://not-th.re.

Architecture: API backend (Node.js, SQLite or PostgreSQL) + UI frontend (separate container) + Draw (Excalidraw proxy).

## Compatible install methods

| Method | Storage | When to use |
|---|---|---|
| Micro (API only, SQLite) | SQLite | Smallest; use the public UI at not-th.re pointing to your API |
| Minimal (API + UI + Draw) | SQLite | Full self-hosted; single port via UI proxy |
| Simple (API + UI + Draw + PostgreSQL) | PostgreSQL | Recommended for production with more pastes |
| Full (HA with Traefik) | PostgreSQL | High-availability multi-replica with load balancer |

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| preflight | "Which deployment tier?" | Micro / Minimal / Simple / Full | Drives compose config |
| config | "HTTPS domain?" | FQDN | HTTPS is mandatory — Web Crypto API requires secure context |
| config | "Instance password (optional)?" | Free-text | INSTANCE_PASSWORD restricts who can save pastes |
| config | "Terms of service URL?" | URL | TERMS_OF_SERVICE_URL shown in UI |
| database | "PostgreSQL password?" | Free-text (sensitive) | Simple/Full tiers only |

## Software-layer concerns

| Concern | Detail |
|---|---|
| HTTPS mandatory | Web Crypto API (crypto.subtle) requires a secure context — UI will not function over plain HTTP |
| Images | ghcr.io/not-three/api, ghcr.io/not-three/ui, ghcr.io/not-three/draw |
| API port | 3000 (or 4000 in micro mode) |
| UI port | 4000 (or proxied internally in minimal) |
| Storage | SQLite at /data/db (default) or PostgreSQL |
| CLI | @not3/cli npm package or ghcr.io/not-three/cli Docker image |

## Install: Micro (API only)

Source: https://github.com/not-three/main/blob/main/README.md#micro

Smallest footprint. Pair with the public UI at https://not-th.re (set your server URL in Tools → Edit Settings).

```yaml
services:
  api:
    image: ghcr.io/not-three/api:latest
    restart: unless-stopped
    environment:
      CORS_ENABLED: true
      LIMITS_DISABLED: true
      INSTANCE_PASSWORD: MySecretPassword   # optional; removes if not needed
    ports:
      - 4000:4000
    volumes:
      - db:/data/db

volumes:
  db:
```

```bash
docker compose up -d
```

After deploy, visit https://not-th.re → Tools → Edit Settings:
```json
{
  "customServer": {
    "url": "https://your-api-host:4000/",
    "password": "MySecretPassword"
  }
}
```

## Install: Minimal (full self-hosted, SQLite)

Source: https://github.com/not-three/main/blob/main/README.md#minimal

All components, single exposed port (4000). UI proxies API and Draw internally.

```yaml
x-restart: &restart
  restart: unless-stopped

services:
  api:
    image: ghcr.io/not-three/api:latest
    <<: *restart
    volumes:
      - db:/data/db

  draw:
    image: ghcr.io/not-three/draw:latest
    <<: *restart

  ui:
    image: ghcr.io/not-three/ui:latest
    <<: *restart
    ports:
      - 4000:4000
    depends_on:
      - api
      - draw
    environment:
      PROXY_URL: http://api:3000
      DRAW_PROXY_URL: http://draw:80

volumes:
  db:
```

## Install: Simple (PostgreSQL)

Source: https://github.com/not-three/main/blob/main/README.md#simple

Recommended for production. Separate ports per service.

```yaml
x-restart: &restart
  restart: unless-stopped

services:
  api:
    image: ghcr.io/not-three/api:latest
    <<: *restart
    depends_on:
      - db
    ports:
      - 3000:3000
    environment:
      CORS_ENABLED: true
      CORS_ORIGIN: https://your-domain.com
      DATABASE_MODE: pg
      DATABASE_HOST: db
      DATABASE_USERNAME: notthree
      DATABASE_PASSWORD: changeme
      DATABASE_NAME: notthree

  draw:
    image: ghcr.io/not-three/draw:latest
    <<: *restart
    ports:
      - 4500:80

  ui:
    image: ghcr.io/not-three/ui:latest
    <<: *restart
    ports:
      - 4000:4000
    environment:
      API_URL: https://your-domain.com:3000
      DRAW_URL: https://your-domain.com:4500
      TERMS_OF_SERVICE_URL: https://example.com/tos

  db:
    image: postgres:14.5
    <<: *restart
    environment:
      POSTGRES_PASSWORD: changeme
      POSTGRES_USER: notthree
      POSTGRES_DB: notthree
    volumes:
      - db:/var/lib/postgresql/data

volumes:
  db:
```

## CLI usage

```bash
# Install CLI
npm install -g @not3/cli

# Or via Docker
docker run --rm -it -v "$(pwd):/data" ghcr.io/not-three/cli --help

# Save a paste
echo "hello world" | not3 save

# Read a paste
not3 query <id> <seed>
```

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

## Gotchas

- HTTPS is not optional: The Web Crypto API (`crypto.subtle`) is unavailable in non-secure contexts. Deploy behind TLS (nginx/Caddy/Traefik with Let's Encrypt) before using the UI.
- Encrypted links include the server URL: If you use a private server, shared links will embed your server's address. Recipients are notified and asked to confirm loading from an external server.
- INSTANCE_PASSWORD is optional but recommended: Without it, anyone who knows your API URL can store pastes.
- Micro tier needs public UI trust: In micro mode, you're relying on not-th.re's public UI to interact with your private API — the UI is served by a third party.
- CORS_ORIGIN must match UI URL: In Simple/Full deployments, set CORS_ORIGIN to the UI's public URL to avoid cross-origin errors.

## Links

- GitHub (monorepo index): https://github.com/not-three/main
- API repo: https://github.com/not-three/api
- UI repo: https://github.com/not-three/ui
- Hosted instance: https://not-th.re
- CLI on npm: https://www.npmjs.com/package/@not3/cli
