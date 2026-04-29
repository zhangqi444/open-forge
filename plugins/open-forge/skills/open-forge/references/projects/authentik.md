---
name: authentik
description: Self-hosted identity provider (OIDC, SAML, LDAP, proxy, RADIUS). Replaces Keycloak/Auth0 for internal SSO. Python/Django + PostgreSQL + Redis.
---

# authentik

authentik is a full-featured IdP and SSO platform. It speaks OAuth2/OIDC, SAML 2.0, LDAP, RADIUS, and has a forward-auth proxy for apps without native SSO. Enrollment flows, MFA (TOTP, WebAuthn, Duo), policies, and group/role mapping are configurable through a web UI or declaratively via "blueprints."

- Upstream repo: <https://github.com/goauthentik/authentik>
- Docs: <https://docs.goauthentik.io/>
- Installation: <https://docs.goauthentik.io/docs/install-config/install/docker-compose>
- Images: `ghcr.io/goauthentik/server` (also on Docker Hub)

## Architecture in one minute

- **server** — Django web server + API + SSO endpoints (OIDC, SAML, etc.) on ports 9000 (HTTP) / 9443 (HTTPS)
- **worker** — background task runner (user sync, LDAP import, outposts management); needs the Docker socket to manage outpost containers
- **postgresql** — persistent store (users, apps, policies, sessions, events)

Older versions also shipped a **Redis** service. As of recent releases (2024.4+), authentik uses a local Redis replacement inside the server container by default; the upstream compose file no longer defines a Redis service.

**Outposts** are separate containers deployed per integration (proxy outpost, LDAP outpost, RADIUS outpost). The worker manages their lifecycle via Docker / Kubernetes. You usually don't run them manually — create them in the UI.

## Compatible install methods

| Infra              | Runtime                       | Notes                                                                       |
| ------------------ | ----------------------------- | --------------------------------------------------------------------------- |
| Single VM          | Docker + Compose              | Recommended; upstream publishes `docker-compose.yml` at goauthentik.io       |
| Kubernetes         | Helm chart (official)         | `authentik/authentik` — production-grade                                    |
| Bare metal         | Unsupported                   | Not a supported install path                                                |

## Inputs to collect

| Input                       | Example                                 | Phase     | Notes                                                                      |
| --------------------------- | --------------------------------------- | --------- | -------------------------------------------------------------------------- |
| `PG_PASS`                   | strong random                           | Data      | **Required.** PostgreSQL password                                           |
| `AUTHENTIK_SECRET_KEY`      | 50+ random chars                        | Runtime   | **Required.** Signs cookies/tokens; `openssl rand -base64 60 \| tr -d '\n'` |
| Host FQDN                   | `auth.example.com`                      | DNS/Proxy | Terminate TLS at a reverse proxy; point it at `server:9000`                 |
| `AUTHENTIK_TAG`             | `2026.2.2` (current at time of writing) | Runtime   | Pin — floating tags are fine on dev, dangerous in prod                      |
| SMTP                        | host, user, pass                        | Runtime   | Set `AUTHENTIK_EMAIL__*` — needed for password-reset / enrollment           |
| `AUTHENTIK_BOOTSTRAP_PASSWORD` (optional) | strong random               | First run | If set, creates the `akadmin` user with this password on first boot        |
| `AUTHENTIK_BOOTSTRAP_TOKEN` (optional)    | random                      | First run | Initial API token; alternative to interactive bootstrap                     |

## Install via Docker Compose

Download upstream's authoritative compose + env template:

```sh
mkdir -p authentik && cd authentik
wget https://goauthentik.io/docker-compose.yml
echo "PG_PASS=$(openssl rand -base64 36 | tr -d '\n')" > .env
echo "AUTHENTIK_SECRET_KEY=$(openssl rand -base64 60 | tr -d '\n')" >> .env
# Pin the tag you want (check releases):
echo "AUTHENTIK_TAG=2026.2.2" >> .env
# Optional — bootstrap a first admin non-interactively:
echo "AUTHENTIK_BOOTSTRAP_PASSWORD=$(openssl rand -base64 24 | tr -d '\n')" >> .env
echo "AUTHENTIK_BOOTSTRAP_EMAIL=admin@example.com" >> .env

docker compose up -d
```

Services defined in the upstream compose (at <https://goauthentik.io/docker-compose.yml>):

- `postgresql` — `docker.io/library/postgres:16-alpine`, volume `database:/var/lib/postgresql/data`
- `server` — `ghcr.io/goauthentik/server:${AUTHENTIK_TAG}` running `command: server`, ports `${COMPOSE_PORT_HTTP:-9000}:9000` and `${COMPOSE_PORT_HTTPS:-9443}:9443`, mounts `./data`, `./custom-templates`
- `worker` — same image running `command: worker`, **needs `/var/run/docker.sock`** to manage outposts, mounts `./data`, `./certs`, `./custom-templates`

On first boot, browse `https://auth.example.com/if/flow/initial-setup/` to set the `akadmin` password (unless you used `AUTHENTIK_BOOTSTRAP_PASSWORD`). After login, create your first application + provider.

### Reverse proxy notes

Terminate TLS in front (Traefik, nginx, Caddy) and forward to `server:9000` over HTTP inside the compose network, **or** forward to `server:9443` with `--insecure-skip-verify` / equivalent if you want HTTPS inside. Upstream docs: <https://docs.goauthentik.io/docs/install-config/reverse-proxy>.

## Data & config layout

- `./data/` → `/data` in server + worker — media uploads, certificates, blueprint-loaded files
- `./certs/` → `/certs` in worker — SSL certs for outposts / LDAP
- `./custom-templates/` → `/templates` — override enrollment/email templates
- PostgreSQL data in the `database` named volume
- All app settings are env-driven (`AUTHENTIK_*` prefix). Full reference: <https://docs.goauthentik.io/docs/install-config/configuration/>

## Backup

```sh
# DB dump
docker compose exec -T postgresql pg_dump -U authentik authentik | gzip > authentik-db-$(date +%F).sql.gz

# App state
tar czf authentik-data-$(date +%F).tgz data/ certs/ custom-templates/ .env
```

**`AUTHENTIK_SECRET_KEY` is irreplaceable.** Losing it invalidates all existing sessions + signed tokens. Keep `.env` in your secret store.

## Upgrade

1. Read the release notes — authentik publishes **year-based versions** (e.g. `2026.2`). Each major (year.quarter) can have breaking changes: <https://github.com/goauthentik/authentik/releases>. Also check <https://docs.goauthentik.io/docs/releases>.
2. Back up DB + `data/`.
3. Edit `AUTHENTIK_TAG` in `.env` (one major step at a time; don't jump multiple majors).
4. `docker compose pull && docker compose up -d`.
5. Migrations run automatically on start; tail `docker compose logs -f server worker` and watch for errors before sending traffic.

## Gotchas

- **`AUTHENTIK_SECRET_KEY` is permanent.** Rotating it is explicitly unsupported and will invalidate long-lived tokens/cookies. Generate once, guard carefully.
- **Worker needs the Docker socket.** It manages outpost containers by talking to Docker directly. This is root-equivalent host access. Use `docker-socket-proxy` if that's unacceptable.
- **`:latest` tag does not exist for production.** Use year-version tags (e.g. `2026.2.2`). Pin patch versions in prod.
- **Initial-setup flow is world-accessible** until you complete it. `https://<host>/if/flow/initial-setup/` — don't deploy the hub on the public internet and then take a 3-hour lunch break before creating the admin.
- **Outposts need reachability back to the hub.** A proxy outpost running on a different host must be able to reach the hub's API; firewall accordingly.
- **`AUTHENTIK_POSTGRESQL__PASSWORD` uses double underscores** to namespace nested config keys. Single underscore = silent config miss. Same convention for `AUTHENTIK_EMAIL__HOST`, etc.
- **LDAP outpost** binds to 389/636 and needs its own set of credentials (the "bind DN" password set on the outpost itself). Don't confuse this with the authentik admin.
- **Blueprints apply at startup.** Drop a YAML in `./blueprints/` → mounted into the worker → reconciled on worker boot. Perfect for GitOps, surprising if you don't expect it.
- **Free tier vs enterprise features.** Some features (on-premise enterprise support, some RAC features) are gated by an enterprise license. The core IdP is open source under MIT.
- **Clock skew breaks everything OAuth.** JWTs are time-bound; keep NTP running.
- **Redis removal migration**: if you're upgrading from a pre-2024.4 install that still had a separate Redis service, follow the migration notes — don't blindly copy the new compose over the old.

## Links

- Docs: <https://docs.goauthentik.io/>
- Docker-Compose install: <https://docs.goauthentik.io/docs/install-config/install/docker-compose>
- Config reference: <https://docs.goauthentik.io/docs/install-config/configuration/>
- Release notes: <https://docs.goauthentik.io/docs/releases>
- GitHub releases: <https://github.com/goauthentik/authentik/releases>
- Helm chart: <https://github.com/goauthentik/helm>
- Container registry: <https://github.com/goauthentik/authentik/pkgs/container/server>
