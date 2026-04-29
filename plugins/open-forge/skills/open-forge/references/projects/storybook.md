---
name: storybook-project
description: Storybook recipe for open-forge. Frontend workshop for building UI components in isolation — npm package, not a traditional "self-hosted app." "Deploying" Storybook means building the static bundle (`npm run build-storybook`) and serving `storybook-static/` from any static host (S3+CDN, Nginx, Caddy, Vercel, Netlify, GitHub Pages).
---

# Storybook (frontend workshop)

MIT-licensed frontend workshop for building, testing, and documenting UI components in isolation. React, Vue, Angular, Web Components, Svelte, Preact, Ember, and more.

**Upstream README:** https://github.com/storybookjs/storybook/blob/main/README.md
**Upstream docs:** https://storybook.js.org/docs
**Deploy guide:** https://storybook.js.org/docs/sharing/publish-storybook

> [!NOTE]
> Storybook is **not a traditional self-hosted app**. It's a dev tool + an npm package + a static site generator. "Deploying" Storybook means:
>
> 1. Adding `@storybook/*` packages to your JS project.
> 2. Running `npm run build-storybook` → produces `storybook-static/`.
> 3. Serving `storybook-static/` from any static web host.
>
> There is no database, no long-running server, no auth layer shipped by upstream. All of the self-host concerns in this recipe are about **hosting the built static bundle**.

## Compatible combos

| Infra | Runtime | Status | Notes |
|---|---|---|---|
| localhost | native (`npx storybook dev`) | ✅ | Dev only — hot-reload on `http://localhost:6006` |
| static (S3 + CloudFront) | n/a | ✅ | Upload `storybook-static/` to S3, serve via CDN |
| static (Nginx / Caddy) | native | ✅ | `root /srv/storybook-static; try_files $uri $uri/ /index.html;` |
| Cloudflare Pages | native | ✅ | Connect repo; build command `npm run build-storybook`; output `storybook-static` |
| Vercel | native | ✅ | Official Vercel adapter — `npx @storybook/cli@latest init` sets it up |
| Netlify | native | ✅ | Same story as Vercel |
| GitHub Pages | native | ✅ | Free for public repos. Upstream ships `storybook-deployer` and first-party `@storybook/gh-pages` docs |
| Docker | `httpd` / `nginx` | ✅ | Build static, `COPY storybook-static /usr/share/nginx/html` |
| Chromatic | hosted | ✅ | Upstream-blessed commercial option (Chromatic is made by the Storybook team) — free tier available |

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| project | "Path to the JS project that has Storybook installed?" | Free-text | We're serving its `storybook-static/` output |
| dns | "Domain to host Storybook on?" | Free-text | e.g. `storybook.example.com`, `design.example.com` |
| build | "Framework in the project?" | AskUserQuestion: React / Vue / Angular / Svelte / Web Components / Ember / Preact / SolidJS / Other | For build-command hints |
| host | "Where to deploy?" | AskUserQuestion: Cloudflare Pages / Vercel / Netlify / GitHub Pages / S3+CDN / own-VPS / Chromatic | Each has its own adapter |
| auth | "Should Storybook be public or auth-gated?" | AskUserQuestion: Public / Basic auth / OAuth (via proxy) | Static hosts typically need external auth (Cloudflare Access, Tailscale funnel, basic auth in Nginx/Caddy) |

## Install / deploy paths

### 1. Dev-mode (local)

Source: https://storybook.js.org/docs

```bash
# Inside an existing JS project
npx storybook@latest init
npm run storybook   # starts dev server on :6006
```

Hot-reload, live editing. Not a production path — it's a dev server.

### 2. Build static → any static host

```bash
npm run build-storybook
# Outputs to ./storybook-static/
```

Upload the directory to any static host. Examples:

**Cloudflare Pages** (Git-integrated): build command `npm run build-storybook`, output directory `storybook-static`. Zero config for the simple case.

**S3 + CloudFront**:

```bash
aws s3 sync ./storybook-static s3://my-storybook-bucket/ --delete
aws cloudfront create-invalidation --distribution-id <ID> --paths '/*'
```

**Own VPS with Caddy**:

```caddy
storybook.example.com {
  root * /srv/storybook
  file_server
  encode gzip zstd
}
```

Upload `storybook-static/*` to `/srv/storybook/`.

**Docker (Nginx static serve)**:

```dockerfile
FROM nginx:alpine
COPY storybook-static /usr/share/nginx/html
```

### 3. GitHub Pages

```bash
npx storybook-deployer --out storybook-static
# Or via gh-pages package
```

See https://storybook.js.org/docs/sharing/publish-storybook#github-pages

### 4. Chromatic (upstream-blessed SaaS)

```bash
npx chromatic --project-token=<token>
```

Publishes Storybook to Chromatic's CDN + adds visual regression testing. Free tier. Made by the Storybook team.

## Software-layer concerns

### There is no Storybook "server"

Key mental shift: unlike Ghost / Immich / Supabase, there's no long-running process to run, no database, no secrets. The "app" is a directory of static files. Treat it like a docs site.

### Build-time env

Storybook respects standard framework env-vars (`NEXT_PUBLIC_*`, `VITE_*`, etc.) at build time. There's no runtime config — everything's baked into `storybook-static/`.

### Auth / access control

Because it's static, you authenticate at the edge:

- **Cloudflare Pages + Cloudflare Access** — email-OTP / Google SSO in front of the bucket
- **Tailscale** — `tailscale serve` makes it private-tailnet-only
- **Basic auth in Caddy/Nginx** — cheap but ugly
- **Vercel/Netlify password protection** — paid feature on both

### Versioned / branch-preview Storybooks

Common pattern: one Storybook per git branch. Deploy under `storybook.example.com/pr-123/`. Cloudflare Pages / Vercel / Netlify do this natively via preview URLs.

## Upgrade procedure

Upgrading Storybook = bumping `@storybook/*` npm packages in your project.

```bash
npx storybook@latest upgrade
```

The upgrade CLI migrates config files (`.storybook/main.js`, `preview.js`) between majors. Then redeploy by rebuilding:

```bash
npm run build-storybook
# Redeploy storybook-static/ to your host
```

Storybook publishes upgrade notes: https://storybook.js.org/releases

## Gotchas

- **This isn't a self-hosted app in the usual sense.** If someone asks "how do I deploy Storybook on my Hetzner server," the answer is: build it once, serve the output folder. Don't provision a whole Docker stack.
- **Framework lock-in.** Storybook is tied to your project's JS framework. React Storybook ≠ Vue Storybook. Build commands and config files differ.
- **`build-storybook` can take minutes on big projects.** For CI + preview-per-PR, cache `node_modules/`, `.storybook-cache/`, and consider [`@storybook/webpack-cache`](https://github.com/storybookjs/storybook) (baked in for v7+).
- **Output directory is `storybook-static/` by default but overridable.** Some examples use `./out` or `./storybook-build`. Match the deploy config to whatever the project's `package.json` script emits.
- **SPA routing quirks.** Storybook is an SPA; static hosts need `try_files $uri $uri/ /index.html;` (or equivalent) so deep links like `/?path=/story/button--primary` work on reload. Cloudflare Pages / Vercel / Netlify do this automatically; Nginx / S3+CDN needs explicit config.
- **No built-in analytics or auth.** Storybook is internal tooling — put it behind Cloudflare Access, VPN, or basic auth. **Don't publish without gating unless you explicitly want the world looking at your component library** (some teams do, as marketing).
- **Chromatic is separate.** Confusingly, the Storybook team also sells Chromatic (visual regression + hosted Storybook). Free tier is generous; if you use it, you don't need a separate "self-host" for the viewer.
- **Addons matter more than the core.** Deployment-wise it's all the same; just noting that a Storybook's usefulness depends on `@storybook/addon-a11y`, `-actions`, `-docs`, `-test`, etc. Upgrade path applies to addons too.

## TODO — verify on subsequent deployments

- [ ] Exercise the Caddy + Cloudflare Access combo for a private-by-default Storybook.
- [ ] Document the preview-per-PR pattern with Cloudflare Pages.
- [ ] Confirm `storybook-deployer` is still recommended for GH Pages vs `gh-pages` npm package.
- [ ] Tailscale serve pattern for internal-only Storybooks.
- [ ] Chromatic free-tier limits (builds/month) — what's the break-point where self-host pays off?
