---
name: apostrophe
description: Apostrophe (ApostropheCMS) recipe for open-forge. Covers CLI scaffold, Docker Compose, and production deployment. Full-stack Node.js + MongoDB CMS with in-context editing, headless REST/GraphQL API, and enterprise features. Sourced from https://github.com/apostrophecms/apostrophe and https://docs.apostrophecms.org/.
---

# ApostropheCMS (Apostrophe)

Full-stack content management system built with Node.js and MongoDB. Content creators edit directly on live pages without switching to a separate admin interface. Supports headless delivery via REST API for any frontend framework (React, Vue, Astro, etc.), in-context page editing, enterprise permissions and workflow, automated translations, and multi-site. Upstream: https://github.com/apostrophecms/apostrophe. Docs: https://docs.apostrophecms.org/. MIT.

## Compatible install methods

| Method | Upstream | When to use |
|---|---|---|
| CLI (apos create) | https://docs.apostrophecms.org/guide/development-setup.html | New project scaffold |
| Docker Compose | https://docs.apostrophecms.org/ | Containerized dev/prod |
| Starter kit (Astro) | https://apostrophecms.com/starter-kits/ | Headless + visual editing |
| ApostropheCMS Hosting | https://apostrophecms.com/hosting | Managed; out of scope |

## Inputs to collect

| Phase | Prompt | Applicability |
|---|---|---|
| preflight | "New project or existing codebase?" | CLI vs Docker |
| database | "MongoDB connection string?" | Required |
| storage | "Local uploads or S3/cloud storage?" | Configure in modules |
| domain | "Production domain?" | For canonical URLs and CORS |
| session | "SESSION_SECRET value?" | Required; random string |

## CLI quickstart (new project)

```sh
# Install CLI
npm install -g @apostrophecms/cli

# Create project
apos create my-site
cd my-site
npm install

# Development (requires local MongoDB)
APOS_MONGODB_URI="mongodb://localhost:27017/my-site" npm run dev
```

Access at http://localhost:3000. Admin at /login (set up first user on first visit).

## Docker Compose

```yaml
version: "3.8"
services:
  apostrophe:
    image: node:20-alpine
    working_dir: /app
    command: sh -c "npm install && npm run dev"
    ports:
      - "3000:3000"
    environment:
      APOS_MONGODB_URI: "mongodb://mongo:27017/apostrophe"
      SESSION_SECRET: "change-me-to-a-long-random-string"
      NODE_ENV: development
      APOS_RELEASE_ID: "1"
    volumes:
      - ./:/app
      - uploads:/app/public/uploads
    depends_on:
      - mongo

  mongo:
    image: mongo:7
    volumes:
      - mongo-data:/data/db

volumes:
  uploads:
  mongo-data:
```

**Note:** For production, use an official prebuilt image from your CI pipeline rather than building at runtime.

## Production environment variables

| Variable | Required | Purpose |
|---|---|---|
| APOS_MONGODB_URI | Yes | MongoDB connection string |
| SESSION_SECRET | Yes | Express session signing key; keep secret |
| NODE_ENV | Yes | Set to `production` |
| APOS_RELEASE_ID | Yes | Unique string per deployment (e.g., git SHA); busts asset cache |
| APOS_UPLOADFS_BACKEND | No | `s3` for S3/MinIO storage |
| APOS_S3_BUCKET | No | S3 bucket name |
| APOS_S3_REGION | No | AWS region |
| APOS_S3_KEY | No | AWS access key |
| APOS_S3_SECRET | No | AWS secret key |

## Headless API usage

```js
// Fetch published articles via REST API
const res = await fetch('https://your-site.com/api/v1/article?page=1');
const data = await res.json();
// data.results = array of article pieces
```

Full REST API: https://docs.apostrophecms.org/reference/api/pieces.html

## Upgrade procedure

```sh
# Update package.json to new apostrophe version
npm install apostrophe@latest

# Check migration guide for breaking changes
# https://docs.apostrophecms.org/guide/migration/

# Run database migration (if any)
node app @apostrophe/migration:migrate
```

## Gotchas

- **APOS_RELEASE_ID required in production** — This env var must change with every deployment; use git SHA (`git rev-parse HEAD`). Without it, clients cache stale assets.
- **MongoDB required** — Apostrophe uses MongoDB exclusively; no SQL/PostgreSQL option. Minimum MongoDB 6.0.
- **Session secret** — `SESSION_SECRET` must be a long random string and consistent across restarts/replicas. Changing it logs out all users.
- **Uploads storage** — Local file uploads are not suitable for multi-instance or containerized deployments; use S3/MinIO via `uploadfs` module.
- **Asset compilation at startup** — First startup compiles frontend assets (CSS/JS); allow extra time. Production builds are faster with `NODE_ENV=production`.
- **Multi-site** — Apostrophe supports running multiple sites from one codebase via `@apostrophecms/multisite` module; requires a MongoDB replica set.
- **Enterprise features** — Workflow (draft/publish), page comparison, and automated translation are available in the commercial Pro bundle; core editing is MIT.

## Links

- GitHub: https://github.com/apostrophecms/apostrophe
- Documentation: https://docs.apostrophecms.org/
- REST API reference: https://docs.apostrophecms.org/reference/api/pieces.html
- Headless guide: https://docs.apostrophecms.org/guide/headless-cms.html
- Starter kits: https://apostrophecms.com/starter-kits/
