---
name: PLANKA
description: Self-hosted real-time Kanban board (Trello clone). Projects, boards, lists, cards, drag-and-drop, real-time sync across users, Markdown descriptions, 100+ notification providers, OIDC SSO. Node.js + Postgres. AGPL-3.0 (OSS) / commercial Pro tier.
---

# PLANKA

PLANKA is the most polished OSS Trello clone. Looks like Trello, feels like Trello, behaves like Trello — but entirely self-hosted. Drag-and-drop cards across lists, mentions + notifications, attachments + avatars, labels, due dates, card stopwatch, member assignments, markdown descriptions, board templates.

- **Real-time sync** — two users on the same board see each other's edits instantly
- **Rich markdown** — proper editor, code blocks, task lists
- **Flexible notifications** — 100+ providers via Apprise (Discord, Slack, Telegram, Gotify, ntfy, Matrix, email, SMS, and many more)
- **OIDC SSO** — sign in with Keycloak / Zitadel / Authelia / Google / Azure AD / etc.
- **i18n** — 40+ UI languages
- **Commercial Pro** tier adds: advanced permissions, dashboard, extra features (see <https://planka.app/pro>)

- Upstream repo: <https://github.com/plankanban/planka>
- Website: <https://planka.app>
- Docs: <https://docs.planka.cloud>
- Install: <https://docs.planka.cloud/docs/installation/docker/production-version/>
- Demo: <https://planka.app>
- API: <https://plankanban.github.io/planka/swagger-ui/>

## Architecture in one minute

- **`planka`** — single Node.js service (Sails.js + React)
- **Postgres** — everything (users, projects, boards, cards, attachments, notifications)
- **Volume `/app/data`** — file uploads (attachments, avatars, custom backgrounds)
- WebSockets for real-time sync (any reverse proxy must forward WS)

## Compatible install methods

| Infra       | Runtime                                              | Notes                                                                    |
| ----------- | ---------------------------------------------------- | ------------------------------------------------------------------------ |
| Single VM   | Docker Compose (bundled Postgres)                    | **Upstream-documented**                                                   |
| Single VM   | Docker with external Postgres                        | Recommended for prod                                                      |
| Kubernetes  | Community Helm charts                                  | <https://docs.planka.cloud/docs/installation/kubernetes/>                 |
| Managed     | PLANKA Cloud                                           | <https://planka.app/pricing>                                              |

## Inputs to collect

| Input                       | Example                             | Phase     | Notes                                                          |
| --------------------------- | ----------------------------------- | --------- | -------------------------------------------------------------- |
| `BASE_URL`                  | `https://planka.example.com`         | DNS       | Used by email/OIDC redirects                                    |
| `SECRET_KEY`                | `openssl rand -hex 64`              | Security  | **Critical** — session + webhook signing                        |
| `DATABASE_URL`              | `postgresql://user:pw@db:5432/planka` | DB      | Postgres 13+                                                     |
| `DEFAULT_ADMIN_EMAIL`       | `admin@example.com`                  | Bootstrap | Seeds first admin; setting this **locks the user from deletion** |
| `DEFAULT_ADMIN_PASSWORD`    | strong                              | Bootstrap | Initial password                                                 |
| `DEFAULT_ADMIN_NAME`        | `Alice Admin`                        | Bootstrap | Display name                                                     |
| `DEFAULT_ADMIN_USERNAME`    | `alice`                              | Bootstrap | Username                                                        |
| `TRUST_PROXY`               | `true` (behind reverse proxy)        | Runtime   | For correct IP-based rate limiting                               |
| OIDC (optional)             | issuer / client / secret / scopes   | Auth      | Env vars `OIDC_*`                                                 |
| SMTP (optional)             | host/port/user/pw/from               | Email     | For notifications                                                |

## Install via Docker Compose

Upstream [docker-compose.yml](https://github.com/plankanban/planka/blob/master/docker-compose.yml) is comprehensive. Trimmed minimum:

```yaml
services:
  planka:
    image: ghcr.io/plankanban/planka:1.27.2     # pin; check releases
    container_name: planka
    restart: on-failure
    ports:
      - "3000:1337"
    volumes:
      - data:/app/data
      # - ./terms:/app/terms/custom       # custom ToS/privacy
    environment:
      BASE_URL: https://planka.example.com
      DATABASE_URL: postgresql://postgres:<strong>@postgres/planka
      SECRET_KEY: <openssl rand -hex 64>
      TRUST_PROXY: "true"
      # Initial admin (optional; set only on first boot)
      DEFAULT_ADMIN_EMAIL: admin@example.com
      DEFAULT_ADMIN_PASSWORD: <strong>
      DEFAULT_ADMIN_NAME: Admin
      DEFAULT_ADMIN_USERNAME: admin
    depends_on:
      postgres: { condition: service_healthy }

  postgres:
    image: postgres:17-alpine
    container_name: planka-db
    restart: on-failure
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: <strong>
      POSTGRES_DB: planka
    volumes:
      - db-data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres -d planka"]
      interval: 10s
      retries: 5

volumes:
  data:
  db-data:
```

Listens on port **1337** inside container (Sails.js default). Map externally to whatever you want.

## Reverse proxy (WebSockets required)

nginx:

```nginx
location / {
    proxy_pass http://127.0.0.1:3000;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}
```

Caddy (auto-handles WS):

```
planka.example.com {
    reverse_proxy 127.0.0.1:3000
}
```

## First boot

1. Browse `https://planka.example.com`
2. Log in with `DEFAULT_ADMIN_EMAIL` + `DEFAULT_ADMIN_PASSWORD`
3. Create your first project + board
4. **Settings → Users** — invite others
5. **Settings → OIDC** (if desired) — configure SSO

## Data & config layout

Inside `/app/data/`:

- `user-avatars/` — uploaded avatars
- `project-background-images/` — board background images
- `attachments/` — file uploads on cards

All the app state lives in Postgres.

## Backup

```sh
docker compose exec -T postgres pg_dump -U postgres planka | gzip > planka-db-$(date +%F).sql.gz
docker run --rm -v data:/src -v "$PWD":/backup alpine tar czf /backup/planka-data-$(date +%F).tgz -C /src .
```

## Upgrade

1. Releases: <https://github.com/plankanban/planka/releases>. Active; major version jumps occasionally rename env vars.
2. `docker compose pull && docker compose up -d`. Migrations via Sails' `waterline-migration` or manual scripts.
3. **Always back up DB** before version bumps.
4. Read release notes — 1.x → 2.x transition (if it happens) will have breaking changes.
5. Config keys list: <https://docs.planka.cloud/docs/category/configuration/>.

## Gotchas

- **`BASE_URL` is baked into OIDC redirect URIs** + email links. Fix permanently before wiring up SSO or sending invites.
- **`DEFAULT_ADMIN_EMAIL` locks the user** against deletion/editing if set. Intentional safety: even another admin can't lock themselves out.
- **`SECRET_KEY` loss** = all active sessions invalidated; users must re-login. Back up as part of secrets workflow.
- **Port 1337** is the internal port (Sails.js convention). Map externally to 3000/80/443 as you prefer.
- **WebSocket required** for real-time sync. nginx/proxies without WS upgrade = boards appear frozen between users.
- **Per-card activity log** is stored in DB; can grow if board churn is high. Occasional pruning is fine.
- **100+ notification providers via Apprise** — configure destination URLs in board notification settings. Discord/Slack webhooks, ntfy topics, Matrix rooms, and many more.
- **Email notifications** are separate from Apprise-style channels; configure SMTP.
- **Markdown editor** supports task lists, code blocks, tables. GFM-ish.
- **Custom card backgrounds** upload to `data/` — consider size limits for multi-user installs (`MAX_UPLOAD_FILE_SIZE` env).
- **Attachment size** default limit is generous; tune for your use case.
- **Permission model is flat in OSS**: project members = all equal. **Pro** adds fine-grained roles.
- **Pro features** (advanced permissions, dashboards, additional integrations) are behind a paid license key. OSS is fully functional for Trello-parity.
- **API is REST** (Swagger at the link above) — automate board management from scripts.
- **No native mobile apps from upstream**, but the PWA is solid; community Notes app (macOS/iOS/Windows/Android) is for the Notes sub-app.
- **AGPL-3.0** — public SaaS-ification = must share source.
- **Security issues**: report via `security@planka.group`, NOT GitHub public issues.
- **Alternatives worth knowing:**
  - **Wekan** — older Trello clone (Meteor.js), real-time too, feature parity-ish
  - **Kanboard** — PHP, single-user-first, simpler UI
  - **Focalboard** (archived) — was Mattermost's Trello clone; now part of Mattermost Boards
  - **Vikunja** — more general (Todoist + Trello hybrid), Go, active development
  - **Nextcloud Deck** — lightweight Kanban if you already run Nextcloud
  - **Trello / Notion / Linear / ClickUp** — commercial SaaS

## Links

- Repo: <https://github.com/plankanban/planka>
- Website: <https://planka.app>
- Docs: <https://docs.planka.cloud/docs/welcome/>
- Installation: <https://docs.planka.cloud/docs/installation/docker/production-version/>
- Configuration: <https://docs.planka.cloud/docs/category/configuration/>
- API (Swagger): <https://plankanban.github.io/planka/swagger-ui/>
- Pro version: <https://planka.app/pro>
- Pricing: <https://planka.app/pricing>
- Releases: <https://github.com/plankanban/planka/releases>
- Container registry: <https://github.com/plankanban/planka/pkgs/container/planka>
- Discord: <https://discord.gg/WqqYNd7Jvt>
- Security: security@planka.group
