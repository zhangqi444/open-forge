---
name: docusaurus-project
description: Docusaurus recipe for open-forge. MIT-licensed static-site generator from Meta, optimized for docs/blog sites. Unlike a server-based self-host target, Docusaurus is a BUILD tool — `npm init docusaurus@latest` scaffolds a site, `npm run build` produces static HTML in `build/`, and any static-file host (nginx, Caddy, S3+CloudFront, GitHub Pages, Vercel, Netlify, Cloudflare Pages) serves the output. Recipe covers scaffolding, build, and the common self-host deploy targets.
---

# Docusaurus

MIT-licensed static-site generator for documentation and blog sites, maintained by Meta. Upstream: <https://github.com/facebook/docusaurus>. Docs: <https://docusaurus.io/docs>.

**Important reframing for self-host.** Docusaurus is **not** a server you run 24/7. It's a build tool:

1. `npm init docusaurus@latest my-site classic` — scaffolds a new site.
2. `cd my-site && npm run start` — dev server on `:3000` with hot reload (dev only).
3. `npm run build` — emits static HTML/CSS/JS into `build/`.
4. Point any static-file host at `build/`. Done.

That shifts the "install method" question from "which runtime / orchestrator?" to "which static host?" — and a lot of open-forge's infra-layer machinery (Docker Compose, Kubernetes, databases) doesn't apply. The recipes below cover the upstream-documented deploy targets.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Self-host on nginx / Caddy | <https://docusaurus.io/docs/deployment> | ✅ (generic "deploy to static host") | You already run a web server and want docs on a subdomain. |
| GitHub Pages | <https://docusaurus.io/docs/deployment#deploying-to-github-pages> | ✅ | Free, public repos, `docusaurus deploy` command handles it. |
| Vercel | <https://docusaurus.io/docs/deployment#deploying-to-vercel> | ✅ (partnership-documented) | Zero-config for private repos / preview deploys. |
| Netlify | <https://docusaurus.io/docs/deployment#deploying-to-netlify> | ✅ | Similar to Vercel; free tier suitable for docs. |
| Cloudflare Pages | <https://docusaurus.io/docs/deployment#deploying-to-cloudflare-pages> | ✅ | Fast CDN edge; free tier generous. |
| AWS Amplify / S3+CloudFront | <https://docusaurus.io/docs/deployment#deploying-to-aws-amplify> | ✅ | AWS-native; suitable if you're already on AWS. |
| Docker + nginx:alpine | Community pattern (not upstream-documented) | ⚠️ | Bundle the built `build/` into an `nginx:alpine` image for portable deploy. |
| Gitpod / CodeSandbox | <https://docusaurus.io/docs/deployment> | ✅ | Ephemeral preview, not production. |

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Existing Docusaurus site, or scaffold a new one?" | `AskUserQuestion`: `Scaffold new` / `Existing repo` | Drives whether we run `npm init docusaurus@latest` or just `npm ci`. |
| preflight | "Node.js version available?" (Docusaurus v3 needs Node ≥ 18.0) | Free-text / auto-detect via `node -v` | Install latest LTS via `nvm` if missing. |
| project | *scaffold* "Site name / slug?" | Free-text | Becomes the directory name + `docusaurus.config.js` `title`. |
| project | *scaffold* "Template: `classic` / `facebook` / `bare`?" | `AskUserQuestion` | `classic` is the default — docs + blog + landing page. Upstream templates: <https://github.com/facebook/docusaurus/tree/main/packages/create-docusaurus/templates>. |
| deploy | "Where do you want to host the built site?" | `AskUserQuestion` with options from the table above | Drives which deploy section runs. |
| deploy | *self-host* "FQDN for the docs site?" (e.g. `docs.example.com`) | Free-text | Sets `url` + `baseUrl` in `docusaurus.config.js`. |
| deploy | *self-host* "Reverse proxy to use?" | `AskUserQuestion`: `nginx` / `Caddy` / `Traefik` / `Apache` | Loads the matching snippet below. |
| deploy | *GH Pages* "Repo in `user.github.io` format or project repo?" | `AskUserQuestion` | Affects `url` + `baseUrl` math (project repos deploy to `user.github.io/project-name/`). |
| deploy | *GH Pages* "Deploy branch?" (`gh-pages` or `main`+`docs/` folder) | `AskUserQuestion` | Sets `deploymentBranch`. |

## Scaffold a new site

```bash
# 1. Node.js ≥ 18.0 required for Docusaurus v3 (v2 supports ≥ 14)
node -v            # verify

# 2. Scaffold via the upstream CLI
npm init docusaurus@latest my-site classic

# 3. Dev loop (hot reload on http://localhost:3000/)
cd my-site
npm run start

# 4. Production build (emits static files to build/)
npm run build

# 5. Smoke-test the production build locally
npm run serve      # serves build/ on :3000
```

`npm init docusaurus@latest` is the upstream-blessed scaffolder per the main README. Templates other than `classic`: `facebook` (Meta's internal look), `bare` (no presets), and `classic-typescript` (TS variant).

### Key files in a Docusaurus project

| File | Role |
|---|---|
| `docusaurus.config.js` | Site config — `title`, `url`, `baseUrl`, navbar, footer, theme, plugins. Change canonical URL here. |
| `sidebars.js` | Docs sidebar hierarchy. |
| `docs/` | Docs content (Markdown / MDX). |
| `blog/` | Blog posts, dated filenames. |
| `src/pages/` | Arbitrary React-component pages (e.g. `index.js` = landing page). |
| `static/` | Copied verbatim into `build/`. Put `robots.txt`, favicons, images here. |

Upstream docs index: <https://docusaurus.io/docs>.

## Deploy — self-host behind a reverse proxy

### Build on a CI server, rsync to the web host

```bash
# On CI
npm ci
npm run build
rsync -avz --delete build/ deploy@docs-host:/var/www/docs/
```

### Nginx (site at root)

```nginx
server {
    listen 80;
    listen [::]:80;
    server_name docs.example.com;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name docs.example.com;

    ssl_certificate     /etc/letsencrypt/live/docs.example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/docs.example.com/privkey.pem;

    root /var/www/docs;
    index index.html;

    # Docusaurus emits .html; fall back to .html for pretty URLs
    location / {
        try_files $uri $uri/ $uri.html =404;
    }

    # Long cache for hashed static assets
    location /assets/ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

### Caddy

```caddy
docs.example.com {
    root * /var/www/docs
    try_files {path} {path}.html {path}/
    file_server
    encode zstd gzip

    @assets path /assets/*
    header @assets Cache-Control "public, max-age=31536000, immutable"
}
```

Caddy provisions TLS via Let's Encrypt automatically.

### Docker + nginx:alpine (community pattern)

Useful if you want an immutable image per docs version. Not in upstream's deployment docs, but a common pattern.

```dockerfile
# Stage 1 — build
FROM node:20-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Stage 2 — serve
FROM nginx:alpine
COPY --from=build /app/build /usr/share/nginx/html
# Optional: custom nginx config for try_files behavior
# COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
```

## Deploy — GitHub Pages

Upstream's preferred free hosting. <https://docusaurus.io/docs/deployment#deploying-to-github-pages>.

1. Set `url` + `baseUrl` + `organizationName` + `projectName` in `docusaurus.config.js`:

   ```js
   module.exports = {
     url: 'https://<user>.github.io',
     baseUrl: '/<project>/',     // or '/' for user/org sites (<user>.github.io)
     organizationName: '<user>', // GitHub user/org
     projectName: '<project>',
     deploymentBranch: 'gh-pages',
     trailingSlash: false,
   };
   ```

2. Deploy:

   ```bash
   # HTTPS (user-driven auth)
   GIT_USER=<github-user> npm run deploy

   # SSH
   USE_SSH=true npm run deploy
   ```

3. Enable **Settings → Pages → Source: gh-pages** in the GitHub repo.

### Via GitHub Actions

Upstream publishes a reference workflow at <https://docusaurus.io/docs/deployment#triggering-deployment-with-github-actions> — copy verbatim; it checks out, builds, and pushes to `gh-pages`.

## Deploy — Vercel / Netlify / Cloudflare Pages

These three take a **"import repo → set build command → done"** path. Upstream's deployment docs link out to each provider's Docusaurus-specific guide.

| Provider | Build command | Output dir |
|---|---|---|
| Vercel | `npm run build` | `build` |
| Netlify | `npm run build` | `build` |
| Cloudflare Pages | `npm run build` | `build` |

Environment vars: if `docusaurus.config.js` reads any (`process.env.ALGOLIA_APP_ID` etc.), set them in the provider's dashboard.

## Upgrade

Docusaurus major upgrades (v1 → v2 → v3) are non-trivial — content migrations, theme API changes, plugin config shifts.

```bash
# Minor / patch upgrades (same major)
npx npm-check-updates '@docusaurus/*' -u
npm install
npm run build   # verify nothing broke
```

For **major upgrades**: follow the upstream migration guide (`npm run docusaurus -- --help` lists CLI migration helpers for v1→v2; v2→v3 has a dedicated page at <https://docusaurus.io/docs/migration>). Always upgrade on a branch, diff the build output, then merge.

## Gotchas

- **"Self-host" here = static files, not a server.** No DB, no Redis, no container orchestration. If someone asks for "HA Docusaurus," they want a CDN in front of static files (Cloudflare / CloudFront).
- **Node 18+ for v3.** Docusaurus v2 accepted Node 14+; v3 hard-requires 18. If `npm run build` errors with "Cannot find module 'node:...'" on a fresh machine, check the Node version.
- **`trailingSlash` config matters for static hosts.** nginx `try_files $uri $uri/ $uri.html` handles both shapes; S3+CloudFront needs a Lambda@Edge or origin behavior tweak for pretty URLs. Pick `true` or `false` early and stick with it — switching after launch breaks bookmarks.
- **`baseUrl` must match deploy location.** GH Pages project repo = `/<project>/`; root domain = `/`. Getting this wrong → broken CSS/JS on the deployed site (requests go to `/assets/…` but files live at `/<project>/assets/…` or vice versa).
- **Algolia DocSearch is a separate signup.** If you add Algolia site search, you apply via <https://docsearch.algolia.com/apply/> — free for open-source docs, paid for commercial. Self-hosted alternatives: <https://typesense.org/docs/guide/docsearch.html>.
- **MDX v3 breaking changes in Docusaurus v3.** Some MDX v1/v2 syntax that was lax (e.g. bare `{something}` in prose) errors out in v3. The migration guide has a full list.
- **`npm run build` is memory-hungry on big sites.** Sites with thousands of docs pages may need `NODE_OPTIONS="--max-old-space-size=4096"` on CI runners with limited memory.
- **Static output is version-able.** Snapshot `build/` in git (or a CDN) to keep a rollback; `npm run build` is deterministic-ish but image optimization plugins can introduce byte diffs.

## Upstream references

- Repo: <https://github.com/facebook/docusaurus>
- Docs: <https://docusaurus.io/docs>
- Installation: <https://docusaurus.io/docs/installation>
- Deployment: <https://docusaurus.io/docs/deployment>
- Migration guides: <https://docusaurus.io/docs/migration>
- Templates: <https://github.com/facebook/docusaurus/tree/main/packages/create-docusaurus/templates>
- 5-minute tutorial: <https://tutorial.docusaurus.io>
- Playground: <https://docusaurus.new>

## TODO — verify on first deployment

- Confirm `classic` template still ships docs + blog + landing (upstream occasionally restructures templates).
- Verify Node version pin in `package.json` `engines.node` of a fresh scaffold matches what we gate on in preflight.
- Confirm GH Actions workflow snippet in upstream's deployment doc still compiles against current actions versions.
- Test Vercel / Netlify / Cloudflare Pages one-click imports against a scaffolded v3 site to confirm auto-detection still works.
