---
name: wingfit-project
description: Wingfit recipe for open-forge. Minimalist fitness app for planning workouts, tracking personal records, and integrating smartwatch data. Single-container Docker deployment backed by a local storage volume. Upstream: https://github.com/itskovacs/wingfit
---

# Wingfit

Minimalist, privacy-first fitness app for planning workouts, tracking personal records, and leveraging smartwatch data. No telemetry, no cloud dependency — data stays in a local storage volume. Upstream: <https://github.com/itskovacs/wingfit>. Demo: <https://wingfit.fr>.

Built with FastAPI (Python). Exposes port `8000` inside the container. License: CC BY-NC-SA 4.0 (non-commercial only).

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux host | Docker Compose (recommended) | Single service, upstream compose file |
| Any Linux host | `docker run` | Quick start |
| Umbrel | Umbrel app store | <https://apps.umbrel.com/app/wingfit> |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Which host port should Wingfit bind to?" | Default: `8080` (maps container `:8000`) |
| preflight | "Where should the storage volume live on the host?" | Default: `./storage` — do not change the container path `/app/storage` |
| config | "Enable OIDC authentication?" | Optional |
| config (if OIDC) | "OIDC discovery URL, client ID, client secret, redirect URI?" | Written to `storage/config.yml` |

## Software-layer concerns

### Image

```
ghcr.io/itskovacs/wingfit:5
```

Pin to a major tag. Latest tags: <https://github.com/itskovacs/wingfit/pkgs/container/wingfit>

### Data directory

All persistent data is stored under `/app/storage` inside the container. Map a bind-mount:

```yaml
volumes:
  - ./storage:/app/storage
```

Do **not** change `/app/storage` (the container path). Only the host-side path (`./storage`) is customisable.

### Recommended compose

```yaml
services:
  wingfit:
    image: ghcr.io/itskovacs/wingfit:5
    restart: unless-stopped
    ports:
      - "8080:8000"
    volumes:
      - ./storage:/app/storage
```

> Source: upstream docker-compose.yml — <https://github.com/itskovacs/wingfit/blob/main/docker-compose.yml>
> Note: the upstream file uses `build: .` (builds from source). Replace with the image reference above for a clean deploy.

### Configuration file

Runtime config lives at `storage/config.yml` (created on first run). Edit directly on the host; **restart the container after any change**.

| Key | Default | Purpose |
|---|---|---|
| `ACCESS_TOKEN_EXPIRE_MINUTES` | `30` | Access token lifespan |
| `REFRESH_TOKEN_EXPIRE_MINUTES` | `1440` | Refresh token lifespan (24 h) |
| `REGISTER_ENABLE` | `true` | Set `false` to lock signups after initial setup |
| `OIDC_DISCOVERY_URL` | — | OIDC SSO discovery endpoint |
| `OIDC_CLIENT_ID` / `OIDC_CLIENT_SECRET` | — | OIDC credentials |
| `OIDC_REDIRECT_URI` | — | Must match public URL + `/auth` |

Full config reference: <https://github.com/itskovacs/wingfit/tree/main/docs/config.md>

### Reverse proxy / TLS

Wingfit has no built-in TLS. Front it with Caddy, Traefik, or nginx. The OIDC redirect URI must match the public HTTPS URL.

### OIDC + self-signed CA

If Wingfit can't reach an internal OIDC provider due to a self-signed cert, bake your CA into a custom image. See upstream troubleshooting: <https://github.com/itskovacs/wingfit/tree/main/docs/config.md#tbshoot-cert>

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

Data in the storage volume persists across upgrades.

## Gotchas

- **License CC BY-NC-SA 4.0** — commercial use is prohibited. Personal/non-commercial self-hosting is fine.
- **Container path `/app/storage` is fixed** — only the host-side of the bind-mount is customisable.
- **Config changes require a restart** — `docker compose restart` after editing `storage/config.yml`.
- **Upstream compose uses `build: .`** — swap in the prebuilt image (`ghcr.io/itskovacs/wingfit:5`) for production deploys.
- **Disable registration after setup** — set `REGISTER_ENABLE: false` to prevent unwanted signups on public instances.
- **OIDC redirect URI must match exactly** — mismatched URIs cause silent auth failures.

## Links

- Upstream README + docs: <https://github.com/itskovacs/wingfit>
- Config docs: <https://github.com/itskovacs/wingfit/tree/main/docs/config.md>
- Umbrel listing: <https://apps.umbrel.com/app/wingfit>
