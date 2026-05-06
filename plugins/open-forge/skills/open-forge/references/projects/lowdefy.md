---
name: lowdefy
description: Lowdefy recipe for open-forge. Config-first web app builder for building internal tools, admin panels, and dashboards using YAML. Source: https://github.com/lowdefy/lowdefy. Website: https://lowdefy.com.
---

# Lowdefy

Config-first web stack for building internal tools, admin panels, dashboards, and forms using YAML. Built on Next.js and Auth.js. Replaces hundreds of lines of React code with concise, schema-validated YAML config. Includes 70+ UI components, 50+ logic operators, and 10+ data connectors (MongoDB, PostgreSQL, MySQL, REST APIs, Google Sheets, S3, Elasticsearch, Stripe). License: Apache-2.0. Upstream: <https://github.com/lowdefy/lowdefy>. Website: <https://lowdefy.com>.

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| VPS / bare metal | Node.js (Next.js server) | Self-hosted production deployment |
| VPS / bare metal | Docker | Containerized deployment |
| Local dev | npx lowdefy dev | Zero-install local dev server |
| Cloud | Vercel / Netlify / any Next.js host | Cloud deployment via lowdefy build |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| port | "Port to serve Lowdefy on?" | Default: 3000 |
| app_name | "App name?" | Used in lowdefy.yaml |
| auth | "Enable authentication?" | Lowdefy uses Auth.js (30+ providers) |
| auth_secret | "Auth secret (random string)?" | Generate with `openssl rand -hex 32` |
| db_connector | "Primary data connector? (mongodb / postgresql / mysql / rest / sheets / none)" | Depends on your backend |
| db_url | "Database connection URL?" | e.g. mongodb://user:pass@host:27017/db |

## Software-layer concerns

- **Node.js 18+** required
- App is defined entirely in `lowdefy.yaml` (or split YAML files) — no React/JS required for core usage
- `lowdefy.yaml` is the entry point: defines pages, blocks, connections, operators
- Build outputs a Next.js app under `.lowdefy/server/` — deploy like any Next.js app
- No persistent server-side state; data lives in connected backends (DB, APIs, etc.)
- Auth: built on Auth.js v5 — supports 75+ OAuth providers, email magic links, credentials
- Secrets managed via `.env` file or environment variables
- Docker image: build with `npx lowdefy@latest build` then serve with `node .lowdefy/server/index.js`

### Quick start (local dev)

```bash
mkdir my-app && cd my-app
npx lowdefy@latest init
# Edit lowdefy.yaml to build your app
npx lowdefy@latest dev
# Visit http://localhost:3000
```

### Example lowdefy.yaml (minimal)

```yaml
lowdefy: 4
name: My App

pages:
  - id: home
    type: PageHeaderMenu
    properties:
      title: Home
    blocks:
      - id: greeting
        type: Markdown
        properties:
          content: |
            # Welcome to My Lowdefy App
```

### Production deployment (Node.js)

```bash
npm install -g lowdefy
lowdefy build
# Outputs to .lowdefy/server/
node .lowdefy/server/index.js
```

### Docker Compose

```yaml
services:
  lowdefy:
    image: node:18-alpine
    container_name: lowdefy
    restart: unless-stopped
    working_dir: /app
    command: sh -c "npm install -g lowdefy && lowdefy build && node .lowdefy/server/index.js"
    ports:
      - "3000:3000"
    environment:
      - LOWDEFY_SECRET_MONGO_URL=mongodb://user:pass@mongo:27017/mydb
      - AUTH_SECRET=changeme_use_openssl_rand
      - PORT=3000
    volumes:
      - ./lowdefy.yaml:/app/lowdefy.yaml:ro
      - lowdefy-cache:/app/.lowdefy

  # Example MongoDB backend
  mongo:
    image: mongo:7
    container_name: lowdefy-mongo
    restart: unless-stopped
    volumes:
      - lowdefy-mongo-data:/data/db

volumes:
  lowdefy-cache:
  lowdefy-mongo-data:
```

### Environment variables

| Variable | Purpose |
|---|---|
| `LOWDEFY_SECRET_*` | Secrets injected into connections — referenced as `_secret: MY_VAR` in YAML |
| `AUTH_SECRET` | Required for Auth.js session signing |
| `AUTH_URL` | Public URL for Auth.js callbacks (needed for OAuth) |
| `PORT` | Server port (default 3000) |

## Upgrade procedure

1. Update Lowdefy version in `package.json` (if using npm) or update the `npx lowdefy@latest` reference
2. Rebuild: `lowdefy build`
3. Restart the server process / container
4. Review the [changelog](https://github.com/lowdefy/lowdefy/releases) — config YAML changes are generally backward-compatible

## Gotchas

- **Build step required**: Unlike traditional CMSes, every config change requires `lowdefy build` before being served. In production, wire build into your CI/CD pipeline.
- **No server-side logic without plugins**: Lowdefy executes config, not arbitrary code. Custom logic requires writing an npm plugin (Operator/Action/Connection). This is intentional for security but may surprise developers.
- **Secrets naming**: Secrets referenced in YAML as `_secret: MY_VAR` must be set as `LOWDEFY_SECRET_MY_VAR` in the environment. The prefix is mandatory.
- **Auth.js v5**: The auth system was rewritten for v5. Older OAuth provider configs may need updating. See Auth.js docs for migration.
- **Not a full CMS**: Lowdefy builds internal tools and admin panels, not public marketing websites or blogs. Use it for dashboards, form builders, data entry UIs, not storefronts.
- **Cold start on serverless**: If deploying to Vercel/Netlify, the Next.js server may have cold starts. For consistently low-latency tools, self-host with a persistent Node.js process.

## Links

- Upstream repo: https://github.com/lowdefy/lowdefy
- Website: https://lowdefy.com
- Documentation: https://docs.lowdefy.com
- Getting started tutorial: https://docs.lowdefy.com/tutorial-start
- Plugin development: https://docs.lowdefy.com/plugins-introduction
- Community plugins: https://github.com/lowdefy/community-plugins
- Discord: https://discord.gg/WmcJgXt
- Release notes: https://github.com/lowdefy/lowdefy/releases
