---
name: strapi
description: Strapi recipe for open-forge. Covers the upstream-documented install methods — CLI quickstart (Node.js, dev/production), community Docker workflow via @strapi-community/dockerize, and database options (SQLite for dev, PostgreSQL/MySQL/MariaDB for production).
---

# Strapi

Open-source headless CMS built on Node.js. Automatically generates REST and GraphQL APIs from content types defined in the visual Content-Type Builder. Upstream: <https://github.com/strapi/strapi>. Docs: <https://docs.strapi.io>.

Strapi is a Node.js application listening on port `1337` by default. The admin panel lives at `/admin`. There is **no official Docker image** — Strapi projects are code repositories; Docker images are built from the project's own Dockerfile. What varies across deployments is the database backend (SQLite for dev, PostgreSQL/MySQL/MariaDB for production), how the project is containerized, and how the reverse proxy is configured.

## Compatible install methods

Verified against upstream docs at <https://docs.strapi.io/cms/installation/>.

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| CLI quickstart (local/dev) | <https://docs.strapi.io/cms/installation/cli> | ✅ | Development on Mac/Win/Linux with SQLite. |
| CLI + PostgreSQL (production) | <https://docs.strapi.io/cms/deployment> | ✅ | Self-hosted production on a VPS/server. |
| Community Docker (`@strapi-community/dockerize`) | <https://github.com/strapi-community/strapi-tool-dockerize> | ⚠️ Community | Generates Dockerfile + docker-compose for your project. Not official but widely used. |
| Strapi Cloud | <https://strapi.io/cloud> | ✅ | Managed PaaS — out of scope for open-forge. |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| preflight | "Which database backend?" | `AskUserQuestion`: `SQLite (dev only)` / `PostgreSQL` / `MySQL` / `MariaDB` | All methods |
| preflight | "Project name / directory?" | Free-text | CLI install |
| preflight | "Use TypeScript?" | `AskUserQuestion`: `Yes` / `No` | CLI install |
| db | "PostgreSQL/MySQL host, port, database name, username, password?" | Free-text (sensitive) | PostgreSQL/MySQL/MariaDB |
| secrets | "JWT_SECRET, ADMIN_JWT_SECRET, APP_KEYS?" | Free-text (generate with `openssl rand -base64 32`) | All production deploys |
| domain | "Domain or IP for the Strapi API?" | Free-text | Production/reverse-proxy setups |

## Software-layer concerns

### Config paths and env vars

Key environment variables (used in `.env` at project root or passed to Docker):

| Variable | Purpose | Example |
|---|---|---|
| `DATABASE_CLIENT` | DB driver | `postgres`, `mysql`, `sqlite` |
| `DATABASE_HOST` | DB host | `postgres` (Docker service name) |
| `DATABASE_PORT` | DB port | `5432`, `3306` |
| `DATABASE_NAME` | DB name | `strapi` |
| `DATABASE_USERNAME` | DB user | `strapi` |
| `DATABASE_PASSWORD` | DB password | (strong random) |
| `JWT_SECRET` | JWT signing key | 32+ random bytes, base64 |
| `ADMIN_JWT_SECRET` | Admin JWT key | 32+ random bytes, base64 |
| `APP_KEYS` | Session keys (comma-separated) | Four base64 strings |
| `NODE_ENV` | `development` or `production` | `production` |

Config files live at `config/database.js` (or `.ts`), `config/server.js`, and `config/plugins.js` in the project directory.

### Community Docker workflow

Since there is no official Docker image, use the community dockerize tool to generate a Dockerfile and docker-compose for an existing project:

```bash
npx @strapi-community/dockerize@latest
```

This generates a Dockerfile that builds from `node:20-alpine`, installs dependencies, and runs `strapi start`. Reference: <https://github.com/strapi-community/strapi-tool-dockerize>.

Example docker-compose structure (community-generated, not official):

```yaml
services:
  strapi:
    build: .
    environment:
      DATABASE_CLIENT: postgres
      DATABASE_HOST: postgres
      DATABASE_PORT: 5432
      DATABASE_NAME: strapi
      DATABASE_USERNAME: strapi
      DATABASE_PASSWORD: "${DB_PASSWORD}"
      JWT_SECRET: "${JWT_SECRET}"
      ADMIN_JWT_SECRET: "${ADMIN_JWT_SECRET}"
      APP_KEYS: "${APP_KEYS}"
      NODE_ENV: production
    ports:
      - "1337:1337"
    depends_on:
      - postgres
  postgres:
    image: postgres:17
    environment:
      POSTGRES_USER: strapi
      POSTGRES_PASSWORD: "${DB_PASSWORD}"
      POSTGRES_DB: strapi
    volumes:
      - postgres_data:/var/lib/postgresql/data

volumes:
  postgres_data:
```

Store all secrets in `.env` (never commit to git). Reverse-proxy Strapi behind NGINX or Caddy for TLS.

### Data directories

| Path | Contents |
|---|---|
| `public/uploads/` | Uploaded media files (local storage provider) |
| `.tmp/` | SQLite DB file (`data.db`) in dev |
| `config/` | Server, database, plugins, middleware config |

For production, use a cloud storage provider (S3, Cloudinary) for uploads rather than local disk — see <https://docs.strapi.io/cms/plugins/upload>.

## Upgrade procedure

Based on <https://docs.strapi.io/cms/upgrades>:

1. Read the migration guide for the target version.
2. Back up the database and `public/uploads/`.
3. Update `@strapi/strapi` and all `@strapi/*` packages in `package.json`.
4. Run `npm install` (or `yarn`/`pnpm`).
5. Run `npm run build` to rebuild the admin panel.
6. Start: `npm run start` (or redeploy your Docker image).
7. DB migrations run automatically on first start.

For Docker: rebuild the image (`docker compose build`) then `docker compose up -d`.

## Gotchas

- **No official Docker image.** Strapi projects are code — you build the image from your own `Dockerfile`. The `strapi/strapi` image on Docker Hub is outdated and unmaintained.
- **Admin panel must be built.** After any code or plugin change, run `npm run build`. In Docker, rebuild the image.
- **APP_KEYS must be four distinct values.** Generate with `openssl rand -base64 32` four times, comma-separated.
- **SQLite is dev-only.** Concurrent writes will corrupt the database; use PostgreSQL for production.
- **Uploads are not in the DB.** Back up `public/uploads/` separately, or use a cloud storage plugin.
- **Content-Type Builder is disabled in production** (`NODE_ENV=production`). Schema changes must be made in dev and deployed via code.

## Links

- Upstream: <https://github.com/strapi/strapi>
- Install docs: <https://docs.strapi.io/cms/installation/cli>
- Deployment: <https://docs.strapi.io/cms/deployment>
- Database configuration: <https://docs.strapi.io/cms/configurations/database>
- Upgrade guides: <https://docs.strapi.io/cms/upgrades>
- Community dockerize tool: <https://github.com/strapi-community/strapi-tool-dockerize>
