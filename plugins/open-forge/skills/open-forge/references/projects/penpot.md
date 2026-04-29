---
name: penpot-project
description: Penpot recipe for open-forge. MPL-2.0 open-source design & prototyping platform — Figma-style collaborative vector design built on open web standards (SVG, CSS, HTML). Clojure + ClojureScript app, ships as a multi-container Docker Compose stack (frontend nginx, backend, exporter, Postgres, Valkey/Redis). Verified Digital Public Good. Covers the upstream-blessed Docker Compose install, Kubernetes (community Helm), configuration via PENPOT_FLAGS, and the critical secret-key + storage-backend decisions for production.
---

# Penpot

MPL-2.0 open-source design & prototyping platform. Collaborative vector design tool with plugin API, Design Tokens, MCP server, and a "designs are code" philosophy using SVG + CSS + HTML natively. Upstream: <https://github.com/penpot/penpot>. Docs: <https://help.penpot.app/>. Self-host guide: <https://help.penpot.app/technical-guide/getting-started/>. Configuration reference: <https://help.penpot.app/technical-guide/configuration/>.

## What you're deploying

The upstream docker-compose.yaml runs:

- **penpot-frontend** — nginx serving the ClojureScript SPA + reverse-proxying API/websocket
- **penpot-backend** — Clojure (JVM) API + realtime
- **penpot-exporter** — Node.js service that renders PDF / PNG / SVG exports via headless Chromium
- **penpot-postgres** — Postgres 15 (primary DB)
- **penpot-valkey** — Valkey (Redis fork) for websocket pub/sub + session cache

Default public entry: container port `8080` (exposed as host `9001` in upstream's default compose). TLS terminated by an external reverse proxy OR by the included-but-commented Traefik service.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose (upstream `docker/images/docker-compose.yaml`) | <https://github.com/penpot/penpot/blob/develop/docker/images/docker-compose.yaml> | ✅ Recommended | The canonical self-host path. |
| Kubernetes (community Helm) | <https://github.com/penpot/penpot-helm> · <https://artifacthub.io/packages/helm/penpot/penpot> | ⚠️ Community-maintained | Upstream links to this chart but it's maintained by the community. |
| Elestio | <https://elest.io/open-source/penpot> | ⚠️ Managed provider | One-click managed deploy. |
| Build from source | Clojure + Clojure CLI + Node.js for frontend | ✅ | Dev / contributors. Not a typical self-host path. |

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Install method?" | `AskUserQuestion` | Drives section. |
| domain | "Public FQDN?" | Free-text (e.g. `penpot.example.com`) | Written into `PENPOT_PUBLIC_URI`. |
| ports | "External HTTP(S) port?" | Free-text, default `9001` | `penpot-frontend` publishes `9001:8080` by default. |
| tls | "Reverse proxy for TLS? (Caddy / nginx / Traefik included / external)" | `AskUserQuestion` | The compose includes a commented Traefik service; most users front with an existing reverse proxy. |
| secret | "Generate `PENPOT_SECRET_KEY`?" | Boolean (auto-generate recommended) | **Mandatory for production.** Derive with `python3 -c "import secrets; print(secrets.token_urlsafe(64))"`. Replace the `change-this-insecure-key` default. |
| storage | "Asset storage? (filesystem / S3)" | `AskUserQuestion` | FS uses Docker volume `penpot_assets`; S3 requires `AWS_ACCESS_KEY_ID` + `PENPOT_OBJECTS_STORAGE_S3_*` vars. |
| smtp | "SMTP host / port / user / pass / from?" | Free-text (sensitive) | Required for email verification (`disable-email-verification` in PENPOT_FLAGS defaults to DISABLED in upstream compose — flip before public deploy). |
| db | "Use bundled Postgres or external?" | `AskUserQuestion` | Bundled is fine for small teams; external recommended for production durability. |
| auth | "Which login methods? (password / Google / GitHub / GitLab / OIDC / LDAP)" | Multi-select | Each sets its own `PENPOT_FLAGS` plus `PENPOT_<provider>_CLIENT_*` vars. |

## Install — Docker Compose

```bash
# 1. Download the upstream compose file to a fresh directory
sudo mkdir -p /opt/penpot && cd /opt/penpot
sudo curl -fsSL \
  https://raw.githubusercontent.com/penpot/penpot/develop/docker/images/docker-compose.yaml \
  -o docker-compose.yaml

# 2. Generate a secret key
SECRET_KEY=$(openssl rand -base64 64 | tr -d '\n')

# 3. Edit docker-compose.yaml — the three BLOCKS at the top:
#    x-flags: PENPOT_FLAGS: disable-email-verification enable-smtp ...
#    x-uri:   PENPOT_PUBLIC_URI: http://localhost:9001
#    x-secret-key: PENPOT_SECRET_KEY: change-this-insecure-key
#
#    For production, replace these with:
sudo sed -i \
  -e "s|PENPOT_PUBLIC_URI: http://localhost:9001|PENPOT_PUBLIC_URI: https://penpot.example.com|" \
  -e "s|PENPOT_SECRET_KEY: change-this-insecure-key|PENPOT_SECRET_KEY: ${SECRET_KEY}|" \
  docker-compose.yaml

# 4. Flip PENPOT_FLAGS for production — remove disable-email-verification + disable-secure-session-cookies
#    (upstream's compose ships with both DISABLED for local-dev friendliness)
sudo sed -i \
  's|PENPOT_FLAGS: disable-email-verification enable-smtp enable-prepl-server disable-secure-session-cookies|PENPOT_FLAGS: enable-registration enable-login-with-password enable-smtp enable-prepl-server|' \
  docker-compose.yaml

# 5. Start
sudo docker compose up -d
sudo docker compose logs -f penpot-backend
# Wait for "Welcome to Penpot" banner; backend migrations finish on first boot.
```

Visit `http://host:9001/` (or your domain behind the reverse proxy). Register the first account — **that account will NOT be admin automatically**; Penpot has no instance-admin UI. To promote a user to admin, use the CLI:

```bash
docker compose exec penpot-backend ./run.sh manage create-profile --email you@example.com --fullname 'You' --password '<pw>'
# Or mark existing as admin:
docker compose exec penpot-backend ./run.sh manage set-profile-admin --email you@example.com
```

(Command names vary by version; check `./run.sh manage --help` inside the backend container.)

## PENPOT_FLAGS — the main knob

Penpot features are toggled via `PENPOT_FLAGS` — a space-separated list of `enable-*` / `disable-*` tokens in env. Full list: <https://help.penpot.app/technical-guide/configuration/#feature-flags>.

Common flags:

| Flag | Effect |
|---|---|
| `enable-registration` / `disable-registration` | Toggle signup. Disable for private instances. |
| `enable-login-with-password` | Allow email+password login. |
| `enable-login-with-google` / `-github` / `-gitlab` / `-oidc` / `-ldap` | OAuth / SSO providers. Each needs its own `PENPOT_<PROVIDER>_CLIENT_ID` + `CLIENT_SECRET`. |
| `enable-email-verification` / `disable-email-verification` | **Enable in production.** Default `docker-compose.yaml` disables it — fine for laptop dev, dangerous on public URLs. |
| `enable-smtp` | Enable outbound mail. Also requires `PENPOT_SMTP_*` vars. |
| `enable-secure-session-cookies` / `disable-secure-session-cookies` | **Enable in production.** Disabled in upstream compose default. |
| `enable-prepl-server` | Internal REPL server for admin CLI (stays on). |
| `enable-webhooks` | Webhooks feature. |
| `enable-onboarding-team` / `-questions` / `-newsletter` | Onboarding wizard components. |
| `enable-telemetry` / `disable-telemetry` | Anonymous usage metrics. Audit at upstream before enabling. |

Flags evaluate left-to-right, so `enable-X disable-X` → disabled. Document your final flag list in a comment next to the compose file — debugging "why is SSO not working" starts with "is the flag enabled?"

## SMTP

```yaml
environment:
  # Add to penpot-backend env:
  PENPOT_SMTP_DEFAULT_FROM: "Penpot <no-reply@example.com>"
  PENPOT_SMTP_DEFAULT_REPLY_TO: "no-reply@example.com"
  PENPOT_SMTP_HOST: smtp.example.com
  PENPOT_SMTP_PORT: 587
  PENPOT_SMTP_USERNAME: ...
  PENPOT_SMTP_PASSWORD: ...
  PENPOT_SMTP_TLS: "true"
  PENPOT_SMTP_SSL: "false"
```

Required for email-verification, password reset, team invites. Without SMTP, these flows quietly fail.

## S3 asset storage (production)

For any production deploy, move asset storage off the local volume to S3/R2/compatible:

```yaml
environment:
  # Add to penpot-backend:
  PENPOT_OBJECTS_STORAGE_BACKEND: s3
  PENPOT_OBJECTS_STORAGE_S3_ENDPOINT: https://s3.example.com
  PENPOT_OBJECTS_STORAGE_S3_BUCKET: penpot-assets
  PENPOT_OBJECTS_STORAGE_S3_REGION: us-east-1
  AWS_ACCESS_KEY_ID: ...
  AWS_SECRET_ACCESS_KEY: ...
```

Remove the `penpot_assets:/opt/data/assets` volume mount from backend + frontend once S3 is live.

## Reverse proxy (Caddy)

```caddy
penpot.example.com {
    reverse_proxy 127.0.0.1:9001
    # Large uploads
    request_body {
        max_size 350MB
    }
}
```

Set `PENPOT_HTTP_SERVER_MAX_BODY_SIZE` accordingly (default 367001600 ≈ 350MB). The compose ships with this sized for big SVG/PNG imports — don't squash it smaller than your users' file sizes.

## Upgrade procedure

```bash
cd /opt/penpot
# 1. Back up Postgres + assets
docker compose exec penpot-postgres pg_dump -U penpot penpot > penpot-$(date +%F).sql
sudo tar -czf penpot-assets-$(date +%F).tar.gz \
  $(docker volume inspect penpot_penpot_assets -f '{{.Mountpoint}}')

# 2. Pull new images (optionally pin PENPOT_VERSION env var to a specific tag)
docker compose pull
docker compose up -d
docker compose logs -f penpot-backend   # migrations run on boot
```

Pin `PENPOT_VERSION=2.3.0` (or similar) in your env / compose if you want deterministic versions. Default is `latest`.

## Backup

Key things to archive:

1. **Postgres DB** — `pg_dump -U penpot penpot` via `docker compose exec`.
2. **Assets volume** — `penpot_penpot_assets` Docker volume (OR the S3 bucket if using S3 storage).
3. **`docker-compose.yaml` + env overrides** — treat as infra-as-code, version-control.

The DB contains all design file metadata + flags + users. The assets volume contains the actual SVG / image bytes. Restoring only one is not enough.

## Gotchas

- **Default `PENPOT_SECRET_KEY` is literally `change-this-insecure-key` in the upstream compose.** This is a dev convenience, not a production default. Change it before first boot — changing it later invalidates all sessions + tokens + invitation codes.
- **Default PENPOT_FLAGS disables email verification AND secure session cookies.** Both are fine for a laptop demo and dangerous on a public URL. Flip to `enable-email-verification` + `enable-secure-session-cookies` for anything public.
- **No instance-admin UI by default.** Users with `is_admin=true` in the `profile` table get admin; there's no "Promote to admin" button in the web UI. Use the backend CLI via `docker compose exec penpot-backend ./run.sh manage …` to promote.
- **Postgres 15 baked into compose.** Switching to newer Postgres is a manual pg_dump + restore, not a version bump. Upstream pins Postgres deliberately.
- **Valkey = Redis fork.** Upstream renamed from Redis to Valkey around 2024 licensing concerns. Functionally equivalent; old tutorials referencing `penpot-redis` service work if you rename appropriately.
- **Exporter service is Chromium-heavy.** `penpot-exporter` runs headless Chromium. On memory-constrained hosts, exports can OOM. Give backend + exporter both at least 1GB RAM (compose has no default limit; set `mem_limit` as needed).
- **CSRF + `PENPOT_PUBLIC_URI` mismatch.** If the URI in config doesn't match what the browser sees (scheme, port, trailing slash), logins appear to succeed but next request 403s. Match EXACTLY including `https://` prefix.
- **WebSocket proxying.** The realtime layer is WebSocket-based. Upstream Traefik config template in the compose does this correctly; nginx / Caddy setups need `proxy_set_header Upgrade $http_upgrade; proxy_set_header Connection "upgrade";` — Caddy's `reverse_proxy` does this by default.
- **OAuth provider URIs are picky.** Google / GitHub / GitLab / OIDC redirect URIs must exactly match `${PENPOT_PUBLIC_URI}/api/auth/oauth/<provider>/callback`. Off-by-one (trailing slash, http vs https) = "provider returned an error."
- **File-size limits bite on design imports.** Figma-to-Penpot migrations via SVG can be multi-hundred-MB. Default max body size is 350MB; bump `PENPOT_HTTP_SERVER_MAX_BODY_SIZE` and the reverse-proxy equivalent if larger files needed.
- **Penpot is under ACTIVE development.** Feature flags shift between releases; config keys occasionally rename (the v2.0 release renamed several). Read the CHANGELOG before every upgrade: <https://github.com/penpot/penpot/blob/develop/CHANGES.md>.
- **Data is stored as CLJS data structures in Postgres.** Direct SQL access works for user/team admin but editing design-file data manually is a recipe for corrupt files. Use the API.
- **Community Helm chart drifts from upstream compose.** If you use the Helm chart, some env-var names or service layouts differ. Cross-check with the chart's values.yaml, not this recipe.

## Links

- Upstream repo: <https://github.com/penpot/penpot>
- Self-host overview: <https://help.penpot.app/technical-guide/getting-started/>
- Configuration reference: <https://help.penpot.app/technical-guide/configuration/>
- Feature flags: <https://help.penpot.app/technical-guide/configuration/#feature-flags>
- Docker compose: <https://github.com/penpot/penpot/blob/develop/docker/images/docker-compose.yaml>
- Helm chart (community): <https://github.com/penpot/penpot-helm>
- Plugins / API: <https://help.penpot.app/mcp/>
- Changelog: <https://github.com/penpot/penpot/blob/develop/CHANGES.md>
- Community forum: <https://community.penpot.app/>
- Releases: <https://github.com/penpot/penpot/releases>
